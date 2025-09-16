#!/usr/bin/env python3
"""
Merge the best content from all plate files to create a comprehensive, coherent system.
Uses file_2 as base since it has the most plates (182) with good descriptions.
"""

import json
import re
from typing import Dict, Any

def clean_plate_id(old_id: str, plate_data: Dict[str, Any]) -> str:
    """Convert generic IDs like magnus_10 to proper IDs like MAGNUS-PREDATOR"""

    character = plate_data.get('character', '').upper().replace('Ú', 'U').replace('Ó', 'O')
    description = plate_data.get('description', '').lower()
    name = plate_data.get('name', '').upper()
    is_master = plate_data.get('is_master', False)

    # Handle master plates
    if is_master or 'master' in name.lower() or 'master base' in description.lower():
        return f"{character}-MASTER"

    # Character-specific mappings based on descriptions
    if character == "SIGRID":
        if 'pure innocence' in description and 'untouched' in description:
            return "SIGRID-PURE"
        elif 'cornered' in description or 'incest resistance' in description:
            return "SIGRID-CORNERED"
        elif 'marked' in description or 'violation' in description:
            return "SIGRID-MARKED"
        elif 'corvid' in description or 'raven' in description or 'tilberi' in description:
            return "SIGRID-CORVID"
        elif 'mathematical' in description:
            return "SIGRID-MATHEMATICAL"
        elif 'witness' in description:
            return "SIGRID-WITNESS"
        elif 'protection' in description or 'bergrisi' in description:
            return "SIGRID-PROTECTED"
        elif 'oracle' in description or 'prophecy' in description:
            return "SIGRID-ORACLE"

    elif character in ["MAGNUS", "MAGNÚS"]:
        if 'predator' in description or 'incest' in description.lower() or 'threat' in description:
            return "MAGNUS-PREDATOR"
        elif 'authority' in description and 'summer' in description:
            return "MAGNUS-AUTHORITY"
        elif 'confused' in description or 'mathematical breakdown' in description:
            return "MAGNUS-CONFUSED"
        elif 'ram' in description and 'complete' in description:
            return "MAGNUS-RAM"
        elif 'aging' in description or 'supernatural strength cost' in description:
            return "MAGNUS-AGING"

    elif character in ["GUDRUN", "GUÐRÚN"]:
        if 'abundant' in description or 'competence' in description:
            return "GUDRUN-ABUNDANT"
        elif 'condemned' in description or 'death sentence' in description:
            return "GUDRUN-CONDEMNED"
        elif 'eternal' in description or 'ewe complete' in description:
            return "GUDRUN-ETERNAL"
        elif 'wool production' in description:
            return "GUDRUN-PRODUCING"

    elif character in ["JON", "JÓN"]:
        if 'temporal' in description or 'temporal sight' in description:
            return "JON-TEMPORAL"
        elif 'mild' in description or 'early fever' in description:
            return "JON-MILD"
        elif 'lamb complete' in description:
            return "JON-LAMB"
        elif 'prophet' in description:
            return "JON-PROPHET"

    elif character == "LILJA":
        if 'pure' in description and 'innocence' in description:
            return "LILJA-PURE"
        elif 'sensing' in description or 'house communication' in description:
            return "LILJA-SENSING"
        elif 'mathematical' in description:
            return "LILJA-MATHEMATICAL"
        elif 'lamb' in description or 'final child consciousness' in description:
            return "LILJA-LAMB"

    # If old_id already looks proper, keep it
    if '-' in old_id and not old_id[0].isdigit() and '_' not in old_id:
        return old_id.upper()

    # Otherwise generate from plate number if available
    if 'PLATE' in name:
        plate_num = re.search(r'PLATE\s*(\d+)', name)
        if plate_num:
            return f"{character}-PLATE{plate_num.group(1)}"

    return old_id.upper()

def fix_bracket_references(description: str) -> str:
    """Fix bracket references to use proper plate IDs"""
    if not description:
        return description

    # Map of bad references to correct ones
    ref_map = {
        '[Master base]': '[MAGNUS-MASTER]',
        '[Pure base]': '[SIGRID-PURE]',
        '[Knowing base]': '[SIGRID-MASTER]',
        '[Oracle base]': '[SIGRID-ORACLE]',
        '[Summoning base]': '[SIGRID-MASTER]',
        '[Cornered base]': '[SIGRID-CORNERED]',
        '[Awakening base]': '[SIGRID-PURE]',
        '[Marked base]': '[SIGRID-MARKED]',
        '[Chosen base]': '[SIGRID-MASTER]',
        '[Becoming base]': '[SIGRID-CORVID]',
        '[Transitional base]': '[SIGRID-CORVID]',
        '[Dual base]': '[SIGRID-CORVID]',
        '[Abundant base]': '[GUDRUN-ABUNDANT]',
        '[Mild base]': '[JON-MILD]',
        '[Harmonic base]': '[LILJA-PURE]',
        '[Sensing base]': '[LILJA-SENSING]',
        '[Mathematical base]': '[LILJA-MATHEMATICAL]',
        '[Communicating base]': '[LILJA-SENSING]',
        '[Evolving base]': '[LILJA-PURE]',
        '[Accepting base]': '[LILJA-LAMB]',
        '[Variable base]': '[LILJA-SENSING]',
        '[Mapping base]': '[LILJA-SENSING]',
        '[Counting base]': '[LILJA-MATHEMATICAL]',
        '[Prophesying base]': '[LILJA-SENSING]',
        '[Producing base]': '[LILJA-LAMB]',
        '[Wondering base]': '[LILJA-LAMB]'
    }

    result = description
    for bad_ref, good_ref in ref_map.items():
        result = result.replace(bad_ref, good_ref)

    return result

def clean_description(description: str) -> str:
    """Clean up placeholder descriptions"""
    if description in ['**', '***', '']:
        return ""
    return fix_bracket_references(description)

def main():
    # Load all files
    files_data = {}
    file_paths = {
        'file_2': '/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete 2.json',
        'file_3': '/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete 3.json',
        'current': '/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json',
        'backup': '/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json.backup'
    }

    for name, path in file_paths.items():
        try:
            with open(path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                if 'plate_index' in data:
                    files_data[name] = data['plate_index']
                else:
                    files_data[name] = {k: v for k, v in data.items() if not k.startswith('_')}
        except Exception as e:
            print(f"Error loading {name}: {e}")
            files_data[name] = {}

    # Start with file_2 as base (has 182 plates with good descriptions)
    merged = {}

    # First pass: Add all plates from file_2 with proper IDs
    for old_id, plate_data in files_data['file_2'].items():
        new_id = clean_plate_id(old_id, plate_data)
        plate_data['description'] = clean_description(plate_data.get('description', ''))

        # Clean up name field
        if 'name' in plate_data and plate_data['name'].startswith('**'):
            plate_data['name'] = plate_data['name'].replace('**', '').strip()

        # Skip plates with empty descriptions
        if plate_data['description']:
            merged[new_id] = plate_data

    # Second pass: Add missing plates from file_3
    for old_id, plate_data in files_data['file_3'].items():
        new_id = clean_plate_id(old_id, plate_data)

        # Only add if not already present and has good description
        if new_id not in merged:
            plate_data['description'] = clean_description(plate_data.get('description', ''))
            if plate_data['description']:
                # Clean up name field
                if 'name' in plate_data and plate_data['name'].startswith('**'):
                    plate_data['name'] = plate_data['name'].replace('**', '').strip()
                merged[new_id] = plate_data

    # Third pass: Add any plates from current/backup that are missing
    for source in ['current', 'backup']:
        for old_id, plate_data in files_data[source].items():
            new_id = clean_plate_id(old_id, plate_data)

            # Only add if not already present and has good description
            if new_id not in merged:
                plate_data['description'] = clean_description(plate_data.get('description', ''))
                if plate_data['description']:
                    # Clean up name field
                    if 'name' in plate_data and plate_data['name'].startswith('**'):
                        plate_data['name'] = plate_data['name'].replace('**', '').strip()
                    merged[new_id] = plate_data

    # Add critical environmental plates that shots reference
    critical_plates = {
        "BAÐSTOFA-DOMESTIC": {
            "character": "Environment",
            "name": "Baðstofa Domestic",
            "description": "The living space in its domestic state - warm, inhabited, breathing with the family's life force",
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
            "description": "Cliff environment plate for Westfjords setting - vertical basalt columns, bird colonies, crashing waves below",
            "is_master": False
        },
        "POLYNYA-SITE": {
            "character": "Environment",
            "name": "Polynya Site",
            "description": "The ice hole where whales surface - black water surrounded by white ice, steam rising, death zone",
            "is_master": False
        },
        "RÉTTIR-PATTERN": {
            "character": "Environment",
            "name": "Réttir Pattern",
            "description": "Ancient sheep sorting pen patterns visible in floor - five radiating pens from center, stone beneath earth",
            "is_master": False
        }
    }

    for plate_id, plate_data in critical_plates.items():
        if plate_id not in merged:
            merged[plate_id] = plate_data

    # Create final structure with proper nesting
    final_data = {
        "plate_index": dict(sorted(merged.items())),
        "_total_plates": len(merged),
        "_complete_system": True,
        "last_updated": "2025-09-16T07:15:00Z"
    }

    # Save the merged file
    output_path = '/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_merged.json'
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(final_data, f, ensure_ascii=False, indent=2)

    print(f"Merged {len(merged)} plates to {output_path}")

    # Show statistics
    by_char = {}
    for plate_id in merged:
        char = plate_id.split('-')[0]
        by_char[char] = by_char.get(char, 0) + 1

    print("\nPlates by character:")
    for char, count in sorted(by_char.items()):
        print(f"  {char}: {count} plates")

    # Check shot coverage
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

    coverage = set(merged.keys()) & shot_plates
    missing = shot_plates - set(merged.keys())

    print(f"\nShot coverage: {len(coverage)}/{len(shot_plates)} plates referenced in shots")
    if missing:
        print(f"Still missing: {missing}")

if __name__ == "__main__":
    main()