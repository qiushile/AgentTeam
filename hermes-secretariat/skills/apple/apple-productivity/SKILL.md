---
name: apple-productivity
description: "Apple productivity tools: Notes (memo CLI) and Reminders (remindctl CLI) for macOS."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos]
metadata:
  hermes:
    tags: [Apple, macOS, Notes, Reminders, productivity, memo, remindctl]
---

# Apple Productivity Suite

Unified skill for Apple Notes and Reminders management via CLI tools on macOS.

---

## Section A: Apple Notes (memo)

Manage Apple Notes via the `memo` CLI. Notes sync across all Apple devices via iCloud.

**Install**: `brew tap antoniorodr/memo && brew install antoniorodr/memo/memo`

**Quick Reference**:
| Action | Command |
|--------|---------|
| List all | `memo notes` |
| Filter by folder | `memo notes -f "Folder Name"` |
| Search | `memo notes -s "query"` |
| Create | `memo notes -a "Title"` or `memo notes -a` (interactive) |
| Edit | `memo notes -e` (interactive selection) |
| Delete | `memo notes -d` (interactive selection) |
| Move to folder | `memo notes -m` (interactive) |
| Export | `memo notes -ex` (HTML/Markdown) |

**Limitations**: Cannot edit notes with images/attachments. Interactive prompts require terminal (use `pty=true` if needed).

---

## Section B: Apple Reminders (remindctl)

Manage Apple Reminders via the `remindctl` CLI. Tasks sync across all Apple devices via iCloud.

**Install**: `brew install steipete/tap/remindctl`

**Quick Reference**:
| Action | Command |
|--------|---------|
| Today's reminders | `remindctl` or `remindctl today` |
| All reminders | `remindctl all` |
| Overdue | `remindctl overdue` |
| This week | `remindctl week` |
| Specific date | `remindctl 2026-01-04` |
| List all lists | `remindctl list` |
| Create reminder | `remindctl add "Buy milk"` |
| With due date | `remindctl add --title "Call mom" --list Personal --due tomorrow` |
| With early alarm | `remindctl add --title "Meeting" --due "2026-02-15 14:00" --alarm "2026-02-15 13:30"` |
| Complete | `remindctl complete 1 2 3` |
| Delete | `remindctl delete ID --force` |
| JSON output | `remindctl today --json` |

**Date formats**: `today`, `tomorrow`, `YYYY-MM-DD`, `YYYY-MM-DD HH:mm`, ISO 8601.

**Key distinction**: `--due` sets the reminder's due date/time; `--alarm` sets the notification trigger. They are different fields.

---

## Rules

1. When user says "remind me", clarify: Apple Reminders (syncs to phone) vs agent cronjob alert
2. Prefer Apple Notes when user wants cross-device sync (iPhone/iPad/Mac)
3. Use the `memory` tool for agent-internal notes that don't need to sync
4. Use the `obsidian` skill for Markdown-native knowledge management
5. Always confirm reminder content and due date before creating
6. Use `--json` for programmatic parsing of reminders