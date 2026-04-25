---
name: skill-finder
description: Search for and discover AI agent skills from the skills.sh marketplace, then help decide whether and how to wire them into Pi. Use this skill whenever the user wants to find, search for, discover, or browse skills for Pi or other AI agents — even if they just say something like "is there a skill for X?" or "find me something that helps with Y". Also trigger when the user mentions skills.sh directly.
---

# Skill Finder

Search the [skills.sh](https://skills.sh) marketplace to discover reusable skills for Pi and other AI agents, then map the selected skill to this repository's Pi installation model when the user wants it persisted.

## How it works

The skills.sh API provides a single search endpoint. You query it, get back matching skills ranked by relevance, and present them to the user sorted by popularity (install count).

## Search workflow

### 1. Get the query from the user

If the user already provided a search term, use it directly. Otherwise, ask what kind of skill they're looking for.

### 2. Call the API

Use `curl` to hit the search endpoint:

```bash
curl -s "https://skills.sh/api/search?q=<URL_ENCODED_QUERY>&limit=10"
```

The response is JSON with this structure:

```json
{
  "query": "react",
  "searchType": "fuzzy",
  "skills": [
    {
      "id": "vercel-labs/agent-skills/vercel-react-best-practices",
      "skillId": "vercel-react-best-practices",
      "name": "vercel-react-best-practices",
      "installs": 207832,
      "source": "vercel-labs/agent-skills"
    }
  ],
  "count": 10,
  "duration_ms": 37
}
```

### 3. Parse and sort

Use `jq` to extract and sort results by install count (descending):

```bash
curl -s "https://skills.sh/api/search?q=<QUERY>&limit=10" | jq -r '.skills | sort_by(-.installs) | .[] | "\(.installs)\t\(.name)\t\(.source)"'
```

### 4. Present results

Show results in a clean table format:

| # | Skill | Source | Installs |
|---|-------|--------|----------|
| 1 | skill-name | owner/repo | 12,345 |

### 5. Let the user choose

After showing the results, ask if they want to persist any of them in the environment repo.

For this repo, persistent Pi installation now works by:

1. adding the upstream repo under `resources/agents/pi/settings.json` in the `packages` list
2. adding an explicit `skills` path there if package discovery is not enough

Skills are not shared across coding agents by default in this repository; non-Pi agents use their native skill locations unless the user explicitly asks otherwise.

**The `id` field is NOT always the correct repo path.** The API `id` is `<source>/<skill-name>`, but skills are often nested inside a subdirectory (e.g. `skills/skill-name`). Always verify the actual path before suggesting the persistent wiring.

### Verifying the correct repo path

Before suggesting the persistent wiring, check the repo's directory structure via the GitHub API:

```bash
curl -s "https://api.github.com/repos/<org>/<repo>/contents/" | jq -r '.[] | "\(.type)\t\(.name)"'
```

If the root listing doesn't show the skill directory directly, look for a `skills/` or similar subdirectory and check inside it:

```bash
curl -s "https://api.github.com/repos/<org>/<repo>/contents/skills" | jq -r '.[] | "\(.type)\t\(.name)"'
```

Use whichever path actually contains the skill's `SKILL.md`.

**Example:**
```bash
# Repo vercel-labs/agent-browser has skills under skills/, not at root:
source: vercel-labs/agent-browser
repo skill path: skills/agent-browser
```

When the user wants to persist the result, hand off to the `environment-change` skill to update `resources/agents/pi/settings.json` and `sources/agents.nix`. Do not invent `.refs` or submodule steps.

## Tips

- If the search returns no results, suggest the user try broader or alternative terms.
- If the query is vague, try a couple of related searches to give broader coverage (e.g., if the user asks for "testing", also try "test" or "unittest").
- Format install counts with thousands separators for readability (e.g., 207,832 not 207832).
