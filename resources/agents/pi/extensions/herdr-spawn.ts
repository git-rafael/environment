import { execFileSync } from "node:child_process";
import type { ExtensionAPI, ExtensionCommandContext } from "@mariozechner/pi-coding-agent";

type SpawnTarget = "pi" | "shell";
type SpawnLocation = "right" | "down" | "tab" | "workspace";
type NotifyLevel = "info" | "success" | "warning" | "error";

type PaneRef = {
  pane_id?: string;
  tab_id?: string;
  workspace_id?: string;
};

type HerdrResponse = {
  result?: {
    pane?: PaneRef;
    root_pane?: PaneRef;
    tab?: {
      tab_id?: string;
      workspace_id?: string;
    };
    workspace?: {
      workspace_id?: string;
    };
  };
};

const LOG_PREFIX = "[herdr-spawn]";
const DEFAULT_TIMEOUT_MS = 5000;
const USAGE = [
  "usage: /spawn <pi|sh> <right|down|tab|workspace>",
  "examples: /spawn pi right | /spawn pi tab | /spawn sh workspace",
  "extra: /spawn status",
].join(" ");

export default function (pi: ExtensionAPI) {
  function notify(ctx: { hasUI: boolean; ui: { notify(message: string, level?: NotifyLevel): void } }, message: string, level: NotifyLevel = "info") {
    if (ctx.hasUI) ctx.ui.notify(`${LOG_PREFIX} ${message}`, level);
  }

  function extractError(error: unknown): string {
    if (error && typeof error === "object") {
      const maybeError = error as {
        stderr?: string | Buffer;
        stdout?: string | Buffer;
        message?: string;
      };

      const stderr = maybeError.stderr?.toString().trim();
      if (stderr) return stderr;

      const stdout = maybeError.stdout?.toString().trim();
      if (stdout) return stdout;

      if (maybeError.message) return maybeError.message;
    }

    return String(error);
  }

  function runHerdr(args: string[]): string {
    return execFileSync("herdr", args, {
      encoding: "utf8",
      timeout: DEFAULT_TIMEOUT_MS,
      env: process.env,
    });
  }

  function runHerdrJson(args: string[]): HerdrResponse {
    const stdout = runHerdr(args).trim();
    if (!stdout) throw new Error(`herdr returned no JSON for: ${args.join(" ")}`);
    return JSON.parse(stdout) as HerdrResponse;
  }

  function getCurrentPaneId(): string | null {
    return process.env.HERDR_PANE_ID?.trim() || null;
  }

  function getCurrentWorkspaceId(): string | null {
    const paneId = getCurrentPaneId();
    if (!paneId) return null;

    const parsed = runHerdrJson(["pane", "get", paneId]);
    return parsed.result?.pane?.workspace_id?.trim() || null;
  }

  function normalizeTarget(value: string): SpawnTarget | null {
    switch (value.trim().toLowerCase()) {
      case "pi":
        return "pi";
      case "sh":
      case "shell":
      case "zsh":
        return "shell";
      default:
        return null;
    }
  }

  function normalizeLocation(value: string): SpawnLocation | null {
    switch (value.trim().toLowerCase()) {
      case "right":
      case "r":
        return "right";
      case "down":
      case "d":
        return "down";
      case "tab":
      case "t":
        return "tab";
      case "workspace":
      case "ws":
      case "w":
        return "workspace";
      default:
        return null;
    }
  }

  function getCommandForTarget(target: SpawnTarget): string {
    if (target === "pi") return "env-agent";
    return "env-shell";
  }

  function createDestinationPane(location: SpawnLocation, cwd: string): string {
    if (location === "right" || location === "down") {
      const paneId = getCurrentPaneId();
      if (!paneId) throw new Error("current pi is not running inside a herdr pane");

      const parsed = runHerdrJson(["pane", "split", paneId, "--direction", location, "--cwd", cwd]);
      const newPaneId = parsed.result?.pane?.pane_id?.trim();
      if (!newPaneId) throw new Error(`herdr did not return a pane id for split ${location}`);
      return newPaneId;
    }

    if (location === "tab") {
      const workspaceId = getCurrentWorkspaceId();
      if (!workspaceId) throw new Error("could not resolve the current herdr workspace");

      const parsed = runHerdrJson(["tab", "create", "--workspace", workspaceId, "--cwd", cwd]);
      const newPaneId = parsed.result?.root_pane?.pane_id?.trim();
      if (!newPaneId) throw new Error("herdr did not return the root pane for the new tab");
      return newPaneId;
    }

    const parsed = runHerdrJson(["workspace", "create", "--cwd", cwd]);
    const newPaneId = parsed.result?.root_pane?.pane_id?.trim();
    if (!newPaneId) throw new Error("herdr did not return the root pane for the new workspace");
    return newPaneId;
  }

  function spawn(target: SpawnTarget, location: SpawnLocation, cwd: string) {
    const paneId = createDestinationPane(location, cwd);
    runHerdr(["pane", "run", paneId, getCommandForTarget(target)]);
    return `started ${target === "pi" ? "pi" : "shell"} in ${location} from ${cwd}`;
  }

  pi.registerCommand("spawn", {
    description: "Create a herdr pane/tab/workspace and start pi or a shell",
    handler: async (args: string, ctx: ExtensionCommandContext) => {
      const trimmed = args.trim();

      if (!trimmed || trimmed.toLowerCase() === "help") {
        notify(ctx, USAGE, "info");
        return;
      }

      if (trimmed.toLowerCase() === "status") {
        const paneId = getCurrentPaneId();
        const workspaceId = paneId ? getCurrentWorkspaceId() : null;
        notify(
          ctx,
          `pane=${paneId ?? "none"}; workspace=${workspaceId ?? "none"}; cwd=${ctx.cwd}`,
          paneId ? "info" : "warning"
        );
        return;
      }

      const parts = trimmed.split(/\s+/).filter(Boolean);
      if (parts.length !== 2) {
        notify(ctx, USAGE, "warning");
        return;
      }

      const target = normalizeTarget(parts[0]);
      const location = normalizeLocation(parts[1]);

      if (!target || !location) {
        notify(ctx, USAGE, "warning");
        return;
      }

      try {
        notify(ctx, spawn(target, location, ctx.cwd), "success");
      } catch (error) {
        notify(ctx, `failed: ${extractError(error)}`, "error");
      }
    },
  });

  function registerSpawnShortcut(shortcut: string, description: string, target: SpawnTarget, location: SpawnLocation) {
    pi.registerShortcut(shortcut, {
      description,
      handler: async (ctx) => {
        try {
          notify(ctx, spawn(target, location, ctx.cwd), "success");
        } catch (error) {
          notify(ctx, `failed: ${extractError(error)}`, "error");
        }
      },
    });
  }

  registerSpawnShortcut("ctrl+shift+right", "Spawn pi in a pane to the right", "pi", "right");
  registerSpawnShortcut("ctrl+shift+down", "Spawn pi in a pane below", "pi", "down");
  registerSpawnShortcut("ctrl+shift+up", "Spawn pi in a new tab", "pi", "tab");
  registerSpawnShortcut("ctrl+shift+enter", "Spawn pi in a new workspace", "pi", "workspace");

  registerSpawnShortcut("ctrl+shift+alt+right", "Spawn shell in a pane to the right", "shell", "right");
  registerSpawnShortcut("ctrl+shift+alt+down", "Spawn shell in a pane below", "shell", "down");
  registerSpawnShortcut("ctrl+shift+alt+up", "Spawn shell in a new tab", "shell", "tab");
  registerSpawnShortcut("ctrl+shift+alt+enter", "Spawn shell in a new workspace", "shell", "workspace");
}
