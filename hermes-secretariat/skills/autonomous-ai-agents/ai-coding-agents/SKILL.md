---
name: ai-coding-agents
description: "AI coding agents: Claude Code (Anthropic), Codex (OpenAI), and OpenCode (provider-agnostic) — orchestration via Hermes terminal."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [Coding-Agent, Claude, Codex, OpenCode, autonomous, refactoring]
---

# AI Coding Agents Suite

Unified skill for delegating coding tasks to autonomous AI coding agents. Three agents: Claude Code (Anthropic), Codex (OpenAI), OpenCode (provider-agnostic).

## Shared Pattern

All three agents follow the same Hermes orchestration pattern:
- **One-shot**: `agent exec/run "prompt"` — runs and exits
- **Background**: Start with `background=true, pty=true`, monitor with `process` tools
- **PR review**: Clone to temp dir or worktree, run review, post results
- **Parallel**: Use separate workdirs/worktrees to avoid collisions

---

## Section A: Claude Code (Anthropic)

**Install**: `npm install -g @anthropic-ai/claude-code`

### Two Orchestration Modes

**Print Mode (PREFERRED for most tasks)**:
```
terminal(command="claude -p 'Add error handling to all API calls in src/' --allowedTools 'Read,Edit' --max-turns 10", workdir="/project", timeout=120)
```
- One-shot, returns result, exits. No PTY needed.
- Supports: `--output-format json`, `--json-schema`, `--max-turns`, `--max-budget-usd`
- Use `--bare` for CI (fastest startup, skips plugins/hooks/MCP)

**Interactive PTY (multi-turn)**:
```
terminal(command="tmux new-session -d -s claude-work && tmux send-keys -t claude-work 'claude' Enter", pty=true)
```
- Requires tmux for reliable orchestration
- Handle trust dialog: `tmux send-keys Enter` (default = "Yes, I trust")
- Handle permissions dialog: `tmux send-keys Down && Enter` (default = "No, exit" — WRONG)

### Key Flags
| Flag | Effect |
|------|--------|
| `-p, --print` | Non-interactive one-shot |
| `--max-turns N` | Limit agentic loops (print mode only) |
| `--max-budget-usd N` | Cap API spend |
| `--model sonnet/opus/haiku` | Model selection |
| `--effort low/medium/high/max` | Reasoning depth |
| `--dangerously-skip-permissions` | Auto-approve all tool use |
| `--bare` | Skip hooks, plugins, MCP (CI mode) |
| `--worktree name` | Isolated git worktree |
| `--tmux` | Create tmux session for worktree |

### CLAUDE.md — Project Context
Claude auto-loads `CLAUDE.md` from project root. Use for persisting project context:
- Architecture overview
- Key commands
- Code standards
- Dependencies

For many rules, use `.claude/rules/*.md` directory instead of one massive CLAUDE.md.

### Hooks (Automation on Events)
Configure in `.claude/settings.json`:
```json
{
  "hooks": {
    "PostToolUse": [{"matcher": "Write(*.py)", "hooks": [{"type": "command", "command": "ruff check --fix $CLAUDE_FILE_PATHS"}]}],
    "PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "if echo \"$CLAUDE_TOOL_INPUT\" | grep -q 'rm -rf'; then exit 2; fi"}]}]
  }
}
```

### MCP Integration
```
claude mcp add -s user github -- npx @modelcontextprotocol/server-github
claude mcp add -s local postgres -- npx @anthropic-ai/server-postgres --connection-string postgresql://localhost/mydb
```

### Pitfalls
1. Print mode is cleaner — prefer `-p` for single tasks
2. `--dangerously-skip-permissions` dialog defaults to "No, exit" — must send Down then Enter
3. `--max-turns` is print-mode only
4. Trust dialog only appears once per directory
5. Context degrades above 70% window — use `/compact` proactively
6. Always clean up tmux sessions when done

---

## Section B: Codex (OpenAI)

**Install**: `npm install -g @openai/codex`

### One-Shot
```
terminal(command="codex exec 'Add dark mode toggle to settings'", workdir="~/project", pty=true)
```

### Background (Long Tasks)
```
terminal(command="codex exec --full-auto 'Refactor auth module'", workdir="~/project", background=true, pty=true)
# Monitor: process(action="poll", session_id="...")
```

### Key Flags
| Flag | Effect |
|------|--------|
| `exec "prompt"` | One-shot execution |
| `--full-auto` | Auto-approve changes in workspace |
| `--yolo` | No sandbox, no approvals (fastest, most dangerous) |

### Rules
1. **Always use `pty=true`** — Codex is interactive
2. **Git repo required** — use `mktemp -d && git init` for scratch
3. **`exec` for one-shots**, `--full-auto` for building
4. **Background for long tasks** with process monitoring

---

## Section C: OpenCode (Provider-Agnostic)

**Install**: `npm i -g opencode-ai@latest` or `brew install anomalyco/tap/opencode`

### One-Shot
```
terminal(command="opencode run 'Add retry logic to API calls and update tests'", workdir="~/project")
```

### Interactive (Background)
```
terminal(command="opencode", workdir="~/project", background=true, pty=true)
process(action="submit", session_id="<id>", data="Implement OAuth refresh flow")
# Exit: process(action="write", data="\x03") or process(action="kill")
```

### Key Flags
| Flag | Use |
|------|-----|
| `run 'prompt'` | One-shot, no PTY needed |
| `--continue` / `-c` | Continue last session |
| `--session <id>` | Resume specific session |
| `--model provider/model` | Force specific model |
| `--format json` | Machine-readable output |
| `--file <path>` / `-f` | Attach files |
| `--thinking` | Show thinking blocks |
| `pr <number>` | Built-in PR review command |

### Rules
1. Prefer `opencode run` for one-shot — no PTY needed
2. Exit with Ctrl+C (`\x03`), NOT `/exit` (opens agent selector)
3. Separate workdirs for parallel sessions
4. Enter may need double-press in TUI

---

## Shared Pitfalls

1. **Always scope to a single repo/workdir** — never share working directories across parallel agent sessions
2. **Use isolated worktrees** for untrusted code generation
3. **Monitor with process tools** before assuming completion
4. **Review output before accepting** — agents may hallucinate file changes
5. **Cost tracking** — use `--max-budget-usd` (Claude) or `opencode stats` (OpenCode)