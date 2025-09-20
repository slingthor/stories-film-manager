#!/usr/bin/env python3
"""Update SIGRID-MASTER to use 'young girl' instead of age reference"""

import json

def main():
    with open('character_plates_complete.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Update SIGRID-MASTER description
    if 'SIGRID-MASTER' in data['plate_index']:
        old_desc = data['plate_index']['SIGRID-MASTER']['description']

        # Replace age reference with "young girl"
        new_desc = old_desc.replace('16-year-old Westfjords girl', 'young Westfjords girl')

        data['plate_index']['SIGRID-MASTER']['description'] = new_desc

        print(f"Updated SIGRID-MASTER age reference:")
        print(f"  Changed: '16-year-old Westfjords girl' → 'young Westfjords girl'")

        # Create backup
        with open('character_plates_complete.json.backup_age_fix', 'w', encoding='utf-8') as f:
            with open('character_plates_complete.json', 'r') as orig:
                f.write(orig.read())

        # Write updated data
        with open('character_plates_complete.json', 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

        print("\nSuccessfully updated SIGRID-MASTER age reference")
        print("Backup saved as character_plates_complete.json.backup_age_fix")
    else:
        print("SIGRID-MASTER not found in plate_index")

if __name__ == '__main__':
    main()