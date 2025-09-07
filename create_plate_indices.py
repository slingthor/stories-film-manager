#!/usr/bin/env python3

import json
import os

# Create plate indices for the app to load

CHARACTER_PLATES = {
    "MAGNUS-AUTHORITY": {
        "name": "Summer Authority",
        "character": "magnus",
        "description": "Magnús Þorláksson, 55-year-old fisherman with weathered rectangular face, steel-blue eyes focused with traditional hunting intelligence, clean brown vaðmál sweater with skilled mending at left elbow, erect confident posture",
        "tags": ["prologue", "authority", "summer"]
    },
    "MAGNUS-CONFUSED": {
        "name": "Mathematical Breakdown",
        "character": "magnus",
        "description": "Magnús with weathered rectangular face showing authority cracking, steel-blue eyes unfocused with thousand-yard mathematical stare, gripping driftwood cane white-knuckle tight, hunched posture with defensive shoulder positioning",
        "tags": ["main", "breakdown", "confusion"]
    },
    "MAGNUS-PREDATOR": {
        "name": "Violence Ready",
        "character": "magnus",
        "description": "Magnús with 0Hz hands (perfect stillness frequency) creating visible -25°C local temperature drop, predatory focus replacing defeat, cane gripped as weapon",
        "tags": ["main", "violence", "predator"]
    },
    "MAGNUS-POSSESSOR": {
        "name": "Territorial Claim",
        "character": "magnus",
        "description": "Magnús with predatory intimacy, jaw soft with false tenderness, eyes showing predatory affection mixing threat with seeming care, hands at perfect 0Hz for gentle violation",
        "tags": ["main", "incest", "possession"]
    },
    "MAGNUS-ENFORCER": {
        "name": "Authority Restored",
        "character": "magnus", 
        "description": "Magnús after domestic violence, clothing straightened suggesting authority restoration, upright posture showing dominance reestablished",
        "tags": ["main", "violence", "dominance"]
    },
    "MAGNUS-RAM": {
        "name": "Ram Form",
        "character": "magnus",
        "description": "Magnificent Icelandic ram with curved horns, pure white wool, wearing brown vaðmál sweater inside-out, steel-blue ram eyes showing human consciousness trapped",
        "tags": ["transformation", "ram", "final"]
    },
    "SIGRID-PURE": {
        "name": "Untouched Innocence",
        "character": "sigrid",
        "description": "Sigrid, 23-year-old with heart-shaped face, grey eyes with amber flecks, maintaining 8-foot comfortable distance, pristine black wool dress",
        "tags": ["prologue", "innocence", "pure"]
    },
    "SIGRID-AWAKENING": {
        "name": "Growing Awareness",
        "character": "sigrid",
        "description": "Sigrid with heart-shaped face sharp with growing intelligence, grey eyes with amber flecks brightening, positioned exactly 11 feet maintaining defensive spacing",
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
        "description": "Sigrid with heart-shaped face sharp with analytical intelligence, grey eyes with amber flecks bright from mathematical awareness, positioned exactly 11 feet maintaining defensive spacing",
        "tags": ["main", "analytical", "mathematical"]
    },
    "SIGRID-CORNERED": {
        "name": "Trapped",
        "character": "sigrid",
        "description": "Sigrid pressed against wall, maintaining 11 feet but wall prevents retreat, breathing 15/min fear response, klettagjá cracks forming behind spelling 'VITNI' (witness)",
        "tags": ["main", "trapped", "violence"]
    },
    "SIGRID-CORVID": {
        "name": "Raven Form",
        "character": "sigrid",
        "description": "Sigrid as magnificent raven with glossy black feathers, human intelligence visible in corvid eyes, eternal witness consciousness",
        "tags": ["transformation", "raven", "final"]
    },
    "GUDRUN-ABUNDANT": {
        "name": "Competent Mother",
        "character": "gudrun",
        "description": "Guðrún, 42-year-old with oval face, pristine traditional faldbúningur with silver filigree, competent maternal authority",
        "tags": ["prologue", "mother", "abundant"]
    },
    "GUDRUN-PRODUCING": {
        "name": "Wool Emergence",
        "character": "gudrun",
        "description": "Guðrún with 15mm wool growth visible under collar, faldbúningur showing stress wear, counting confusion visible",
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
        "description": "Guðrún as Icelandic ewe with thick grey-brown wool, wearing tattered faldbúningur remnants, human consciousness retained",
        "tags": ["transformation", "ewe", "final"]
    },
    "JON-MILD": {
        "name": "Early Fever",
        "character": "jon",
        "description": "Jón, 16-year-old with narrow angular face, 39°C fever creating slight flush, prophetic glimpses visible in dilated pupils",
        "tags": ["prologue", "fever", "mild"]
    },
    "JON-PROPHET": {
        "name": "Fever Prophet",
        "character": "jon",
        "description": "Jón with 41°C fever, temporal sight active, seeing multiple timelines simultaneously, gap-toothed from transformation",
        "tags": ["main", "prophet", "fever"]
    },
    "JON-LAMB": {
        "name": "Lamb Form",
        "character": "jon",
        "description": "Jón as young ram lamb with soft grey wool, simple animal consciousness, following flock instinct",
        "tags": ["transformation", "lamb", "final"]
    },
    "LILJA-PURE": {
        "name": "Perfect Innocence",
        "character": "lilja",
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
        "description": "Baðstofa with driftwood beams flexing like ribs during house breathing, turf walls showing blood vessel patterns",
        "tags": ["organic", "breathing", "alive"]
    },
    "BADSTOFA-CLIFF": {
        "name": "Klettagjá Emerging",
        "category": "interior",
        "description": "Baðstofa with vertical crack widening in wall, spelling 'VITNI' in crack patterns, escape route forming",
        "tags": ["escape", "cliff", "witness"]
    },
    "BADSTOFA-VIOLENCE": {
        "name": "Violence Space",
        "category": "interior",
        "description": "Baðstofa during violence, shadows wrong angles, walls perspiring fear, beams groaning protest",
        "tags": ["violence", "fear", "protest"]
    },
    "BADSTOFA-MONUMENT": {
        "name": "Becoming Obelisk",
        "category": "interior",
        "description": "Baðstofa crystallizing into black obsidian monument, walls becoming volcanic glass, 30-foot obelisk emerging",
        "tags": ["transformation", "monument", "obsidian"]
    },
    "WESTFJORDS-HOSTILE": {
        "name": "Winter Hostile",
        "category": "landscape",
        "description": "Westfjords landscape in extreme winter, -40°C temperatures, horizontal ice-rain, survival impossible",
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
        "description": "North Atlantic with industrial trawlers visible, diesel rainbow on water, modernity corrupting traditional waters",
        "tags": ["industrial", "contamination", "modern"]
    },
    "DANISH-COLD-SPREADING": {
        "name": "Administrative Temperature",
        "category": "weather",
        "description": "Danish language creating environmental coldness, administrative vocabulary affecting physical temperature",
        "tags": ["danish", "cold", "administrative"]
    }
}

def create_indices():
    base_path = "/Users/ingthor/Documents/stories/appdata/json/5/plate_indices"
    
    # Create directory if it doesn't exist
    os.makedirs(base_path, exist_ok=True)
    
    # Create character plates index
    char_index = {
        "plate_index": CHARACTER_PLATES
    }
    
    with open(f"{base_path}/character_plates.json", 'w', encoding='utf-8') as f:
        json.dump(char_index, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Created character_plates.json with {len(CHARACTER_PLATES)} plates")
    
    # Create environmental plates index
    env_index = {
        "plate_index": ENVIRONMENTAL_PLATES
    }
    
    with open(f"{base_path}/environmental_plates.json", 'w', encoding='utf-8') as f:
        json.dump(env_index, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Created environmental_plates.json with {len(ENVIRONMENTAL_PLATES)} plates")
    
    # Also create in resources directory for compatibility
    resources_path = "/Users/ingthor/Documents/stories/appdata/resources/plates"
    os.makedirs(resources_path, exist_ok=True)
    
    with open(f"{resources_path}/character_plates.json", 'w', encoding='utf-8') as f:
        json.dump(char_index, f, indent=2, ensure_ascii=False)
    
    with open(f"{resources_path}/environmental_plates.json", 'w', encoding='utf-8') as f:
        json.dump(env_index, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Also created copies in resources/plates directory")

if __name__ == "__main__":
    create_indices()