#!/usr/bin/env python3
"""
Fix character plates to use proper IDs that match shot references,
while preserving the plate_index structure the app expects.
"""

import json
import re

def determine_plate_id(plate_data, old_id):
    """Determine the proper plate ID based on the description and character"""

    character = plate_data.get('character', '').upper()
    description = plate_data.get('description', '').lower()
    name = plate_data.get('name', '').upper()
    is_master = plate_data.get('is_master', False)

    # Handle master plates
    if is_master or 'master' in name.lower() or 'Master base' in description:
        return f"{character}-MASTER"

    # Character-specific mappings based on descriptions
    if character == "SIGRID":
        if 'pure innocence' in description.lower() and 'untouched' in description:
            return "SIGRID-PURE"
        elif 'cornered' in description or 'incest resistance' in description.lower():
            return "SIGRID-CORNERED"
        elif 'marked' in description or 'violation' in description:
            return "SIGRID-MARKED"
        elif 'corvid' in description or 'raven' in description:
            return "SIGRID-CORVID"
        elif 'mathematical' in description:
            return "SIGRID-MATHEMATICAL"
        elif 'witness burden' in description:
            return "SIGRID-WITNESS"
        elif 'house protection' in description:
            return "SIGRID-PROTECTED"

    elif character == "MAGNUS" or character == "MAGNÚS":
        if 'predator' in description or 'violence' in description or 'threat' in description:
            return "MAGNUS-PREDATOR"
        elif 'authority' in description and 'summer' in description:
            return "MAGNUS-AUTHORITY"
        elif 'confused' in description or 'mathematical breakdown' in description:
            return "MAGNUS-CONFUSED"
        elif 'ram' in description:
            return "MAGNÚS-RAM"

    elif character == "GUDRUN" or character == "GUÐRÚN":
        if 'abundant' in description or 'competence' in description:
            return "GUDRUN-ABUNDANT"
        elif 'condemned' in description or 'death' in description:
            return "GUDRUN-CONDEMNED"
        elif 'eternal' in description or 'ewe' in description:
            return "GUDRUN-ETERNAL"
        elif 'producing' in description or 'wool' in description:
            return "GUDRUN-PRODUCING"

    elif character == "JON" or character == "JÓN":
        if 'temporal' in description or 'sight' in description:
            return "JON-TEMPORAL"
        elif 'mild' in description or 'fever' in description.lower() and 'early' in description:
            return "JON-MILD"
        elif 'lamb' in description and 'complete' in description:
            return "JON-LAMB"
        elif 'prophet' in description:
            return "JON-PROPHET"

    elif character == "LILJA":
        if 'pure' in description and 'innocence' in description:
            return "LILJA-PURE"
        elif 'sensing' in description or 'environmental' in description:
            return "LILJA-SENSING"
        elif 'mathematical' in description:
            return "LILJA-MATHEMATICAL"
        elif 'lamb' in description:
            return "LILJA-LAMB"

    # If no specific match, generate based on name/old_id
    if 'PLATE' in name:
        plate_num = re.search(r'PLATE\s*(\d+)', name)
        if plate_num:
            return f"{character}-PLATE{plate_num.group(1)}"

    # Default fallback - use cleaned version of old ID
    if '_' in old_id:
        parts = old_id.split('_')
        return f"{character.upper()}-{parts[-1].upper()}"

    return f"{character}-{old_id.upper()}"

def fix_bracket_references(description):
    """Fix bracket references in descriptions"""
    if not description:
        return description

    # Map of bad references to correct ones
    ref_map = {
        '[Master base]': '[MAGNÚS-MASTER]',
        '[Pure base]': '[SIGRID-PURE]',
        '[Knowing base]': '[SIGRID-MASTER]',
        '[Oracle base]': '[SIGRID-MASTER]',
        '[Summoning base]': '[SIGRID-MASTER]',
        '[Cornered base]': '[SIGRID-CORNERED]',
        '[Awakening base]': '[SIGRID-PURE]',
        '[Marked base]': '[SIGRID-MARKED]',
        '[Chosen base]': '[SIGRID-MASTER]',
        '[Becoming base]': '[SIGRID-CORVID]',
        '[Transitional base]': '[SIGRID-CORVID]',
        '[Dual base]': '[SIGRID-CORVID]',
        '[Abundant base]': '[GUDRUN-ABUNDANT]',
        '[Mild base]': '[JON-MILD]',
        '[Harmonic base]': '[LILJA-PURE]',
        '[Sensing base]': '[LILJA-SENSING]',
        '[Mathematical base]': '[LILJA-MATHEMATICAL]',
        '[Communicating base]': '[LILJA-SENSING]',
        '[Evolving base]': '[LILJA-PURE]',
        '[Accepting base]': '[LILJA-LAMB]'
    }

    result = description
    for bad_ref, good_ref in ref_map.items():
        result = result.replace(bad_ref, good_ref)

    return result

def main():
    # Load current file
    with open('/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Get plates from nested or flat structure
    if 'plate_index' in data:
        plates = data['plate_index']
    else:
        plates = {k: v for k, v in data.items() if not k.startswith('_')}

    print(f"Processing {len(plates)} plates...")

    # Create new plate_index with proper IDs
    new_plate_index = {}
    id_mapping = {}  # Track old to new ID mappings

    for old_id, plate_data in plates.items():
        # Determine the correct plate ID
        new_id = determine_plate_id(plate_data, old_id)

        # Fix bracket references in description
        if 'description' in plate_data:
            plate_data['description'] = fix_bracket_references(plate_data['description'])

        # Clean up name field
        if 'name' in plate_data and plate_data['name'].startswith('**'):
            plate_data['name'] = plate_data['name'][2:].strip()

        # Store with new ID
        new_plate_index[new_id] = plate_data
        id_mapping[old_id] = new_id

    # Add any critical missing plates that shots reference
    critical_plates = {
        "BAÐSTOFA-DOMESTIC": {
            "character": "Environment",
            "name": "Baðstofa Domestic",
            "description": "The living space in its domestic state - warm, inhabited, breathing",
            "is_master": False
        },
        "WESTFJORDS-CLIFF": {
            "character": "Environment",
            "name": "Westfjords Cliff",
            "description": "Cliff environment plate for Westfjords setting",
            "is_master": False
        }
    }

    for plate_id, plate_data in critical_plates.items():
        if plate_id not in new_plate_index:
            new_plate_index[plate_id] = plate_data

    # Create final structure with plate_index as app expects
    final_data = {
        "plate_index": new_plate_index,
        "_total_plates": len(new_plate_index),
        "_complete_system": True,
        "last_updated": data.get("last_updated", "")
    }

    # Save the fixed file
    with open('/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json', 'w', encoding='utf-8') as f:
        json.dump(final_data, f, ensure_ascii=False, indent=2)

    print(f"\nFixed {len(new_plate_index)} plates")
    print("\nID mappings:")
    for old_id, new_id in sorted(id_mapping.items())[:20]:
        print(f"  {old_id} -> {new_id}")

    # Count by character
    by_char = {}
    for plate_id in new_plate_index:
        char = plate_id.split('-')[0]
        by_char[char] = by_char.get(char, 0) + 1

    print("\nPlates by character:")
    for char, count in sorted(by_char.items()):
        print(f"  {char}: {count} plates")

if __name__ == "__main__":
    main()