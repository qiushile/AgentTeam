---
name: ascii-creative
description: "ASCII creative suite: text banners, message art, image-to-ASCII conversion, and full ASCII video production pipeline."
version: 1.0.0
author: Hermes Agent (adapted from 0xbyt4)
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [ASCII, Art, Video, Creative, Unicode, Text-Art, pyfiglet, cowsay, boxes]
---

# ASCII Creative Suite

Unified skill for all ASCII-based creative generation. Two modes: quick ASCII art tools and full ASCII video production pipeline.

---

## Section A: ASCII Art Tools

Quick ASCII art generation for text banners, message art, decorative borders, and image conversion.

### A1: Text Banners (pyfiglet — local, 571 fonts)

```bash
pip install pyfiglet --break-system-packages -q
python3 -m pyfiglet "YOUR TEXT" -f slant
python3 -m pyfiglet --list_fonts
```

Recommended fonts: `slant` (clean), `doom` (bold), `big` (readable), `small` (compact), `cyberlarge` (tech).

### A2: Text Banners (asciified API — remote, no install)

```bash
curl -s "https://asciified.thelicato.io/api/v2/ascii?text=Hello+World"
curl -s "https://asciified.thelicato.io/api/v2/ascii?text=Hello&font=Slant"
curl -s "https://asciified.thelicato.io/api/v2/fonts"
```

### A3: Cowsay (Message Art)

```bash
cowsay "Hello World"
cowsay -f tux "Linux rules"
cowsay -l  # List all characters (50+)
```

### A4: Boxes (Decorative Borders)

```bash
echo "Hello World" | boxes -d stone
echo "Hello World" | boxes -d cat
boxes -l  # List all 70+ designs
```

### A5: TOIlet (Colored Text Art)

```bash
toilet "Hello World" --gay  # Rainbow coloring
toilet -F border --gay "Fancy!"  # Combined effects
```

### A6: Image to ASCII

```bash
ascii-image-converter image.png -C  # Color output
ascii-image-converter image.png -b  # Braille characters
jp2a --colors image.jpg  # JPEG only, lightweight
```

### A7: Search Pre-Made Art

```bash
curl -s 'https://ascii.co.uk/art/cat' -o /tmp/ascii_art.html
# Extract with Python: re.findall(r'<pre[^>]*>(.*?)</pre>', text, re.DOTALL)
curl -s https://api.github.com/octocat  # Octocat easter egg
```

### A8: Fun Utilities

```bash
curl -s "qrenco.de/https://example.com"  # QR codes as ASCII
curl -s "wttr.in/London"  # Weather as ASCII
```

### Decision Flow

1. Text as banner → pyfiglet (installed) or asciified API (no install)
2. Wrap message in character → cowsay
3. Add decorative border → boxes
4. Art of specific thing → ascii.co.uk
5. Convert image → ascii-image-converter or jp2a
6. QR code → qrenco.de
7. Weather → wttr.in
8. Custom/creative → LLM with Unicode palette

---

## Section B: ASCII Video Production

Full production pipeline for ASCII art video — converts video/audio/images into colored ASCII character video (MP4, GIF).

### Modes

| Mode | Input | Output |
|------|-------|--------|
| Video-to-ASCII | Video file | ASCII recreation |
| Audio-reactive | Audio file | Generative visuals |
| Generative | None | Procedural animation |
| Hybrid | Video + audio | ASCII video with overlays |
| Lyrics/text | Audio + text/SRT | Timed text with effects |

### Pipeline Architecture

```
INPUT → ANALYZE → SCENE_FN → TONEMAP → SHADE → ENCODE
```

1. **INPUT**: Load/decode source
2. **ANALYZE**: Extract per-frame features
3. **SCENE_FN**: Render to pixel canvas
4. **TONEMAP**: Percentile-based adaptive brightness normalization
5. **SHADE**: Post-processing via ShaderChain + FeedbackBuffer
6. **ENCODE**: Pipe raw RGB frames to ffmpeg

### Stack

Single self-contained Python script per project. Python 3.10+, NumPy, SciPy, Pillow, ffmpeg, concurrent.futures.

### Creative Standard

- Articulate creative concept BEFORE writing code
- First-render excellence — output must be visually striking without revision
- Cohesive aesthetic over technical correctness
- Dense, layered, considered — every frame should reward viewing
- Per-section variation: different background effect, character palette, color strategy, shader intensity

### Key Implementation Details

**Tonemap (CRITICAL)** — use adaptive tonemap, NOT linear multipliers:
```python
def tonemap(canvas, gamma=0.75):
    f = canvas.astype(np.float32)
    lo, hi = np.percentile(f[::4, ::4], [1, 99.5])
    if hi - lo < 10: hi = lo + 10
    f = np.clip((f - lo) / (hi - lo), 0, 1) ** gamma
    return (f * 255).astype(np.uint8)
```

**Font cell height** — macOS Pillow: `textbbox()` returns wrong height. Use `font.getmetrics()`: `cell_height = ascent + descent`.

**ffmpeg pipe deadlock** — never `stderr=subprocess.PIPE` with long-running ffmpeg. Redirect to file.

### References

| File | Contents |
|------|----------|
| `references/architecture.md` | Grid system, palettes, color system |
| `references/composition.md` | Blend modes, tonemap, feedback, masking |
| `references/effects.md` | Effect building blocks, particles, transforms |
| `references/shaders.md` | ShaderChain, 38 shader catalog, transitions |
| `references/scenes.md` | Scene protocol, Renderer class, design patterns |
| `references/inputs.md` | Audio analysis, video sampling, TTS integration |
| `references/optimization.md` | Hardware detection, quality profiles, parallel rendering |
| `references/troubleshooting.md` | NumPy traps, blend pitfalls, font issues |

### Performance Targets

| Component | Budget |
|-----------|--------|
| Feature extraction | 1-5ms |
| Effect function | 2-15ms |
| Character render | 80-150ms (bottleneck) |
| Shader pipeline | 5-25ms |
| **Total** | ~100-200ms/frame |

---

## Pitfalls

1. **ASCII video brightness** — always use `tonemap()`, never `canvas * N` multipliers
2. **Font cell height on macOS** — use `getmetrics()`, not `textbbox()`
3. **ffmpeg deadlock** — redirect stderr to file, never PIPE
4. **Unicode font compatibility** — validate palettes at init
5. **CWD drift** — use absolute paths for all file operations