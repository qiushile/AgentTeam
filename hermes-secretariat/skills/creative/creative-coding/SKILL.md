---
name: creative-coding
description: "Creative coding: p5.js sketches, Manim animations, Pretext text layouts."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [creative-coding, p5js, manim, pretext, generative-art, animation, visualization]
    category: creative
---

# Creative Coding

Programmatic visual art: browser-based generative sketches (p5.js), educational math animations (Manim CE), and typographic text layouts (Pretext).

## When to Use

- User asks for generative art, creative coding, or visual sketches → **p5.js**
- User asks for math/algorithm explainer videos → **Manim**
- User asks for text-based visual art, kinetic typography → **Pretext**
- User asks for interactive visualizations → **p5.js**
- User asks for 3Blue1Brown-style animations → **Manim**

## Decision Tree

1. **Is the output a video/animation that teaches a concept?** → Manim
2. **Is it an interactive browser sketch or generative art?** → p5.js
3. **Is it text-as-geometry or kinetic typography?** → Pretext
4. **Is it a static diagram?** → Use `visual-design` skill instead

---

## 1. p5.js — Browser-Based Creative Coding

**When:** Generative art, data visualization, interactive experiences, WebGL shaders, audio-reactive visuals.

**Creative Standard:**
- *Concept First:* Articulate the creative concept before writing code. What does it communicate?
- *First-Render Excellence:* Must be visually striking on first load. If it looks like a tutorial exercise, it's wrong.
- *Beyond Reference Vocabulary:* Noise functions, particle systems are a starting vocabulary. Combine, layer, invent.
- *Proactively Creative:* Add at least one visual detail the user didn't ask for.
- *Dense & Layered:* Never flat white backgrounds. Always compositional hierarchy.
- *Cohesive Aesthetic:* Shared color temperature, consistent stroke weight, harmonious motion.

**Modes:** Generative art, Data visualization, Interactive experience, Animation/motion graphics, 3D scene, Image processing, Audio-reactive.

**Thinking Framework:**
1. Near (literal): direct translation of prompt.
2. Medium (interesting): specific but unexpected.
3. Far (abstract): prime numbers, asymptotic curves, color of 3am.
*Decision:* Develop medium-distance associations.

**Setup:** See `scripts/p5js-setup.sh` for environment setup.
**Export:** See `scripts/p5js-export-frames.js` and `scripts/p5js-render.sh` for frame export.
**Serve:** See `scripts/p5js-serve.sh` for local development server.

**References:**
- `references/p5js-core-api.md` — Core API reference
- `references/p5js-color-systems.md` — Color modes and palettes
- `references/p5js-shapes-and-geometry.md` — Shape primitives
- `references/p5js-animation.md` — Animation techniques
- `references/p5js-interaction.md` — Mouse/keyboard interaction
- `references/p5js-typography.md` — Text rendering
- `references/p5js-visual-effects.md` — Post-processing effects
- `references/p5js-webgl-and-3d.md` — WebGL mode
- `references/p5js-export-pipeline.md` — Frame export and recording
- `references/p5js-troubleshooting.md` — Common issues

**Templates:**
- `templates/p5js-viewer.html` — HTML viewer template

---

## 2. Manim CE — Educational Math Animations

**When:** Concept explainers, equation derivations, algorithm visualizations, data stories, paper explainers.

**Creative Standard:**
- *Narrative Arc:* Articulate the "aha moment" and visual story before coding.
- *Geometry Before Algebra:* Show the shape first, equation second.
- *First-Render Excellence:* Visually clear and aesthetically cohesive without revision rounds.
- *Opacity Layering:* Primary=1.0, Contextual=0.4, Structural=0.15.
- *Breathing Room:* Every animation needs `self.wait()`. 2-second pause after key reveal.
- *Cohesive Visual Language:* Shared color palette, consistent typography, matching speeds.

**Modes:** Concept explainer, Equation derivation, Algorithm visualization, Data story, Architecture diagram, Paper explainer, 3D visualization.

**Stack:** Manim CE (Core), LaTeX (Math), ffmpeg (Video I/O), ElevenLabs/Qwen3-TTS (Optional TTS).

**Thinking Framework:**
- *Eliminate:* Remove all notation, explain purely through animation/spatial relationships.
- *Assumption Reversal:* List standard visualization assumptions, pick the most fundamental, reverse it.

**Setup:** See `scripts/manim-setup.sh` for environment setup.

**References:**
- `references/manim-scene-planning.md` — Scene structure and planning
- `references/manim-production-quality.md` — Production standards
- `references/manim-decorations.md` — Decorative elements
- `references/manim-troubleshooting.md` — Common issues
- `references/manim-camera-and-3d.md` — Camera and 3D objects
- `references/manim-equations.md` — Equation rendering
- `references/manim-graphs-and-data.md` — Graphs and data visualization
- `references/manim-visual-design.md` — Visual design principles
- `references/manim-rendering.md` — Rendering settings
- `references/manim-animation-design-thinking.md` — Design thinking for animations
- `references/manim-animations.md` — Animation techniques
- `references/manim-mobjects.md` — Mathematical objects
- `references/manim-updaters-and-trackers.md` — Updaters and value trackers
- `references/manim-paper-explainer.md` — Paper explainer workflow

---

## 3. Pretext — DOM-Free Text Layout

**When:** Text flowing around moving shapes, ASCII-art with real words, text-as-geometry games, kinetic typography, shrink-wrap UI.

**Author:** Cheng Lou (React core, ReasonML, Midjourney). 15KB zero-dependency TS library.

**Core Primitive:** Given `(text, font, width)`, returns line breaks, per-line widths, per-grapheme positions, total height via canvas measurement (no reflow).

**Don't Use For:** Static SVG/HTML (use CSS), rich text editors, image-to-text (use ascii-art), pure canvas gen art with no text (use p5js).

**Creative Standard:**
- *No Hello World:* Must add intentional color, motion, composition, and one unrequested visual detail.
- *Palettes:* Dark backgrounds, warm cores (amber-on-black, cold-white-on-charcoal, desaturated pastels).
- *Proportional Fonts:* Lean into non-monospaced (Iowan Old Style, Inter, JetBrains Mono, Helvetica Neue).
- *Real Text:* No lorem ipsum. Use short manifestos or meaningful corpus.

**Community Corpus:** pretext-breaker, tetris-pretext, PreTextExperiments, somnai-dreams/pretext-demos, bad-apple-pretext, dokobot/pretext-demo, SmisLee/alarmy-pretext-demo. Official playground: chenglou.me/pretext.

**References:**
- `references/pretext-patterns.md` — Common patterns and techniques

**Templates:**
- `templates/pretext-hello-orb-flow.html` — Orbital flow example
- `templates/pretext-donut-orbit.html` — Donut orbit example

---

## Shared Principles

All three tools share these creative coding principles:

1. **Concept First:** Articulate what you're communicating before writing code.
2. **First-Render Excellence:** Must be visually striking on first load.
3. **Proactively Creative:** Add at least one detail the user didn't ask for.
4. **Cohesive Aesthetic:** Shared color temperature, consistent style, harmonious motion.
5. **Beyond Reference Vocabulary:** Combine, layer, invent. Don't just use the default examples.

## Pitfalls

- **p5js:** Default canvas size (100x100) is too small. Always set explicit size.
- **p5js:** `noLoop()` stops draw() — use `redraw()` for one-shot updates.
- **Manim:** Forgetting `self.wait()` makes animations feel rushed.
- **Manim:** LaTeX compilation errors are silent — check the log.
- **Pretext:** Using monospace fonts defeats the purpose — use proportional fonts.
- **Pretext:** Lorem ipsum looks lazy — use real text.
