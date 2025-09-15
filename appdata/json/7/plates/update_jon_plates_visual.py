#!/usr/bin/env python3
"""
Update Jon's character plates with visual descriptions focusing on appearance.
Maintains all original plate IDs and references while removing action-based descriptions.
"""

import json

# Define Jon plates with visual descriptions only
JON_PLATES_VISUAL = {
    "JON-MASTER": {
        "description": "Jón Magnússon, 8-year-old Westfjords boy with round cherubic face, small upturned nose slightly reddened from cold, hazel eyes with distinct green-brown flecks showing unusual depth, sandy brown hair falling over forehead in damp wisps, thin shoulders lost in oversized brown vaðmál wool sweater that reaches past his hands, dark wool trousers mended at both knees with lighter patches, thick grey wool stockings bunched at ankles, scuffed leather shoes too large for his feet, pale complexion with faint pink flush at cheeks, delicate hands with dirt under fingernails",
        "shot_range": "",
        "character": "Jon",
        "name": "Jon Master",
        "is_master": True
    },
    "JON-MILD": {
        "character": "Jon",
        "shot_range": "",
        "name": "Mild",
        "description": "[JON-MASTER] with early temporal awareness - pupils slightly dilated giving eyes luminous quality, face flushed with warmth despite cold room, hair slightly lifted as if by static, oversized sweater hanging looser as shoulders hunch forward, fingers stained with dust, subtle tremor in hands, lips moving silently, thin perspiration on forehead catching lamplight",
        "is_master": False
    },
    "JON-RISING": {
        "character": "Jon",
        "name": "Rising",
        "description": "[JON-MILD] with mathematical intensity - deep furrow between eyebrows, eyes darting rapidly as if reading invisible text, both hands raised with fingers extended for counting, hair disheveled with strands at odd angles, mouth slightly open with tongue tip visible, head tilted questioning, sweater sleeves pushed up revealing thin wrists, face showing confusion mixed with revelation",
        "shot_range": "",
        "is_master": False
    },
    "JON-SEEING": {
        "shot_range": "",
        "description": "[JON-RISING] in full prophetic state - face unnaturally serene for child, eyes unfocused yet alert with whites slightly visible, hair moving without breeze, sweater draped naturally as if suddenly grown into, skin with subtle translucent quality in lamplight, hands perfectly still with palms forward, unnaturally straight posture for 8-year-old, expression simultaneously young and ancient",
        "character": "Jon",
        "name": "Seeing",
        "is_master": False
    },
    "JON-TEMPORAL": {
        "description": "[JON-SEEING] showing temporal overlay - face appearing multiple ages simultaneously, eyes reflecting colors not in room, slight double exposure effect around body edges, hair appearing different lengths in peripheral vision, sweater showing future wear patterns, hands appearing both child and adult sized depending on angle, expression cycling through emotions rapidly, skin with goosebumps in runic patterns",
        "character": "Jon",
        "shot_range": "",
        "is_master": False,
        "name": "Temporal"
    },
    "JON-PROPHET": {
        "character": "Jon",
        "description": "[JON-TEMPORAL] with prophetic illumination - face lit by subtle green aurora glow, eyes reflecting distant fire pinpoints, hair floating slightly underwater-like, sweater showing impossible shadows, fingers occasionally transparent, breath visible forming brief runes in cold air, skin with oil-on-water iridescence, expression too mature for child features",
        "shot_range": "",
        "name": "Prophet",
        "is_master": False
    },
    "JON-WANDERING": {
        "description": "[JON-TEMPORAL] in exploration - face alert with purpose, eyes bright and fever-glossy, dust patterns on hands, knees freshly dirty from kneeling, hair falling across one eye, sweater twisted revealing undershirt, shoes leaving unusual dust patterns, complexion alternating flush and pallor, small hand scratches resembling script",
        "is_master": False,
        "shot_range": "",
        "character": "Jon",
        "name": "Wandering"
    },
    "JON-ENERGETIC": {
        "shot_range": "",
        "character": "Jon",
        "name": "Energetic",
        "description": "[JON-PROPHET] with witness intensity - face of one who's seen too much, eyes wide and unblinking with visible blood vessels, hair damp despite cold, sweater dark with moisture at collar, hands in small white-knuckled fists, jaw clenched giving angular quality, visible temple pulse, wide grounded stance unusual for child, grey-pale photographic skin tone",
        "is_master": False
    },
    "JON-MISSION": {
        "character": "Jon",
        "is_master": False,
        "description": "[JON-PROPHET] focused determination - face set beyond his years, index finger darkened with floor grime, dust giving hair greyish cast, sweater sleeves rolled exposing thin veined forearms, tongue slightly protruding in concentration, knees worn through patches, toe-scuffed shoes, expression of crucial puzzle-solving, intense squinting focus",
        "shot_range": "",
        "name": "Mission"
    },
    "JON-EMERGING": {
        "name": "Emerging",
        "character": "Jon",
        "description": "[JON-TEMPORAL] between forms - face with subtle jaw elongation, eyes showing horizontal pupil dilation in light, hair woollier at temples and nape, shoulders hunched suggesting different anatomy, hands curled hiding changes, sweater hanging differently, skin with faint lanolin sheen, peaceful expression despite changes, ears positioned slightly higher",
        "shot_range": "",
        "is_master": False
    },
    "JON-FITTING": {
        "is_master": False,
        "character": "Jon",
        "shot_range": "",
        "description": "[JON-SEEING] in serious play - face bright with childish concentration, pockets bulging with small objects, dirt circles on knees, hair tousled from movement, sweater twisted from activity, dirty nimble hands, expression of important childhood games, pink exertion cheeks, gap-toothed smile when pleased",
        "name": "Fitting"
    },
    "JON-CHANGING": {
        "character": "Jon",
        "name": "Changing",
        "shot_range": "",
        "is_master": False,
        "description": "[JON-TEMPORAL] accepting transformation - face serene with acceptance, body lower with weight on hands, fingers showing early fusion, hair coarsening at crown, sweater riding up revealing white down on lower back, knees bending differently, expression of relief not fear, thicker skin patches at joints"
    },
    "JON-LAMB": {
        "shot_range": "",
        "is_master": False,
        "character": "Jon",
        "name": "Lamb",
        "description": "[JON-CHANGING] mid-transformation - torn sweater revealing white wool beneath (garment or growth unclear), elongated face with flattening nose bridge, human intelligence in ovine features, hands/hooves as overlapping realities, impossible posture neither upright nor quadrupedal, hair/wool indistinguishable at hairline, clothes hanging wrong on changing frame",
    },
    "JON-GAPPED": {
        "character": "Jon",
        "shot_range": "",
        "description": "[JON-CHANGING] with gap-toothed revelation - mouth open showing missing front teeth, lamb-like appearance, fingers splayed with slight webbing, face lit with understanding, hair electrified by realization, sweater hanging loose on shrinking body, eyes wide with mathematical impossibility, expression of terrible puzzle solved",
        "name": "Gapped",
        "is_master": False
    },
    "JON-GRINDING": {
        "shot_range": "",
        "character": "Jon",
        "is_master": False,
        "description": "[JON-LAMB] with circular jaw motion - lower jaw grinding without food, mixed human/herbivore teeth visible, wool covering body except torn sweater areas, hazel eyes with rectangular pupils, elongated ovine muzzle retaining boyish eye area, all fours with occasional upright attempts, tattered clothes over wool",
        "name": "Grinding"
    },
    "JON-LOSING": {
        "name": "Losing",
        "character": "Jon",
        "is_master": False,
        "shot_range": "",
        "description": "[JON-LAMB] predominantly sheep - face mostly ovine with hint of boy in eyes, fully quadrupedal, sweater remnants like shed skin on wool, clear hooves where hands were, mobile ears relocated to skull sides, thick lanolin-sheened wool coat, only human element in intelligent gaze, peaceful release expression"
    },
    "JON-MASTERING": {
        "character": "Jon",
        "description": "[JON-TEMPORAL] mastering forms - face showing all ages in multiple exposure (infant/boy/elder/lamb), ancient innocent eyes, body occupying multiple positions creating blur, sweater both new and threadbare, hair simultaneously brown and white wool, hands/hooves superimposed, expression cycling through all emotions rapidly, translucent skin showing vessels and wool follicles",
        "name": "Mastering",
        "shot_range": "",
        "is_master": False
    },
    "JON-FINAL": {
        "character": "Jon",
        "description": "[JON-MASTERING] at threshold - face luminous with terrible joy, streaming tears but ecstatic expression, mouth open with visible frost breath, body between standing and falling to fours, sweater falling revealing transformation, hands in counting gesture becoming hooves, hair/wool corona around head, eyes reflecting nuclear flash not lamplight, expression of child seeing beginning and end",
        "name": "Final",
        "shot_range": "",
        "is_master": False
    }
}

def update_jon_plates():
    """Update the character plates JSON file with visual Jon descriptions."""

    # Read the current plates file
    with open('character_plates_complete.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Update each Jon plate
    updated_count = 0
    for plate_id, plate_data in JON_PLATES_VISUAL.items():
        if plate_id in data['plate_index']:
            # Update the plate while preserving any other fields
            data['plate_index'][plate_id].update(plate_data)
            print(f"Updated {plate_id}")
            updated_count += 1
        else:
            # Add new plate if it doesn't exist
            data['plate_index'][plate_id] = plate_data
            print(f"Added new plate {plate_id}")
            updated_count += 1

    # Save the updated file
    with open('character_plates_complete.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"\nSuccessfully updated {updated_count} Jon plates")
    print("Changes made:")
    print("- Focused on visual appearance rather than actions")
    print("- Maintained temporal prophet narrative through physical descriptions")
    print("- Kept all original plate IDs and references intact")
    print("- Emphasized transformation as visual progression")
    print("- Removed medical terminology while keeping physical changes")

if __name__ == "__main__":
    update_jon_plates()