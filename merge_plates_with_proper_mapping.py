#!/usr/bin/env python3
"""
Merge the old backup plate file with enhancements, ensuring proper master plate mappings
are applied during the merge process.
"""

import json
import re

def get_master_plate_id(character):
    """Get the correct master plate ID for a character"""
    master_mappings = {
        'MAGNUS': 'MAGNUS-MASTER',
        'MAGNÚS': 'MAGNUS-MASTER',
        'SIGRID': 'SIGRID-MASTER',
        'GUDRUN': 'GUDRUN-MASTER',
        'GUÐRÚN': 'GUDRUN-MASTER',
        'JON': 'JON-MASTER',
        'JÓN': 'JON-MASTER',
        'LILJA': 'LILJA-MASTER'
    }
    return master_mappings.get(character.upper(), f'{character.upper()}-MASTER')

def fix_bracket_references(description):
    """Fix bracket references to use proper plate IDs"""
    if not description:
        return description

    # Map base references to proper master plates
    master_ref_map = {
        '[Master base]': '[MAGNUS-MASTER]',
        '[MAGNUS-MASTER base]': '[MAGNUS-MASTER]',
        '[MAGNÚS-MASTER]': '[MAGNUS-MASTER]',
        '[Pure base]': '[SIGRID-PURE]',
        '[Sigrid base]': '[SIGRID-MASTER]',
        '[SIGRID-MASTER base]': '[SIGRID-MASTER]',
        '[Abundant base]': '[GUDRUN-ABUNDANT]',
        '[Gudrun base]': '[GUDRUN-MASTER]',
        '[GUDRUN-MASTER base]': '[GUDRUN-MASTER]',
        '[Mild base]': '[JON-MILD]',
        '[Jon base]': '[JON-MASTER]',
        '[JON-MASTER base]': '[JON-MASTER]',
        '[Lilja base]': '[LILJA-MASTER]',
        '[LILJA-MASTER base]': '[LILJA-MASTER]'
    }

    # Character-specific state references
    state_ref_map = {
        # Sigrid states
        '[Awakening base]': '[SIGRID-PURE]',
        '[Marked base]': '[SIGRID-MARKED]',
        '[Cornered base]': '[SIGRID-CORNERED]',
        '[Oracle base]': '[SIGRID-MASTER]',
        '[Chosen base]': '[SIGRID-MASTER]',
        '[Becoming base]': '[SIGRID-CORVID]',
        '[Transitional base]': '[SIGRID-CORVID]',
        '[Dual base]': '[SIGRID-CORVID]',
        # Gudrun states
        '[Preparing base]': '[GUDRUN-PREPARING]',
        '[Counting base]': '[GUDRUN-COUNTING]',
        '[Producing base]': '[GUDRUN-PRODUCING]',
        '[Recognizing base]': '[GUDRUN-RECOGNIZING]',
        '[Returning base]': '[GUDRUN-RETURNING]',
        '[Variable base]': '[GUDRUN-MASTER]',
        # Jon states
        '[Wandering base]': '[JON-PROPHET]',
        '[Temporal base]': '[JON-TEMPORAL]',
        '[Changing base]': '[JON-CHANGING]',
        '[Seeing base]': '[JON-TEMPORAL]',
        '[Awakening base]': '[JON-MILD]',
        '[Emerging base]': '[JON-EMERGING]',
        '[Gapped base]': '[JON-GAPPED]',
        '[Energetic base]': '[JON-PROPHET]',
        '[Mastering base]': '[JON-MASTERING]',
        # Lilja states
        '[Harmonic base]': '[LILJA-PURE]',
        '[Sensing base]': '[LILJA-SENSING]',
        '[Mathematical base]': '[LILJA-MATHEMATICAL]',
        '[Communicating base]': '[LILJA-SENSING]',
        '[Evolving base]': '[LILJA-PURE]',
        '[Accepting base]': '[LILJA-LAMB]',
        '[Counting base]': '[LILJA-MATHEMATICAL]',
        '[Mapping base]': '[LILJA-SENSING]',
        '[Prophesying base]': '[LILJA-SENSING]',
        '[Producing base]': '[LILJA-LAMB]',
        '[Wondering base]': '[LILJA-LAMB]',
        # Magnus states
        '[Defeated base]': '[MAGNUS-DEFEATED]',
        '[Possessor base]': '[MAGNUS-PREDATOR]',
        '[Shifting base]': '[MAGNUS-SHIFTING]',
        '[Recognizing base]': '[MAGNUS-RECOGNIZING]'
    }

    result = description
    # Apply all mappings
    for bad_ref, good_ref in {**master_ref_map, **state_ref_map}.items():
        result = result.replace(bad_ref, good_ref)

    return result

def normalize_plate_id(plate_id):
    """Normalize plate IDs to match shot references"""
    # Handle S- prefix plates (from old backup)
    if plate_id.startswith('S-'):
        return 'MAGNUS-' + plate_id[2:]
    elif plate_id.startswith('N-'):
        # Map N- prefixes to appropriate characters
        if 'RECOGNIZING' in plate_id or 'WATCHING' in plate_id or 'PROTECTING' in plate_id:
            return 'GUDRUN-' + plate_id[2:]
        elif 'MISSION' in plate_id or 'PROPHET' in plate_id or 'COUNTING' in plate_id:
            return 'JON-' + plate_id[2:]
        else:
            return plate_id[2:]  # Remove N- prefix

    # Already normalized
    return plate_id

def main():
    # Load the old backup file (has correct structure)
    backup_path = '/Users/ingthor/Documents/stories/appdata copy 5/json/7/character_plates_index.json'
    with open(backup_path, 'r', encoding='utf-8') as f:
        backup_data = json.load(f)

    # Load current file for any additional plates
    current_path = '/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json'
    try:
        with open(current_path, 'r', encoding='utf-8') as f:
            current_data = json.load(f)
    except:
        current_data = {'plate_index': {}}

    # Start with backup plates, normalizing IDs and fixing references
    merged_plates = {}

    # Process backup plates
    backup_plates = backup_data.get('plate_index', backup_data)
    for old_id, plate_data in backup_plates.items():
        # Normalize the plate ID
        new_id = normalize_plate_id(old_id)

        # Fix bracket references in description BEFORE adding
        if 'description' in plate_data:
            plate_data['description'] = fix_bracket_references(plate_data['description'])

        # Ensure character field is set correctly
        if 'character' not in plate_data or not plate_data['character']:
            # Infer from ID
            parts = new_id.split('-')
            if parts[0] in ['MAGNUS', 'SIGRID', 'GUDRUN', 'JON', 'LILJA']:
                plate_data['character'] = parts[0].title()

        merged_plates[new_id] = plate_data

    # Add any missing plates from current file
    current_plates = current_data.get('plate_index', {})
    for plate_id, plate_data in current_plates.items():
        if plate_id not in merged_plates:
            # Fix references before adding
            if 'description' in plate_data:
                plate_data['description'] = fix_bracket_references(plate_data['description'])
            merged_plates[plate_id] = plate_data

    # Add critical missing plates that shots reference
    critical_additions = {
        "MAGNUS-MASTER": {
            "character": "Magnus",
            "name": "Magnus Master",
            "description": "Magnús Þorláksson, 55-year-old Westfjords fisherman with weathered rectangular face, broken aquiline nose bent leftward, steel-blue hooded eyes, charcoal-grey beard reaching mid-chest, 5'10\" stocky build, brown vaðmál wool sweater with elbow patches, dark wool trousers, sealskin boots, thick leather belt, carved driftwood cane in right hand, erect confident posture, jaw set with paternal authority, steady 10/min breathing, hands stable except 3Hz counting tremor",
            "is_master": True
        },
        "JON-MASTER": {
            "character": "Jon",
            "name": "Jon Master",
            "description": "Jón Magnússon, 8-year-old Westfjords boy with round cherubic face, small upturned nose slightly reddened from cold, hazel eyes with distinct green-brown flecks, sandy brown hair falling over forehead, thin shoulders in oversized brown wool sweater, dark wool trousers mended at knees, grey wool stockings, too-large leather shoes, pale complexion with pink cheek flush, delicate hands with dirt under nails",
            "is_master": True
        },
        "GUDRUN-MASTER": {
            "character": "Gudrun",
            "name": "Gudrun Master",
            "description": "Guðrún Magnúsdóttir, 35-year-old with oval face, high defined cheekbones, straight nose, thin determined lips, grey-green almond eyes, white faldbúningur headdress with black velvet band and brass pin, grey vaðmál dress, brown wool apron, black wool shawl, 5'2\" malnourished frame showing ribs, V-notch scar in right ear from childhood, brass wedding ring loose on thinned finger",
            "is_master": True
        },
        "LILJA-MASTER": {
            "character": "Lilja",
            "name": "Lilja Master",
            "description": "Lilja Magnúsdóttir, 5-year-old with cherubic round face, tiny upturned button nose, rosebud pink mouth, oversized cornflower-blue eyes, tangled dark blonde hair with uneven bangs, 3'6\" delicate frame, grey wool dress with torn hem, brown wool stockings with holes, simple leather shoes, clutching 8-inch cloth doll with brass button eyes and yellow yarn hair, timid posture, thumb-sucking comfort behavior",
            "is_master": True
        },
        "SIGRID-PURE": {
            "character": "Sigrid",
            "name": "Sigrid Pure",
            "description": "[SIGRID-MASTER] with untouched innocence - grey-brown dress clean and recently washed, no visible pregnancy, posture naturally confident with gentle back-straightness, arms loose at sides, grey eyes bright with curiosity, breathing easy 15/min peaceful rhythm, soprano voice pure and musical, facial expression open with trusting family connection, braids perfectly arranged, positioned comfortably 8 feet from Magnus, wooden cross resting naturally in pocket",
            "is_master": False
        },
        "S-RAM": {
            "character": "Magnus",
            "name": "Magnus Ram Transformation",
            "description": "Pure Icelandic ram with magnificent curved horns, dense white wool, powerful quadruped build, steel-blue ram eyes showing human consciousness clearly visible, brown vaðmál sweater worn inside-out revealing human history, breathing 8/min sheep rhythm, positioned in flock formation with family, human intelligence operating through ram anatomy",
            "is_master": False
        }
    }

    # Add critical plates if missing
    for plate_id, plate_data in critical_additions.items():
        if plate_id not in merged_plates:
            plate_data['description'] = fix_bracket_references(plate_data.get('description', ''))
            merged_plates[plate_id] = plate_data

    # Environmental plates
    env_plates = {
        "BAÐSTOFA-DOMESTIC": {
            "character": "Environment",
            "name": "Baðstofa Domestic",
            "description": "The living space in its domestic state - warm, inhabited, breathing with family life force",
            "is_master": False
        },
        "BAÐSTOFA-MONUMENT": {
            "character": "Environment",
            "name": "Baðstofa Monument",
            "description": "The living space transforming into eternal monument - walls becoming stone, breathing slowing to geological time",
            "is_master": False
        },
        "HOUSE-MONUMENT": {
            "character": "Environment",
            "name": "House Monument",
            "description": "The house as final monolithic form - black obsidian walls, no longer breathing, eternal witness",
            "is_master": False
        },
        "WESTFJORDS-CLIFF": {
            "character": "Environment",
            "name": "Westfjords Cliff",
            "description": "Cliff environment - vertical basalt columns, bird colonies, crashing waves below",
            "is_master": False
        },
        "WESTFJORDS-FJORD": {
            "character": "Environment",
            "name": "Westfjords Fjord",
            "description": "Fjord waters - deep black water, steep mountain walls, morning mist",
            "is_master": False
        },
        "WESTFJORDS-SUMMER": {
            "character": "Environment",
            "name": "Westfjords Summer",
            "description": "Summer landscape - brief green grass, wildflowers, 24-hour daylight",
            "is_master": False
        },
        "WESTFJORDS-WINTER": {
            "character": "Environment",
            "name": "Westfjords Winter",
            "description": "Winter landscape - complete white coverage, frozen sea edge, polar darkness",
            "is_master": False
        },
        "SEA-ABUNDANT": {
            "character": "Environment",
            "name": "Sea Abundant",
            "description": "Rich fishing waters - whale pods visible, seabirds circling, calm surface",
            "is_master": False
        },
        "SEA-BATTLE": {
            "character": "Environment",
            "name": "Sea Battle",
            "description": "Violent waters during hunt - blood spreading, thrashing motion, desperate struggle",
            "is_master": False
        },
        "SEA-EXTRACTED": {
            "character": "Environment",
            "name": "Sea Extracted",
            "description": "Empty waters after overfishing - no life visible, oil slick surface, industrial contamination",
            "is_master": False
        },
        "STOFA-PEACEFUL": {
            "character": "Environment",
            "name": "Stofa Peaceful",
            "description": "Main room in calm state - lamplight steady, beams quiet, normal shadows",
            "is_master": False
        },
        "STOFA-STIRRING": {
            "character": "Environment",
            "name": "Stofa Stirring",
            "description": "Main room awakening - beams creaking, shadows moving independently, warm spots appearing",
            "is_master": False
        },
        "STOFA-FRAGMENTING": {
            "character": "Environment",
            "name": "Stofa Fragmenting",
            "description": "Main room breaking reality - multiple time periods visible simultaneously, past and future overlapping",
            "is_master": False
        },
        "STOFA-BODY": {
            "character": "Environment",
            "name": "Stofa Body",
            "description": "Main room as giant's anatomy - floor showing organ patterns, walls breathing, house consciousness manifest",
            "is_master": False
        }
    }

    for plate_id, plate_data in env_plates.items():
        if plate_id not in merged_plates:
            merged_plates[plate_id] = plate_data

    # Create final structure
    final_data = {
        "plate_index": dict(sorted(merged_plates.items())),
        "_total_plates": len(merged_plates),
        "_complete_system": True,
        "last_updated": "2025-09-16T07:00:00Z"
    }

    # Save the merged file
    output_path = '/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete_merged.json'
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(final_data, f, ensure_ascii=False, indent=2)

    print(f"Merged {len(merged_plates)} plates to {output_path}")

    # Check coverage
    import glob
    shot_plates = set()
    for shot_file in glob.glob('/Users/ingthor/Documents/stories/appdata/json/7/shots/json/*.json'):
        try:
            with open(shot_file, 'r') as f:
                shot_data = json.load(f)
                for variant in shot_data.get('prompt_variants', []):
                    for plate_id in variant.get('selected_plates', []):
                        shot_plates.add(plate_id)
        except:
            pass

    coverage = set(merged_plates.keys()) & shot_plates
    missing = shot_plates - set(merged_plates.keys())

    print(f"\nShot coverage: {len(coverage)}/{len(shot_plates)} plates referenced in shots")
    if missing:
        print(f"Still missing: {missing}")

    # Show plate counts by character
    by_char = {}
    for plate_id in merged_plates:
        char = merged_plates[plate_id].get('character', 'Unknown')
        by_char[char] = by_char.get(char, 0) + 1

    print("\nPlates by character:")
    for char, count in sorted(by_char.items()):
        print(f"  {char}: {count} plates")

if __name__ == "__main__":
    main()