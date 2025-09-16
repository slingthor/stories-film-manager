#!/usr/bin/env python3
"""
Fix remaining bracket reference issues in character plates.
"""

import json
import re

def fix_bracket_references_comprehensive(plates):
    """Fix all bracket references to use valid plate IDs."""

    # Create a mapping of "base" references to actual plate IDs
    plate_base_mapping = {}

    # First, identify all actual plate IDs for mapping
    for plate_id in plates.keys():
        if "-" in plate_id:
            char, plate_name = plate_id.split("-", 1)
            plate_base_mapping[f"{plate_name} base"] = plate_id
            plate_base_mapping[f"{char}-{plate_name} base"] = plate_id

    # Additional specific mappings
    specific_mappings = {
        "Previous aging base": "MAGNÚS-AGING",
        "Injured base": "MAGNÚS-WOUNDED",
        "Defeated base": "MAGNÚS-DEFEATED",
        "Predator base": "MAGNÚS-PREDATOR",
        "Authority base": "MAGNÚS-SUMMER",  # Use summer as authority base
        "Possessor base": "MAGNÚS-POSSESSOR",
        "Shifting base": "MAGNÚS-SHIFTING",
        "Recognition base": "MAGNÚS-RECOGNIZING",
        "Breaking base": "MAGNÚS-BREAKING",
        "Preparing base": "MAGNÚS-PREPARATION",
        "Variable base depending on scene": "LILJA-MASTER",
        "Abundant base": "GUÐRÚN-ABUNDANT",
        "Wearing base": "GUÐRÚN-WEARING",
        "Counting base": "GUÐRÚN-COUNTING",
        "Producing base": "GUÐRÚN-PRODUCING",
        "Beaten base": "GUÐRÚN-BEATEN",
        "Condemned base": "GUÐRÚN-CONDEMNED",
        "Walking base": "GUÐRÚN-WALKING",
        "Offering base": "GUÐRÚN-OFFERING",
        "Returning base": "GUÐRÚN-RETURNING",
        "Recognizing base": "GUÐRÚN-RECOGNIZING",
        "Divine base": "GUÐRÚN-DIVINE",
        "Crowned base": "GUÐRÚN-CROWNED",
        "Rising base": "JÓN-RISING",
        "Seeing base": "JÓN-SEEING",
        "Changing base": "JÓN-CHANGING",
        "Gapped base": "JÓN-GAPPED",
        "Emerging base": "JÓN-EMERGING",
        "Grinding base": "JÓN-GRINDING",
        "Energetic base": "JÓN-ENERGETIC",
        "Temporal base": "JÓN-TEMPORAL",
        "Wandering base": "JÓN-WANDERING",
        "Fitting base": "JÓN-FITTING",
        "Mastering base": "JÓN-MASTERING",
        "Sensing base": "LILJA-SENSING",
        "Harmonic base": "LILJA-HARMONIC",
        "Mapping base": "LILJA-MAPPING",
        "Prophesying base": "LILJA-PROPHESYING",
        "Producing base": "LILJA-PRODUCING",
        "Wondering base": "LILJA-WONDERING",
        "Awakening base": "SIGRID-AWAKENING",
        "Marked base": "SIGRID-MARKED",
        "Summoning base": "SIGRID-SUMMONING",
        "Oracle base": "SIGRID-ORACLE",
        "Cornered base": "SIGRID-CORNERED",
        "Chosen base": "SIGRID-CHOSEN",
        "Transitional base": "SIGRID-TRANSITIONAL",
        "Becoming base": "SIGRID-BECOMING",
        "Dual base": "SIGRID-DUAL"
    }

    # Combine mappings
    all_mappings = {**plate_base_mapping, **specific_mappings}

    # Fix descriptions
    for plate_id, plate_data in plates.items():
        description = plate_data["description"]

        # Fix bracket references
        for base_ref, target_plate in all_mappings.items():
            if target_plate in plates:  # Only fix if target exists
                description = description.replace(f"[{base_ref}]", f"[{target_plate}]")

        # Update the description
        plate_data["description"] = description

    return plates

def main():
    # Load plates
    with open('/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json', 'r', encoding='utf-8') as f:
        plates = json.load(f)

    print(f"Loaded {len(plates)} plates")
    print("Fixing bracket references...")

    # Fix bracket references
    plates = fix_bracket_references_comprehensive(plates)

    # Save updated plates
    with open('/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json', 'w', encoding='utf-8') as f:
        json.dump(plates, f, indent=2, ensure_ascii=False)

    print("Bracket references fixed and file updated!")

    # Validate again
    print("\nValidating bracket references...")
    invalid_refs = []
    for plate_id, plate_data in plates.items():
        desc = plate_data["description"]
        brackets = re.findall(r'\[([^\]]+)\]', desc)
        for bracket_content in brackets:
            if bracket_content.endswith(" base"):
                invalid_refs.append(f"{plate_id}: [{bracket_content}]")
            elif bracket_content not in plates and bracket_content not in ["Variable base depending on scene"]:
                # Check if it should reference a plate
                if any(char.upper() in bracket_content for char in ["MAGNUS", "GUDRUN", "SIGRID", "LILJA", "JON"]):
                    invalid_refs.append(f"{plate_id}: [{bracket_content}]")

    if invalid_refs:
        print(f"Still found {len(invalid_refs)} invalid references:")
        for ref in invalid_refs[:10]:
            print(f"  {ref}")
    else:
        print("All bracket references are now valid!")

if __name__ == "__main__":
    main()