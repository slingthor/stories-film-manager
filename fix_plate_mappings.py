#!/usr/bin/env python3

import json
import glob
import os

# Define the complete mapping based on SHOT_PLATE_MAPPING_GUIDE.md
PLATE_MAPPINGS = {
    'prologue': {
        'interior': 'BAÐSTOFA-DOMESTIC',
        'landscape': 'WESTFJORDS-SUMMER', 
        'sea': 'SEA-ABUNDANT',
        'house': 'HOUSE-TRADITIONAL'
    },
    'early_winter': {
        'interior': 'BAÐSTOFA-ORGANIC',
        'landscape': 'WESTFJORDS-WINTER',
        'sea': 'SEA-EXTRACTED', 
        'house': 'HOUSE-GEOLOGICAL'
    },
    'mid_winter': {
        'interior': 'STOFA-CLIFF',
        'landscape': 'WESTFJORDS-WINTER',
        'sea': 'SEA-CONTAMINATED',
        'house': 'HOUSE-CRYSTALLIZING'
    },
    'transformation': {
        'interior': 'BAÐSTOFA-MONUMENT',
        'landscape': 'WESTFJORDS-WINTER',
        'sea': 'SEA-ETERNAL',
        'house': 'HOUSE-MONUMENT'
    }
}

def determine_narrative_stage(filename, shot_data):
    """Determine narrative stage based on filename and shot metadata"""
    
    # Check filename patterns
    if 'prologue' in filename.lower():
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
                
                # Update selected_plates if it exists
                if 'selected_plates' in variant:
                    if 'environment' in variant['selected_plates']:
                        env_plates = variant['selected_plates']['environment']
                        
                        # Update each environmental plate category
                        for plate_type in ['interior', 'landscape', 'sea']:
                            if plate_type in env_plates:
                                old_value = env_plates[plate_type]
                                new_value = mapping.get(plate_type, old_value)
                                if old_value != new_value:
                                    env_plates[plate_type] = new_value
                                    updated = True
                                    print(f"  Updated {plate_type}: {old_value} -> {new_value}")
                
                # Also update the selectedEnvironmentPlateId field
                if 'selectedEnvironmentPlateId' in variant:
                    current_plate = variant['selectedEnvironmentPlateId']
                    
                    # Determine which category this plate belongs to
                    new_plate = None
                    
                    # Check if it's an interior plate
                    if any(x in current_plate for x in ['STOFA', 'BAÐSTOFA', 'BA\u00d0STOFA']):
                        new_plate = mapping['interior']
                    # Check if it's a landscape/exterior plate
                    elif any(x in current_plate for x in ['WESTFJORDS', 'WINTER', 'SUMMER', 'HOUSE', 'EXTERIOR']):
                        # House plates
                        if 'HOUSE' in current_plate:
                            new_plate = mapping.get('house', mapping['landscape'])
                        else:
                            new_plate = mapping['landscape']
                    # Check if it's a sea plate
                    elif 'SEA' in current_plate:
                        new_plate = mapping.get('sea', mapping['landscape'])
                    else:
                        # Default to landscape for unknown plates
                        new_plate = mapping['landscape']
                    
                    if variant['selectedEnvironmentPlateId'] != new_plate:
                        print(f"  Updated selectedEnvironmentPlateId: {variant['selectedEnvironmentPlateId']} -> {new_plate}")
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
    
    # Get all JSON files
    all_files = glob.glob(os.path.join(shot_dir, '*.json'))
    print(f"Found {len(all_files)} JSON files to process\n")
    
    updated_count = 0
    for filepath in all_files:
        filename = os.path.basename(filepath)
        print(f"Processing: {filename}")
        
        if update_shot_file(filepath):
            updated_count += 1
            print(f"  ✓ Updated")
        else:
            print(f"  - No changes needed")
    
    print(f"\n{'='*50}")
    print(f"Total files updated: {updated_count}/{len(all_files)}")

if __name__ == '__main__':
    main()