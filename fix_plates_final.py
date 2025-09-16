#!/usr/bin/env python3
"""
Final comprehensive fix for character plates:
1. Flatten nested structure completely
2. Fix all bracket references
3. Convert IDs to proper format
"""

import json
import re

def main():
    # Read the current file
    with open('/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Check if plates are nested under plate_index
    if 'plate_index' in data:
        plates = data['plate_index']
        print(f"Found {len(plates)} plates in nested structure")
    else:
        plates = {k: v for k, v in data.items() if not k.startswith('_')}
        print(f"Found {len(plates)} plates in flat structure")

    # Create new flat structure with proper IDs
    fixed_plates = {}

    # Process each plate
    for old_id, plate_data in plates.items():
        # Get character name
        char = plate_data.get('character', '').upper()

        # Map to proper Icelandic names
        char_map = {
            'MAGNUS': 'MAGNÚS',
            'GUDRUN': 'GUÐRÚN',
            'JON': 'JÓN',
            'LILJA': 'LILJA',
            'SIGRID': 'SIGRID'
        }
        char = char_map.get(char, char)

        # Generate new ID based on plate name
        name = plate_data.get('name', '')

        # Clean up names that start with **
        if name.startswith('**'):
            name = name[2:].strip()

        # Determine the new ID
        if plate_data.get('is_master', False):
            new_id = f"{char}-MASTER"
        elif 'PLATE' in name:
            # Extract plate number if present
            match = re.search(r'PLATE\s*(\d+)', name)
            if match:
                num = match.group(1)
                new_id = f"{char}-PLATE{num}"
            else:
                new_id = f"{char}-{name.replace(' ', '-').upper()}"
        else:
            # Use descriptive name from description if available
            desc = plate_data.get('description', '')
            if desc and '(' in desc:
                desc_name = desc.split('(')[0].strip()
                if desc_name and desc_name != '**':
                    new_id = f"{char}-{desc_name.replace(' ', '-').upper()}"
                else:
                    new_id = f"{char}-PLATE{old_id.split('_')[-1] if '_' in old_id else '1'}"
            else:
                new_id = f"{char}-PLATE{old_id.split('_')[-1] if '_' in old_id else '1'}"

        # Fix bracket references in description
        if 'description' in plate_data:
            desc = plate_data['description']

            # Map of bad references to correct ones
            ref_map = {
                '[Master base]': '[MAGNÚS-MASTER]',
                '[Pure base]': '[SIGRID-PURE]',
                '[Knowing base]': '[SIGRID-KNOWING]',
                '[Oracle base]': '[SIGRID-ORACLE]',
                '[Summoning base]': '[SIGRID-SUMMONING]',
                '[Cornered base]': '[SIGRID-CORNERED]',
                '[Awakening base]': '[SIGRID-AWAKENING]',
                '[Marked base]': '[SIGRID-MARKED]',
                '[Chosen base]': '[SIGRID-CHOSEN]',
                '[Becoming base]': '[SIGRID-BECOMING]',
                '[Transitional base]': '[SIGRID-TRANSITIONAL]',
                '[Dual base]': '[SIGRID-DUAL]',
                '[Abundant base]': '[GUÐRÚN-MASTER]',
                '[Mild base]': '[JÓN-MASTER]',
                '[Harmonic base]': '[LILJA-HARMONIC]',
                '[Sensing base]': '[LILJA-SENSING]',
                '[Mathematical base]': '[LILJA-MATHEMATICAL]',
                '[Communicating base]': '[LILJA-COMMUNICATING]',
                '[Evolving base]': '[LILJA-EVOLVING]',
                '[Accepting base]': '[LILJA-ACCEPTING]'
            }

            for bad_ref, good_ref in ref_map.items():
                desc = desc.replace(bad_ref, good_ref)

            plate_data['description'] = desc

        # Add to fixed structure
        fixed_plates[new_id] = plate_data

    # Add any missing master plates
    masters = {
        "MAGNÚS-MASTER": {
            "character": "Magnus",
            "name": "Master Authority",
            "description": "Base Magnus template - natural aristocratic authority through physical presence and family position",
            "is_master": True
        },
        "GUÐRÚN-MASTER": {
            "character": "Gudrun",
            "name": "Master Abundant",
            "description": "Base Gudrun template - overwhelming abundance becoming burden",
            "is_master": True
        },
        "JÓN-MASTER": {
            "character": "Jon",
            "name": "Master Mild",
            "description": "Base Jon template - gentle fevered child seeing through reality",
            "is_master": True
        },
        "LILJA-MASTER": {
            "character": "Lilja",
            "name": "Master Pure",
            "description": "Base Lilja template - innocent child with supernatural environmental awareness",
            "is_master": True
        },
        "SIGRID-MASTER": {
            "character": "Sigrid",
            "name": "Master Pure",
            "description": "Base Sigrid template - untouched innocence before violation and transformation",
            "is_master": True
        }
    }

    for master_id, master_data in masters.items():
        if master_id not in fixed_plates:
            fixed_plates[master_id] = master_data

    # Add variant plates that are referenced but might be missing
    variants = {
        "SIGRID-PURE": {
            "character": "Sigrid",
            "name": "Pure Innocence",
            "description": "Pure untouched innocence state",
            "is_master": False
        },
        "SIGRID-ORACLE": {
            "character": "Sigrid",
            "name": "Oracle Emergence",
            "description": "Oracle abilities emerging",
            "is_master": False
        },
        "SIGRID-KNOWING": {
            "character": "Sigrid",
            "name": "Knowing State",
            "description": "Knowledge and awareness state",
            "is_master": False
        },
        "SIGRID-SUMMONING": {
            "character": "Sigrid",
            "name": "Summoning Power",
            "description": "Supernatural summoning abilities",
            "is_master": False
        },
        "SIGRID-CORNERED": {
            "character": "Sigrid",
            "name": "Cornered Resistance",
            "description": "Cornered but resisting",
            "is_master": False
        },
        "SIGRID-AWAKENING": {
            "character": "Sigrid",
            "name": "Awakening Awareness",
            "description": "Growing defensive awareness",
            "is_master": False
        },
        "SIGRID-MARKED": {
            "character": "Sigrid",
            "name": "Marked State",
            "description": "Post-violation marked state",
            "is_master": False
        },
        "SIGRID-CHOSEN": {
            "character": "Sigrid",
            "name": "Chosen by Landvættir",
            "description": "Chosen and protected",
            "is_master": False
        },
        "SIGRID-BECOMING": {
            "character": "Sigrid",
            "name": "Becoming Raven",
            "description": "Active transformation state",
            "is_master": False
        },
        "SIGRID-TRANSITIONAL": {
            "character": "Sigrid",
            "name": "Transitional Form",
            "description": "Between species",
            "is_master": False
        },
        "SIGRID-DUAL": {
            "character": "Sigrid",
            "name": "Dual Nature",
            "description": "Both human and raven simultaneously",
            "is_master": False
        },
        "LILJA-HARMONIC": {
            "character": "Lilja",
            "name": "Harmonic Discovery",
            "description": "Discovering frequency abilities",
            "is_master": False
        },
        "LILJA-SENSING": {
            "character": "Lilja",
            "name": "Environmental Sensing",
            "description": "Supernatural environmental awareness",
            "is_master": False
        },
        "LILJA-MATHEMATICAL": {
            "character": "Lilja",
            "name": "Mathematical Observer",
            "description": "Child confusion about mathematical impossibility",
            "is_master": False
        },
        "LILJA-COMMUNICATING": {
            "character": "Lilja",
            "name": "House Communication",
            "description": "Communicating with house consciousness",
            "is_master": False
        },
        "LILJA-EVOLVING": {
            "character": "Lilja",
            "name": "Evolving Prophet",
            "description": "Prophetic abilities emerging",
            "is_master": False
        },
        "LILJA-ACCEPTING": {
            "character": "Lilja",
            "name": "Accepting Change",
            "description": "Accepting transformation with enthusiasm",
            "is_master": False
        }
    }

    for var_id, var_data in variants.items():
        if var_id not in fixed_plates:
            fixed_plates[var_id] = var_data

    # Sort by character and ID
    sorted_plates = dict(sorted(fixed_plates.items()))

    # Save as flat structure (no nesting)
    with open('/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json', 'w', encoding='utf-8') as f:
        json.dump(sorted_plates, f, ensure_ascii=False, indent=2)

    print(f"\nFixed {len(sorted_plates)} plates")
    print("Structure flattened and references fixed")

    # Count by character
    by_char = {}
    for plate_id in sorted_plates:
        char = plate_id.split('-')[0]
        by_char[char] = by_char.get(char, 0) + 1

    print("\nPlates by character:")
    for char, count in sorted(by_char.items()):
        print(f"  {char}: {count} plates")

if __name__ == "__main__":
    main()