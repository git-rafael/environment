import { execFileSync, spawnSync } from "node:child_process";
import { readFileSync } from "node:fs";
import type { ExtensionAPI, ExtensionCommandContext } from "@mariozechner/pi-coding-agent";

function isUsableShell(shell: string | undefined): shell is string {
  return !!shell?.trim() && !/(^|\/)env-agent$/.test(shell) && !/(^|\/)pi$/.test(shell);
}

function readPasswdShell(user: string): string | undefined {
  try {
    const passwd = readFileSync("/etc/passwd", "utf8");
    const line = passwd.split("\n").find((entry) => entry.startsWith(`${user}:`));
    const shell = line?.split(":")[6]?.trim();
    return isUsableShell(shell) ? shell : undefined;
  } catch {
    return undefined;
  }
}

function getRegisteredUserShell(): string | undefined {
  const user = process.env.USER?.trim() || process.env.LOGNAME?.trim();
  if (!user) return undefined;

  try {
    const entry = execFileSync("getent", ["passwd", user], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
    const shell = entry.split(":")[6]?.trim();
    if (isUsableShell(shell)) return shell;
  } catch {
    // ignore
  }

  const passwdShell = readPasswdShell(user);
  if (passwdShell) return passwdShell;

  try {
    const output = execFileSync("dscl", [".", "-read", `/Users/${user}`, "UserShell"], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    });
    const shell = output.split(":").slice(1).join(":").trim();
    if (isUsableShell(shell)) return shell;
  } catch {
    // ignore
  }

  return undefined;
}

function resolveShell(): string {
  const configured = process.env.PI_SHELL?.trim();
  if (configured) return configured;

  // Intentionally ignore SHELL here because this machine uses env-agent for other flows.
  return getRegisteredUserShell() ?? "bash";
}

function runShell(shell: string, args: string, options?: { login?: boolean }) {
  const env = { ...process.env, SHELL: shell };
  const interactiveFlag = options?.login ? "-il" : "-i";
  const commandFlag = options?.login ? "-lc" : "-c";

  return args.trim()
    ? spawnSync(shell, [commandFlag, args], {
        stdio: "inherit",
        env,
      })
    : spawnSync(shell, [interactiveFlag], {
        stdio: "inherit",
        env,
      });
}

async function shellHandler(args: string, ctx: ExtensionCommandContext) {
  if (!ctx.hasUI) {
    ctx.shutdown();
    return;
  }

  const shell = resolveShell();

  await ctx.ui.custom((tui, _theme, _kb, done) => {
    tui.stop();
    process.stdout.write("\x1b[2J\x1b[H");

    runShell(shell, args, { login: true });

    done(0);
    return {
      render: () => [],
      invalidate: () => {},
    };
  });

  ctx.shutdown();
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("shell", {
    description: "Open an interactive shell; exiting it also exits pi",
    handler: shellHandler,
  });

  pi.registerCommand("sh", {
    description: "Alias for /shell",
    handler: shellHandler,
  });
}
