#!/usr/bin/env python3

import re
import os
import json

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
    
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        
        if line.startswith('Progressive State:'):
            shot_data['progressive_state'] = line.split(':', 1)[1].strip()
            
        elif line.startswith('Duration:'):
            duration_match = re.search(r'(\d+)', line)
            if duration_match:
                shot_data['duration'] = int(duration_match.group(1))
                
        elif line.startswith('[STITCH') or line.startswith('[NO STITCH'):
            shot_data['stitch_from'] = line
            
        elif line.startswith('Subject:'):
            # Collect subject content - may span multiple lines
            subject_lines = [line.split(':', 1)[1].strip()]
            i += 1
            while i < len(lines) and not lines[i].strip().startswith(('Action:', 'Scene:', 'Style:')):
                if lines[i].strip():
                    subject_lines.append(lines[i].strip())
                i += 1
            shot_data['subject'] = ' '.join(subject_lines)
            i -= 1  # Back up one since we'll increment at end of loop
            
        elif line.startswith('Action:'):
            # Collect action content - may span multiple lines
            action_lines = [line.split(':', 1)[1].strip()]
            i += 1
            while i < len(lines) and not lines[i].strip().startswith(('Scene:', 'Style:', 'Dialogue:')):
                if lines[i].strip():
                    action_lines.append(lines[i].strip())
                i += 1
            shot_data['action'] = ' '.join(action_lines)
            i -= 1
            
        elif line.startswith('Scene:'):
            # Collect scene content
            scene_lines = [line.split(':', 1)[1].strip()]
            i += 1
            while i < len(lines) and not lines[i].strip().startswith(('Style:', 'Dialogue:', 'Sounds:')):
                if lines[i].strip():
                    scene_lines.append(lines[i].strip())
                i += 1
            shot_data['scene'] = ' '.join(scene_lines)
            i -= 1
            
        elif line.startswith('Style:'):
            # Collect style content
            style_lines = [line.split(':', 1)[1].strip()]
            i += 1
            while i < len(lines) and not lines[i].strip().startswith(('Dialogue:', 'Sounds:', 'Technical')):
                if lines[i].strip():
                    style_lines.append(lines[i].strip())
                i += 1
            shot_data['style'] = ' '.join(style_lines)
            i -= 1
            
        elif line.startswith('Dialogue:'):
            # Collect dialogue content
            dialogue_lines = [line.split(':', 1)[1].strip()]
            i += 1
            while i < len(lines) and not lines[i].strip().startswith(('Sounds:', 'Technical')):
                if lines[i].strip():
                    dialogue_lines.append(lines[i].strip())
                i += 1
            shot_data['dialogue'] = ' '.join(dialogue_lines)
            i -= 1
            
        elif line.startswith('Sounds:'):
            # Collect all sounds content
            sounds_lines = [line]
            i += 1
            while i < len(lines) and not lines[i].strip().startswith(('Technical')):
                if lines[i].strip():
                    sounds_lines.append(lines[i].strip())
                i += 1
            sounds_text = ' '.join(sounds_lines)
            shot_data['sounds'] = parse_sounds(sounds_text)
            i -= 1
            
        elif line.startswith('Technical'):
            shot_data['technical_negative'] = line.split(':', 1)[1].strip() if ':' in line else line
            
        elif line.startswith('Women\'s Silence:'):
            shot_data['others']['womens_silence'] = line.split(':', 1)[1].strip()
            
        elif line.startswith('Triple Reality:'):
            shot_data['others']['triple_reality'] = line.split(':', 1)[1].strip()
            
        i += 1
    
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

def convert_shots_fixed():
    raw_dir = "/Users/ingthor/Documents/stories/App/shots/raw2"
    json_dir = "/Users/ingthor/Documents/stories/App/shots/json"
    
    # Clear existing JSON files
    if os.path.exists(json_dir):
        for f in os.listdir(json_dir):
            if f.endswith('.json'):
                os.remove(os.path.join(json_dir, f))
    
    os.makedirs(json_dir, exist_ok=True)
    
    raw_files = [f for f in os.listdir(raw_dir) if f.endswith('.txt') and 'unknown' not in f]
    
    print(f"Converting {len(raw_files)} shot files with fixed parser...")
    
    for filename in sorted(raw_files):
        raw_path = os.path.join(raw_dir, filename)
        
        with open(raw_path, 'r', encoding='utf-8') as f:
            raw_content = f.read()
        
        # Parse shot metadata from filename
        if '_prologue_' in filename:
            sequence_type = 'prologue'
            shot_match = re.match(r'shot_([^_]+)_prologue_(.+)\.txt', filename)
        else:
            sequence_type = 'main_story'  
            shot_match = re.match(r'shot_([^_]+)_main_(.+)\.txt', filename)
        
        if not shot_match:
            continue
            
        shot_id = shot_match.group(1)
        shot_title = shot_match.group(2).replace('_', ' ')
        
        # Parse content
        parsed = parse_shot_content(raw_content)
        
        # Extract characters from subject/action
        characters = []
        char_matches = re.findall(r'\[([A-ZÉÍÓÚ]+)\]', parsed['subject'] + ' ' + parsed['action'])
        for char in char_matches:
            if char in ['MAGNÚS', 'SIGRID', 'GUÐRÚN', 'JÓN', 'LILJA']:
                characters.append(char)
        
        # Create JSON structure
        json_data = {
            "shot_metadata": {
                "id": shot_id,
                "name": shot_title.upper().replace(' ', '_').replace('-', '_'),
                "title": shot_title,
                "sequence_type": sequence_type,
                "duration_seconds": parsed['duration'],
                "narrative_function": parsed['progressive_state'][:50] + '...' if len(parsed['progressive_state']) > 50 else parsed['progressive_state'],
                "stitch_from": parsed['stitch_from']
            },
            
            "progressive_state": parsed['progressive_state'],
            
            "prompt_variants": [{
                "variant_id": f"{shot_id}_story_primary",
                "variant_name": f"Primary - {shot_title}",
                "intent_tags": ["story_primary"],
                "priority": 1,
                
                "subject": parsed['subject'],
                "action": parsed['action'], 
                "scene": parsed['scene'],
                "style": parsed['style'],
                "camera_position": re.search(r'(.+?)\s*\(that\'s where the camera is\)', parsed['style']).group(1) if re.search(r'\(that\'s where the camera is\)', parsed['style']) else parsed['style'],
                "dialogue": parsed['dialogue'],
                
                "audio": parsed['sounds'],
                
                "character_plates": {
                    "present": characters,
                    "referenced": []
                },
                
                "negative_prompt": parsed['technical_negative'],
                
                "video_references": []
            }],
            
            "others": parsed['others'],
            
            "notes": {
                "sequence": sequence_type,
                "characters_involved": characters,
                "original_preserved": True
            }
        }
        
        # Create JSON filename  
        json_filename = filename.replace('.txt', '.json')
        json_path = os.path.join(json_dir, json_filename)
        
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(json_data, f, indent=2, ensure_ascii=False)
        
        print(f"✓ {filename}")
    
    # Count results
    json_files = [f for f in os.listdir(json_dir) if f.endswith('.json')]
    prologue_count = len([f for f in json_files if '_prologue_' in f])
    main_count = len([f for f in json_files if '_main_' in f])
    
    print(f"\n✅ COMPLETE: {len(json_files)} JSON files")
    print(f"📁 Prologue: {prologue_count}")
    print(f"📁 Main story: {main_count}")

if __name__ == "__main__":
    convert_shots_fixed()