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

## Step 2: Convert

For each markdown file:

1. **Pre-process**: Remove `---`/`***`/`___` horizontal rule lines from the markdown
2. **Pandoc convert**: `pandoc -s input.md -o output.docx --reference-doc=reference.docx`
3. **Post-process** with python-docx:
   - Remove any remaining paragraph borders (pBdr)
   - Remove bullet symbols from numbering.xml (`\uf0b7`, `\uf0a7`, `•`, `o`, etc.)
   - Convert any remaining blue text to black (`b > r + 30 and b > g + 30`)
   - Add black borders to all tables (`tblBorders` with `single` style, `sz=4`, `color=000000`)

## Key Pitfalls

- **`---` in markdown**: pandoc converts these to paragraph bottom borders. Must remove from source markdown BEFORE conversion.
- **Bullet symbols persist in numbering.xml**: The `\uf0b7` (Wingdings bullet) character lives in numbering.xml, not in paragraph text. Must modify numbering definitions directly.
- **Blue heading styles**: The reference template defaults to blue headings. Must set `RGBColor(0, 0, 0)` on all heading styles AND check individual runs.
- **Table borders must include all 6 sides**: `top`, `left`, `bottom`, `right`, `insideH`, `insideV` — missing `insideH` or `insideV` leaves internal grid lines invisible.
- **Run `python-docx` from system python**, not a sandboxed environment where the package isn't installed.
