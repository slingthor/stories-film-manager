#!/usr/bin/env python3
"""
Update plate JSON files to use actual plate IDs in brackets instead of generic base types.
For example: "[Seeing base]" -> "[JON-SEEING]" 
"""

import json
import re
from pathlib import Path

def load_json_file(file_path):
    """Load JSON file and return data"""
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json_file(file_path, data):
    """Save data to JSON file with proper formatting"""
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

def find_master_plates(plates_data):
    """Find all master plates in the data"""
    masters = {}
    for plate_id, plate_data in plates_data.get('plate_index', {}).items():
        if plate_data.get('is_master', False):
            # Extract character name for character plates
            if 'character' in plate_data:
                char_name = plate_data['character'].upper()
                masters[char_name] = plate_id
            else:
                # For environmental plates, use the plate name pattern
                if 'MASTER' in plate_id or plate_id in ['SEA-DIVINE', 'STOFA-DOMESTIC', 'SEA-EXTRACTED', 'STOFA-BODY', 'SEA-ACCUSATION']:
                    base_name = plate_id.replace('-MASTER', '').split('-')[0]
                    masters[base_name] = plate_id
    return masters

def find_base_plate_mappings(plates_data):
    """Create mapping from base type to actual plate IDs"""
    mappings = {
        # Environmental mappings
        'Divine base': 'SEA-DIVINE',
        'Master base': 'WESTFJORDS-MASTER',  # Could be multiple, pick one as default
        'Organic base': 'STOFA-BODY',
        'Body base': 'STOFA-BODY', 
        'Domestic base': 'STOFA-DOMESTIC',
        'Contaminated base': 'SEA-ACCUSATION',
        'Accusation base': 'SEA-ACCUSATION',
        'Extracted base': 'SEA-EXTRACTED',
        'Battle base': 'SEA-EXTRACTED',  # SEA-BATTLE references extracted base
        'Crystallizing base': 'STOFA-CRYSTALLIZING',
        'Cleft base': 'STOFA-CRYSTALLIZING',  # STOFA-CRYSTALLIZING seems to be the cleft base
        'Cliff base': 'STOFA-CLIFF',
        'Stirring base': 'STOFA-STIRRING',
        'Geological base': 'HOUSE-GEOLOGICAL', 
        'Traditional base': 'HOUSE-TRADITIONAL',
        
        # Character base types - we'll need to determine these based on the actual data
    }
    
    # Find character base mappings by looking at existing plates
    for plate_id, plate_data in plates_data.get('plate_index', {}).items():
        desc = plate_data.get('description', '')
        if '[' in desc and ']' in desc:
            # Extract the base reference
            match = re.search(r'\[([^\]]+)\]', desc)
            if match:
                base_ref = match.group(1)
                if 'character' in plate_data:
                    char = plate_data['character'].upper()
                    
                    # Map common character base patterns
                    if 'base' in base_ref.lower():
                        if 'seeing' in base_ref.lower():
                            mappings['Seeing base'] = f'{char}-SEEING'
                        elif 'rising' in base_ref.lower():
                            mappings['Rising base'] = f'{char}-RISING'
                        elif 'mastering' in base_ref.lower():
                            mappings['Mastering base'] = f'{char}-MASTER'
                        elif 'master' in base_ref.lower():
                            mappings[base_ref] = f'{char}-MASTER'
                        elif 'sensing' in base_ref.lower():
                            mappings['Sensing base'] = 'LILJA-SENSING'
                        elif 'evolving' in base_ref.lower():
                            mappings['Evolving base'] = 'LILJA-EVOLVING'
                        elif 'communicating' in base_ref.lower():
                            mappings['Communicating base'] = 'LILJA-COMMUNICATING'
                        elif 'harmonic' in base_ref.lower():
                            mappings['Harmonic base'] = 'LILJA-HARMONIC'
                        elif 'prophesying' in base_ref.lower():
                            mappings['Prophesying base'] = 'LILJA-PROPHESYING'
                        elif 'wondering' in base_ref.lower():
                            mappings['Wondering base'] = 'LILJA-WONDERING'
                        elif 'producing' in base_ref.lower():
                            mappings['Producing base'] = f'{char}-PRODUCING'
                        elif 'wearing' in base_ref.lower():
                            mappings['Wearing base'] = 'GUDRUN-WEARING'
                        elif 'walking' in base_ref.lower():
                            mappings['Walking base'] = 'GUDRUN-WALKING'
                        elif 'abundant' in base_ref.lower():
                            mappings['Abundant base'] = 'GUDRUN-ABUNDANT'
                        elif 'returning' in base_ref.lower():
                            mappings['Returning base'] = 'GUDRUN-RETURNING'
                        elif 'crowned' in base_ref.lower():
                            mappings['Crowned base'] = 'GUDRUN-CROWNED'
                        elif 'beaten' in base_ref.lower():
                            mappings['Beaten base'] = 'GUDRUN-BEATEN'
                        elif 'authority' in base_ref.lower():
                            mappings['Authority base'] = 'MAGNUS-AUTHORITY'
                        elif 'injured' in base_ref.lower():
                            mappings['Injured base'] = 'MAGNUS-INJURED'
                        elif 'pure' in base_ref.lower():
                            mappings['Pure base'] = f'{char}-PURE'
                        elif 'variable' in base_ref.lower():
                            mappings['Variable base'] = f'{char}-MASTER'
    
    return mappings

def update_plate_references(plates_data, mappings):
    """Update plate descriptions to use actual plate IDs instead of base type names"""
    updated_count = 0
    
    for plate_id, plate_data in plates_data.get('plate_index', {}).items():
        desc = plate_data.get('description', '')
        if '[' in desc and ']' in desc:
            # Find all bracket references
            matches = re.findall(r'\[([^\]]+)\]', desc)
            
            for match in matches:
                if match in mappings:
                    # Replace the generic base type with actual plate ID
                    old_ref = f'[{match}]'
                    new_ref = f'[{mappings[match]}]'
                    desc = desc.replace(old_ref, new_ref)
                    updated_count += 1
                    print(f"  {plate_id}: {old_ref} -> {new_ref}")
            
            plate_data['description'] = desc
    
    return updated_count

def main():
    # Paths to the plate files
    char_file = Path('/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json')
    env_file = Path('/Users/ingthor/Documents/stories/appdata/json/7/plates/environmental_plates_complete.json')
    
    print("Loading plate data...")
    char_data = load_json_file(char_file)
    env_data = load_json_file(env_file)
    
    # Combine all plate data for comprehensive mapping
    all_plates = {
        **char_data.get('plate_index', {}),
        **env_data.get('plate_index', {})
    }
    combined_data = {'plate_index': all_plates}
    
    print("Finding base plate mappings...")
    mappings = find_base_plate_mappings(combined_data)
    
    print(f"Found {len(mappings)} base mappings:")
    for base_type, plate_id in mappings.items():
        print(f"  {base_type} -> {plate_id}")
    
    print("\nUpdating character plates...")
    char_updates = update_plate_references(char_data, mappings)
    
    print("\nUpdating environmental plates...")
    env_updates = update_plate_references(env_data, mappings)
    
    print(f"\nTotal updates: {char_updates + env_updates}")
    
    if char_updates > 0:
        print(f"Saving character plates with {char_updates} updates...")
        save_json_file(char_file, char_data)
    
    if env_updates > 0:
        print(f"Saving environmental plates with {env_updates} updates...")
        save_json_file(env_file, env_data)
    
    print("Done!")

if __name__ == '__main__':
    main()