#!/usr/bin/env python3

import re
import os
import json
from pathlib import Path

def parse_shot_content(content):
    """Parse shot content into structured data"""
    lines = content.strip().split('\n')
    
    shot_data = {
        'progressive_state': '',
        'duration': 8,
        'stitch_from': '',
        'subject': '',
        'action': '',
        'scene': '',
        'style': '',
        'dialogue': '',
        'sounds': {'primary': [], 'ambient': [], 'absent': []},
        'technical_negative': '',
        'others': {}
    }
    
    current_section = None
    current_content = []
    
    for line in lines:
        line = line.strip()
        
        # Skip empty lines
        if not line:
            if current_section and current_content:
                # Save previous section
                content_text = ' '.join(current_content)
                if current_section == 'Progressive State':
                    shot_data['progressive_state'] = content_text
                elif current_section == 'Duration':
                    duration_match = re.search(r'(\d+)', content_text)
                    if duration_match:
                        shot_data['duration'] = int(duration_match.group(1))
                elif current_section == 'STITCH':
                    shot_data['stitch_from'] = content_text
                elif current_section == 'Subject':
                    shot_data['subject'] = content_text
                elif current_section == 'Action':
                    shot_data['action'] = content_text
                elif current_section == 'Scene':
                    shot_data['scene'] = content_text
                elif current_section == 'Style':
                    shot_data['style'] = content_text
                elif current_section == 'Dialogue':
                    shot_data['dialogue'] = content_text
                elif current_section == 'Sounds':
                    shot_data['sounds'] = parse_sounds(content_text)
                elif current_section == 'Technical':
                    shot_data['technical_negative'] = content_text
                else:
                    # Store in others section
                    shot_data['others'][current_section] = content_text
                
                current_content = []
            continue
            
        # Check for section headers
        if line.startswith('Progressive State:'):
            current_section = 'Progressive State'
            current_content = [line.split(':', 1)[1].strip()]
        elif line.startswith('Duration:'):
            current_section = 'Duration'
            current_content = [line.split(':', 1)[1].strip()]
        elif line.startswith('[STITCH') or line.startswith('[NO STITCH'):
            current_section = 'STITCH'
            current_content = [line]
        elif line.startswith('Subject:'):
            current_section = 'Subject'
            current_content = [line.split(':', 1)[1].strip()]
        elif line.startswith('Action:'):
            current_section = 'Action'
            current_content = [line.split(':', 1)[1].strip()]
        elif line.startswith('Scene:'):
            current_section = 'Scene'
            current_content = [line.split(':', 1)[1].strip()]
        elif line.startswith('Style:'):
            current_section = 'Style'
            current_content = [line.split(':', 1)[1].strip()]
        elif line.startswith('Dialogue:'):
            current_section = 'Dialogue'
            current_content = [line.split(':', 1)[1].strip()]
        elif line.startswith('Sounds:'):
            current_section = 'Sounds'
            current_content = [line.split(':', 1)[1].strip()]
        elif line.startswith('Technical'):
            current_section = 'Technical'
            current_content = [line.split(':', 1)[1].strip() if ':' in line else line]
        elif line.startswith('Women\'s Silence:'):
            current_section = 'Women\'s Silence'
            current_content = [line.split(':', 1)[1].strip()]
        elif line.startswith('Triple Reality:'):
            current_section = 'Triple Reality'
            current_content = [line.split(':', 1)[1].strip()]
        else:
            # Continue current section
            if current_section:
                current_content.append(line)
    
    # Handle final section
    if current_section and current_content:
        content_text = ' '.join(current_content)
        if current_section == 'Progressive State':
            shot_data['progressive_state'] = content_text
        elif current_section == 'Subject':
            shot_data['subject'] = content_text
        elif current_section == 'Action':
            shot_data['action'] = content_text
        elif current_section == 'Scene':
            shot_data['scene'] = content_text
        elif current_section == 'Style':
            shot_data['style'] = content_text
        elif current_section == 'Dialogue':
            shot_data['dialogue'] = content_text
        elif current_section == 'Sounds':
            shot_data['sounds'] = parse_sounds(content_text)
        elif current_section == 'Technical':
            shot_data['technical_negative'] = content_text
        else:
            shot_data['others'][current_section] = content_text
    
    return shot_data

def parse_sounds(sounds_text):
    """Parse sounds section into structured format"""
    sounds = {'primary': [], 'ambient': [], 'absent': []}
    
    # Extract PRIMARY sounds
    primary_match = re.search(r'\[PRIMARY:\s*([^\]]+)\]', sounds_text)
    if primary_match:
        primary_text = primary_match.group(1)
        sounds['primary'] = [s.strip() for s in primary_text.split(',')]
    
    # Extract AMBIENT sounds
    ambient_match = re.search(r'\[AMBIENT:\s*([^\]]+)\]', sounds_text)
    if ambient_match:
        ambient_text = ambient_match.group(1)
        sounds['ambient'] = [s.strip() for s in ambient_text.split(',')]
    
    # Extract ABSENT sounds
    absent_match = re.search(r'\[ABSENT:\s*([^\]]+)\]', sounds_text)
    if absent_match:
        absent_text = absent_match.group(1)
        sounds['absent'] = [s.strip() for s in absent_text.split(',')]
    
    return sounds

def extract_characters(subject, action):
    """Extract character references from subject and action text"""
    characters = []
    
    # Look for character references in brackets
    char_matches = re.findall(r'\[([A-Z][A-ZÉÍÓÚ]*)\]', subject + ' ' + action)
    
    character_map = {
        'MAGNÚS': 'MAGNÚS',
        'SIGRID': 'SIGRID', 
        'GUÐRÚN': 'GUÐRÚN',
        'JÓN': 'JÓN',
        'LILJA': 'LILJA'
    }
    
    for char in char_matches:
        if char in character_map:
            characters.append(character_map[char])
    
    return characters

def determine_character_plates(characters, sequence_type, film_position):
    """Determine appropriate character plates based on film position"""
    plates = {}
    
    for char in characters:
        if char == 'MAGNÚS':
            if sequence_type == 'prologue':
                plates[char] = 'MAGNÚS-AUTHORITY'
            elif film_position < 40:
                plates[char] = 'MAGNÚS-CONFUSED'
            elif film_position < 70:
                plates[char] = 'MAGNÚS-PREDATOR'
            else:
                plates[char] = 'MAGNÚS-TRANSFORMING'
        
        elif char == 'SIGRID':
            if sequence_type == 'prologue':
                plates[char] = 'SIGRID-PURE'
            elif film_position < 50:
                plates[char] = 'SIGRID-MARKED'
            elif film_position < 80:
                plates[char] = 'SIGRID-ORACLE'
            else:
                plates[char] = 'SIGRID-TRANSFORMING'
                
        elif char == 'GUÐRÚN':
            if sequence_type == 'prologue':
                plates[char] = 'GUÐRÚN-ABUNDANT'
            elif film_position < 60:
                plates[char] = 'GUÐRÚN-PRODUCING'
            else:
                plates[char] = 'GUÐRÚN-SACRIFICING'
                
        elif char == 'JÓN':
            if sequence_type == 'prologue':
                plates[char] = 'JÓN-MILD'
            elif film_position < 70:
                plates[char] = 'JÓN-PROPHETIC'
            else:
                plates[char] = 'JÓN-TRANSFORMING'
                
        elif char == 'LILJA':
            if sequence_type == 'prologue':
                plates[char] = 'LILJA-PURE'
            elif film_position < 70:
                plates[char] = 'LILJA-SENSING'
            else:
                plates[char] = 'LILJA-TRANSFORMING'
    
    return plates

def determine_environmental_plates(scene, sequence_type):
    """Determine environmental plates based on scene description"""
    plates = {}
    
    scene_lower = scene.lower()
    
    # Landscape
    if 'cliff' in scene_lower:
        plates['landscape'] = 'WESTFJORDS-CLIFF'
    elif 'beach' in scene_lower:
        plates['landscape'] = 'WESTFJORDS-BEACH'
    elif 'ocean' in scene_lower:
        plates['landscape'] = 'WESTFJORDS-MARITIME'
    elif 'interior' in scene_lower or 'inside' in scene_lower:
        plates['landscape'] = 'BAÐSTOFA-INTERIOR'
    else:
        plates['landscape'] = 'WESTFJORDS-GENERAL'
    
    # Weather
    if sequence_type == 'prologue':
        plates['weather'] = 'COOPERATIVE-SUPERNATURAL'
    else:
        if 'storm' in scene_lower:
            plates['weather'] = 'HOSTILE-WINTER'
        else:
            plates['weather'] = 'WINTER-SURVIVAL'
    
    # Lighting
    if 'dawn' in scene_lower:
        plates['lighting'] = 'DAWN-LIGHT'
    elif 'evening' in scene_lower or 'sunset' in scene_lower:
        plates['lighting'] = 'EVENING-LIGHT'
    elif 'darkness' in scene_lower or 'dark' in scene_lower:
        plates['lighting'] = 'DARKNESS'
    else:
        plates['lighting'] = 'NATURAL-LIGHT'
    
    return plates

def convert_shots():
    raw_dir = "/Users/ingthor/Documents/stories/App/shots/raw2"
    json_dir = "/Users/ingthor/Documents/stories/App/shots/json"
    
    # Create output directory
    os.makedirs(json_dir, exist_ok=True)
    
    # Get all raw files
    raw_files = [f for f in os.listdir(raw_dir) if f.endswith('.txt')]
    
    print(f"Converting {len(raw_files)} shot files...")
    
    for filename in sorted(raw_files):
        raw_path = os.path.join(raw_dir, filename)
        
        # Skip unknown files
        if 'unknown' in filename:
            continue
            
        # Read raw content
        with open(raw_path, 'r', encoding='utf-8') as f:
            raw_content = f.read()
        
        # Parse first line for shot metadata
        lines = raw_content.strip().split('\n')
        if not lines:
            continue
            
        first_line = lines[0].strip()
        shot_match = re.match(r'SHOT\s+([^:]+):\s*(.+)', first_line)
        
        if not shot_match:
            continue
            
        shot_id = shot_match.group(1).strip()
        shot_title = shot_match.group(2).strip()
        
        # Determine sequence type
        sequence_type = 'prologue' if '_prologue_' in filename else 'main_story'
        
        # Parse content
        parsed = parse_shot_content(raw_content)
        
        # Extract characters
        characters = extract_characters(parsed['subject'], parsed['action'])
        
        # Calculate film position (rough estimate)
        if sequence_type == 'prologue':
            # Prologue is roughly 0-25%
            film_position = min(25.0, len(os.listdir(json_dir)) * 1.5)
        else:
            # Main story is 25-100%
            film_position = 25.0 + (len([f for f in os.listdir(json_dir) if 'main' in f]) * 0.8)
        
        # Create JSON structure
        json_data = {
            "shot_metadata": {
                "id": shot_id,
                "name": shot_title.upper().replace(' ', '_').replace('-', '_'),
                "title": shot_title,
                "sequence_type": sequence_type,
                "duration_seconds": parsed['duration'],
                "film_position_percentage": round(film_position, 1),
                "narrative_function": determine_narrative_function(shot_title, sequence_type),
                "story_significance": determine_significance(shot_title),
                "realm_classification": {
                    "physical_percentage": 85.0,
                    "psychological_percentage": 20.0,
                    "mythological_percentage": 15.0
                },
                "stitch_from": parsed['stitch_from']
            },
            
            "progressive_state": parsed['progressive_state'],
            
            "prompt_variants": [{
                "variant_id": f"{shot_id}_story_primary",
                "variant_name": f"Primary Narrative - {shot_title}",
                "intent_tags": ["story_primary"],
                "priority": 1,
                
                "subject": parsed['subject'],
                "action": parsed['action'],
                "scene": parsed['scene'],
                "style": parsed['style'],
                "camera_position": extract_camera_position(parsed['style']),
                "dialogue": parsed['dialogue'],
                
                "audio": {
                    "primary_sounds": parsed['sounds']['primary'],
                    "ambient_sounds": parsed['sounds']['ambient'],
                    "absent_sounds": parsed['sounds']['absent']
                },
                
                "character_plates": {
                    "present": list(determine_character_plates(characters, sequence_type, film_position).values()),
                    "referenced": []
                },
                
                "environmental_plates": determine_environmental_plates(parsed['scene'], sequence_type),
                
                "negative_prompt": parsed['technical_negative'],
                
                "video_references": []
            }],
            
            "others": parsed['others'],
            
            "notes": {
                "thematic_purpose": determine_thematic_purpose(shot_title, sequence_type),
                "original_content_preserved": True
            }
        }
        
        # Create JSON filename
        json_filename = filename.replace('.txt', '.json')
        json_path = os.path.join(json_dir, json_filename)
        
        # Write JSON file
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(json_data, f, indent=2, ensure_ascii=False)
        
        print(f"Converted: {filename} -> {json_filename}")
    
    # Final verification
    json_files = [f for f in os.listdir(json_dir) if f.endswith('.json')]
    print(f"\nTotal JSON files created: {len(json_files)}")
    
    prologue_json = len([f for f in json_files if '_prologue_' in f])
    main_json = len([f for f in json_files if '_main_' in f])
    
    print(f"Prologue JSON: {prologue_json}")
    print(f"Main story JSON: {main_json}")

def extract_camera_position(style_text):
    """Extract camera position from style description"""
    camera_match = re.search(r'\(that\'s where the camera is\)', style_text)
    if camera_match:
        # Get text before the camera position marker
        before_marker = style_text[:camera_match.start()].strip()
        return before_marker
    return style_text

def determine_narrative_function(title, sequence_type):
    """Determine narrative function based on title and sequence"""
    title_lower = title.lower()
    
    if 'counting' in title_lower:
        return 'Mathematical impossibility establishment'
    elif 'breathing' in title_lower:
        return 'House consciousness revelation'  
    elif 'transformation' in title_lower:
        return 'Species change documentation'
    elif 'raven' in title_lower:
        return 'Witness preparation and escape'
    elif sequence_type == 'prologue':
        return 'Predatory seduction - abundance too perfect'
    else:
        return 'Reality breakdown progression'

def determine_significance(title):
    """Determine story significance level"""
    title_lower = title.lower()
    
    critical_words = ['counting', 'transformation', 'flash', 'camera recognizes', 'breathing house']
    if any(word in title_lower for word in critical_words):
        return 'universal_masterpiece'
    elif any(word in title_lower for word in ['whale', 'feast', 'raven', 'light']):
        return 'high_impact'
    else:
        return 'supporting'

def determine_thematic_purpose(title, sequence_type):
    """Determine thematic purpose"""
    title_lower = title.lower()
    
    if 'counting' in title_lower:
        return 'Administrative violence through mathematical contamination'
    elif 'breathing' in title_lower:
        return 'House consciousness as protective landvættir'
    elif 'transformation' in title_lower:
        return 'Species change enabling consciousness preservation'
    elif sequence_type == 'prologue':
        return 'False abundance establishing predatory seduction'
    else:
        return 'Reality breakdown enabling transcendence'

if __name__ == "__main__":
    convert_shots()