#!/usr/bin/env python3
"""
Generate a summary report of all extracted character plates.
"""

import json
import re

def main():
    # Load plates
    with open('/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json', 'r', encoding='utf-8') as f:
        plates = json.load(f)

    print("CHARACTER PLATES EXTRACTION SUMMARY")
    print("=" * 50)
    print(f"Total plates extracted: {len(plates)}")
    print()

    # Count by character
    character_counts = {}
    master_plates = []

    for plate_id, plate_data in plates.items():
        char = plate_data["character"]
        character_counts[char] = character_counts.get(char, 0) + 1

        if plate_data.get("is_master", False):
            master_plates.append(plate_id)

    print("PLATES BY CHARACTER:")
    for char, count in sorted(character_counts.items()):
        print(f"  {char}: {count} plates")
    print()

    print(f"MASTER PLATES ({len(master_plates)}):")
    for master in sorted(master_plates):
        print(f"  {master}")
    print()

    # Check bracket references
    print("BRACKET REFERENCE ANALYSIS:")
    bracket_patterns = []
    for plate_id, plate_data in plates.items():
        desc = plate_data["description"]
        brackets = re.findall(r'\[[^\]]+\]', desc)
        for bracket in brackets:
            if bracket not in bracket_patterns:
                bracket_patterns.append(bracket)

    print(f"Found {len(bracket_patterns)} unique bracket patterns:")
    for pattern in sorted(bracket_patterns):
        print(f"  {pattern}")
    print()

    # Verify all bracket references point to valid plates
    print("BRACKET REFERENCE VALIDATION:")
    invalid_refs = []
    for plate_id, plate_data in plates.items():
        desc = plate_data["description"]
        brackets = re.findall(r'\[([^\]]+)\]', desc)
        for bracket_content in brackets:
            # Check if this references another plate
            if bracket_content in plates:
                continue
            elif bracket_content.endswith(" base"):
                base_plate = bracket_content.replace(" base", "")
                if base_plate not in plates:
                    invalid_refs.append(f"{plate_id}: [{bracket_content}] -> {base_plate} not found")
            elif bracket_content not in ["Variable base"]:  # Skip known special cases
                # Check if it's a reference that should exist
                if any(char.upper() in bracket_content for char in ["MAGNUS", "GUDRUN", "SIGRID", "LILJA", "JON"]):
                    invalid_refs.append(f"{plate_id}: [{bracket_content}] -> not found")

    if invalid_refs:
        print("Invalid bracket references found:")
        for ref in invalid_refs[:10]:  # Show first 10
            print(f"  {ref}")
        if len(invalid_refs) > 10:
            print(f"  ... and {len(invalid_refs) - 10} more")
    else:
        print("All bracket references appear valid!")
    print()

    # Sample plates
    print("SAMPLE PLATES:")
    for char in ["Magnus", "Gudrun", "Jon", "Lilja", "Sigrid"]:
        char_plates = [pid for pid, pdata in plates.items() if pdata["character"] == char]
        if char_plates:
            sample_id = char_plates[0]
            sample_data = plates[sample_id]
            desc_preview = sample_data["description"][:100] + "..." if len(sample_data["description"]) > 100 else sample_data["description"]
            print(f"  {sample_id}: {desc_preview}")
    print()

    print("EXTRACTION COMPLETED SUCCESSFULLY!")
    print("=" * 50)

if __name__ == "__main__":
    main()