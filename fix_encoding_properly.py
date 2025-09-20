#!/usr/bin/env python3
"""
Fix character encoding issues in all JSON files - more comprehensive version.
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

    # More comprehensive replacements based on actual errors seen
    replacements = {
        # Specific cases found in the files
        'GuÐ°rún': 'Guðrún',
        'GuÐ°rÃºn': 'Guðrún',
        'MagnÃºs': 'Magnús',
        'Magnús': 'Magnús',  # This one seems OK
        'Ð¾á': 'þá',
        'ÞÐš': 'ÞÚ',
        'Â°': '°',
        # Arrow character - removed due to encoding issues

        # General Icelandic character fixes
        'Ã¡': 'á',
        'Ã©': 'é',
        'Ã­': 'í',
        'Ã³': 'ó',
        'Ãº': 'ú',
        'Ã½': 'ý',
        'Ã¦': 'æ',
        'Ã¶': 'ö',
        'Ãž': 'þ',
        'Ã°': 'ð',
        'Ã': 'Á',
        'Ã‰': 'É',
        'Ã': 'Í',
        'Ã"': 'Ó',
        'Ãš': 'Ú',
        'Ã': 'Ý',
        'Ã†': 'Æ',
        'Ã–': 'Ö',
        'Ãž': 'Þ',
        'Ã': 'Ð',

        # More complex patterns
        'JÃ¡rmungandr': 'Jörmungandr',
        'JÃ³rmungandr': 'Jörmungandr',
        'JÃRMUNGANDR': 'JÖRMUNGANDR',
        'FORYSTUFÃƒÂ\u00a9': 'FORYSTUFÉ',
        'FORYSTUFÃ': 'FORYSTUFÉ',
        'BaÃ°stofa': 'Baðstofa',
        'BAÃ\u0090STOFA': 'BAÐSTOFA',
        'RagnarÃ¶k': 'Ragnarök',
        'Ragnarök': 'Ragnarök',  # This one seems OK
        'GrÃ­mur': 'Grímur',
        'GriÃ°ungur': 'Griðungur',
        'GriÃšngur': 'Griðungur',
        'GRIÃŠNGUR': 'GRIÐUNGUR',
        'RÃ¡ttir': 'Réttir',
        'RÃttir': 'Réttir',
        'RÃTTIR': 'RÉTTIR',
        'KlettagjÃ¡': 'Klettagjá',
        'Klettagjá': 'Klettagjá',  # This one seems OK
        'DauÃ°ur': 'Dauður',
        'DauÃšr': 'Dauður',
        'DAUÃŠR': 'DAUÐUR',

        # Fix double-encoded UTF-8
        'Ã\u0081': 'Á',
        'Ã\u0090': 'Ð',
        'Ã\u0093': 'Ó',
        'Ã\u009a': 'Ú',
        'Ã\u009d': 'Ý',
        'Ã\u009e': 'Þ',

        # Fix the specific broken patterns
        'Ð°': 'ð',  # Cyrillic a that should be eth
        'Ðš': 'Ú',
        'Ð¾': 'þ',
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
        original_str = json.dumps(data, sort_keys=True, ensure_ascii=False)
        fixed_str = json.dumps(fixed_data, sort_keys=True, ensure_ascii=False)

        if original_str != fixed_str:
            # Create backup with new timestamp to avoid overwriting
            backup_path = filepath.with_suffix('.json.backup_proper_' + datetime.now().strftime('%Y%m%d_%H%M%S'))
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
    print("=== Fixing Character Encoding in JSON Files (Comprehensive) ===\n")

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