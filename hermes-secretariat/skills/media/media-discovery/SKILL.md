---
name: media-discovery
description: "Media discovery: GIF search (Tenor), YouTube transcripts/summaries, and Spotify playback."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [media, GIF, YouTube, Spotify, search, transcripts]
---

# Media Discovery Suite

Unified skill for media discovery and playback: GIF search, YouTube content processing, and Spotify control.

---

## Section A: GIF Search (Tenor)

Search and download GIFs from Tenor via curl + jq. No API key needed for basic search.

**Search**:
```bash
curl -s "https://tenor.googleapis.com/v2/search?q=QUERY&key=API_KEY&limit=5" | jq '.results[] | {title, url, media_formats}'
```

**Download**: Use the `media_formats.gif.url` from search results, then `curl -sL URL -o output.gif`.

---

## Section B: YouTube Content Processing

Convert YouTube transcripts to summaries, threads, blogs, and other content formats.

**Workflow**:
1. Extract transcript from YouTube video (URL or video ID)
2. Process transcript into desired output format
3. Deliver: summary, Twitter thread, blog post, bullet notes, etc.

**Use when**: User asks to summarize a YouTube video, convert a transcript, or extract content from a video.

---

## Section C: Spotify Playback

Control Spotify playback: play, search, queue, manage playlists and devices.

**Use when**: User wants to play music, search for tracks/artists, manage playlists, or control playback on Spotify devices.