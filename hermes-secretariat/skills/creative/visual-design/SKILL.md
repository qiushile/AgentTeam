---
name: visual-design
description: "Visual design artifacts: HTML/SVG/JSON diagrams, design systems, brand templates."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [design, visual, diagrams, svg, html, excalidraw, design-systems, brand-templates]
    category: creative
---

# Visual Design Artifacts

Create visual design outputs: HTML artifacts, SVG diagrams, JSON diagrams, design token specs, and brand design systems.

## When to Use

- User asks for a diagram (architecture, flow, sequence, infrastructure)
- User asks for a design system or brand template
- User asks for visual artifacts (HTML, SVG, JSON)
- User asks for design tokens or spec files

## Subsections

### 1. Design Process & Taste (HTML Artifacts)

**When:** Creating HTML artifacts with intentional design — landing pages, dashboards, prototypes, UI components.

**Core Principles:**
- **No generic AI output.** Every artifact must have intentional color, typography, spacing, and one unrequested visual detail.
- **Color dominance over equality.** 60-70% primary, 1-2 supporting, 1 sharp accent. Never equal distribution.
- **Contrast strategy.** Dark backgrounds for title/conclusion, light for content (sandwich), or commit to dark throughout.
- **Visual motif.** Pick ONE distinctive element (rounded frames, colored circle icons, thick single-side borders) and repeat.
- **Proportional systems.** Use 8px grid, 1.5 line-height, 1.25 type scale. Consistency over variety.

**Specific Palettes (Hex Codes):**
- Midnight Executive: `1E2761` (navy), `CADCFC` (ice blue), `FFFFFF` (white)
- Forest & Moss: `2C5F2D` (forest), `97BC62` (moss), `F5F5F5` (cream)
- Coral Energy: `F96167` (coral), `F9E795` (gold), `2F3C7E` (navy)
- Warm Terracotta: `B85042` (terracotta), `E7E8D1` (sand), `A7BEAE` (sage)
- Ocean Gradient: `065A82` (deep blue), `1C7293` (teal), `21295C` (midnight)
- Charcoal Minimal: `36454F` (charcoal), `F2F2F2` (off-white), `212121` (black)
- Teal Trust: `028090` (teal), `00A896` (seafoam), `02C39A` (mint)
- Berry & Cream: `6D2E46` (berry), `A26769` (dusty rose), `ECE2D0` (cream)
- Sage Calm: `84B59F` (sage), `69A297` (eucalyptus), `50808E` (slate)
- Cherry Bold: `990011` (cherry), `FCF6F5` (off-white), `2F3C7E` (navy)

**Thinking Framework:**
1. **Eliminate:** Remove all decoration, explain purely through layout and whitespace.
2. **Assumption Reversal:** List standard design assumptions (e.g., light background, centered layout), pick the most fundamental, reverse it, explore what the reversal reveals.

**Pitfalls:**
- Default sans-serif fonts look generic. Use system font stacks or specific choices (Inter, Iowan Old Style, JetBrains Mono).
- White backgrounds with colored text look like a tutorial exercise. Add texture, gradient, or dark mode.
- Equal distribution of colors looks amateur. Commit to dominance.

---

### 2. Architecture Diagrams (SVG as HTML)

**When:** Infrastructure diagrams, cloud architecture, system topology, network layouts.

**Output Format:** Single HTML file with embedded SVG. Dark theme (charcoal/slate background, light strokes).

**Core Principles:**
- **Dark theme mandatory.** Background `#1a1a1a` or `#0d1117`. Strokes `#e1e4e8` or `#c9d1d9`.
- **Component boxes.** Rounded rectangles (rx=8), subtle borders, optional fill for grouping.
- **Connection lines.** Straight or orthogonal paths. Arrowheads for data flow. Dashed for optional/async.
- **Labels.** Sans-serif, 14-16px, high contrast. Group labels smaller (12px) and muted.
- **Color coding.** Use color to indicate component type: databases (blue), services (green), external (orange), users (purple).

**SVG Structure:**
```html
<svg viewBox="0 0 800 600" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 0 L 10 5 L 0 10 z" fill="#c9d1d9"/>
    </marker>
  </defs>
  <rect width="800" height="600" fill="#0d1117"/>
  <!-- Components -->
  <rect x="50" y="50" width="150" height="80" rx="8" fill="#161b22" stroke="#30363d" stroke-width="2"/>
  <text x="125" y="95" font-family="system-ui" font-size="14" fill="#c9d1d9" text-anchor="middle">Service A</text>
  <!-- Connections -->
  <line x1="200" y1="90" x2="350" y2="90" stroke="#c9d1d9" stroke-width="2" marker-end="url(#arrow)"/>
</svg>
```

**Pitfalls:**
- Don't use light backgrounds — they look like whiteboard sketches, not polished diagrams.
- Don't mix straight and curved lines arbitrarily. Commit to orthogonal or free-form.
- Don't forget arrowheads for directional flow.

---

### 3. Excalidraw Diagrams (JSON)

**When:** Hand-drawn style diagrams, whiteboard sketches, informal architecture, flowcharts.

**Output Format:** `.excalidraw` JSON file (or embedded in markdown).

**Core Principles:**
- **Hand-drawn aesthetic.** Rough edges, slight imperfections, casual feel.
- **Minimal color.** Black strokes, optional light fills (yellow, blue, green). No gradients.
- **Simple shapes.** Rectangles, ellipses, arrows, text. No complex paths.
- **Roughness > 0.** Use `roughness: 1` for hand-drawn look. `roughness: 0` is too clean.

**JSON Structure:**
```json
{
  "type": "excalidraw",
  "version": 2,
  "elements": [
    {
      "type": "rectangle",
      "x": 100,
      "y": 100,
      "width": 200,
      "height": 100,
      "strokeColor": "#000000",
      "backgroundColor": "transparent",
      "fillStyle": "hachure",
      "strokeWidth": 2,
      "roughness": 1,
      "opacity": 100
    },
    {
      "type": "text",
      "x": 150,
      "y": 140,
      "text": "Component",
      "fontSize": 20,
      "fontFamily": 1,
      "strokeColor": "#000000"
    }
  ]
}
```

**Pitfalls:**
- Don't use `roughness: 0` — it defeats the purpose of Excalidraw.
- Don't add too many colors. Stick to black + 1-2 accent fills.
- Don't forget to set `fontFamily: 1` (Virgil) for the hand-drawn font.

---

### 4. Design Token Specs (DESIGN.md)

**When:** Authoring Google's DESIGN.md token spec files for design systems.

**Output Format:** Markdown file with YAML frontmatter and structured token definitions.

**Core Principles:**
- **Token hierarchy.** Global → Alias → Component-specific. Never skip levels.
- **Semantic naming.** `color.primary.action` not `blue-500`. Names describe intent, not value.
- **Value formats.** Colors as hex, spacing as px/rem, typography as object (fontFamily, fontSize, lineHeight, fontWeight).

**Structure:**
```markdown
---
name: design-system
version: 1.0.0
---

# Design Tokens

## Color

### Global
- `color.blue.500`: `#1a73e8`
- `color.gray.100`: `#f8f9fa`

### Alias
- `color.primary.action`: `color.blue.500`
- `color.surface.default`: `color.gray.100`

## Spacing

### Global
- `spacing.1`: `4px`
- `spacing.2`: `8px`

### Alias
- `spacing.component.padding`: `spacing.2`

## Typography

### Global
- `font.family.primary`: `Google Sans`
- `font.size.body`: `14px`

### Alias
- `typography.body.default`: 
  - fontFamily: `font.family.primary`
  - fontSize: `font.size.body`
  - lineHeight: `20px`
```

**Pitfalls:**
- Don't mix value formats. If colors are hex, keep them hex throughout.
- Don't skip the alias layer. Global tokens are raw values; aliases are semantic.
- Don't forget to document the token hierarchy in the file header.

---

### 5. Brand Design Systems (Reference Library)

**When:** User asks for a specific brand's design system (e.g., "make it look like Stripe" or "use Linear's style").

**Output Format:** HTML/CSS implementing the brand's visual language.

**Available Brands (54 total):**
See `references/brand-index.md` for the full list with descriptions and use cases.

**Core Brands:**
- **Stripe:** Clean, professional, blue accent, generous whitespace, subtle shadows.
- **Linear:** Dark mode, purple accent, minimal borders, smooth animations.
- **Vercel:** Black/white, geometric, monospace accents, high contrast.
- **Notion:** Warm grays, rounded corners, playful illustrations, casual tone.
- **Figma:** Colorful, playful, rounded shapes, friendly typography.

**Implementation Pattern:**
```html
<!-- Stripe-style -->
<div style="background: #ffffff; padding: 64px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;">
  <h1 style="color: #0a2540; font-size: 48px; font-weight: 700; letter-spacing: -0.5px;">Headline</h1>
  <p style="color: #425466; font-size: 18px; line-height: 1.5; max-width: 600px;">Body text with generous line-height and muted color.</p>
  <button style="background: #0066cc; color: #ffffff; padding: 12px 24px; border-radius: 4px; font-size: 16px; font-weight: 500; border: none; cursor: pointer;">Call to action</button>
</div>
```

**Pitfalls:**
- Don't copy brands verbatim — adapt their principles to the user's content.
- Don't mix brand styles. Commit to one brand's visual language per artifact.
- Don't forget the brand's typography — it's as important as color.

---

## Decision Tree

1. **User asks for a diagram?**
   - Infrastructure/system → **Architecture Diagrams** (SVG as HTML, dark theme)
   - Informal/whiteboard → **Excalidraw** (JSON, hand-drawn)
   - Flow/sequence → **Architecture Diagrams** or **Excalidraw** depending on formality

2. **User asks for a design system or brand template?**
   - Specific brand → **Brand Design Systems** (reference library)
   - Custom design system → **Design Process & Taste** (HTML artifacts)
   - Token spec file → **Design Token Specs** (DESIGN.md)

3. **User asks for visual artifacts?**
   - HTML/CSS → **Design Process & Taste** or **Brand Design Systems**
   - SVG → **Architecture Diagrams**
   - JSON → **Excalidraw**

## References

- `references/brand-index.md` — Full list of 54 brand design systems with descriptions
- `references/excalidraw-schema.md` — Complete Excalidraw JSON schema
- `references/design-tokens-spec.md` — Google DESIGN.md token spec format

## Scripts

- `scripts/validate-design-tokens.py` — Validate DESIGN.md token files for consistency
