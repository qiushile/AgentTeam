---
name: md-to-docx-chinese
description: "Convert Chinese markdown files to professionally formatted .docx documents — removing horizontal rules, bullets, converting blue to black, adding black table borders."
---

# Markdown to Chinese DOCX Converter

Convert markdown files to client-ready .docx with consistent Chinese typography.

## Dependencies

- `pandoc` (installed at `/usr/local/bin/pandoc`)
- `python-docx` (`pip3 install python-docx`)

## Step 1: Create Reference Template

Create a reference.docx with Chinese fonts and professional styling:

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

# Header
header = doc.sections[0].header
header_para = header.paragraphs[0]
header_para.alignment = WD_ALIGN_PARAGRAPH.RIGHT
run = header_para.add_run('项目文档')
run.font.size = Pt(9)
run.font.color.rgb = RGBColor(0x66, 0x66, 0x66)
run.font.name = 'Microsoft YaHei'
run._element.rPr.rFonts.set(qn('w:eastAsia'), '微软雅黑')

# Footer with page number
footer = doc.sections[0].footer
footer_para = footer.paragraphs[0]
footer_para.alignment = WD_ALIGN_PARAGRAPH.CENTER
fldChar1 = OxmlElement('w:fldChar')
fldChar1.set(qn('w:fldCharType'), 'begin')
instrText = OxmlElement('w:instrText')
instrText.text = 'PAGE'
fldChar2 = OxmlElement('w:fldChar')
fldChar2.set(qn('w:fldCharType'), 'end')
run = footer_para.add_run()
run._r.append(fldChar1)
run._r.append(instrText)
run._r.append(fldChar2)
run.font.size = Pt(9)
run.font.color.rgb = RGBColor(0x66, 0x66, 0x66)

# Styles - all black text, Chinese fonts
style = doc.styles

# Normal
normal = style['Normal']
normal.font.size = Pt(11)
normal.font.name = '宋体'
normal._element.rPr.rFonts.set(qn('w:eastAsia'), '宋体')
normal.paragraph_format.space_before = Pt(0)
normal.paragraph_format.space_after = Pt(6)
normal.paragraph_format.line_spacing = 1.5

# Title
title = style['Title']
title.font.size = Pt(26)
title.font.name = '微软雅黑'
title._element.rPr.rFonts.set(qn('w:eastAsia'), '微软雅黑')
title.font.bold = True
title.font.color.rgb = RGBColor(0, 0, 0)
title.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER

# Headings - ALL BLACK
for name, size in [('Heading 1', 18), ('Heading 2', 14), ('Heading 3', 12), ('Heading 4', 11)]:
    s = style[name]
    s.font.size = Pt(size)
    s.font.name = '微软雅黑'
    s._element.rPr.rFonts.set(qn('w:eastAsia'), '微软雅黑')
    s.font.bold = True
    s.font.color.rgb = RGBColor(0, 0, 0)
    s.paragraph_format.space_before = Pt(12)
    s.paragraph_format.space_after = Pt(6)
    s.paragraph_format.keep_with_next = True

doc.save('reference.docx')
```

## Step 2: Pre-process Markdown

Remove `---`/`***`/`___` horizontal rule lines from the markdown source. Pandoc converts these to paragraph bottom borders (`w:pBdr`), which are difficult to remove cleanly from the output DOCX.

```python
import re
with open(path, 'r') as f:
    content = f.read()
content = re.sub(r'^-{3,}$', '', content, flags=re.MULTILINE)
content = re.sub(r'^\*{3,}$', '', content, flags=re.MULTILINE)
content = re.sub(r'^_{3,}$', '', content, flags=re.MULTILINE)
with open(path, 'w') as f:
    f.write(content)
```

## Step 3: Pandoc Convert

```bash
pandoc -s input.md -o output.docx \
  --reference-doc=reference.docx \
  --from markdown+pipe_tables+task_lists+footnotes+backtick_code_blocks \
  --to docx
```

## Step 4: XML-Level Post-Process (Essential)

python-docx's high-level API is NOT sufficient. Pandoc injects inline formatting (italic, colors, list numbering) that bypasses style definitions. You MUST work directly with the DOCX XML:

```python
import os, re, zipfile, tempfile, shutil

def clean_docx(fpath):
    # Extract
    tmpdir = tempfile.mkdtemp()
    with zipfile.ZipFile(fpath) as z:
        z.extractall(tmpdir)
    
    # Clean document.xml
    doc_path = os.path.join(tmpdir, 'word', 'document.xml')
    with open(doc_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Remove horizontal rules (paragraph with bottom border)
    content = re.sub(
        r'<w:p>\s*<w:pPr>\s*<w:pBdr>\s*<w:bottom[^>]*?/>\s*</w:pBdr>.*?</w:pPr>\s*</w:p>',
        '', content, flags=re.DOTALL)
    
    # 2. Remove ALL italic (including <w:iCs/>)
    content = re.sub(r'<w:i[^>]*?/>', '', content)
    content = re.sub(r'<w:iCs[^>]*?/>', '', content)
    
    # 3. Replace ALL colors to black
    content = re.sub(r'(<w:color[^>]*w:val=")[^"]+(")', r'\g<1>000000\g<2>', content)
    
    # 4. Remove list numbering (numPr at paragraph level)
    content = re.sub(r'<w:numPr>.*?</w:numPr>', '', content, flags=re.DOTALL)
    content = re.sub(r'<w:numPr[^>]*/>', '', content)
    
    # 5. Add black borders to ALL tables (6 sides)
    borders = '<w:tblBorders>' \
        '<w:top w:val="single" w:sz="4" w:space="0" w:color="000000"/>' \
        '<w:left w:val="single" w:sz="4" w:space="0" w:color="000000"/>' \
        '<w:bottom w:val="single" w:sz="4" w:space="0" w:color="000000"/>' \
        '<w:right w:val="single" w:sz="4" w:space="0" w:color="000000"/>' \
        '<w:insideH w:val="single" w:sz="4" w:space="0" w:color="000000"/>' \
        '<w:insideV w:val="single" w:sz="4" w:space="0" w:color="000000"/>' \
        '</w:tblBorders>'
    content = re.sub(r'<w:tblBorders>.*?</w:tblBorders>', '', content, flags=re.DOTALL)
    content = re.sub(r'(<w:tblStyle[^>]*/>)', rf'\1{borders}', content)
    
    with open(doc_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    # Clean styles.xml (pandoc defaults inject italic/color into Heading 4-8 and code styles)
    styles_path = os.path.join(tmpdir, 'word', 'styles.xml')
    with open(styles_path, 'r', encoding='utf-8') as f:
        sc = f.read()
    sc = re.sub(r'<w:i[^>]*?/>', '', sc)
    sc = re.sub(r'<w:iCs[^>]*?/>', '', sc)
    sc = re.sub(r'(<w:color[^>]*w:val=")[^"]+(")', r'\g<1>000000\g<2>', sc)
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

## Step 5: Verify

```python
with zipfile.ZipFile(fpath) as z:
    with z.open('word/document.xml') as xf:
        dc = xf.read().decode('utf-8')
    with z.open('word/styles.xml') as xf:
        sc = xf.read().decode('utf-8')

# Count real italic tags (NOT <w:insideH>/<w:insideV> which contain 'w:i' substring)
it = len(re.findall(r'<w:i(?:Cs)?\s[^>]*/>|<w:i(?:Cs)?/>', dc)) + \
     len(re.findall(r'<w:i(?:Cs)?\s[^>]*/>|<w:i(?:Cs)?/>', sc))
cols = set(re.findall(r'w:color[^>]*?w:val="([0-9a-fA-F]{6})"', dc + sc))
npr = dc.count('<w:numPr>')
hr = dc.count('w:pBdr')

assert it == 0, f"Still {it} italic tags"
assert cols <= {'000000'}, f"Non-black colors: {cols}"
assert npr == 0, f"Still {npr} list numbering elements"
assert hr == 0, f"Still {hr} horizontal rules"
```

## Merging Multiple Markdown Files

When combining multiple docs (e.g., feasibility report + SRS) into one client deliverable:

1. **Read all files**, remove individual titles and revision records
2. **Deduplicate overlapping sections** (project background appears in both files — keep one)
3. **Reorganize into a single logical flow**: project overview → feasibility → functional requirements → non-functional → constraints → acceptance criteria → conclusion
4. **Create a unified cover page** with document version, date, and purpose
5. **Build a single table of contents** and a single revision record at the end
6. Convert the merged file through Steps 2-5 above

## Key Pitfalls

- **`---` in markdown**: pandoc converts these to paragraph bottom borders (`w:pBdr`). Must remove from source markdown BEFORE conversion AND clean any remaining `w:pBdr` from document.xml.
- **python-docx high-level API is insufficient**: Pandoc injects inline `<w:i/>`, `<w:color>`, and `<w:numPr>` directly into runs and paragraphs, bypassing style definitions. Must extract the DOCX as a ZIP and clean document.xml/styles.xml with regex.
- **styles.xml inherits pandoc defaults**: Heading 4-8 come with italic + blue (`#4F81BD`), and pandoc adds syntax highlighting character styles with colors. These survive python-docx style modifications. Clean styles.xml at XML level.
- **`<w:insideH>` and `<w:insideV>` are NOT italic**: They contain `w:i` as a substring but are table border elements. Use precise regex: `<w:i(?:Cs)?\s[^>]*/>|<w:i(?:Cs)?/>`.
- **Blue heading styles**: The reference template defaults to blue headings. Must set `RGBColor(0, 0, 0)` on all heading styles AND force all `w:color` values to `000000` in both document.xml and styles.xml.
- **Table borders must include all 6 sides**: `top`, `left`, `bottom`, `right`, `insideH`, `insideV` — missing `insideH` or `insideV` leaves internal grid lines invisible.
- **List numbering requires two-level removal**: Remove `<w:numPr>` from paragraphs in document.xml AND remove `numPr` from list style definitions in styles.xml.
- **Verify at XML level**: Open the DOCX as a ZIP, check document.xml and styles.xml. `grep` or regex counts are more reliable than python-docx properties.
- **Run python3 from the system environment**, not a sandboxed venv where python-docx isn't installed.
