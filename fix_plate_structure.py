#!/usr/bin/env python3
"""
Fix character plate structure and references:
1. Flatten nested structure (remove plate_index nesting)
2. Convert plate IDs to proper format (e.g., "sigrid_7" -> "SIGRID-PLATE7")
3. Fix all bracket references to use proper plate IDs
"""

import json
import re
from datetime import datetime

def convert_plate_id(old_id):
    """Convert old plate ID format to new format"""
    # Handle master plates
    if 'master' in old_id.lower():
        char = old_id.split('_')[0].upper()
        return f"{char}-MASTER"

    # Parse character and number from old ID
    parts = old_id.split('_')
    if len(parts) != 2:
        return old_id.upper()

    char = parts[0].upper()
    num = parts[1]

    # Map character names properly
    char_map = {
        'MAGNUS': 'MAGNÚS',
        'GUDRUN': 'GUÐRÚN',
        'JON': 'JÓN',
        'LILJA': 'LILJA',
        'SIGRID': 'SIGRID'
    }

    char = char_map.get(char, char)
    return f"{char}-PLATE{num}"

def fix_bracket_references(description):
    """Fix bracket references in descriptions"""
    if not description:
        return description

    # Mapping of bad references to correct plate IDs
    reference_map = {
        '[Master base]': '[MAGNÚS-MASTER]',
        '[Summer base]': '[MAGNÚS-SUMMER]',
        '[Abundant base]': '[GUÐRÚN-MASTER]',
        '[Pure base]': '[SIGRID-PURE]',
        '[Knowing base]': '[LILJA-MASTER]',
        '[Mild base]': '[JÓN-MASTER]',
        '[Oracle base]': '[SIGRID-ORACLE]',
        '[Summoning base]': '[SIGRID-SUMMONING]',
        '[Cornered base]': '[SIGRID-CORNERED]',
        '[Awakening base]': '[SIGRID-AWAKENING]',
        '[Marked base]': '[SIGRID-MARKED]',
        '[Chosen base]': '[SIGRID-CHOSEN]',
        '[Becoming base]': '[SIGRID-BECOMING]',
        '[Transitional base]': '[SIGRID-TRANSITIONAL]',
        '[Dual base]': '[SIGRID-DUAL]',
        '[Sensing base]': '[LILJA-SENSING]',
        '[Harmonic base]': '[LILJA-HARMONIC]',
        '[Mathematical base]': '[LILJA-MATHEMATICAL]',
        '[Communicating base]': '[LILJA-COMMUNICATING]',
        '[Evolving base]': '[LILJA-EVOLVING]',
        '[Accepting base]': '[LILJA-ACCEPTING]',
        '[Variable base]': '[VARIABLE-BASE]'  # Special case
    }

    # Apply all replacements
    result = description
    for bad_ref, good_ref in reference_map.items():
        result = result.replace(bad_ref, good_ref)

    return result

def extract_proper_plate_name(plate_data):
    """Extract a proper plate name from the data"""
    name = plate_data.get('name', '')
    desc = plate_data.get('description', '')

    # Clean up names that start with **
    if name.startswith('**'):
        name = name[2:].strip()

    # If name is just "PLATE X", try to get better name from description
    if re.match(r'^PLATE \d+$', name):
        # Extract meaningful name from description if possible
        if desc and '(' in desc:
            desc_name = desc.split('(')[0].strip()
            if desc_name and desc_name != '**':
                return desc_name

    # Special handling for complex plate names
    if '-' in name and 'PLATE' in name:
        # E.g., "PLATE 1-SUMMER (Shots 1b-7b)" -> "SUMMER"
        parts = name.split('-')
        if len(parts) > 1:
            variant = parts[1].split('(')[0].strip()
            return variant

    return name

def main():
    # Load the current file
    with open('/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Extract plates from nested structure
    plates_nested = data.get('plate_index', {})

    # Create new flat structure with proper IDs
    plates_fixed = {}

    # First pass: convert all plates
    for old_id, plate_data in plates_nested.items():
        # Get character name
        char = plate_data.get('character', '').upper()
        char_map = {
            'MAGNUS': 'MAGNÚS',
            'GUDRUN': 'GUÐRÚN',
            'JON': 'JÓN',
            'LILJA': 'LILJA',
            'SIGRID': 'SIGRID'
        }
        char = char_map.get(char, char)

        # Extract plate name/type
        name = extract_proper_plate_name(plate_data)

        # Generate proper plate ID
        if plate_data.get('is_master', False):
            new_id = f"{char}-MASTER"
        elif name and not name.startswith('PLATE'):
            # Use the meaningful name
            new_id = f"{char}-{name.upper().replace(' ', '-')}"
        else:
            # Fall back to numbered plate
            num = old_id.split('_')[-1] if '_' in old_id else '1'
            new_id = f"{char}-PLATE{num}"

        # Fix description references
        desc = plate_data.get('description', '')
        if desc:
            desc = fix_bracket_references(desc)
            plate_data['description'] = desc

        # Clean up the name field
        if 'name' in plate_data:
            plate_data['name'] = extract_proper_plate_name(plate_data)

        # Add to fixed structure
        plates_fixed[new_id] = plate_data

    # Add master plates that might be missing
    master_plates = {
        "MAGNÚS-MASTER": {
            "character": "Magnus",
            "name": "Master Authority Base",
            "description": "Base template for Magnus - natural aristocratic authority through physical presence and family position.",
            "is_master": True
        },
        "GUÐRÚN-MASTER": {
            "character": "Gudrun",
            "name": "Master Abundant Base",
            "description": "Base template for Gudrun - overwhelming abundance becoming burden.",
            "is_master": True
        },
        "JÓN-MASTER": {
            "character": "Jon",
            "name": "Master Mild Base",
            "description": "Base template for Jon - gentle fevered child seeing through reality.",
            "is_master": True
        },
        "LILJA-MASTER": {
            "character": "Lilja",
            "name": "Master Pure Base",
            "description": "Base template for Lilja - innocent child with supernatural environmental awareness.",
            "is_master": True
        },
        "SIGRID-MASTER": {
            "character": "Sigrid",
            "name": "Master Pure Base",
            "description": "Base template for Sigrid - untouched innocence before violation and transformation.",
            "is_master": True
        }
    }

    # Add master plates if not present
    for master_id, master_data in master_plates.items():
        if master_id not in plates_fixed:
            plates_fixed[master_id] = master_data

    # Create specific variant plates that are referenced
    variant_plates = {
        "SIGRID-PURE": {
            "character": "Sigrid",
            "name": "Pure Innocence",
            "description": "Pure untouched innocence - grey-brown vaðmál dress clean, no pregnancy visible, naturally confident posture, grey eyes bright with curiosity, breathing easy 15/min peaceful rhythm, soprano voice pure and musical, braids perfectly arranged.",
            "is_master": False,
            "shot_range": "(Shots 1-7)"
        },
        "SIGRID-ORACLE": {
            "character": "Sigrid",
            "name": "Oracle Emergence",
            "description": "Oracle abilities emerging - dress tighter around expanding belly, grey eyes with amber flecks, breathing deepening to 14/min oracle rhythm, voice dropping toward contralto with corvid undertones.",
            "is_master": False
        },
        "SIGRID-AWAKENING": {
            "character": "Sigrid",
            "name": "Awakening Awareness",
            "description": "Growing defensive awareness - dress showing wear, first pregnancy hints, arms crossing protectively, grey eyes developing analytical sharpness, positioning shifting away from Magnus.",
            "is_master": False
        },
        "SIGRID-MARKED": {
            "character": "Sigrid",
            "name": "Marked by Violation",
            "description": "Post-violation marked state - dress disheveled, pregnancy visible, posture fully defensive, grey eyes hypervigilant, voice dropped with raven undertones, positioned exactly 11 feet from Magnus.",
            "is_master": False
        },
        "SIGRID-SUMMONING": {
            "character": "Sigrid",
            "name": "Summoning Power",
            "description": "Supernatural summoning abilities - carrying knowledge weight, grey eyes with thousand-yard stare, breathing in oracle rhythm, voice with clear corvid harmonics.",
            "is_master": False
        },
        "SIGRID-CORNERED": {
            "character": "Sigrid",
            "name": "Cornered Resistance",
            "description": "Cornered but resisting - dress stretched over 6-month pregnancy, pressed against wall, arms crossed defensively, breathing accelerated but controlled, maintaining strength despite vulnerability.",
            "is_master": False
        },
        "SIGRID-CHOSEN": {
            "character": "Sigrid",
            "name": "Chosen by Landvættir",
            "description": "Chosen and protected - dress billowing from supernatural protection, posture straightening with confidence, grey eyes bright with connection, voice gaining supernatural authority.",
            "is_master": False
        },
        "SIGRID-BECOMING": {
            "character": "Sigrid",
            "name": "Becoming Raven",
            "description": "Active transformation - dress straining over changing proportions, posture flowing between human and raven, eyes deepening to corvid intelligence, breathing transitioning rhythms.",
            "is_master": False
        },
        "SIGRID-TRANSITIONAL": {
            "character": "Sigrid",
            "name": "Transitional Form",
            "description": "Between species - dress appearing costume-like on changing body, shifting between human and raven patterns, voice with corvid harmonics, positioned at transformation threshold.",
            "is_master": False
        },
        "SIGRID-DUAL": {
            "character": "Sigrid",
            "name": "Dual Nature",
            "description": "Both human and raven simultaneously - dress flowing like feathers while remaining fabric, perfect balance between forms, corvid intelligence with human consciousness visible.",
            "is_master": False
        },
        "LILJA-SENSING": {
            "character": "Lilja",
            "name": "Environmental Sensing",
            "description": "Developing supernatural environmental awareness - eyes tracking house phenomena, increased sensitivity to changes, voice asking questions adults dismiss.",
            "is_master": False
        },
        "LILJA-HARMONIC": {
            "character": "Lilja",
            "name": "Harmonic Discovery",
            "description": "Discovering frequency abilities - producing 528Hz transformation frequency, making house beams creak responsively, vibrational wear patterns appearing.",
            "is_master": False
        },
        "LILJA-MATHEMATICAL": {
            "character": "Lilja",
            "name": "Mathematical Observer",
            "description": "Child confusion about mathematical impossibility - counting differently than adults, recognizing six shadows when five people exist.",
            "is_master": False
        },
        "LILJA-COMMUNICATING": {
            "character": "Lilja",
            "name": "House Communication",
            "description": "Communicating with house consciousness - conducting audible conversations with house, breathing synchronized with house rhythm.",
            "is_master": False
        },
        "LILJA-EVOLVING": {
            "character": "Lilja",
            "name": "Evolving Prophet",
            "description": "Prophetic abilities emerging - modifying lullabies to predict transformation, showing future sight, delivering evolved prophecies.",
            "is_master": False
        },
        "LILJA-ACCEPTING": {
            "character": "Lilja",
            "name": "Accepting Change",
            "description": "Accepting transformation with enthusiasm - practicing sheep vocalizations eagerly, showing adaptation excitement rather than fear.",
            "is_master": False
        }
    }

    # Add variant plates
    for var_id, var_data in variant_plates.items():
        if var_id not in plates_fixed:
            plates_fixed[var_id] = var_data

    # Sort plates by character and ID
    sorted_plates = dict(sorted(plates_fixed.items()))

    # Save the fixed file
    with open('/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json', 'w', encoding='utf-8') as f:
        json.dump(sorted_plates, f, ensure_ascii=False, indent=2)

    print(f"Fixed {len(sorted_plates)} plates")
    print("Structure flattened, IDs converted, and references fixed")

    # Create summary
    by_char = {}
    for plate_id in sorted_plates:
        char = plate_id.split('-')[0]
        by_char[char] = by_char.get(char, 0) + 1

    print("\nPlates by character:")
    for char, count in sorted(by_char.items()):
        print(f"  {char}: {count} plates")

if __name__ == "__main__":
    main()