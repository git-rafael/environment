import { execFileSync } from "node:child_process";
import { createConnection } from "node:net";
import type { ExtensionCommandContext, ExtensionContext } from "@mariozechner/pi-coding-agent";

export type NotifyLevel = "info" | "success" | "warning" | "error";
export type HerdrState = "working" | "blocked" | "idle";
export type HerdrContext = ExtensionContext | ExtensionCommandContext;
export type HerdrUiContext = {
  hasUI: boolean;
  ui: {
    notify(message: string, level?: NotifyLevel): void;
  };
};

export type PaneRef = {
  pane_id?: string;
  tab_id?: string;
  workspace_id?: string;
  agent_status?: string;
};

export type HerdrResponse = {
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

export const HERDR_SOURCE = "herdr:pi";
export const HERDR_AGENT = "pi";
export const DEFAULT_HERDR_TIMEOUT_MS = 5000;
export const DEFAULT_SOCKET_TIMEOUT_MS = 500;

export function isHerdrEnvironment(): boolean {
  return process.env.HERDR_ENV === "1";
}

export function getSocketPath(): string | null {
  return process.env.HERDR_SOCKET_PATH?.trim() || null;
}

export function getPaneId(): string | null {
  return process.env.HERDR_PANE_ID?.trim() || null;
}

export function hasHerdrSocketContext(): boolean {
  return isHerdrEnvironment() && !!getSocketPath() && !!getPaneId();
}

export function runHerdr(args: string[], timeout = DEFAULT_HERDR_TIMEOUT_MS): string {
  return execFileSync("herdr", args, {
    encoding: "utf8",
    timeout,
    env: process.env,
  });
}

export function runHerdrJson<T extends HerdrResponse = HerdrResponse>(args: string[], timeout = DEFAULT_HERDR_TIMEOUT_MS): T {
  const stdout = runHerdr(args, timeout).trim();
  if (!stdout) {
    throw new Error(`herdr returned no JSON for: ${args.join(" ")}`);
  }

  return JSON.parse(stdout) as T;
}

export function getWorkspaceIdFromCurrentPane(): string | null {
  const paneId = getPaneId();
  if (!paneId) return null;

  const parsed = runHerdrJson(["pane", "get", paneId]);
  return parsed.result?.pane?.workspace_id?.trim() || null;
}

export function sleep(ms: number) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
}

export function notify(ctx: HerdrUiContext, prefix: string, message: string, level: NotifyLevel = "info") {
  if (ctx.hasUI) ctx.ui.notify(`${prefix} ${message}`, level);
}

export function extractError(error: unknown): string {
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

export function sendSocketRequest(request: unknown, timeout = DEFAULT_SOCKET_TIMEOUT_MS): Promise<void> {
  if (!hasHerdrSocketContext()) {
    return Promise.resolve();
  }

  const socketPath = getSocketPath();
  if (!socketPath) {
    return Promise.resolve();
  }

  return new Promise((resolve) => {
    let done = false;
    let socket: ReturnType<typeof createConnection> | undefined;
    let timeoutId: NodeJS.Timeout | undefined;

    const finish = () => {
      if (done) return;
      done = true;
      if (timeoutId) clearTimeout(timeoutId);
      socket?.destroy();
      resolve();
    };

    socket = createConnection(socketPath);
    socket.on("error", finish);
    socket.on("connect", () => socket?.write(`${JSON.stringify(request)}\n`));
    socket.on("data", finish);
    socket.on("end", finish);

    timeoutId = setTimeout(finish, timeout);
    timeoutId.unref?.();
  });
}

export function sendAgentState(state: HerdrState, message?: string): Promise<void> {
  return sendSocketRequest({
    id: `${HERDR_SOURCE}:${Date.now()}:${Math.random().toString(36).slice(2)}`,
    method: "pane.report_agent",
    params: {
      pane_id: getPaneId(),
      source: HERDR_SOURCE,
      agent: HERDR_AGENT,
      state,
      message,
    },
  });
}

export function releaseAgent(): Promise<void> {
  return sendSocketRequest({
    id: `${HERDR_SOURCE}:release:${Date.now()}:${Math.random().toString(36).slice(2)}`,
    method: "pane.release_agent",
    params: {
      pane_id: getPaneId(),
      source: HERDR_SOURCE,
      agent: HERDR_AGENT,
    },
  });
}
