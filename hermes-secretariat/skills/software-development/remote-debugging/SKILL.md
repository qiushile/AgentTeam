---
name: remote-debugging
description: "Attach debuggers to running processes: Node.js via --inspect + CDP, Python via pdb + debugpy (DAP). Breakpoints, stepping, scope inspection, heap snapshots."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [debugging, nodejs, python, pdb, debugpy, breakpoints, cdp, dap, remote, attach]
    related_skills: [systematic-debugging]
---

# Remote Debugging — Node.js & Python

Attach debuggers to running processes for breakpoints, stepping, scope inspection, and profiling. Two languages, same pattern: enable inspector, attach client, inspect state.

---

## Node.js: `node inspect` + CDP

### When to Use
- A Node test fails and you need to see intermediate state
- TUI/gateway child processes misbehave
- You need to inspect a closure value that `console.log` can't reach
- Perf: capture CPU profile or heap snapshot

### Quick Reference: `node inspect` REPL

Launch paused on first line:
```bash
node inspect path/to/script.js
# or with tsx
node --inspect-brk $(which tsx) path/to/script.ts
```

| Command | Action |
|---|---|
| `c` / `cont` | continue |
| `n` / `next` | step over |
| `s` / `step` | step into |
| `o` / `out` | step out |
| `sb('file.js', 42)` | set breakpoint |
| `cb('file.js', 42)` | clear breakpoint |
| `bt` | backtrace |
| `repl` | drop into REPL in current scope |
| `exec expr` | evaluate expression |
| `watch('expr')` | evaluate on every pause |

### Attaching to a Running Process

```bash
# 1. Send SIGUSR1 to enable inspector
kill -SIGUSR1 <pid>
# Node prints: Debugger listening on ws://127.0.0.1:9229/<uuid>

# 2. Attach
node inspect -p <pid>
# or by URL
node inspect ws://127.0.0.1:9229/<uuid>
```

Starting with inspector from the beginning:
```bash
node --inspect script.js           # listen, keep running
node --inspect-brk script.js       # listen AND pause on first line
node --inspect=0.0.0.0:9230 script.js   # custom host:port
```

### Programmatic CDP (scripting)

Use `chrome-remote-interface` for automation:
```bash
npm i -g chrome-remote-interface
node --inspect-brk=9229 target.js &
```

```javascript
const CDP = require('chrome-remote-interface');
(async () => {
  const client = await CDP({ port: 9229 });
  const { Debugger, Runtime } = client;
  Debugger.paused(async ({ callFrames }) => {
    // Inspect scopes, evaluate expressions
  });
  await Runtime.enable();
  await Debugger.enable();
  await Debugger.setBreakpointByUrl({ urlRegex: '.*app\\.tsx$', lineNumber: 119 });
  await Runtime.runIfWaitingForDebugger();
})();
```

### Heap Snapshots & CPU Profiles

```javascript
// CPU profile for 5 seconds
await client.Profiler.enable();
await client.Profiler.start();
await new Promise(r => setTimeout(r, 5000));
const { profile } = await client.Profiler.stop();
require('fs').writeFileSync('/tmp/cpu.cpuprofile', JSON.stringify(profile));

// Heap snapshot
await client.HeapProfiler.enable();
const chunks = [];
client.HeapProfiler.addHeapSnapshotChunk(({ chunk }) => chunks.push(chunk));
await client.HeapProfiler.takeHeapSnapshot({ reportProgress: false });
require('fs').writeFileSync('/tmp/heap.heapsnapshot', chunks.join(''));
```

### Node.js Pitfalls

1. **Wrong line numbers in TS** — breakpoints hit emitted JS. Use `--enable-source-maps` or break in `dist/*.js`.
2. **`--inspect` vs `--inspect-brk`** — `--inspect` doesn't pause; script races past breakpoints. Use `--inspect-brk`.
3. **Port collisions** — default 9229. Use `--inspect=0` for random port, read from `/json/list`.
4. **Child processes** — `--inspect` on parent does NOT inspect children. Use `NODE_OPTIONS='--inspect-brk'`.
5. **Security** — `--inspect=0.0.0.0:9229` exposes arbitrary code execution. Always bind to `127.0.0.1`.

---

## Python: pdb + debugpy

### When to Use
- A test fails and traceback doesn't reveal why a value is wrong
- A long-running process misbehaves and can't be restarted
- Post-mortem: inspect locals at crash site
- A subprocess/child is the bug site

**Don't use for:** things `print()` / `logging.debug` solve in under a minute.

### Three Tools, Picked by Situation

| Tool | When |
|---|---|
| `breakpoint()` + pdb | Local, interactive, simplest. Add `breakpoint()` in source, run normally. |
| `python -m pdb` | Launch script under pdb with no source edits. |
| `debugpy` | Remote / headless / attach to running process. Talks DAP. |

### pdb Quick Reference

| Command | Action |
|---|---|
| `n` | next line (step over) |
| `s` | step into |
| `r` | return from function |
| `c` | continue |
| `w` | where (stack trace) |
| `u` / `d` | move up/down stack |
| `a` | print args |
| `p expr` / `pp expr` | print / pretty-print |
| `b file:line` | set breakpoint |
| `b file:line, cond` | conditional breakpoint |
| `!stmt` | execute arbitrary Python |
| `interact` | full Python REPL in current scope |

### Recipe: Local breakpoint
```python
def compute(x, y):
    result = some_helper(x)
    breakpoint()  # drops into pdb here
    return result + y
```
Don't forget to remove `breakpoint()` before committing: `rg -n 'breakpoint\(\)' --type py`

### Recipe: Debug a pytest test
```bash
pytest tests/path/test.py::test_name --pdb -p no:xdist  # -n 0 also works
```

### Recipe: Post-mortem
```python
import pdb, sys
try:
    run_the_thing()
except Exception:
    pdb.post_mortem(sys.exc_info()[2])
```

### Recipe: Remote debug with debugpy

**Pattern A: Source-edit — wait for debugger at launch**
```python
import debugpy
debugpy.listen(("127.0.0.1", 5678))
debugpy.wait_for_client()
debugpy.breakpoint()
```

**Pattern B: No source edit — launch with `-m debugpy`**
```bash
python -m debugpy --listen 127.0.0.1:5678 --wait-for-client your_script.py
```

**Pattern C: Attach to running process**
```bash
python -m debugpy --listen 127.0.0.1:5678 --pid <pid>
```

**Simpler alternative: `remote-pdb`** (cleanest for terminal agents)
```bash
pip install remote-pdb
```
```python
from remote_pdb import set_trace
set_trace(host="127.0.0.1", port=4444)  # blocks until connection
```
Then: `nc 127.0.0.1 4444` → get a `(Pdb)` prompt.

### Python Pitfalls

1. **pdb under pytest-xdist silently does nothing.** Use `-p no:xdist` or `-n 0`.
2. **`breakpoint()` in CI hangs the process.** Never commit it.
3. **`PYTHONBREAKPOINT=0`** disables all `breakpoint()` calls.
4. **`debugpy.listen` blocks only with `wait_for_client()`.** Without it, execution continues.
5. **Attach to PID fails on hardened kernels.** Fix: `echo 0 > /proc/sys/kernel/yama/ptrace_scope`.
6. **Threads** — pdb only debugs current thread. Use debugpy for thread-aware DAP.
7. **asyncio** — `await` inside pdb requires Python 3.13+ or `interact` mode tricks.

---

## Verification Checklist

- [ ] Inspector/debugger is actually listening: `curl -s http://127.0.0.1:9229/json/list` (Node) or `ss -tlnp | grep 5678` (Python)
- [ ] First breakpoint actually hits
- [ ] Source listing at pause shows the right file
- [ ] Post-debug cleanup: no stray `breakpoint()` / `set_trace()` in committed code
