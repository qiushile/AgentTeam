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

# Title
title = style['Title']
title.font.size = Pt(26)
title.font.name = '微软雅黑'
title._element.rPr.rFonts.set(qn('w:eastAsia'), '微软雅黑')
title.font.bold = True
title.font.color.rgb = RGBColor(0x1F, 0x4E, 0x79)
title.paragraph_format.space_after = Pt(12)
title.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER

# Heading 1
h1 = style['Heading 1']
h1.font.size = Pt(18)
h1.font.name = '微软雅黑'
h1._element.rPr.rFonts.set(qn('w:eastAsia'), '微软雅黑')
h1.font.bold = True
h1.font.color.rgb = RGBColor(0x1F, 0x4E, 0x79)
h1.paragraph_format.space_before = Pt(24)
h1.paragraph_format.space_after = Pt(12)

# Heading 2
h2 = style['Heading 2']
h2.font.size = Pt(14)
h2.font.name = '微软雅黑'
h2._element.rPr.rFonts.set(qn('w:eastAsia'), '微软雅黑')
h2.font.bold = True
h2.font.color.rgb = RGBColor(0x2E, 0x75, 0xB6)
h2.paragraph_format.space_before = Pt(18)
h2.paragraph_format.space_after = Pt(8)

# Heading 3
h3 = style['Heading 3']
h3.font.size = Pt(12)
h3.font.name = '微软雅黑'
h3._element.rPr.rFonts.set(qn('w:eastAsia'), '微软雅黑')
h3.font.bold = True
h3.font.color.rgb = RGBColor(0x44, 0x72, 0xC4)
h3.paragraph_format.space_before = Pt(12)
h3.paragraph_format.space_after = Pt(6)

# Save template
doc.save('reference.docx')
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

### Step 3: Verify

```bash
ls -lh output/*.docx
```

Open each file in Word to verify:
- Headers/footers render correctly
- Heading hierarchy is preserved (H1 → H2 → H3)
- Tables, lists, code blocks are formatted
- Chinese text uses the correct fonts

## Pitfalls

| Issue | Solution |
|---|---|
| Chinese fonts not rendering in Word | Must set `w:eastAsia` on every style's `_element.rPr.rFonts` |
| Pandoc ignores template styles | Use `--standalone` flag; ensure reference.docx path is correct |
| Page numbers not showing | Use `fldChar` XML element (not literal text) — see `add_page_number_field()` above |
| Special characters in filenames | Always quote paths: `"02-需求规格说明书(SRS).md"` |
| Markdown links/images not converting | Pandoc handles standard markdown links; absolute local image paths may need adjustment |

## When to Use

- Converting project documentation, reports, proposals from markdown to client-ready Word documents
- Batch conversion of multiple markdown files with consistent styling
- Documents requiring Chinese font support (宋体/微软雅黑/楷体 etc.)

## When NOT to Use

- Need tracked changes, comments, or form controls → use `officecli-docx` skill
- Need complex tables with merged cells, floating images → use `officecli-docx` skill
- Single simple file with no formatting needs → `pandoc input.md -o output.docx` without reference-doc is sufficient
