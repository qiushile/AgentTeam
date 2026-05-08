---
name: markdown-to-docx
description: "Convert markdown files to professionally formatted .docx documents using pandoc with a reference template — supports Chinese fonts (宋体/微软雅黑), headers/footers, styled headings, and consistent formatting for client deliverables."
---

# Markdown to DOCX Conversion

Convert one or more markdown files to individual, professionally formatted `.docx` documents using **pandoc** + a **reference.docx** template.

## Prerequisites

- `pandoc` installed (`pandoc --version`)
- `python-docx` installed (`pip3 install python-docx`)

## Workflow

### Step 0: Pre-process Markdown

Before conversion, clean the markdown files:

1. **Remove horizontal rules**: Delete all `---` lines (they render as visible separator lines in DOCX).
2. **Remove emoji characters**: Strip any emoji (✅, ❌, ⚠️, etc.) — they look unprofessional in Chinese business documents.
3. **Remove code-block references to alternative tech stacks**: If the team uses a specific stack (e.g., Java SpringBoot), remove mentions of alternatives (Python FastAPI, Node.js Express, etc.).

### Step 1: Create a Reference Template

Use `python-docx` to create a `reference.docx` that defines all styles. Pandoc maps markdown elements to these styles during conversion.

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

# Header (right-aligned)
header = doc.sections[0].header
header_para = header.paragraphs[0]
header_para.alignment = WD_ALIGN_PARAGRAPH.RIGHT
run = header_para.add_run('Your Header Text')
run.font.size = Pt(9)
run.font.color.rgb = RGBColor(0x66, 0x66, 0x66)
run.font.name = 'Microsoft YaHei'
run._element.rPr.rFonts.set(qn('w:eastAsia'), '微软雅黑')

# Footer (centered page number)
footer = doc.sections[0].footer
footer_para = footer.paragraphs[0]
footer_para.alignment = WD_ALIGN_PARAGRAPH.CENTER

def add_page_number_field(paragraph):
    fldChar1 = OxmlElement('w:fldChar')
    fldChar1.set(qn('w:fldCharType'), 'begin')
    instrText = OxmlElement('w:instrText')
    instrText.text = 'PAGE'
    fldChar2 = OxmlElement('w:fldChar')
    fldChar2.set(qn('w:fldCharType'), 'end')
    run = paragraph.add_run()
    run._r.append(fldChar1)
    run._r.append(instrText)
    run._r.append(fldChar2)
    run.font.size = Pt(9)
    run.font.color.rgb = RGBColor(0x66, 0x66, 0x66)
    run.font.name = 'Microsoft YaHei'
    run._element.rPr.rFonts.set(qn('w:eastAsia'), '微软雅黑')

add_page_number_field(footer_para)

# Styles — the key mapping for pandoc
style = doc.styles

# Normal (body text)
normal = style['Normal']
normal.font.size = Pt(11)
normal.font.name = '宋体'
normal._element.rPr.rFonts.set(qn('w:eastAsia'), '宋体')
normal.paragraph_format.space_before = Pt(0)
normal.paragraph_format.space_after = Pt(6)
normal.paragraph_format.line_spacing = 1.5

# Heading styles — all BLACK for Chinese business docs
title = style['Title']
title.font.size = Pt(26)
title.font.name = '微软雅黑'
title._element.rPr.rFonts.set(qn('w:eastAsia'), '微软雅黑')
title.font.bold = True
title.font.italic = False
title.font.color.rgb = RGBColor(0x00, 0x00, 0x00)  # BLACK, not blue
title.paragraph_format.space_after = Pt(12)
title.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER

# Heading 1-3 — BLACK, NOT italic
for h_name, h_size in [('Heading 1', 18), ('Heading 2', 14), ('Heading 3', 12)]:
    h = style[h_name]
    h.font.size = Pt(h_size)
    h.font.name = '微软雅黑'
    h._element.rPr.rFonts.set(qn('w:eastAsia'), '微软雅黑')
    h.font.bold = True
    h.font.italic = False
    h.font.color.rgb = RGBColor(0x00, 0x00, 0x00)  # BLACK

# Also clean Heading 4-8 (pandoc may use these for deeper nesting)
for i in range(4, 9):
    try:
        h = style[f'Heading {i}']
        h.font.bold = True
        h.font.italic = False
        h.font.color.rgb = RGBColor(0x00, 0x00, 0x00)
    except:
        pass

# List Paragraph — remove bullets
lp = style['List Paragraph']
lp.font.size = Pt(11)
lp.font.name = '宋体'
lp._element.rPr.rFonts.set(qn('w:eastAsia'), '宋体')
lp.paragraph_format.left_indent = Cm(0)

# Remove numbering/bullets from latent list styles
nsmap = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
for list_style_name in ['List Bullet', 'List Bullet 2', 'List Bullet 3',
                         'List Number', 'List Number 2', 'List Number 3']:
    try:
        s = style[list_style_name]
        pPr = s.element.find('.//w:pPr', nsmap)
        if pPr is not None:
            numPr = pPr.find('w:numPr', nsmap)
            if numPr is not None:
                pPr.remove(numPr)
        s.font.name = '宋体'
        s._element.rPr.rFonts.set(qn('w:eastAsia'), '宋体')
        s.font.size = Pt(11)
    except:
        pass

# Save template
doc.save('reference.docx')

# IMPORTANT: Clean up the XML directly to remove ALL italic and color
# from latent styles that python-docx doesn't expose (Heading 4+, code
# highlighting, table accent styles, etc.)
import re, zipfile, tempfile, shutil

tmpdir = tempfile.mkdtemp()
with zipfile.ZipFile('reference.docx') as z:
    z.extractall(tmpdir)

styles_path = os.path.join(tmpdir, 'word', 'styles.xml')
with open(styles_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove ALL italic elements
content = re.sub(r'<w:i(?:Cs)?\s[^>]*/>|<w:i(?:Cs)?/>', '', content)

# Force ALL colors to black
content = re.sub(r'(<w:color[^>]*w:val=")[^"]+(")', r'\g<1>000000\g<2>', content)

# CRITICAL: Strip ALL theme-related attributes. Word's themeColor="accent1"
# renders as blue even when w:color is set to black.
content = re.sub(r'\s*w:themeColor="[^"]*"', '', content)
content = re.sub(r'\s*w:themeTint="[^"]*"', '', content)
content = re.sub(r'\s*w:themeShade="[^"]*"', '', content)
content = re.sub(r'\s*w:themeFill="[^"]*"', '', content)
content = re.sub(r'\s*w:themeFillTint="[^"]*"', '', content)
content = re.sub(r'\s*w:themeFillShade="[^"]*"', '', content)

with open(styles_path, 'w', encoding='utf-8') as f:
    f.write(content)

with zipfile.ZipFile('reference.docx', 'w') as z:
    for root, dirs, files in os.walk(tmpdir):
        for file in files:
            fpath = os.path.join(root, file)
            arcname = os.path.relpath(fpath, tmpdir)
            z.write(fpath, arcname)
shutil.rmtree(tmpdir)
```

**Critical detail:** Chinese fonts require **both** `font.name` AND `run._element.rPr.rFonts.set(qn('w:eastAsia'), '中文字体名')`. Without the `w:eastAsia` setting, Word falls back to default Latin font and Chinese characters render in the wrong typeface.

### Step 2: Convert Each File

Convert markdown files one at a time using pandoc:

```bash
cd /path/to/markdir
pandoc -s "01-文档.md" -o "output/01-文档.docx" \
  --reference-doc="output/reference.docx" \
  --from markdown+pipe_tables+task_lists+footnotes+backtick_code_blocks \
  --to docx
```

**Pandoc flags explained:**
- `-s` / `--standalone`: Include full document structure (header, styles)
- `--reference-doc`: Applies the template's styles to the output
- `--from markdown+pipe_tables+task_lists+footnotes+backtick_code_blocks`: Enable all common markdown extensions

### Step 3: Post-process Output DOCX

Pandoc's reference.docx contains many **latent styles** (Heading 4-8, code syntax highlighting, table accent styles) with built-in colors and italics that survive even if you explicitly set Heading 1-3. **Always post-process each output DOCX at the XML level:**

```python
import os, re, zipfile, tempfile, shutil

def fix_docx(fpath):
    """Remove italic, force black colors, remove list numbering, add table borders."""
    tmpdir = tempfile.mkdtemp()
    with zipfile.ZipFile(fpath) as z:
        z.extractall(tmpdir)
    
    # Clean document.xml
    doc_path = os.path.join(tmpdir, 'word', 'document.xml')
    with open(doc_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove horizontal rules (pandoc renders --- as paragraph bottom border)
    content = re.sub(
        r'<w:p>\s*<w:pPr>\s*<w:pBdr>\s*<w:bottom[^>]*?/>\s*</w:pBdr>.*?</w:pPr>\s*</w:p>',
        '', content, flags=re.DOTALL
    )
    
    # Remove italic (exact match, not insideH/insideV)
    content = re.sub(r'<w:i(?:Cs)?\s[^>]*/>|<w:i(?:Cs)?/>', '', content)
    
    # Replace ALL colors to black
    content = re.sub(r'(<w:color[^>]*w:val=")[^"]+(")', r'\g<1>000000\g<2>', content)
    
    # Remove list numbering
    content = re.sub(r'<w:numPr>.*?</w:numPr>', '', content, flags=re.DOTALL)
    content = re.sub(r'<w:numPr[^>]*/>', '', content)
    
    # Add table borders (black, single, 0.5pt)
    border_xml = ('<w:tblBorders>'
        '<w:top w:val="single" w:sz="4" w:space="0" w:color="000000"/>'
        '<w:left w:val="single" w:sz="4" w:space="0" w:color="000000"/>'
        '<w:bottom w:val="single" w:sz="4" w:space="0" w:color="000000"/>'
        '<w:right w:val="single" w:sz="4" w:space="0" w:color="000000"/>'
        '<w:insideH w:val="single" w:sz="4" w:space="0" w:color="000000"/>'
        '<w:insideV w:val="single" w:sz="4" w:space="0" w:color="000000"/>'
        '</w:tblBorders>')
    
    # Add borders after tblStyle
    content = re.sub(r'(<w:tblStyle[^>]*/>)', r'\1' + border_xml, content)
    # Remove duplicate consecutive borders
    content = re.sub(r'(<w:tblBorders>.*?</w:tblBorders>)\s*<w:tblBorders>.*?</w:tblBorders>',
                     r'\1', content, flags=re.DOTALL)
    
    with open(doc_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    # Clean styles.xml too
    styles_path = os.path.join(tmpdir, 'word', 'styles.xml')
    if os.path.exists(styles_path):
        with open(styles_path, 'r', encoding='utf-8') as f:
            sc = f.read()
        sc = re.sub(r'<w:i(?:Cs)?\s[^>]*/>|<w:i(?:Cs)?/>', '', sc)
        sc = re.sub(r'(<w:color[^>]*w:val=")[^"]+(")', r'\g<1>000000\g<2>', sc)
        # Strip theme colors (same reason as document.xml)
        sc = re.sub(r'\s*w:themeColor="[^"]*"', '', sc)
        sc = re.sub(r'\s*w:themeTint="[^"]*"', '', sc)
        sc = re.sub(r'\s*w:themeShade="[^"]*"', '', sc)
        sc = re.sub(r'\s*w:themeFill="[^"]*"', '', sc)
        sc = re.sub(r'\s*w:themeFillTint="[^"]*"', '', sc)
        sc = re.sub(r'\s*w:themeFillShade="[^"]*"', '', sc)
        with open(styles_path, 'w', encoding='utf-8') as f:
            f.write(sc)
    
    # Repack
    with zipfile.ZipFile(fpath, 'w') as z:
        for root, dirs, files in os.walk(tmpdir):
            for file in files:
                fp = os.path.join(root, file)
                z.write(fp, os.path.relpath(fp, tmpdir))
    
    shutil.rmtree(tmpdir)
```

### Step 4: Verify

Check each DOCX at the XML level to confirm clean output:

```python
import re, zipfile

with zipfile.ZipFile(fpath) as z:
    with z.open('word/document.xml') as xf:
        dc = xf.read().decode('utf-8')
    with z.open('word/styles.xml') as xf:
        sc = xf.read().decode('utf-8')

# Real italic (not insideH/insideV border tags)
it = len(re.findall(r'<w:i(?:Cs)?\s[^>]*/>|<w:i(?:Cs)?/>', dc)) + \
     len(re.findall(r'<w:i(?:Cs)?\s[^>]*/>|<w:i(?:Cs)?/>', sc))
# Non-black colors
cols = set(re.findall(r'w:color[^>]*?w:val="([0-9a-fA-F]{6})"', dc)) | \
       set(re.findall(r'w:color[^>]*?w:val="([0-9a-fA-F]{6})"', sc))
# List numbering
npr = dc.count('<w:numPr>')

print(f"italic={it} colors={cols if cols else 'none'} numPr={npr}")
# Expected: italic=0, colors={'000000'}, numPr=0
```

### Step 5: Final Verification

Open each file in Word to verify:
- Headers/footers render correctly
- Heading hierarchy is preserved (H1 → H2 → H3), all in black
- Tables have black borders on all cells
- No list bullets or numbering
- No italic or colored text anywhere
- Chinese text uses the correct fonts

## Pitfalls

| Issue | Solution |
|---|---|
| `---` in MD creates visible horizontal lines in DOCX | Remove all `---` lines from MD before conversion |
| Chinese fonts not rendering in Word | Must set `w:eastAsia` on every style's `_element.rPr.rFonts` |
| Pandoc ignores template styles | Use `--standalone` flag; ensure reference.docx path is correct |
| Page numbers not showing | Use `fldChar` XML element (not literal text) — see `add_page_number_field()` above |
| Special characters in filenames | Always quote paths: `"02-需求规格说明书(SRS).md"` |
| Heading 4+ or code blocks render blue/italic | Pandoc's reference.docx has latent styles (Heading 4-8, syntax highlighting) with baked-in colors. Must post-process output DOCX XML to strip italic and force black |
| List bullets appear despite no styling in template | Pandoc adds `<w:numPr>` to list paragraphs. Remove at both style level AND document.xml post-processing |
| Tables have no visible borders | Add `<w:tblBorders>` XML elements with `w:val="single" w:color="000000"` to each table's `w:tblPr` |
| `<w:i>` regex accidentally matches `<w:insideH>`/`<w:insideV>` | Use exact regex: `<w:i(?:Cs)?\s[^>]*/>|<w:i(?:Cs)?/>` — NOT `<w:i` alone |

## When to Use

- Converting project documentation, reports, proposals from markdown to client-ready Word documents
- Batch conversion of multiple markdown files with consistent styling
- Documents requiring Chinese font support (宋体/微软雅黑/楷体 etc.)

## When NOT to Use

- Need tracked changes, comments, or form controls → use `officecli-docx` skill
- Need complex tables with merged cells, floating images → use `officecli-docx` skill
- Single simple file with no formatting needs → `pandoc input.md -o output.docx` without reference-doc is sufficient
