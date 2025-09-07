#!/usr/bin/env python3
"""
Add Aspect Ratios Script
Adds aspect ratio data to shot JSON files based on the ASPECT_RATIO_EVOLUTION_TECHNICAL_SPEC.
"""

import json
import os
import re
from pathlib import Path

SHOT_JSON_DIR = '/Users/ingthor/Documents/stories/appdata/json/7/shots/json'

def get_aspect_ratio_for_shot(shot_id: str, sequence_type: str = "main_story") -> str:
    """Get the appropriate aspect ratio for a shot based on the technical spec."""
    
    # Handle prologue shots
    if sequence_type == "prologue" or "prologue" in shot_id.lower():
        return "1.85:1"  # False freedom
    
    # Extract numeric shot number
    shot_num_match = re.search(r'(\d+)', shot_id)
    if not shot_num_match:
        return "4:3"  # Default
    
    shot_num = int(shot_num_match.group(1))
    
    # Apply aspect ratio evolution rules
    if 1 <= shot_num <= 7:
        return "4:3"  # Trap springs
    elif 8 <= shot_num <= 10:
        return "1:1"  # Counting violence
    elif 11 <= shot_num <= 42:
        return "4:3"  # Return to containment
    elif shot_num == 43:
        return "1:1"  # Violence precision
    elif 44 <= shot_num <= 48:
        return "4:3"  # Domestic continuation
    elif 49 <= shot_num <= 50:
        return "1:1"  # Incest threat
    elif 51 <= shot_num <= 58:
        return "4:3"  # Final containment
    elif shot_num >= 59:
        return "2.39:1"  # Explosive liberation
    else:
        return "4:3"  # Default fallback

def add_aspect_ratio_to_shot(shot_file_path: str) -> bool:
    """Add aspect ratio to a single shot JSON file."""
    with open(shot_file_path, 'r', encoding='utf-8') as f:
        shot_data = json.load(f)
    
    # Get shot metadata
    shot_metadata = shot_data.get('shot_metadata', {})
    shot_id = shot_metadata.get('id', '')
    sequence_type = shot_metadata.get('sequence_type', 'main_story')
    
    # Skip if aspect_ratio already exists
    if 'aspect_ratio' in shot_data:
        return False
    
    # Determine aspect ratio
    aspect_ratio = get_aspect_ratio_for_shot(shot_id, sequence_type)
    
    # Add aspect ratio to shot data
    shot_data['aspect_ratio'] = aspect_ratio
    
    # Write back the updated file
    with open(shot_file_path, 'w', encoding='utf-8') as f:
        json.dump(shot_data, f, indent=2, ensure_ascii=False)
    
    return True

def add_aspect_ratios_to_all_shots():
    """Add aspect ratios to all shot JSON files."""
    print(f"Adding aspect ratios to shots in {SHOT_JSON_DIR}...")
    
    if not os.path.exists(SHOT_JSON_DIR):
        print(f"Shot directory not found: {SHOT_JSON_DIR}")
        return
    
    shot_files = [f for f in Path(SHOT_JSON_DIR).glob('*.json') if 'shot_' in f.name.lower()]
    print(f"Found {len(shot_files)} shot files")
    
    updated_count = 0
    aspect_ratio_counts = {}
    
    for shot_file in shot_files:
        try:
            filename = os.path.basename(shot_file)
            
            if add_aspect_ratio_to_shot(str(shot_file)):
                # Read back to get the aspect ratio that was added
                with open(shot_file, 'r', encoding='utf-8') as f:
                    shot_data = json.load(f)
                    aspect_ratio = shot_data.get('aspect_ratio', 'unknown')
                    
                # Count aspect ratios
                aspect_ratio_counts[aspect_ratio] = aspect_ratio_counts.get(aspect_ratio, 0) + 1
                
                updated_count += 1
                
                # Extract shot info for reporting
                shot_metadata = shot_data.get('shot_metadata', {})
                shot_id = shot_metadata.get('id', '')
                sequence_type = shot_metadata.get('sequence_type', '')
                
                print(f"  Shot {shot_id} ({sequence_type}): {aspect_ratio}")
            
            if updated_count % 20 == 0 and updated_count > 0:
                print(f"  Progress: {updated_count} files updated...")
                
        except Exception as e:
            print(f"Error updating {shot_file}: {e}")
    
    print(f"\nAspect ratio assignment complete:")
    print(f"- Total files updated: {updated_count}")
    print(f"\nAspect ratio distribution:")
    for ratio, count in sorted(aspect_ratio_counts.items()):
        print(f"  {ratio}: {count} shots")

if __name__ == "__main__":
    add_aspect_ratios_to_all_shots()