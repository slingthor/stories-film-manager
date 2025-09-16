#!/usr/bin/env python3
"""
Fix character-specific bracket references in plate descriptions.
Must check which character a plate belongs to before mapping references.
"""

import json
import re

def get_character_specific_mapping(character):
    """Get the correct mapping for a specific character"""

    if character == 'Magnus':
        return {
            '[Master base]': '[MAGNUS-MASTER]',
            '[Defeated base]': '[MAGNUS-DEFEATED]',
            '[Predator base]': '[MAGNUS-PREDATOR]',
            '[Possessor base]': '[MAGNUS-POSSESSOR]',
            '[Shifting base]': '[MAGNUS-SHIFTING]',
            '[Breaking base]': '[MAGNUS-BREAKING]',
            '[Preparing base]': '[MAGNUS-PREPARING]',
            '[Previous aging base]': '[MAGNUS-AGING]',
            '[Injured base]': '[MAGNUS-WOUNDED]',
            '[Authority base]': '[MAGNUS-ENFORCER]',
            '[Recognition base]': '[MAGNUS-RECOGNIZING]'
        }

    elif character == 'Sigrid':
        return {
            '[Master base]': '[SIGRID-MASTER]',
            '[Pure base]': '[SIGRID-PURE]',
            '[Sigrid base]': '[SIGRID-MASTER]',
            '[Awakening base]': '[SIGRID-PURE]',  # Sigrid's awakening
            '[Marked base]': '[SIGRID-MARKED]',
            '[Cornered base]': '[SIGRID-CORNERED]',
            '[Oracle base]': '[SIGRID-MASTER]',
            '[Chosen base]': '[SIGRID-MASTER]',
            '[Becoming base]': '[SIGRID-CORVID]',
            '[Transitional base]': '[SIGRID-CORVID]',
            '[Dual base]': '[SIGRID-CORVID]'
        }

    elif character == 'Gudrun':
        return {
            '[Master base]': '[GUDRUN-MASTER]',
            '[Gudrun base]': '[GUDRUN-MASTER]',
            '[Abundant base]': '[GUDRUN-ABUNDANT]',
            '[Preparing base]': '[GUDRUN-PREPARING]',  # Gudrun's preparing
            '[Counting base]': '[GUDRUN-COUNTING]',  # Gudrun's counting
            '[Producing base]': '[GUDRUN-PRODUCING]',
            '[Recognizing base]': '[GUDRUN-RECOGNIZING]',  # Gudrun's recognizing
            '[Returning base]': '[GUDRUN-RETURNING]',
            '[Variable base]': '[GUDRUN-MASTER]'
        }

    elif character == 'Jon':
        return {
            '[Master base]': '[JON-MASTER]',
            '[Jon base]': '[JON-MASTER]',
            '[Mild base]': '[JON-MILD]',
            '[Wandering base]': '[JON-PROPHET]',
            '[Temporal base]': '[JON-TEMPORAL]',
            '[Changing base]': '[JON-CHANGING]',
            '[Seeing base]': '[JON-TEMPORAL]',
            '[Awakening base]': '[JON-MILD]',  # Jon's awakening
            '[Emerging base]': '[JON-EMERGING]',
            '[Gapped base]': '[JON-GAPPED]',
            '[Energetic base]': '[JON-PROPHET]',
            '[Mastering base]': '[JON-MASTERING]'
        }

    elif character == 'Lilja':
        return {
            '[Master base]': '[LILJA-MASTER]',
            '[Lilja base]': '[LILJA-MASTER]',
            '[Harmonic base]': '[LILJA-PURE]',
            '[Sensing base]': '[LILJA-SENSING]',  # Lilja's sensing
            '[Mathematical base]': '[LILJA-MATHEMATICAL]',
            '[Communicating base]': '[LILJA-SENSING]',
            '[Evolving base]': '[LILJA-PURE]',
            '[Accepting base]': '[LILJA-LAMB]',
            '[Counting base]': '[LILJA-MATHEMATICAL]',  # Lilja's counting
            '[Mapping base]': '[LILJA-SENSING]',
            '[Prophesying base]': '[LILJA-SENSING]',
            '[Producing base]': '[LILJA-LAMB]',  # Lilja's producing
            '[Wondering base]': '[LILJA-LAMB]'
        }

    else:  # Environment plates
        return {}

def main():
    filepath = '/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json'

    with open(filepath, 'r') as f:
        data = json.load(f)

    plates = data['plate_index']
    all_ids = set(plates.keys())

    # Process each plate with character-specific mappings
    fixes_made = 0
    for plate_id, plate_data in plates.items():
        character = plate_data.get('character', '')

        if 'description' in plate_data:
            desc = plate_data['description']
            original_desc = desc

            # Get character-specific mappings
            mappings = get_character_specific_mapping(character)

            # Apply mappings
            for bad_ref, good_ref in mappings.items():
                if bad_ref in desc:
                    desc = desc.replace(bad_ref, good_ref)
                    print(f"Fixed {character} plate {plate_id}: {bad_ref} -> {good_ref}")
                    fixes_made += 1

            plate_data['description'] = desc

    # Save the file
    with open(filepath, 'w') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"\nMade {fixes_made} character-specific reference fixes")

    # Final validation
    invalid_refs = []
    for plate_id, plate_data in plates.items():
        desc = plate_data.get('description', '')
        refs = re.findall(r'\[([A-Z\-]+)\]', desc)
        for ref in refs:
            if ref not in all_ids:
                invalid_refs.append((plate_id, ref))

    if invalid_refs:
        print(f"\nWarning: Still have {len(set(invalid_refs))} invalid references:")
        for plate_id, ref in list(set(invalid_refs))[:10]:
            char = plates[plate_id].get('character', '?')
            print(f"  {plate_id} ({char}) references [{ref}]")
    else:
        print("All bracket references are now valid!")

if __name__ == "__main__":
    main()