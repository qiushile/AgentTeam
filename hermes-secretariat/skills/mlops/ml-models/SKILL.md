---
name: ml-models
description: "ML model tools: AudioCraft (MusicGen text-to-music, AudioGen text-to-sound) and Segment Anything (SAM zero-shot image segmentation)."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [ML, AudioCraft, MusicGen, SAM, image-segmentation, text-to-music]
---

# ML Models Suite

Unified skill for specialized ML models: audio generation and image segmentation.

---

## Section A: AudioCraft (MusicGen + AudioGen)

Generate music and sound effects from text prompts using Meta's AudioCraft.

**MusicGen**: Text-to-music generation. Create songs, instrumentals, and musical pieces from text descriptions.
**AudioGen**: Text-to-sound generation. Create sound effects, ambient sounds, and Foley from text.

**Key features**:
- Text prompt → audio generation
- Multiple model sizes (small, medium, large)
- Conditioning on melody/chords (MusicGen)
- Duration control

**Typical workflow**:
1. Define text prompt describing the audio
2. Select model size based on quality needs
3. Generate audio → save as WAV/MP3
4. Optionally post-process (trim, fade, normalize)

---

## Section B: Segment Anything Model (SAM)

Zero-shot image segmentation via points, boxes, or masks using Meta's SAM.

**Best for**: Object segmentation without training, interactive segmentation, instance segmentation.

**Key features**:
- Zero-shot: no training data needed
- Multiple input modes: points, boxes, masks
- High-quality segmentation masks
- Works with any image

**Typical workflow**:
1. Load image
2. Provide segmentation input (point click, bounding box, or text prompt)
3. SAM generates mask(s)
4. Apply mask for downstream tasks (editing, analysis, extraction)