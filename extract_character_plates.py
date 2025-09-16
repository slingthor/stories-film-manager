#!/usr/bin/env python3
"""
Character Plates Extraction and Bracket Reference Fixing Script

This script extracts ALL character plate descriptions from the enhancement files
and fixes their bracket references to use proper plate IDs.
"""

import json
import re
import os
from pathlib import Path

def extract_plates_from_file(file_path, character_name):
    """Extract all plates from a character enhancement file."""
    plates = {}

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Warning: File not found: {file_path}")
        return plates

    # Extract MASTER plate first
    master_pattern = rf'{character_name.upper()}-MASTER-V2:\s*(.*?)(?=\n\n|\nCLOTHING BASE:)'
    master_match = re.search(master_pattern, content, re.DOTALL)

    if master_match:
        master_desc = master_match.group(1).strip()
        plates[f"{character_name.upper()}-MASTER"] = {
            "character": character_name.title(),
            "name": f"{character_name.title()} Master",
            "description": master_desc,
            "is_master": True,
            "shot_range": ""
        }

    # Extract all character plate definitions (MAGNÚS-SUMMER, JÓN-MILD, etc.)
    # Match pattern: CHARACTER-NAME: [base reference] description
    char_plate_pattern = rf'({character_name.upper()}-[A-ZÁÉÍÓÚÝÞÆÐöäü-]+):\s*(.*?)(?=\n\n|\*\*Acting Direction:|\*\*PLATE|\*\*Scene|═|^{character_name.upper()}-|$)'
    char_plate_matches = re.finditer(char_plate_pattern, content, re.DOTALL | re.MULTILINE)

    for match in char_plate_matches:
        plate_id = match.group(1)
        description = match.group(2).strip()

        # Skip MASTER plate (already extracted)
        if "MASTER" in plate_id:
            continue

        # Extract name from plate_id
        name_part = plate_id.split('-', 1)[1] if '-' in plate_id else plate_id
        name = name_part.replace('-', ' ').title()

        plates[plate_id] = {
            "character": character_name.title(),
            "name": name,
            "description": description,
            "is_master": False,
            "shot_range": ""
        }

    # Extract numbered PLATE sections more broadly
    # Pattern: PLATE X: Name (Shot range)
    plate_section_pattern = r'PLATE\s+(\d+):\s*([^(]+?)(?:\(([^)]+)\))?\s*\n([A-ZÁÉÍÓÚÝÞÆÐöäü]+-[A-ZÁÉÍÓÚÝÞÆÐöäü-]+):\s*(.*?)(?=\n\n|\*\*Acting Direction|\*\*PLATE|\*\*Scene|═|$)'
    plate_section_matches = re.finditer(plate_section_pattern, content, re.DOTALL)

    for match in plate_section_matches:
        plate_num = match.group(1)
        plate_name = match.group(2).strip()
        shot_range = match.group(3) or ""
        plate_id = match.group(4)
        description = match.group(5).strip()

        plates[plate_id] = {
            "character": character_name.title(),
            "name": plate_name,
            "description": description,
            "is_master": False,
            "shot_range": f"(Shots {shot_range})" if shot_range else ""
        }

    # Extract special circumstance plates
    special_pattern = r'\*\*PLATE\s+(\d+):\s*([^(]+?)(?:\(([^)]+)\))?\s*:\*\*\s*\n([A-ZÁÉÍÓÚÝÞÆÐöäü]+-[A-ZÁÉÍÓÚÝÞÆÐöäü-]+):\s*(.*?)(?=\n\n|\*\*Acting Direction|\*\*PLATE|\*\*Scene|═|$)'
    special_matches = re.finditer(special_pattern, content, re.DOTALL)

    for match in special_matches:
        plate_num = match.group(1)
        plate_name = match.group(2).strip()
        shot_range = match.group(3) or ""
        plate_id = match.group(4)
        description = match.group(5).strip()

        plates[plate_id] = {
            "character": character_name.title(),
            "name": plate_name,
            "description": description,
            "is_master": False,
            "shot_range": f"(Shots {shot_range})" if shot_range else ""
        }

    # Additional pattern for plates without explicit numbers - look for sections starting with character name
    # Look for headings like "**PROLOGUE PERIOD" followed by plate definitions
    section_plates_pattern = rf'(\*\*[^*]+\*\*.*?\n.*?({character_name.upper()}-[A-ZÁÉÍÓÚÝÞÆÐöäü-]+):\s*(.*?)(?=\n\*\*|\n{character_name.upper()}-|\n\n\*\*|═|$))'
    section_matches = re.finditer(section_plates_pattern, content, re.DOTALL)

    for match in section_matches:
        plate_id = match.group(2)
        description = match.group(3).strip()

        # Skip if already extracted or is MASTER
        if plate_id in plates or "MASTER" in plate_id:
            continue

        # Extract name from plate_id
        name_part = plate_id.split('-', 1)[1] if '-' in plate_id else plate_id
        name = name_part.replace('-', ' ').title()

        plates[plate_id] = {
            "character": character_name.title(),
            "name": name,
            "description": description,
            "is_master": False,
            "shot_range": ""
        }

    return plates

def fix_bracket_references(description):
    """Fix bracket references to use correct plate IDs."""
    # Define the mapping for bracket references
    bracket_mappings = {
        # Master base references
        r'\[Master base\]': '[MAGNUS-MASTER]',
        r'\[Abundant base\]': '[GUDRUN-MASTER]',
        r'\[Pure base\]': '[SIGRID-MASTER]',
        r'\[Knowing base\]': '[LILJA-MASTER]',
        r'\[Mild base\]': '[JON-MASTER]',

        # Character-specific master references (keep correct ones)
        r'\[MAGNÚS-MASTER\]': '[MAGNUS-MASTER]',
        r'\[MAGNUS-MASTER\]': '[MAGNUS-MASTER]',
        r'\[GUÐRÚN-MASTER\]': '[GUDRUN-MASTER]',
        r'\[GUDRUN-MASTER\]': '[GUDRUN-MASTER]',
        r'\[SIGRID-MASTER\]': '[SIGRID-MASTER]',
        r'\[LILJA-MASTER\]': '[LILJA-MASTER]',
        r'\[JÓN-MASTER\]': '[JON-MASTER]',
        r'\[JON-MASTER\]': '[JON-MASTER]',

        # Generic "base" patterns - remove "base" from plate references
        r'\[([A-ZÁÉÍÓÚÝÞÆÐ]+-[A-ZÁÉÍÓÚÝÞÆÐ-]+) base\]': r'[\1]',

        # Specific plate base references that need character name fixing
        r'\[([A-Z]+)-([A-Z-]+) base\]': r'[\1-\2]',

        # Variable base reference
        r'\[Variable base\]': '[LILJA-MASTER]',  # Default to appropriate master
    }

    fixed_description = description
    for pattern, replacement in bracket_mappings.items():
        fixed_description = re.sub(pattern, replacement, fixed_description)

    return fixed_description

def main():
    """Main extraction function."""
    # Define file paths
    enhancement_files = {
        "Magnus": "/Users/ingthor/Documents/stories/enhancements/magnus_advanced_character_plates_system.txt",
        "Gudrun": "/Users/ingthor/Documents/stories/enhancements/gudrun_advanced_character_plates_system.txt",
        "Jon": "/Users/ingthor/Documents/stories/enhancements/jon_advanced_character_plates_system.txt",
        "Lilja": "/Users/ingthor/Documents/stories/enhancements/lilja_advanced_character_plates_system.txt",
        "Sigrid": "/Users/ingthor/Documents/stories/enhancements/sigrid_advanced_character_plates_system.txt"
    }

    all_plates = {}

    print("Extracting character plates from enhancement files...")

    for character, file_path in enhancement_files.items():
        print(f"\nProcessing {character}...")
        plates = extract_plates_from_file(file_path, character)

        # Fix bracket references in descriptions
        for plate_id, plate_data in plates.items():
            plate_data["description"] = fix_bracket_references(plate_data["description"])

        all_plates.update(plates)
        print(f"  Extracted {len(plates)} plates for {character}")

    # Save to JSON file
    output_file = "/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json"

    print(f"\nSaving {len(all_plates)} total plates to {output_file}...")

    # Create backup of existing file
    if os.path.exists(output_file):
        backup_file = output_file + ".backup"
        os.rename(output_file, backup_file)
        print(f"Created backup: {backup_file}")

    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(all_plates, f, indent=2, ensure_ascii=False)

    print(f"Successfully saved {len(all_plates)} character plates!")

    # Print summary by character
    print("\nSummary by character:")
    character_counts = {}
    for plate_id, plate_data in all_plates.items():
        char = plate_data["character"]
        character_counts[char] = character_counts.get(char, 0) + 1

    for char, count in sorted(character_counts.items()):
        print(f"  {char}: {count} plates")

    # Print master plates
    print("\nMaster plates found:")
    for plate_id, plate_data in all_plates.items():
        if plate_data.get("is_master", False):
            print(f"  {plate_id}: {plate_data['name']}")

    # Print some example fixed descriptions
    print("\nExample fixed bracket references:")
    for plate_id, plate_data in list(all_plates.items())[:3]:
        if "[" in plate_data["description"]:
            desc_preview = plate_data["description"][:100] + "..." if len(plate_data["description"]) > 100 else plate_data["description"]
            print(f"  {plate_id}: {desc_preview}")

if __name__ == "__main__":
    main()