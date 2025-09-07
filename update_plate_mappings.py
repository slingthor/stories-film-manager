#!/usr/bin/env python3

import json
import glob
import os

# Define the mapping based on SHOT_PLATE_MAPPING_GUIDE.md
PLATE_MAPPINGS = {
    'prologue': {
        'environment': 'WESTFJORDS-SUMMER',  # False abundance period
        'environment_interior': 'BAÐSTOFA-DOMESTIC'  # Interior during false abundance
    },
    'early_winter': {
        'environment': 'WESTFJORDS-WINTER',
        'environment_interior': 'BAÐSTOFA-ORGANIC'  # Mathematical breakdown
    },
    'mid_winter': {
        'environment': 'WESTFJORDS-WINTER', 
        'environment_interior': 'STOFA-CLIFF'  # Violence and crisis
    },
    'transformation': {
        'environment': 'WESTFJORDS-WINTER',
        'environment_interior': 'BAÐSTOFA-MONUMENT'  # Species change
    }
}

def determine_narrative_stage(filename, shot_data):
    """Determine narrative stage based on filename and shot metadata"""
    
    # Check filename patterns
    if 'prologue' in filename:
        return 'prologue'
    
    # Check shot metadata if available
    if 'shot_metadata' in shot_data:
        metadata = shot_data['shot_metadata']
        
        # Check film position percentage
        if 'film_position_percentage' in metadata:
            percentage = metadata['film_position_percentage']
            if percentage < 15:
                return 'prologue'
            elif percentage < 40:
                return 'early_winter'
            elif percentage < 70:
                return 'mid_winter'
            else:
                return 'transformation'
        
        # Check sequence type
        if metadata.get('sequence_type') == 'prologue':
            return 'prologue'
    
    # Default to early_winter if can't determine
    return 'early_winter'

def update_shot_file(filepath):
    """Update a single shot file with correct plate mappings"""
    
    try:
        with open(filepath, 'r') as f:
            data = json.load(f)
        
        filename = os.path.basename(filepath)
        narrative_stage = determine_narrative_stage(filename, data)
        mapping = PLATE_MAPPINGS[narrative_stage]
        
        updated = False
        
        # Update in prompt_variants if exists
        if 'prompt_variants' in data:
            for variant in data['prompt_variants']:
                if 'selectedEnvironmentPlateId' in variant:
                    # Determine if interior or exterior based on multiple factors
                    current_plate = variant['selectedEnvironmentPlateId']
                    
                    # Check if it's an interior shot based on current plate or other indicators
                    is_interior = False
                    
                    # Check current plate name
                    if 'STOFA' in current_plate or 'BAÐSTOFA' in current_plate or 'BA\u00d0STOFA' in current_plate:
                        is_interior = True
                    
                    # Also check the prompt content for interior keywords
                    if 'prompt_content' in variant:
                        prompt_lower = variant['prompt_content'].lower()
                        interior_keywords = ['interior', 'inside', 'indoor', 'stofa', 'baðstofa', 
                                           'room', 'floor', 'ceiling', 'walls', 'beams']
                        if any(keyword in prompt_lower for keyword in interior_keywords):
                            is_interior = True
                    
                    # Set the appropriate plate
                    if is_interior:
                        new_plate = mapping['environment_interior']
                    else:
                        new_plate = mapping['environment']
                    
                    if variant['selectedEnvironmentPlateId'] != new_plate:
                        variant['selectedEnvironmentPlateId'] = new_plate
                        updated = True
        
        if updated:
            with open(filepath, 'w') as f:
                json.dump(data, f, indent=2)
            return True
        
        return False
        
    except Exception as e:
        print(f"Error processing {filepath}: {e}")
        return False

def main():
    shot_dir = '/Users/ingthor/Documents/stories/appdata/json/7/shots/json/'
    
    # Process prologue shots
    prologue_files = glob.glob(os.path.join(shot_dir, '*prologue*.json'))
    print(f"Found {len(prologue_files)} prologue shot files")
    
    updated_count = 0
    for filepath in prologue_files:
        if update_shot_file(filepath):
            updated_count += 1
            print(f"Updated: {os.path.basename(filepath)}")
    
    print(f"\nUpdated {updated_count} prologue shot files")
    
    # Process main story shots based on film percentage
    main_files = glob.glob(os.path.join(shot_dir, '*main*.json'))
    print(f"\nFound {len(main_files)} main story shot files")
    
    main_updated = 0
    for filepath in main_files:
        if update_shot_file(filepath):
            main_updated += 1
            print(f"Updated: {os.path.basename(filepath)}")
    
    print(f"Updated {main_updated} main story shot files")
    print(f"\nTotal files updated: {updated_count + main_updated}")

if __name__ == '__main__':
    main()