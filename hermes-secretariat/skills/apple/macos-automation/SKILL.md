---
name: macos-automation
description: "macOS-specific automation: iMessage/SMS messaging and desktop control (screenshots, clicks, keyboard input)."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos]
metadata:
  hermes:
    tags: [macos, imessage, sms, desktop-control, automation, screenshots, apple]
    category: apple
---

# macOS Automation

macOS-specific automation capabilities for messaging and desktop control.

## When to Use

- **iMessage section**: When sending/receiving iMessages or SMS on macOS
- **Desktop Control section**: When driving the macOS desktop (screenshots, clicks, keyboard input, window management)

---

## 1. iMessage / SMS (imsg CLI)

### Overview

Send and receive iMessages and SMS via the `imsg` CLI on macOS. Uses the Messages app backend — requires macOS with Messages configured.

### Prerequisites

1. **macOS** with Messages app configured and signed in
2. **imsg CLI** installed: `brew install imsg` or build from source
3. **Permissions**: Terminal/iTerm needs Automation permission for Messages app
   - System Preferences → Security & Privacy → Privacy → Automation
   - Enable "Messages" for your terminal app

### Installation

```bash
# Homebrew (recommended)
brew install imsg

# Or build from source
git clone https://github.com/wdmimsg/imsg.git
cd imsg && make install
```

### Core Commands

#### Send Messages

```bash
# Send iMessage (Apple ID or phone number)
imsg send "Hello!" --to user@example.com

# Send SMS (phone number with country code)
imsg send "Hello!" --to +1234567890

# Send to multiple recipients
imsg send "Group message" --to user1@example.com --to user2@example.com

# Send with attachment
imsg send "Check this out" --to user@example.com --attach /path/to/image.jpg

# Send to a group chat by name
imsg send "Message" --group "Family"
```

#### Read Messages

```bash
# List recent conversations
imsg list

# Read messages from a specific contact
imsg read --from user@example.com

# Read last N messages
imsg read --from user@example.com --limit 10

# Search messages
imsg search "keyword"

# Search by date range
imsg search "keyword" --after "2026-01-01" --before "2026-01-31"
```

#### Conversation Management

```bash
# List all conversations
imsg conversations

# Get conversation ID
imsg conversations --from user@example.com

# Mark as read
imsg mark-read --from user@example.com

# Delete messages (caution!)
imsg delete --from user@example.com --before "2025-01-01"
```

### Critical Rules

1. **Phone numbers need country code** — `+1` for US/Canada, `+44` for UK, etc.
2. **iMessage vs SMS** — iMessage uses Apple ID/email, SMS uses phone number
3. **Permissions required** — Automation permission for Messages app must be granted
4. **Group chats** — use `--group "Name"` or find the group's chat GUID
5. **Attachments** — use absolute paths, relative paths may fail

### Common Pitfalls

- **Messages app not signed in**: imsg requires active Messages session
  - Fix: Open Messages app and sign in with Apple ID
- **Automation permission denied**: Terminal can't control Messages
  - Fix: System Preferences → Security & Privacy → Automation → enable Messages
- **Phone number format wrong**: Missing country code → delivery fails
  - Fix: Always use `+<country code><number>` format
- **Group chat not found**: Name doesn't match exactly
  - Fix: Use `imsg conversations` to find exact group name or GUID
- **Attachment path wrong**: Relative paths or non-existent files
  - Fix: Use absolute paths, verify file exists

### Workflow Patterns

#### Monitor for New Messages

```bash
# Poll for new messages (script)
while true; do
  imsg list --unread | while read -r line; do
    echo "New message: $line"
    # Process message...
  done
  sleep 5
done
```

#### Auto-Reply Bot

```bash
# Simple auto-reply (use with caution!)
imsg list --unread | while read -r from message; do
  if [[ "$message" == *"urgent"* ]]; then
    imsg send "I'll get back to you soon" --from-me --to "$from"
  fi
done
```

---

## 2. Desktop Control (Computer Use)

### Overview

Drive the macOS desktop programmatically: take screenshots, click elements, type text, manage windows. Uses native macOS APIs and accessibility features.

### Prerequisites

1. **macOS** with Accessibility permissions enabled
   - System Preferences → Security & Privacy → Privacy → Accessibility
   - Enable Terminal/iTerm (or whatever runs Hermes)
2. **Screen Recording permission** (for screenshots on macOS 10.15+)
   - System Preferences → Security & Privacy → Privacy → Screen Recording

### Core Capabilities

#### Screenshots

```bash
# Full screen screenshot
screencapture -x /tmp/screenshot.png

# Specific window (by window ID)
screencapture -l <window_id> -x /tmp/window.png

# Specific region (x,y,width,height)
screencapture -R 100,100,800,600 -x /tmp/region.png

# Interactive selection (user draws region)
screencapture -i -x /tmp/selection.png
```

#### Mouse Control

```bash
# Click at coordinates
osascript -e 'tell application "System Events" to click at {500, 300}'

# Double-click
osascript -e 'tell application "System Events" to double click at {500, 300}'

# Right-click (contextual click)
osascript -e 'tell application "System Events" to control click at {500, 300}'

# Move mouse (no click)
osascript -e 'tell application "System Events" to move mouse to {500, 300}'

# Drag from point A to point B
osascript -e 'tell application "System Events" to drag from {100, 100} to {500, 500}'
```

#### Keyboard Input

```bash
# Type text
osascript -e 'tell application "System Events" to keystroke "Hello World"'

# Press special keys
osascript -e 'tell application "System Events" to key code 36'  # Enter
osascript -e 'tell application "System Events" to key code 48'  # Tab
osascript -e 'tell application "System Events" to key code 51'  # Delete

# Key combinations
osascript -e 'tell application "System Events" to keystroke "c" using command down'  # Cmd+C
osascript -e 'tell application "System Events" to keystroke "v" using command down'  # Cmd+V
osascript -e 'tell application "System Events" to keystroke "z" using {command down, shift down}'  # Cmd+Shift+Z
```

#### Window Management

```bash
# List all windows
osascript -e 'tell application "System Events" to get name of every window of every process'

# Get frontmost window
osascript -e 'tell application "System Events" to get name of front window of (first process whose frontmost is true)'

# Bring app to front
osascript -e 'tell application "Safari" to activate'

# Minimize window
osascript -e 'tell application "System Events" to tell process "Safari" to set miniaturized of front window to true'

# Resize window
osascript -e 'tell application "System Events" to tell process "Safari" to set size of front window to {1200, 800}'

# Move window
osascript -e 'tell application "System Events" to tell process "Safari" to set position of front window to {100, 100}'
```

#### Application Control

```bash
# Launch app
open -a "Safari"

# Quit app
osascript -e 'tell application "Safari" to quit'

# Force quit
killall "Safari"

# Check if app is running
pgrep -x "Safari" && echo "Running" || echo "Not running"

# Get app version
osascript -e 'tell application "Safari" to version'
```

### Critical Rules

1. **Accessibility permissions required** — System Preferences must grant access
2. **Screen Recording permissions for screenshots** — macOS 10.15+ requires explicit permission
3. **Coordinates are absolute** — (0,0) is top-left of primary display
4. **Multi-monitor setups** — coordinates span across all displays
5. **App must be frontmost for keyboard input** — activate app before typing
6. **Use `osascript` for complex automation** — AppleScript is the native automation language

### Common Pitfalls

- **Accessibility permission denied**: Commands fail silently or with permission errors
  - Fix: System Preferences → Security & Privacy → Accessibility → enable Terminal
- **Screen Recording permission denied**: Screenshots are blank or fail
  - Fix: System Preferences → Security & Privacy → Screen Recording → enable Terminal
- **Wrong coordinates**: Clicking in wrong location
  - Fix: Use `screencapture` to verify screen layout, check display scaling
- **App not frontmost**: Keyboard input goes to wrong app
  - Fix: `tell application "X" to activate` before keyboard commands
- **AppleScript syntax errors**: Quotes, escaping, or syntax issues
  - Fix: Test in Script Editor first, use proper escaping for special characters
- **Multi-monitor coordinate confusion**: Clicks land on wrong display
  - Fix: Use `system_profiler SPDisplaysDataType` to understand display layout

### Workflow Patterns

#### Screenshot → Analyze → Act

```bash
# 1. Take screenshot
screencapture -x /tmp/screen.png

# 2. Analyze with vision tool
# (use vision_analyze to understand what's on screen)

# 3. Act based on analysis
osascript -e 'tell application "System Events" to click at {500, 300}'
```

#### UI Automation Loop

```bash
# Repeat until condition is met
while true; do
  screencapture -x /tmp/check.png
  # Analyze screenshot...
  if [[ condition_met ]]; then
    break
  fi
  # Take action...
  sleep 1
done
```

#### Window Layout Setup

```bash
# Arrange windows in a grid
osascript -e 'tell application "Safari" to activate'
osascript -e 'tell application "System Events" to tell process "Safari" to set position of front window to {0, 25}'
osascript -e 'tell application "System Events" to tell process "Safari" to set size of front window to {960, 1055}'

osascript -e 'tell application "Terminal" to activate'
osascript -e 'tell application "System Events" to tell process "Terminal" to set position of front window to {960, 25}'
osascript -e 'tell application "System Events" to tell process "Terminal" to set size of front window to {960, 1055}'
```

---

## Tool Selection Guide

| Task | Tool |
|------|------|
| Send iMessage/SMS | **iMessage** (imsg CLI) |
| Read message history | **iMessage** (imsg CLI) |
| Monitor for new messages | **iMessage** (imsg CLI) |
| Take screenshots | **Desktop Control** (screencapture) |
| Click UI elements | **Desktop Control** (osascript) |
| Type text / keyboard shortcuts | **Desktop Control** (osascript) |
| Manage windows | **Desktop Control** (osascript) |
| Launch/quit applications | **Desktop Control** (open/osascript) |

## Common Pitfalls Across Both Tools

1. **Permissions not granted** — both require explicit macOS permissions
2. **Silent failures** — permission errors may not produce visible error messages
3. **Coordinate system confusion** — multi-monitor setups, display scaling
4. **App state assumptions** — verify app is running/frontmost before interacting
5. **AppleScript escaping** — special characters, quotes, backslashes need proper escaping

## Verification Checklists

### After iMessage Operation
- [ ] Messages app is signed in and running
- [ ] Automation permission granted for terminal
- [ ] Recipient format correct (email for iMessage, +country code for SMS)
- [ ] Message sent successfully (check `imsg list` or Messages app)
- [ ] Attachments use absolute paths and exist

### After Desktop Control Operation
- [ ] Accessibility permission granted for terminal
- [ ] Screen Recording permission granted (for screenshots)
- [ ] Target app is running and frontmost (for keyboard input)
- [ ] Coordinates are correct (verify with screenshot)
- [ ] AppleScript syntax is valid (test in Script Editor if unsure)
- [ ] Operation completed successfully (verify with screenshot or app state)
