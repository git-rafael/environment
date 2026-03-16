---
name: skill-finder
description: Search for and discover AI agent skills from the skills.sh marketplace. Use this skill whenever the user wants to find, search for, discover, or browse skills for Claude Code or other AI agents — even if they just say something like "is there a skill for X?" or "find me something that helps with Y". Also trigger when the user mentions skills.sh directly.
---

# Skill Finder

Search the [skills.sh](https://skills.sh) marketplace to discover reusable skills for AI agents like Claude Code, Cursor, Copilot, and others.

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

After showing the results, ask if they want to install any of them. To install, the user needs:

1. A local clone of the `git-rafael/environment` repository
2. The `env-load` CLI (which is part of that repo)

The install command uses `env-load refs add`, which adds an upstream GitHub repo as a sparse-checkout submodule under `.refs/` and creates a symlink in `resources/skills/`:

```bash
env-load refs add <source> <path-to-skill>
```

Where `<source>` is the `source` field from the API (e.g. `vercel-labs/agent-skills`) and `<path-to-skill>` is the path within that repo to the skill directory.

**The `id` field is NOT always the correct repo path.** The API `id` is `<source>/<skill-name>`, but skills are often nested inside a subdirectory (e.g. `skills/skill-name`). Always verify the actual path before presenting the install command.

### Verifying the correct repo path

Before suggesting the install command, check the repo's directory structure via the GitHub API:

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
env-load refs add vercel-labs/agent-browser skills/agent-browser
# NOT: env-load refs add vercel-labs/agent-browser agent-browser  ← broken symlink
```

Do NOT run the install command yourself — present it to the user and let them run it, since it modifies git submodules and the repo state.

## Tips

- If the search returns no results, suggest the user try broader or alternative terms.
- If the query is vague, try a couple of related searches to give broader coverage (e.g., if the user asks for "testing", also try "test" or "unittest").
- Format install counts with thousands separators for readability (e.g., 207,832 not 207832).
