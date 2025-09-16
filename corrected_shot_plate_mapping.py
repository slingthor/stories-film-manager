#!/usr/bin/env python3
"""
Corrected comprehensive shot-plate mapping script using actual environmental plate names
"""
import json
import os
import glob
import re

# Character progression mappings from integration guide
CHARACTER_PLATE_MAPPINGS = {
    # PROLOGUE - Pure/abundant states
    "0a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE"},
    "0b": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE"},
    "1-": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE"},
    "1a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT"},
    "1b": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "1c": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE"},
    "2a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "2b": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "3a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "jon": "JON-MILD"},
    "3b": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "4a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "4b": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "5a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "5b": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "5p": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "6a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "6b": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "7a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "7b": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "8a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "8b": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "8c": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "9a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "20": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "21": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "22": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},

    # MAIN STORY - Transformation progression
    "1": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "2": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "3": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "4": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "5": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "6": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "7": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},
    "8": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},
    "9": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},
    "10": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},
    "11": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},
    "12": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},
    "13": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},
    "14": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},
    "15": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},
    "16": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},
    "16p": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},
    "17": {"magnus": "MAGNUS-PREDATOR", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-ACCEPTING", "gudrun": "GUDRUN-BEATEN", "jon": "JON-TEMPORAL"},
    "18": {"magnus": "MAGNUS-PREDATOR", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-ACCEPTING", "gudrun": "GUDRUN-BEATEN", "jon": "JON-TEMPORAL"},
    "19": {"magnus": "MAGNUS-PREDATOR", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-ACCEPTING", "gudrun": "GUDRUN-BEATEN", "jon": "JON-TEMPORAL"},

    # Mid-story escalation
    "22b": {"magnus": "MAGNUS-PREDATOR", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-ACCEPTING", "gudrun": "GUDRUN-BEATEN", "jon": "JON-TEMPORAL"},
    "23": {"magnus": "MAGNUS-PREDATOR", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-ACCEPTING", "gudrun": "GUDRUN-BEATEN", "jon": "JON-TEMPORAL"},
    "23a": {"magnus": "MAGNUS-PREDATOR", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-ACCEPTING", "gudrun": "GUDRUN-BEATEN", "jon": "JON-TEMPORAL"},
    "23b": {"magnus": "MAGNUS-PREDATOR", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-ACCEPTING", "gudrun": "GUDRUN-BEATEN", "jon": "JON-TEMPORAL"},
    "23c": {"magnus": "MAGNUS-PREDATOR", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-ACCEPTING", "gudrun": "GUDRUN-BEATEN", "jon": "JON-TEMPORAL"},
    "23p": {"magnus": "MAGNUS-PREDATOR", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-ACCEPTING", "gudrun": "GUDRUN-BEATEN", "jon": "JON-TEMPORAL"},

    # Transformation deepens
    "39p": {"lilja": "LILJA-ACCEPTING", "jon": "JON-GAPPED"},  # Children's hunger - specific scene
    "43b": {"magnus": "MAGNUS-ENFORCER", "gudrun": "GUDRUN-BEATEN"},  # Shadow violence
    "45c": {"gudrun": "GUDRUN-DIVINE", "sigrid": "SIGRID-MASTER"},  # Griðungur emerges

    # Final transformation - characters become mythological
    "55p": {"magnus": "MAGNUS-RAM", "sigrid": "SIGRID-CORVID", "lilja": "LILJA-MASTER", "gudrun": "GUDRUN-ETERNAL", "jon": "JON-LAMB"},
    "61": {"jon": "JON-LAMB", "gudrun": "GUDRUN-ETERNAL"},  # Camera recognizes itself
}

# Environmental plates using actual names from app
ENVIRONMENTAL_PLATE_MAPPINGS = {
    # PROLOGUE - Pure/traditional environment
    "0a": ["SEA-DIVINE", "WESTFJORDS-FJORD"],
    "0b": ["SEA-DIVINE", "WESTFJORDS-FJORD"],
    "1-": ["SEA-DIVINE", "WESTFJORDS-FJORD"],
    "1a": ["SEA-DIVINE", "WESTFJORDS-BEACH"],
    "1b": ["SEA-DIVINE", "WESTFJORDS-BEACH"],
    "1c": ["SEA-ABUNDANT", "WESTFJORDS-BEACH"],
    "2a": ["SEA-DIVINE", "WESTFJORDS-BEACH"],
    "2b": ["SEA-DIVINE", "WESTFJORDS-CLIFF"],
    "3a": ["BAÐSTOFA-DOMESTIC", "WESTFJORDS-BEACH"],
    "3b": ["SEA-DIVINE", "WESTFJORDS-CLIFF"],
    "4a": ["WESTFJORDS-CLIFF", "WESTFJORDS-SUMMER"],
    "4b": ["BAÐSTOFA-DOMESTIC", "WESTFJORDS-BEACH"],
    "5a": ["SEA-DIVINE", "WESTFJORDS-BEACH"],
    "5b": ["SEA-DIVINE", "WESTFJORDS-BEACH"],
    "5p": ["STOFA-SURVEILLANCE", "WESTFJORDS-BEACH"],
    "6a": ["BAÐSTOFA-DOMESTIC", "WESTFJORDS-BEACH"],
    "6b": ["WESTFJORDS-CLIFF", "WESTFJORDS-SUMMER"],
    "7a": ["BAÐSTOFA-DOMESTIC", "WESTFJORDS-BEACH"],
    "7b": ["BAÐSTOFA-DOMESTIC"],
    "8a": ["BAÐSTOFA-DOMESTIC"],
    "8b": ["BAÐSTOFA-DOMESTIC"],
    "8c": ["BAÐSTOFA-DOMESTIC"],
    "9a": ["BAÐSTOFA-DOMESTIC"],
    "20": ["WESTFJORDS-WINTER", "HOUSE-TRADITIONAL"],
    "21": ["WESTFJORDS-WINTER", "HOUSE-TRADITIONAL"],
    "22": ["WESTFJORDS-WINTER", "HOUSE-TRADITIONAL"],

    # MAIN STORY - House transformation progression
    "1": ["STOFA-BODY", "WESTFJORDS-WINTER"],
    "2": ["STOFA-BODY", "WESTFJORDS-WINTER"],
    "3": ["STOFA-BODY"],
    "4": ["STOFA-BODY", "WESTFJORDS-WINTER"],
    "5": ["STOFA-BODY", "WESTFJORDS-WINTER"],
    "6": ["STOFA-BODY"],
    "7": ["STOFA-BODY", "WESTFJORDS-WINTER"],
    "8": ["STOFA-BODY"],
    "9": ["STOFA-BODY"],
    "10": ["STOFA-BODY"],
    "11": ["STOFA-BODY"],
    "12": ["STOFA-BODY"],
    "13": ["STOFA-BODY", "WESTFJORDS-WINTER"],
    "14": ["STOFA-BODY"],
    "15": ["STOFA-BODY"],
    "16": ["STOFA-BODY"],
    "16p": ["STOFA-PEACEFUL"],  # Special peaceful moment
    "17": ["STOFA-BODY"],
    "18": ["STOFA-BODY", "WESTFJORDS-WINTER"],
    "19": ["STOFA-BODY"],
    "22b": ["STOFA-BODY"],
    "23": ["STOFA-BODY", "WESTFJORDS-WINTER"],
    "23a": ["STOFA-BODY"],
    "23b": ["STOFA-BODY"],
    "23c": ["STOFA-BODY", "WESTFJORDS-WINTER"],
    "23p": ["SEA-EXTRACTED", "WESTFJORDS-FJORD"],

    # Mid-story - Sea journeys and transformations
    "24": ["STOFA-BODY", "WESTFJORDS-WINTER"],
    "24a": ["STOFA-BODY"],
    "24b": ["WESTFJORDS-WINTER", "SEA-BATTLE"],
    "24c": ["WESTFJORDS-WINTER", "SEA-BATTLE"],
    "24d": ["WESTFJORDS-WINTER"],
    "25": ["STOFA-BODY"],
    "26": ["SEA-EXTRACTED", "WESTFJORDS-FJORD"],
    "27": ["SEA-EXTRACTED", "WESTFJORDS-FJORD"],
    "28": ["SEA-EXTRACTED", "WESTFJORDS-FJORD"],
    "29": ["SEA-EXTRACTED", "WESTFJORDS-FJORD"],
    "30": ["SEA-EXTRACTED", "WESTFJORDS-FJORD"],
    "31": ["SEA-EXTRACTED", "STOFA-CLEFT"],
    "32": ["SEA-BATTLE", "WESTFJORDS-FJORD"],
    "33": ["SEA-BATTLE", "WESTFJORDS-FJORD"],
    "34": ["SEA-BATTLE", "WESTFJORDS-FJORD"],
    "35a": ["SEA-BATTLE", "WESTFJORDS-FJORD"],
    "35b": ["SEA-BATTLE", "WESTFJORDS-FJORD"],
    "35c": ["SEA-BATTLE", "WESTFJORDS-FJORD"],
    "36": ["SEA-BATTLE", "WESTFJORDS-FJORD"],
    "37": ["SEA-BATTLE", "WESTFJORDS-FJORD"],
    "38a": ["SEA-BATTLE", "STOFA-BODY"],
    "38b": ["SEA-BATTLE", "WESTFJORDS-FJORD"],
    "39": ["STOFA-BODY", "WESTFJORDS-WINTER"],
    "39p": ["STOFA-DESPERATE"],  # Children's hunger

    # Escalation to climax
    "40": ["STOFA-BODY", "WESTFJORDS-CLIFF"],
    "41": ["STOFA-BODY", "WESTFJORDS-CLIFF"],
    "42a": ["STOFA-BODY"],
    "42b": ["STOFA-BODY"],
    "42c": ["STOFA-BODY"],
    "43a": ["STOFA-BODY"],
    "43b": ["STOFA-RECORDING"],  # Shadow violence - house recording
    "43c": ["STOFA-BODY"],
    "44a": ["WESTFJORDS-CLIFF"],
    "44b": ["WESTFJORDS-CLIFF"],
    "44c": ["WESTFJORDS-CLIFF"],
    "45a": ["SEA-BATTLE"],
    "45b": ["SEA-BATTLE"],
    "45c": ["SEA-CONTAMINATED", "WESTFJORDS-FJORD"],  # Griðungur emerges
    "46a": ["SEA-CONTAMINATED", "WESTFJORDS-FJORD"],
    "46b": ["SEA-CONTAMINATED", "WESTFJORDS-FJORD"],
    "46c": ["SEA-CONTAMINATED", "WESTFJORDS-FJORD"],
    "47a": ["SEA-CONTAMINATED"],
    "47b": ["WESTFJORDS-CLIFF"],
    "47c": ["STOFA-BODY"],
    "48": ["STOFA-BODY"],
    "49a": ["STOFA-BODY", "WESTFJORDS-CLIFF"],
    "49b": ["STOFA-BODY"],
    "49c": ["STOFA-BODY"],

    # Final transformation - House becomes monument
    "50a": ["STOFA-CRYSTALLIZING"],
    "50b": ["STOFA-CRYSTALLIZING"],
    "50c": ["STOFA-CRYSTALLIZING"],
    "50d": ["STOFA-CRYSTALLIZING", "WESTFJORDS-CLIFF"],
    "51a": ["STOFA-CRYSTALLIZING", "WESTFJORDS-CLIFF"],
    "51b": ["STOFA-CRYSTALLIZING", "WESTFJORDS-CLIFF"],
    "51c": ["STOFA-CLEFT"],
    "52a": ["STOFA-CRYSTALLIZING"],
    "52b": ["STOFA-CRYSTALLIZING"],
    "52c": ["STOFA-CRYSTALLIZING", "WESTFJORDS-CLIFF"],
    "53a": ["STOFA-CRYSTALLIZING"],
    "53b": ["STOFA-CRYSTALLIZING"],
    "53c": ["STOFA-CRYSTALLIZING"],
    "54a": ["STOFA-CRYSTALLIZING"],
    "54b": ["STOFA-CRYSTALLIZING", "WESTFJORDS-CLIFF"],
    "54c": ["STOFA-CRYSTALLIZING"],
    "55a": ["SEA-ETERNAL", "WESTFJORDS-CLIFF"],
    "55b": ["SEA-ETERNAL", "WESTFJORDS-CLIFF"],
    "55c": ["SEA-ETERNAL", "WESTFJORDS-CLIFF"],
    "55p": ["STOFA-MONUMENT"],  # Becoming monument
    "56": ["STOFA-MONUMENT"],
    "56a": ["STOFA-MONUMENT"],
    "56b": ["STOFA-MONUMENT"],
    "56c": ["STOFA-MONUMENT", "WESTFJORDS-CLIFF"],
    "57": ["STOFA-MONUMENT"],
    "57a": ["STOFA-MONUMENT"],
    "57b": ["STOFA-MONUMENT", "WESTFJORDS-CLIFF"],
    "57c": ["STOFA-MONUMENT"],
    "58a": ["WESTFJORDS-CLIFF"],
    "58b": ["STOFA-MONUMENT", "WESTFJORDS-CLIFF"],
    "58c": ["STOFA-MONUMENT", "WESTFJORDS-CLIFF"],
    "59a": ["STOFA-CLIFF"],
    "59b": ["STOFA-CLIFF"],
    "59c": ["STOFA-CLIFF", "WESTFJORDS-CLIFF"],
    "60a": ["STOFA-CLIFF", "WESTFJORDS-CLIFF"],
    "60b": ["STOFA-CLIFF", "WESTFJORDS-CLIFF"],
    "60c": ["STOFA-MONUMENT"],
    "61": ["BAÐSTOFA-MONUMENT"],  # Final monument state
    "61a": ["WESTFJORDS-CLIFF"],
    "61b": ["WESTFJORDS-CLIFF"],
    "61c": ["WESTFJORDS-CLIFF"],
    "62a": ["WESTFJORDS-CLIFF"],
    "62b": ["WESTFJORDS-CLIFF"],
    "63": ["WESTFJORDS-CLIFF"],  # Final transcendence
}

def extract_characters_from_prompt(prompt_text):
    """Extract character names mentioned in brackets from prompt text"""
    if not prompt_text:
        return set()

    characters = set()
    bracket_matches = re.findall(r'\[([A-ZÁÐÞÆÍÓÚÝÖ\s]+)\]', prompt_text.upper())

    for match in bracket_matches:
        cleaned = match.strip()
        if cleaned in ['MAGNÚS', 'MAGNUS']:
            characters.add('magnus')
        elif cleaned == 'SIGRID':
            characters.add('sigrid')
        elif cleaned == 'LILJA':
            characters.add('lilja')
        elif cleaned in ['GUÐRÚN', 'GUDRUN']:
            characters.add('gudrun')
        elif cleaned == 'JÓN' or cleaned == 'JON':
            characters.add('jon')

    return characters

def normalize_shot_id(shot_id):
    """Normalize shot ID for mapping lookup"""
    return shot_id.replace('.', 'p').replace('-', '')

def update_shot_file(filepath):
    """Update a single shot file with corrected plate mappings"""
    print(f"\n📁 Processing: {os.path.basename(filepath)}")

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"  ❌ Error reading file: {e}")
        return False

    shot_metadata = data.get('shot_metadata', {})
    shot_id = shot_metadata.get('id', '')
    sequence_type = shot_metadata.get('sequence_type', 'main_story')

    normalized_id = normalize_shot_id(shot_id)
    print(f"  🎬 Shot ID: {shot_id} (normalized: {normalized_id})")
    print(f"  📋 Sequence: {sequence_type}")

    changes_made = False

    # Update each prompt variant
    for i, variant in enumerate(data.get('prompt_variants', [])):
        print(f"    📝 Variant {i+1}: {variant.get('variant_name', 'Unnamed')}")

        # Extract characters mentioned in this variant's prompt
        subject = variant.get('subject', '')
        action = variant.get('action', '')
        scene = variant.get('scene', '')
        prompt_text = f"{subject} {action} {scene}"
        mentioned_characters = extract_characters_from_prompt(prompt_text)

        if mentioned_characters:
            print(f"      👥 Characters in prompt: {', '.join(mentioned_characters)}")

        # Get mapped characters from the integration guide
        mapped_characters = CHARACTER_PLATE_MAPPINGS.get(normalized_id, {})

        # Combine mentioned and mapped characters for this variant
        all_characters = set(mapped_characters.keys()) | mentioned_characters

        # Build character plates for this variant
        character_plates = {}
        for character in all_characters:
            if character in mapped_characters:
                plate_id = mapped_characters[character]
                character_plates[character] = plate_id
                print(f"      Character: {character} -> {plate_id}")
            elif character in mentioned_characters:
                # Use master plate as fallback for characters mentioned in prompt
                master_plate = f"{character.upper()}-MASTER"
                character_plates[character] = master_plate
                print(f"      Character: {character} -> {master_plate} (from prompt)")

        # Get environmental plates
        env_plates = ENVIRONMENTAL_PLATE_MAPPINGS.get(normalized_id, [])
        if not env_plates:
            # Default environmental plates based on sequence
            if sequence_type == "prologue":
                env_plates = ["BAÐSTOFA-DOMESTIC", "WESTFJORDS-SUMMER", "SEA-DIVINE"]
            else:
                env_plates = ["STOFA-BODY", "WESTFJORDS-WINTER", "SEA-EXTRACTED"]

        print(f"      Environment: {', '.join(env_plates)}")

        # Create the flat array format the app expects
        all_plates = []

        # Add character plates
        for char, plate in character_plates.items():
            all_plates.append(plate)

        # Add environmental plates
        all_plates.extend(env_plates)

        # Update variant with all three required structures
        variant["selected_plates"] = all_plates
        variant["available_character_plates"] = character_plates
        variant["available_environmental_plates"] = env_plates

        changes_made = True

    # Save updated file
    if changes_made:
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print(f"  ✅ Updated successfully")

    return changes_made

def main():
    """Update all shot files with corrected plate mappings"""
    shot_dir = "/Users/ingthor/Documents/stories/appdata/json/7/shots/json"

    print("=" * 60)
    print("CORRECTED SHOT PLATE MAPPING UPDATE")
    print("Using actual environmental plate names from app")
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
    print("All shots now have corrected environmental plate mappings")
    print("=" * 60)

if __name__ == "__main__":
    main()