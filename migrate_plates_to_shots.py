#!/usr/bin/env python3
"""
Migration script to map plates to shots based on shot_range fields in plate indices.
This restores the plate-to-shot mappings from the plate index files.
"""

import json
import re
import os
from pathlib import Path

def parse_shot_range(shot_range_str):
    """Parse shot range string like '(Shots 1-9)' or 'Shots 10-15' into list of shot numbers."""
    if not shot_range_str:
        return []
    
    # Extract numbers from patterns like "(Shots 1-9)", "Shots 10-15", etc.
    pattern = r'[Ss]hots?\s*(\d+)(?:\s*-\s*(\d+))?'
    matches = re.findall(pattern, shot_range_str)
    
    shot_numbers = []
    for match in matches:
        start = int(match[0])
        if match[1]:  # Range specified
            end = int(match[1])
            shot_numbers.extend(range(start, end + 1))
        else:  # Single shot
            shot_numbers.append(start)
    
    return shot_numbers

def load_plate_indices(version_path):
    """Load character and environmental plate indices."""
    char_index_path = version_path / "plate_indices" / "character_plates.json"
    env_index_path = version_path / "plate_indices" / "environmental_plates.json"
    
    character_plates = {}
    environmental_plates = {}
    
    if char_index_path.exists():
        with open(char_index_path, 'r') as f:
            data = json.load(f)
            character_plates = data.get('plate_index', {})
    
    if env_index_path.exists():
        with open(env_index_path, 'r') as f:
            data = json.load(f)
            environmental_plates = data.get('plate_index', {})
    
    return character_plates, environmental_plates

def build_shot_to_plates_mapping(character_plates, environmental_plates):
    """Build mapping of shot numbers to plate IDs based on shot_range fields."""
    shot_to_char_plates = {}
    shot_to_env_plates = {}
    
    # Process character plates
    for plate_id, plate_info in character_plates.items():
        shot_range = plate_info.get('shot_range', '')
        shot_numbers = parse_shot_range(shot_range)
        
        for shot_num in shot_numbers:
            if shot_num not in shot_to_char_plates:
                shot_to_char_plates[shot_num] = {}
            
            # Group by character
            character = plate_info.get('character', '').lower()
            if character:
                if character not in shot_to_char_plates[shot_num]:
                    shot_to_char_plates[shot_num][character] = []
                shot_to_char_plates[shot_num][character].append(plate_id)
    
    # Process environmental plates
    for plate_id, plate_info in environmental_plates.items():
        shot_range = plate_info.get('shot_range', '')
        shot_numbers = parse_shot_range(shot_range)
        
        for shot_num in shot_numbers:
            if shot_num not in shot_to_env_plates:
                shot_to_env_plates[shot_num] = {}
            
            # Categorize by type (landscape, weather, lighting, etc.)
            plate_type = plate_info.get('type', 'general').lower()
            if plate_type not in shot_to_env_plates[shot_num]:
                shot_to_env_plates[shot_num][plate_type] = []
            shot_to_env_plates[shot_num][plate_type].append(plate_id)
    
    return shot_to_char_plates, shot_to_env_plates

def update_shot_file(shot_path, char_plates, env_plates):
    """Update a shot file with selected plates."""
    with open(shot_path, 'r') as f:
        shot_data = json.load(f)
    
    # Extract shot number from filename (e.g., shot_1_main.json -> 1)
    filename = shot_path.name
    shot_num_match = re.search(r'shot_(\d+)', filename)
    if not shot_num_match:
        return False
    
    shot_num = int(shot_num_match.group(1))
    
    # Get plates for this shot
    char_plates_for_shot = char_plates.get(shot_num, {})
    env_plates_for_shot = env_plates.get(shot_num, {})
    
    # Update selected_plates in each prompt variant
    updated = False
    for variant in shot_data.get('prompt_variants', []):
        if 'selected_plates' not in variant:
            variant['selected_plates'] = {'characters': {}, 'environment': {}}
        
        # Clear existing selections to start fresh
        variant['selected_plates']['characters'] = {}
        variant['selected_plates']['environment'] = {}
        
        # Determine the primary character for this shot based on references
        primary_character = None
        
        # Check character_plates referenced field for hints
        char_plates_ref = variant.get('character_plates', {})
        referenced = char_plates_ref.get('referenced', [])
        
        # Extract character names from referenced plates (e.g., "MAGNUS-CONFUSED" -> "magnus")
        for ref in referenced:
            for char_name in ['magnus', 'sigrid', 'gudrun', 'jon', 'lilja']:
                if char_name.upper() in ref.upper():
                    primary_character = char_name
                    break
            if primary_character:
                break
        
        # If no primary character found from references, check subject/action text
        if not primary_character:
            text_to_check = (variant.get('subject', '') + ' ' + variant.get('action', '')).lower()
            for char_name in ['magnus', 'sigrid', 'gudrun', 'jon', 'lilja']:
                # Use proper name forms for checking
                char_forms = {
                    'magnus': ['magnús', 'magnus'],
                    'sigrid': ['sigrid'],
                    'gudrun': ['guðrún', 'gudrun'],
                    'jon': ['jón', 'jon'],
                    'lilja': ['lilja']
                }
                for form in char_forms.get(char_name, [char_name]):
                    if form in text_to_check:
                        primary_character = char_name
                        break
                if primary_character:
                    break
        
        # If still no primary, use priority order
        if not primary_character:
            priority_order = ['magnus', 'sigrid', 'gudrun', 'jon', 'lilja']
            for char in priority_order:
                if char in char_plates_for_shot and char_plates_for_shot[char]:
                    primary_character = char
                    break
        
        # Select ALL character plates that apply to this shot
        # The UI expects only one selectedCharacterPlateId, but we store all in selected_plates
        for character, plate_ids in char_plates_for_shot.items():
            if plate_ids:
                # Use the appropriate specialized plate for this shot
                variant['selected_plates']['characters'][character] = plate_ids[0]
                updated = True
        
        # For environment, select the most relevant single plate
        if env_plates_for_shot:
            # Priority for environment types
            env_priority = ['interior', 'landscape', 'weather', 'lighting', 'sea']
            for env_type in env_priority:
                if env_type in env_plates_for_shot and env_plates_for_shot[env_type]:
                    variant['selected_plates']['environment'][env_type] = env_plates_for_shot[env_type][0]
                    updated = True
                    break  # Only one environment plate for UI compatibility
    
    if updated:
        # Write back the updated shot file
        with open(shot_path, 'w') as f:
            json.dump(shot_data, f, indent=2, ensure_ascii=False)
        return True
    
    return False

def migrate_version(version_num):
    """Migrate plates for a specific version."""
    base_path = Path("/Users/ingthor/Documents/stories/appdata/json")
    version_path = base_path / str(version_num)
    
    if not version_path.exists():
        print(f"Version {version_num} path does not exist")
        return
    
    print(f"\nMigrating version {version_num}...")
    
    # Load plate indices
    char_plates, env_plates = load_plate_indices(version_path)
    print(f"Loaded {len(char_plates)} character plates and {len(env_plates)} environmental plates")
    
    # Build shot-to-plates mapping
    shot_to_char, shot_to_env = build_shot_to_plates_mapping(char_plates, env_plates)
    print(f"Built mappings for {len(shot_to_char)} shots with characters and {len(shot_to_env)} shots with environment")
    
    # Update shot files
    shots_path = version_path / "shots" / "json"
    if not shots_path.exists():
        print(f"No shots/json directory found for version {version_num}")
        return
    
    shot_files = list(shots_path.glob("shot_*_main.json"))
    updated_count = 0
    
    for shot_file in shot_files:
        if update_shot_file(shot_file, shot_to_char, shot_to_env):
            updated_count += 1
            print(f"  Updated {shot_file.name}")
    
    print(f"Updated {updated_count} shot files in version {version_num}")

def main():
    """Main migration function."""
    print("Starting plate-to-shot migration...")
    
    # Migrate version 7 (current latest version used by the app)
    migrate_version(7)
    
    # Also migrate version 6 as backup
    migrate_version(6)
    
    print("\nMigration complete!")

if __name__ == "__main__":
    main()