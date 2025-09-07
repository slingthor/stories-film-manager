#!/usr/bin/env python3
"""
Debug Plate Loading
Check what plates are loaded and what shots are expecting.
"""

import json
import os
from pathlib import Path

CHAR_PLATES_PATH = '/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_index.json'
ENV_PLATES_PATH = '/Users/ingthor/Documents/stories/appdata/json/7/plates/environmental_plates_index.json'
SHOTS_DIR = '/Users/ingthor/Documents/stories/appdata/json/7/shots/json'

def debug_plate_system():
    """Debug the plate loading system."""
    
    # Load central plates
    with open(CHAR_PLATES_PATH, 'r') as f:
        char_data = json.load(f)
    
    with open(ENV_PLATES_PATH, 'r') as f:
        env_data = json.load(f)
    
    char_plates = char_data['plate_index']
    env_plates = env_data['plate_index']
    
    print(f"📊 Central Plate System Status:")
    print(f"  Character plates: {len(char_plates)}")
    print(f"  Environmental plates: {len(env_plates)}")
    
    print(f"\n🎭 Character Plates Available:")
    for plate_id, plate_info in char_plates.items():
        print(f"  {plate_id}: {plate_info['character']} - {plate_info['name']}")
    
    print(f"\n🌍 Environmental Plates Available:")
    for plate_id, plate_info in env_plates.items():
        print(f"  {plate_id}: {plate_info['category']} - {plate_info['name']}")
    
    # Check what shots are requesting
    shot_files = list(Path(SHOTS_DIR).glob('shot_8*.json'))[:3]  # Just check a few Shot 8 variants
    
    print(f"\n🎬 Shot Plate References (Sample):")
    for shot_file in shot_files:
        with open(shot_file, 'r') as f:
            shot_data = json.load(f)
        
        shot_id = shot_data.get('shot_metadata', {}).get('id', '')
        
        for variant in shot_data.get('prompt_variants', []):
            char_plate = variant.get('selectedCharacterPlateId')
            env_plate = variant.get('selectedEnvironmentPlateId')
            
            char_exists = char_plate in char_plates if char_plate else False
            env_exists = env_plate in env_plates if env_plate else False
            
            print(f"  {shot_id}:")
            print(f"    Character: {char_plate} {'✅' if char_exists else '❌'}")
            print(f"    Environment: {env_plate} {'✅' if env_exists else '❌'}")
            break  # Just check first variant

if __name__ == "__main__":
    debug_plate_system()