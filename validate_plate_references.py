#!/usr/bin/env python3
"""
Validate all bracket references in plate descriptions against existing plate IDs.
Identify and attempt to fix invalid references.
"""

import json
import re
from collections import defaultdict

def extract_all_references(plates):
    """Extract all bracket references from plate descriptions"""
    all_refs = defaultdict(list)

    for plate_id, plate_data in plates.items():
        desc = plate_data.get('description', '')
        # Find all [...] references
        refs = re.findall(r'\[([^\]]+)\]', desc)
        for ref in refs:
            all_refs[ref].append(plate_id)

    return all_refs

def validate_references(plates):
    """Validate all references against existing plate IDs"""
    all_plate_ids = set(plates.keys())
    all_refs = extract_all_references(plates)

    valid_refs = {}
    invalid_refs = {}

    for ref, using_plates in all_refs.items():
        if ref in all_plate_ids:
            valid_refs[ref] = using_plates
        else:
            invalid_refs[ref] = using_plates

    return valid_refs, invalid_refs

def analyze_invalid_references(invalid_refs, plates):
    """Analyze invalid references to suggest fixes"""
    suggestions = {}
    all_plate_ids = set(plates.keys())

    for bad_ref, using_plates in invalid_refs.items():
        # Try to find similar plate IDs
        possible_matches = []

        # Check for case variations
        for plate_id in all_plate_ids:
            if plate_id.upper() == bad_ref.upper():
                possible_matches.append(plate_id)
                continue

            # Check for partial matches
            if bad_ref.upper() in plate_id or plate_id in bad_ref.upper():
                possible_matches.append(plate_id)

        # Analyze the context - what character uses this reference?
        characters_using = set()
        for plate_id in using_plates:
            char = plates[plate_id].get('character', 'Unknown')
            characters_using.add(char)

        # Try to infer the correct reference based on character
        if len(characters_using) == 1:
            char = list(characters_using)[0]
            # Try character-specific master
            if 'MASTER' in bad_ref.upper() or 'BASE' in bad_ref.upper():
                master_id = f"{char.upper()}-MASTER"
                if master_id in all_plate_ids:
                    possible_matches.insert(0, master_id)

        suggestions[bad_ref] = {
            'used_by': using_plates,
            'characters': list(characters_using),
            'possible_matches': possible_matches[:3]  # Top 3 suggestions
        }

    return suggestions

def main():
    filepath = '/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json'

    print("=" * 60)
    print("PLATE REFERENCE VALIDATION REPORT")
    print("=" * 60)

    with open(filepath, 'r') as f:
        data = json.load(f)

    plates = data['plate_index']
    all_plate_ids = set(plates.keys())

    print(f"\n📊 Total plates in index: {len(plates)}")

    # Get all master plates
    master_plates = {pid for pid in all_plate_ids if 'MASTER' in pid or pid.endswith('-ABUNDANT') or pid.endswith('-MILD')}
    print(f"📌 Master/base plates found: {len(master_plates)}")

    # List master plates by character
    print("\n🎭 Master plates by character:")
    master_by_char = defaultdict(list)
    for pid in sorted(master_plates):
        char = plates[pid].get('character', 'Unknown')
        master_by_char[char].append(pid)

    for char, masters in sorted(master_by_char.items()):
        print(f"  {char}: {', '.join(masters)}")

    # Validate references
    valid_refs, invalid_refs = validate_references(plates)

    print(f"\n✅ Valid references: {len(valid_refs)}")
    print(f"❌ Invalid references: {len(invalid_refs)}")

    if invalid_refs:
        print("\n" + "=" * 60)
        print("INVALID REFERENCES FOUND")
        print("=" * 60)

        suggestions = analyze_invalid_references(invalid_refs, plates)

        for bad_ref, info in suggestions.items():
            print(f"\n❌ [{bad_ref}]")
            print(f"   Used by {len(info['used_by'])} plates: {', '.join(info['used_by'][:3])}")
            print(f"   Characters: {', '.join(info['characters'])}")
            if info['possible_matches']:
                print(f"   Possible fixes: {', '.join(info['possible_matches'])}")
            else:
                print(f"   No automatic fix found - may need manual review")

        # Generate fix script
        print("\n" + "=" * 60)
        print("SUGGESTED FIXES")
        print("=" * 60)

        print("\nPython code to fix these references:")
        print("```python")
        print("fixes = {")

        for bad_ref, info in suggestions.items():
            if info['possible_matches']:
                suggested = info['possible_matches'][0]
                print(f"    '[{bad_ref}]': '[{suggested}]',")
            else:
                print(f"    # '[{bad_ref}]': '???',  # Needs manual review")

        print("}")
        print("```")
    else:
        print("\n✅ SUCCESS! All bracket references are valid!")

    # Statistics
    print("\n" + "=" * 60)
    print("REFERENCE STATISTICS")
    print("=" * 60)

    # Most referenced plates
    ref_count = defaultdict(int)
    for ref, using_plates in valid_refs.items():
        ref_count[ref] = len(using_plates)

    print("\n📈 Most referenced plates (top 10):")
    for ref, count in sorted(ref_count.items(), key=lambda x: x[1], reverse=True)[:10]:
        char = plates[ref].get('character', 'Unknown')
        print(f"  [{ref}] ({char}): referenced {count} times")

    # Plates with most references
    plate_ref_count = {}
    for plate_id, plate_data in plates.items():
        desc = plate_data.get('description', '')
        refs = re.findall(r'\[([^\]]+)\]', desc)
        if refs:
            plate_ref_count[plate_id] = len(refs)

    print("\n📊 Plates with most outgoing references (top 10):")
    for plate_id, count in sorted(plate_ref_count.items(), key=lambda x: x[1], reverse=True)[:10]:
        char = plates[plate_id].get('character', 'Unknown')
        print(f"  {plate_id} ({char}): has {count} references")

    print("\n" + "=" * 60)
    print("VALIDATION COMPLETE")
    print("=" * 60)

if __name__ == "__main__":
    main()