---
name: code-review
description: "Code review workflows: pre-commit verification pipeline (security scan, quality gates, independent reviewer) and parallel 3-agent cleanup (reuse, quality, efficiency)."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [code-review, security, verification, quality, pre-commit, auto-fix, cleanup, refactor, delegation, parallel]
    related_skills: [test-driven-development, systematic-debugging]
---

# Code Review — Verification & Cleanup

Two workflows for reviewing code, triggered by different situations:

1. **Pre-commit verification** — security scan + independent reviewer before `git commit`
2. **Parallel cleanup** — three focused reviewers (reuse, quality, efficiency) after changes

---

## Workflow 1: Pre-Commit Verification

Use when: after implementing a feature/fix, before `git commit` or `git push`. Also when user says "commit", "push", "ship", "verify", or "review before merge."

**Core principle:** No agent should verify its own work. Fresh context finds what you miss.

**Skip for:** documentation-only changes, pure config tweaks, or when user says "skip verification."

### Step 1 — Get the diff

```bash
git diff --cached
```

If empty, try `git diff` then `git diff HEAD~1 HEAD`. If diff exceeds 15,000 characters, split by file.

### Step 2 — Static security scan

Scan added lines only:

```bash
# Hardcoded secrets
git diff --cached | grep "^+" | grep -iE "(api_key|secret|password|token|passwd)\s*=\s*['\"][^'\"]{6,}['\"]"
# Shell injection
git diff --cached | grep "^+" | grep -E "os\.system\(|subprocess.*shell=True"
# Dangerous eval/exec
git diff --cached | grep "^+" | grep -E "\beval\(|\bexec\("
# Unsafe deserialization
git diff --cached | grep "^+" | grep -E "pickle\.loads?\("
# SQL injection
git diff --cached | grep "^+" | grep -E "execute\(f\"|\.format\(.*SELECT|\.format\(.*INSERT"
```

### Step 3 — Baseline tests and linting

Detect the project language and run appropriate tools. Capture failure count BEFORE your changes as baseline. Only NEW failures block the commit.

### Step 4 — Self-review checklist

- [ ] No hardcoded secrets, API keys, or credentials
- [ ] Input validation on user-provided data
- [ ] SQL queries use parameterized statements
- [ ] File operations validate paths (no traversal)
- [ ] External calls have error handling
- [ ] No debug print/console.log left behind
- [ ] No commented-out code
- [ ] New code has tests (if test suite exists)

### Step 5 — Independent reviewer subagent

```python
delegate_task(
    goal="""You are an independent code reviewer. Review the git diff and return ONLY valid JSON.

FAIL-CLOSED RULES:
- security_concerns non-empty -> passed must be false
- logic_errors non-empty -> passed must be false

SECURITY (auto-FAIL): hardcoded secrets, backdoors, shell injection, SQL injection, path traversal, eval()/exec() with user input, pickle.loads().

LOGIC ERRORS (auto-FAIL): wrong conditional logic, missing error handling, off-by-one errors, race conditions.

SUGGESTIONS (non-blocking): missing tests, style, performance, naming.

<static_scan_results>
[INSERT FINDINGS]
</static_scan_results>

<code_changes>
[INSERT GIT DIFF]
</code_changes>

Return ONLY JSON: {"passed": bool, "security_concerns": [], "logic_errors": [], "suggestions": [], "summary": "..."}""",
    context="Independent code review. Return only JSON verdict.",
    toolsets=["terminal"]
)
```

### Step 6 — Evaluate results

**All passed:** Proceed to commit.
**Any failures:** Report, then proceed to auto-fix.

### Step 7 — Auto-fix loop (max 2 cycles)

Spawn a THIRD agent context to fix ONLY reported issues. Re-run Steps 1-6 after fixes.

### Step 8 — Commit

```bash
git add -A && git commit -m "[verified] <description>"
```

---

## Workflow 2: Parallel Cleanup (/simplify)

Use when: user says "simplify", "simplify my changes", "review my code", "clean up my changes."

**Core principle:** Three narrow reviewers beat one broad reviewer. Each deeply searches the codebase for a single class of problem.

### Phase 1 — Identify the changes

```bash
git diff          # default: uncommitted changes
git diff HEAD     # if empty, include staged
git diff --staged # "staged changes"
git diff HEAD~1   # "the last commit"
```

### Phase 2 — Launch three reviewers in parallel

Use `delegate_task` batch mode. Give EVERY reviewer the COMPLETE diff plus repo path.

**Reviewer 1 — Code Reuse:** Find code that duplicates existing functionality. Search for existing utilities the new code could call instead.

**Reviewer 2 — Code Quality:** Find redundant state, parameter sprawl, copy-paste-with-variation, leaky abstractions, stringly-typed code.

**Reviewer 3 — Efficiency:** Find unnecessary work, missed concurrency, hot-path bloat, TOCTOU anti-patterns, memory issues, overly broad reads.

Each reviewer reports: `file:line → problem → suggested fix`, ranked `high`/`medium`/`low` confidence.

### Phase 3 — Aggregate and apply

1. Merge findings, dedup overlaps.
2. Discard false positives silently.
3. Resolve conflicts: **correctness > user's focus > readability/reuse > micro-perf.**
4. Apply surviving fixes with `patch`/`write_file` (unless dry run).
5. Verify: run targeted tests + linter for touched files.
6. Summarize what changed.

### Pitfalls

- Don't fan out wider than 3 reviewers.
- Give the WHOLE diff to each reviewer.
- Require `file:line` evidence; drop findings that lack it.
- Apply ≠ rewrite. Keep edits scoped.
- Respect project conventions (AGENTS.md, linter config).

---

## Integration with Other Skills

- **test-driven-development:** This pipeline verifies TDD discipline was followed.
- **systematic-debugging:** Use when review finds bugs that need root-cause investigation.
