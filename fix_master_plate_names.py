#!/usr/bin/env python3
"""
Fix master plate names and references in the character plates file.
"""

import json
import re

def main():
    # Load the file
    filepath = '/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json'
    with open(filepath, 'r') as f:
        data = json.load(f)

    plates = data['plate_index']

    # First, rename the master plates (remove -V suffix)
    renames = {
        'MAGNUS-MASTER-V': 'MAGNUS-MASTER',
        'SIGRID-MASTER-V': 'SIGRID-MASTER',
        'GUDRUN-MASTER-V': 'GUDRUN-MASTER',
        'JON-MASTER-V': 'JON-MASTER',
        'LILJA-MASTER-V': 'LILJA-MASTER',
        'BAÐSTOFA-MASTER-V': 'BAÐSTOFA-MASTER'
    }

    # Create new plates dict with renamed keys
    new_plates = {}
    for old_id, plate_data in plates.items():
        new_id = renames.get(old_id, old_id)

        # Also fix the "2:" at the beginning of some descriptions
        if 'description' in plate_data:
            desc = plate_data['description']
            # Remove leading "2: " if it exists
            if desc.startswith('2: '):
                desc = desc[3:]
            plate_data['description'] = desc

        new_plates[new_id] = plate_data

    # Now fix all bracket references to use correct master names
    # The references in descriptions should already be correct ([MAGNUS-MASTER] etc)
    # but let's verify and fix any wrong ones

    reference_fixes = {
        '[Master base]': '[MAGNUS-MASTER]',
        '[MAGNÚS-MASTER]': '[MAGNUS-MASTER]',
        '[Defeated base]': '[MAGNUS-DEFEATED]',
        '[Predator base]': '[MAGNUS-PREDATOR]',
        '[Possessor base]': '[MAGNUS-POSSESSOR]',
        '[Shifting base]': '[MAGNUS-SHIFTING]',
        '[Breaking base]': '[MAGNUS-BREAKING]',
        '[Preparing base]': '[MAGNUS-PREPARING]',
        '[Previous aging base]': '[MAGNUS-AGING]',
        '[Injured base]': '[MAGNUS-WOUNDED]',
        '[Authority base]': '[MAGNUS-ENFORCER]',
        '[Recognition base]': '[MAGNUS-RECOGNIZING]'
    }

    for plate_id, plate_data in new_plates.items():
        if 'description' in plate_data:
            desc = plate_data['description']
            for bad_ref, good_ref in reference_fixes.items():
                desc = desc.replace(bad_ref, good_ref)
            plate_data['description'] = desc

    # Update data with fixed plates
    data['plate_index'] = new_plates
    data['_total_plates'] = len(new_plates)

    # Save the file
    with open(filepath, 'w') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"Fixed {len(renames)} master plate names")
    print(f"Total plates: {len(new_plates)}")

    # Verify all references are valid
    all_ids = set(new_plates.keys())
    invalid_refs = []
    for plate_id, plate_data in new_plates.items():
        desc = plate_data.get('description', '')
        refs = re.findall(r'\[([A-Z\-]+)\]', desc)
        for ref in refs:
            if ref not in all_ids:
                invalid_refs.append((plate_id, ref))

    if invalid_refs:
        print(f"\nWarning: Found {len(set(invalid_refs))} invalid references:")
        for plate_id, ref in set(invalid_refs):
            print(f"  {plate_id} references [{ref}]")
    else:
        print("All bracket references are now valid!")

if __name__ == "__main__":
    main()