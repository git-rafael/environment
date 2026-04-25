---
name: mattpocock-skill-explorer
description: Explore Matt Pocock's agent skill catalog for Pi. Use this when the user asks what mattpocock/skills skills exist, wants more planning, TDD, refactoring, GitHub issue, architecture, or writing skills, or wants help deciding which Matt Pocock skills to add next.
compatibility: Requires the environment repository's Pi settings and the upstream mattpocock/skills package. Some workflow skills expect GitHub CLI, subagents, or project-specific docs to be available.
---

# Matt Pocock Skill Explorer

Use this skill to help the user decide which upstream `mattpocock/skills` skills should be enabled in Pi.

The embedded catalog in this file is only a fallback snapshot and curation guide. Treat the installed `mattpocock/skills` repository as the source of truth whenever the user asks what skills currently exist or what a skill actually does.

## Authoritative lookup workflow

Before giving detailed claims about available skills or exact behavior, inspect the live upstream package that Pi installed:

```bash
# Repository overview, if present
~/.pi/agent/git/github.com/mattpocock/skills/README.md

# Individual skill definitions
~/.pi/agent/git/github.com/mattpocock/skills/*/SKILL.md
```

If the Pi package has not been installed yet, explain that the authoritative local clone will appear after applying Home Manager and starting Pi. If internet access is available, inspect the upstream repository instead. If neither source is available, use the fallback snapshot below and clearly label it as a snapshot.

Also inspect the environment repository to see which skills are currently enabled:

```bash
~/Desktop/Codebase/home/environment/resources/agents/pi/settings.json
```

## How to answer

1. Start from the user's goal, not from the catalog.
2. For current availability or exact behavior, read the live `README.md` and relevant `<skill>/SKILL.md` before answering.
3. Mention which related skills are already part of the curated default set when relevant.
4. Call out side effects: GitHub issue creation, file edits, ADR/context doc updates, pre-commit hook setup, or persistent style changes.
5. If the user wants to add more skills persistently, edit `resources/agents/pi/settings.json` by:
   - keeping the pinned package entry for `git:github.com/mattpocock/skills@60aa99c0230fbac087514ba5fca2ae6e519965fe`;
   - adding explicit paths under the top-level `skills` array, because this repo's skills live at the repo root rather than under a conventional `skills/` directory.
6. Prefer adding specific skills over enabling everything, to keep Pi's skill list focused.
7. Do not assert that a skill exists or does a specific action solely from the fallback snapshot when an authoritative source is available.

## Current curated set

These are the recommended baseline skills for planning, design, and implementation workflows:

```json
[
  "git/github.com/mattpocock/skills/grill-me",
  "git/github.com/mattpocock/skills/tdd",
  "git/github.com/mattpocock/skills/design-an-interface",
  "git/github.com/mattpocock/skills/request-refactor-plan",
  "git/github.com/mattpocock/skills/triage-issue",
  "git/github.com/mattpocock/skills/to-issues",
  "git/github.com/mattpocock/skills/to-prd",
  "git/github.com/mattpocock/skills/zoom-out"
]
```

## Fallback snapshot with guidance

This section is a convenience snapshot from `mattpocock/skills` at commit `60aa99c0230fbac087514ba5fca2ae6e519965fe` plus local curation notes. Use it for orientation, but verify against the live `README.md` or individual `SKILL.md` files before making detailed or current claims.

Legend:

- Recommended: good default candidate.
- Optional: add when the user has that workflow.
- Sensitive: can modify repo workflow, create GitHub issues, or persist communication/style changes; add intentionally.
- Specialized: niche workflow; add when explicitly needed.

### Recommended baseline

| Skill | Guidance | What it covers |
| --- | --- | --- |
| `grill-me` | Recommended | Relentlessly interviews the user about a plan/design, one question at a time, with recommended answers. |
| `tdd` | Recommended | Red-green-refactor TDD, one vertical slice at a time, testing behavior through public interfaces. |
| `design-an-interface` | Recommended | Generates multiple radically different module/API interface designs and compares trade-offs. |
| `request-refactor-plan` | Recommended/sensitive | Interviews for a refactor plan, breaks it into tiny commits, and creates a GitHub issue. |
| `triage-issue` | Recommended/sensitive | Investigates a bug, identifies root cause, and creates a GitHub issue with a TDD fix plan. |
| `to-issues` | Recommended/sensitive | Breaks a plan/PRD into independently grabbable GitHub issues using vertical slices. |
| `to-prd` | Recommended/sensitive | Synthesizes current context into a PRD and creates a GitHub issue. |
| `zoom-out` | Recommended/manual | Gives a higher-level map of relevant modules/callers. `disable-model-invocation` means it is best invoked manually. |

### Strong optional additions

| Skill | Guidance | What it covers |
| --- | --- | --- |
| `domain-model` | Optional/manual | Domain-aware grilling that sharpens terminology and updates `CONTEXT.md`/ADRs as decisions crystallize. |
| `improve-codebase-architecture` | Optional | Finds opportunities to deepen modules, improve seams/adapters, and make code more testable/AI-navigable. |
| `ubiquitous-language` | Optional | Extracts a DDD-style glossary from conversation and saves canonical terms. |
| `github-triage` | Optional/sensitive | Label-based GitHub issue triage workflow for preparing issues for agents. |
| `qa` | Optional/sensitive | Conversational QA session where reported bugs/issues become GitHub issues. |
| `write-a-skill` | Optional | Creates new agent skills with progressive disclosure and bundled resources. |

### Specialized or usually leave out initially

| Skill | Guidance | What it covers |
| --- | --- | --- |
| `caveman` | Sensitive/style | Ultra-compressed persistent communication mode until disabled. Useful but globally changes response style. |
| `edit-article` | Specialized | Edits articles for clarity, structure, and prose quality. |
| `obsidian-vault` | Specialized | Searches, creates, and organizes notes in an Obsidian vault with wikilinks. |
| `scaffold-exercises` | Specialized | Creates exercise directory structures for course content. |
| `migrate-to-shoehorn` | Specialized | Migrates TypeScript test files from `as` assertions to `@total-typescript/shoehorn`. |
| `setup-pre-commit` | Sensitive/project-specific | Sets up Husky, lint-staged, Prettier, type checking, and tests. |
| `git-guardrails-claude-code` | Specialized/Claude-specific | Sets up Claude Code hooks to block dangerous git commands. Not generally useful for Pi. |

## Persistent addition template

Before adding a skill, verify the directory exists in the live upstream package. Then preserve the pinned package and append only the desired path under top-level `skills`:

```json
{
  "packages": [
    {
      "source": "git:github.com/mattpocock/skills@60aa99c0230fbac087514ba5fca2ae6e519965fe",
      "extensions": [],
      "skills": [],
      "prompts": [],
      "themes": []
    }
  ],
  "skills": [
    "git/github.com/mattpocock/skills/grill-me",
    "git/github.com/mattpocock/skills/example-to-add"
  ]
}
```

After editing the environment repo, validate Home Manager and remind the user to commit before applying with `env-load user notebook ~/Desktop/Codebase/home/environment`.
