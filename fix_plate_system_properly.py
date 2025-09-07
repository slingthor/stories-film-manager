#!/usr/bin/env python3
"""
Complete plate system fix - creates proper plate references in shots
"""

import json
import glob
import os

# Default master plates for each category
DEFAULT_PLATES = {
    'characters': {
        'magnus': 'MAGNUS-AUTHORITY',
        'sigrid': 'SIGRID-PURE', 
        'gudrun': 'GUDRUN-ABUNDANT',
        'jon': 'JON-MASTER',
        'lilja': 'LILJA-PURE'
    },
    'environment': {
        'interior': 'BAÐSTOFA-DOMESTIC',
        'landscape': 'WESTFJORDS-MASTER',
        'sea': 'SEA-MASTER',
        'house': 'HOUSE-TRADITIONAL'
    }
}

# Narrative-based plate mappings
NARRATIVE_MAPPINGS = {
    'prologue': {
        'characters': {
            'magnus': 'MAGNUS-AUTHORITY',
            'sigrid': 'SIGRID-PURE',
            'gudrun': 'GUDRUN-ABUNDANT', 
            'jon': 'JON-MASTER',
            'lilja': 'LILJA-PURE'
        },
        'environment': {
            'interior': 'BAÐSTOFA-DOMESTIC',
            'landscape': 'WESTFJORDS-SUMMER',
            'sea': 'SEA-ABUNDANT',
            'house': 'HOUSE-TRADITIONAL'
        }
    },
    'early_winter': {
        'characters': {
            'magnus': 'MAGNUS-CONFUSED',
            'sigrid': 'SIGRID-CALCULATING',
            'gudrun': 'GUDRUN-COUNTING',
            'jon': 'JON-PROPHET',
            'lilja': 'LILJA-MATHEMATICAL'
        },
        'environment': {
            'interior': 'BAÐSTOFA-ORGANIC',
            'landscape': 'WESTFJORDS-WINTER',
            'sea': 'SEA-EXTRACTED',
            'house': 'HOUSE-GEOLOGICAL'
        }
    },
    'mid_winter': {
        'characters': {
            'magnus': 'MAGNUS-EMPIRE',
            'sigrid': 'SIGRID-MARKED',
            'gudrun': 'GUDRUN-BEATEN',
            'jon': 'JON-MILD',
            'lilja': 'LILJA-COUNTING'
        },
        'environment': {
            'interior': 'STOFA-CLIFF',
            'landscape': 'WESTFJORDS-WINTER',
            'sea': 'SEA-CONTAMINATED',
            'house': 'HOUSE-CRYSTALLIZING'
        }
    },
    'transformation': {
        'characters': {
            'magnus': 'MAGNUS-FINAL',
            'sigrid': 'SIGRID-ANCIENT',
            'gudrun': 'GUDRUN-TRANSFORMING',
            'jon': 'JON-FINAL',
            'lilja': 'LILJA-LAMB'
        },
        'environment': {
            'interior': 'BAÐSTOFA-MONUMENT',
            'landscape': 'WESTFJORDS-WINTER',
            'sea': 'SEA-ETERNAL',
            'house': 'HOUSE-MONUMENT'
        }
    }
}

def load_plate_definitions():
    """Load the complete plate definitions"""
    char_plates = {}
    env_plates = {}
    
    # Load character plates
    char_file = '/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json'
    if os.path.exists(char_file):
        with open(char_file, 'r') as f:
            data = json.load(f)
            if 'plate_index' in data:
                char_plates = set(data['plate_index'].keys())
    
    # Load environmental plates  
    env_file = '/Users/ingthor/Documents/stories/appdata/json/7/plates/environmental_plates_complete.json'
    if os.path.exists(env_file):
        with open(env_file, 'r') as f:
            data = json.load(f)
            if 'plate_index' in data:
                env_plates = set(data['plate_index'].keys())
    
    return char_plates, env_plates

def determine_narrative_stage(filename, shot_data):
    """Determine narrative stage based on shot metadata"""
    
    # Check filename
    if 'prologue' in filename.lower():
        return 'prologue'
    
    # Check shot metadata
    if 'shot_metadata' in shot_data:
        metadata = shot_data['shot_metadata']
        
        # Check sequence type
        if metadata.get('sequence_type') == 'prologue':
            return 'prologue'
            
        # Check film position
        if 'film_position_percentage' in metadata:
            pos = metadata['film_position_percentage']
            if pos < 15:
                return 'prologue'
            elif pos < 40:
                return 'early_winter'
            elif pos < 70:
                return 'mid_winter'
            else:
                return 'transformation'
    
    return 'early_winter'  # Default

def validate_plate_id(plate_id, valid_plates, plate_type):
    """Check if a plate ID exists in the valid set"""
    if plate_id in valid_plates:
        return plate_id
    
    # Handle common variations
    if plate_id.replace('Ð', 'D') in valid_plates:
        return plate_id.replace('Ð', 'D')
    if plate_id.replace('D', 'Ð') in valid_plates:
        return plate_id.replace('D', 'Ð')
    
    # Map old invalid IDs to defaults
    invalid_ids = ['FOUNDATION', 'BASE', 'CONSTANTS', 'SCENE', 'DETAILS', 
                   'PROPERTIES', 'SYSTEM', 'OVERVIEW']
    if plate_id in invalid_ids:
        return None
    
    print(f"    Warning: Invalid {plate_type} plate ID: {plate_id}")
    return None

def clean_shot_file(filepath, char_plates, env_plates):
    """Clean up a single shot file"""
    
    try:
        with open(filepath, 'r') as f:
            data = json.load(f)
        
        filename = os.path.basename(filepath)
        narrative_stage = determine_narrative_stage(filename, data)
        mappings = NARRATIVE_MAPPINGS[narrative_stage]
        
        changes_made = False
        
        # Process each prompt variant
        if 'prompt_variants' in data:
            for variant in data['prompt_variants']:
                
                # Remove embedded plate definitions - we only want IDs
                fields_to_remove = ['character_plates', 'environmental_plates', 
                                  'recommended_plates', 'available_plates']
                for field in fields_to_remove:
                    if field in variant:
                        del variant[field]
                        changes_made = True
                
                # Initialize selected_plates if missing
                if 'selected_plates' not in variant:
                    variant['selected_plates'] = {
                        'characters': {},
                        'environment': {}
                    }
                    changes_made = True
                
                # Ensure proper structure
                if 'characters' not in variant['selected_plates']:
                    variant['selected_plates']['characters'] = {}
                    changes_made = True
                if 'environment' not in variant['selected_plates']:
                    variant['selected_plates']['environment'] = {}
                    changes_made = True
                
                # Update character plates with narrative-appropriate selections
                for char_name in ['magnus', 'sigrid', 'gudrun', 'jon', 'lilja']:
                    if char_name in mappings['characters']:
                        plate_id = mappings['characters'][char_name]
                        # Validate the plate ID
                        if validate_plate_id(plate_id, char_plates, 'character'):
                            variant['selected_plates']['characters'][char_name] = plate_id
                            changes_made = True
                
                # Update environment plates
                for env_type in ['interior', 'landscape', 'sea', 'house']:
                    if env_type in mappings['environment']:
                        plate_id = mappings['environment'][env_type]
                        # Validate the plate ID
                        if validate_plate_id(plate_id, env_plates, 'environment'):
                            variant['selected_plates']['environment'][env_type] = plate_id
                            changes_made = True
                
                # Set the primary selected plate IDs for UI display
                # Character: Use magnus as default, or first available character
                if variant['selected_plates']['characters']:
                    if 'magnus' in variant['selected_plates']['characters']:
                        variant['selectedCharacterPlateId'] = variant['selected_plates']['characters']['magnus']
                    else:
                        # Use first character
                        first_char = list(variant['selected_plates']['characters'].keys())[0]
                        variant['selectedCharacterPlateId'] = variant['selected_plates']['characters'][first_char]
                    changes_made = True
                
                # Environment: Determine based on shot context
                current_env_plate = variant.get('selectedEnvironmentPlateId', '')
                
                # Interior shot detection
                is_interior = False
                if 'prompt_content' in variant:
                    prompt_lower = variant['prompt_content'].lower()
                    interior_keywords = ['interior', 'inside', 'stofa', 'baðstofa', 
                                       'room', 'house interior', 'indoor']
                    is_interior = any(kw in prompt_lower for kw in interior_keywords)
                
                # Also check current plate
                if any(x in current_env_plate for x in ['STOFA', 'BAÐSTOFA', 'BADSTOFA']):
                    is_interior = True
                
                # Sea shot detection
                is_sea = False
                if 'prompt_content' in variant:
                    sea_keywords = ['sea', 'ocean', 'water', 'rowing', 'boat', 'maritime']
                    is_sea = any(kw in prompt_lower for kw in sea_keywords)
                if 'SEA' in current_env_plate:
                    is_sea = True
                
                # Set appropriate environment plate
                if is_sea and 'sea' in variant['selected_plates']['environment']:
                    variant['selectedEnvironmentPlateId'] = variant['selected_plates']['environment']['sea']
                elif is_interior and 'interior' in variant['selected_plates']['environment']:
                    variant['selectedEnvironmentPlateId'] = variant['selected_plates']['environment']['interior']
                elif 'landscape' in variant['selected_plates']['environment']:
                    variant['selectedEnvironmentPlateId'] = variant['selected_plates']['environment']['landscape']
                else:
                    # Fallback to first available
                    if variant['selected_plates']['environment']:
                        first_env = list(variant['selected_plates']['environment'].values())[0]
                        variant['selectedEnvironmentPlateId'] = first_env
                
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
    # Load valid plate IDs
    print("Loading plate definitions...")
    char_plates, env_plates = load_plate_definitions()
    print(f"Found {len(char_plates)} character plates")
    print(f"Found {len(env_plates)} environmental plates")
    
    # Process all shot files
    shot_dir = '/Users/ingthor/Documents/stories/appdata/json/7/shots/json/'
    all_files = glob.glob(os.path.join(shot_dir, '*.json'))
    print(f"\nProcessing {len(all_files)} shot files...")
    
    updated = 0
    for i, filepath in enumerate(all_files):
        if i % 10 == 0:
            print(f"  Processing {i}/{len(all_files)}...")
        
        if clean_shot_file(filepath, char_plates, env_plates):
            updated += 1
    
    print(f"\n{'='*60}")
    print(f"COMPLETE: Updated {updated}/{len(all_files)} shot files")
    print(f"\nThe plate system is now properly structured:")
    print(f"  - All embedded plate data removed from shots")
    print(f"  - Shots now only reference plate IDs from central storage")
    print(f"  - Multiple character/environment plates properly mapped")
    print(f"  - Default master plates set for each narrative stage")
    print(f"\nShots can now be edited in the UI and will reference the")
    print(f"correct plates from the central storage.")

if __name__ == '__main__':
    main()