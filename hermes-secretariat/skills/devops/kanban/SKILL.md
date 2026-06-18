---
name: kanban
description: "Hermes Kanban multi-agent system: orchestrator decomposition playbook + worker pitfalls, examples, and edge cases."
version: 1.0.0
platforms: [linux, macos, windows]
environments: [kanban]
metadata:
  hermes:
    tags: [kanban, multi-agent, orchestration, routing, collaboration, workflow, pitfalls]
---

# Hermes Kanban — Orchestrator & Worker Guide

The Kanban system is Hermes' durable multi-agent work queue. This skill covers both roles:

- **Orchestrator** — you decompose goals into tasks, route them to specialist profiles, and manage dependencies
- **Worker** — you execute a dispatched task, report progress, and hand off cleanly

The basic worker lifecycle (6 steps: orient → work → heartbeat → block/complete) is auto-injected into every kanban process via the `KANBAN_GUIDANCE` system-prompt block. This skill is the deeper playbook for both roles.

---

## Part 1: Orchestrator — Decomposition Playbook

### Profiles are user-configured — not a fixed roster

Hermes setups vary widely. Some users run a single profile that does everything; some run a small fleet (`docker-worker`, `cron-worker`); some run a curated specialist team they've named themselves. There is **no default specialist roster** — the orchestrator skill does not know what profiles exist on this machine.

Before fanning out, you must ground the decomposition in the profiles that actually exist. The dispatcher silently fails to spawn unknown assignee names — it doesn't autocorrect, doesn't suggest, doesn't fall back. So a card assigned to `researcher` on a setup that only has `docker-worker` just sits in `ready` forever.

**Step 0: discover available profiles before planning.**

Use one of these:

- `hermes profile list` — prints the table of profiles configured on this machine.
- `kanban_list(assignee="<some-name>")` — sanity-check a single name. Returns an empty list (rather than an error) for an unknown assignee.
- **Just ask the user.** "What profiles do you have set up?" is a fine first turn.

### When to use the board (vs. just doing the work)

Create Kanban tasks when any of these are true:

1. **Multiple specialists are needed.** Research + analysis + writing is three profiles.
2. **The work should survive a crash or restart.** Long-running, recurring, or important.
3. **The user might want to interject.** Human-in-the-loop at any step.
4. **Multiple subtasks can run in parallel.** Fan-out for speed.
5. **Review / iteration is expected.** A reviewer profile loops on drafter output.
6. **The audit trail matters.** Board rows persist in SQLite forever.

If *none* of those apply — use `delegate_task` instead or answer the user directly.

### The anti-temptation rules

- **Do not execute the work yourself.** If you find yourself "just fixing this quickly" — stop and create a task.
- **For any concrete task, create a Kanban task and assign it.** Every single time.
- **Split multi-lane requests before creating cards.** Extract lanes first, then create one card per lane.
- **Run independent lanes in parallel.** Leave them unlinked so the dispatcher can fan them out.
- **Never create dependent work as independent ready cards.** Pass `parents=[...]` in the original `kanban_create` call.
- **If no specialist fits, ask the user which profile to use.** Do not invent profile names.
- **Decompose, route, and summarize — that's the whole job.**

### Decomposition playbook

#### Step 1 — Understand the goal

Ask clarifying questions if the goal is ambiguous. Cheap to ask; expensive to spawn the wrong fleet.

#### Step 2 — Sketch the task graph

Before creating anything, draft the graph out loud:

1. Extract the lanes from the request.
2. Map each lane to one of the profiles you discovered in Step 0.
3. Decide whether each lane is independent or gated by another lane.
4. Create independent lanes as parallel cards with no parent links.
5. Create synthesis/review/integration cards with parent links.

#### Step 3 — Create tasks and link

```python
t1 = kanban_create(
    title="research: Postgres cost vs current",
    assignee="<profile-A>",
    body="Compare estimated infrastructure costs over a 3-year window.",
    tenant=os.environ.get("HERMES_TENANT"),
)["task_id"]

t2 = kanban_create(
    title="synthesize migration recommendation",
    assignee="<profile-B>",
    body="Read the findings from T1. Produce a 1-page recommendation.",
    parents=[t1],
)["task_id"]
```

`parents=[...]` gates promotion — children stay in `todo` until every parent reaches `done`, then auto-promote to `ready`.

#### Step 4 — Complete your own task

```python
kanban_complete(
    summary="decomposed into T1-T2: 1 research lane, 1 synthesis on its output",
    metadata={"task_graph": {"T1": {"assignee": "<profile-A>", "parents": []}, "T2": {"assignee": "<profile-B>", "parents": ["T1"]}}},
)
```

### Common patterns

- **Fan-out + fan-in:** N research cards with no parents, one synthesis card with all as parents.
- **Parallel implementation + validation:** implementer + verifier in parallel, reviewer depends on both.
- **Pipeline with gates:** `planner → implementer → reviewer`. Each stage's `parents=[previous_task]`.
- **Same-profile queue:** N tasks to the same profile, no dependencies. Dispatcher serializes.
- **Human-in-the-loop:** Any task can `kanban_block()` to wait for input.

### Goal-mode cards (persistent workers)

For open-ended cards where one turn rarely finishes:

```python
kanban_create(
    title="Translate the full docs site to French",
    body="Acceptance: every page translated, no English left.",
    assignee="<translator-profile>",
    goal_mode=True,
    goal_max_turns=15,
)["task_id"]
```

### Recovering stuck workers

1. **Reclaim** — abort the running worker, reset to `ready`.
2. **Reassign** — switch to a different profile.
3. **Change profile model** — edit profile config, then Reclaim.

---

## Part 2: Worker — Pitfalls and Examples

### Workspace handling

| Kind | What it is | How to work |
|---|---|---|
| `scratch` | Fresh tmp dir, yours alone | Read/write freely; GC'd when archived. |
| `dir:<path>` | Shared persistent directory | Other runs will read what you write. |
| `worktree` | Git worktree | Commit work here. |

### Tenant isolation

If `$HERMES_TENANT` is set, prefix memory entries with the tenant so context doesn't leak across tenants.

### Good summary + metadata shapes

**Coding task:**
```python
kanban_complete(
    summary="shipped rate limiter — token bucket, 14 tests pass",
    metadata={
        "changed_files": ["rate_limiter.py", "tests/test_rate_limiter.py"],
        "tests_run": 14, "tests_passed": 14,
        "decisions": ["user_id primary, IP fallback for unauthenticated requests"],
    },
)
```

**Review-required (block instead of complete):**
```python
kanban_comment(body="review-required handoff:\n" + json.dumps({...}, indent=2))
kanban_block(reason="review-required: rate limiter shipped — needs eyes before merging")
```

**Research task:**
```python
kanban_complete(
    summary="3 libraries reviewed; vLLM wins on throughput",
    metadata={"sources_read": 12, "recommendation": "vLLM"},
)
```

### Claiming cards you actually created

Only list ids captured from successful `kanban_create` return values in `created_cards`. Never invent ids from prose.

### Block reasons that get answered fast

Bad: `"stuck"`. Good: one sentence naming the specific decision you need. Leave longer context as a comment.

### Heartbeats worth sending

Good: `"epoch 12/50, loss 0.31"`, `"scanned 1.2M/2.4M rows"`. Bad: `"still working"`, empty.

### Retry scenarios

If `kanban_show` returns prior runs, read their `outcome`/`summary`/`error`. Don't repeat the failed path.

### Do NOT

- Call `delegate_task` as a substitute for `kanban_create`.
- Call `clarify` — you're headless. Use `kanban_comment` + `kanban_block`.
- Modify files outside `$HERMES_KANBAN_WORKSPACE`.
- Complete a task you didn't actually finish. Block it instead.

### Pitfalls

- **Task state can change between dispatch and startup.** Always `kanban_show` first.
- **Workspace may have stale artifacts.** Read the comment thread.
- **Don't rely on the CLI when tools are available.** `kanban_*` tools work across all backends.

---

## CLI Reference

Every tool has a CLI equivalent:
- `kanban_show` ↔ `hermes kanban show <id> --json`
- `kanban_complete` ↔ `hermes kanban complete <id> --summary "..." --metadata '{...}'`
- `kanban_block` ↔ `hermes kanban block <id> "reason"`
- `kanban_create` ↔ `hermes kanban create "title" --assignee <profile> [--parent <id>]`
