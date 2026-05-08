---
name: chinese-client-docx
description: "Convert markdown to client-ready Chinese Word documents with strict formatting: black text only, no italic, no horizontal rules, no page constraints, black-bordered tables,宋体+微软雅黑 fonts. Includes XML-level post-processing pipeline."
---

# Chinese Client DOCX Pipeline

Convert markdown to professionally formatted `.docx` for Chinese client delivery, with strict formatting requirements enforced at both the markdown source and XML post-processing levels.

## Workflow

### Step 1: Create clean markdown source

**MUST NOT contain:**
- `---` horizontal rules (pandoc converts these to Word paragraph borders that are hard to remove)
- Emoji characters
- Inline HTML styling

**MUST use:**
- Pipe tables for all tabular data
- `#` / `##` / `###` for heading hierarchy
- Plain text lists (no manual bullets or numbers needed — pandoc handles these, and post-processing removes list formatting)

### Step 2: Convert with pandoc

```bash
pandoc -s "input.md" -o "output.docx" \
  --reference-doc="reference.docx" \
  --from markdown+pipe_tables+task_lists+footnotes+backtick_code_blocks \
  --to docx
```

### Step 3: XML post-processing (MANDATORY)

Pandoc + reference.docx alone cannot achieve the strict formatting. **Every output DOCX must be post-processed at the XML level.**

#### 3.1 Extract DOCX
```python
import zipfile, tempfile, os
tmpdir = tempfile.mkdtemp()
with zipfile.ZipFile('output.docx') as z:
    z.extractall(tmpdir)
```

#### 3.2 Clean `word/document.xml`

Apply these regex replacements in order:

```python
import re

with open(f'{tmpdir}/word/document.xml') as f:
    dc = f.read()

# 1. Remove horizontal rules (paragraph borders)
dc = re.sub(r'<w:pBdr>.*?</w:pBdr>', '', dc, flags=re.DOTALL)

# 2. Remove page flow constraints (with next / keep lines together)
dc = re.sub(r'<w:keepNext/>', '', dc)
dc = re.sub(r'<w:keepLines/>', '', dc)
dc = re.sub(r'<w:keepNext[^>]*/>', '', dc)
dc = re.sub(r'<w:keepLines[^>]*/>', '', dc)

# 3. Remove ALL theme color attributes (critical — these cause blue text even when w:color is black)
for attr in ['themeColor', 'themeTint', 'themeShade', 'themeFill', 'themeFillTint', 'themeFillShade']:
    dc = re.sub(rf'\s*w:{attr}="[^"]*"', '', dc)

# 4. Force ALL explicit colors to black
dc = re.sub(r'(<w:color[^>]*w:val=")[^"]+(")', r'\g<1>000000\g<2>', dc)

# 5. Remove italic
dc = re.sub(r'<w:i[^>]*?/>', '', dc)
dc = re.sub(r'<w:iCs[^>]*?/>', '', dc)

# 6. Remove list numbering
dc = re.sub(r'<w:numPr>.*?</w:numPr>', '', dc, flags=re.DOTALL)
dc = re.sub(r'<w:numPr[^>]*/>', '', dc)

# 7. Remove revision tracking (RSID) — these cause "square dots" in Word
dc = re.sub(r'\s*w:rsid\w*="[^"]+"', '', dc)
dc = re.sub(r'<w:rsid\w*[^>]*/>', '', dc)

# 8. Clean empty paragraph/run property blocks
dc = re.sub(r'<w:pPr>\s*</w:pPr>', '', dc)
dc = re.sub(r'<w:rPr>\s*</w:rPr>', '', dc)

# 9. Table borders: remove existing, add clean black borders
borders = '<w:tblBorders><w:top w:val="single" w:sz="4" w:space="0" w:color="000000"/><w:left w:val="single" w:sz="4" w:space="0" w:color="000000"/><w:bottom w:val="single" w:sz="4" w:space="0" w:color="000000"/><w:right w:val="single" w:sz="4" w:space="0" w:color="000000"/><w:insideH w:val="single" w:sz="4" w:space="0" w:color="000000"/><w:insideV w:val="single" w:sz="4" w:space="0" w:color="000000"/></w:tblBorders>'
dc = re.sub(r'<w:tblBorders>.*?</w:tblBorders>', '', dc, flags=re.DOTALL)
dc = re.sub(r'(<w:tblStyle[^>]*/>)', rf'\1{borders}', dc)

with open(f'{tmpdir}/word/document.xml', 'w') as f:
    f.write(dc)
```

#### 3.3 Clean `word/styles.xml`

```python
with open(f'{tmpdir}/word/styles.xml') as f:
    sc = f.read()

# Apply same cleanup as document.xml
sc = re.sub(r'<w:pBdr>.*?</w:pBdr>', '', sc, flags=re.DOTALL)
sc = re.sub(r'<w:keepNext/>', '', sc)
sc = re.sub(r'<w:keepLines/>', '', sc)
sc = re.sub(r'<w:keepNext[^>]*/>', '', sc)
sc = re.sub(r'<w:keepLines[^>]*/>', '', sc)
sc = re.sub(r'\s*w:rsid\w*="[^"]+"', '', sc)
sc = re.sub(r'<w:rsid\w*[^>]*/>', '', sc)
for attr in ['themeColor', 'themeTint', 'themeShade', 'themeFill', 'themeFillTint', 'themeFillShade']:
    sc = re.sub(rf'\s*w:{attr}="[^"]*"', '', sc)
sc = re.sub(r'(<w:color[^>]*w:val=")[^"]+(")', r'\g<1>000000\g<2>', sc)
sc = re.sub(r'<w:i[^>]*?/>', '', sc)
sc = re.sub(r'<w:iCs[^>]*/>', '', sc)
sc = re.sub(r'<w:pPr>\s*</w:pPr>', '', sc)
sc = re.sub(r'<w:rPr>\s*</w:rPr>', '', sc)

# Set default language to Chinese
sc = sc.replace('w:val="en-US"', 'w:val="zh-CN"')
sc = sc.replace('w:eastAsia="en-US"', 'w:eastAsia="zh-CN"')

with open(f'{tmpdir}/word/styles.xml', 'w') as f:
    f.write(sc)
```

#### 3.4 Repack DOCX

```python
with zipfile.ZipFile('output.docx', 'w') as z:
    for root, dirs, files in os.walk(tmpdir):
        for file in files:
            fp = os.path.join(root, file)
            arc = os.path.relpath(fp, tmpdir)
            z.write(fp, arc)

import shutil
shutil.rmtree(tmpdir)
```

#### 3.5 Verify

```python
with zipfile.ZipFile('output.docx') as z:
    with z.open('word/document.xml') as xf:
        dc = xf.read().decode('utf-8')

assert dc.count('w:pBdr') == 0, "Horizontal rules still present"
assert dc.count('w:keepNext') == 0, "keepNext still present"
assert dc.count('w:keepLines') == 0, "keepLines still present"
assert dc.count('<w:numPr>') == 0, "List numbering still present"
assert dc.count('w:rsid') == 0, "RSID still present"
assert len(re.findall(r'w:themeColor="[^"]*"', dc)) == 0, "Theme colors still present"
```

### Step 4: File organization

- `.md` files go in the project directory (git-tracked)
- `.docx` files go in `docx-output/` subdirectory
- `.gitignore` excludes `docx-output/`

## Reference template (reference.docx)

Create once, then reuse for all documents. Must be pre-cleaned:

```python
from docx import Document
from docx.shared import Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

doc = Document()

# Page margins
for section in doc.sections:
    section.top_margin = Cm(2.54)
    section.bottom_margin = Cm(2.54)
    section.left_margin = Cm(3.17)
    section.right_margin = Cm(3.17)

# Header/footer setup (right-aligned header, centered page number footer)
# ... [see markdown-to-docx skill for header/footer code] ...

style = doc.styles

# Normal — 宋体 11pt, 1.5 line spacing
normal = style['Normal']
normal.font.size = Pt(11)
normal.font.name = '宋体'
normal._element.rPr.rFonts.set(qn('w:eastAsia'), '宋体')
normal.paragraph_format.space_before = Pt(0)
normal.paragraph_format.space_after = Pt(6)
normal.paragraph_format.line_spacing = 1.5

# Title — 微软雅黑 26pt, BLACK, bold, centered
title = style['Title']
title.font.size = Pt(26)
title.font.name = '微软雅黑'
title._element.rPr.rFonts.set(qn('w:eastAsia'), '微软雅黑')
title.font.bold = True
title.font.color.rgb = RGBColor(0x00, 0x00, 0x00)
title.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER

# Heading 1-3 — 微软雅黑, BLACK, bold, NO italic
for h_name, h_size in [('Heading 1', 18), ('Heading 2', 14), ('Heading 3', 12)]:
    h = style[h_name]
    h.font.size = Pt(h_size)
    h.font.name = '微软雅黑'
    h._element.rPr.rFonts.set(qn('w:eastAsia'), '微软雅黑')
    h.font.bold = True
    h.font.color.rgb = RGBColor(0x00, 0x00, 0x00)
    h.font.italic = False

# List Paragraph — no indent
lp = style['List Paragraph']
lp.font.size = Pt(11)
lp.font.name = '宋体'
lp._element.rPr.rFonts.set(qn('w:eastAsia'), '宋体')
lp.paragraph_format.left_indent = Cm(0)

# Remove numbering from list styles
nsmap = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
for ls in ['List Bullet', 'List Bullet 2', 'List Bullet 3',
           'List Number', 'List Number 2', 'List Number 3']:
    try:
        s = style[ls]
        pPr = s.element.find('.//w:pPr', nsmap)
        if pPr is not None:
            numPr = pPr.find('w:numPr', nsmap)
            if numPr is not None:
                pPr.remove(numPr)
        s.font.name = '宋体'
        s._element.rPr.rFonts.set(qn('w:eastAsia'), '宋体')
        s.font.size = Pt(11)
        s.font.italic = False
    except KeyError:
        pass

doc.save('reference.docx')
```

Then clean the XML in the saved reference.docx to remove ALL theme colors:
```python
# Extract, clean styles.xml, repack (same pipeline as Step 3)
```

## Critical pitfalls

| Pitfall | Cause | Fix |
|---------|-------|-----|
| Blue text persists | `w:themeColor="accent1"` — Word's theme default is blue, overrides `w:color` | Remove ALL `w:themeColor`, `w:themeTint`, `w:themeShade` attributes |
| Horizontal rules keep appearing | Markdown source contains `---` which pandoc converts to `w:pBdr` | Remove `---` from markdown AND strip `w:pBdr` in post-processing |
| "Square dots" at line starts | `w:rsid` revision tracking marks in Word XML | Remove all `w:rsid*` attributes |
| Heading 4-8 have italic/blue | Default Word styles include these | Strip from styles.xml post-processing |
| Chinese fonts render wrong | Missing `w:eastAsia` font setting | Always set BOTH `font.name` AND `rFonts.set(qn('w:eastAsia'), ...)` |
| Tables have no borders | Pandoc doesn't add borders by default | Inject `w:tblBorders` after every `w:tblStyle` |

## When to use

- Client-facing Chinese documents requiring strict professional formatting
- Project proposals, requirements specs, meeting minutes for delivery
- Any DOCX that must have: black-only text,宋体 body, 微软雅黑 headings, black table borders, no italics, no revision marks

## When NOT to use

- Need tracked changes or comments → use `officecli-docx`
- Need complex Word features (form fields, macros, floating images) → use `officecli-docx`
- Quick internal drafts → basic `pandoc input.md -o output.docx` is sufficient