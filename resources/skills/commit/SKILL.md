---
name: commit
description: Create git commits with clear, imperative English messages. Use this skill when the user asks to commit changes, save progress, or when a natural commit point is reached after completing a task — even if the user doesn't explicitly say "commit".
---

# Commit

Create a git commit from the current working tree changes.

## Steps

1. Run `git status` and `git diff HEAD` to understand what changed.
2. Stage modified and deleted files with `git add -u`.
3. Commit with a short, imperative English message (e.g., "Add feature X", "Fix Y bug").
4. Do not ask for confirmation — commit directly.

## Commit message style

- Imperative mood, present tense ("Add", "Fix", "Update", not "Added", "Fixed", "Updated")
- First line under 72 characters
- Focus on **why** or **what** changed, not how
- No period at the end
- NEVER include Co-Authored-By or any co-authorship trailers
