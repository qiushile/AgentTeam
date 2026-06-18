---
name: note-apps
description: "Note-taking app CLIs: Obsidian (filesystem vault, markdown, wikilinks) and Notion (API + ntn CLI, pages, databases, markdown, Workers)."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [notes, obsidian, notion, markdown, vault, database, api, cli, productivity]
---

# Note-Taking Apps — Obsidian & Notion

Two note-taking systems, accessed via different paradigms:

1. **Obsidian** — filesystem-first, markdown files in a vault, wikilinks
2. **Notion** — API-driven, pages + databases, ntn CLI or HTTP/curl

---

## Part 1: Obsidian Vault

Filesystem-first Obsidian vault work: reading notes, listing notes, searching, creating, appending, wikilinks.

### Vault Path

The vault path is the `OBSIDIAN_VAULT_PATH` environment variable (from `${HERMES_HOME:-~/.hermes}/.env`). If unset, use `~/Documents/Obsidian Vault`.

File tools do not expand shell variables — resolve the vault path first and pass a concrete absolute path. Vault paths may contain spaces.

If unknown, use `terminal` to resolve `OBSIDIAN_VAULT_PATH` or check the fallback. Once known, switch to file tools.

### Read a Note

Use `read_file` with the resolved absolute path. Prefer over `cat` (line numbers, pagination).

### List Notes

Use `search_files` with `target: "files"` and the vault path:
- All markdown notes: `pattern: "*.md"` under vault path
- Subfolder: search under that subfolder's absolute path

### Search

Use `search_files`:
- Filenames: `target: "files"`, filename `pattern`
- Contents: `target: "content"`, content regex as `pattern`, `file_glob: "*.md"`

### Create a Note

Use `write_file` with the resolved absolute path and full markdown content.

### Append to a Note

- `patch` for anchored append (after existing heading, before known trailing block)
- `write_file` when rewriting the whole note is clearer

### Wikilinks

Obsidian links notes with `[[Note Name]]` syntax. Use these when creating notes to link related content.

---

## Part 2: Notion — API + ntn CLI

Talk to Notion two ways. Same integration token works for both.

◆ **`ntn` CLI** — Notion's official CLI. Shorter syntax, one-line file uploads, required for Workers. macOS + Linux only. **Default when installed.**
◆ **HTTP + curl** — works everywhere including Windows. **Default fallback.**

### Setup

1. Create integration at https://notion.so/my-integrations
2. Copy API key (starts with `ntn_` or `secret_`)
3. Store in `${HERMES_HOME:-~/.hermes}/.env`: `NOTION_API_KEY=ntn_your_key_here`
4. **Share target pages/databases with the integration** in Notion: page menu `...` → `Connect to` → your integration name

### Install ntn (macOS / Linux)

```bash
curl -fsSL https://ntn.dev | bash
# Or: npm install --global ntn
```

Skip `ntn login` — use integration token instead:
```bash
export NOTION_API_TOKEN=$NOTION_API_KEY
export NOTION_KEYRING=0
```

### ntn CLI (preferred, macOS / Linux)

```bash
ntn api v1/users                                  # GET
ntn api v1/pages/{page_id}                        # Read page metadata
ntn api v1/pages/{page_id}/markdown               # Read as Markdown
ntn api v1/blocks/{page_id}/children              # Read blocks
ntn api v1/search query="page title"              # Search

# Create page from Markdown
ntn api v1/pages parent[page_id]=xxx \
  properties[title][0][text][content]="Notes" \
  markdown="# Agenda\n\n- Item 1\n- Item 2"

# Patch page with Markdown
ntn api v1/pages/{page_id}/markdown -X PATCH markdown="## Update\n\nDone."

# Query database
ntn api v1/data_sources/{id}/query -X POST \
  filter[property]=Status filter[select][equals]=Active

# File uploads (one-liner)
ntn files create < photo.png
```

### HTTP + curl (cross-platform)

All requests need:
```bash
-H "Authorization: Bearer $NOTION_API_KEY"
-H "Notion-Version: 2025-09-03"
-H "Content-Type: application/json"
```

Key endpoints:
- `GET /v1/pages/{id}` — page metadata
- `GET /v1/pages/{id}/markdown` — page as Markdown
- `GET /v1/blocks/{id}/children` — page content as blocks
- `POST /v1/search` — search
- `POST /v1/pages` — create page (accepts `markdown` body)
- `PATCH /v1/pages/{id}/markdown` — update page content
- `POST /v1/data_sources/{id}/query` — query database
- `POST /v1/file_uploads` → PUT bytes → reference in page (3-step file upload)

### API Version 2025-09-03 — Databases vs Data Sources

- Databases became **data sources** — use `/data_sources/` endpoints for queries
- Two IDs per database: `database_id` (for creating pages) and `data_source_id` (for querying)

### Property Types

- **Title:** `{"title": [{"text": {"content": "..."}}]}`
- **Select:** `{"select": {"name": "Option"}}`
- **Date:** `{"date": {"start": "2026-01-15"}}`
- **Checkbox:** `{"checkbox": true}`
- **Number:** `{"number": 42}`
- **Relation:** `{"relation": [{"id": "page_id"}]}`

### Notion Workers (advanced, requires ntn, Business/Enterprise plan)

Workers are TypeScript programs Notion hosts. Can expose Syncs, Tools, and Webhooks.

```bash
ntn workers new my-worker
cd my-worker
# Edit src/index.ts
ntn workers deploy --name my-worker
```

```typescript
import { Worker } from "@notionhq/workers";
const worker = new Worker();
export default worker;

worker.tool("greet", {
  title: "Greet a User",
  inputSchema: { type: "object", properties: { name: { type: "string" } }, required: ["name"] },
  execute: async ({ name }) => `Hello, ${name}!`,
});
```

Worker lifecycle: `ntn workers deploy/list/exec`, `ntn workers sync trigger/pause`, `ntn workers env set`, `ntn workers runs list/logs`, `ntn workers webhooks list`.

### Notion-Flavored Markdown

Standard CommonMark plus XML-like tags for Notion-specific blocks. See `references/block-types.md` for the full block catalog.

Key additions:
- `<callout icon="🎯" color="blue_bg">...</callout>`
- `<details><summary>Toggle</summary>...</details>`
- `<columns><column>Left</column><column>Right</column></columns>`
- Mentions: `<mention-page url="...">Title</mention-page>`
- Colors: `gray brown orange yellow green blue purple pink red` + `*_bg` variants

### Notes

- Rate limit: ~3 requests/second average
- The API cannot set database **view** filters — that's UI-only
- Use `"is_inline": true` when creating data sources to embed in a page
- Always pass `-s` to curl to suppress progress bars
