#!/usr/bin/env python3
"""
Verify all JSON files are valid after encoding fixes.
"""

import json
from pathlib import Path

def verify_json_file(filepath):
    """Verify a single JSON file is valid."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return True, None
    except json.JSONDecodeError as e:
        return False, str(e)
    except Exception as e:
        return False, str(e)

def main():
    print("=== Verifying JSON Files ===\n")

    base_path = Path("/Users/ingthor/Documents/stories/appdata/json/7")

    files_to_verify = []

    # 1. Character plates
    char_plates = base_path / "plates" / "character_plates_complete.json"
    if char_plates.exists():
        files_to_verify.append(char_plates)

    # 2. Environmental plates
    env_plates = base_path / "plates" / "environmental_plates_complete.json"
    if env_plates.exists():
        files_to_verify.append(env_plates)

    # 3. Main film system
    main_film = base_path / "main_film_system.json"
    if main_film.exists():
        files_to_verify.append(main_film)

    # 4. All shot JSON files
    shots_dir = base_path / "shots" / "json"
    if shots_dir.exists():
        files_to_verify.extend(shots_dir.glob("*.json"))

    print(f"Found {len(files_to_verify)} JSON files to verify\n")

    valid_count = 0
    invalid_files = []

    for filepath in files_to_verify:
        valid, error = verify_json_file(filepath)
        if valid:
            valid_count += 1
            print(f"✓ Valid: {filepath.name}")
        else:
            invalid_files.append((filepath, error))
            print(f"✗ Invalid: {filepath.name}")
            print(f"  Error: {error}")

    print(f"\n=== Summary ===")
    print(f"Total files checked: {len(files_to_verify)}")
    print(f"Valid JSON files: {valid_count}")
    print(f"Invalid JSON files: {len(invalid_files)}")

    if invalid_files:
        print("\n=== Invalid Files Details ===")
        for filepath, error in invalid_files:
            print(f"\n{filepath.name}:")
            print(f"  {error}")
    else:
        print("\n✅ All JSON files are valid!")

    # Quick content check on a few files
    print("\n=== Sample Content Check ===")
    sample_files = [char_plates, env_plates, main_film]

    for filepath in sample_files:
        if filepath.exists():
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                # Check for any remaining encoding issues
                if 'Ã' in content:
                    print(f"⚠️  {filepath.name}: Still contains potential encoding issues (Ã characters)")
                else:
                    print(f"✓ {filepath.name}: No obvious encoding issues")

if __name__ == "__main__":
    main()