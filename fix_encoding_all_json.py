#!/usr/bin/env python3
"""
Fix character encoding issues in all JSON files.
Converts corrupted UTF-8 characters back to proper Icelandic characters.
"""

import json
import os
import shutil
from pathlib import Path
from datetime import datetime

def fix_encoding(text):
    """Fix common encoding issues with Icelandic characters."""
    if not isinstance(text, str):
        return text

    # Common character replacements based on the pattern seen
    replacements = {
        'Ã¡': 'á',  # á
        'Ã©': 'é',  # é
        'Ã­': 'í',  # í
        'Ã³': 'ó',  # ó
        'Ãº': 'ú',  # ú
        'Ã½': 'ý',  # ý
        'Ã¦': 'æ',  # æ
        'Ã¶': 'ö',  # ö
        'Ãž': 'þ',  # þ (thorn)
        'Ã': 'Á',  # Á
        'Ã‰': 'É',  # É
        'Ã': 'Í',  # Í
        'Ã"': 'Ó',  # Ó
        'Ãš': 'Ú',  # Ú
        'Ã': 'Ý',  # Ý
        'Ã†': 'Æ',  # Æ
        'Ã–': 'Ö',  # Ö
        'Ãž': 'Þ',  # Þ
        'Ã°': 'ð',  # ð (eth)
        'Ã': 'Ð',  # Ð

        # Special cases for combined issues
        'MagnÃºs': 'Magnús',
        'GuÃ°rÃºn': 'Guðrún',
        'MAGNÃ\u0161S': 'MAGNÚS',
        'GUÃ\u0090RÃ\u0161N': 'GUÐRÚN',
        'JÃ¡rmungandr': 'Jörmungandr',
        'FORYSTUFÃƒÂ\u00a9': 'FORYSTUFÉ',
        'BaÃ°stofa': 'Baðstofa',
        'BAÃ\u0090STOFA': 'BAÐSTOFA',
        'RagnarÃ¶k': 'Ragnarök',
        'GrÃ­mur': 'Grímur',
        'GriÃ°ungur': 'Griðungur',
        'RÃ¡ttir': 'Réttir',
        'KlettagjÃ¡': 'Klettagjá',
        'DauÃ°ur': 'Dauður',

        # More general patterns
        'Ã\u0081': 'Á',
        'Ã\u0090': 'Ð',
        'Ã\u0093': 'Ó',
        'Ã\u009a': 'Ú',
        'Ã\u009d': 'Ý',
        'Ã\u009e': 'Þ',
    }

    result = text
    for bad, good in replacements.items():
        result = result.replace(bad, good)

    return result

def fix_json_encoding(obj):
    """Recursively fix encoding in JSON object."""
    if isinstance(obj, dict):
        return {fix_encoding(k): fix_json_encoding(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [fix_json_encoding(item) for item in obj]
    elif isinstance(obj, str):
        return fix_encoding(obj)
    else:
        return obj

def process_json_file(filepath):
    """Process a single JSON file to fix encoding."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # Fix encoding
        fixed_data = fix_json_encoding(data)

        # Check if anything changed
        original_str = json.dumps(data, sort_keys=True)
        fixed_str = json.dumps(fixed_data, sort_keys=True)

        if original_str != fixed_str:
            # Create backup
            backup_path = filepath.with_suffix('.json.backup_' + datetime.now().strftime('%Y%m%d_%H%M%S'))
            shutil.copy2(filepath, backup_path)
            print(f"✓ Backed up: {backup_path.name}")

            # Write fixed data
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(fixed_data, f, indent=2, ensure_ascii=False)

            print(f"✓ Fixed: {filepath.name}")
            return True
        else:
            print(f"  No changes needed: {filepath.name}")
            return False

    except Exception as e:
        print(f"✗ Error processing {filepath}: {e}")
        return False

def main():
    print("=== Fixing Character Encoding in JSON Files ===\n")

    base_path = Path("/Users/ingthor/Documents/stories/appdata/json/7")

    files_to_fix = []

    # 1. Character plates
    char_plates = base_path / "plates" / "character_plates_complete.json"
    if char_plates.exists():
        files_to_fix.append(char_plates)

    # 2. Environmental plates
    env_plates = base_path / "plates" / "environmental_plates_complete.json"
    if env_plates.exists():
        files_to_fix.append(env_plates)

    # 3. Main film system
    main_film = base_path / "main_film_system.json"
    if main_film.exists():
        files_to_fix.append(main_film)

    # 4. All shot JSON files
    shots_dir = base_path / "shots" / "json"
    if shots_dir.exists():
        files_to_fix.extend(shots_dir.glob("*.json"))

    print(f"Found {len(files_to_fix)} JSON files to process\n")

    fixed_count = 0
    for filepath in files_to_fix:
        if process_json_file(filepath):
            fixed_count += 1

    print(f"\n=== Summary ===")
    print(f"Total files processed: {len(files_to_fix)}")
    print(f"Files fixed: {fixed_count}")
    print(f"Files unchanged: {len(files_to_fix) - fixed_count}")

if __name__ == "__main__":
    main()