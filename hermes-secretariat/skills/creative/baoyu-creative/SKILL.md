---
name: baoyu-creative
description: "Baoyu creative suite: article illustrations, knowledge comics, and infographics with consistent type × style × palette workflows."
version: 1.0.0
author: Hermes Agent (adapted from 宝玉/JimLiu baoyu-skills)
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [creative, image-generation, article-illustration, comic, infographic]
    category: creative
---

# Baoyu Creative Suite

Unified skill for all Baoyu (宝玉/JimLiu) creative generation workflows. All three modes share the same core conventions: `image_generate` for rendering, `clarify` for user confirmation, prompt-file-as-reproducibility-record, and style/type/palette dimension systems.

## Shared Conventions

- **Image generation**: Use Hermes' `image_generate` tool (prompt + aspect_ratio → URL). Download returned URLs to local PNGs via `curl -fsSL "<url>" -o <absolute-path>`. Always use absolute paths for `-o`.
- **Aspect ratio mapping**: `16:9` → `landscape`, `9:16` → `portrait`, `1:1` → `square`. Custom ratios → nearest named aspect.
- **Prompt files**: Write the full final prompt to a file under `prompts/` BEFORE calling `image_generate`. The prompt file is the reproducibility record.
- **Clarify workflow**: Use `clarify` tool for confirmations (one question at a time). Ask the most important question first. If clarify times out, treat as default for THAT question only and continue asking remaining questions — surface defaults visibly so user can correct.
- **Data integrity**: Never summarize, paraphrase, or alter source statistics. Strip all credentials/secrets from source content before including in output.
- **Backup rule**: When regenerating, rename existing files with `-backup-YYYYMMDD-HHMMSS` suffix.
- **Output structure**: `{type}/{topic-slug}/` with `source-{slug}`, `analysis.md`, `prompts/`, and generated PNGs.

---

## Section A: Article Illustrations

**Trigger**: User asks to illustrate an article, add images to content, "为文章配图".

Three dimensions: **Type** × **Style** × **Palette**.

| Type | Best For |
|------|----------|
| `infographic` | Data, metrics, technical |
| `scene` | Narratives, emotional |
| `flowchart` | Processes, workflows |
| `comparison` | Side-by-side, options |
| `framework` | Models, architecture |
| `timeline` | History, evolution |

**Output**: `{article-dir}/imgs/` or `illustrations/{topic-slug}/` with `outline.md`, `prompts/NN-{type}-{slug}.md`, and `NN-{type}-{slug}.png`.

**Workflow**: Detect refs → Analyze content → Confirm settings (clarify) → Generate outline → Generate prompts → Generate images → Finalize (insert markdown image links).

Detailed procedures: `references/article-illustrator-workflow.md`
Style definitions: `references/article-illustrator-styles.md`

---

## Section B: Knowledge Comics

**Trigger**: User asks for knowledge/educational comic, biography comic, tutorial comic, "知识漫画".

Visual dimensions: **Art** × **Tone** × **Layout** × **Aspect**.

| Art Style | Tone | Layout |
|-----------|------|--------|
| ligne-claire, manga, realistic, ink-brush, chalk, minimalist | neutral, warm, dramatic, romantic, energetic, vintage, action | standard, cinematic, dense, splash, mixed, webtoon, four-panel |

**Presets**: `ohmsha`, `wuxia`, `shoujo`, `concept-story`, `four-panel` — each with special rules beyond plain art+tone.

**Output**: `comic/{topic-slug}/` with `storyboard.md`, `characters/characters.md`, `prompts/`, and page PNGs.

**Key**: Character consistency via text descriptions in `characters/characters.md` embedded inline in every page prompt. Character sheet PNG is human review artifact only.

Detailed procedures: `references/comic-workflow.md`
Character template: `references/character-template.md`
Storyboard template: `references/storyboard-template.md`

---

## Section C: Infographics

**Trigger**: User asks for infographic, visual summary, "信息图", "可视化", "高密度信息大图".

Two dimensions: **Layout** (21 options) × **Style** (21 options). Freely combine any layout with any style.

**Keyword shortcuts**: Auto-select layout when user input contains `高密度信息大图` → `dense-modules`, `信息图` → `bento-grid`.

**Output**: `infographic/{topic-slug}/` with `structured-content.md`, `prompts/infographic.md`, and `infographic.png`.

**Workflow**: Analyze → Generate structured content → Recommend combinations → Confirm (clarify) → Generate prompt → Generate image → Summary.

Detailed procedures: `references/infographic-workflow.md`
Layout definitions: `references/layouts/`
Style definitions: `references/styles/`

---

## Shared References

| File | Content |
|------|---------|
| `references/base-prompt.md` | Base prompt template for image generation |
| `references/analysis-framework.md` | Content analysis methodology |
| `references/article-illustrator-workflow.md` | Article illustration detailed procedures |
| `references/article-illustrator-styles.md` | Article illustration style gallery |
| `references/comic-workflow.md` | Knowledge comic detailed procedures |
| `references/character-template.md` | Character definition format |
| `references/storyboard-template.md` | Storyboard structure |
| `references/infographic-workflow.md` | Infographic detailed procedures |
| `references/layouts/` | 21 infographic layout definitions |
| `references/styles/` | Infographic style definitions |

## Pitfalls (All Modes)

1. **`image_generate` returns a URL, not a local file** — always download via `terminal` (`curl`) before using.
2. **Use absolute paths for `curl -o`** — persistent-shell CWD can drift between batches.
3. **No backend selection** — `image_generate` uses user-configured backend; don't write model names expecting routing.
4. **Prompt files are mandatory** — no image generation without a saved prompt file.
5. **Strip secrets** — scan source for API keys/tokens/credentials before any output.
6. **Never alter source data** — "73% increase" stays "73% increase".