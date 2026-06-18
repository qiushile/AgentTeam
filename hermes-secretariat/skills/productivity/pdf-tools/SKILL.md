---
name: pdf-tools
description: "PDF workflows: extract text from PDFs/scans (pymupdf, marker-pdf, OCR), edit PDF text/typos/titles via NL prompts (nano-pdf), split/merge/search PDFs."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [PDF, Documents, OCR, Text-Extraction, Editing, Research, Arxiv, Productivity]
    related_skills: [powerpoint]
---

# PDF Tools — Extract, Edit, Split, Merge

Two workflows for working with PDFs:

1. **Extract text** — from text-based or scanned PDFs (pymupdf, marker-pdf)
2. **Edit text** — fix typos, change titles, update content (nano-pdf)

Plus: split, merge, search PDFs with pymupdf.

---

## Part 1: Extract Text from PDFs

### Step 1: Remote URL Available?

If the document has a URL, **always try `web_extract` first**:
```
web_extract(urls=["https://arxiv.org/pdf/2402.03300"])
```
This handles PDF-to-markdown via Firecrawl with no local dependencies.

Only use local extraction when: the file is local, web_extract fails, or you need batch processing.

### Step 2: Choose Local Extractor

| Feature | pymupdf (~25MB) | marker-pdf (~3-5GB) |
|---------|-----------------|---------------------|
| **Text-based PDF** | ✅ | ✅ |
| **Scanned PDF (OCR)** | ❌ | ✅ (90+ languages) |
| **Tables** | ✅ (basic) | ✅ (high accuracy) |
| **Equations / LaTeX** | ❌ | ✅ |
| **Code blocks** | ❌ | ✅ |
| **Forms** | ❌ | ✅ |
| **Install size** | ~25MB | ~3-5GB (PyTorch + models) |
| **Speed** | Instant | ~1-14s/page (CPU) |

**Decision**: Use pymupdf unless you need OCR, equations, forms, or complex layout analysis.

### pymupdf (lightweight)

```bash
pip install pymupdf pymupdf4llm
```

**Via helper script** (`scripts/extract_pymdf.py`):
```bash
python scripts/extract_pymupdf.py document.pdf              # Plain text
python scripts/extract_pymupdf.py document.pdf --markdown    # Markdown
python scripts/extract_pymupdf.py document.pdf --tables      # Tables
python scripts/extract_pymupdf.py document.pdf --images out/ # Extract images
python scripts/extract_pymupdf.py document.pdf --metadata    # Title, author, pages
python scripts/extract_pymupdf.py document.pdf --pages 0-4   # Specific pages
```

**Inline**:
```bash
python3 -c "
import pymupdf
doc = pymupdf.open('document.pdf')
for page in doc:
    print(page.get_text())
"
```

### marker-pdf (high-quality OCR)

```bash
pip install marker-pdf
```

**Via helper script** (`scripts/extract_marker.py`):
```bash
python scripts/extract_marker.py document.pdf                # Markdown
python scripts/extract_marker.py document.pdf --json         # JSON with metadata
python scripts/extract_marker.py document.pdf --output_dir out/  # Save images
python scripts/extract_marker.py scanned.pdf                 # Scanned PDF (OCR)
python scripts/extract_marker.py document.pdf --use_llm      # LLM-boosted accuracy
```

**CLI**:
```bash
marker_single document.pdf --output_dir ./output
marker /path/to/folder --workers 4    # Batch
```

### Arxiv Papers

```
web_extract(urls=["https://arxiv.org/abs/2402.03300"])   # Abstract
web_extract(urls=["https://arxiv.org/pdf/2402.03300"])   # Full paper
web_search(query="arxiv GRPO reinforcement learning 2026")  # Search
```

---

## Part 2: Edit PDF Text

Edit PDFs using natural-language instructions via nano-pdf.

### Prerequisites

```bash
uv pip install nano-pdf  # or pip install nano-pdf
```

### Usage

```bash
nano-pdf edit <file.pdf> <page_number> "<instruction>"
```

### Examples

```bash
# Change a title on page 1
nano-pdf edit deck.pdf 1 "Change the title to 'Q3 Results' and fix the typo in the subtitle"

# Update a date on a specific page
nano-pdf edit report.pdf 3 "Update the date from January to February 2026"

# Fix content
nano-pdf edit contract.pdf 2 "Change the client name from 'Acme Corp' to 'Acme Industries'"
```

### Notes

- Page numbers may be 0-based or 1-based — if the edit hits the wrong page, retry with ±1
- Always verify the output PDF after editing
- The tool uses an LLM under the hood — requires an API key
- Works well for text changes; complex layout modifications may need a different approach

---

## Part 3: Split, Merge & Search

pymupdf handles these natively:

```python
# Split: extract pages 1-5 to a new PDF
import pymupdf
doc = pymupdf.open("report.pdf")
new = pymupdf.open()
for i in range(5):
    new.insert_pdf(doc, from_page=i, to_page=i)
new.save("pages_1-5.pdf")
```

```python
# Merge multiple PDFs
import pymupdf
result = pymupdf.open()
for path in ["a.pdf", "b.pdf", "c.pdf"]:
    result.insert_pdf(pymupdf.open(path))
result.save("merged.pdf")
```

```python
# Search for text across all pages
import pymupdf
doc = pymupdf.open("report.pdf")
for i, page in enumerate(doc):
    results = page.search_for("revenue")
    if results:
        print(f"Page {i+1}: {len(results)} match(es)")
```

---

## Notes

- `web_extract` is always first choice for URLs
- pymupdf is the safe default — instant, no models, works everywhere
- marker-pdf is for OCR, scanned docs, equations — install only when needed
- marker-pdf downloads ~2.5GB of models to `~/.cache/huggingface/` on first use
- For Word docs: `pip install python-docx` (better than OCR — parses actual structure)
- For PowerPoint: see the `powerpoint` skill (uses python-pptx)
