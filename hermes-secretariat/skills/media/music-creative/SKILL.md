---
name: music-creative
description: "Music creative suite: AI music generation (Suno/HeartMuLa), audio analysis (songsee), and songwriting craft."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [music, songwriting, audio-analysis, AI-music, Suno]
---

# Music Creative Suite

Unified skill for all music-related creative workflows. Three modes: AI music generation, audio feature analysis, and songwriting craft.

---

## Section A: AI Music Generation (HeartMuLa + Suno)

Generate music from lyrics + tags using HeartMuLa (local) or Suno API.

### HeartMuLa
Local song generation from lyrics and style tags. Use when you need full control over generation without external API dependencies.

**Workflow**: Provide lyrics + genre/style tags → generate audio → deliver to user.

### Suno AI Music
Use the `songwriting-and-ai-music` skill for Suno AI prompts and workflows.

**Key conventions**:
- Lyrics should be structured (verse, chorus, bridge)
- Style tags control genre, mood, instrumentation
- Always specify tempo, key, and instrumentation preferences
- Suno generates full songs (~2-4 minutes)

---

## Section B: Audio Analysis (songsee)

Extract audio spectrograms and features (mel, chroma, MFCC) via CLI.

**Use when**: User asks about audio characteristics, wants to analyze a song's structure, or needs feature extraction for ML/audio ML tasks.

**Features**:
- Mel spectrograms: frequency-time representation
- Chroma features: pitch class energy over time
- MFCC: timbral characteristics
- Beat detection and tempo estimation

---

## Section C: Songwriting Craft

Songwriting craft guidance and AI music prompts.

**Key principles**:
- Structure matters: verse-chorus-verse-chorus-bridge-chorus is standard
- Lyrics should match the rhythm and mood of the intended style
- Hook/chorus should be memorable and repeatable
- Bridge provides contrast before final chorus
- For AI generation, be explicit about style, mood, instrumentation, and structure in prompts

---

## Pitfalls

1. **AI music generation is stochastic** — multiple generations may be needed for quality results
2. **Lyrics structure affects output** — unstructured text produces unstructured music
3. **Style tags are powerful** — be specific about genre, mood, era, instrumentation
4. **Audio analysis requires the actual audio file** — cannot analyze from text description alone