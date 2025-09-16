#!/usr/bin/env python3
"""
Add missing master plates to the character plates file.
"""

import json

def main():
    # Load existing plates
    with open('/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json', 'r', encoding='utf-8') as f:
        plates = json.load(f)

    # Add missing master plates
    masters_to_add = {
        "MAGNUS-MASTER": {
            "character": "Magnus",
            "name": "Magnus Master",
            "description": "Magnús Þorláksson, 55-year-old Westfjords fisherman with weathered rectangular face, prominent angular Nordic cheekbones creating deep shadows, broken aquiline nose with visible leftward bend showing old injury, thin weather-cracked lips permanently chapped from salt air, deep-set steel-blue hooded eyes under heavy brow ridge with pronounced crow's feet extending to temples, thick charcoal-grey unkempt beard reaching mid-chest with individual coarse hairs visible, shoulder-length grey hair with natural wave pattern, greasy from whale oil and matted from weather exposure, 5'10\" broad-shouldered stocky frame with barrel chest, thick forearms with prominent veins, weathered hands showing fishing rope scars across palms, always grips carved driftwood walking cane (worn smooth at handle, iron tip for ice), tarnished silver wedding ring on left hand fourth finger, breathing pattern 12 breaths per minute baseline rhythm, gravelly bass voice with slight wheeze.",
            "is_master": True,
            "shot_range": ""
        },
        "GUDRUN-MASTER": {
            "character": "Gudrun",
            "name": "Gudrun Master",
            "description": "Guðrún Magnúsdóttir, 35-year-old Westfjords woman with oval face showing premature aging from hardship, hollow cheeks from chronic malnutrition creating sharp cheekbone definition, straight narrow nose with thin nostrils, pale thin lips permanently pressed together suggesting years of enforced silence, grey-green almond-shaped eyes with dark purple circles from exhaustion and hidden V-shaped notch scar behind left ear (livestock marking from marriage ceremony), dark brown hair completely hidden under traditional white curved faldbúningur headdress with black velvet band and brass pin positioned exactly 2cm above left temple, 5'5\" thin frame showing visible malnutrition with prominent collarbone and wrist bones, brass wedding ring loose on thin finger from weight loss, soft alto voice with slight fear tremor, breathing pattern 14 breaths per minute anxiety baseline, hands showing constant nervous wringing motion.",
            "is_master": True,
            "shot_range": ""
        },
        "JON-MASTER": {
            "character": "Jon",
            "name": "Jon Master",
            "description": "Jón Magnússon, 8-year-old Westfjords boy with round face perpetually flushed with fever creating red patches on pale cheeks, small button nose bright red from illness and cold, chapped lips with visible blood spots from persistent wet coughing, large hazel eyes with green-brown flecks glazed from 39°C fever creating thousand-yard temporal stare, sandy brown hair matted with fever sweat and unwashed for weeks, 4'2\" thin frame showing prominent rib outline beneath clothing from malnutrition, oversized brown vaðmál wool sweater hanging loose on shoulders (inherited from older brother), dark wool trousers with patches at knees, thick wool stockings, simple leather shoes, listless posture with fever weakness but occasional sudden energy bursts from illness, persistent wet cough producing blood-flecked sputum, trembling from fever creating constant body vibration, hoarse whisper voice from throat irritation, breathing 18 breaths per minute elevated child-fever rhythm.",
            "is_master": True,
            "shot_range": ""
        }
    }

    # Add missing masters
    for plate_id, plate_data in masters_to_add.items():
        if plate_id not in plates:
            plates[plate_id] = plate_data
            print(f"Added missing master: {plate_id}")

    # Save updated plates
    with open('/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json', 'w', encoding='utf-8') as f:
        json.dump(plates, f, indent=2, ensure_ascii=False)

    print(f"\nUpdated file with {len(plates)} total plates")

    # Print summary by character
    print("\nFinal summary by character:")
    character_counts = {}
    master_count = 0
    for plate_id, plate_data in plates.items():
        char = plate_data["character"]
        character_counts[char] = character_counts.get(char, 0) + 1
        if plate_data.get("is_master", False):
            master_count += 1

    for char, count in sorted(character_counts.items()):
        print(f"  {char}: {count} plates")

    print(f"\nTotal masters found: {master_count}")

if __name__ == "__main__":
    main()