import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { hasHerdrSocketContext, releaseAgent, sendAgentState } from "./shared";

export function registerHerdrAgentState(pi: ExtensionAPI) {
  if (!hasHerdrSocketContext()) {
    return;
  }

  let agentActive = false;
  let blockedCount = 0;
  let blockedMessage: string | undefined;
  let lastState: "working" | "blocked" | "idle" | undefined;
  let lastMessage: string | undefined;

  function desiredState() {
    if (blockedCount > 0) {
      return { state: "blocked" as const, message: blockedMessage };
    }
    if (agentActive) {
      return { state: "working" as const, message: undefined };
    }
    return { state: "idle" as const, message: undefined };
  }

  function publishState() {
    const next = desiredState();
    if (next.state === lastState && next.message === lastMessage) {
      return;
    }

    lastState = next.state;
    lastMessage = next.message;
    void sendAgentState(next.state, next.message);
  }

  pi.events.on("herdr:blocked", (data) => {
    if (!data?.active) {
      blockedCount = Math.max(0, blockedCount - 1);
      if (blockedCount === 0) {
        blockedMessage = undefined;
      }
      publishState();
      return;
    }

    blockedCount += 1;
    blockedMessage = data.label;
    publishState();
  });

  pi.on("agent_start", () => {
    agentActive = true;
    publishState();
  });

  pi.on("agent_end", () => {
    agentActive = false;
    publishState();
  });

  pi.on("session_shutdown", async () => {
    await releaseAgent();
  });
}
