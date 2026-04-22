import { execFileSync } from "node:child_process";
import { complete } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionContext, ExtensionCommandContext } from "@mariozechner/pi-coding-agent";

type PaneGetResponse = {
  result?: {
    pane?: {
      workspace_id?: string;
    };
  };
};

const DEFAULT_INTERVAL_MS = 1000;
const DEFAULT_MAX_TOKENS = 24;
const DEFAULT_MAX_WORKSPACE_NAME_LENGTH = 32;
const DEFAULT_VERBOSE = false;
const AUTO_DETECT_MODELS = [
  "gpt-5.4-nano",
  "gemini-3-flash",
  "claude-4-5-haiku",
  "gpt-5.4-mini",
];
const WORKSPACE_NAME_ELLIPSIS = "...";
const GENERIC_SESSION_NAMES = new Set(["", "chat"]);
const MAX_TITLE_WORDS = 5;
const LOG_PREFIX = "[herdr-workspace-summary]";

function wordCount(text: string): number {
  return text.trim().split(/\s+/).filter(Boolean).length;
}

export default function (pi: ExtensionAPI) {
  let timer: NodeJS.Timeout | null = null;
  let workspaceId: string | null = null;
  let lastSyncedName: string | null = null;
  let lastSourceName: string | null = null;
  let lastResolvedName: string | null = null;
  let pendingSourceName: string | null = null;
  let started = false;
  let syncGeneration = 0;
  let latestCtx: ExtensionContext | ExtensionCommandContext | null = null;
  let resolvedModelName = "";
  let lastError: string | null = null;

  function debug(ctx: ExtensionContext | ExtensionCommandContext, message: string) {
    if (ctx.hasUI) ctx.ui.notify(`${LOG_PREFIX} ${message}`, "info");
  }

  function getPaneId(): string | null {
    return process.env.HERDR_PANE_ID?.trim() || null;
  }

  function getWorkspaceIdFromHerdr(): string | null {
    const paneId = getPaneId();
    if (!paneId) return null;

    try {
      const stdout = execFileSync("herdr", ["pane", "get", paneId], {
        encoding: "utf8",
        timeout: 3000,
        env: process.env,
      });
      const parsed = JSON.parse(stdout) as PaneGetResponse;
      return parsed.result?.pane?.workspace_id?.trim() || null;
    } catch {
      return null;
    }
  }

  function getCurrentSessionName(): string | null {
    const name = pi.getSessionName()?.trim() || "";
    if (GENERIC_SESSION_NAMES.has(name.toLowerCase())) return null;
    return name;
  }

  function formatWorkspaceName(name: string): string {
    const trimmed = name.trim().replace(/\s+/g, " ");
    if (trimmed.length <= DEFAULT_MAX_WORKSPACE_NAME_LENGTH) return trimmed;

    return `${trimmed.slice(0, DEFAULT_MAX_WORKSPACE_NAME_LENGTH - WORKSPACE_NAME_ELLIPSIS.length).trimEnd()}${WORKSPACE_NAME_ELLIPSIS}`;
  }

  function normalizeShortTitle(title: string): string {
    const cleaned = title
      .trim()
      .replace(/^['"`]+|['"`]+$/g, "")
      .replace(/[\n\r]+/g, " ")
      .replace(/\s+/g, " ");

    if (!cleaned) return "";

    const shortened = cleaned.split(/\s+/).filter(Boolean).slice(0, MAX_TITLE_WORDS).join(" ");
    return formatWorkspaceName(shortened);
  }

  function fallbackTitle(name: string): string {
    const firstWords = name.trim().split(/\s+/).filter(Boolean).slice(0, MAX_TITLE_WORDS).join(" ");
    return formatWorkspaceName(firstWords || name);
  }

  function shouldUseModel(name: string): boolean {
    return wordCount(name) > MAX_TITLE_WORDS || name.trim().length > DEFAULT_MAX_WORKSPACE_NAME_LENGTH;
  }

  function resolveModel(ctx: ExtensionContext | ExtensionCommandContext): { provider: string; model: string } | undefined {
    const available = ctx.modelRegistry.getAvailable();
    for (const candidateId of AUTO_DETECT_MODELS) {
      const match = available.find((model) => model.id === candidateId);
      if (match) {
        resolvedModelName = `${match.provider}/${match.id}`;
        return { provider: match.provider, model: match.id };
      }
    }

    resolvedModelName = "";
    return undefined;
  }

  async function summarizeWorkspaceTitle(name: string): Promise<string> {
    const ctx = latestCtx;
    if (!ctx || !shouldUseModel(name)) return fallbackTitle(name);

    const resolved = resolveModel(ctx);
    if (!resolved) {
      lastError = `No summary model available (tried: ${AUTO_DETECT_MODELS.join(", ")})`;
      return fallbackTitle(name);
    }

    const model = ctx.modelRegistry.find(resolved.provider, resolved.model);
    if (!model) {
      lastError = "MODEL_NOT_FOUND";
      return fallbackTitle(name);
    }

    const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
    if (!auth?.ok || !auth.apiKey) {
      lastError = "NO_API_KEY";
      return fallbackTitle(name);
    }

    const prompt = [
      "Rewrite this coding-session title into a short workspace title.",
      `Rules: maximum ${MAX_TITLE_WORDS} words; preserve the core task; no quotes; no punctuation unless essential; stay concrete; output only the title.`,
      "If the title is already short and clear, return a tightened version.",
      "",
      `<title>${name}</title>`,
    ].join("\n");

    try {
      const response = await complete(model, {
        systemPrompt: "You create ultra-short workspace titles for coding sessions. Reply with title text only.",
        messages: [{
          role: "user" as const,
          content: [{ type: "text" as const, text: prompt }],
          timestamp: Date.now(),
        }],
      }, {
        apiKey: auth.apiKey,
        headers: auth.headers,
        maxTokens: DEFAULT_MAX_TOKENS,
        sessionId: ctx.sessionManager.getSessionId(),
      } as any);

      if (response.stopReason === "error") {
        const errMsg = response.errorMessage || "unknown provider error";
        let code = errMsg;
        try {
          const parsed = JSON.parse(errMsg);
          code = parsed?.detail?.code
            || parsed?.error?.code
            || parsed?.error?.message
            || (typeof parsed?.detail === "string" ? parsed.detail : null)
            || errMsg;
        } catch {}
        lastError = String(code);
        return fallbackTitle(name);
      }

      const text = response.content
        .filter((content): content is { type: "text"; text: string } => content.type === "text")
        .map((content) => content.text)
        .join(" ")
        .trim();

      const normalized = normalizeShortTitle(text);
      if (!normalized) {
        lastError = "EMPTY_SUMMARY";
        return fallbackTitle(name);
      }

      lastError = null;
      return normalized;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      lastError = message;
      return fallbackTitle(name);
    }
  }

  function renameWorkspace(workspaceName: string): boolean {
    if (!workspaceId) return false;

    try {
      execFileSync("herdr", ["workspace", "rename", workspaceId, workspaceName], {
        encoding: "utf8",
        timeout: 3000,
        env: process.env,
      });
      lastSyncedName = workspaceName;
      return true;
    } catch {
      return false;
    }
  }

  async function syncNow(force = false): Promise<boolean> {
    if (!workspaceId) workspaceId = getWorkspaceIdFromHerdr();
    const name = getCurrentSessionName();
    if (!workspaceId || !name) return false;

    if (!force && pendingSourceName === name) return false;
    if (!force && name === lastSourceName && lastResolvedName && lastResolvedName === lastSyncedName) return false;

    lastSourceName = name;
    pendingSourceName = name;
    const currentGeneration = ++syncGeneration;

    const workspaceName = await summarizeWorkspaceTitle(name);

    if (currentGeneration !== syncGeneration) return false;

    pendingSourceName = null;
    lastResolvedName = workspaceName;

    if (!force && workspaceName === lastSyncedName) return false;

    const ok = renameWorkspace(workspaceName);
    if (ok && DEFAULT_VERBOSE && latestCtx?.hasUI) {
      latestCtx.ui.notify(`${LOG_PREFIX} ${name} -> ${workspaceName}${resolvedModelName ? ` (${resolvedModelName})` : ""}`, "info");
    }
    return ok;
  }

  function start(ctx: ExtensionContext | ExtensionCommandContext) {
    latestCtx = ctx;
    resolveModel(ctx);

    if (started) return;
    started = true;
    workspaceId = getWorkspaceIdFromHerdr();
    lastSyncedName = null;
    lastSourceName = null;
    lastResolvedName = null;
    pendingSourceName = null;
    syncGeneration = 0;
    lastError = null;

    if (!workspaceId) {
      debug(ctx, "no herdr workspace detected; staying idle");
      return;
    }

    void syncNow(true);
    timer = setInterval(() => {
      void syncNow();
    }, DEFAULT_INTERVAL_MS);
    timer.unref?.();
  }

  function stop() {
    started = false;
    syncGeneration++;
    if (timer) clearInterval(timer);
    timer = null;
    workspaceId = null;
    lastSyncedName = null;
    lastSourceName = null;
    lastResolvedName = null;
    pendingSourceName = null;
    lastError = null;
  }

  pi.on("session_start", async (_event, ctx) => {
    stop();
    start(ctx);
  });

  pi.on("session_shutdown", async () => {
    stop();
  });

  pi.registerCommand("herdr-workspace-summary", {
    description: "Show or force pi session name sync to the current herdr workspace",
    handler: async (args: string, ctx: ExtensionCommandContext) => {
      latestCtx = ctx;
      resolveModel(ctx);

      const command = args.trim().toLowerCase();

      if (command === "restart") {
        stop();
        start(ctx);
        return;
      }

      if (command === "stop") {
        stop();
        if (ctx.hasUI) ctx.ui.notify(`${LOG_PREFIX} stopped`, "info");
        return;
      }

      const setPrefix = "set ";
      if (args.trim().toLowerCase().startsWith(setPrefix)) {
        const name = args.trim().slice(setPrefix.length).trim();
        if (!name) {
          if (ctx.hasUI) ctx.ui.notify(`${LOG_PREFIX} usage: /herdr-workspace-summary set <name>`, "warning");
          return;
        }
        pi.setSessionName(name);
        if (!started) start(ctx);
        const ok = await syncNow(true);
        if (ctx.hasUI) {
          const workspaceName = lastResolvedName ?? fallbackTitle(name);
          ctx.ui.notify(
            ok
              ? `${LOG_PREFIX} session renamed to: ${name} | workspace: ${workspaceName}`
              : `${LOG_PREFIX} session renamed to: ${name}`,
            ok ? "success" : "info"
          );
        }
        return;
      }

      if (!started) start(ctx);

      if (command === "now") {
        const ok = await syncNow(true);
        if (ctx.hasUI) {
          const sessionName = pi.getSessionName() ?? "(none)";
          ctx.ui.notify(
            ok
              ? `${LOG_PREFIX} synced workspace to: ${lastResolvedName ?? formatWorkspaceName(sessionName)}`
              : `${LOG_PREFIX} nothing to sync (workspace=${workspaceId ?? "none"}, session=${sessionName})`,
            ok ? "success" : "info"
          );
        }
        return;
      }

      const sessionName = pi.getSessionName() ?? "(none)";
      const status = started ? "running" : "stopped";
      const pending = pendingSourceName ?? "none";
      const model = resolvedModelName || "auto";
      if (ctx.hasUI) {
        ctx.ui.notify(
          `${LOG_PREFIX} ${status}; workspace=${workspaceId ?? "none"}; session=${sessionName}; title=${lastResolvedName ?? "none"}; pending=${pending}; model=${model}; error=${lastError ?? "none"}`,
          "info"
        );
      }
    },
  });
}
