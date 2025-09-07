#!/usr/bin/env python3
"""
Fix Plate Integration Script
Updates shot JSON files to have selectedCharacterPlateId and selectedEnvironmentPlateId 
at the correct level on PromptVariant objects.
"""

import json
import os
from pathlib import Path

SHOT_JSON_DIR = '/Users/ingthor/Documents/stories/appdata/json/7/shots/json'

def fix_shot_file(shot_file_path: str) -> bool:
    """Fix a single shot JSON file to have correct plate selection structure."""
    with open(shot_file_path, 'r', encoding='utf-8') as f:
        shot_data = json.load(f)
    
    updated = False
    
    for variant in shot_data.get('prompt_variants', []):
        # Check if we have the new structure with available_plates and selected_plates
        char_plates = variant.get('character_plates', {})
        env_plates = variant.get('environmental_plates', {})
        
        # Extract selected plates from our new structure
        char_selected = char_plates.get('selected_plates', {})
        env_selected = env_plates.get('selected_plates', {})
        
        # Set selectedCharacterPlateId - pick the first character plate available
        if char_selected and not variant.get('selectedCharacterPlateId'):
            # Priority order for character selection
            priority_chars = ['magnus', 'sigrid', 'gudrun', 'jon', 'lilja']
            
            for char in priority_chars:
                if char in char_selected:
                    variant['selectedCharacterPlateId'] = char_selected[char]
                    print(f"  Set selectedCharacterPlateId: {char_selected[char]} for {char}")
                    updated = True
                    break
        
        # Set selectedEnvironmentPlateId - pick the first environment plate available  
        if env_selected and not variant.get('selectedEnvironmentPlateId'):
            # Priority order for environment selection
            priority_envs = ['interior', 'landscape', 'weather', 'lighting', 'sea']
            
            for env in priority_envs:
                if env in env_selected:
                    variant['selectedEnvironmentPlateId'] = env_selected[env]
                    print(f"  Set selectedEnvironmentPlateId: {env_selected[env]} for {env}")
                    updated = True
                    break
        
        # Also ensure backward compatibility with selected_plates structure
        if 'selected_plates' not in variant:
            variant['selected_plates'] = {}
            
        variant['selected_plates']['characters'] = char_selected
        variant['selected_plates']['environment'] = env_selected
    
    if updated:
        # Write back the updated file
        with open(shot_file_path, 'w', encoding='utf-8') as f:
            json.dump(shot_data, f, indent=2, ensure_ascii=False)
        
        return True
    
    return False

def fix_all_shot_files():
    """Fix all shot JSON files to have correct plate selection structure."""
    print(f"Fixing plate selections in {SHOT_JSON_DIR}...")
    
    if not os.path.exists(SHOT_JSON_DIR):
        print(f"Shot directory not found: {SHOT_JSON_DIR}")
        return
    
    shot_files = [f for f in Path(SHOT_JSON_DIR).glob('*.json') if 'shot_' in f.name.lower()]
    print(f"Found {len(shot_files)} shot files")
    
    updated_count = 0
    
    for shot_file in shot_files:
        try:
            filename = os.path.basename(shot_file)
            # Extract shot number for reporting
            import re
            shot_match = re.search(r'shot_(\w+)', filename)
            shot_id = shot_match.group(1) if shot_match else filename
            
            print(f"Processing Shot {shot_id}...")
            if fix_shot_file(str(shot_file)):
                updated_count += 1
            
            if updated_count % 10 == 0 and updated_count > 0:
                print(f"  Progress: {updated_count} files updated...")
                
        except Exception as e:
            print(f"Error updating {shot_file}: {e}")
    
    print(f"\nFix complete: {updated_count} shot files updated with correct plate structure")

if __name__ == "__main__":
    fix_all_shot_files()