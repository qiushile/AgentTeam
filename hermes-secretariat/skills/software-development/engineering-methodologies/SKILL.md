---
name: engineering-methodologies
description: "Systematic engineering disciplines: debugging (root cause investigation), TDD (test-first development), and exploratory QA (web app testing)."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [debugging, tdd, qa, testing, methodology, engineering-discipline]
    category: software-development
---

# Engineering Methodologies

Systematic approaches to software engineering challenges. Each methodology has iron laws that must be followed — skipping steps leads to failure.

## When to Use

- **Debugging section**: When investigating bugs, errors, crashes, or unexpected behavior
- **TDD section**: When writing new features or refactoring existing code
- **QA section**: When testing web applications for bugs and issues

---

## 1. Systematic Debugging (4-Phase Root Cause Investigation)

### Iron Law
`NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST`

Attempting to fix symptoms without understanding root cause is failure. ALWAYS investigate first.

### Phase 1: Root Cause Investigation

**Before any fix attempt, complete these steps:**

1. **Read the error carefully** — full stack trace, error message, context
2. **Reproduce the issue** — can you trigger it consistently?
3. **Check recent changes** — what changed since it last worked?
4. **Gather evidence** — logs, state, environment, inputs
5. **Trace data flow** — follow the data from input to output

**Common mistakes to avoid:**
- Jumping to fixes based on error message keywords
- Assuming the error location is the root cause
- Ignoring context (what changed, what's different)
- Fixing symptoms instead of causes

### Phase 2: Hypothesis & Prediction

Based on evidence, form a hypothesis:
- "I believe the root cause is X because [evidence]"
- "If this is correct, then I should see Y when I [test]"

**Predict what you'll see before testing.** If your prediction is wrong, your hypothesis is wrong — go back to Phase 1.

### Phase 3: Fix & Verify

Only after root cause is confirmed:
1. Implement the minimal fix that addresses the root cause
2. Verify the fix resolves the original issue
3. Verify the fix doesn't break anything else
4. Test edge cases related to the root cause

### Phase 4: Retrospective

After the fix is verified:
- What was the root cause?
- What evidence led to it?
- What could have prevented this?
- What did you learn?

### Debugging Iron Laws

1. **NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST**
2. **Evidence over assumptions** — don't guess, gather data
3. **Reproduce before fixing** — if you can't reproduce it, you can't verify the fix
4. **Minimal fixes** — address the root cause, not symptoms
5. **Verify thoroughly** — test the fix AND related functionality

---

## 2. Test-Driven Development (RED-GREEN-REFACTOR)

### Iron Law
`NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST`

If you didn't watch the test fail, you don't know if it tests the right thing.

### The TDD Cycle

#### RED — Write a Failing Test

1. **Identify the next small behavior** you want to add
2. **Write a test** that describes that behavior
3. **Run the test** — it MUST fail (if it passes, you wrote the wrong test)
4. **Verify the failure message** makes sense (tests the right thing)

**What counts as "fail"?**
- Compilation error (function doesn't exist yet) ✓
- Assertion failure (function exists but returns wrong value) ✓
- Test passes ✗ — you wrote the wrong test or the feature already exists

#### GREEN — Make It Pass

1. **Write the MINIMAL code** to make the test pass
2. **Run the test** — it MUST pass
3. **Don't add extra features** — only what's needed for this test

**What counts as "minimal"?**
- Hardcoded values that make the test pass ✓ (yes, really)
- Simple logic that satisfies the test ✓
- Extra features "while you're here" ✗
- Refactoring beyond what's needed ✗

#### REFACTOR — Clean Up

Only AFTER the test passes:
1. **Remove duplication** — DRY principle
2. **Improve names** — clarity over cleverness
3. **Simplify logic** — if you can make it clearer
4. **Run tests after each change** — don't break what works

**What NOT to refactor:**
- Adding new features (that's a new RED cycle)
- Changing behavior (that's a bug fix, not refactoring)
- Optimizing prematurely (make it work, make it right, make it fast — in that order)

### TDD Iron Laws

1. **NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST**
2. **Watch the test fail** — if it passes on first run, you wrote the wrong test
3. **Minimal implementation** — write only what's needed to pass the current test
4. **Refactor only after green** — never refactor with a failing test
5. **Small steps** — one behavior at a time, not big features

### When TDD Works Best

- Well-defined requirements or specifications
- Pure functions and business logic
- API contracts and interfaces
- Regression tests for bugs (write the test that would have caught it)

### When TDD is Harder

- Exploratory prototyping (spike first, then TDD the final design)
- UI/UX work (hard to test visual design)
- Legacy code without tests (characterization tests first)

---

## 3. Exploratory QA Testing (Web Applications)

### Overview

Systematic exploratory QA testing of web applications using browser automation. Navigate, interact, capture evidence, produce structured bug reports.

### 5-Phase Workflow

#### Phase 1: Plan

1. **Create output directory**:
   ```
   {output_dir}/
   ├── screenshots/       # Evidence screenshots
   └── report.md          # Final report
   ```

2. **Identify testing scope** based on user input

3. **Build rough sitemap**:
   - Landing/home page
   - Navigation links (header, footer, sidebar)
   - Key user flows (sign up, login, search, checkout)
   - Forms and interactive elements
   - Edge cases (empty states, error pages, 404s)

#### Phase 2: Explore

For each page or feature:

1. **Navigate**: `browser_navigate(url="...")`

2. **Snapshot DOM**: `browser_snapshot()` — understand structure

3. **Check console**: `browser_console(clear=true)` — catch JS errors
   **Do this after EVERY navigation and significant interaction**

4. **Annotated screenshot**: `browser_vision(question="...", annotate=true)`
   - `annotate=true` overlays numbered labels on interactive elements
   - Each `[N]` maps to ref `@eN` for subsequent commands

5. **Test interactions systematically**:
   - Click buttons/links: `browser_click(ref="@eN")`
   - Fill forms: `browser_type(ref="@eN", text="...")`
   - Keyboard navigation: `browser_press(key="Tab")`, `browser_press(key="Enter")`
   - Scroll: `browser_scroll(direction="down")`
   - Test validation with invalid inputs
   - Test empty submissions

6. **After each interaction**, check:
   - Console errors: `browser_console()`
   - Visual changes: `browser_vision(question="What changed?")`
   - Expected vs actual behavior

#### Phase 3: Collect Evidence

For every issue found:

1. **Screenshot the issue**: `browser_vision(question="Capture the issue", annotate=false)`
   - Save the `screenshot_path` for the report

2. **Record details**:
   - URL where issue occurs
   - Steps to reproduce
   - Expected behavior
   - Actual behavior
   - Console errors (if any)
   - Screenshot path

3. **Classify the issue**:
   - **Severity**: Critical / High / Medium / Low
   - **Category**: Functional / Visual / Accessibility / Console / UX / Content

#### Phase 4: Categorize

1. Review all collected issues
2. **De-duplicate** — merge issues that are the same bug in different places
3. Assign final severity and category
4. **Sort by severity** (Critical → High → Medium → Low)
5. Count issues by severity and category for executive summary

#### Phase 5: Report

Generate structured markdown report with:

1. **Executive summary**:
   - Total issue count
   - Breakdown by severity
   - Testing scope

2. **Per-issue sections**:
   - Issue number and title
   - Severity and category badges
   - URL where observed
   - Description
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshot references (`MEDIA:<screenshot_path>`)
   - Console errors if relevant

3. **Summary table** of all issues

4. **Testing notes**:
   - What was tested
   - What was not tested
   - Any blockers

Save report to `{output_dir}/report.md`.

### QA Iron Laws

1. **Always check console after navigation and interactions** — silent JS errors are high-value findings
2. **Use `annotate=true`** when reasoning about interactive element positions
3. **Test with valid AND invalid inputs** — form validation bugs are common
4. **Scroll through long pages** — content below the fold may have rendering issues
5. **Test navigation flows end-to-end** — click through multi-step processes
6. **Don't forget edge cases**: empty states, very long text, special characters, rapid clicking
7. **Include `MEDIA:<screenshot_path>`** in reports so users see evidence inline

### Browser Tools Reference

| Tool | Purpose |
|------|---------|
| `browser_navigate` | Go to a URL |
| `browser_snapshot` | Get DOM text snapshot (accessibility tree) |
| `browser_click` | Click element by ref (`@eN`) or text |
| `browser_type` | Type into input field |
| `browser_scroll` | Scroll up/down |
| `browser_back` | Go back in browser history |
| `browser_press` | Press keyboard key |
| `browser_vision` | Screenshot + AI analysis; `annotate=true` for element labels |
| `browser_console` | Get JS console output and errors |

---

## Methodology Selection Guide

| Situation | Methodology |
|-----------|-------------|
| Bug/error/crash investigation | **Debugging** (4-phase root cause) |
| Writing new features | **TDD** (RED-GREEN-REFACTOR) |
| Refactoring existing code | **TDD** (characterization tests first, then refactor) |
| Testing web app for bugs | **QA** (5-phase exploratory testing) |
| Unknown issue type | Start with **Debugging** Phase 1, then switch as needed |

## Common Pitfalls Across All Methodologies

1. **Skipping investigation** — jumping to fixes without understanding root cause
2. **Skipping tests** — writing code without verifying it works
3. **Skipping verification** — assuming the fix works without testing
4. **Big steps** — trying to fix/implement too much at once
5. **Ignoring evidence** — dismissing data that contradicts your hypothesis
6. **Not checking console** — missing silent JS errors in QA
7. **Fixing symptoms** — addressing surface issues instead of root causes

## Verification Checklists

### After Debugging
- [ ] Root cause identified and documented
- [ ] Fix addresses root cause, not just symptoms
- [ ] Original issue is resolved
- [ ] Related functionality still works
- [ ] Edge cases tested
- [ ] Retrospective completed

### After TDD
- [ ] Every production line has a failing test that justified it
- [ ] All tests pass
- [ ] Code is refactored (no duplication, clear names)
- [ ] No extra features snuck in
- [ ] Tests are readable and document behavior

### After QA
- [ ] All planned areas tested
- [ ] Console checked after every navigation/interaction
- [ ] Issues de-duplicated and categorized
- [ ] Screenshots captured for all issues
- [ ] Report includes executive summary and per-issue details
- [ ] Screenshots referenced with `MEDIA:` paths
