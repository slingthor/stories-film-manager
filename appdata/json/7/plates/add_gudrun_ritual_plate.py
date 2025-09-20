#!/usr/bin/env python3
"""Add GUÐRÚN-RITUAL plate for the four corners landvættir ritual scene"""

import json

# GUÐRÚN-RITUAL plate definition based on the ritual context
GUDRUN_RITUAL = {
    "character": "Gudrun",
    "name": "Gudrun Ritual",
    "description": "[GUDRUN-PRODUCING] performing south corner wool offering - faldbúningur arranged with ceremonial dignity despite wear, grey dress sleeves rolled back exposing wool-producing wrists for ritual offering, brown apron removed to show full dress for ceremony, black shawl arranged as ritual mantle over shoulders, wool threads 35mm visible and actively producing for landvættir offering, thin frame held erect with ritual authority despite malnutrition, posture kneeling in south corner with offering arms extended, grey-green eyes focused on supernatural summoning with maternal desperation for family protection, breathing synchronized 14/min with family ritual rhythm, hands offering wool strands as divine tribute while continuing production, facial expression showing desperate hope mixed with supernatural concentration, brass ring catching lamplight as hands weave offering patterns.",
    "shot_range": "Shots 23-24",
    "is_master": False
}

def main():
    with open('character_plates_complete.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Add GUÐRÚN-RITUAL to plate_index
    if 'GUDRUN-RITUAL' not in data['plate_index']:
        data['plate_index']['GUDRUN-RITUAL'] = GUDRUN_RITUAL

        print("Added GUÐRÚN-RITUAL plate:")
        print(f"  Name: {GUDRUN_RITUAL['name']}")
        print(f"  Character: {GUDRUN_RITUAL['character']}")
        print(f"  Shot Range: {GUDRUN_RITUAL['shot_range']}")
        print(f"  Description length: {len(GUDRUN_RITUAL['description'])} chars")
        print("\nKey elements:")
        print("  - South corner position for ritual")
        print("  - Wool offering to landvættir")
        print("  - Synchronized family breathing at 14/min")
        print("  - Ceremonial arrangement despite poverty")
        print("  - Desperate maternal protection intent")

        # Create backup
        with open('character_plates_complete.json.backup_ritual', 'w', encoding='utf-8') as f:
            with open('character_plates_complete.json', 'r') as orig:
                f.write(orig.read())

        # Write updated data
        with open('character_plates_complete.json', 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

        print("\nSuccessfully added GUÐRÚN-RITUAL plate")
        print("Backup saved as character_plates_complete.json.backup_ritual")
    else:
        print("GUÐRÚN-RITUAL already exists in plate_index")

if __name__ == '__main__':
    main()