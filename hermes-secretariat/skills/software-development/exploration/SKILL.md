---
name: exploration
description: "Pre-build validation: throwaway experiments (spikes) for technical feasibility and HTML mockups (sketches) for design direction. Validate before committing."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [spike, sketch, prototype, experiment, feasibility, mockup, design, exploration, throwaway, validation]
    related_skills: [plan, code-review]
---

# Exploration — Validate Before You Build

Two complementary techniques for reducing uncertainty before committing to a real build:

1. **Spikes** — throwaway code experiments to validate technical feasibility
2. **Sketches** — disposable HTML mockups to compare design directions

Both are disposable by design. Throw them away once they've paid their debt.

---

## Part 1: Spikes — Technical Feasibility

Use when: "let me try this", "I want to see if X works", "spike this out", "is this even possible?", "compare A vs B".

**Don't use when:** the answer is knowable from docs or reading code (just research), the work is production path (use `plan`), or the idea is already validated.

### Core Method

```
decompose  →  research  →  build  →  verdict
   ↑__________________________________________↓
                  iterate on findings
```

### Step 1: Decompose

Break the idea into **2-5 independent feasibility questions**. Each question is one spike:

| # | Spike | Validates (Given/When/Then) | Risk |
|---|-------|----------------------------|------|
| 001 | websocket-streaming | Given a WS connection, when LLM streams tokens, then client receives chunks < 100ms | High |
| 002a | pdf-parse-pdfjs | Given a multi-page PDF, when parsed with pdfjs, then structured text is extractable | Medium |
| 002b | pdf-parse-camelot | Given a multi-page PDF, when parsed with camelot, then structured text is extractable | Medium |

**Order by risk.** The spike most likely to kill the idea runs first.

### Step 2: Research (brief, per spike)

1. Brief it: 2-3 sentences on what this spike is, why it matters, key risk.
2. Surface competing approaches if there's real choice.
3. Pick one. State why.
4. Skip research for pure logic with no external dependencies.

### Step 3: Build

One directory per spike. Keep it standalone:
```
spikes/
├── 001-websocket-streaming/
│   ├── README.md
│   └── main.py
├── 002a-pdf-parse-pdfjs/
│   ├── README.md
│   └── parse.js
```

**Bias toward something the user can interact with.** Default choices:
1. Runnable CLI with observable output
2. Minimal HTML page demonstrating behavior
3. Small web server with one endpoint
4. Unit test with recognizable assertions

**Depth over speed.** Never declare "it works" after one happy-path run. Test edge cases.

### Step 4: Verdict

Each spike's `README.md` closes with:
```markdown
## Verdict: VALIDATED | PARTIAL | INVALIDATED

### What worked / What didn't / Surprises
### Recommendation for the real build
```

**VALIDATED** = core question answered yes, with evidence.
**PARTIAL** = works under constraints X, Y, Z — document them.
**INVALIDATED** = doesn't work. This is a successful spike.

### Comparison Spikes (002a / 002b)

Build back to back, then head-to-head:
```markdown
| Dimension | pdfjs (002a) | camelot (002b) |
|-----------|--------------|----------------|
| Extraction quality | 9/10 structured | 7/10 table-only |
| Setup complexity | npm install, 1 line | pip + ghostscript |
| Perf on 100-page PDF | 3s | 18s |
```

For parallel comparison spikes that need real engineering, fan out with `delegate_task`.

---

## Part 2: Sketches — Design Direction

Use when: "sketch this screen", "show me what X could look like", "compare layout A vs B", "give me 2-3 takes on this UI", "mockup this before I build".

**Don't use when:** user wants production code (build it properly), a polished one-off artifact (`claude-design`), a diagram (`excalidraw`, `architecture-diagram`), or the design is already locked.

### Core Method

```
intake  →  variants  →  head-to-head  →  pick winner (or iterate)
```

### Step 1: Intake (skip if user gave enough)

Get three things — one question at a time:
1. **Feel.** "What should this feel like? Adjectives, emotions, a vibe."
2. **References.** "What apps, sites, or products capture the feel?"
3. **Core action.** "What's the single most important thing a user does on this screen?"

### Step 2: Variants (2-3, never 1, rarely 4+)

Each variant is a complete, standalone HTML file. Each should take a **different design stance**, not different pixel values:

- **Density:** compact / airy / ultra-dense
- **Emphasis:** content-first / action-first / tool-first
- **Aesthetic:** editorial / utilitarian / playful
- **Layout:** single-column / sidebar / split-pane

**Variant naming:** describe the stance, not the number.
```
sketches/
├── 001-calm-editorial/index.html + README.md
├── 001-utilitarian-dense/index.html + README.md
└── 001-playful-split/index.html + README.md
```

### Step 3: Make them real HTML

Each variant is a **single self-contained HTML file**:
- Inline `<style>`, system fonts or one Google Font
- Tailwind via CDN is fine
- Realistic fake content — actual sentences, not "Lorem ipsum"
- **Interactive**: links clickable, hovers real, at least one state transition

**Verify variants visually — use browser tools:**
```
browser_navigate(url="file:///absolute/path/to/sketches/001-calm-editorial/index.html")
browser_vision(question="Does this layout look clean and readable?")
```

### Step 4: Variant README

Each variant's `README.md`:
```markdown
## Variant: {stance name}
### Design stance — one sentence
### Key choices — Layout, Typography, Color, Interaction
### Trade-offs — Strong at / Weak at
### Best for — the kind of user/use case
```

### Step 5: Head-to-head

Present as a comparison table. **Opinionate:**
```markdown
| Dimension | Calm editorial | Utilitarian dense | Playful split |
|-----------|----------------|-------------------|---------------|
| Density   | Low            | High              | Medium        |
| Feel      | Calm, trusted  | Sharp, tool-like  | Inviting      |

**My take:** Utilitarian dense for power users, calm editorial for content-forward.
```

### Interactivity bar

A sketch is interactive enough when the user can:
1. Click a primary action and something visible happens
2. See one meaningful state transition
3. Hover recognizable affordances

---

## Output Conventions

- **Spikes:** `spikes/` (or `.planning/spikes/` with GSD conventions) in repo root
- **Sketches:** `sketches/` (or `.planning/sketches/`)
- One subdir per item: `NNN-descriptive-name/`
- Keep everything disposable — a spike/sketch that you felt the need to preserve should be promoted into real project code
