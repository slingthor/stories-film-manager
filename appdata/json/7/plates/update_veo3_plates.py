#!/usr/bin/env python3
import json
import re
import os

# Load current JSON
json_path = '/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json'
with open(json_path, 'r') as f:
    plates_data = json.load(f)

# Enhancement files to process
enhancement_files = {
    'jon': '/Users/ingthor/Documents/stories/enhancements/jon_advanced_character_plates_system.txt',
    'magnus': '/Users/ingthor/Documents/stories/enhancements/magnus_advanced_character_plates_system.txt',
    'sigrid': '/Users/ingthor/Documents/stories/enhancements/sigrid_advanced_character_plates_system.txt',
    'gudrun': '/Users/ingthor/Documents/stories/enhancements/gudrun_advanced_character_plates_system.txt',
    'lilja': '/Users/ingthor/Documents/stories/enhancements/lilja_advanced_character_plates_system.txt'
}

def parse_plate_from_text(file_path, character_name):
    """Parse VEO3 plates from enhancement text files"""
    plates = {}

    if not os.path.exists(file_path):
        print(f"Warning: {file_path} not found")
        return plates

    with open(file_path, 'r') as f:
        content = f.read()

    # Pattern to match plate definitions
    # Looking for patterns like "JÓN-MILD:" or "MAGNÚS-AUTHORITY:"
    pattern = rf'{character_name.upper()}[ÚÓ]?S?-([A-Z\-]+):\s*(.+?)(?=\n\n|\*\*Acting|\Z)'

    matches = re.findall(pattern, content, re.DOTALL | re.IGNORECASE)

    for match in matches:
        plate_suffix = match[0]
        description = match[1].strip()

        # Clean up the description
        description = description.replace('\n', ' ')
        description = re.sub(r'\s+', ' ', description)

        # Extract the base reference if it exists (e.g., "[Mild base]" or "[Rising base]")
        base_match = re.match(r'\[([^\]]+)\s+base\]\s*(.*)', description)
        if base_match:
            base_ref = base_match.group(1).upper()
            rest_of_desc = base_match.group(2)

            # Convert base reference to plate ID format
            if base_ref in ['MILD', 'RISING', 'SEEING', 'TEMPORAL', 'PROPHET', 'MASTER']:
                base_plate_id = f"{character_name.upper()}-{base_ref}"
                description = f"[{base_plate_id}] {rest_of_desc}"
            elif base_ref == 'MASTER':
                base_plate_id = f"{character_name.upper()}-MASTER"
                description = f"[{base_plate_id}] {rest_of_desc}"
            else:
                # Keep original format if not recognized
                description = f"[{base_ref} base] {rest_of_desc}"

        plate_id = f"{character_name.upper()}-{plate_suffix}"
        plates[plate_id] = description

    return plates

# Update plates for each character
updated_count = 0
for character, file_path in enhancement_files.items():
    print(f"\nProcessing {character.upper()} plates from {file_path}")

    veo3_plates = parse_plate_from_text(file_path, character)

    for plate_id, description in veo3_plates.items():
        if plate_id in plates_data['plate_index']:
            old_desc = plates_data['plate_index'][plate_id].get('description', '')
            if len(description) > len(old_desc) * 2:  # Only update if new description is significantly longer
                plates_data['plate_index'][plate_id]['description'] = description
                print(f"  Updated {plate_id}: {description[:100]}...")
                updated_count += 1
            else:
                print(f"  Skipped {plate_id} (description not significantly longer)")
        else:
            print(f"  {plate_id} not found in JSON")

# Also update JON-MILD with proper description from text
jon_mild_desc = """[JON-MASTER] with 39°C fever beginning - round face flushed pink with fever warmth, button nose red from congestion, lips chapped but not severely bloodied, hazel eyes slightly glazed but still focusing on immediate surroundings, sandy hair damp with mild fever sweat, thin frame in oversized brown sweater appearing comically large, posture listless but responsive to family activity, wet cough occasional rather than constant, trembling mild and intermittent, voice hoarse but audible whisper, breathing 18/min child-fever rhythm, fever visions minimal (brief glimpses of ram running in snow)."""

if 'JON-MILD' in plates_data['plate_index']:
    plates_data['plate_index']['JON-MILD']['description'] = jon_mild_desc
    print(f"\nUpdated JON-MILD with full description")
    updated_count += 1

# Save updated JSON
with open(json_path, 'w') as f:
    json.dump(plates_data, f, indent=2)

print(f"\n✅ Updated {updated_count} plate descriptions")
print(f"Total plates in system: {len(plates_data['plate_index'])}")