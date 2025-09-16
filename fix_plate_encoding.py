#!/usr/bin/env python3
"""
Fix character encoding issues in plate descriptions.
Bakes the encoding corrections directly into the JSON files.
"""

import json
import re

def fix_encoding(text):
    """Fix corrupted UTF-8 encoding for Icelandic characters"""
    if not text:
        return text

    # Fix specific corrupted names first (exact matches)
    replacements = {
        # Names
        "MAGNÃšS": "MAGNÚS",
        "MagnÃºs": "Magnús",
        "MAGNÚS": "MAGNUS",  # Also normalize to MAGNUS for consistency
        "Magnús": "Magnus",
        "JÃN": "JÓN",
        "JÃ³n": "Jón",
        "GuÃ°rÃºn": "Guðrún",
        "GUÃ°RÃšN": "GUÐRÚN",
        "GUÐRÚN": "GUDRUN",  # Normalize
        "Guðrún": "Gudrun",
        "SigrÃ­Ã°": "Sigrid",
        "SIGRÃÃ°": "SIGRID",

        # Icelandic words
        "Ã¾rÃ­r": "þrír",  # three
        "fjÃ³rir": "fjórir",  # four
        "Ã­slenskur": "íslenskur",  # Icelandic
        "ÃžÃº": "Þú",  # You
        "Ã©g": "ég",  # I
        "hÃºn": "hún",  # she
        "HÃšN": "HÚN",  # SHE
        "mÃ­n": "mín",  # mine
        "MÃN": "MÍN",  # MINE
        "ennÃ¾Ã¡": "ennþá",  # yet/still
        "rÃ©ttir": "réttir",  # sheep sorting pens
        "klettagjÃ¡": "klettagjá",  # rock cleft
        "baÃ°stofa": "baðstofa",  # living room
        "faldbÃºningur": "faldbúningur",  # headdress
        "harÃ°fiskur": "harðfiskur",  # dried fish
        "hÃ¡karl": "hákarl",  # fermented shark
        "vaÃ°mÃ¡l": "vaðmál",  # wool fabric
        "JÃ¶rmungandr": "Jörmungandr",  # world serpent
        "landvÃ¦ttir": "landvættir",  # land spirits
        "GrÃ­Ã°ungur": "Gríðungur",  # bull
        "forystufÃ©": "forystuféð",  # lead sheep
        "GlÃ¡mr": "Glámr",  # name from saga
        "RagnarÃ¶k": "Ragnarök",  # end of world
        "Ãsland": "Ísland",  # Iceland
        "ÃSLAND": "ÍSLAND",  # ICELAND

        # General patterns - lowercase
        "Ã¡": "á",
        "Ã©": "é",
        "Ã­": "í",
        "Ã³": "ó",
        "Ãº": "ú",
        "Ã½": "ý",
        "Ã¾": "þ",
        "Ã°": "ð",
        "Ã¦": "æ",
        "Ã¶": "ö",

        # Uppercase
        "Ã": "Á",
        "Ã‰": "É",
        "Ã": "Í",
        "Ã": "Ó",
        "Ãš": "Ú",
        "Ã": "Ý",
        "Ãž": "Þ",
        "Ã": "Ð",
        "Ã†": "Æ",
        "Ã–": "Ö",

        # Also fix these common ones
        "Þorláksson": "Thorlaksson",
        "Magnúsdóttir": "Magnusdottir",
        "Magnússon": "Magnusson",
    }

    result = text
    for bad, good in replacements.items():
        result = result.replace(bad, good)

    return result

def fix_plate_file(filepath):
    """Fix encoding in a plate JSON file"""

    print(f"Processing {filepath}...")

    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    fixed_count = 0

    # Fix plates if they exist
    if 'plate_index' in data:
        plates = data['plate_index']

        for plate_id, plate_data in plates.items():
            # Fix description
            if 'description' in plate_data:
                original = plate_data['description']
                fixed = fix_encoding(original)
                if original != fixed:
                    plate_data['description'] = fixed
                    fixed_count += 1
                    print(f"  Fixed {plate_id}")

            # Fix name
            if 'name' in plate_data:
                original = plate_data['name']
                fixed = fix_encoding(original)
                if original != fixed:
                    plate_data['name'] = fixed

            # Fix character name
            if 'character' in plate_data:
                original = plate_data['character']
                fixed = fix_encoding(original)
                if original != fixed:
                    plate_data['character'] = fixed

    # Save if changes were made
    if fixed_count > 0:
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"  Saved {fixed_count} fixes to {filepath}")
    else:
        print(f"  No encoding issues found")

    return fixed_count

def main():
    import glob

    print("=" * 60)
    print("FIXING CHARACTER ENCODING IN PLATE FILES")
    print("=" * 60)

    # Fix main character plates file
    main_file = '/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json'
    fixes = fix_plate_file(main_file)

    # Also fix environmental plates
    env_file = '/Users/ingthor/Documents/stories/appdata/json/7/plates/environmental_plates_complete.json'
    if os.path.exists(env_file):
        fixes += fix_plate_file(env_file)

    # Fix any backup files too
    for backup_file in glob.glob('/Users/ingthor/Documents/stories/appdata/json/7/plates/*.json'):
        if 'complete' in backup_file or 'index' in backup_file:
            fix_plate_file(backup_file)

    print("\n" + "=" * 60)
    print("ENCODING FIXES COMPLETE")
    print("=" * 60)

    # Verify the main file
    print("\nVerifying main plate file...")
    with open(main_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Check for any remaining encoding issues
    remaining_issues = []
    if 'plate_index' in data:
        for plate_id, plate_data in data['plate_index'].items():
            desc = plate_data.get('description', '')
            # Check for common corruption patterns
            if any(pattern in desc for pattern in ['Ã', 'Ãº', 'Ã¡', 'Ã©', 'Ã­', 'Ã³', 'Ã¶', 'Ã½', 'Ã¾', 'Ã°']):
                remaining_issues.append(plate_id)

    if remaining_issues:
        print(f"⚠️ Warning: {len(remaining_issues)} plates may still have encoding issues:")
        for pid in remaining_issues[:5]:
            print(f"  - {pid}")
    else:
        print("✅ All encoding issues have been fixed!")

import os

if __name__ == "__main__":
    main()