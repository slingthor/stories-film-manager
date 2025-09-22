#!/usr/bin/env python3
"""Update all character MASTER plates with period-appropriate 1880s Icelandic clothing"""

import json
import re

# Define clothing updates for each character's MASTER plate
CLOTHING_UPDATES = {
    "MAGNUS-MASTER": {
        "old_pattern": r"(Magnus Thorlaksson, 55-year-old Westfjords fisherman with weathered rectangular face[^,]+, prominent angular Nordic cheekbones[^,]+, broken aquiline nose[^,]+, thin weather-cracked lips[^,]+, deep-set steel-blue hooded eyes[^,]+, thick charcoal-grey unkempt beard[^,]+, shoulder-length grey hair[^,]+, 5'10\" broad-shouldered stocky frame[^,]+, thick forearms[^,]+, weathered hands[^,]+)",
        "addition": ", wearing traditional 1880s Westfjords attire: brown undyed vaðmál (wadmal) wool sweater with coarse homespun texture, visible darning at left elbow using darker wool thread, high crew neck, fitted sleeves reaching wrists, dark charcoal vaðmál wool trousers with patch-repairs at both knees using mismatched brown fabric, thick grey wool stockings knitted by hand, sealskin boots (selskórnir) with rawhide lacing reaching mid-calf, wide leather belt with tarnished iron buckle from Danish trade, no modern lopapeysa patterns (those came later in 1900s)",
    },

    "GUDRUN-MASTER": {
        "old_pattern": r"(Guðrún Magnusdóttir, 35-year-old Westfjords woman with oval face showing premature aging from hardship[^,]+, hollow cheeks from chronic malnutrition[^,]+, grey-green almond eyes[^,]+, thin cracked lips[^,]+, straight nose[^,]+, dark brown hair[^,]+, 5'5\" skeletal frame[^,]+)",
        "addition": ", wearing traditional 1880s married woman's attire: white linen faldbúningur headdress (married woman's cap) with starched wings, black velvet band with small brass pin at front, dark grey vaðmál dress (upphlutur and pils) reaching ankles, fitted bodice laced at front with leather cords, long sleeves with tight cuffs, brown wool apron (svunta) tied at waist showing domestic role, black wool shawl (sjal) for warmth draped over shoulders, thick brown wool stockings, simple leather shoes with worn soles",
    },

    "SIGRID-MASTER": {
        "old_pattern": r"(Sigrid Þorláksdóttir, young Westfjords woman with heart-shaped face[^,]+, high prominent cheekbones[^,]+, small straight nose[^,]+, full natural pink lips[^,]+, large grey eyes[^,]+, waist-length wheat-blonde hair[^,]+, 5'4\" slender frame[^,]+)",
        "addition": ", wearing modest 1880s unmarried woman's clothing: natural undyed linen shift (undergarment) beneath outer clothes, dark brown vaðmál dress (simpler than married women's) with high neckline for modesty, long sleeves loose at shoulder tight at wrist, no apron (signifying unmarried status), simple leather belt with iron clasp, grey wool stockings darned at heels, worn leather shoes inherited from deceased mother, small wooden cross on leather cord at neck (Christian influence), hair in two long braids (unmarried style) with no headdress",
    },

    "JON-MASTER": {
        "old_pattern": r"(Jón Magnusson, 8-year-old Westfjords boy with round face[^,]+, small button nose[^,]+, chapped lips[^,]+, large hazel eyes[^,]+, sandy brown hair[^,]+, 4'2\" thin frame[^,]+)",
        "addition": ", wearing worn children's clothing typical of 1880s poverty: oversized brown vaðmál wool sweater inherited from older deceased brother, sleeves rolled up three times to free hands, visible patches at elbows in mismatched grey wool, dark brown wool trousers too long requiring cuffing, held up with rope belt, thick grey wool stockings with holes at toes showing pink skin, simple leather shoes too large stuffed with straw for fit, no undergarments (too poor), clothing shows multiple generation hand-downs with various repair patches",
    },

    "LILJA-MASTER": {
        "old_pattern": r"(Lilja Magnusdóttir, 5-year-old Westfjords girl with perfectly cherubic round face[^,]+, tiny upturned button nose[^,]+, rosebud mouth[^,]+, extraordinarily large cornflower-blue eyes[^,]+, tangled dark blonde hair[^,]+, 3'6\" small delicate frame[^,]+)",
        "addition": ", wearing child's dress showing extreme poverty: grey vaðmál wool dress (kjóll) made from mother's old garment, hem torn and dragging from active play, too large requiring constant hitching up, makeshift belt from braided wool scraps, dark brown wool stockings with large darned patches at knees, holes at toes exposing feet, simple leather shoes with soles worn through showing wrapped cloth padding, no undergarments, permanently clutching handmade cloth doll with dress matching hers, brass button eyes from father's old coat, yellow yarn hair unraveling",
    }
}

def update_master_plates():
    """Update all MASTER plates with detailed clothing descriptions"""

    # Load the current plates
    with open('character_plates_complete.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    updates_made = []

    for plate_id, updates in CLOTHING_UPDATES.items():
        if plate_id in data['plate_index']:
            current_desc = data['plate_index'][plate_id]['description']

            # Check if clothing is already detailed (avoid double-adding)
            if "vaðmál" in current_desc or "traditional 1880s" in current_desc:
                print(f"✓ {plate_id} already has detailed clothing")
                continue

            # Find where to insert the clothing description
            # Look for the end of physical description before other details
            if plate_id == "MAGNUS-MASTER":
                # Magnus has specific items mentioned after physical description
                insertion_point = current_desc.find(", always grips carved driftwood")
                if insertion_point > 0:
                    new_desc = (current_desc[:insertion_point] +
                               updates["addition"] +
                               current_desc[insertion_point:])
                else:
                    # Fallback: add before the breathing pattern
                    insertion_point = current_desc.find(", breathing pattern")
                    new_desc = (current_desc[:insertion_point] +
                               updates["addition"] +
                               current_desc[insertion_point:])

            elif plate_id == "GUDRUN-MASTER":
                # Gudrun - add after physical frame description
                insertion_point = current_desc.find(", weak voice")
                if insertion_point > 0:
                    new_desc = (current_desc[:insertion_point] +
                               updates["addition"] +
                               current_desc[insertion_point:])
                else:
                    # Fallback
                    new_desc = current_desc + updates["addition"]

            elif plate_id == "SIGRID-MASTER":
                # Sigrid - add after physical description
                insertion_point = current_desc.find(", quiet voice")
                if insertion_point > 0:
                    new_desc = (current_desc[:insertion_point] +
                               updates["addition"] +
                               current_desc[insertion_point:])
                else:
                    # Fallback
                    new_desc = current_desc + updates["addition"]

            elif plate_id in ["JON-MASTER", "LILJA-MASTER"]:
                # Children - these already have some clothing mentioned
                # We need to replace the basic clothing with detailed version
                if plate_id == "JON-MASTER":
                    # Jon has "oversized brown vaðmál wool sweater" mentioned
                    new_desc = re.sub(
                        r", oversized brown vaðmál wool sweater[^,]+, dark wool trousers[^,]+, thick wool stockings, simple leather shoes",
                        updates["addition"],
                        current_desc
                    )
                else:  # LILJA-MASTER
                    # Lilja has "grey vaðmál wool dress" mentioned
                    new_desc = re.sub(
                        r", grey vaðmál wool dress[^,]+, dark brown wool stockings[^,]+, simple leather shoes[^,]+, permanently clutching[^,]+",
                        updates["addition"],
                        current_desc
                    )

            # Update the description
            data['plate_index'][plate_id]['description'] = new_desc
            updates_made.append(plate_id)
            print(f"✅ Updated {plate_id} with detailed 1880s clothing")

    # Save backup
    with open('character_plates_complete.json.backup_clothing', 'w', encoding='utf-8') as f:
        with open('character_plates_complete.json', 'r') as orig:
            f.write(orig.read())

    # Save updated file
    with open('character_plates_complete.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"\n✅ Successfully updated {len(updates_made)} MASTER plates with period-appropriate clothing")
    print("📁 Backup saved as character_plates_complete.json.backup_clothing")

    # Show sample of updates
    if updates_made:
        print(f"\n📝 Sample updated description for {updates_made[0]}:")
        print(f"{data['plate_index'][updates_made[0]]['description'][:500]}...")

if __name__ == '__main__':
    update_master_plates()