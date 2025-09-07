#!/usr/bin/env python3

import json
import re
import os
from pathlib import Path

# Character plate mappings from the MASTER file
SHOT_PLATE_MAPPING = {
    # PROLOGUE SHOTS
    "1b_prologue": {
        "characters": {
            "magnus": "MAGNUS-AUTHORITY",
            "sigrid": "SIGRID-PURE", 
            "gudrun": "GUDRUN-ABUNDANT",
            "jon": "JON-MILD",
            "lilja": "LILJA-PURE"
        },
        "environment": {
            "landscape": "WESTFJORDS-SUMMER",
            "sea": "SEA-ABUNDANT"
        }
    },
    "2a_prologue": {
        "characters": {
            "magnus": "MAGNUS-AUTHORITY",
            "sigrid": "SIGRID-PURE",
            "gudrun": "GUDRUN-ABUNDANT",
            "jon": "JON-MILD",
            "lilja": "LILJA-PURE"
        },
        "environment": {
            "landscape": "WESTFJORDS-SUMMER",
            "sea": "SEA-ABUNDANT"
        }
    },
    "3a_prologue": {
        "characters": {
            "magnus": "MAGNUS-AUTHORITY",
            "jon": "JON-MILD"
        },
        "environment": {
            "landscape": "WESTFJORDS-AUTUMN"
        }
    },
    "5p_prologue": {  # Shot 5.5
        "characters": {
            "magnus": "MAGNUS-WATCHING",
            "sigrid": "SIGRID-AWAKENING",
            "gudrun": "GUDRUN-ABUNDANT",
            "jon": "JON-RISING",
            "lilja": "LILJA-SENSING"
        },
        "environment": {
            "interior": "BADSTOFA-NORMAL"
        }
    },
    "6a_prologue": {
        "characters": {
            "gudrun": "GUDRUN-ABUNDANT",
            "sigrid": "SIGRID-AWAKENING"
        },
        "environment": {
            "interior": "BADSTOFA-NORMAL"
        }
    },
    "9b_prologue": {
        "characters": {
            "magnus": "MAGNUS-TRANSITION",
            "sigrid": "SIGRID-MARKED",
            "gudrun": "GUDRUN-WEARING",
            "jon": "JON-SEEING",
            "lilja": "LILJA-HARMONIC"
        },
        "environment": {
            "interior": "BADSTOFA-ORGANIC"
        }
    },
    
    # MAIN STORY SHOTS
    "1_main": {
        "characters": {
            "magnus": "MAGNUS-CONFUSED",
            "sigrid": "SIGRID-MARKED",
            "gudrun": "GUDRUN-PRODUCING",
            "jon": "JON-PROPHET",
            "lilja": "LILJA-MATHEMATICAL"
        },
        "environment": {
            "interior": "BADSTOFA-ORGANIC",
            "weather": "WESTFJORDS-HOSTILE"
        }
    },
    "5_main": {
        "characters": {
            "magnus": "MAGNUS-CONFUSED"
        },
        "environment": {
            "interior": "BADSTOFA-ORGANIC"
        }
    },
    "8_main": {
        "characters": {
            "magnus": "MAGNUS-CONFUSED",
            "sigrid": "SIGRID-CALCULATING",
            "gudrun": "GUDRUN-COUNTING",
            "jon": "JON-PROPHET",
            "lilja": "LILJA-MATHEMATICAL"
        },
        "environment": {
            "interior": "BADSTOFA-ORGANIC",
            "weather": "DANISH-COLD-SPREADING"
        }
    },
    "9_main": {
        "characters": {
            "magnus": "MAGNUS-CONFUSED",
            "sigrid": "SIGRID-CALCULATING",
            "gudrun": "GUDRUN-COUNTING",
            "jon": "JON-PROPHET",
            "lilja": "LILJA-MATHEMATICAL"
        },
        "environment": {
            "interior": "BADSTOFA-ORGANIC"
        }
    },
    "10_main": {
        "characters": {
            "magnus": "MAGNUS-CONFUSED",
            "sigrid": "SIGRID-CALCULATING",
            "gudrun": "GUDRUN-COUNTING",
            "jon": "JON-PROPHET",
            "lilja": "LILJA-MATHEMATICAL"
        },
        "environment": {
            "interior": "BADSTOFA-ORGANIC"
        }
    },
    "11_main": {
        "characters": {
            "gudrun": "GUDRUN-PRODUCING",
            "magnus": "MAGNUS-CONFUSED"
        },
        "environment": {
            "interior": "BADSTOFA-ORGANIC"
        }
    },
    "16p_main": {  # Shot 16.5
        "characters": {
            "sigrid": "SIGRID-PROPHECY"
        },
        "environment": {
            "interior": "BADSTOFA-NIGHT"
        }
    },
    "18_main": {
        "characters": {
            "magnus": "MAGNUS-PROVIDER"
        },
        "environment": {
            "interior": "BADSTOFA-PANIC"
        }
    },
    "23_main": {
        "characters": {
            "magnus": "MAGNUS-RITUAL",
            "gudrun": "GUDRUN-RITUAL",
            "sigrid": "SIGRID-SUMMONING",
            "jon": "JON-TEMPORAL",
            "lilja": "LILJA-HARMONIC"
        },
        "environment": {
            "interior": "BADSTOFA-RITUAL"
        }
    },
    "24_main": {
        "characters": {
            "magnus": "MAGNUS-RITUAL",
            "gudrun": "GUDRUN-RITUAL",
            "sigrid": "SIGRID-SUMMONING"
        },
        "environment": {
            "interior": "BADSTOFA-RITUAL"
        }
    },
    "26_main": {
        "characters": {
            "magnus": "MAGNUS-AFLOAT"
        },
        "environment": {
            "sea": "SEA-HOSTILE"
        }
    },
    "27_main": {
        "characters": {
            "magnus": "MAGNUS-AFLOAT"
        },
        "environment": {
            "sea": "SEA-HOSTILE"
        }
    },
    "28_main": {
        "characters": {
            "magnus": "MAGNUS-AFLOAT"
        },
        "environment": {
            "sea": "SEA-HOSTILE"
        }
    },
    "29_main": {
        "characters": {
            "magnus": "MAGNUS-AFLOAT"
        },
        "environment": {
            "sea": "SEA-HOSTILE"
        }
    },
    "30_main": {
        "characters": {
            "magnus": "MAGNUS-AFLOAT"
        },
        "environment": {
            "sea": "SEA-HOSTILE"
        }
    },
    "31_main": {
        "characters": {
            "magnus": "MAGNUS-AGING"
        },
        "environment": {
            "sea": "SEA-INDUSTRIAL"
        }
    },
    "32_main": {
        "characters": {
            "magnus": "MAGNUS-WOUNDED"
        },
        "environment": {
            "sea": "SEA-INDUSTRIAL"
        }
    },
    "33_main": {
        "characters": {
            "magnus": "MAGNUS-WOUNDED"
        },
        "environment": {
            "sea": "SEA-INDUSTRIAL"
        }
    },
    "34_main": {
        "characters": {
            "magnus": "MAGNUS-WOUNDED"
        },
        "environment": {
            "sea": "SEA-INDUSTRIAL"
        }
    },
    "35_main": {
        "characters": {
            "magnus": "MAGNUS-WOUNDED"
        },
        "environment": {
            "sea": "SEA-INDUSTRIAL"
        }
    },
    "36_main": {
        "characters": {
            "magnus": "MAGNUS-DEFEATED"
        },
        "environment": {
            "interior": "BADSTOFA-PANIC"
        }
    },
    "39p_main": {  # Shot 39.5
        "characters": {
            "jon": "JON-GAPPED",
            "lilja": "LILJA-ACCEPTING"
        },
        "environment": {
            "interior": "BADSTOFA-ORGANISM"
        }
    },
    "41_main": {
        "characters": {
            "magnus": "MAGNUS-PREDATOR",
            "gudrun": "GUDRUN-BEATEN",
            "sigrid": "SIGRID-CORNERED"
        },
        "environment": {
            "interior": "BADSTOFA-VIOLENCE"
        }
    },
    "42_main": {
        "characters": {
            "magnus": "MAGNUS-PREDATOR",
            "gudrun": "GUDRUN-BEATEN",
            "sigrid": "SIGRID-CORNERED"
        },
        "environment": {
            "interior": "BADSTOFA-VIOLENCE"
        }
    },
    "43_main": {
        "characters": {
            "magnus": "MAGNUS-ZERO-HZ",
            "gudrun": "GUDRUN-BEATEN",
            "sigrid": "SIGRID-CORNERED"
        },
        "environment": {
            "interior": "BADSTOFA-VIOLENCE"
        }
    },
    "43a_main": {
        "characters": {
            "magnus": "MAGNUS-ENFORCER"
        },
        "environment": {
            "interior": "BADSTOFA-VIOLENCE"
        }
    },
    "43b_main": {
        "characters": {
            "magnus": "MAGNUS-ENFORCER",
            "gudrun": "GUDRUN-BEATEN"
        },
        "environment": {
            "interior": "BADSTOFA-VIOLENCE"
        }
    },
    "44_main": {
        "characters": {
            "gudrun": "GUDRUN-WALKING",
            "magnus": "MAGNUS-DEFEATED"
        },
        "environment": {
            "landscape": "WESTFJORDS-HOSTILE"
        }
    },
    "45_main": {
        "characters": {
            "gudrun": "GUDRUN-CROWNED"
        },
        "environment": {
            "sea": "SEA-INDUSTRIAL"
        }
    },
    "46_main": {
        "characters": {
            "gudrun": "GUDRUN-DIVINE"
        },
        "environment": {
            "sea": "SEA-INDUSTRIAL"
        }
    },
    "47_main": {
        "characters": {
            "gudrun": "GUDRUN-RETURNING",
            "magnus": "MAGNUS-DEFEATED"
        },
        "environment": {
            "interior": "BADSTOFA-PANIC"
        }
    },
    "48_main": {
        "characters": {
            "gudrun": "GUDRUN-RETURNING",
            "magnus": "MAGNUS-DEFEATED"
        },
        "environment": {
            "interior": "BADSTOFA-PANIC"
        }
    },
    "49_main": {
        "characters": {
            "magnus": "MAGNUS-POSSESSOR",
            "sigrid": "SIGRID-CORNERED"
        },
        "environment": {
            "interior": "BADSTOFA-VIOLENCE"
        }
    },
    "49a_main": {
        "characters": {
            "magnus": "MAGNUS-POSSESSOR",
            "sigrid": "SIGRID-CORNERED"
        },
        "environment": {
            "interior": "BADSTOFA-CLIFF"
        }
    },
    "50_main": {
        "characters": {
            "magnus": "MAGNUS-POSSESSING",
            "sigrid": "SIGRID-CORNERED"
        },
        "environment": {
            "interior": "BADSTOFA-CLIFF"
        }
    },
    "55p_main": {  # Shot 55.5
        "characters": {
            "magnus": "MAGNUS-SHIFTING",
            "sigrid": "SIGRID-TRANSITIONAL",
            "gudrun": "GUDRUN-SPEAKING",
            "jon": "JON-CHANGING",
            "lilja": "LILJA-FINAL"
        },
        "environment": {
            "interior": "BADSTOFA-FRAGMENTING"
        }
    },
    "56_main": {
        "characters": {
            "magnus": "MAGNUS-RECOGNIZING",
            "sigrid": "SIGRID-TRANSITIONAL",
            "gudrun": "GUDRUN-SPEAKING"
        },
        "environment": {
            "interior": "BADSTOFA-TRANSFORMING"
        }
    },
    "57_main": {
        "characters": {
            "magnus": "MAGNUS-RECOGNIZING",
            "sigrid": "SIGRID-BECOMING",
            "gudrun": "GUDRUN-EWE"
        },
        "environment": {
            "interior": "BADSTOFA-TRANSFORMING"
        }
    },
    "58_main": {
        "characters": {
            "magnus": "MAGNUS-BREAKING",
            "sigrid": "SIGRID-BECOMING"
        },
        "environment": {
            "interior": "BADSTOFA-TRANSFORMING"
        }
    },
    "59_main": {
        "characters": {
            "magnus": "MAGNUS-BREAKING",
            "sigrid": "SIGRID-DUAL"
        },
        "environment": {
            "interior": "BADSTOFA-MONUMENT"
        }
    },
    "59a_main": {
        "characters": {
            "magnus": "MAGNUS-RAM",
            "sigrid": "SIGRID-CORVID"
        },
        "environment": {
            "interior": "BADSTOFA-MONUMENT"
        }
    },
    "60_main": {
        "characters": {
            "sigrid": "SIGRID-CORVID"
        },
        "environment": {
            "landscape": "WESTFJORDS-ETERNAL"
        }
    },
    "61_main": {
        "characters": {
            "sigrid": "SIGRID-CORVID"
        },
        "environment": {
            "landscape": "WESTFJORDS-ETERNAL"
        }
    },
    "62_main": {
        "characters": {
            "sigrid": "SIGRID-CORVID"
        },
        "environment": {
            "landscape": "WESTFJORDS-ETERNAL"
        }
    }
}

# Character plate descriptions (simplified for testing)
CHARACTER_PLATES = {
    "MAGNUS-AUTHORITY": {
        "name": "Summer Authority",
        "description": "Magnús Þorláksson, 55-year-old fisherman with weathered rectangular face, steel-blue eyes focused with traditional hunting intelligence, clean brown vaðmál sweater with skilled mending at left elbow, erect confident posture"
    },
    "MAGNUS-CONFUSED": {
        "name": "Mathematical Breakdown",
        "description": "Magnús with weathered rectangular face showing authority cracking, steel-blue eyes unfocused with thousand-yard mathematical stare, gripping driftwood cane white-knuckle tight, hunched posture with defensive shoulder positioning"
    },
    "MAGNUS-PREDATOR": {
        "name": "Violence Ready",
        "description": "Magnús with 0Hz hands (perfect stillness frequency) creating visible -25°C local temperature drop, predatory focus replacing defeat, cane gripped as weapon"
    },
    "MAGNUS-POSSESSOR": {
        "name": "Territorial Claim",
        "description": "Magnús with predatory intimacy, jaw soft with false tenderness, eyes showing predatory affection mixing threat with seeming care, hands at perfect 0Hz for gentle violation"
    },
    "MAGNUS-RAM": {
        "name": "Ram Form",
        "description": "Magnificent Icelandic ram with curved horns, pure white wool, wearing brown vaðmál sweater inside-out, steel-blue ram eyes showing human consciousness trapped"
    },
    "SIGRID-PURE": {
        "name": "Untouched Innocence",
        "description": "Sigrid, 23-year-old with heart-shaped face, grey eyes with amber flecks, maintaining 8-foot comfortable distance, pristine black wool dress"
    },
    "SIGRID-AWAKENING": {
        "name": "Growing Awareness",
        "description": "Sigrid with heart-shaped face sharp with growing intelligence, grey eyes with amber flecks brightening, positioned exactly 11 feet maintaining defensive spacing"
    },
    "SIGRID-CALCULATING": {
        "name": "Analytical Assessment",
        "description": "Sigrid with heart-shaped face sharp with analytical intelligence, grey eyes with amber flecks bright from mathematical awareness, positioned exactly 11 feet maintaining defensive spacing"
    },
    "SIGRID-CORNERED": {
        "name": "Trapped",
        "description": "Sigrid pressed against wall, maintaining 11 feet but wall prevents retreat, breathing 15/min fear response, klettagjá cracks forming behind spelling 'VITNI' (witness)"
    },
    "SIGRID-CORVID": {
        "name": "Raven Form",
        "description": "Sigrid as magnificent raven with glossy black feathers, human intelligence visible in corvid eyes, eternal witness consciousness"
    },
    "GUDRUN-ABUNDANT": {
        "name": "Competent Mother",
        "description": "Guðrún, 42-year-old with oval face, pristine traditional faldbúningur with silver filigree, competent maternal authority"
    },
    "GUDRUN-PRODUCING": {
        "name": "Wool Emergence",
        "description": "Guðrún with 15mm wool growth visible under collar, faldbúningur showing stress wear, counting confusion visible"
    },
    "GUDRUN-BEATEN": {
        "name": "Violence Survivor",
        "description": "Guðrún with bruising, maintaining dignity despite violence, wool growth 30mm creating visible ridge"
    },
    "GUDRUN-EWE": {
        "name": "Ewe Form",
        "description": "Guðrún as Icelandic ewe with thick grey-brown wool, wearing tattered faldbúningur remnants, human consciousness retained"
    },
    "JON-MILD": {
        "name": "Early Fever",
        "description": "Jón, 16-year-old with narrow angular face, 39°C fever creating slight flush, prophetic glimpses visible in dilated pupils"
    },
    "JON-PROPHET": {
        "name": "Fever Prophet",
        "description": "Jón with 41°C fever, temporal sight active, seeing multiple timelines simultaneously, gap-toothed from transformation"
    },
    "JON-LAMB": {
        "name": "Lamb Form",
        "description": "Jón as young ram lamb with soft grey wool, simple animal consciousness, following flock instinct"
    },
    "LILJA-PURE": {
        "name": "Perfect Innocence",
        "description": "Lilja, 12-year-old with round cherubic face, wide green eyes, perfect childhood wonder"
    },
    "LILJA-MATHEMATICAL": {
        "name": "Truth Recognition",
        "description": "Lilja recognizing counting impossibility, child truth-telling about obvious mathematical failures"
    },
    "LILJA-LAMB": {
        "name": "Lamb Form",
        "description": "Lilja as small ewe lamb with pure white wool, innocent animal awareness"
    }
}

# Environmental plate descriptions
ENVIRONMENTAL_PLATES = {
    "BADSTOFA-ORGANIC": {
        "name": "House Breathing Revealed",
        "description": "Baðstofa with driftwood beams flexing like ribs during house breathing, turf walls showing blood vessel patterns"
    },
    "BADSTOFA-CLIFF": {
        "name": "Klettagjá Emerging",
        "description": "Baðstofa with vertical crack widening in wall, spelling 'VITNI' in crack patterns, escape route forming"
    },
    "BADSTOFA-MONUMENT": {
        "name": "Becoming Obelisk",
        "description": "Baðstofa crystallizing into black obsidian monument, walls becoming volcanic glass, 30-foot obelisk emerging"
    },
    "WESTFJORDS-HOSTILE": {
        "name": "Winter Hostile",
        "description": "Westfjords landscape in extreme winter, -40°C temperatures, horizontal ice-rain, survival impossible"
    },
    "WESTFJORDS-ETERNAL": {
        "name": "Monument Landscape",
        "description": "Westfjords with black obsidian obelisk visible, eternal monument to family tragedy"
    },
    "SEA-INDUSTRIAL": {
        "name": "Trawler Contamination",
        "description": "North Atlantic with industrial trawlers visible, diesel rainbow on water, modernity corrupting traditional waters"
    },
    "DANISH-COLD-SPREADING": {
        "name": "Administrative Temperature",
        "description": "Danish language creating environmental coldness, administrative vocabulary affecting physical temperature"
    }
}

def update_shot_with_plates(shot_file, plate_mapping):
    """Update a shot JSON file with plate data"""
    
    # Read existing shot
    with open(shot_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Get shot ID from filename
    filename = os.path.basename(shot_file)
    
    # Try to match shot ID with our mapping
    shot_id = None
    for key in plate_mapping.keys():
        if key.replace('_', '') in filename.lower() or key in filename.lower():
            shot_id = key
            break
    
    if not shot_id:
        # Try to extract shot number from metadata
        if 'shot_metadata' in data:
            meta_id = data['shot_metadata'].get('id', '')
            # Check if this ID is in our mapping
            for key in plate_mapping.keys():
                if meta_id in key or key.replace('_main', '').replace('_prologue', '') == meta_id:
                    shot_id = key
                    break
    
    if not shot_id or shot_id not in plate_mapping:
        print(f"  ⚠️  No mapping found for {filename}")
        return False
    
    mapping = plate_mapping[shot_id]
    
    # Update each prompt variant
    if 'prompt_variants' in data:
        for variant in data['prompt_variants']:
            # Add available plates
            variant['available_plates'] = {
                'characters': {},
                'environment': {}
            }
            
            # Add character plates
            for char_key, plate_id in mapping.get('characters', {}).items():
                if plate_id in CHARACTER_PLATES:
                    plate = CHARACTER_PLATES[plate_id]
                    variant['available_plates']['characters'][char_key] = [{
                        'id': plate_id,
                        'name': plate['name'],
                        'description': plate['description']
                    }]
            
            # Add environment plates
            for env_key, plate_id in mapping.get('environment', {}).items():
                if plate_id in ENVIRONMENTAL_PLATES:
                    plate = ENVIRONMENTAL_PLATES[plate_id]
                    variant['available_plates']['environment'][env_key] = [{
                        'id': plate_id,
                        'name': plate['name'],
                        'description': plate['description']
                    }]
            
            # Set selected plates (defaults to first available)
            variant['selected_plates'] = {
                'characters': {},
                'environment': {}
            }
            
            for char_key, plate_id in mapping.get('characters', {}).items():
                variant['selected_plates']['characters'][char_key] = plate_id
            
            for env_key, plate_id in mapping.get('environment', {}).items():
                variant['selected_plates']['environment'][env_key] = plate_id
    
    # Save updated file
    with open(shot_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    print(f"  ✅ Updated {os.path.basename(shot_file)}")
    print(f"     Characters: {list(mapping.get('characters', {}).keys())}")
    print(f"     Environment: {list(mapping.get('environment', {}).keys())}")
    return True

def main():
    shots_dir = "/Users/ingthor/Documents/stories/appdata/json/5/shots/json"
    
    print("=" * 60)
    print("PLATE MAPPING INTEGRATION")
    print("=" * 60)
    
    # Get all shot files
    shot_files = list(Path(shots_dir).glob("*.json"))
    print(f"\nFound {len(shot_files)} shot files")
    
    # Update shots with mappings
    updated = 0
    for shot_file in shot_files:
        if update_shot_with_plates(shot_file, SHOT_PLATE_MAPPING):
            updated += 1
    
    print("\n" + "=" * 60)
    print(f"COMPLETE: Updated {updated}/{len(shot_files)} shots with plate mappings")
    print("=" * 60)

if __name__ == "__main__":
    main()