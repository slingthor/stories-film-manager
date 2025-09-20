#!/usr/bin/env python3
"""
Fix character plate descriptions that incorrectly start with references to other plates.
This was causing multiple characters to show Magnus's description.
"""

import json
import re
from datetime import datetime
import shutil

def create_backup(file_path):
    """Create timestamped backup of file"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{file_path}.backup_fix_refs_{timestamp}"
    shutil.copy2(file_path, backup_path)
    print(f"Created backup: {backup_path}")
    return backup_path

def fix_plate_reference_in_description(description):
    """Remove plate references from the beginning of descriptions"""
    # Pattern to match [PLATENAME-VARIANT] at the start of description
    pattern = r'^\s*\[[A-Z]+-[A-Z]+(?:-[A-Z]+)*\]\s*'

    # Check if description starts with a plate reference
    if re.match(pattern, description):
        # Remove the plate reference from the beginning
        fixed = re.sub(pattern, '', description)
        return fixed.strip()

    return description

def fix_plate_descriptions(data):
    """Fix all plate descriptions in the JSON data"""
    fixed_count = 0

    if 'plate_index' in data:
        for plate_id, plate_data in data['plate_index'].items():
            if 'description' in plate_data:
                original = plate_data['description']
                fixed = fix_plate_reference_in_description(original)

                if original != fixed:
                    print(f"Fixing {plate_id}:")
                    print(f"  - Removed reference from beginning")
                    # Show first 100 chars of before/after
                    print(f"  - Before: {original[:100]}...")
                    print(f"  - After:  {fixed[:100]}...")
                    print()
                    plate_data['description'] = fixed
                    fixed_count += 1

    return fixed_count

def main():
    """Fix character plates with incorrect plate references in descriptions"""
    file_path = '/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json'

    print(f"Processing: {file_path}")
    print("-" * 50)

    try:
        # Create backup
        create_backup(file_path)

        # Read JSON
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # Fix descriptions
        fixed_count = fix_plate_descriptions(data)

        if fixed_count > 0:
            print(f"\n✓ Fixed {fixed_count} plate descriptions")

            # Write back
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)

            print(f"✓ Successfully saved fixes to {file_path}")
        else:
            print("No plate references found at beginning of descriptions")

    except Exception as e:
        print(f"Error processing {file_path}: {e}")

if __name__ == "__main__":
    main()