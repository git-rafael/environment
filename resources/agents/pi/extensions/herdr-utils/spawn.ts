import type { ExtensionAPI, ExtensionCommandContext } from "@mariozechner/pi-coding-agent";
import {
  extractError,
  getPaneId,
  getWorkspaceIdFromCurrentPane,
  notify,
  runHerdr,
  runHerdrJson,
  sleep,
  type HerdrResponse,
  type NotifyLevel,
} from "./shared";

type SpawnTarget = "pi" | "shell";
type SpawnLocation = "right" | "down" | "tab" | "workspace";

const LOG_PREFIX = "[herdr-spawn]";
const PANE_READY_TIMEOUT_MS = 15000;
const PANE_READY_POLL_MS = 100;
const USAGE = [
  "usage: /spawn <pi|sh> <right|down|tab|workspace>",
  "examples: /spawn pi right | /spawn pi tab | /spawn sh workspace",
  "extra: /spawn status",
].join(" ");

export function registerHerdrSpawn(pi: ExtensionAPI) {
  function notifySpawn(ctx: { hasUI: boolean; ui: { notify(message: string, level?: NotifyLevel): void } }, message: string, level: NotifyLevel = "info") {
    notify(ctx, LOG_PREFIX, message, level);
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

  function getCommandForTarget(target: SpawnTarget): string | null {
    if (target === "pi") return null;
    return "/shell";
  }

  function waitForPaneReady(paneId: string) {
    const deadline = Date.now() + PANE_READY_TIMEOUT_MS;
    let lastStatus = "unknown";

    while (Date.now() < deadline) {
      const parsed = runHerdrJson<HerdrResponse>(["pane", "get", paneId]);
      const status = parsed.result?.pane?.agent_status?.trim() || "unknown";
      lastStatus = status;

      if (status === "idle") return;

      sleep(PANE_READY_POLL_MS);
    }

    throw new Error(`pane ${paneId} did not become ready (last agent status: ${lastStatus})`);
  }

  function createDestinationPane(location: SpawnLocation, cwd: string): string {
    if (location === "right" || location === "down") {
      const paneId = getPaneId();
      if (!paneId) throw new Error("current pi is not running inside a herdr pane");

      const parsed = runHerdrJson<HerdrResponse>(["pane", "split", paneId, "--direction", location, "--cwd", cwd]);
      const newPaneId = parsed.result?.pane?.pane_id?.trim();
      if (!newPaneId) throw new Error(`herdr did not return a pane id for split ${location}`);
      return newPaneId;
    }

    if (location === "tab") {
      const workspaceId = getWorkspaceIdFromCurrentPane();
      if (!workspaceId) throw new Error("could not resolve the current herdr workspace");

      const parsed = runHerdrJson<HerdrResponse>(["tab", "create", "--workspace", workspaceId, "--cwd", cwd]);
      const newPaneId = parsed.result?.root_pane?.pane_id?.trim();
      if (!newPaneId) throw new Error("herdr did not return the root pane for the new tab");
      return newPaneId;
    }

    const parsed = runHerdrJson<HerdrResponse>(["workspace", "create", "--cwd", cwd]);
    const newPaneId = parsed.result?.root_pane?.pane_id?.trim();
    if (!newPaneId) throw new Error("herdr did not return the root pane for the new workspace");
    return newPaneId;
  }

  function spawn(target: SpawnTarget, location: SpawnLocation, cwd: string) {
    const paneId = createDestinationPane(location, cwd);
    const command = getCommandForTarget(target);

    if (command) {
      waitForPaneReady(paneId);
      runHerdr(["pane", "run", paneId, command]);
    }

    return `started ${target === "pi" ? "pi" : "shell"} in ${location} from ${cwd}`;
  }

  pi.registerCommand("spawn", {
    description: "Create a herdr pane/tab/workspace and open pi or /shell",
    handler: async (args: string, ctx: ExtensionCommandContext) => {
      const trimmed = args.trim();

      if (!trimmed || trimmed.toLowerCase() === "help") {
        notifySpawn(ctx, USAGE, "info");
        return;
      }

      if (trimmed.toLowerCase() === "status") {
        const paneId = getPaneId();
        const workspaceId = paneId ? getWorkspaceIdFromCurrentPane() : null;
        notifySpawn(
          ctx,
          `pane=${paneId ?? "none"}; workspace=${workspaceId ?? "none"}; cwd=${ctx.cwd}`,
          paneId ? "info" : "warning"
        );
        return;
      }

      const parts = trimmed.split(/\s+/).filter(Boolean);
      if (parts.length !== 2) {
        notifySpawn(ctx, USAGE, "warning");
        return;
      }

      const target = normalizeTarget(parts[0]);
      const location = normalizeLocation(parts[1]);

      if (!target || !location) {
        notifySpawn(ctx, USAGE, "warning");
        return;
      }

      try {
        notifySpawn(ctx, spawn(target, location, ctx.cwd), "success");
      } catch (error) {
        notifySpawn(ctx, `failed: ${extractError(error)}`, "error");
      }
    },
  });

  function registerSpawnShortcut(shortcut: string, description: string, target: SpawnTarget, location: SpawnLocation) {
    pi.registerShortcut(shortcut, {
      description,
      handler: async (ctx) => {
        try {
          notifySpawn(ctx, spawn(target, location, ctx.cwd), "success");
        } catch (error) {
          notifySpawn(ctx, `failed: ${extractError(error)}`, "error");
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
