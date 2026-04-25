---
name: gws-skill-explorer
description: Explore the Google Workspace CLI skill catalog for Pi. Use this when the user asks what Google Workspace, gws, Gmail, Drive, Sheets, Calendar, Docs, Chat, Meet, Forms, Tasks, personas, recipes, or additional Google skills are available, or when they want to decide which googleworkspace/cli skills to add next.
compatibility: Requires the environment repository's Pi settings and the upstream googleworkspace/cli package. The actual Google Workspace task skills require the gws binary and authentication.
---

# Google Workspace Skill Explorer

Use this skill to help the user decide which upstream `googleworkspace/cli` skills should be enabled in Pi.

The embedded catalog in this file is only a fallback snapshot and curation guide. Treat the installed `googleworkspace/cli` repository as the source of truth whenever the user asks what skills currently exist or what a skill actually does.

## Authoritative lookup workflow

Before giving detailed claims about available skills or exact behavior, inspect the live upstream package that Pi installed:

```bash
# Main generated index, if present
~/.pi/agent/git/github.com/googleworkspace/cli/docs/skills.md

# Individual skill definitions
~/.pi/agent/git/github.com/googleworkspace/cli/skills/*/SKILL.md
```

If the Pi package has not been installed yet, explain that the authoritative local clone will appear after applying Home Manager and starting Pi. If internet access is available, inspect the upstream repository instead. If neither source is available, use the fallback snapshot below and clearly label it as a snapshot.

Also inspect the environment repository to see which skills are currently enabled:

```bash
~/Desktop/Codebase/home/environment/resources/agents/pi/settings.json
```

## How to answer

1. Start from the user's goal, not from the catalog.
2. For current availability or exact behavior, read `docs/skills.md` and the relevant `skills/<name>/SKILL.md` from the live `googleworkspace/cli` clone before answering.
3. Mention which related skills are already part of the curated default set when relevant.
4. For skills that perform writes, sends, sharing, forwarding, permission changes, or admin actions, call out the risk and recommend explicit confirmation before execution.
5. If the user wants to add more skills persistently, edit `resources/agents/pi/settings.json` in the environment repository by adding paths under the `git:github.com/googleworkspace/cli@v0.22.5` package `skills` array.
6. Prefer adding specific skills over enabling the whole catalog, to keep Pi's skill list focused.
7. Do not assert that a skill exists or does a specific action solely from the fallback snapshot when an authoritative source is available.

## Current curated set

These are the recommended baseline skills for everyday productivity:

```json
[
  "skills/gws-shared",
  "skills/gws-drive",
  "skills/gws-sheets",
  "skills/gws-gmail",
  "skills/gws-calendar",
  "skills/gws-docs",
  "skills/gws-tasks",
  "skills/gws-chat",
  "skills/gws-workflow",
  "skills/gws-drive-upload",
  "skills/gws-sheets-read",
  "skills/gws-sheets-append",
  "skills/gws-gmail-triage",
  "skills/gws-gmail-read",
  "skills/gws-gmail-send",
  "skills/gws-gmail-reply",
  "skills/gws-calendar-agenda",
  "skills/gws-calendar-insert",
  "skills/gws-docs-write",
  "skills/gws-chat-send",
  "skills/gws-workflow-standup-report",
  "skills/gws-workflow-meeting-prep",
  "skills/gws-workflow-email-to-task",
  "skills/gws-workflow-weekly-digest",
  "skills/recipe-find-free-time",
  "skills/recipe-review-overdue-tasks",
  "skills/recipe-backup-sheet-as-csv",
  "skills/recipe-compare-sheet-tabs",
  "skills/recipe-block-focus-time",
  "skills/recipe-plan-weekly-schedule"
]
```

## Fallback snapshot with guidance

This section is a convenience snapshot from `googleworkspace/cli` v0.22.5 plus local curation notes. Use it for orientation, but verify against the live `docs/skills.md` or individual `SKILL.md` files before making detailed or current claims.

Legend:

- Recommended: good default candidate.
- Optional: add when the user has that workflow.
- Sensitive: can expose data, notify others, change permissions, or perform admin-like actions; add only intentionally.
- Specialized: niche workflow; add when explicitly needed.

### Services

| Skill | Guidance | What it covers |
| --- | --- | --- |
| `skills/gws-shared` | Recommended, prerequisite | Auth, global flags, CLI syntax, safety rules. |
| `skills/gws-drive` | Recommended | Files, folders, shared drives. |
| `skills/gws-sheets` | Recommended | Read/write Google Sheets. |
| `skills/gws-gmail` | Recommended but sensitive | Send, read, and manage email. |
| `skills/gws-calendar` | Recommended | Calendars and events. |
| `skills/gws-admin-reports` | Sensitive | Workspace Admin audit logs and usage reports. |
| `skills/gws-docs` | Recommended | Read and write Google Docs. |
| `skills/gws-slides` | Optional | Read/write presentations. |
| `skills/gws-tasks` | Recommended | Google task lists and tasks. |
| `skills/gws-people` | Optional/sensitive | Contacts and profiles. |
| `skills/gws-chat` | Recommended but write-capable | Chat spaces and messages. |
| `skills/gws-classroom` | Specialized | Classroom courses and rosters. |
| `skills/gws-forms` | Optional | Google Forms. |
| `skills/gws-keep` | Optional | Google Keep notes. |
| `skills/gws-meet` | Optional | Meet conferences. |
| `skills/gws-events` | Specialized | Workspace event subscriptions. |
| `skills/gws-modelarmor` | Specialized | Google Model Armor content filtering. |
| `skills/gws-workflow` | Recommended | Cross-service productivity workflows. |
| `skills/gws-script` | Specialized/sensitive | Apps Script project management. |

### Helpers

| Skill | Guidance | What it covers |
| --- | --- | --- |
| `skills/gws-drive-upload` | Recommended | Upload files to Drive. |
| `skills/gws-sheets-append` | Recommended | Append rows to a spreadsheet. |
| `skills/gws-sheets-read` | Recommended | Read values from Sheets. |
| `skills/gws-gmail-send` | Recommended but sensitive | Send email. |
| `skills/gws-gmail-triage` | Recommended | Summarize unread inbox. |
| `skills/gws-gmail-reply` | Recommended but sensitive | Reply in an email thread. |
| `skills/gws-gmail-reply-all` | Sensitive | Reply-all in a thread. |
| `skills/gws-gmail-forward` | Sensitive | Forward messages. |
| `skills/gws-gmail-read` | Recommended/sensitive | Read email body and headers. |
| `skills/gws-gmail-watch` | Specialized | Watch new mail as NDJSON stream. |
| `skills/gws-calendar-insert` | Recommended | Create calendar events. |
| `skills/gws-calendar-agenda` | Recommended | Show upcoming events. |
| `skills/gws-docs-write` | Recommended | Append text to Docs. |
| `skills/gws-chat-send` | Recommended but sensitive | Send Chat messages. |
| `skills/gws-events-subscribe` | Specialized | Subscribe to Workspace events. |
| `skills/gws-events-renew` | Specialized | Renew/reactivate event subscriptions. |
| `skills/gws-modelarmor-sanitize-prompt` | Specialized | Sanitize prompts through Model Armor. |
| `skills/gws-modelarmor-sanitize-response` | Specialized | Sanitize responses through Model Armor. |
| `skills/gws-modelarmor-create-template` | Specialized | Create Model Armor templates. |
| `skills/gws-workflow-standup-report` | Recommended | Today's meetings plus open tasks. |
| `skills/gws-workflow-meeting-prep` | Recommended | Prepare agenda, attendees, and linked docs. |
| `skills/gws-workflow-email-to-task` | Recommended | Convert Gmail messages to Tasks. |
| `skills/gws-workflow-weekly-digest` | Recommended | Weekly meetings plus unread email count. |
| `skills/gws-workflow-file-announce` | Optional/sensitive | Announce Drive file in Chat. |
| `skills/gws-script-push` | Specialized/sensitive | Push local files to Apps Script. |

### Personas

Personas are broad role bundles. Add them only when the user wants the agent to lean into a role across multiple Workspace apps.

| Skill | Guidance | What it covers |
| --- | --- | --- |
| `skills/persona-exec-assistant` | Optional/sensitive | Executive schedule, inbox, communications. |
| `skills/persona-project-manager` | Optional | Tasks, meetings, docs for project coordination. |
| `skills/persona-hr-coordinator` | Specialized/sensitive | HR onboarding and employee communications. |
| `skills/persona-sales-ops` | Specialized | Sales workflows and client communications. |
| `skills/persona-it-admin` | Sensitive | IT administration and Workspace configuration. |
| `skills/persona-content-creator` | Optional | Create and distribute Workspace content. |
| `skills/persona-customer-support` | Specialized | Support tickets, responses, escalations. |
| `skills/persona-event-coordinator` | Optional | Event planning and logistics. |
| `skills/persona-team-lead` | Optional | Standups, team tasks, coordination. |
| `skills/persona-researcher` | Optional | Research notes, references, collaboration. |

### Recipes

Recipes are multi-step workflows. They are powerful, so inspect their steps and ask for confirmation before write/share/send operations.

| Skill | Guidance | What it covers |
| --- | --- | --- |
| `skills/recipe-label-and-archive-emails` | Optional/sensitive | Label matching Gmail messages and archive them. |
| `skills/recipe-draft-email-from-doc` | Optional | Use a Doc as email content. |
| `skills/recipe-organize-drive-folder` | Optional/sensitive | Create/move Drive folders and files. |
| `skills/recipe-share-folder-with-team` | Sensitive | Share folders and contents with collaborators. |
| `skills/recipe-email-drive-link` | Optional/sensitive | Share Drive file and email link. |
| `skills/recipe-create-doc-from-template` | Optional | Copy a template and fill a Doc. |
| `skills/recipe-create-expense-tracker` | Optional | Create a Sheets expense tracker. |
| `skills/recipe-copy-sheet-for-new-month` | Optional | Duplicate a Sheets tab for a new month. |
| `skills/recipe-block-focus-time` | Recommended | Create recurring focus time blocks. |
| `skills/recipe-reschedule-meeting` | Optional/sensitive | Move a Calendar event and notify attendees. |
| `skills/recipe-create-gmail-filter` | Optional/sensitive | Create Gmail filters. |
| `skills/recipe-schedule-recurring-event` | Optional | Create recurring Calendar events. |
| `skills/recipe-find-free-time` | Recommended | Query free/busy and find meeting slots. |
| `skills/recipe-bulk-download-folder` | Optional | Download all files from a Drive folder. |
| `skills/recipe-find-large-files` | Optional | Find large Drive files. |
| `skills/recipe-create-shared-drive` | Sensitive/admin | Create shared drives and members. |
| `skills/recipe-log-deal-update` | Specialized | Append sales deal updates to Sheets. |
| `skills/recipe-collect-form-responses` | Optional | Retrieve Google Form responses. |
| `skills/recipe-post-mortem-setup` | Optional/sensitive | Create post-mortem doc, meeting, Chat notice. |
| `skills/recipe-create-task-list` | Optional | Create a Tasks list. |
| `skills/recipe-review-overdue-tasks` | Recommended | Review overdue Google Tasks. |
| `skills/recipe-watch-drive-changes` | Specialized | Subscribe to Drive change notifications. |
| `skills/recipe-create-classroom-course` | Specialized | Create Classroom courses. |
| `skills/recipe-create-meet-space` | Optional | Create a Meet meeting space. |
| `skills/recipe-review-meet-participants` | Optional/sensitive | Review Meet attendance. |
| `skills/recipe-create-presentation` | Optional | Create a Slides presentation. |
| `skills/recipe-save-email-attachments` | Optional/sensitive | Save Gmail attachments to Drive. |
| `skills/recipe-send-team-announcement` | Sensitive | Send announcement via Gmail and Chat. |
| `skills/recipe-create-feedback-form` | Optional | Create and share a feedback Form. |
| `skills/recipe-sync-contacts-to-sheet` | Sensitive | Export contacts to Sheets. |
| `skills/recipe-share-event-materials` | Optional/sensitive | Share Drive files with event attendees. |
| `skills/recipe-create-vacation-responder` | Optional/sensitive | Enable Gmail out-of-office responder. |
| `skills/recipe-create-events-from-sheet` | Optional/sensitive | Create Calendar events in bulk from Sheets. |
| `skills/recipe-plan-weekly-schedule` | Recommended | Review week and add planning blocks. |
| `skills/recipe-share-doc-and-notify` | Optional/sensitive | Share a Doc and email collaborators. |
| `skills/recipe-backup-sheet-as-csv` | Recommended | Export a Sheet as CSV. |
| `skills/recipe-save-email-to-doc` | Optional/sensitive | Save email content to a Doc. |
| `skills/recipe-compare-sheet-tabs` | Recommended | Compare two Sheet tabs. |
| `skills/recipe-batch-invite-to-event` | Sensitive | Add attendees to an event in bulk. |
| `skills/recipe-forward-labeled-emails` | Sensitive | Forward labeled emails. |
| `skills/recipe-generate-report-from-sheet` | Optional | Generate a Docs report from Sheets data. |

## Persistent addition template

Before adding a skill, verify the path exists in the live upstream package. Then preserve the pinned package and append only the desired paths:

```json
{
  "source": "git:github.com/googleworkspace/cli@v0.22.5",
  "extensions": [],
  "skills": [
    "skills/gws-shared",
    "skills/example-to-add"
  ],
  "prompts": [],
  "themes": []
}
```

After editing the environment repo, validate Home Manager and remind the user to commit before applying with `env-load user notebook ~/Desktop/Codebase/home/environment`.
