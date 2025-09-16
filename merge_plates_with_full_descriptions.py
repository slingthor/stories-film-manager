#!/usr/bin/env python3
"""
Merge the old backup plate file with full descriptions from enhancement files,
ensuring proper master plate mappings are applied during the merge process.
"""

import json
import re
import os

def extract_plates_from_enhancement_file(filepath):
    """Extract plate definitions from enhancement text files"""
    plates = {}

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Extract character name from filename
    filename = os.path.basename(filepath).lower()
    if 'magnus' in filename:
        character = 'Magnus'
    elif 'sigrid' in filename:
        character = 'Sigrid'
    elif 'gudrun' in filename:
        character = 'Gudrun'
    elif 'jon' in filename:
        character = 'Jon'
    elif 'lilja' in filename:
        character = 'Lilja'
    elif 'baðstofa' in filename or 'house' in filename:
        character = 'Environment'
    elif 'sea' in filename:
        character = 'Environment'
    elif 'westfjords' in filename:
        character = 'Environment'
    else:
        character = 'Environment'

    # Pattern to find plate definitions
    # Look for patterns like "MAGNÚS-MASTER-V2:" or "PLATE 1:" or "MAGNÚS-SUMMER:"
    patterns = [
        r'(MAGNÚS-[A-Z\-]+(?:-V\d+)?):?\s*([^\n]+(?:\n(?![A-Z]{3,})[^\n]+)*)',
        r'(SIGRID-[A-Z\-]+(?:-V\d+)?):?\s*([^\n]+(?:\n(?![A-Z]{3,})[^\n]+)*)',
        r'(GUÐRÚN-[A-Z\-]+(?:-V\d+)?):?\s*([^\n]+(?:\n(?![A-Z]{3,})[^\n]+)*)',
        r'(JÓN-[A-Z\-]+(?:-V\d+)?):?\s*([^\n]+(?:\n(?![A-Z]{3,})[^\n]+)*)',
        r'(LILJA-[A-Z\-]+(?:-V\d+)?):?\s*([^\n]+(?:\n(?![A-Z]{3,})[^\n]+)*)',
        r'(BAÐSTOFA-[A-Z\-]+):?\s*([^\n]+(?:\n(?![A-Z]{3,})[^\n]+)*)',
        r'(STOFA-[A-Z\-]+):?\s*([^\n]+(?:\n(?![A-Z]{3,})[^\n]+)*)',
        r'(WESTFJORDS-[A-Z\-]+):?\s*([^\n]+(?:\n(?![A-Z]{3,})[^\n]+)*)',
        r'(SEA-[A-Z\-]+):?\s*([^\n]+(?:\n(?![A-Z]{3,})[^\n]+)*)',
        r'(HOUSE-[A-Z\-]+):?\s*([^\n]+(?:\n(?![A-Z]{3,})[^\n]+)*)',
    ]

    for pattern in patterns:
        matches = re.finditer(pattern, content, re.MULTILINE)
        for match in matches:
            plate_id = match.group(1)
            description = match.group(2).strip()

            # Clean up the plate ID
            plate_id = plate_id.replace('-V2', '').replace('-V3', '')
            plate_id = plate_id.replace('MAGNÚS', 'MAGNUS')
            plate_id = plate_id.replace('GUÐRÚN', 'GUDRUN')
            plate_id = plate_id.replace('JÓN', 'JON')

            # Clean up description - remove excess whitespace, join lines
            description = ' '.join(description.split())

            # Skip if description is too short or looks like a header
            if len(description) < 50 or description.startswith('PLATE '):
                continue

            # Determine if this is a master plate
            is_master = 'MASTER' in plate_id

            plates[plate_id] = {
                'character': character,
                'name': plate_id.replace('-', ' ').title(),
                'description': description,
                'is_master': is_master
            }

    # Also look for named plates like "PLATE 1: Summer Authority"
    plate_pattern = r'PLATE \d+:\s*([^\n]+)\n([A-Z\-]+):\s*([^\n]+(?:\n(?!PLATE)[^\n]+)*)'
    matches = re.finditer(plate_pattern, content, re.MULTILINE)
    for match in matches:
        name = match.group(1).strip()
        plate_id = match.group(2)
        description = match.group(3).strip()

        # Clean up
        plate_id = plate_id.replace('MAGNÚS', 'MAGNUS').replace('GUÐRÚN', 'GUDRUN').replace('JÓN', 'JON')
        description = ' '.join(description.split())

        if len(description) > 50:
            plates[plate_id] = {
                'character': character,
                'name': name,
                'description': description,
                'is_master': False
            }

    return plates

def fix_bracket_references(description):
    """Fix bracket references to use proper plate IDs"""
    if not description:
        return description

    # Map base references to proper master plates
    master_ref_map = {
        '[Master base]': '[MAGNUS-MASTER]',
        '[MAGNUS-MASTER base]': '[MAGNUS-MASTER]',
        '[MAGNÚS-MASTER]': '[MAGNUS-MASTER]',
        '[Pure base]': '[SIGRID-PURE]',
        '[Sigrid base]': '[SIGRID-MASTER]',
        '[SIGRID-MASTER base]': '[SIGRID-MASTER]',
        '[Abundant base]': '[GUDRUN-ABUNDANT]',
        '[Gudrun base]': '[GUDRUN-MASTER]',
        '[GUDRUN-MASTER base]': '[GUDRUN-MASTER]',
        '[Mild base]': '[JON-MILD]',
        '[Jon base]': '[JON-MASTER]',
        '[JON-MASTER base]': '[JON-MASTER]',
        '[Lilja base]': '[LILJA-MASTER]',
        '[LILJA-MASTER base]': '[LILJA-MASTER]',
        '[Previous aging base]': '[MAGNUS-AGING]',
        '[Injured base]': '[MAGNUS-WOUNDED]',
        '[Defeated base]': '[MAGNUS-DEFEATED]',
        '[Predator base]': '[MAGNUS-PREDATOR]',
        '[Authority base]': '[MAGNUS-ENFORCER]',
        '[Possessor base]': '[MAGNUS-POSSESSOR]',
        '[Shifting base]': '[MAGNUS-SHIFTING]',
        '[Recognition base]': '[MAGNUS-RECOGNIZING]',
        '[Breaking base]': '[MAGNUS-BREAKING]',
        '[Preparing base]': '[MAGNUS-PREPARING]'
    }

    result = description
    # Apply all mappings
    for bad_ref, good_ref in master_ref_map.items():
        result = result.replace(bad_ref, good_ref)

    return result

def normalize_plate_id(plate_id):
    """Normalize plate IDs to match shot references"""
    # Handle S- prefix plates (Magnus plates from old backup)
    if plate_id.startswith('S-'):
        # S- prefix indicates Magnus character
        suffix = plate_id[2:]
        if suffix == 'RAM':
            return 'MAGNUS-RAM'
        else:
            return 'MAGNUS-' + suffix
    elif plate_id.startswith('N-'):
        # N- prefixes need context-based mapping
        suffix = plate_id[2:]
        if 'PROPHET' in suffix or 'TEMPORAL' in suffix or 'CHANGING' in suffix:
            return 'JON-' + suffix
        elif 'RECOGNIZING' in suffix or 'WATCHING' in suffix or 'PROTECTING' in suffix:
            return 'GUDRUN-' + suffix
        elif 'ABUNDANT' in suffix or 'COUNTING' in suffix or 'PRODUCING' in suffix:
            return 'GUDRUN-' + suffix
        else:
            return plate_id[2:]  # Remove N- prefix

    # Already normalized
    return plate_id

def main():
    # First, extract all plates from enhancement files
    enhancement_plates = {}
    enhancement_dir = '/Users/ingthor/Documents/stories/enhancements/enhancements/charsystem'

    enhancement_files = [
        'magnus_advanced_character_plates_system.txt',
        'sigrid_advanced_character_plates_system.txt',
        'gudrun_advanced_character_plates_system.txt',
        'jon_advanced_character_plates_system.txt',
        'lilja_advanced_character_plates_system.txt',
        'lilja_complete_character_plates_expanded.txt',
        'baðstofa_environmental_plates_bergrisi_transformation.txt',
        'house_exterior_immediate_surroundings_plates.txt',
        'sea_environmental_plates_character_progression.txt',
        'westfjords_exterior_environmental_plates_system.txt'
    ]

    print("Extracting plates from enhancement files...")
    for filename in enhancement_files:
        filepath = os.path.join(enhancement_dir, filename)
        if os.path.exists(filepath):
            print(f"  Processing {filename}")
            file_plates = extract_plates_from_enhancement_file(filepath)
            enhancement_plates.update(file_plates)
            print(f"    Found {len(file_plates)} plates")

    print(f"\nTotal plates extracted from enhancements: {len(enhancement_plates)}")

    # Load the old backup file (has correct ID structure)
    backup_path = '/Users/ingthor/Documents/stories/appdata copy 5/json/7/character_plates_index.json'
    with open(backup_path, 'r', encoding='utf-8') as f:
        backup_data = json.load(f)

    # Start with enhancement plates as base
    merged_plates = {}

    # Add all enhancement plates with proper references fixed
    for plate_id, plate_data in enhancement_plates.items():
        plate_data['description'] = fix_bracket_references(plate_data['description'])
        merged_plates[plate_id] = plate_data

    # Process backup plates - normalize IDs and merge
    backup_plates = backup_data.get('plate_index', backup_data)
    for old_id, plate_data in backup_plates.items():
        # Normalize the plate ID
        new_id = normalize_plate_id(old_id)

        # If we don't have this plate from enhancements, add it
        if new_id not in merged_plates:
            # Fix bracket references in description
            if 'description' in plate_data:
                plate_data['description'] = fix_bracket_references(plate_data['description'])

            # Ensure character field is set correctly
            if 'character' not in plate_data or not plate_data['character']:
                parts = new_id.split('-')
                if parts[0] in ['MAGNUS', 'SIGRID', 'GUDRUN', 'JON', 'LILJA']:
                    plate_data['character'] = parts[0].title()

            merged_plates[new_id] = plate_data
        else:
            # We have enhancement description - but check if backup has useful metadata
            if 'name' not in merged_plates[new_id] and 'name' in plate_data:
                merged_plates[new_id]['name'] = plate_data['name']

    # Add critical master plates if somehow missing
    critical_masters = {
        "MAGNUS-MASTER": {
            "character": "Magnus",
            "name": "Magnus Master",
            "is_master": True
        },
        "SIGRID-MASTER": {
            "character": "Sigrid",
            "name": "Sigrid Master",
            "is_master": True
        },
        "GUDRUN-MASTER": {
            "character": "Gudrun",
            "name": "Gudrun Master",
            "is_master": True
        },
        "JON-MASTER": {
            "character": "Jon",
            "name": "Jon Master",
            "is_master": True
        },
        "LILJA-MASTER": {
            "character": "Lilja",
            "name": "Lilja Master",
            "is_master": True
        }
    }

    for plate_id, metadata in critical_masters.items():
        if plate_id not in merged_plates:
            print(f"Warning: Master plate {plate_id} not found in enhancements, using fallback")
            merged_plates[plate_id] = metadata
        elif 'description' not in merged_plates[plate_id] or not merged_plates[plate_id]['description']:
            print(f"Warning: Master plate {plate_id} has no description")

    # Create final structure
    final_data = {
        "plate_index": dict(sorted(merged_plates.items())),
        "_total_plates": len(merged_plates),
        "_complete_system": True,
        "last_updated": "2025-09-16T08:00:00Z"
    }

    # Save the merged file
    output_path = '/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json'
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(final_data, f, ensure_ascii=False, indent=2)

    print(f"\nMerged {len(merged_plates)} plates to {output_path}")

    # Show plate counts by character
    by_char = {}
    for plate_id in merged_plates:
        char = merged_plates[plate_id].get('character', 'Unknown')
        by_char[char] = by_char.get(char, 0) + 1

    print("\nPlates by character:")
    for char, count in sorted(by_char.items()):
        print(f"  {char}: {count} plates")

    # Check which plates have descriptions
    with_desc = sum(1 for p in merged_plates.values() if p.get('description'))
    without_desc = len(merged_plates) - with_desc
    print(f"\nPlates with descriptions: {with_desc}")
    print(f"Plates without descriptions: {without_desc}")

    if without_desc > 0:
        print("\nPlates missing descriptions:")
        for plate_id, plate_data in merged_plates.items():
            if not plate_data.get('description'):
                print(f"  {plate_id}")

if __name__ == "__main__":
    main()