#!/usr/bin/env python3
"""Fix SIGRID-MASTER truncated description"""

import json

# Full SIGRID-MASTER description from the character system
FULL_SIGRID_MASTER = """Sigrid Þorláksdóttir, 16-year-old Westfjords girl with heart-shaped face showing delicate bone structure, high prominent cheekbones creating natural shadow beneath, small straight nose with distinctive narrow bridge, full naturally pink lips with defined cupid's bow, large expressive grey eyes with darker ring around iris and natural upward tilt at outer corners, thick dark eyebrows with natural arch, clear pale complexion with few freckles across nose bridge, long thick chestnut-brown hair usually in two tight braids reaching mid-back with smaller strands escaping around face, 5'5" slender build with beginning feminine curves, narrow shoulders and delicate wrists, long graceful fingers with short practical nails, traditional grey-brown vaðmál wool dress reaching ankles with fitted bodice and full skirt, white linen underdress visible at neckline and wrists, dark brown wool apron when working, black wool shawl for outdoors, worn leather shoes with metal buckles, small wooden cross necklace on leather cord (hidden under dress), breathing pattern 16 breaths per minute baseline, voice clear soprano with slight rural accent becoming stronger under stress."""

def main():
    with open('character_plates_complete.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Fix SIGRID-MASTER
    if 'SIGRID-MASTER' in data['plate_index']:
        old_desc = data['plate_index']['SIGRID-MASTER']['description']
        data['plate_index']['SIGRID-MASTER']['description'] = FULL_SIGRID_MASTER

        print(f"Fixed SIGRID-MASTER:")
        print(f"  Old length: {len(old_desc)} chars (truncated)")
        print(f"  New length: {len(FULL_SIGRID_MASTER)} chars (complete)")

        # Create backup
        with open('character_plates_complete.json.backup_sigrid_fix', 'w', encoding='utf-8') as f:
            with open('character_plates_complete.json', 'r') as orig:
                f.write(orig.read())

        # Write fixed data
        with open('character_plates_complete.json', 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

        print("\nSuccessfully fixed SIGRID-MASTER")
        print("Backup saved as character_plates_complete.json.backup_sigrid_fix")
    else:
        print("SIGRID-MASTER not found in plate_index")

if __name__ == '__main__':
    main()