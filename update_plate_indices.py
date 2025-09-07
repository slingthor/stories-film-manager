#!/usr/bin/env python3

import json
import os

# Update plate indices to mark master plates

CHARACTER_PLATES = {
    # Magnus plates - AUTHORITY is the main/master for UI
    "MAGNUS-AUTHORITY": {
        "name": "Magnus Base",
        "character": "magnus",
        "is_master": True,  # This is the main plate for Magnus
        "description": "Magnús Þorláksson, 55-year-old fisherman with weathered rectangular face, steel-blue eyes, traditional authority",
        "tags": ["prologue", "authority", "summer"]
    },
    "MAGNUS-CONFUSED": {
        "name": "Mathematical Breakdown",
        "character": "magnus",
        "description": "Magnús with weathered rectangular face showing authority cracking, steel-blue eyes unfocused with thousand-yard mathematical stare",
        "tags": ["main", "breakdown", "confusion"]
    },
    "MAGNUS-PREDATOR": {
        "name": "Violence Ready",
        "character": "magnus",
        "description": "Magnús with 0Hz hands (perfect stillness frequency) creating visible -25°C local temperature drop",
        "tags": ["main", "violence", "predator"]
    },
    "MAGNUS-POSSESSOR": {
        "name": "Territorial Claim",
        "character": "magnus",
        "description": "Magnús with predatory intimacy, jaw soft with false tenderness, eyes showing predatory affection",
        "tags": ["main", "incest", "possession"]
    },
    "MAGNUS-ENFORCER": {
        "name": "Authority Restored",
        "character": "magnus", 
        "description": "Magnús after domestic violence, clothing straightened suggesting authority restoration",
        "tags": ["main", "violence", "dominance"]
    },
    "MAGNUS-RAM": {
        "name": "Ram Form",
        "character": "magnus",
        "description": "Magnificent Icelandic ram with curved horns, pure white wool, wearing brown vaðmál sweater inside-out",
        "tags": ["transformation", "ram", "final"]
    },
    
    # Sigrid plates - PURE is the main/master
    "SIGRID-PURE": {
        "name": "Sigrid Base",
        "character": "sigrid",
        "is_master": True,  # Main plate for Sigrid
        "description": "Sigrid, 23-year-old with heart-shaped face, grey eyes with amber flecks, pristine black wool dress",
        "tags": ["prologue", "innocence", "pure"]
    },
    "SIGRID-AWAKENING": {
        "name": "Growing Awareness",
        "character": "sigrid",
        "description": "Sigrid with heart-shaped face sharp with growing intelligence, positioned exactly 11 feet maintaining defensive spacing",
        "tags": ["prologue", "awakening", "awareness"]
    },
    "SIGRID-MARKED": {
        "name": "Post-Violation",
        "character": "sigrid",
        "description": "Sigrid maintaining maximum distance, eyes showing violation awareness, defensive positioning constant",
        "tags": ["main", "violation", "marked"]
    },
    "SIGRID-CALCULATING": {
        "name": "Analytical Assessment",
        "character": "sigrid",
        "description": "Sigrid with heart-shaped face sharp with analytical intelligence, grey eyes bright from mathematical awareness",
        "tags": ["main", "analytical", "mathematical"]
    },
    "SIGRID-CORNERED": {
        "name": "Trapped",
        "character": "sigrid",
        "description": "Sigrid pressed against wall, maintaining 11 feet but wall prevents retreat, klettagjá cracks forming behind",
        "tags": ["main", "trapped", "violence"]
    },
    "SIGRID-CORVID": {
        "name": "Raven Form",
        "character": "sigrid",
        "description": "Sigrid as magnificent raven with glossy black feathers, human intelligence visible in corvid eyes",
        "tags": ["transformation", "raven", "final"]
    },
    
    # Gudrun plates - ABUNDANT is the main/master
    "GUDRUN-ABUNDANT": {
        "name": "Gudrun Base",
        "character": "gudrun",
        "is_master": True,  # Main plate for Gudrun
        "description": "Guðrún, 42-year-old with oval face, pristine traditional faldbúningur with silver filigree",
        "tags": ["prologue", "mother", "abundant"]
    },
    "GUDRUN-PRODUCING": {
        "name": "Wool Emergence",
        "character": "gudrun",
        "description": "Guðrún with 15mm wool growth visible under collar, faldbúningur showing stress wear",
        "tags": ["main", "wool", "transformation"]
    },
    "GUDRUN-BEATEN": {
        "name": "Violence Survivor",
        "character": "gudrun",
        "description": "Guðrún with bruising, maintaining dignity despite violence, wool growth 30mm creating visible ridge",
        "tags": ["main", "violence", "beaten"]
    },
    "GUDRUN-EWE": {
        "name": "Ewe Form",
        "character": "gudrun",
        "description": "Guðrún as Icelandic ewe with thick grey-brown wool, wearing tattered faldbúningur remnants",
        "tags": ["transformation", "ewe", "final"]
    },
    
    # Jon plates - MILD is the main/master
    "JON-MILD": {
        "name": "Jon Base",
        "character": "jon",
        "is_master": True,  # Main plate for Jon
        "description": "Jón, 16-year-old with narrow angular face, 39°C fever creating slight flush",
        "tags": ["prologue", "fever", "mild"]
    },
    "JON-PROPHET": {
        "name": "Fever Prophet",
        "character": "jon",
        "description": "Jón with 41°C fever, temporal sight active, seeing multiple timelines simultaneously",
        "tags": ["main", "prophet", "fever"]
    },
    "JON-LAMB": {
        "name": "Lamb Form",
        "character": "jon",
        "description": "Jón as young ram lamb with soft grey wool, simple animal consciousness",
        "tags": ["transformation", "lamb", "final"]
    },
    
    # Lilja plates - PURE is the main/master
    "LILJA-PURE": {
        "name": "Lilja Base",
        "character": "lilja",
        "is_master": True,  # Main plate for Lilja
        "description": "Lilja, 12-year-old with round cherubic face, wide green eyes, perfect childhood wonder",
        "tags": ["prologue", "innocence", "pure"]
    },
    "LILJA-MATHEMATICAL": {
        "name": "Truth Recognition",
        "character": "lilja",
        "description": "Lilja recognizing counting impossibility, child truth-telling about obvious mathematical failures",
        "tags": ["main", "mathematical", "truth"]
    },
    "LILJA-LAMB": {
        "name": "Lamb Form",
        "character": "lilja",
        "description": "Lilja as small ewe lamb with pure white wool, innocent animal awareness",
        "tags": ["transformation", "lamb", "final"]
    }
}

ENVIRONMENTAL_PLATES = {
    "BADSTOFA-ORGANIC": {
        "name": "House Breathing Revealed",
        "category": "interior",
        "description": "Baðstofa with driftwood beams flexing like ribs during house breathing",
        "tags": ["organic", "breathing", "alive"]
    },
    "BADSTOFA-CLIFF": {
        "name": "Klettagjá Emerging",
        "category": "interior",
        "description": "Baðstofa with vertical crack widening in wall, spelling 'VITNI' in crack patterns",
        "tags": ["escape", "cliff", "witness"]
    },
    "BADSTOFA-VIOLENCE": {
        "name": "Violence Space",
        "category": "interior",
        "description": "Baðstofa during violence, shadows wrong angles, walls perspiring fear",
        "tags": ["violence", "fear", "protest"]
    },
    "BADSTOFA-MONUMENT": {
        "name": "Becoming Obelisk",
        "category": "interior",
        "description": "Baðstofa crystallizing into black obsidian monument, walls becoming volcanic glass",
        "tags": ["transformation", "monument", "obsidian"]
    },
    "WESTFJORDS-HOSTILE": {
        "name": "Winter Hostile",
        "category": "landscape",
        "description": "Westfjords landscape in extreme winter, -40°C temperatures, horizontal ice-rain",
        "tags": ["winter", "hostile", "death"]
    },
    "WESTFJORDS-ETERNAL": {
        "name": "Monument Landscape",
        "category": "landscape",
        "description": "Westfjords with black obsidian obelisk visible, eternal monument to family tragedy",
        "tags": ["eternal", "monument", "witness"]
    },
    "SEA-INDUSTRIAL": {
        "name": "Trawler Contamination",
        "category": "sea",
        "description": "North Atlantic with industrial trawlers visible, diesel rainbow on water",
        "tags": ["industrial", "contamination", "modern"]
    },
    "DANISH-COLD-SPREADING": {
        "name": "Administrative Temperature",
        "category": "weather",
        "description": "Danish language creating environmental coldness, administrative vocabulary affecting physical temperature",
        "tags": ["danish", "cold", "administrative"]
    }
}

def update_indices():
    base_path = "/Users/ingthor/Documents/stories/appdata/json/5/plate_indices"
    
    # Create character plates index
    char_index = {
        "plate_index": CHARACTER_PLATES
    }
    
    with open(f"{base_path}/character_plates.json", 'w', encoding='utf-8') as f:
        json.dump(char_index, f, indent=2, ensure_ascii=False)
    
    # Count master plates
    master_count = sum(1 for p in CHARACTER_PLATES.values() if p.get('is_master', False))
    print(f"✅ Updated character_plates.json with {len(CHARACTER_PLATES)} plates ({master_count} master plates)")
    
    # List master plates
    print("\nMaster plates:")
    for plate_id, plate in CHARACTER_PLATES.items():
        if plate.get('is_master', False):
            print(f"  - {plate['character'].title()}: {plate_id}")
    
    # Create environmental plates index (unchanged)
    env_index = {
        "plate_index": ENVIRONMENTAL_PLATES
    }
    
    with open(f"{base_path}/environmental_plates.json", 'w', encoding='utf-8') as f:
        json.dump(env_index, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ Environmental plates unchanged: {len(ENVIRONMENTAL_PLATES)} plates")

if __name__ == "__main__":
    update_indices()