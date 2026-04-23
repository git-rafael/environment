// installed by herdr
// safe to edit. this integration only activates inside herdr-managed panes.
// @ts-nocheck

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { registerHerdrAgentState } from "./agent-state";
import { registerHerdrSpawn } from "./spawn";
import { registerHerdrWorkspaceSummary } from "./workspace-summary";

export default function (pi: ExtensionAPI) {
  registerHerdrAgentState(pi);
  registerHerdrSpawn(pi);
  registerHerdrWorkspaceSummary(pi);
}
