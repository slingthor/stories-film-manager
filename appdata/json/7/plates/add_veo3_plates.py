#!/usr/bin/env python3
import json
import os

# Read the current character plates
with open('/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json', 'r') as f:
    current = json.load(f)

# Read the backup with correct VEO3 structure
with open('/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json.backup', 'r') as f:
    backup = json.load(f)

# Add comprehensive VEO3 plates from backup to current system
new_veo3_plates = {}

# Extract all VEO3 format plates from backup (CHARACTER-VARIANT format)
for key, value in backup['plate_index'].items():
    if '-' in key and key.isupper() and not key in current['plate_index']:
        new_veo3_plates[key] = value

# Add new VEO3 plates to current system (only those not already present)
for key, value in new_veo3_plates.items():
    current['plate_index'][key] = value

# Update total count
current['_total_plates'] = len(current['plate_index'])

# Write back to file
with open('/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json', 'w') as f:
    json.dump(current, f, indent=2)

print(f"Added {len(new_veo3_plates)} additional VEO3 plates to the system")
print(f"Total plates now: {current['_total_plates']}")
if new_veo3_plates:
    print("New VEO3 plates added:")
    for key in sorted(new_veo3_plates.keys()):
        print(f"  - {key}")