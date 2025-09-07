#!/usr/bin/env python3
"""
Clean plate system - shots only have a list of plate IDs
UI determines plate type by querying central storage
"""

import json
import glob
import os

def load_plate_definitions():
    """Load plate definitions to know what exists"""
    all_plates = {}
    
    # Load character plates
    char_file = '/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json'
    if os.path.exists(char_file):
        with open(char_file, 'r') as f:
            data = json.load(f)
            if 'plate_index' in data:
                for plate_id, plate_data in data['plate_index'].items():
                    all_plates[plate_id] = {
                        'type': 'character',
                        'character': plate_data.get('character', ''),
                        **plate_data
                    }
    
    # Load environmental plates  
    env_file = '/Users/ingthor/Documents/stories/appdata/json/7/plates/environmental_plates_complete.json'
    if os.path.exists(env_file):
        with open(env_file, 'r') as f:
            data = json.load(f)
            if 'plate_index' in data:
                for plate_id, plate_data in data['plate_index'].items():
                    all_plates[plate_id] = {
                        'type': 'environmental',
                        'category': plate_data.get('category', ''),
                        **plate_data
                    }
    
    return all_plates

def get_default_plates_for_shot(filename, shot_data):
    """Determine which plates should be selected based on shot context"""
    plates = []
    
    # Determine narrative stage
    pos = 0
    if 'shot_metadata' in shot_data:
        pos = shot_data['shot_metadata'].get('film_position_percentage', 0)
    
    # Character plates based on narrative progression
    if pos < 15:  # Prologue
        plates.extend([
            'MAGNUS-AUTHORITY',
            'SIGRID-PURE',
            'GUDRUN-ABUNDANT',
            'JON-MASTER',
            'LILJA-PURE'
        ])
    elif pos < 40:  # Early winter
        plates.extend([
            'MAGNUS-CONFUSED',
            'SIGRID-CALCULATING', 
            'GUDRUN-COUNTING',
            'JON-PROPHET',
            'LILJA-MATHEMATICAL'
        ])
    elif pos < 70:  # Mid winter
        plates.extend([
            'MAGNUS-MASTER',  # Using MASTER instead of non-existent EMPIRE
            'SIGRID-MARKED',
            'GUDRUN-BEATEN',
            'JON-MILD',
            'LILJA-COUNTING'
        ])
    else:  # Transformation
        plates.extend([
            'MAGNUS-PREDATOR',  # Using PREDATOR for late stage
            'SIGRID-MARKED',    # ANCIENT doesn't exist
            'GUDRUN-TRANSFORMING',
            'JON-TEMPORAL',     # Using TEMPORAL for late stage
            'LILJA-LAMB'
        ])
    
    # Environmental plates based on context
    if pos < 15:  # Prologue
        plates.append('WESTFJORDS-SUMMER')
        plates.append('BAÐSTOFA-DOMESTIC')
        plates.append('SEA-ABUNDANT')
        plates.append('HOUSE-TRADITIONAL')
    elif pos < 40:  # Early winter
        plates.append('WESTFJORDS-WINTER')
        plates.append('BAÐSTOFA-ORGANIC')
        plates.append('SEA-EXTRACTED')
        plates.append('HOUSE-GEOLOGICAL')
    elif pos < 70:  # Mid winter
        plates.append('WESTFJORDS-WINTER')
        plates.append('STOFA-CLIFF')
        plates.append('SEA-CONTAMINATED')
        plates.append('HOUSE-CRYSTALLIZING')
    else:  # Transformation
        plates.append('WESTFJORDS-WINTER')
        plates.append('BAÐSTOFA-MONUMENT')
        plates.append('SEA-ETERNAL')
        plates.append('HOUSE-MONUMENT')
    
    return plates

def clean_shot_file(filepath, all_plates):
    """Clean up a single shot file to use simple plate list"""
    
    try:
        with open(filepath, 'r') as f:
            data = json.load(f)
        
        filename = os.path.basename(filepath)
        changes_made = False
        
        # Get default plates for this shot
        default_plates = get_default_plates_for_shot(filename, data)
        
        # Process each prompt variant
        if 'prompt_variants' in data:
            for variant in data['prompt_variants']:
                
                # Remove old complex structures
                fields_to_remove = [
                    'character_plates', 
                    'environmental_plates',
                    'recommended_plates', 
                    'available_plates',
                    'selectedCharacterPlateId',
                    'selectedEnvironmentPlateId'
                ]
                for field in fields_to_remove:
                    if field in variant:
                        del variant[field]
                        changes_made = True
                
                # Check if we already have a clean selected_plates list
                existing_plates = variant.get('selected_plates', {})
                
                # If it's the old nested structure, extract plate IDs
                if isinstance(existing_plates, dict):
                    plate_list = []
                    
                    # Extract character plates
                    if 'characters' in existing_plates:
                        for char_name, plate_id in existing_plates['characters'].items():
                            if plate_id and plate_id in all_plates:
                                plate_list.append(plate_id)
                    
                    # Extract environment plates
                    if 'environment' in existing_plates:
                        for env_type, plate_id in existing_plates['environment'].items():
                            if plate_id and plate_id in all_plates:
                                plate_list.append(plate_id)
                    
                    # Use extracted plates or defaults
                    variant['selected_plates'] = plate_list if plate_list else default_plates
                    changes_made = True
                
                # If no plates at all, use defaults
                elif not existing_plates:
                    variant['selected_plates'] = default_plates
                    changes_made = True
                
                # Validate all plates exist
                if 'selected_plates' in variant:
                    valid_plates = [p for p in variant['selected_plates'] if p in all_plates]
                    if len(valid_plates) != len(variant['selected_plates']):
                        variant['selected_plates'] = valid_plates if valid_plates else default_plates
                        changes_made = True
        
        # Save if changes were made
        if changes_made:
            with open(filepath, 'w') as f:
                json.dump(data, f, indent=2)
            return True
        
        return False
        
    except Exception as e:
        print(f"Error processing {filepath}: {e}")
        return False

def main():
    # Load all plate definitions
    print("Loading plate definitions...")
    all_plates = load_plate_definitions()
    print(f"Found {len(all_plates)} total plates")
    
    char_plates = [p for p in all_plates.values() if p['type'] == 'character']
    env_plates = [p for p in all_plates.values() if p['type'] == 'environmental']
    print(f"  - {len(char_plates)} character plates")
    print(f"  - {len(env_plates)} environmental plates")
    
    # Process all shot files
    shot_dir = '/Users/ingthor/Documents/stories/appdata/json/7/shots/json/'
    all_files = glob.glob(os.path.join(shot_dir, '*.json'))
    print(f"\nProcessing {len(all_files)} shot files...")
    
    updated = 0
    for i, filepath in enumerate(all_files):
        if i % 10 == 0:
            print(f"  Processing {i}/{len(all_files)}...")
        
        if clean_shot_file(filepath, all_plates):
            updated += 1
    
    print(f"\n{'='*60}")
    print(f"COMPLETE: Updated {updated}/{len(all_files)} shot files")
    print(f"\nThe plate system is now clean and simple:")
    print(f"  - Shots have a simple list of plate IDs in 'selected_plates'")
    print(f"  - No nested structures or type information in shots")
    print(f"  - UI queries central storage to determine plate types")
    print(f"  - UI can filter plates by character name or environment category")
    print(f"\nExample shot structure:")
    print(f'  "selected_plates": [')
    print(f'    "MAGNUS-CONFUSED",')
    print(f'    "SIGRID-CALCULATING",')
    print(f'    "BAÐSTOFA-ORGANIC",')
    print(f'    "WESTFJORDS-WINTER"')
    print(f'  ]')

if __name__ == '__main__':
    main()