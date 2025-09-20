#!/usr/bin/env python3
"""
Fix remaining cross-character plate references in the main plate system.
"""

import json
import re

def main():
    filepath = 'character_plates_complete.json'

    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Define the fixes needed based on our analysis
    fixes = {
        'GUDRUN-COUNTING': {
            'old': '[MAGNUS-PREPARING]',
            'new': '[GUDRUN-MASTER]'
        },
        'LILJA-SENSING': {
            'old': '[SIGRID-PURE]',
            'new': '[LILJA-MASTER]'
        },
        'ZERO-HZ': {
            'old': '[MAGNUS-WOUNDED]',
            'new': ''  # Environmental plate shouldn't reference character
        },
        'TIME-SPLIT': {
            'old': '[MAGNUS-ROWING]',
            'new': ''  # Environmental plate shouldn't reference character
        }
    }

    # Apply fixes
    modified = False
    for plate_id, fix in fixes.items():
        if plate_id in data['plate_index']:
            old_desc = data['plate_index'][plate_id].get('description', '')
            if fix['old'] in old_desc:
                # For environmental plates, remove the reference entirely
                if fix['new'] == '':
                    new_desc = old_desc.replace(fix['old'] + ' ', '')
                    new_desc = new_desc.replace(fix['old'], '')
                else:
                    new_desc = old_desc.replace(fix['old'], fix['new'])

                data['plate_index'][plate_id]['description'] = new_desc
                modified = True
                print(f"Fixed {plate_id}:")
                print(f"  - Replaced '{fix['old']}' with '{fix['new'] if fix['new'] else '(removed)'}'")

    if modified:
        # Create backup
        with open(filepath + '.backup_cross_refs', 'w', encoding='utf-8') as f:
            with open(filepath, 'r') as orig:
                f.write(orig.read())

        # Write fixed data
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

        print(f"\nSuccessfully fixed {len([f for f in fixes if f in data['plate_index']])} plates")
        print(f"Backup saved as {filepath}.backup_cross_refs")
    else:
        print("No changes needed")

if __name__ == '__main__':
    main()