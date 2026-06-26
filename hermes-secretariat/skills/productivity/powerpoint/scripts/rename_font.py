#!/usr/bin/env python3
"""
Rename font internal names using fontTools.
Usage: python3 rename_font.py <input_font> <output_font> <family_name> [full_name] [postscript_name]

Example:
  python3 rename_font.py NotoSansCJKsc-Regular.otf 思源黑体CN-Regular.otf "Source Han Sans CN" "Source Han Sans CN Regular" "SourceHanSansCN-Regular"
"""

import sys
from fontTools.ttLib import TTFont


def rename_font(input_path: str, output_path: str, family: str, full_name: str = None, ps_name: str = None):
    """Rename font internal names and save to new file."""
    if full_name is None:
        full_name = f"{family} Regular"
    if ps_name is None:
        ps_name = family.replace(" ", "") + "-Regular"

    font = TTFont(input_path)
    name_table = font['name']

    # Define new names
    new_names = {
        1: family,       # Font Family
        2: 'Regular',    # Subfamily
        4: full_name,    # Full Name
        6: ps_name       # PostScript Name
    }

    # Update existing name records
    for record in name_table.names:
        if record.nameID in new_names:
            try:
                if record.platformID == 3:  # Windows
                    record.string = new_names[record.nameID].encode('utf-16-be')
                else:  # Mac
                    record.string = new_names[record.nameID].encode('utf-8')
            except Exception:
                record.string = new_names[record.nameID]

    # Add Chinese name if family contains CJK characters
    if any('\u4e00' <= c <= '\u9fff' for c in family) or 'CJK' in family or 'Han' in family:
        # Extract Chinese name from family if present
        chinese_family = family
        name_table.setName(chinese_family, 1, 3, 1, 0x0804)  # Chinese Simplified
        name_table.setName(f"{chinese_family} Regular", 4, 3, 1, 0x0804)

    font.save(output_path)
    print(f"Saved renamed font to: {output_path}")

    # Verify
    font2 = TTFont(output_path)
    print("\nNew font names:")
    for record in font2['name'].names:
        if record.nameID in [1, 4, 6]:
            try:
                lang = "中文" if record.langID == 0x0804 else "English"
                print(f"  nameID={record.nameID} ({lang}): {record.toUnicode()}")
            except Exception:
                pass


if __name__ == '__main__':
    if len(sys.argv) < 4:
        print(__doc__)
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2]
    family = sys.argv[3]
    full_name = sys.argv[4] if len(sys.argv) > 4 else None
    ps_name = sys.argv[5] if len(sys.argv) > 5 else None

    rename_font(input_path, output_path, family, full_name, ps_name)
