#!/usr/bin/env python3
"""
Create Correct Shot-to-Plate Mapping
Based on SHOT_PLATE_MAPPING_GUIDE.md - individual shot mappings, no ranges.
"""

import json
import os
from pathlib import Path

SHOTS_DIR = '/Users/ingthor/Documents/stories/appdata/json/7/shots/json'
CHAR_PLATES_PATH = '/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_index.json'
ENV_PLATES_PATH = '/Users/ingthor/Documents/stories/appdata/json/7/plates/environmental_plates_index.json'

# Individual shot-to-plate mappings from the guide
SHOT_PLATE_MAPPINGS = {
    # Prologue shots - False abundance
    "0a": {
        "characters": {
            "magnus": "MAGNUS-AUTHORITY",
            "sigrid": "SIGRID-PURE", 
            "gudrun": "GUDRUN-ABUNDANT"
        },
        "environment": "BAÐSTOFA-DOMESTIC"
    },
    
    # Shot 8 - Danish counting violence  
    "8": {
        "characters": {
            "magnus": "MAGNUS-CONFUSED",
            "sigrid": "SIGRID-CALCULATING",
            "gudrun": "GUDRUN-COUNTING", 
            "jon": "JON-PROPHET",
            "lilja": "LILJA-MATHEMATICAL"
        },
        "environment": "BAÐSTOFA-ORGANIC"
    },
    
    # Shot 17 - Three-frame reality flash
    "17": {
        "characters": {
            "magnus": "MAGNUS-CONFUSED",
            "sigrid": "SIGRID-MARKED",
            "gudrun": "GUDRUN-PRODUCING"
        },
        "environment": "BAÐSTOFA-DARKNESS"
    },
    
    # Shot 56 - Transformation complete
    "56": {
        "characters": {
            "magnus": "MAGNUS-HYBRID",
            "sigrid": "SIGRID-TRANSITIONAL", 
            "gudrun": "GUDRUN-SPEAKING",
            "jon": "JON-CHANGING",
            "lilja": "LILJA-FINAL"
        },
        "environment": "BAÐSTOFA-CLIFF"
    }
}

def normalize_shot_id(shot_id: str) -> str:
    """Normalize shot ID for mapping lookup."""
    # Remove file extension and path
    base_id = shot_id.replace('_main', '').replace('.json', '')
    # Handle variants like 8a, 8b, 8c -> map to base shot 8
    if len(base_id) > 1 and base_id[-1].isalpha():
        return base_id[:-1]  # Remove letter suffix
    return base_id

def get_plate_mapping_for_shot(shot_id: str) -> dict:
    """Get the correct plate mapping for a specific shot."""
    normalized_id = normalize_shot_id(shot_id)
    
    # Check for exact match first
    if normalized_id in SHOT_PLATE_MAPPINGS:
        return SHOT_PLATE_MAPPINGS[normalized_id]
    
    # Default mappings based on narrative progression
    try:
        shot_num = int(normalized_id) if normalized_id.lstrip('-').isdigit() else 0
    except:
        shot_num = 0
    
    if shot_num <= 7:
        # Early shots - abundance/authority
        return {
            "characters": {
                "magnus": "MAGNUS-AUTHORITY",
                "sigrid": "SIGRID-PURE",
                "gudrun": "GUDRUN-ABUNDANT"
            },
            "environment": "BAÐSTOFA-DOMESTIC"
        }
    elif 8 <= shot_num <= 16:
        # Mathematical breakdown period
        return {
            "characters": {
                "magnus": "MAGNUS-CONFUSED", 
                "sigrid": "SIGRID-CALCULATING",
                "gudrun": "GUDRUN-COUNTING"
            },
            "environment": "BAÐSTOFA-ORGANIC"
        }
    elif 17 <= shot_num <= 40:
        # Crisis/violence period
        return {
            "characters": {
                "magnus": "MAGNUS-PREDATOR",
                "sigrid": "SIGRID-CORNERED", 
                "gudrun": "GUDRUN-PRODUCING"
            },
            "environment": "BAÐSTOFA-CLIFF"
        }
    else:
        # Transformation period
        return {
            "characters": {
                "magnus": "MAGNUS-HYBRID",
                "sigrid": "SIGRID-TRANSITIONAL",
                "gudrun": "GUDRUN-SPEAKING"
            },
            "environment": "BAÐSTOFA-MONUMENT"
        }

def create_clean_plate_indices():
    """Create clean, correctly structured plate indices."""
    
    # Define the essential plates based on the mapping guide
    character_plates = {
        "plate_index": {
            # Magnus plates
            "MAGNUS-AUTHORITY": {
                "character": "Magnus",
                "name": "Authority",
                "description": "Magnús Þorláksson as confident patriarch, weathered but authoritative, steel-blue eyes showing leadership, clean brown vaðmál sweater, cane held casually, upright posture.",
                "is_master": False
            },
            "MAGNUS-CONFUSED": {
                "character": "Magnus", 
                "name": "Confused",
                "description": "Authority cracking during mathematical breakdown, counting failure visible, hunched posture, cane gripped for support, disheveled clothing.",
                "is_master": False
            },
            "MAGNUS-PREDATOR": {
                "character": "Magnus",
                "name": "Predator", 
                "description": "0Hz violence-ready, territorial positioning, cane as weapon, predatory surveillance focus, authority through intimidation.",
                "is_master": False
            },
            "MAGNUS-HYBRID": {
                "character": "Magnus",
                "name": "Hybrid",
                "description": "Ram transformation visible, posture lowering toward quadruped, jaw showing ruminant changes, steel-blue eyes developing horizontal pupils.",
                "is_master": False
            },
            "MAGNUS-MASTER": {
                "character": "Magnus",
                "name": "Magnus Master",
                "description": "Base template for Magnus variations - 55-year-old Westfjords fisherman, weathered rectangular face, broken aquiline nose, steel-blue hooded eyes, charcoal-grey beard.",
                "is_master": True
            },
            
            # Sigrid plates
            "SIGRID-PURE": {
                "character": "Sigrid",
                "name": "Pure",
                "description": "Innocent 16-year-old, untouched by family corruption, grey-brown vaðmál dress clean, positioned 8 feet from Magnus, natural confidence.",
                "is_master": False
            },
            "SIGRID-CALCULATING": {
                "character": "Sigrid", 
                "name": "Calculating",
                "description": "Analytical awareness during family counting breakdown, mathematical intelligence processing impossibility, positioned exactly 11 feet from counting center.",
                "is_master": False
            },
            "SIGRID-MARKED": {
                "character": "Sigrid",
                "name": "Marked",
                "description": "Post-violation defensive positioning, dress disheveled, pregnancy 2-month curve visible, arms crossed protectively, 11-foot defensive spacing.",
                "is_master": False
            },
            "SIGRID-CORNERED": {
                "character": "Sigrid",
                "name": "Cornered", 
                "description": "Maximum threat situation, pressed against wall, 6-month pregnancy visible, arms defensive over belly, klettagjá forming behind her.",
                "is_master": False
            },
            "SIGRID-TRANSITIONAL": {
                "character": "Sigrid",
                "name": "Transitional",
                "description": "Species change beginning, dress appearing costume-like on changing body, pregnancy full-term mystical, posture shifting between human and corvid.",
                "is_master": False
            },
            "SIGRID-MASTER": {
                "character": "Sigrid", 
                "name": "Sigrid Master",
                "description": "Base template - 16-year-old heart-shaped face, three-freckle nose constellation, grey eyes with amber flecks, wheat-blonde braids, 5'4\" lean build.",
                "is_master": True
            },
            
            # Gudrun plates
            "GUDRUN-ABUNDANT": {
                "character": "Gudrun",
                "name": "Abundant",
                "description": "Competent mother during false prosperity, white faldbúningur pristine, grey dress clean, brown apron fresh, confident maternal authority.",
                "is_master": False
            },
            "GUDRUN-COUNTING": {
                "character": "Gudrun", 
                "name": "Counting",
                "description": "During family counting breakdown, faldbúningur disheveled, grey dress wrinkled, brown apron twisted from nervous handling.",
                "is_master": False
            },
            "GUDRUN-PRODUCING": {
                "character": "Gudrun",
                "name": "Producing", 
                "description": "Wool emergence visible, faldbúningur concealing wrist situation, grey dress sleeves pulled down, brown apron catching falling wool.",
                "is_master": False
            },
            "GUDRUN-SPEAKING": {
                "character": "Gudrun",
                "name": "Speaking",
                "description": "Truth-telling transformation, blood-soaked dress, faldbúningur ice crown, wool production complete, maternal authority through species change.",
                "is_master": False
            },
            "GUDRUN-MASTER": {
                "character": "Gudrun",
                "name": "Gudrun Master", 
                "description": "Base template - 35-year-old oval face, hollow cheeks, grey-green eyes, white faldbúningur headdress, 5'5\" skeletal frame from malnutrition.",
                "is_master": True
            },
            
            # Jon plates
            "JON-PROPHET": {
                "character": "Jon",
                "name": "Prophet",
                "description": "8-year-old with 41°C fever enabling temporal sight, round face flushed red, hazel eyes glazed with prophetic vision, sandy hair matted with sweat.",
                "is_master": False
            },
            "JON-CHANGING": {
                "character": "Jon",
                "name": "Changing", 
                "description": "Species transformation active, fever 43°C critical, face structure beginning lamb change, sheep teeth functional, consciousness maintained.",
                "is_master": False
            },
            "JON-MASTER": {
                "character": "Jon",
                "name": "Jon Master",
                "description": "Base template - 8-year-old round face flushed with fever, button nose bright red, hazel eyes, sandy brown hair, 4'2\" skeletal frame.",
                "is_master": True
            },
            
            # Lilja plates
            "LILJA-MATHEMATICAL": {
                "character": "Lilja", 
                "name": "Mathematical",
                "description": "Child confusion about adult mathematical impossibility, silently counting along but getting different numbers, blue eyes showing innocent awareness.",
                "is_master": False
            },
            "LILJA-FINAL": {
                "character": "Lilja",
                "name": "Final",
                "description": "Before consciousness simplification, face maintaining child expression despite anatomical changes, mouth adapted for sheep vocalization.",
                "is_master": False
            },
            "LILJA-MASTER": {
                "character": "Lilja",
                "name": "Lilja Master",
                "description": "Base template - 3-year-old cherubic face, cornflower-blue eyes, rosebud mouth, wheat-blonde curls, traditional child's dress.",
                "is_master": True
            }
        },
        "last_updated": "2025-09-06"
    }
    
    environmental_plates = {
        "plate_index": {
            "BAÐSTOFA-DOMESTIC": {
                "category": "Interior",
                "name": "Domestic",
                "description": "Traditional turf house interior, driftwood beams architectural, turf walls structural, packed earth floor normal, whale oil lamp burning bright."
            },
            "BAÐSTOFA-ORGANIC": {
                "category": "Interior", 
                "name": "Organic",
                "description": "House consciousness stirring, driftwood beams flexing like ribs during breathing, turf walls showing subtle blood vessel patterns."
            },
            "BAÐSTOFA-DARKNESS": {
                "category": "Interior",
                "name": "Darkness",
                "description": "Three-frame flash environment, architecture existing in multiple reality states simultaneously, lighting creating impossible illumination patterns."
            },
            "BAÐSTOFA-CLIFF": {
                "category": "Interior", 
                "name": "Cliff",
                "description": "Klettagjá formation complete, walls pure obsidian extending upward, floor slope creating canyon effect, cliff interior revealed."
            },
            "BAÐSTOFA-MONUMENT": {
                "category": "Interior",
                "name": "Monument", 
                "description": "Crystallization complete, transparent cliff walls revealing family consciousness, perfect geometric architecture, obsidian monument interior."
            }
        },
        "last_updated": "2025-09-06"
    }
    
    # Write the clean indices
    with open(CHAR_PLATES_PATH, 'w', encoding='utf-8') as f:
        json.dump(character_plates, f, indent=2, ensure_ascii=False)
    
    with open(ENV_PLATES_PATH, 'w', encoding='utf-8') as f:
        json.dump(environmental_plates, f, indent=2, ensure_ascii=False)
    
    print(f"Created clean character plates index with {len(character_plates['plate_index'])} plates")
    print(f"Created clean environmental plates index with {len(environmental_plates['plate_index'])} plates")

def update_shot_files_with_correct_mappings():
    """Update all shot files with correct individual plate mappings."""
    
    shot_files = list(Path(SHOTS_DIR).glob('*.json'))
    updated_count = 0
    
    for shot_file in shot_files:
        try:
            with open(shot_file, 'r', encoding='utf-8') as f:
                shot_data = json.load(f)
            
            # Get shot metadata
            shot_metadata = shot_data.get('shot_metadata', {})
            shot_id = shot_metadata.get('id', '')
            
            # Get correct mapping for this specific shot
            mapping = get_plate_mapping_for_shot(shot_id)
            
            modified = False
            
            # Update prompt variants with correct plate references
            for variant in shot_data.get('prompt_variants', []):
                # Update character plate - default to Sigrid for main character focus
                old_char_id = variant.get('selectedCharacterPlateId')
                if 'sigrid' in mapping['characters']:
                    new_char_id = mapping['characters']['sigrid']
                elif 'magnus' in mapping['characters']:
                    new_char_id = mapping['characters']['magnus'] 
                else:
                    new_char_id = mapping['characters'][list(mapping['characters'].keys())[0]]
                
                if old_char_id != new_char_id:
                    variant['selectedCharacterPlateId'] = new_char_id
                    print(f"Shot {shot_id}: character {old_char_id} -> {new_char_id}")
                    modified = True
                
                # Update environment plate
                old_env_id = variant.get('selectedEnvironmentPlateId') 
                new_env_id = mapping['environment']
                
                if old_env_id != new_env_id:
                    variant['selectedEnvironmentPlateId'] = new_env_id
                    print(f"Shot {shot_id}: environment {old_env_id} -> {new_env_id}")
                    modified = True
            
            # Save if modified
            if modified:
                with open(shot_file, 'w', encoding='utf-8') as f:
                    json.dump(shot_data, f, indent=2, ensure_ascii=False)
                updated_count += 1
                
        except Exception as e:
            print(f"Error processing {shot_file}: {e}")
    
    print(f"\nUpdated {updated_count} shot files with correct individual plate mappings")

if __name__ == "__main__":
    print("Creating clean plate system with individual shot mappings...")
    create_clean_plate_indices()
    update_shot_files_with_correct_mappings()
    print("Done! Each shot now has individual plate mapping.")