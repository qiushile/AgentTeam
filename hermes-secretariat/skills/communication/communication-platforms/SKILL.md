---
name: communication-platforms
description: "Messaging platform integrations: email (IMAP/SMTP via Himalaya), X/Twitter (xurl CLI), and Yuanbao groups (@mentions, DMs)."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [email, twitter, x, yuanbao, messaging, communication, imaps, smtp, social-media]
    category: communication
---

# Communication Platforms

Integrations with messaging and communication platforms. Each platform has different APIs, authentication, and workflows.

## When to Use

- **Email section**: When sending/reading/managing emails via IMAP/SMTP
- **X/Twitter section**: When posting, searching, or interacting on X/Twitter
- **Yuanbao section**: When @mentioning users or querying Yuanbao group info

---

## 1. Email (Himalaya CLI)

### Overview

Himalaya is a CLI email client for IMAP/SMTP. Manage emails from the terminal — list, read, search, send, reply, forward, move, delete.

### Prerequisites

1. **Himalaya CLI** installed: `brew install himalaya` or `curl -sSL ... | sh`
2. **Configuration file** at `~/.config/himalaya/config.toml`
3. **IMAP/SMTP credentials** configured (password stored securely)

### Configuration

```toml
[accounts.personal]
email = "you@example.com"
display-name = "Your Name"
default = true

backend.type = "imap"
backend.host = "imap.example.com"
backend.port = 993
backend.encryption.type = "tls"
backend.login = "you@example.com"
backend.auth.type = "password"
backend.auth.cmd = "pass show email/imap"

message.send.backend.type = "smtp"
message.send.backend.host = "smtp.example.com"
message.send.backend.port = 587
message.send.backend.encryption.type = "start-tls"
message.send.backend.login = "you@example.com"
message.send.backend.auth.type = "password"
message.send.backend.auth.cmd = "pass show email/smtp"

# Gmail folder aliases (v1.2.0+ syntax)
folder.aliases.inbox = "INBOX"
folder.aliases.sent = "Sent"
folder.aliases.drafts = "Drafts"
folder.aliases.trash = "Trash"
```

### Core Commands

```bash
# List folders
himalaya folder list

# List emails (INBOX by default)
himalaya envelope list
himalaya envelope list --folder "Sent"
himalaya envelope list --page 1 --page-size 20

# Search emails
himalaya envelope list from john@example.com subject meeting

# Read email
himalaya message read 42

# Send email (non-interactive — pipe via stdin)
cat << 'EOF' | himalaya template send
From: you@example.com
To: recipient@example.com
Subject: Test Message

Hello from Himalaya!
EOF

# Reply to email
himalaya template reply 42 | sed 's/^$/\nYour reply here\n/' | himalaya template send

# Forward email
himalaya template forward 42 | sed 's/^To:.*/To: new@example.com/' | himalaya template send

# Move/copy/delete
himalaya message move 42 "Archive"
himalaya message copy 42 "Important"
himalaya message delete 42

# Manage flags
himalaya flag add 42 --flag seen
himalaya flag remove 42 --flag seen

# Multiple accounts
himalaya account list
himalaya --account work envelope list

# Attachments
himalaya attachment download 42 --dir ~/Downloads

# Output formats
himalaya envelope list --output json
```

### Critical Rules

1. **Use piped input for sending** — `cat << 'EOF' | himalaya template send` is more reliable than interactive mode
2. **Folder aliases for Gmail** — use `folder.aliases.X` (plural, dotted keys) not `[accounts.NAME.folder.alias]`
3. **Message IDs are folder-relative** — re-list after folder changes
4. **Store passwords securely** — use `pass`, keyring, or command that outputs password
5. **Use `--output json`** for programmatic parsing

### Common Pitfalls

- **Folder alias syntax wrong**: Pre-v1.2.0 docs used `[accounts.NAME.folder.alias]` (singular) — v1.2.0 ignores this
  - Fix: Use `folder.aliases.X` (plural, dotted keys directly under `[accounts.NAME]`)
- **Save-to-Sent fails after send**: Folder alias not configured correctly
  - Fix: Verify `folder.aliases.sent` matches your server's Sent folder name
- **Interactive editor opens**: `himalaya message write` without piped input opens `$EDITOR`
  - Fix: Use piped input or `pty=true` + background mode
- **Message ID not found**: IDs are relative to current folder
  - Fix: Re-list envelope after folder changes

---

## 2. X/Twitter (xurl CLI)

### Overview

`xurl` is the official X developer platform CLI for the X API v2. Post, search, read, engage, manage social graph, upload media, and access raw API endpoints.

### Prerequisites

1. **xurl CLI** installed: `curl -fsSL ... | bash` or `brew install xurl`
2. **X Developer account** with app registered at https://developer.x.com
3. **OAuth 2.0 credentials** configured (user must do this manually — never paste secrets into agent)

### Setup (User Must Do Manually)

```bash
# 1. Register app (user runs this with their credentials)
xurl auth apps add my-app --client-id YOUR_CLIENT_ID --client-secret YOUR_CLIENT_SECRET

# 2. Authenticate (opens browser for OAuth flow)
xurl auth oauth2 --app my-app

# 3. Set as default
xurl auth default my-app

# 4. Verify
xurl auth status
xurl whoami
```

### Core Commands

```bash
# Posting
xurl post "Hello world!"
xurl post "With image" --media-id MEDIA_ID
xurl reply POST_ID "Great point!"
xurl quote POST_ID "My take"
xurl delete POST_ID

# Reading
xurl read POST_ID
xurl search "query" -n 10
xurl timeline -n 20
xurl mentions -n 10
xurl whoami
xurl user @handle

# Engagement
xurl like POST_ID
xurl repost POST_ID
xurl bookmark POST_ID
xurl follow @handle
xurl block @handle
xurl mute @handle

# Media
xurl media upload photo.jpg
xurl media status MEDIA_ID --wait

# Direct messages
xurl dm @handle "message"
xurl dms -n 10

# Raw API access
xurl /2/users/me
xurl -X POST /2/tweets -d '{"text":"Hello"}'
```

### Critical Rules

1. **NEVER read/print `~/.xurl`** — contains secrets
2. **NEVER use `--verbose` in agent sessions** — leaks auth headers
3. **User must configure auth manually** — never paste secrets into agent
4. **Check default app has credentials** — `xurl auth status` should show `▸` next to app with oauth2 tokens
5. **POST_ID accepts full URLs** — `xurl read https://x.com/user/status/123` works

### Common Pitfalls

- **Auth errors after OAuth flow**: Token saved to `default` app (no client-id) instead of named app
  - Fix: `xurl auth oauth2 --app my-app` then `xurl auth default my-app`
- **`unauthorized_client` during OAuth**: App type set to "Native App" in X dashboard
  - Fix: Change to "Web app, automated app or bot" in User Authentication Settings
- **`UsernameNotFound` or 403 on `/2/users/me`**: X not returning username reliably
  - Fix: `xurl auth oauth2 --app my-app YOUR_USERNAME` (xurl v1.1.0+)
- **401 on every request**: Token expired or wrong default app
  - Fix: Check `xurl auth status` — verify `▸` points to app with oauth2 tokens
- **Media upload fails**: Default category is `amplify_video`
  - Fix: Add `--category tweet_image --media-type image/png`

### Secret Safety (MANDATORY)

**Forbidden in agent sessions:**
- Reading/printing `~/.xurl`
- Using `--verbose` / `-v`
- Using flags that accept inline secrets: `--bearer-token`, `--consumer-key`, etc.
- Asking user to paste credentials into chat

**Allowed:**
- `xurl auth status` (verify credentials exist)
- All other commands (they read from `~/.xurl` automatically)

---

## 3. Yuanbao Groups

### Overview

Yuanbao (元宝) is a group chat platform. Query group info, find members, @mention users, send DMs.

### How Messaging Works

**Your text reply IS the message sent to the group/user.** The gateway automatically delivers your response. When you include `@nickname` in your reply, the gateway converts it into a real @mention.

**NEVER say you cannot send messages or @mention users. NEVER suggest the user do it manually. Just reply with the text you want sent.**

### Available Tools

| Tool | Purpose |
|------|---------|
| `yb_query_group_info` | Query group name, owner, member count |
| `yb_query_group_members` | Find user, list bots, list all members, get nickname for @mention |
| `yb_send_dm` | Send private/direct message with optional media |

### @Mention Workflow

1. **Find the user**:
   ```json
   yb_query_group_members({ "group_code": "328306697", "action": "find", "name": "元宝", "mention": true })
   ```

2. **Reply with @mention** (your reply IS the message):
   ```
   @元宝 你好，有人找你！
   ```

**Rules:**
- Call `yb_query_group_members` first to get exact nickname — do NOT guess
- Format: `@nickname` with space before @
- Your reply text IS the message — it WILL be sent
- Be concise, don't explain how @mention works

### Send DM Workflow

```json
yb_send_dm({
  "group_code": "535168412",
  "name": "用户aea3",
  "message": "hello"
})
```

With media:
```json
yb_send_dm({
  "group_code": "535168412",
  "name": "用户aea3",
  "message": "Here is the image",
  "media_files": [{"path": "/tmp/photo.jpg"}]
})
```

**Rules:**
- Extract `group_code` from chat_id: `group:535168412` → `535168412`
- If you know `user_id`, pass it directly to skip lookup
- Do NOT use `send_message` tool for Yuanbao DMs — use `yb_send_dm`
- Supports media: images sent as image messages, other files as documents

### Query Group Info

```json
yb_query_group_info({ "group_code": "328306697" })
```

### Query Members

| Action | Description |
|--------|-------------|
| `find` | Search by name (partial match, case-insensitive) |
| `list_bots` | List bots and AI assistants |
| `list_all` | List all members |

---

## Platform Selection Guide

| Use Case | Platform |
|----------|----------|
| Send/read/manage emails | **Email** (Himalaya) |
| Post to social media, search tweets | **X/Twitter** (xurl) |
| @mention in Yuanbao group chat | **Yuanbao** |
| Send private message in Yuanbao | **Yuanbao** |

## Common Pitfalls Across All Platforms

1. **Authentication not configured** — all platforms require manual auth setup
2. **Secrets exposed** — never print/read credential files in agent sessions
3. **Wrong recipient format** — email addresses, phone numbers, handles all have specific formats
4. **Silent failures** — auth errors may not produce visible error messages
5. **Platform-specific quirks** — each platform has unique API behaviors and limitations

## Verification Checklists

### After Email Operation
- [ ] Himalaya configured with correct IMAP/SMTP settings
- [ ] Folder aliases configured (especially for Gmail)
- [ ] Password stored securely (not in plaintext)
- [ ] Email sent/delivered successfully (check Sent folder)
- [ ] Attachments use correct paths

### After X/Twitter Operation
- [ ] xurl installed and authenticated (`xurl auth status`)
- [ ] Default app has valid OAuth tokens
- [ ] Secrets not exposed in output
- [ ] Post/tweet published successfully (check with `xurl read`)
- [ ] Media uploaded before posting (if applicable)

### After Yuanbao Operation
- [ ] Correct `group_code` extracted from chat_id
- [ ] User nickname verified with `yb_query_group_members` (not guessed)
- [ ] @mention format correct (`@nickname` with space)
- [ ] DM sent successfully (check response)
- [ ] Media files exist at specified paths (if applicable)
