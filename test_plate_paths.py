#!/usr/bin/env python3
"""
Test Plate Path Changes
Verify that the new plate files exist and are properly structured.
"""

import json
import os

def test_plate_paths():
    """Test the new plate path structure."""
    
    base_path = "/Users/ingthor/Documents/stories/appdata/json/7/plates"
    
    # Check if new paths exist
    char_path = os.path.join(base_path, "character_plates_index.json")
    env_path = os.path.join(base_path, "environmental_plates_index.json")
    
    print("🧪 Testing New Plate Path Structure")
    print(f"Base path: {base_path}")
    print(f"Character plates: {char_path}")
    print(f"Environmental plates: {env_path}")
    
    # Test character plates
    if os.path.exists(char_path):
        print("✅ Character plates file exists")
        with open(char_path, 'r') as f:
            char_data = json.load(f)
        
        plates = char_data.get('plate_index', {})
        print(f"   Found {len(plates)} character plates")
        
        # Show first few plates
        for i, (plate_id, plate_info) in enumerate(list(plates.items())[:3]):
            character = plate_info.get('character', 'Unknown')
            name = plate_info.get('name', 'Unknown')
            print(f"   - {plate_id}: {character} - {name}")
    else:
        print("❌ Character plates file missing")
    
    # Test environmental plates
    if os.path.exists(env_path):
        print("✅ Environmental plates file exists")
        with open(env_path, 'r') as f:
            env_data = json.load(f)
        
        plates = env_data.get('plate_index', {})
        print(f"   Found {len(plates)} environmental plates")
        
        # Show all environmental plates
        for plate_id, plate_info in plates.items():
            category = plate_info.get('category', 'Unknown')
            name = plate_info.get('name', 'Unknown')
            print(f"   - {plate_id}: {category} - {name}")
    else:
        print("❌ Environmental plates file missing")
    
    # Check that old directory is gone
    old_path = "/Users/ingthor/Documents/stories/appdata/json/7/plate_indices"
    if os.path.exists(old_path):
        print(f"⚠️  Old directory still exists: {old_path}")
    else:
        print("✅ Old plate_indices directory successfully removed")

if __name__ == "__main__":
    test_plate_paths()