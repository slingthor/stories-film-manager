#!/usr/bin/env python3
"""Enhance all character MASTER plates with detailed colors, sizes, and measurements for clothing"""

import json
import re

# Define enhanced clothing with specific colors, sizes, and measurements
ENHANCED_CLOTHING = {
    "MAGNUS-MASTER": """wearing traditional 1880s Westfjords working man's attire: thick dark brown vaðmál wool sweater (chest 44 inches) with coarse homespun texture showing 3-inch visible darning patch at left elbow using charcoal grey wool thread, high crew neck 2 inches tall, fitted sleeves 28 inches long reaching wrists with 1-inch cuffs, dark charcoal grey vaðmál wool trousers (waist 36 inches, inseam 30 inches) with 4x4 inch brown fabric patches at both knees, thick heather grey hand-knitted wool stockings reaching mid-calf, dark brown sealskin boots 12 inches tall with natural beige rawhide lacing in X-pattern, 2-inch wide worn brown leather belt with tarnished brass buckle showing verdigris patina""",

    "GUDRUN-MASTER": """wearing traditional 1880s Icelandic married woman's formal attire: crisp white linen faldbúningur headdress standing 6 inches tall with starched wing-pieces extending 4 inches on each side, 1-inch wide black velvet band circling forehead with small brass pin (1cm diameter) centered at front, ankle-length dark grey vaðmál dress (bust 34 inches, waist 28 inches) with upphlutur bodice and pils skirt, fitted bodice with brown leather lacing cords crossed in front, long sleeves 24 inches with 2-inch tight cuffs at wrists, chestnut brown wool apron 20x16 inches tied at waist showing domestic status, charcoal black wool shawl 48x24 inches draped over shoulders for warmth, thick coffee-brown hand-knitted wool stockings, worn black leather shoes (size 37 European) with 1-inch heels showing sole wear""",

    "SIGRID-MASTER": """wearing modest 1880s unmarried woman's everyday clothing: natural cream-colored linen shift undergarment visible at neckline, ankle-length dark chocolate brown vaðmál dress (bust 32 inches, waist 26 inches) simpler cut than married women's, high round neckline rising 2 inches up throat for modesty, long sleeves 22 inches loose at shoulders tapering to 1.5-inch tight cuffs at wrists, no apron (signifying unmarried status), simple dark brown leather belt 1.5 inches wide with plain iron clasp, heather grey wool stockings with visible darning at heels in darker grey thread, worn brown leather shoes (size 36 European) inherited from mother showing cracked leather at toes, small carved wooden cross 1 inch tall on brown leather cord hanging at collarbone, wheat-blonde hair in two long braids reaching waist (unmarried style) tied with brown wool ribbons, no headdress""",

    "JON-MASTER": """wearing poverty-worn children's hand-me-down clothing: oversized muddy brown vaðmál wool sweater (adult small size on child's frame) inherited from deceased older brother, sweater hanging to mid-thigh requiring bottom 6 inches rolled up, sleeves rolled up four times creating thick 3-inch cuffs to free small hands, visible grey wool patches 3x3 inches at both elbows with uneven stitching, dark coffee-brown wool trousers (adult size 28 waist on size 20 child) too long by 8 inches requiring triple cuffing at ankles, makeshift rope belt from twisted hemp 0.5 inches thick tied in square knot, thick grey wool stockings with 2-inch holes at both big toes showing pale pink skin, cracked brown leather shoes size 32 European (too large by 2 sizes) stuffed with dried straw at toes for fit, no undergarments due to poverty, all clothing showing 3-4 generations of repairs in various brown and grey wool patches""",

    "LILJA-MASTER": """wearing extreme poverty child's makeshift dress: oversized grey vaðmál wool dress (child size 8 on size 4 frame) crudely made from mother's old garment with visible uneven seams, dress length reaching ankles with torn hem dragging 3 inches on ground from active play, dress width requiring constant hitching up at shoulders which slip down arms, makeshift belt from braided grey and brown wool scraps 0.25 inches thick tied in bow, dark coffee-brown wool stockings with large 3x3 inch darned patches at both knees in mismatched grey wool, holes at all toes exposing small pink feet, simple brown leather shoes size 26 European with soles worn completely through showing wrapped beige cloth padding underneath, no undergarments, permanently clutching handmade cloth doll 8 inches tall wearing matching grey dress, doll with two brass buttons 0.5cm diameter for eyes from father's old naval coat, yellow wool yarn hair in six strands partially unraveled"""
}

def enhance_clothing_details():
    """Update all MASTER plates with enhanced clothing details including colors and sizes"""

    # Load current plates
    with open('character_plates_complete.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    updates_made = []

    for plate_id, new_clothing in ENHANCED_CLOTHING.items():
        if plate_id in data['plate_index']:
            current_desc = data['plate_index'][plate_id]['description']

            # Find and replace the clothing section
            # Pattern to match existing clothing description
            if "wearing" in current_desc:
                # Split at "wearing" and reconstruct with new clothing
                parts = current_desc.split("wearing", 1)
                if len(parts) == 2:
                    # Find where the clothing description ends (usually at the next major descriptor)
                    base_desc = parts[0]
                    remainder = parts[1]

                    # Find the end of clothing description
                    # Look for common endings like "always grips", "breathing pattern", "quiet voice", etc.
                    end_markers = [
                        ", always grips",
                        ", breathing pattern",
                        ", quiet voice",
                        ", gravelly bass",
                        ", weak voice",
                        ", listless posture",
                        ", timid defensive",
                        ", permanently clutching handmade"  # Keep doll description separate
                    ]

                    clothing_end = len(remainder)
                    ending_text = ""

                    for marker in end_markers:
                        if marker in remainder:
                            idx = remainder.find(marker)
                            if idx < clothing_end and idx != -1:
                                clothing_end = idx
                                ending_text = remainder[idx:]
                                break

                    # Special handling for Lilja's doll which is part of her description
                    if plate_id == "LILJA-MASTER" and "permanently clutching" in current_desc:
                        # The doll description is now part of the clothing
                        new_desc = base_desc + new_clothing
                        # Add back any remaining description after clothing
                        if ", timid defensive" in current_desc:
                            idx = current_desc.find(", timid defensive")
                            new_desc += current_desc[idx:]
                    else:
                        new_desc = base_desc + new_clothing + ending_text

                    data['plate_index'][plate_id]['description'] = new_desc
                    updates_made.append(plate_id)
                    print(f"✅ Enhanced {plate_id} with detailed colors and sizes")
            else:
                print(f"⚠️ {plate_id} doesn't have 'wearing' keyword - skipping")

    # Save backup
    with open('character_plates_complete.json.backup_colors', 'w', encoding='utf-8') as f:
        with open('character_plates_complete.json', 'r') as orig:
            f.write(orig.read())

    # Save updated file
    with open('character_plates_complete.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"\n✅ Successfully enhanced {len(updates_made)} MASTER plates with detailed colors and sizes")
    print("📁 Backup saved as character_plates_complete.json.backup_colors")

    # Verify updates
    if updates_made:
        print(f"\n📝 Verification - {updates_made[0]} now includes:")
        desc = data['plate_index'][updates_made[0]]['description']
        # Extract just the clothing part for display
        if "wearing" in desc:
            clothing_start = desc.index("wearing")
            clothing_section = desc[clothing_start:clothing_start+400]
            print(clothing_section + "...")

if __name__ == '__main__':
    enhance_clothing_details()