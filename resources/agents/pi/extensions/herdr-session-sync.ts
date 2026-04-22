import { execFileSync } from "node:child_process";
import type { ExtensionAPI, ExtensionContext, ExtensionCommandContext } from "@mariozechner/pi-coding-agent";

type PaneGetResponse = {
  result?: {
    pane?: {
      workspace_id?: string;
    };
  };
};

const DEFAULT_INTERVAL_MS = 1000;
const MAX_WORKSPACE_NAME_LENGTH = 32;
const WORKSPACE_NAME_ELLIPSIS = "...";
const GENERIC_SESSION_NAMES = new Set(["", "chat"]);

export default function (pi: ExtensionAPI) {
  let timer: NodeJS.Timeout | null = null;
  let workspaceId: string | null = null;
  let lastSyncedName: string | null = null;
  let started = false;

  function debug(ctx: ExtensionContext | ExtensionCommandContext, message: string) {
    if (ctx.hasUI) ctx.ui.notify(`[herdr-sync] ${message}`, "info");
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
    const trimmed = name.trim();
    if (trimmed.length <= MAX_WORKSPACE_NAME_LENGTH) return trimmed;

    return `${trimmed.slice(0, MAX_WORKSPACE_NAME_LENGTH - WORKSPACE_NAME_ELLIPSIS.length).trimEnd()}${WORKSPACE_NAME_ELLIPSIS}`;
  }

  function renameWorkspace(name: string): boolean {
    if (!workspaceId) return false;

    const workspaceName = formatWorkspaceName(name);

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

  function syncNow(): boolean {
    if (!workspaceId) workspaceId = getWorkspaceIdFromHerdr();
    const name = getCurrentSessionName();
    const workspaceName = name ? formatWorkspaceName(name) : null;
    if (!workspaceId || !name || !workspaceName || workspaceName === lastSyncedName) return false;
    return renameWorkspace(name);
  }

  function start(ctx: ExtensionContext | ExtensionCommandContext) {
    if (started) return;
    started = true;
    workspaceId = getWorkspaceIdFromHerdr();
    lastSyncedName = null;

    if (!workspaceId) {
      debug(ctx, "no herdr workspace detected; staying idle");
      return;
    }

    syncNow();
    timer = setInterval(() => {
      syncNow();
    }, DEFAULT_INTERVAL_MS);
    timer.unref?.();
    debug(ctx, `watching workspace ${workspaceId}`);
  }

  function stop() {
    started = false;
    if (timer) clearInterval(timer);
    timer = null;
    workspaceId = null;
    lastSyncedName = null;
  }

  pi.on("session_start", async (_event, ctx) => {
    stop();
    start(ctx);
  });

  pi.on("session_shutdown", async () => {
    stop();
  });

  pi.registerCommand("herdr-sync", {
    description: "Show or force pi session name sync to the current herdr workspace",
    handler: async (args: string, ctx: ExtensionCommandContext) => {
      const command = args.trim().toLowerCase();

      if (command === "restart") {
        stop();
        start(ctx);
        return;
      }

      if (command === "stop") {
        stop();
        if (ctx.hasUI) ctx.ui.notify("[herdr-sync] stopped", "info");
        return;
      }

      const setPrefix = "set ";
      if (args.trim().toLowerCase().startsWith(setPrefix)) {
        const name = args.trim().slice(setPrefix.length).trim();
        if (!name) {
          if (ctx.hasUI) ctx.ui.notify("[herdr-sync] usage: /herdr-sync set <name>", "warning");
          return;
        }
        pi.setSessionName(name);
        if (!started) start(ctx);
        const ok = syncNow();
        if (ctx.hasUI) {
          ctx.ui.notify(
            ok
              ? `[herdr-sync] session renamed to: ${name} | workspace: ${formatWorkspaceName(name)}`
              : `[herdr-sync] session renamed to: ${name}`,
            ok ? "success" : "info"
          );
        }
        return;
      }

      if (!started) start(ctx);

      if (command === "now") {
        const ok = syncNow();
        if (ctx.hasUI) {
          const sessionName = pi.getSessionName() ?? "(none)";
          ctx.ui.notify(
            ok
              ? `[herdr-sync] synced workspace to: ${formatWorkspaceName(sessionName)}`
              : `[herdr-sync] nothing to sync (workspace=${workspaceId ?? "none"}, session=${sessionName})`,
            ok ? "success" : "info"
          );
        }
        return;
      }

      const sessionName = pi.getSessionName() ?? "(none)";
      const status = started ? "running" : "stopped";
      if (ctx.hasUI) {
        ctx.ui.notify(
          `[herdr-sync] ${status}; workspace=${workspaceId ?? "none"}; session=${sessionName}; last=${lastSyncedName ?? "none"}`,
          "info"
        );
      }
    },
  });
}
