#!/usr/bin/env python3
"""
Parse plate files and create JSON index files for shot-to-plate mapping
"""

import json
import re
import os
from pathlib import Path

# Base paths
ENHANCEMENT_PATH = "/Users/ingthor/Documents/stories/enhancements"
APP_PATH = "/Users/ingthor/Documents/stories/App"
SHOTS_PATH = f"{APP_PATH}/App/FilmManager/Resources/shots/json"

def parse_character_plates():
    """Parse all character plate files and extract plate information"""
    
    character_files = {
        "magnus": "magnus_advanced_character_plates_system.txt",
        "sigrid": "sigrid_advanced_character_plates_system.txt", 
        "gudrun": "gudrun_advanced_character_plates_system.txt",
        "jon": "jon_advanced_character_plates_system.txt",
        "lilja": "lilja_complete_character_plates_expanded.txt"
    }
    
    plate_index = {}
    
    for character, filename in character_files.items():
        filepath = Path(ENHANCEMENT_PATH) / filename
        
        if not filepath.exists():
            print(f"Warning: {filepath} not found")
            continue
            
        with open(filepath, 'r') as f:
            content = f.read()
            
        # Extract master plate
        master_match = re.search(r'([A-Z]+)-MASTER[^:]*:(.*?)(?=\n\n|\nCLOTHING|\nPHYSICAL)', content, re.DOTALL)
        if master_match:
            master_id = f"{character.upper()}-MASTER"
            plate_index[master_id] = {
                "file": character,
                "section": "MASTER PLATE",
                "character": character.capitalize(),
                "is_master": True,
                "description": master_match.group(2).strip()[:200] + "..."  # First 200 chars
            }
        
        # Extract regular plates
        plate_patterns = [
            r'PLATE \d+[^:]*:\s*([^(]+)\s*\(([^)]+)\)\s*\n([A-Z]+-[A-Z]+):(.*?)(?=\n\n|\*\*Acting)',
            r'([A-Z]+)-([A-Z]+):(.*?)(?=\n\n|\*\*Acting)',
        ]
        
        for pattern in plate_patterns:
            for match in re.finditer(pattern, content, re.DOTALL):
                if len(match.groups()) >= 3:
                    if "PLATE" in match.group(0):
                        plate_name = match.group(1).strip()
                        shot_range = match.group(2).strip()
                        plate_id = match.group(3).strip()
                        description = match.group(4).strip()[:200] + "..."
                    else:
                        plate_id = f"{match.group(1)}-{match.group(2)}"
                        description = match.group(3).strip()[:200] + "..."
                        shot_range = extract_shot_range(content, plate_id)
                        plate_name = match.group(2).replace('_', ' ').title()
                    
                    # Determine film percentage range based on narrative context
                    percentage_range = determine_percentage_range(shot_range, plate_id)
                    
                    plate_index[plate_id] = {
                        "file": character,
                        "section": f"PLATE {plate_id.split('-')[1]}",
                        "character": character.capitalize(),
                        "name": plate_name,
                        "shot_range": shot_range,
                        "film_percentage_range": percentage_range,
                        "narrative_stage": determine_narrative_stage(plate_id),
                        "description": description
                    }
    
    return {
        "plate_files": {k: f"{ENHANCEMENT_PATH}/{v}" for k, v in character_files.items()},
        "plate_index": plate_index
    }

def parse_environmental_plates():
    """Parse all environmental plate files"""
    
    env_files = {
        "interior": "baðstofa_environmental_plates_bergrisi_transformation.txt",
        "exterior_house": "house_exterior_immediate_surroundings_plates.txt",
        "exterior_westfjords": "westfjords_exterior_environmental_plates_system.txt",
        "sea": "sea_environmental_plates_character_progression.txt"
    }
    
    plate_index = {}
    
    for env_type, filename in env_files.items():
        filepath = Path(ENHANCEMENT_PATH) / filename
        
        if not filepath.exists():
            print(f"Warning: {filepath} not found")
            continue
            
        with open(filepath, 'r') as f:
            content = f.read()
        
        # Extract environmental plates
        patterns = [
            r'PLATE[^:]*:\s*([^:]+):(.*?)(?=\nPLATE|\n\n\*\*|\Z)',
            r'([A-Z]+(?:-[A-Z]+)+):(.*?)(?=\n[A-Z]+(?:-[A-Z]+)+:|\n\n|\Z)'
        ]
        
        for pattern in patterns:
            for match in re.finditer(pattern, content, re.DOTALL):
                if len(match.groups()) >= 2:
                    plate_name = match.group(1).strip()
                    description = match.group(2).strip()[:200] + "..."
                    
                    # Create plate ID
                    if '-' in plate_name and plate_name.isupper():
                        plate_id = plate_name
                    else:
                        plate_id = create_env_plate_id(env_type, plate_name)
                    
                    plate_index[plate_id] = {
                        "file": env_type,
                        "type": env_type,
                        "name": plate_name,
                        "narrative_stage": determine_env_narrative_stage(plate_id),
                        "description": description
                    }
    
    # Add integration file plates
    parse_integration_file(plate_index)
    
    return {
        "plate_files": {k: f"{ENHANCEMENT_PATH}/{v}" for k, v in env_files.items()},
        "plate_index": plate_index
    }

def parse_integration_file(plate_index):
    """Parse the FINAL_ENVIRONMENTAL_INTEGRATION file for additional plates"""
    filepath = Path(ENHANCEMENT_PATH) / "FINAL_ENVIRONMENTAL_INTEGRATION_COMPLETE_SYSTEM.txt"
    
    if filepath.exists():
        with open(filepath, 'r') as f:
            content = f.read()
        
        # Extract integrated environmental descriptions
        pattern = r'(WESTFJORDS-[A-Z-]+|BAÐSTOFA-[A-Z]+|SEA-[A-Z-]+|HOUSE-[A-Z]+)[^(]*\(([^)]+)\)'
        
        for match in re.finditer(pattern, content):
            plate_id = match.group(1)
            description = match.group(2)
            
            if plate_id not in plate_index:
                env_type = determine_env_type(plate_id)
                plate_index[plate_id] = {
                    "file": "integration",
                    "type": env_type,
                    "name": plate_id.replace('-', ' ').title(),
                    "narrative_stage": determine_env_narrative_stage(plate_id),
                    "description": description[:200] + "..." if len(description) > 200 else description
                }

def create_shot_recommendations():
    """Create shot-to-plate recommendations based on MASTER integration file"""
    
    # Read the MASTER integration file
    master_path = Path(ENHANCEMENT_PATH) / "MASTER_CHARACTER_INTEGRATION_SHOT_BY_SHOT_MAPPING.txt"
    
    shot_mappings = {}
    
    if master_path.exists():
        with open(master_path, 'r') as f:
            content = f.read()
        
        # Parse shot-specific plate assignments
        shot_pattern = r'\*\*SHOT ([^:]+):\s*([^*]+)\*\*\s*(.*?)(?=\*\*SHOT|\*\*Family Breathing|\Z)'
        
        for match in re.finditer(shot_pattern, content, re.DOTALL):
            shot_id = match.group(1).strip()
            shot_title = match.group(2).strip()
            shot_content = match.group(3)
            
            # Extract character plates
            character_plates = {}
            char_pattern = r'- ([^:]+):\s*([A-Z]+-[A-Z]+[^(\n]*)'
            for char_match in re.finditer(char_pattern, shot_content):
                character = char_match.group(1).strip().lower()
                if character in ['magnus', 'sigrid', 'guðrún', 'gudrun', 'jón', 'jon', 'lilja']:
                    character = character.replace('ð', 'd').replace('ú', 'u').replace('ó', 'o')
                    plate_id = char_match.group(2).strip().split('(')[0].strip()
                    character_plates[character] = plate_id
            
            # Extract breathing coordination
            breathing_match = re.search(r'\*\*(?:Family )?Breathing[^:]*:\*\*\s*([^\n]+)', shot_content)
            breathing = breathing_match.group(1) if breathing_match else None
            
            # Extract acting theme
            acting_match = re.search(r'\*\*Acting Theme:\*\*\s*([^\n]+)', shot_content)
            acting = acting_match.group(1) if acting_match else None
            
            # Convert shot ID to file format
            shot_file_ids = convert_shot_id(shot_id)
            
            if shot_file_ids:
                # Handle both single IDs and lists
                if isinstance(shot_file_ids, str):
                    shot_file_ids = [shot_file_ids]
                    
                for shot_file_id in shot_file_ids:
                    shot_mappings[shot_file_id] = {
                        "narrative_context": shot_title,
                        "recommended_plates": {
                            "characters": character_plates,
                            "environment": extract_env_plates_for_shot(shot_id, content)
                        }
                    }
                    
                    if breathing:
                        shot_mappings[shot_file_id]["breathing_coordination"] = breathing
                    if acting:
                        shot_mappings[shot_file_id]["acting_theme"] = acting
    
    # Add environmental plates from integration file
    add_environmental_mappings(shot_mappings)
    
    return {"shot_mappings": shot_mappings}

def add_environmental_mappings(shot_mappings):
    """Add environmental plate mappings from the integration file"""
    
    filepath = Path(ENHANCEMENT_PATH) / "FINAL_ENVIRONMENTAL_INTEGRATION_COMPLETE_SYSTEM.txt"
    
    if filepath.exists():
        with open(filepath, 'r') as f:
            content = f.read()
        
        # Parse shot-by-shot environmental mapping
        pattern = r'\*\*SHOT ([^:]+):[^*]+\*\*\s*(.*?)(?=\*\*SHOT|\Z)'
        
        for match in re.finditer(pattern, content, re.DOTALL):
            shot_id = match.group(1).strip()
            shot_content = match.group(2)
            
            shot_file_ids = convert_shot_id(shot_id)
            
            if shot_file_ids:
                # Handle both single IDs and lists
                if isinstance(shot_file_ids, str):
                    shot_file_ids = [shot_file_ids]
                    
                for shot_file_id in shot_file_ids:
                    if shot_file_id not in shot_mappings:
                        shot_mappings[shot_file_id] = {
                            "recommended_plates": {"characters": {}, "environment": {}}
                        }
                    
                    # Extract environmental plates
                    env_plates = {}
                    
                    for line in shot_content.split('\n'):
                        if 'Landscape:' in line:
                            match = re.search(r'(WESTFJORDS-[A-Z-]+)', line)
                            if match:
                                env_plates['landscape'] = match.group(1)
                        elif 'Sea:' in line:
                            match = re.search(r'(SEA-[A-Z-]+)', line)
                            if match:
                                env_plates['sea'] = match.group(1)
                        elif 'Interior:' in line or 'Exterior:' in line:
                            match = re.search(r'(BAÐSTOFA-[A-Z]+|HOUSE-[A-Z]+)', line)
                            if match:
                                key = 'interior' if 'BAÐSTOFA' in match.group(1) else 'exterior'
                                env_plates[key] = match.group(1)
                    
                    shot_mappings[shot_file_id]["recommended_plates"]["environment"].update(env_plates)

# Helper functions
def extract_shot_range(content, plate_id):
    """Extract shot range from content context"""
    # Look for shot range patterns near the plate ID
    pattern = rf'{re.escape(plate_id)}[^(]*\(([^)]+)\)'
    match = re.search(pattern, content)
    if match:
        return match.group(1)
    return "Various"

def determine_percentage_range(shot_range, plate_id):
    """Determine film percentage range based on shot range and plate type"""
    if "prologue" in shot_range.lower() or "0-" in shot_range:
        return [0, 15]
    elif "early" in plate_id.lower() or "pure" in plate_id.lower():
        return [0, 25]
    elif "confused" in plate_id.lower() or "mathematical" in plate_id.lower():
        return [25, 45]
    elif "predator" in plate_id.lower() or "violence" in plate_id.lower():
        return [45, 65]
    elif "transform" in plate_id.lower() or "hybrid" in plate_id.lower():
        return [65, 85]
    elif "monument" in plate_id.lower() or "eternal" in plate_id.lower():
        return [85, 100]
    else:
        return [0, 100]

def determine_narrative_stage(plate_id):
    """Determine narrative stage from plate ID"""
    plate_lower = plate_id.lower()
    
    if "authority" in plate_lower or "pure" in plate_lower or "abundant" in plate_lower:
        return "false_abundance"
    elif "confused" in plate_lower or "mathematical" in plate_lower or "counting" in plate_lower:
        return "mathematical_breakdown"
    elif "predator" in plate_lower or "violence" in plate_lower or "cornered" in plate_lower:
        return "violence_crisis"
    elif "transform" in plate_lower or "hybrid" in plate_lower or "becoming" in plate_lower:
        return "transformation"
    elif "ram" in plate_lower or "corvid" in plate_lower or "eternal" in plate_lower:
        return "final_form"
    else:
        return "general"

def determine_env_narrative_stage(plate_id):
    """Determine narrative stage for environmental plates"""
    plate_lower = plate_id.lower()
    
    if "domestic" in plate_lower or "traditional" in plate_lower:
        return "domestic_disguise"
    elif "organic" in plate_lower or "breathing" in plate_lower or "awakening" in plate_lower:
        return "organic_revelation"
    elif "cliff" in plate_lower or "geological" in plate_lower:
        return "geological_emergence"
    elif "crystalliz" in plate_lower or "monument" in plate_lower:
        return "crystallization"
    elif "eternal" in plate_lower:
        return "eternal_monument"
    else:
        return "general"

def determine_env_type(plate_id):
    """Determine environment type from plate ID"""
    if "BAÐSTOFA" in plate_id:
        return "interior"
    elif "HOUSE" in plate_id:
        return "exterior"
    elif "SEA" in plate_id:
        return "sea"
    elif "WESTFJORDS" in plate_id:
        return "landscape"
    else:
        return "general"

def create_env_plate_id(env_type, plate_name):
    """Create standardized environment plate ID"""
    prefix_map = {
        "interior": "BAÐSTOFA",
        "exterior_house": "HOUSE",
        "exterior_westfjords": "WESTFJORDS",
        "sea": "SEA"
    }
    
    prefix = prefix_map.get(env_type, env_type.upper())
    suffix = plate_name.upper().replace(' ', '-').replace('_', '-')
    
    # Clean up the suffix
    suffix = re.sub(r'[^A-Z-]', '', suffix)
    
    return f"{prefix}-{suffix}"

def extract_env_plates_for_shot(shot_id, content):
    """Extract environmental plates for a specific shot"""
    env_plates = {}
    
    # Look for environmental context around this shot
    shot_pattern = rf'SHOT {re.escape(shot_id)}.*?(?=SHOT|\Z)'
    shot_match = re.search(shot_pattern, content, re.DOTALL)
    
    if shot_match:
        shot_content = shot_match.group(0)
        
        # Extract environmental references
        if 'winter' in shot_content.lower() or 'cold' in shot_content.lower():
            env_plates['weather'] = 'WINTER-HOSTILE'
        elif 'summer' in shot_content.lower() or 'warm' in shot_content.lower():
            env_plates['weather'] = 'SUMMER-COOPERATIVE'
        
        if 'house' in shot_content.lower():
            if 'breathing' in shot_content.lower():
                env_plates['interior'] = 'BAÐSTOFA-ORGANIC'
            else:
                env_plates['interior'] = 'BAÐSTOFA-DOMESTIC'
    
    return env_plates

def convert_shot_id(shot_id):
    """Convert shot ID from MASTER format to file format"""
    # Handle various formats
    shot_id = shot_id.strip()
    
    # Remove "SHOT" prefix if present
    shot_id = shot_id.replace("SHOT ", "").replace("SHOTS ", "")
    
    # Handle ranges (e.g., "26-35")
    if "-" in shot_id and not shot_id[0].isalpha():
        # Return multiple shot IDs for ranges
        parts = shot_id.split("-")
        try:
            start = int(parts[0])
            end = int(parts[1])
            return [f"shot_{i}_main" for i in range(start, end + 1)]
        except:
            shot_id = parts[0]
    
    # Determine if prologue or main
    if any(x in shot_id.upper() for x in ["B", "A", "C"]) and shot_id[0].isdigit():
        # Prologue format
        shot_id = shot_id.lower().replace(" ", "")
        return f"shot_{shot_id}_prologue"
    elif shot_id[0].isdigit():
        # Main story format
        shot_num = re.match(r'(\d+)', shot_id)
        if shot_num:
            return f"shot_{shot_num.group(1)}_main"
    
    return None

def update_shot_files(character_index, env_index, recommendations):
    """Update all shot JSON files with plate recommendations"""
    
    shots_dir = Path(SHOTS_PATH)
    
    if not shots_dir.exists():
        print(f"Error: Shots directory not found at {shots_dir}")
        return
    
    updated_count = 0
    
    for shot_file in shots_dir.glob("*.json"):
        shot_id = shot_file.stem
        
        try:
            with open(shot_file, 'r') as f:
                shot_data = json.load(f)
            
            # Determine film percentage
            film_percentage = shot_data.get('shot_metadata', {}).get('film_position_percentage', 50.0)
            
            # Get recommendations for this shot
            if shot_id in recommendations['shot_mappings']:
                rec = recommendations['shot_mappings'][shot_id]
            else:
                # Create default recommendations based on film percentage
                rec = create_default_recommendations(film_percentage, character_index, env_index)
            
            # Add recommended_plates to each prompt variant
            for variant in shot_data.get('prompt_variants', []):
                variant['recommended_plates'] = rec.get('recommended_plates', {})
                
                # Add selected_plates if not present
                if 'selected_plates' not in variant:
                    variant['selected_plates'] = {
                        "characters": {},
                        "environment": {}
                    }
            
            # Add acting and breathing info if available
            if 'breathing_coordination' in rec:
                shot_data['breathing_coordination'] = rec['breathing_coordination']
            if 'acting_theme' in rec:
                shot_data['acting_theme'] = rec['acting_theme']
            
            # Write updated file
            with open(shot_file, 'w') as f:
                json.dump(shot_data, f, indent=2)
            
            updated_count += 1
            print(f"Updated {shot_id}")
            
        except Exception as e:
            print(f"Error updating {shot_file}: {e}")
    
    print(f"\nUpdated {updated_count} shot files")

def create_default_recommendations(film_percentage, character_index, env_index):
    """Create default plate recommendations based on film percentage"""
    
    recommendations = {"characters": {}, "environment": {}}
    
    # Select character plates based on film percentage
    for plate_id, plate_info in character_index['plate_index'].items():
        if 'film_percentage_range' in plate_info:
            min_pct, max_pct = plate_info['film_percentage_range']
            if min_pct <= film_percentage <= max_pct:
                character = plate_info['character'].lower()
                if character not in recommendations['characters']:
                    recommendations['characters'][character] = plate_id
    
    # Select environmental plates based on film percentage
    if film_percentage < 15:
        recommendations['environment'] = {
            'landscape': 'WESTFJORDS-SUMMER-FALSE-PERFECTION',
            'interior': 'BAÐSTOFA-DOMESTIC'
        }
    elif film_percentage < 45:
        recommendations['environment'] = {
            'landscape': 'WESTFJORDS-WINTER',
            'interior': 'BAÐSTOFA-ORGANIC'
        }
    elif film_percentage < 65:
        recommendations['environment'] = {
            'landscape': 'WESTFJORDS-HOSTILE',
            'interior': 'BAÐSTOFA-CLIFF'
        }
    else:
        recommendations['environment'] = {
            'landscape': 'WESTFJORDS-TRANSCENDENT',
            'interior': 'BAÐSTOFA-MONUMENT'
        }
    
    return {"recommended_plates": recommendations}

def main():
    """Main execution"""
    
    print("=" * 60)
    print("PLATE PARSING AND SHOT MAPPING SYSTEM")
    print("=" * 60)
    
    # Step 1: Parse character plates
    print("\n1. Parsing character plates...")
    character_index = parse_character_plates()
    
    with open(f"{APP_PATH}/character_plates_index.json", 'w') as f:
        json.dump(character_index, f, indent=2)
    
    print(f"   Found {len(character_index['plate_index'])} character plates")
    
    # Step 2: Parse environmental plates
    print("\n2. Parsing environmental plates...")
    env_index = parse_environmental_plates()
    
    with open(f"{APP_PATH}/environmental_plates_index.json", 'w') as f:
        json.dump(env_index, f, indent=2)
    
    print(f"   Found {len(env_index['plate_index'])} environmental plates")
    
    # Step 3: Create shot recommendations
    print("\n3. Creating shot-to-plate recommendations...")
    recommendations = create_shot_recommendations()
    
    with open(f"{APP_PATH}/shot_plate_recommendations.json", 'w') as f:
        json.dump(recommendations, f, indent=2)
    
    print(f"   Created recommendations for {len(recommendations['shot_mappings'])} shots")
    
    # Step 4: Update shot files
    print("\n4. Updating shot JSON files...")
    update_shot_files(character_index, env_index, recommendations)
    
    print("\n✅ PLATE INTEGRATION COMPLETE!")
    print("\nCreated files:")
    print(f"  - {APP_PATH}/character_plates_index.json")
    print(f"  - {APP_PATH}/environmental_plates_index.json")
    print(f"  - {APP_PATH}/shot_plate_recommendations.json")

if __name__ == "__main__":
    main()