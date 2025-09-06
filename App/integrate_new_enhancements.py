#!/usr/bin/env python3
"""
Script to integrate new enhancement files into existing shot JSON files.
New scenes will be added as first variants and set as selected.
Fractional shots (e.g., 11.5) will be inserted between appropriate shots.
"""

import json
import os
import re
from pathlib import Path
from typing import Dict, List, Any, Tuple

# Paths
ENHANCEMENTS_DIR = "/Users/ingthor/Documents/stories/enhancements/enhancements"
SHOTS_JSON_DIR = "/Users/ingthor/Documents/stories/App/App/FilmManager/Resources/shots/json"
SHOTS_DIR = "/Users/ingthor/Documents/stories/App/App/FilmManager/Resources/shots"

def parse_enhancement_file(filepath: str) -> Dict[str, Any]:
    """Parse an enhancement file to extract scene information."""
    with open(filepath, 'r') as f:
        content = f.read()
    
    filename = os.path.basename(filepath)
    
    # Extract shot number from filename
    shot_match = re.search(r'shot[_\s]+([0-9]+\.?[0-9]*[a-z]?)', filename, re.IGNORECASE)
    if not shot_match:
        # Try alternative patterns
        shot_match = re.search(r'([0-9]+\.?[0-9]*[a-z]?)[_\s]+', filename)
    
    shot_number = shot_match.group(1) if shot_match else None
    
    # Determine if this is a new shot or variant
    is_new_shot = any(keyword in filename.lower() for keyword in [
        'point5', 'point_5', '.5', 'minus', 'shot_0', 'new'
    ])
    
    # Extract scene description
    scene_lines = []
    action_lines = []
    style_lines = []
    
    lines = content.split('\n')
    current_section = None
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
            
        # Look for section markers
        if 'SCENE:' in line.upper() or 'SETTING:' in line.upper():
            current_section = 'scene'
        elif 'ACTION:' in line.upper() or 'MOVEMENT:' in line.upper():
            current_section = 'action'
        elif 'STYLE:' in line.upper() or 'AESTHETIC:' in line.upper():
            current_section = 'style'
        elif line.startswith('---') or line.startswith('==='):
            current_section = None
        elif current_section == 'scene':
            scene_lines.append(line)
        elif current_section == 'action':
            action_lines.append(line)
        elif current_section == 'style':
            style_lines.append(line)
        elif len(scene_lines) < 3:  # Default to scene if no section
            scene_lines.append(line)
    
    # Generate variant name from filename
    variant_name = filename.replace('.txt', '').replace('_', ' ').title()
    variant_name = re.sub(r'Shot[_\s]+[0-9]+\.?[0-9]*[a-z]?[_\s]+', '', variant_name, flags=re.IGNORECASE)
    
    return {
        'filename': filename,
        'shot_number': shot_number,
        'is_new_shot': is_new_shot,
        'variant_name': variant_name[:50],  # Limit length
        'scene': ' '.join(scene_lines[:5]),  # First 5 lines for scene
        'action': ' '.join(action_lines[:3]) if action_lines else '',
        'style': ' '.join(style_lines[:2]) if style_lines else '',
        'content': content
    }

def determine_shot_placement(shot_number: str) -> Tuple[str, str]:
    """Determine where to place a shot and its sequence type."""
    if not shot_number:
        return None, 'main'
    
    # Handle negative shots (e.g., shot_minus1)
    if 'minus' in shot_number.lower() or shot_number.startswith('-'):
        return '0', 'prologue'
    
    # Extract numeric part and suffix
    match = re.match(r'([0-9]+\.?[0-9]*)([a-z]*)', shot_number)
    if not match:
        return shot_number, 'main'
    
    num_part = float(match.group(1)) if '.' in match.group(1) else int(match.group(1))
    suffix = match.group(2)
    
    # Determine sequence type based on number
    if num_part < 10:
        sequence_type = 'prologue'
    else:
        sequence_type = 'main'
    
    return shot_number, sequence_type

def load_existing_shot(shot_id: str, sequence_type: str) -> Dict[str, Any]:
    """Load an existing shot JSON file."""
    # Try multiple filename patterns
    patterns = [
        f"shot_{shot_id}_{sequence_type}*.json",
        f"shot_{shot_id}_*.json",
        f"*_{shot_id}_{sequence_type}*.json"
    ]
    
    for pattern in patterns:
        json_files = list(Path(SHOTS_JSON_DIR).glob(pattern))
        if json_files:
            with open(json_files[0], 'r') as f:
                return json.load(f), str(json_files[0])
    
    # Also check non-json directory
    for pattern in patterns:
        json_files = list(Path(SHOTS_DIR).glob(pattern))
        if json_files:
            with open(json_files[0], 'r') as f:
                return json.load(f), str(json_files[0])
    
    return None, None

def create_prompt_variant(enhancement: Dict[str, Any], shot_id: str) -> Dict[str, Any]:
    """Create a prompt variant from enhancement data."""
    return {
        "variant_id": f"{shot_id}_{enhancement['variant_name'].lower().replace(' ', '_')}",
        "variant_name": enhancement['variant_name'],
        "subject": "",  # Could extract from content
        "action": enhancement['action'],
        "scene": enhancement['scene'],
        "style": enhancement['style'],
        "camera_position": "",
        "dialogue": "",
        "negative_prompt": "",
        "recommended_plates": {
            "characters": {},
            "environment": {}
        },
        "selected_plates": {
            "characters": {},
            "environment": {}
        }
    }

def integrate_enhancements():
    """Main function to integrate all enhancements."""
    print("🎬 Starting enhancement integration...")
    
    # Get all enhancement files
    enhancement_files = list(Path(ENHANCEMENTS_DIR).glob("*.txt"))
    print(f"📁 Found {len(enhancement_files)} enhancement files")
    
    # Parse all enhancements
    enhancements = []
    for filepath in enhancement_files:
        try:
            enhancement = parse_enhancement_file(str(filepath))
            if enhancement['shot_number']:
                enhancements.append(enhancement)
                print(f"✅ Parsed: {enhancement['filename']} -> Shot {enhancement['shot_number']}")
            else:
                print(f"⚠️  Skipped: {enhancement['filename']} (no shot number)")
        except Exception as e:
            print(f"❌ Error parsing {filepath}: {e}")
    
    # Group enhancements by shot number
    shots_to_update = {}
    new_shots = []
    
    for enhancement in enhancements:
        shot_number, sequence_type = determine_shot_placement(enhancement['shot_number'])
        
        if enhancement['is_new_shot']:
            new_shots.append({
                'shot_number': shot_number,
                'sequence_type': sequence_type,
                'enhancement': enhancement
            })
        else:
            key = f"{shot_number}_{sequence_type}"
            if key not in shots_to_update:
                shots_to_update[key] = []
            shots_to_update[key].append(enhancement)
    
    print(f"\n📊 Processing {len(shots_to_update)} existing shots and {len(new_shots)} new shots")
    
    # Update existing shots with new variants
    updated_count = 0
    for shot_key, shot_enhancements in shots_to_update.items():
        parts = shot_key.split('_')
        shot_id = parts[0]
        sequence_type = parts[1] if len(parts) > 1 else 'main'
        
        # Load existing shot
        shot_data, filepath = load_existing_shot(shot_id, sequence_type)
        if not shot_data:
            print(f"⚠️  Shot {shot_id}_{sequence_type} not found, skipping")
            continue
        
        # Add new variants at the beginning
        new_variants = []
        for enhancement in shot_enhancements:
            variant = create_prompt_variant(enhancement, shot_id)
            new_variants.append(variant)
        
        # Insert new variants at the beginning
        if 'prompt_variants' in shot_data:
            # Make the first new variant the selected one
            shot_data['prompt_variants'] = new_variants + shot_data['prompt_variants']
        else:
            shot_data['prompt_variants'] = new_variants
        
        # Save updated shot
        with open(filepath, 'w') as f:
            json.dump(shot_data, f, indent=2)
        
        updated_count += 1
        print(f"✅ Updated shot {shot_id}_{sequence_type} with {len(new_variants)} new variants")
    
    # Create new shot files
    created_count = 0
    for new_shot_info in new_shots:
        shot_number = new_shot_info['shot_number']
        sequence_type = new_shot_info['sequence_type']
        enhancement = new_shot_info['enhancement']
        
        # Create shot data structure
        shot_data = {
            "shot_metadata": {
                "id": shot_number,
                "title": enhancement['variant_name'],
                "sequence_type": sequence_type,
                "duration_seconds": 3,
                "narrative_function": "enhancement",
                "stitch_from": ""
            },
            "progressive_state": "",
            "prompt_variants": [
                create_prompt_variant(enhancement, shot_number)
            ],
            "others": {
                "creator_process": "enhancement_integration",
                "source_file": enhancement['filename']
            }
        }
        
        # Determine filename
        safe_title = re.sub(r'[^a-zA-Z0-9_\-]', '_', enhancement['variant_name'][:30])
        filename = f"shot_{shot_number}_{sequence_type}_{safe_title}.json"
        filepath = os.path.join(SHOTS_JSON_DIR, filename)
        
        # Check if file already exists
        if os.path.exists(filepath):
            print(f"⚠️  File already exists: {filename}, skipping")
            continue
        
        # Save new shot
        with open(filepath, 'w') as f:
            json.dump(shot_data, f, indent=2)
        
        created_count += 1
        print(f"✅ Created new shot: {filename}")
    
    print(f"\n🎉 Integration complete!")
    print(f"   - Updated {updated_count} existing shots")
    print(f"   - Created {created_count} new shots")
    print(f"   - Total enhancements processed: {len(enhancements)}")

if __name__ == "__main__":
    integrate_enhancements()