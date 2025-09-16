#!/usr/bin/env python3
"""
Update shot files with correct plate mappings based on:
1. MASTER_CHARACTER_INTEGRATION guide for character plates
2. Environmental plate enhancement files for scene ranges
3. Actual character appearances in prompts
"""

import json
import re
import os
import glob
from typing import Dict, List, Set, Tuple

# Character plate mappings from the integration guide
CHARACTER_PLATE_MAPPINGS = {
    # PROLOGUE SHOTS
    "1b": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD", "lilja": "LILJA-PURE"},
    "2a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD", "lilja": "LILJA-PURE"},
    "3a": {"magnus": "MAGNUS-AUTHORITY", "jon": "JON-MILD"},
    "5p": {"magnus": "MAGNUS-WATCHING", "sigrid": "SIGRID-AWAKENING", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-RISING", "lilja": "LILJA-SENSING"},
    "6a": {"gudrun": "GUDRUN-ABUNDANT", "sigrid": "SIGRID-AWAKENING"},
    "9b": {"magnus": "MAGNUS-TRANSITION", "sigrid": "SIGRID-MARKED", "gudrun": "GUDRUN-WEARING", "jon": "JON-SEEING", "lilja": "LILJA-HARMONIC"},

    # MAIN STORY SHOTS
    "1": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET", "lilja": "LILJA-MATHEMATICAL"},
    "5": {"magnus": "MAGNUS-CONFUSED"},
    "8": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET", "lilja": "LILJA-MATHEMATICAL"},
    "9": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET", "lilja": "LILJA-MATHEMATICAL"},
    "10": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET", "lilja": "LILJA-MATHEMATICAL"},
    "11": {"gudrun": "GUDRUN-PRODUCING", "magnus": "MAGNUS-CONFUSED"},
    "16p": {"sigrid": "SIGRID-PROPHECY"},
    "18": {"magnus": "MAGNUS-PROVIDER"},
    "23": {"magnus": "MAGNUS-RITUAL", "gudrun": "GUDRUN-RITUAL", "sigrid": "SIGRID-SUMMONING"},
    "24": {"magnus": "MAGNUS-RITUAL", "gudrun": "GUDRUN-RITUAL", "sigrid": "SIGRID-SUMMONING", "lilja": "LILJA-HARMONIC", "jon": "JON-TEMPORAL"},
    "26": {"magnus": "MAGNUS-AFLOAT"},
    "27": {"magnus": "MAGNUS-AFLOAT"},
    "28": {"magnus": "MAGNUS-AFLOAT"},
    "29": {"magnus": "MAGNUS-AFLOAT"},
    "30": {"magnus": "MAGNUS-AGING"},
    "31": {"magnus": "MAGNUS-AGING"},
    "32": {"magnus": "MAGNUS-AGING"},
    "33": {"magnus": "MAGNUS-AGING"},
    "34": {"magnus": "MAGNUS-AGING"},
    "35a": {"magnus": "MAGNUS-WOUNDED"},
    "35b": {"magnus": "MAGNUS-WOUNDED"},
    "35c": {"magnus": "MAGNUS-WOUNDED"},
    "36": {"magnus": "MAGNUS-WOUNDED"},
    "37": {"sigrid": "SIGRID-ORACLE", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-CHANGING", "lilja": "LILJA-COMMUNICATING"},
    "38a": {"sigrid": "SIGRID-ORACLE", "gudrun": "GUDRUN-PRODUCING"},
    "38b": {"sigrid": "SIGRID-ORACLE", "gudrun": "GUDRUN-PRODUCING"},
    "39": {"sigrid": "SIGRID-ORACLE", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-GAPPED", "lilja": "LILJA-ACCEPTING"},
    "39p": {"jon": "JON-GAPPED", "lilja": "LILJA-ACCEPTING"},
    "40": {"gudrun": "GUDRUN-PRODUCING"},
    "41": {"magnus": "MAGNUS-PREDATOR", "gudrun": "GUDRUN-BEATEN", "sigrid": "SIGRID-CORNERED"},
    "42a": {"magnus": "MAGNUS-PREDATOR"},
    "42b": {"magnus": "MAGNUS-PREDATOR"},
    "42c": {"magnus": "MAGNUS-ZERO-HZ"},
    "43a": {"magnus": "MAGNUS-ENFORCER"},
    "43b": {"magnus": "MAGNUS-ENFORCER"},
    "43c": {"magnus": "MAGNUS-ENFORCER", "gudrun": "GUDRUN-BEATEN"},
    "44a": {"gudrun": "GUDRUN-WALKING"},
    "44b": {"gudrun": "GUDRUN-WALKING"},
    "44c": {"gudrun": "GUDRUN-WALKING"},
    "45a": {"gudrun": "GUDRUN-CROWNED"},
    "45b": {"gudrun": "GUDRUN-DIVINE"},
    "45c": {"gudrun": "GUDRUN-DIVINE"},
    "46a": {"gudrun": "GUDRUN-DIVINE"},
    "46b": {"gudrun": "GUDRUN-DIVINE"},
    "46c": {"gudrun": "GUDRUN-RETURNING"},
    "47a": {"gudrun": "GUDRUN-RETURNING", "magnus": "MAGNUS-DEFEATED"},
    "47b": {"magnus": "MAGNUS-DEFEATED"},
    "47c": {"magnus": "MAGNUS-DEFEATED"},
    "48": {"magnus": "MAGNUS-DEFEATED", "sigrid": "SIGRID-ORACLE"},
    "49a": {"magnus": "MAGNUS-POSSESSOR", "sigrid": "SIGRID-CORNERED"},
    "49b": {"magnus": "MAGNUS-POSSESSOR", "sigrid": "SIGRID-CORNERED"},
    "49c": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "jon": "JON-ENERGETIC"},
    "50a": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED"},
    "50b": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED"},
    "50c": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED"},
    "50d": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED"},
    "51a": {"jon": "JON-PROPHET", "lilja": "LILJA-SENSING"},
    "51b": {"gudrun": "GUDRUN-SPEAKING"},
    "51c": {"gudrun": "GUDRUN-SPEAKING"},
    "52a": {"sigrid": "SIGRID-TRANSITIONAL"},
    "52b": {"sigrid": "SIGRID-TRANSITIONAL"},
    "52c": {"magnus": "MAGNUS-SHIFTING", "sigrid": "SIGRID-CORNERED"},
    "53a": {"gudrun": "GUDRUN-SPEAKING"},
    "53b": {"gudrun": "GUDRUN-SPEAKING"},
    "53c": {"sigrid": "SIGRID-BECOMING"},
    "54a": {"magnus": "MAGNUS-SHIFTING", "sigrid": "SIGRID-BECOMING", "gudrun": "GUDRUN-SPEAKING"},
    "54b": {"magnus": "MAGNUS-SHIFTING", "sigrid": "SIGRID-BECOMING", "gudrun": "GUDRUN-SPEAKING"},
    "54c": {"magnus": "MAGNUS-SHIFTING", "sigrid": "SIGRID-BECOMING", "gudrun": "GUDRUN-SPEAKING"},
    "55a": {"magnus": "MAGNUS-RECOGNIZING"},
    "55b": {"magnus": "MAGNUS-RECOGNIZING"},
    "55c": {"magnus": "MAGNUS-BREAKING"},
    "55p": {},  # Witness mechanism shot - no specific characters
    "56": {"magnus": "MAGNUS-SHIFTING", "sigrid": "SIGRID-TRANSITIONAL", "gudrun": "GUDRUN-SPEAKING", "jon": "JON-CHANGING", "lilja": "LILJA-FINAL"},
    "56a": {"magnus": "MAGNUS-SHIFTING"},
    "56b": {"gudrun": "GUDRUN-EWE"},
    "56c": {"gudrun": "GUDRUN-EWE"},
    "57": {"magnus": "MAGNUS-BREAKING", "sigrid": "SIGRID-BECOMING", "gudrun": "GUDRUN-EWE", "jon": "JON-LAMB", "lilja": "LILJA-LAMB"},
    "57a": {"magnus": "MAGNUS-BREAKING", "sigrid": "SIGRID-BECOMING"},
    "57b": {"magnus": "MAGNUS-BREAKING", "sigrid": "SIGRID-BECOMING"},
    "57c": {"magnus": "MAGNUS-BREAKING", "sigrid": "SIGRID-BECOMING"},
    "58a": {"sigrid": "SIGRID-DUAL"},
    "58b": {"gudrun": "GUDRUN-EWE"},
    "58c": {"sigrid": "SIGRID-DUAL"},
    "59a": {"sigrid": "SIGRID-DUAL"},
    "59b": {"sigrid": "SIGRID-DUAL"},
    "59c": {"sigrid": "SIGRID-DUAL"},
    "60a": {"sigrid": "SIGRID-CORVID"},
    "60b": {"sigrid": "SIGRID-CORVID"},
    "60c": {"sigrid": "SIGRID-CORVID"},
    "61": {},  # Camera consciousness shot
    "61a": {},
    "61b": {},
    "61c": {},
    "62a": {"magnus": "MAGNUS-RAM", "sigrid": "SIGRID-CORVID", "gudrun": "GUDRUN-ETERNAL", "jon": "JON-LAMB", "lilja": "LILJA-LAMB"},
    "62b": {"magnus": "MAGNUS-RAM", "sigrid": "SIGRID-CORVID", "gudrun": "GUDRUN-ETERNAL", "jon": "JON-LAMB", "lilja": "LILJA-LAMB"},
    "63": {"magnus": "MAGNUS-RAM", "sigrid": "SIGRID-CORVID", "gudrun": "GUDRUN-ETERNAL", "jon": "JON-LAMB", "lilja": "LILJA-LAMB"},
}

# Environmental plate mappings based on shot ranges
ENVIRONMENTAL_PLATE_MAPPINGS = {
    # Baðstofa plates
    "BADSTOFA-DOMESTIC": list(range(1, 10)),  # Prologue shots 1-9
    "BADSTOFA-STIRRING": list(range(10, 16)),  # Prologue shots 10-15
    "BADSTOFA-ORGANIC": list(range(16, 24)),  # Prologue shots 16-23
    "BADSTOFA-BODY": list(range(1, 26)),  # Main shots 1-25
    "BADSTOFA-CLEFT": list(range(26, 46)),  # Main shots 26-45
    "BADSTOFA-CRYSTALLIZING": list(range(46, 61)),  # Main shots 46-60
    "BADSTOFA-CLIFF": list(range(61, 76)),  # Main shots 61-75
    "BADSTOFA-MONUMENT": list(range(76, 86)),  # Main shots 76-85

    # Special scene variations
    "BADSTOFA-SURVEILLANCE": ["5p"],  # Shot 5.5
    "BADSTOFA-PEACEFUL": ["16p"],  # Shot 16.5
    "BADSTOFA-DESPERATE": ["39p"],  # Shot 39.5
    "BADSTOFA-RECORDING": ["43b"],  # Shot 43B
    "BADSTOFA-FRAGMENTING": ["55p"],  # Shot 55.5

    # Sea plates - these would come from sea_environmental_plates file
    "SEA-PREDATORY": list(range(1, 24)),  # Prologue period
    "SEA-BATTLE": list(range(26, 37)),  # Magnus at sea shots
    "SEA-EMPTY": list(range(37, 47)),  # Empty ocean period
    "SEA-CONTAMINATED": list(range(45, 56)),  # Gríðungur emergence

    # Westfjords landscape plates - would come from westfjords file
    "LANDSCAPE-ABUNDANT": list(range(1, 24)),  # Prologue abundance
    "LANDSCAPE-HOSTILE": list(range(1, 30)),  # Main story winter start
    "LANDSCAPE-PREDATORY": list(range(30, 50)),  # Mid-story hostility
    "LANDSCAPE-FROZEN": list(range(50, 64)),  # Final freezing
}

def extract_shot_id(filename: str) -> str:
    """Extract shot ID from filename"""
    # Pattern: shot_XXX_type_NAME.json
    match = re.search(r'shot_([^_]+)(?:_(?:prologue|main))?', filename)
    if match:
        return match.group(1)
    return ""

def normalize_shot_id(shot_id: str) -> str:
    """Normalize shot ID for matching (remove letters if needed for main shots)"""
    # Keep full ID for matching
    return shot_id.lower()

def extract_characters_from_prompt(prompt_text: str) -> Set[str]:
    """Extract character names mentioned in prompt text"""
    characters = set()
    text_lower = prompt_text.lower()

    # Character name patterns to look for
    character_patterns = {
        "magnus": ["magnus", "magnús", "magnÃºs", "father", "patriarch"],
        "sigrid": ["sigrid", "sigrÃ­Ã°", "daughter"],
        "gudrun": ["gudrun", "guðrún", "guÃ°rÃºn", "mother", "wife"],
        "jon": ["jon", "jón", "jÃ³n", "son", "boy"],
        "lilja": ["lilja", "youngest", "girl"]
    }

    for character, patterns in character_patterns.items():
        for pattern in patterns:
            if pattern in text_lower:
                characters.add(character)
                break

    return characters

def get_environmental_plates_for_shot(shot_id: str, sequence_type: str) -> List[str]:
    """Get environmental plates that should be available for a shot"""
    plates = []

    # Parse shot number
    shot_num = None
    match = re.search(r'(\d+)', shot_id)
    if match:
        shot_num = int(match.group(1))

    # Check each environmental plate's range
    for plate_id, shot_range in ENVIRONMENTAL_PLATE_MAPPINGS.items():
        if isinstance(shot_range, list):
            # Check if it's a list of shot IDs (strings) or numbers
            if shot_range and isinstance(shot_range[0], str):
                if shot_id in shot_range:
                    plates.append(plate_id)
            elif shot_num is not None:
                # For prologue vs main, we need to consider sequence type
                if sequence_type == "prologue" and shot_num < 24:
                    if "BADSTOFA" in plate_id and shot_num in shot_range and shot_num < 24:
                        plates.append(plate_id)
                    elif "SEA" in plate_id and shot_num in shot_range and shot_num < 24:
                        plates.append(plate_id)
                    elif "LANDSCAPE" in plate_id and shot_num in shot_range and shot_num < 24:
                        plates.append(plate_id)
                elif sequence_type in ["main", "main_story"] and shot_num >= 1:
                    if "BADSTOFA" in plate_id and shot_num in shot_range:
                        plates.append(plate_id)
                    elif "SEA" in plate_id and shot_num in shot_range:
                        plates.append(plate_id)
                    elif "LANDSCAPE" in plate_id and shot_num in shot_range:
                        plates.append(plate_id)

    return plates

def update_shot_file(filepath: str):
    """Update a single shot file with correct plate mappings"""
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    filename = os.path.basename(filepath)
    shot_id = extract_shot_id(filename)
    normalized_id = normalize_shot_id(shot_id)

    # Determine sequence type
    sequence_type = "main_story"
    if "prologue" in filename.lower():
        sequence_type = "prologue"
    elif data.get("metadata", {}).get("sequence_type"):
        sequence_type = data["metadata"]["sequence_type"]
    elif data.get("prompt_variants") and data["prompt_variants"]:
        # Check first variant for sequence type hints
        first_variant = data["prompt_variants"][0]
        if "prologue" in str(first_variant).lower():
            sequence_type = "prologue"

    print(f"\nProcessing: {filename}")
    print(f"  Shot ID: {shot_id}, Sequence: {sequence_type}")

    changes_made = False

    # Process each prompt variant
    for variant in data.get("prompt_variants", []):
        # Get all prompt text to analyze
        prompt_text = ""
        for field in ["subject", "action", "scene", "dialogue", "style"]:
            if field in variant and variant[field]:
                prompt_text += " " + str(variant[field])

        # Extract characters from prompt
        mentioned_characters = extract_characters_from_prompt(prompt_text)

        # Get mapped characters for this shot
        mapped_characters = CHARACTER_PLATE_MAPPINGS.get(normalized_id, {})

        # Combine mentioned and mapped characters
        all_characters = set(mapped_characters.keys()) | mentioned_characters

        # Build character plates structure
        character_plates = {}
        for character in all_characters:
            if character in mapped_characters:
                plate_id = mapped_characters[character]
                character_plates[character] = plate_id
                print(f"    Mapped {character} -> {plate_id}")
            elif character in mentioned_characters:
                # Use master plate as fallback for mentioned but unmapped characters
                master_plate = f"{character.upper()}-MASTER"
                character_plates[character] = master_plate
                print(f"    Added {character} -> {master_plate} (mentioned in prompt)")

        # Get environmental plates
        env_plates = get_environmental_plates_for_shot(shot_id, sequence_type)

        # Update the variant with new plate structure
        if not "selected_plates" in variant:
            variant["selected_plates"] = {}

        # Store as dictionary for proper character->plate mapping
        variant["selected_plates"]["characters"] = character_plates
        variant["selected_plates"]["environment"] = env_plates

        # Also add available_plates for UI dropdown support
        variant["available_character_plates"] = character_plates
        variant["available_environmental_plates"] = env_plates

        changes_made = True

    # Save the updated file
    if changes_made:
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print(f"  ✅ Updated with {len(character_plates)} characters, {len(env_plates)} environment plates")

    return changes_made

def main():
    """Update all shot files with correct plate mappings"""
    shot_dir = "/Users/ingthor/Documents/stories/appdata/json/7/shots/json"

    print("=" * 60)
    print("UPDATING SHOT PLATE MAPPINGS")
    print("=" * 60)

    # Get all shot files
    shot_files = glob.glob(os.path.join(shot_dir, "shot_*.json"))
    print(f"Found {len(shot_files)} shot files to process")

    updated_count = 0
    for filepath in sorted(shot_files):
        if update_shot_file(filepath):
            updated_count += 1

    print("\n" + "=" * 60)
    print(f"COMPLETE: Updated {updated_count} shot files")
    print("=" * 60)

if __name__ == "__main__":
    main()