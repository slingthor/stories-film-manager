#!/usr/bin/env python3
"""
Fix incorrect MAGNUS-MASTER plate references according to the mapping.
"""

import json
import re
from pathlib import Path

def fix_plate_references():
    plates_file = Path("/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json")

    # Read the current file
    with open(plates_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Create mapping based on analysis
    fixes = {
        # Character plates that should reference their own masters
        "SIGRID-PURE": {"old": "[MAGNUS-MASTER]", "new": "[SIGRID-MASTER]"},
        "LILJA-PURE": {"old": "[MAGNUS-MASTER]", "new": "[LILJA-MASTER]"},
        "GUDRUN-ABUNDANT": {"old": "[MAGNUS-MASTER]", "new": "[GUDRUN-MASTER]"},
        "JON-MILD": {"old": "[MAGNUS-MASTER]", "new": "[JON-MASTER]"},
        "MILD": {"old": "[MAGNUS-MASTER]", "new": "[JON-MASTER]"},  # This appears to be a Jon plate

        # Environmental plates
        "SEA-DIVINE": {"old": "[MAGNUS-MASTER]", "new": "[SEA-MASTER]"},
        "HOUSE-TRADITIONAL": {"old": "[MAGNUS-MASTER]", "new": "[EXTERIOR-MASTER]"},
        "WESTFJORDS-SUMMER": {"old": "[MAGNUS-MASTER]", "new": "[WESTFJORDS-MASTER]"},
        "STOFA-DOMESTIC": {"old": "[MAGNUS-MASTER]", "new": "[BAÐSTOFA-MASTER]"},
        "BAÐSTOFA-DOMESTIC": {"old": "[MAGNUS-MASTER]", "new": "[BAÐSTOFA-MASTER]"},
        "WESTFJORDS-WINTER": {"old": "[MAGNUS-MASTER]", "new": "[WESTFJORDS-MASTER]"},
    }

    changes_made = 0

    # Apply fixes
    for plate_name, plate_data in data.get("plate_index", {}).items():
        if plate_name in fixes:
            description = plate_data.get("description", "")
            old_ref = fixes[plate_name]["old"]
            new_ref = fixes[plate_name]["new"]

            if old_ref in description:
                new_description = description.replace(old_ref, new_ref)
                plate_data["description"] = new_description
                changes_made += 1
                print(f"Fixed {plate_name}: {old_ref} -> {new_ref}")

    # Also fix any remaining MAGNUS-MASTER references in environmental or other character plates
    # by checking character field and applying appropriate fix
    for plate_name, plate_data in data.get("plate_index", {}).items():
        if plate_name not in fixes:  # Only check plates not already fixed
            description = plate_data.get("description", "")
            character = plate_data.get("character", "")

            if "[MAGNUS-MASTER]" in description:
                # Determine correct master based on character
                if character == "Sigrid":
                    new_description = description.replace("[MAGNUS-MASTER]", "[SIGRID-MASTER]")
                    plate_data["description"] = new_description
                    changes_made += 1
                    print(f"Fixed {plate_name} (Sigrid): [MAGNUS-MASTER] -> [SIGRID-MASTER]")
                elif character == "Lilja":
                    new_description = description.replace("[MAGNUS-MASTER]", "[LILJA-MASTER]")
                    plate_data["description"] = new_description
                    changes_made += 1
                    print(f"Fixed {plate_name} (Lilja): [MAGNUS-MASTER] -> [LILJA-MASTER]")
                elif character == "Gudrun":
                    new_description = description.replace("[MAGNUS-MASTER]", "[GUDRUN-MASTER]")
                    plate_data["description"] = new_description
                    changes_made += 1
                    print(f"Fixed {plate_name} (Gudrun): [MAGNUS-MASTER] -> [GUDRUN-MASTER]")
                elif character == "Jon":
                    new_description = description.replace("[MAGNUS-MASTER]", "[JON-MASTER]")
                    plate_data["description"] = new_description
                    changes_made += 1
                    print(f"Fixed {plate_name} (Jon): [MAGNUS-MASTER] -> [JON-MASTER]")
                elif character == "Environment":
                    # For environment plates, try to determine appropriate master
                    if "SEA" in plate_name.upper() or "WATER" in plate_name.upper():
                        new_description = description.replace("[MAGNUS-MASTER]", "[SEA-MASTER]")
                        plate_data["description"] = new_description
                        changes_made += 1
                        print(f"Fixed {plate_name} (Environment/Sea): [MAGNUS-MASTER] -> [SEA-MASTER]")
                    elif "HOUSE" in plate_name.upper() or "EXTERIOR" in plate_name.upper():
                        new_description = description.replace("[MAGNUS-MASTER]", "[EXTERIOR-MASTER]")
                        plate_data["description"] = new_description
                        changes_made += 1
                        print(f"Fixed {plate_name} (Environment/House): [MAGNUS-MASTER] -> [EXTERIOR-MASTER]")
                    elif "WESTFJORDS" in plate_name.upper():
                        new_description = description.replace("[MAGNUS-MASTER]", "[WESTFJORDS-MASTER]")
                        plate_data["description"] = new_description
                        changes_made += 1
                        print(f"Fixed {plate_name} (Environment/Westfjords): [MAGNUS-MASTER] -> [WESTFJORDS-MASTER]")
                    elif "BAÐSTOFA" in plate_name.upper() or "STOFA" in plate_name.upper():
                        new_description = description.replace("[MAGNUS-MASTER]", "[BAÐSTOFA-MASTER]")
                        plate_data["description"] = new_description
                        changes_made += 1
                        print(f"Fixed {plate_name} (Environment/Baðstofa): [MAGNUS-MASTER] -> [BAÐSTOFA-MASTER]")
                    else:
                        print(f"WARNING: Unhandled environment plate {plate_name} with [MAGNUS-MASTER] reference")
                else:
                    print(f"WARNING: Unhandled plate {plate_name} with [MAGNUS-MASTER] reference (character: {character})")

    # Create backup and save
    backup_file = plates_file.with_suffix('.json.backup')
    if not backup_file.exists():
        import shutil
        shutil.copy2(plates_file, backup_file)
        print(f"Created backup: {backup_file}")

    # Write the fixed data
    with open(plates_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"\nCompleted! Made {changes_made} fixes to plate references.")
    return changes_made

if __name__ == "__main__":
    fix_plate_references()