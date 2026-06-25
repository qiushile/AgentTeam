---
name: macos-office-font-management
description: Diagnose and fix PowerPoint/Office font embedding warnings on macOS. Rename font internal names with fontTools when PPT shows "不可用的字体" or "不支持的字体文件格式".
trigger: PowerPoint font embedding warnings, "连同字体保存" dialog, font not available errors, AAT format issues, font name conflicts
---

# macOS Office Font Management

## When to Use
- PowerPoint shows "连同字体保存" (Save with fonts) warning dialog
- Font list shows "不可用的字体" (Font unavailable) or "不支持的字体文件格式 (AAT)"
- Font installed but PowerPoint/Office can't recognize it
- Duplicate font conflicts (e.g., Noto Sans CJK vs Source Han Sans)

## Diagnosis Workflow

1. **Identify problematic fonts** from PPT warning dialog
2. **Check font installation**:
   ```bash
   fc-list | grep -i "font-name"
   ```
3. **Check font file format**:
   ```bash
   file ~/Library/Fonts/font-file.otf
   ```
   - `.ttf`/`.otf` = OK for embedding
   - `.ttc` = TrueType Collection (may have issues)
   - AAT format = not supported by Office (system fonts like Heiti SC)

## Common Issues & Solutions

### Issue 1: Font Name Mismatch
PPT references "思源黑体 CN" but only "Noto Sans CJK SC" is installed (same font, different brand names).

**Solution**: Use fontTools to rename font internal names:

```python
from fontTools.ttLib import TTFont

font = TTFont('original-font.otf')
name_table = font['name']

# Set new names (nameID 1=Family, 4=Full, 6=PostScript)
new_names = {
    1: 'Source Han Sans CN',
    4: 'Source Han Sans CN Regular',
    6: 'SourceHanSansCN-Regular'
}

for record in name_table.names:
    if record.nameID in new_names:
        record.string = new_names[record.nameID].encode('utf-16-be') if record.platformID == 3 else new_names[record.nameID].encode('utf-8')

font.save('renamed-font.otf')
```

Add Chinese names:
```python
name_table.setName('思源黑体 CN', 1, 3, 1, 0x0804)  # Chinese Simplified
name_table.setName('思源黑体 CN Regular', 4, 3, 1, 0x0804)
```

### Issue 2: Duplicate Font Conflicts
Noto Sans CJK SC and Source Han Sans SC are the same font (Adobe+Google collab) with different brand names. Having both causes conflicts.

**Solution**: Delete one version:
```bash
rm ~/Library/Fonts/思源黑体CN-Regular.otf  # Keep Google version
# OR
rm ~/Library/Fonts/NotoSansCJKsc-*.otf     # Keep Adobe version
```

### Issue 3: AAT Format (System Fonts)
macOS system fonts like Heiti SC use Apple's AAT format, which Office cannot embed.

**Solution**: No fix possible. Replace with OTF/TTF alternatives in PPT:
- Use 苹方 (PingFang SC) instead of Heiti SC
- Use Noto Sans CJK SC instead of system fonts

### Issue 4: Font Cache Issues
Font installed but not recognized by Office.

**Solution**: Clear font cache:
```bash
sudo atsutil databases -remove
sudo atsutil server -shutdown
sudo atsutil server -ping
```
Then restart computer.

## Scripts

- `scripts/rename_font.py` — Reusable script to rename font internal names. Usage:
  ```bash
  python3 scripts/rename_font.py input.otf output.otf "New Family Name" "Full Name" "PostScriptName"
  ```

## Pitfalls

- **fontTools required**: Install with `pip3 install fonttools` if not present
- **nameID meanings**: 1=Family, 2=Subfamily, 4=Full Name, 6=PostScript Name
- **Platform encoding**: platformID=3 (Windows) uses UTF-16-BE, platformID=1 (Mac) uses UTF-8
- **TTC files**: TrueType Collections contain multiple fonts; renaming is more complex
- **AAT is unfixable**: System fonts with AAT format cannot be embedded; must use alternatives

## Verification

After renaming/copying fonts:
1. Quit PowerPoint completely (Cmd+Q)
2. Clear font cache (or restart computer)
3. Reopen PPT and try saving again
4. Check if warning dialog still appears
