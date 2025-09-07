#!/usr/bin/env python3
"""
Fix Environmental Plate Categories
Sets proper categories for environmental plates based on their names/IDs.
"""

import json
import os

ENV_PLATES_PATH = '/Users/ingthor/Documents/stories/appdata/json/7/plates/environmental_plates_index.json'

def fix_environmental_categories():
    """Fix empty categories in environmental plates."""
    
    with open(ENV_PLATES_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    plate_index = data.get('plate_index', {})
    fixed_count = 0
    
    for plate_id, plate_data in plate_index.items():
        if plate_data.get('category', '') == '':
            # Determine category from plate ID
            if plate_id.startswith('WESTFJORDS'):
                category = 'Westfjords'
            elif plate_id.startswith('HOUSE'):
                category = 'House'
            elif plate_id.startswith('STOFA') or plate_id.startswith('BAÐSTOFA'):
                category = 'Interior'
            elif plate_id.startswith('SEA'):
                category = 'Maritime'
            else:
                category = 'Environment'
            
            plate_data['category'] = category
            fixed_count += 1
            print(f"Fixed {plate_id}: category = '{category}'")
    
    # Save the updated file
    with open(ENV_PLATES_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    print(f"\nFixed {fixed_count} environmental plates with proper categories")
    
    # Show category distribution
    categories = {}
    for plate_data in plate_index.values():
        cat = plate_data.get('category', 'Unknown')
        categories[cat] = categories.get(cat, 0) + 1
    
    print("\nCategory distribution:")
    for cat, count in sorted(categories.items()):
        print(f"  {cat}: {count} plates")

if __name__ == "__main__":
    fix_environmental_categories()