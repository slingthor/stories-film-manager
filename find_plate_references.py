#!/usr/bin/env python3
"""
Find all plate IDs referenced in shot files
"""

import json
import os
from pathlib import Path

def main():
    shots_dir = Path("/Users/ingthor/Documents/stories/appdata/json/7/shots/json")
    all_plate_ids = set()

    # Process each shot file
    for shot_file in shots_dir.glob("*.json"):
        try:
            with open(shot_file, 'r', encoding='utf-8') as f:
                data = json.load(f)

                # Check prompt_variants for selected_plates
                if 'prompt_variants' in data:
                    for variant in data['prompt_variants']:
                        if 'selected_plates' in variant:
                            plates = variant['selected_plates']
                            if isinstance(plates, list):
                                all_plate_ids.update(plates)
        except Exception as e:
            print(f"Error reading {shot_file.name}: {e}")

    # Print all unique plate IDs
    print(f"Found {len(all_plate_ids)} unique plate IDs referenced in shots:")
    print()

    # Group by character
    by_character = {}
    for plate_id in sorted(all_plate_ids):
        if '-' in plate_id:
            char = plate_id.split('-')[0]
            if char not in by_character:
                by_character[char] = []
            by_character[char].append(plate_id)

    for char in sorted(by_character.keys()):
        print(f"\n{char} plates:")
        for plate_id in sorted(by_character[char]):
            print(f"  {plate_id}")

if __name__ == "__main__":
    main()