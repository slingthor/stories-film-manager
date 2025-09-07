#!/usr/bin/env python3

import json
import os
import re
from pathlib import Path

# Define the aspect ratio rules
def get_aspect_ratio(shot_id):
    """
    Determine aspect ratio based on shot ID according to the evolution timeline:
    * Prologue: 1.85:1 (false freedom)
    * Shots 1-7: 4:3 (trap springs) 
    * Shots 8-10: 1:1 (counting violence)
    * Shots 11-42: Return to 4:3
    * Shot 43: 1:1 (violence)
    * Shots 49-50: 1:1 (incest threat)
    * Shot 59+: 2.39:1 explosion
    """
    
    # Extract the numeric part from shot ID
    # Handle various formats: "0a", "1", "1a", "23b", "-1", "5p", etc.
    
    # Check if it's a prologue shot
    if "prologue" in shot_id.lower():
        return "1.85:1"
    
    # Extract the main shot number
    match = re.search(r'shot_(-?\d+)', shot_id)
    if not match:
        print(f"Could not parse shot ID: {shot_id}")
        return "16:9"  # Default
    
    shot_num = int(match.group(1))
    
    # Handle negative numbers (like shot_-1)
    if shot_num < 0:
        return "1.85:1"  # Treat as prologue
    
    # Apply the rules
    if shot_num == 0:
        return "1.85:1"  # Prologue shots (0a, 0b, etc.)
    elif 1 <= shot_num <= 7:
        return "4:3"
    elif 8 <= shot_num <= 10:
        return "1:1"
    elif 11 <= shot_num <= 42:
        return "4:3"
    elif shot_num == 43:
        return "1:1"
    elif 44 <= shot_num <= 48:
        return "4:3"  # Return to 4:3 between violence moments
    elif 49 <= shot_num <= 50:
        return "1:1"
    elif 51 <= shot_num <= 58:
        return "4:3"  # Back to 4:3 before explosion
    elif shot_num >= 59:
        return "2.39:1"
    else:
        return "16:9"  # Default fallback

def update_json_file(filepath):
    """Update the aspect ratio in a single JSON file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Get the shot ID from the filename
        filename = os.path.basename(filepath)
        shot_id = filename.replace('.json', '')
        
        # Determine the correct aspect ratio
        aspect_ratio = get_aspect_ratio(shot_id)
        
        # Update the shot metadata
        if 'shot_metadata' in data:
            old_ratio = data['shot_metadata'].get('aspect_ratio', 'not set')
            data['shot_metadata']['aspect_ratio'] = aspect_ratio
            
            # Also ensure it exists at the top level if the app expects it there
            data['aspect_ratio'] = aspect_ratio
            
            print(f"Updated {shot_id}: {old_ratio} -> {aspect_ratio}")
        else:
            print(f"Warning: No shot_metadata in {filename}")
            # Try to add it anyway at the top level
            data['aspect_ratio'] = aspect_ratio
        
        # Write back to file
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        return True
    except Exception as e:
        print(f"Error processing {filepath}: {e}")
        return False

def main():
    # Path to the shots directory
    shots_dir = Path("/Users/ingthor/Documents/stories/appdata/json/5/shots/json")
    
    if not shots_dir.exists():
        print(f"Directory not found: {shots_dir}")
        print("Checking for alternative paths...")
        
        # Check version directories
        for version in range(1, 10):
            alt_path = Path(f"/Users/ingthor/Documents/stories/appdata/json/{version}/shots/json")
            if alt_path.exists():
                print(f"Found version {version} at: {alt_path}")
                shots_dir = alt_path
                break
        else:
            print("No valid shots directory found!")
            return
    
    print(f"Processing shots in: {shots_dir}")
    print("=" * 60)
    print("Aspect Ratio Evolution Timeline:")
    print("  Prologue: 1.85:1 (false freedom)")
    print("  Shots 1-7: 4:3 (trap springs)")
    print("  Shots 8-10: 1:1 (counting violence)")
    print("  Shots 11-42: 4:3 (return)")
    print("  Shot 43: 1:1 (violence)")
    print("  Shots 49-50: 1:1 (incest threat)")
    print("  Shot 59+: 2.39:1 (explosion)")
    print("=" * 60)
    
    # Get all JSON files
    json_files = list(shots_dir.glob("*.json"))
    print(f"Found {len(json_files)} JSON files")
    
    # Update each file
    success_count = 0
    for filepath in sorted(json_files):
        if update_json_file(filepath):
            success_count += 1
    
    print("=" * 60)
    print(f"Successfully updated {success_count}/{len(json_files)} files")
    
    # Show summary of aspect ratios
    print("\nAspect Ratio Summary:")
    ratio_counts = {}
    for filepath in json_files:
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                data = json.load(f)
                ratio = data.get('shot_metadata', {}).get('aspect_ratio', data.get('aspect_ratio', 'unknown'))
                ratio_counts[ratio] = ratio_counts.get(ratio, 0) + 1
        except:
            pass
    
    for ratio, count in sorted(ratio_counts.items()):
        print(f"  {ratio}: {count} shots")

if __name__ == "__main__":
    main()