#!/usr/bin/env python3
"""
Fix character system plate references to map to actual plate IDs.
This script will update the character system files to use proper plate references.
"""

import os
import re

# Define the mapping for each character
# Format: {character: {internal_reference: actual_plate_id}}
PLATE_MAPPINGS = {
    'magnus': {
        '[Master base]': '[MAGNUS-MASTER]',
        '[Summer base]': '[MAGNUS-SUMMER]',
        '[Autumn base]': '[MAGNUS-AUTUMN]',
        '[Preparation base]': '[MAGNUS-PREPARATION]',
        '[Confused base]': '[MAGNUS-CONFUSED]',
        '[Departing base]': '[MAGNUS-DEPARTING]',
        '[Afloat base]': '[MAGNUS-AFLOAT]',
        '[Aging base]': '[MAGNUS-AGING]',
        '[Wounded base]': '[MAGNUS-WOUNDED]',
        '[Injured base]': '[MAGNUS-WOUNDED]',
        '[Defeated base]': '[MAGNUS-DEFEATED]',
        '[Predator base]': '[MAGNUS-PREDATOR]',
        '[Enforcer base]': '[MAGNUS-ENFORCER]',
        '[Authority base]': '[MAGNUS-AUTHORITY]',
        '[Possessor base]': '[MAGNUS-POSSESSOR]',
        '[Shifting base]': '[MAGNUS-SHIFTING]',
        '[Recognition base]': '[MAGNUS-RECOGNIZING]',
        '[Recognizing base]': '[MAGNUS-RECOGNIZING]',
        '[Breaking base]': '[MAGNUS-BREAKING]',
        '[Preparing base]': '[MAGNUS-PREPARING]',
        '[Final base]': '[MAGNUS-FINAL]',
        '[Previous aging base]': '[MAGNUS-AGING]',
    },
    'gudrun': {
        '[Master base]': '[GUDRUN-MASTER]',
        '[Abundant base]': '[GUDRUN-ABUNDANT]',
        '[Wearing base]': '[GUDRUN-WEARING]',
        '[Preparing base]': '[GUDRUN-PREPARING]',
        '[Counting base]': '[GUDRUN-COUNTING]',
        '[Producing base]': '[GUDRUN-PRODUCING]',
        '[Beaten base]': '[GUDRUN-BEATEN]',
        '[Condemned base]': '[GUDRUN-CONDEMNED]',
        '[Walking base]': '[GUDRUN-WALKING]',
        '[Offering base]': '[GUDRUN-OFFERING]',
        '[Returning base]': '[GUDRUN-RETURNING]',
        '[Revealing base]': '[GUDRUN-REVEALING]',
        '[Transforming base]': '[GUDRUN-TRANSFORMING]',
        '[Speaking base]': '[GUDRUN-SPEAKING]',
        '[Final base]': '[GUDRUN-FINAL]',
        '[Hidden base]': '[GUDRUN-HIDING]',
        '[Protecting base]': '[GUDRUN-PROTECTING]',
        '[Sacrificed base]': '[GUDRUN-SACRIFICED]',
        '[Divine base]': '[GUDRUN-DIVINE]',
        '[Crowned base]': '[GUDRUN-CROWNED]',
        '[Recognition base]': '[GUDRUN-RECOGNIZING]',
        '[Recognizing base]': '[GUDRUN-RECOGNIZING]',
    },
    'jon': {
        '[Master base]': '[JON-MASTER]',
        '[Mild base]': '[JON-MILD]',
        '[Rising base]': '[JON-RISING]',
        '[Seeing base]': '[JON-SEEING]',
        '[Prophet base]': '[JON-PROPHET]',
        '[Changing base]': '[JON-CHANGING]',
        '[Gapped base]': '[JON-GAPPED]',
        '[Emerging base]': '[JON-EMERGING]',
        '[Grinding base]': '[JON-GRINDING]',
        '[Energetic base]': '[JON-ENERGETIC]',
        '[Losing base]': '[JON-LOSING]',
        '[Temporal base]': '[JON-TEMPORAL]',
        '[Wandering base]': '[JON-WANDERING]',
        '[Fitting base]': '[JON-FITTING]',
        '[Mission base]': '[JON-MISSION]',
        '[Mastering base]': '[JON-MASTERING]',
        '[Final base]': '[JON-FINAL]',
    },
    'sigrid': {
        '[Master base]': '[SIGRID-MASTER]',
        '[Pure base]': '[SIGRID-PURE]',
        '[Awakening base]': '[SIGRID-AWAKENING]',
        '[Calculating base]': '[SIGRID-CALCULATING]',
        '[Marked base]': '[SIGRID-MARKED]',
        '[Deeper base]': '[SIGRID-DEEPER]',
        '[Cornered base]': '[SIGRID-CORNERED]',
        '[Protected base]': '[SIGRID-PROTECTED]',
        '[Chosen base]': '[SIGRID-CHOSEN]',
        '[Escaping base]': '[SIGRID-ESCAPING]',
        '[Oracle base]': '[SIGRID-ORACLE]',
        '[Summoning base]': '[SIGRID-SUMMONING]',
        '[Birthing base]': '[SIGRID-BIRTHING]',
        '[Transitional base]': '[SIGRID-TRANSITIONAL]',
        '[Wingspan base]': '[SIGRID-WINGSPAN]',
        '[Corvid base]': '[SIGRID-CORVID]',
        '[Dual base]': '[SIGRID-DUAL]',
        '[Flight base]': '[SIGRID-FLIGHT]',
        '[Aerial base]': '[SIGRID-AERIAL]',
        '[Eternal base]': '[SIGRID-ETERNAL]',
    },
    'lilja': {
        '[Master base]': '[LILJA-MASTER]',
        '[Pure base]': '[LILJA-PURE]',
        '[Counting base]': '[LILJA-COUNTING]',
        '[Mathematical base]': '[LILJA-MATHEMATICAL]',
        '[Sensing base]': '[LILJA-SENSING]',
        '[Mapping base]': '[LILJA-MAPPING]',
        '[Communicating base]': '[LILJA-COMMUNICATING]',
        '[Prophesying base]': '[LILJA-PROPHESYING]',
        '[Wondering base]': '[LILJA-WONDERING]',
        '[Accepting base]': '[LILJA-ACCEPTING]',
        '[Producing base]': '[LILJA-PRODUCING]',
        '[Lamb base]': '[LILJA-LAMB]',
        '[Final base]': '[LILJA-FINAL]',
        '[Sheep base]': '[LILJA-SHEEP]',
    }
}

def fix_character_file(filepath, character_name):
    """Fix plate references in a single character file"""

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    mappings = PLATE_MAPPINGS.get(character_name, {})

    # Track what we're replacing
    replacements = []

    for old_ref, new_ref in mappings.items():
        if old_ref in content:
            count = content.count(old_ref)
            content = content.replace(old_ref, new_ref)
            replacements.append(f"  - {old_ref} -> {new_ref} ({count} occurrences)")

    if content != original_content:
        # Create backup
        backup_path = filepath + '.backup'
        with open(backup_path, 'w', encoding='utf-8') as f:
            f.write(original_content)
        print(f"Created backup: {backup_path}")

        # Write fixed content
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

        print(f"\nFixed {filepath}:")
        for r in replacements:
            print(r)
        return True
    else:
        print(f"\nNo changes needed for {filepath}")
        return False

def main():
    """Process all character system files"""

    char_dir = '/Users/ingthor/Documents/stories/enhancements/enhancements/charsystem/'

    # Map filenames to character names
    file_mappings = [
        ('magnus_advanced_character_plates_system.txt', 'magnus'),
        ('gudrun_advanced_character_plates_system.txt', 'gudrun'),
        ('jon_advanced_character_plates_system.txt', 'jon'),
        ('sigrid_advanced_character_plates_system.txt', 'sigrid'),
        ('lilja_advanced_character_plates_system.txt', 'lilja'),
        ('lilja_complete_character_plates_expanded.txt', 'lilja'),
    ]

    total_fixed = 0

    for filename, character in file_mappings:
        filepath = os.path.join(char_dir, filename)
        if os.path.exists(filepath):
            if fix_character_file(filepath, character):
                total_fixed += 1
        else:
            print(f"Warning: File not found: {filepath}")

    print(f"\n{'='*60}")
    print(f"Total files fixed: {total_fixed}")
    print(f"{'='*60}")

if __name__ == '__main__':
    main()