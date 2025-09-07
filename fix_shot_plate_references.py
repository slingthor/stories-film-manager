#!/usr/bin/env python3
"""
Fix Shot Plate References
Maps shot-specific plate selections to appropriate central PlateManager IDs
based on narrative context and shot ranges.
"""

import json
import os
import re
from pathlib import Path

SHOTS_DIR = '/Users/ingthor/Documents/stories/appdata/json/7/shots/json'
CHAR_PLATES_PATH = '/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_index.json'
ENV_PLATES_PATH = '/Users/ingthor/Documents/stories/appdata/json/7/plates/environmental_plates_index.json'

def load_central_plates():
    """Load the central plate managers."""
    with open(CHAR_PLATES_PATH, 'r', encoding='utf-8') as f:
        char_data = json.load(f)
    
    with open(ENV_PLATES_PATH, 'r', encoding='utf-8') as f:
        env_data = json.load(f)
    
    return char_data['plate_index'], env_data['plate_index']

def get_appropriate_plate_for_shot(shot_id: str, character: str, shot_title: str, char_plates: dict) -> str:
    """Get the appropriate central plate ID for a character in a specific shot."""
    shot_num = int(re.search(r'\d+', shot_id).group()) if re.search(r'\d+', shot_id) else 0
    
    # Character-specific plate selection based on shot context
    if character.lower() == 'sigrid':
        if 'counting' in shot_title.lower() or shot_num in [8, 9, 10]:
            # During Danish counting - she's calculating/analyzing
            if 'SIGRID-CALCULATING' in char_plates:
                return 'SIGRID-CALCULATING'
            elif 'SIGRID-AWAKENING' in char_plates:
                return 'SIGRID-AWAKENING'
        elif shot_num < 15:
            # Early shots - pure/awakening
            if 'SIGRID-PURE' in char_plates:
                return 'SIGRID-PURE'
            elif 'SIGRID-AWAKENING' in char_plates:
                return 'SIGRID-AWAKENING'
        else:
            # Later shots - more developed plates
            if 'SIGRID-KNOWING' in char_plates:
                return 'SIGRID-KNOWING'
            elif 'SIGRID-MARKED' in char_plates:
                return 'SIGRID-MARKED'
        
        # Default to master plate
        return 'SIGRID-MASTER' if 'SIGRID-MASTER' in char_plates else None
        
    elif character.lower() == 'magnus':
        if shot_num < 20:
            # Early shots - authority/master
            if 'S-AUTHORITY' in char_plates:
                return 'S-AUTHORITY'
            elif 'MAGNUS-MASTER' in char_plates:
                return 'MAGNUS-MASTER'
        elif 'counting' in shot_title.lower():
            # During counting crisis
            if 'S-MATHEMATICAL' in char_plates:
                return 'S-MATHEMATICAL'
            elif 'S-CONFUSED' in char_plates:
                return 'S-CONFUSED'
        else:
            # Default progression
            return 'MAGNUS-MASTER' if 'MAGNUS-MASTER' in char_plates else 'S-AUTHORITY'
            
    elif character.lower() in ['gudrun', 'guðrún']:
        if shot_num < 20:
            # Early shots - abundant/normal
            if 'N-ABUNDANT' in char_plates:
                return 'N-ABUNDANT'
            elif 'GUDRUN-MASTER' in char_plates:
                return 'GUDRUN-MASTER'
        elif 'counting' in shot_title.lower():
            # During counting
            if 'N-COUNTING' in char_plates:
                return 'N-COUNTING'
            elif 'N-WATCHING' in char_plates:
                return 'N-WATCHING'
        else:
            return 'GUDRUN-MASTER' if 'GUDRUN-MASTER' in char_plates else None
            
    elif character.lower() in ['jon', 'jón']:
        if shot_num < 15:
            # Early shots - mild fever
            if 'N-MILD' in char_plates:
                return 'N-MILD'
            elif 'JON-MASTER' in char_plates:
                return 'JON-MASTER'
        elif 'counting' in shot_title.lower():
            # During counting
            if 'N-PROPHET' in char_plates:
                return 'N-PROPHET'
            elif 'N-SEEING' in char_plates:
                return 'N-SEEING'
        else:
            return 'JON-MASTER' if 'JON-MASTER' in char_plates else None
    
    return None

def get_appropriate_env_plate_for_shot(shot_id: str, shot_title: str, env_plates: dict) -> str:
    """Get the appropriate environmental plate for a shot."""
    shot_num = int(re.search(r'\d+', shot_id).group()) if re.search(r'\d+', shot_id) else 0
    
    # Interior shots
    if 'counting' in shot_title.lower() or 'danish' in shot_title.lower():
        # House during counting crisis
        if 'STOFA-SURVEILLANCE' in env_plates:
            return 'STOFA-SURVEILLANCE'
        elif 'STOFA-DOMESTIC' in env_plates:
            return 'STOFA-DOMESTIC'
    
    # Default to house interior for early shots
    if shot_num < 30:
        if 'STOFA-DOMESTIC' in env_plates:
            return 'STOFA-DOMESTIC'
        elif 'HOUSE-TRADITIONAL' in env_plates:
            return 'HOUSE-TRADITIONAL'
    
    # Later shots - more geological
    if 'STOFA-CLEFT' in env_plates:
        return 'STOFA-CLEFT'
    elif 'HOUSE-GEOLOGICAL' in env_plates:
        return 'HOUSE-GEOLOGICAL'
    
    return None

def fix_shot_plate_references():
    """Fix plate references in all shot files."""
    char_plates, env_plates = load_central_plates()
    
    print(f"Loaded {len(char_plates)} character plates and {len(env_plates)} environmental plates")
    
    shot_files = list(Path(SHOTS_DIR).glob('*.json'))
    print(f"Processing {len(shot_files)} shot files...")
    
    fixed_shots = 0
    
    for shot_file in shot_files:
        try:
            with open(shot_file, 'r', encoding='utf-8') as f:
                shot_data = json.load(f)
            
            # Get shot metadata
            shot_metadata = shot_data.get('shot_metadata', {})
            shot_id = shot_metadata.get('id', '')
            shot_title = shot_metadata.get('title', '')
            
            modified = False
            
            # Fix character plate references in prompt variants
            for variant in shot_data.get('prompt_variants', []):
                if 'selectedCharacterPlateId' in variant:
                    old_id = variant['selectedCharacterPlateId']
                    if old_id and old_id not in char_plates:
                        # Determine which character this should be for
                        # Default to Sigrid for main story progression
                        new_id = get_appropriate_plate_for_shot(shot_id, 'sigrid', shot_title, char_plates)
                        
                        if new_id:
                            variant['selectedCharacterPlateId'] = new_id
                            print(f"  Shot {shot_id}: {old_id} -> {new_id}")
                            modified = True
                        else:
                            # Remove invalid reference
                            variant['selectedCharacterPlateId'] = None
                            print(f"  Shot {shot_id}: removed invalid {old_id}")
                            modified = True
                
                if 'selectedEnvironmentPlateId' in variant:
                    old_id = variant['selectedEnvironmentPlateId']
                    if old_id and old_id not in env_plates:
                        new_id = get_appropriate_env_plate_for_shot(shot_id, shot_title, env_plates)
                        
                        if new_id:
                            variant['selectedEnvironmentPlateId'] = new_id
                            print(f"  Shot {shot_id}: env {old_id} -> {new_id}")
                            modified = True
                        else:
                            variant['selectedEnvironmentPlateId'] = None
                            print(f"  Shot {shot_id}: removed invalid env {old_id}")
                            modified = True
            
            # Save if modified
            if modified:
                with open(shot_file, 'w', encoding='utf-8') as f:
                    json.dump(shot_data, f, indent=2, ensure_ascii=False)
                fixed_shots += 1
                
        except Exception as e:
            print(f"Error processing {shot_file}: {e}")
    
    print(f"\nFixed plate references in {fixed_shots} shot files")

if __name__ == "__main__":
    fix_shot_plate_references()