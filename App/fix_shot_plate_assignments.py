#!/usr/bin/env python3
"""
Fix plate assignments in shot JSON files based on narrative progression.
Only assigns plates for characters actually present in shots and selects
appropriate specializations based on narrative stage.
"""

import json
import os
import re
from pathlib import Path
from typing import Dict, List, Set, Optional, Tuple

# Base paths
SHOTS_DIR = "/Users/ingthor/Documents/stories/appdata/json/7/shots/json"
CHARACTER_PLATES_FILE = "/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json"
ENVIRONMENTAL_PLATES_FILE = "/Users/ingthor/Documents/stories/appdata/json/7/plates/environmental_plates_complete.json"

# Narrative stage definitions based on film percentage
NARRATIVE_STAGES = {
    "prologue": (0, 5),  # 0-5%: False abundance, curse establishment
    "early_winter": (5, 25),  # 5-25%: Mathematical breakdown, initial crisis
    "mid_winter": (25, 60),  # 25-60%: Violence, starvation, transformation beginning
    "late_winter": (60, 85),  # 60-85%: Active transformation
    "epilogue": (85, 100)  # 85-100%: Monument, eternal testimony
}

# Character plate mapping by narrative stage
CHARACTER_PLATE_MAPPING = {
    "prologue": {
        "magnus": "MAGNUS-AUTHORITY",  # Confident patriarch
        "sigrid": "SIGRID-PURE",  # Innocent, untouched
        "gudrun": "GUDRUN-ABUNDANT",  # Competent mother
        "jon": "JON-MASTER",  # Base template
        "lilja": "LILJA-PURE"  # Perfect innocence
    },
    "early_winter": {
        "magnus": "MAGNUS-CONFUSED",  # Authority cracking
        "sigrid": "SIGRID-MARKED",  # Post-violation
        "gudrun": "GUDRUN-PRODUCING",  # Wool emerging
        "jon": "JON-PROPHET",  # Fever vision
        "lilja": "LILJA-MATHEMATICAL"  # Counting confusion
    },
    "mid_winter": {
        "magnus": "MAGNUS-PREDATOR",  # Violence-ready
        "sigrid": "SIGRID-CORNERED",  # Maximum threat
        "gudrun": "GUDRUN-CONDEMNED",  # Death journey assignment
        "jon": "JON-TEMPORAL",  # Peak fever consciousness
        "lilja": "LILJA-SENSING"  # Environmental awareness
    },
    "late_winter": {
        "magnus": "MAGNUS-HYBRID",  # Ram transformation
        "sigrid": "SIGRID-TRANSITIONAL",  # Species change
        "gudrun": "GUDRUN-SPEAKING",  # Truth-telling
        "jon": "JON-CHANGING",  # Active transformation
        "lilja": "LILJA-FINAL"  # Before simplification
    },
    "epilogue": {
        "magnus": "S-RAM",  # Ram form
        "sigrid": "SIGRID-CORVID",  # Raven form
        "gudrun": "GUDRUN-ETERNAL",  # Ewe with crown
        "jon": "JON-LAMB",  # Lamb form
        "lilja": "LILJA-LAMB"  # Lamb form
    }
}

# Environmental plate mapping by narrative stage
ENVIRONMENTAL_PLATE_MAPPING = {
    "prologue": {
        "exterior": ["WESTFJORDS-SUMMER", "HOUSE-TRADITIONAL"],
        "interior": ["BAÐSTOFA-DOMESTIC", "STOFA-DOMESTIC"],
        "sea": ["SEA-ABUNDANT", "SEA-DIVINE"]
    },
    "early_winter": {
        "exterior": ["WESTFJORDS-WINTER", "HOUSE-AWAKENING"],
        "interior": ["STOFA-STIRRING", "BAÐSTOFA-ORGANIC"],
        "sea": ["SEA-EXTRACTED", "SEA-CONTAMINATED"]
    },
    "mid_winter": {
        "exterior": ["WESTFJORDS-CLIFF", "HOUSE-GEOLOGICAL"],
        "interior": ["STOFA-BODY", "STOFA-DESPERATE"],
        "sea": ["SEA-BATTLE", "SEA-SEDUCTIVE"]
    },
    "late_winter": {
        "exterior": ["HOUSE-CLIFF", "HOUSE-CRYSTALLIZING"],
        "interior": ["STOFA-CLIFF", "BAÐSTOFA-CLIFF"],
        "sea": ["SEA-ACCUSATION"]
    },
    "epilogue": {
        "exterior": ["HOUSE-MONUMENT"],
        "interior": ["BAÐSTOFA-MONUMENT", "STOFA-MONUMENT"],
        "sea": ["SEA-ETERNAL"]
    }
}

def load_plates() -> Tuple[Dict, Dict]:
    """Load character and environmental plates from JSON files."""
    with open(CHARACTER_PLATES_FILE, 'r') as f:
        char_data = json.load(f)
    
    with open(ENVIRONMENTAL_PLATES_FILE, 'r') as f:
        env_data = json.load(f)
    
    return char_data['plate_index'], env_data['plate_index']

def get_narrative_stage(film_percentage: float) -> str:
    """Determine narrative stage based on film percentage."""
    for stage, (start, end) in NARRATIVE_STAGES.items():
        if start <= film_percentage < end:
            return stage
    return "epilogue"  # Default to epilogue for 100%

def extract_characters_from_shot(shot_data: Dict) -> Set[str]:
    """Extract which characters are actually present in a shot."""
    characters = set()
    
    # Check prompt variants for character mentions
    for variant in shot_data.get('prompt_variants', []):
        # Check subject, action, scene, and dialogue fields
        # Don't convert to lowercase to preserve encoded names
        text = ' '.join([
            str(variant.get('subject', '')),
            str(variant.get('action', '')),
            str(variant.get('scene', '')),
            str(variant.get('dialogue', ''))
        ])
        
        # Also create lowercase version for some checks
        text_lower = text.lower()
        
        # Look for character names - check both lowercase and uppercase encoded versions
        if 'magnus' in text_lower or 'magnús' in text_lower or 'MAGNÚS' in text or 'þorláksson' in text_lower or 'father' in text_lower:
            characters.add('magnus')
        if 'sigrid' in text_lower or 'sigríður' in text_lower or 'SIGRÍÐUR' in text or 'daughter' in text_lower:
            characters.add('sigrid')
        if 'gudrun' in text_lower or 'guðrún' in text_lower or 'GUÐRÚN' in text or 'mother' in text_lower or 'wife' in text_lower:
            characters.add('gudrun')
        if 'jon' in text_lower or 'jón' in text_lower or 'JÓN' in text or 'son' in text_lower or 'boy' in text_lower:
            characters.add('jon')
        if 'lilja' in text_lower or 'LILJA' in text or 'toddler' in text_lower or 'child' in text_lower:
            characters.add('lilja')
    
    # Special cases based on shot metadata
    shot_name = shot_data.get('shot_metadata', {}).get('name', '').lower()
    shot_id = shot_data.get('shot_metadata', {}).get('id', '').lower()
    
    # Prologue shots (curse pole, landscape) typically have no characters
    if 'prologue' in shot_id or 'pole' in shot_name or 'shadow' in shot_name:
        return set()
    
    # Family counting scenes have all family members
    if 'counting' in shot_name or 'mathematical' in shot_name:
        return {'magnus', 'sigrid', 'gudrun', 'jon', 'lilja'}
    
    # Solo journey shots
    if 'alone' in shot_name or 'departure' in shot_name:
        if 'magnus' in shot_name:
            return {'magnus'}
        elif 'gudrun' in shot_name:
            return {'gudrun'}
    
    # If no characters detected but it's clearly an interior family scene
    if not characters and 'baðstofa' in text.lower():
        # Most interior scenes have the whole family
        return {'magnus', 'sigrid', 'gudrun', 'jon', 'lilja'}
    
    return characters

def determine_environment_type(shot_data: Dict) -> str:
    """Determine the primary environment type for a shot."""
    # Check prompt variants for environment clues
    for variant in shot_data.get('prompt_variants', []):
        scene = str(variant.get('scene', '')).lower()
        subject = str(variant.get('subject', '')).lower()
        
        if 'baðstofa' in scene or 'interior' in scene or 'inside' in scene:
            return 'interior'
        elif 'sea' in scene or 'ocean' in scene or 'water' in scene or 'rowing' in scene:
            return 'sea'
        elif 'cliff' in scene or 'mountain' in scene or 'outside' in scene or 'westfjords' in scene:
            return 'exterior'
    
    # Default based on shot name
    shot_name = shot_data.get('shot_metadata', {}).get('name', '').lower()
    if 'sea' in shot_name or 'rowing' in shot_name:
        return 'sea'
    elif 'house' in shot_name or 'baðstofa' in shot_name:
        return 'interior'
    else:
        return 'exterior'

def select_plates_for_shot(shot_data: Dict, char_plates: Dict, env_plates: Dict) -> List[str]:
    """Select appropriate plates for a shot based on narrative context."""
    selected_plates = []
    
    # Get film percentage and narrative stage
    film_percentage = shot_data.get('shot_metadata', {}).get('film_position_percentage', 50.0)
    narrative_stage = get_narrative_stage(film_percentage)
    
    # Get characters present in shot
    characters_present = extract_characters_from_shot(shot_data)
    
    # Select character plates
    if narrative_stage in CHARACTER_PLATE_MAPPING:
        stage_plates = CHARACTER_PLATE_MAPPING[narrative_stage]
        for character in characters_present:
            if character in stage_plates:
                plate_id = stage_plates[character]
                if plate_id in char_plates:
                    selected_plates.append(plate_id)
    
    # Select environmental plates
    env_type = determine_environment_type(shot_data)
    if narrative_stage in ENVIRONMENTAL_PLATE_MAPPING:
        env_options = ENVIRONMENTAL_PLATE_MAPPING[narrative_stage].get(env_type, [])
        # Select the most appropriate environmental plate
        for plate_id in env_options:
            if plate_id in env_plates:
                selected_plates.append(plate_id)
                break  # Usually just one environmental plate per shot
    
    return selected_plates

def update_shot_file(filepath: Path, char_plates: Dict, env_plates: Dict) -> bool:
    """Update a single shot file with corrected plate assignments."""
    try:
        with open(filepath, 'r') as f:
            shot_data = json.load(f)
        
        # Select appropriate plates
        selected_plates = select_plates_for_shot(shot_data, char_plates, env_plates)
        
        # Update each prompt variant
        for variant in shot_data.get('prompt_variants', []):
            variant['selected_plates'] = selected_plates
        
        # Write back to file
        with open(filepath, 'w') as f:
            json.dump(shot_data, f, indent=2, ensure_ascii=False)
        
        return True
    except Exception as e:
        print(f"Error updating {filepath}: {e}")
        return False

def main():
    """Main function to fix all shot files."""
    print("Loading plate data...")
    char_plates, env_plates = load_plates()
    print(f"Loaded {len(char_plates)} character plates and {len(env_plates)} environmental plates")
    
    # Get all shot files
    shot_files = list(Path(SHOTS_DIR).glob("shot_*.json"))
    print(f"Found {len(shot_files)} shot files to process")
    
    # Update each shot file
    success_count = 0
    for i, filepath in enumerate(shot_files, 1):
        if update_shot_file(filepath, char_plates, env_plates):
            success_count += 1
            print(f"✓ Updated {filepath.name} ({i}/{len(shot_files)})")
        else:
            print(f"✗ Failed to update {filepath.name}")
    
    print(f"\nCompleted: {success_count}/{len(shot_files)} files updated successfully")

if __name__ == "__main__":
    main()