#!/usr/bin/env python3
"""Update SIGRID-MASTER with the more detailed V2 description from character system"""

import json

# Full SIGRID-MASTER-V2 description from the character system
SIGRID_MASTER_V2 = """Sigrid Þorláksdóttir, 16-year-old Westfjords girl with heart-shaped face showing delicate bone structure, high prominent cheekbones creating natural shadow beneath, small straight nose with distinctive three-freckle triangle constellation on bridge (left freckle 2mm above right, center freckle 3mm higher), naturally full pink lips with visible cupid's bow definition, large grey eyes with amber flecks arranged like scattered gold-dust around pupils, thick blonde eyelashes, wheat-blonde hair plaited in two tight traditional braids reaching mid-back with small wisps escaping at temples, 5'4" lean athletic build with hidden wiry strength, always positioned with back against nearest wall or solid surface, wooden cross carved from driftwood visible in right dress pocket creating small rectangular bulge, breathing pattern 15 breaths per minute (maintaining human rhythm), clear soprano voice with perfect Icelandic pronunciation, defensive posture with arms crossed or hands protective over belly area."""

def main():
    with open('character_plates_complete.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Update SIGRID-MASTER with V2 description
    if 'SIGRID-MASTER' in data['plate_index']:
        old_desc = data['plate_index']['SIGRID-MASTER']['description']
        data['plate_index']['SIGRID-MASTER']['description'] = SIGRID_MASTER_V2

        print(f"Updated SIGRID-MASTER to V2:")
        print(f"  Old length: {len(old_desc)} chars")
        print(f"  New length: {len(SIGRID_MASTER_V2)} chars (more detailed)")

        # Show key improvements
        print("\nKey improvements in V2:")
        print("  - Added three-freckle triangle constellation detail")
        print("  - Added amber flecks in grey eyes detail")
        print("  - Changed hair from chestnut-brown to wheat-blonde")
        print("  - Height changed from 5'5\" to 5'4\"")
        print("  - Added defensive positioning behavior")

        # Create backup
        with open('character_plates_complete.json.backup_sigrid_v2', 'w', encoding='utf-8') as f:
            with open('character_plates_complete.json', 'r') as orig:
                f.write(orig.read())

        # Write updated data
        with open('character_plates_complete.json', 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

        print("\nSuccessfully updated SIGRID-MASTER to V2")
        print("Backup saved as character_plates_complete.json.backup_sigrid_v2")
    else:
        print("SIGRID-MASTER not found in plate_index")

if __name__ == '__main__':
    main()