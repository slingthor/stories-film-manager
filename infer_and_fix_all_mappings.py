#!/usr/bin/env python3
"""
Infer plate mappings from enhancement files and fix all references.
"""

import json
import re
import os
import glob

def extract_plate_mappings_from_file(filepath):
    """Extract plate definitions and their base references from enhancement file"""
    mappings = {}

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find all plate definitions with their references
    # Pattern: PLATE-NAME: [base reference] description...
    pattern = r'([A-Z\-]+):\s*\[([^\]]+)\][^\n]+'
    matches = re.findall(pattern, content)

    for plate_id, base_ref in matches:
        # Clean up plate ID (remove MAGNÚS -> MAGNUS, etc)
        plate_id = plate_id.replace('MAGNÚS', 'MAGNUS')
        plate_id = plate_id.replace('GUÐRÚN', 'GUDRUN')
        plate_id = plate_id.replace('JÓN', 'JON')

        # Store the mapping
        mappings[plate_id] = base_ref

    return mappings

def infer_all_mappings():
    """Infer all plate base mappings from enhancement files"""

    enhancement_dir = '/Users/ingthor/Documents/stories/enhancements/enhancements/charsystem'
    all_mappings = {}

    for filepath in glob.glob(os.path.join(enhancement_dir, '*.txt')):
        file_mappings = extract_plate_mappings_from_file(filepath)
        all_mappings.update(file_mappings)

    return all_mappings

def create_reference_map(inferred_mappings, existing_plates):
    """Create a complete mapping of base references to actual plate IDs"""

    reference_map = {}

    # Process each inferred mapping
    for plate_id, base_ref in inferred_mappings.items():
        if base_ref not in reference_map:
            # Try to find the actual plate that base_ref refers to
            base_ref_clean = base_ref.strip()

            # Common patterns
            if base_ref_clean == 'Master base':
                # Determine which master based on the plate prefix
                if plate_id.startswith('MAGNUS'):
                    reference_map[f'[{base_ref}]'] = '[MAGNUS-MASTER]'
                elif plate_id.startswith('SIGRID'):
                    reference_map[f'[{base_ref}]'] = '[SIGRID-MASTER]'
                elif plate_id.startswith('GUDRUN'):
                    reference_map[f'[{base_ref}]'] = '[GUDRUN-MASTER]'
                elif plate_id.startswith('JON'):
                    reference_map[f'[{base_ref}]'] = '[JON-MASTER]'
                elif plate_id.startswith('LILJA'):
                    reference_map[f'[{base_ref}]'] = '[LILJA-MASTER]'

            elif 'base' in base_ref_clean:
                # Try to find a matching plate
                base_name = base_ref_clean.replace(' base', '').upper()

                # Check for direct matches
                for existing_id in existing_plates:
                    if base_name in existing_id:
                        reference_map[f'[{base_ref}]'] = f'[{existing_id}]'
                        break

    return reference_map

def main():
    filepath = '/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json'

    # Load current plates
    with open(filepath, 'r') as f:
        data = json.load(f)

    plates = data['plate_index']
    all_plate_ids = set(plates.keys())

    print("=== INFERRING MAPPINGS FROM ENHANCEMENT FILES ===")
    inferred = infer_all_mappings()

    # Show what we found
    print(f"Found {len(inferred)} plate definitions in enhancement files")

    # Build comprehensive reference map
    print("\n=== BUILDING REFERENCE MAP ===")

    # First, identify all unique base references used in descriptions
    all_base_refs = set()
    for plate_id, plate_data in plates.items():
        desc = plate_data.get('description', '')
        # Find all [...base] patterns
        refs = re.findall(r'\[([^]]+base)\]', desc)
        all_base_refs.update(refs)

    print(f"Found {len(all_base_refs)} unique base references in descriptions")

    # Now map each base reference to the correct plate
    # This is complex because we need context
    print("\n=== FIXING ALL REFERENCES ===")

    fixes_made = 0
    unfixable = []

    for plate_id, plate_data in plates.items():
        if 'description' not in plate_data:
            continue

        desc = plate_data['description']
        character = plate_data.get('character', '')

        # Find all bracket references in this description
        refs = re.findall(r'\[([^]]+)\]', desc)

        for ref in refs:
            if ref not in all_plate_ids:
                # This reference needs fixing
                # Try to infer the correct plate

                fixed = False

                # Check if it's in our inferred mappings
                if plate_id in inferred:
                    base_ref = inferred[plate_id]
                    # Try to resolve this base reference
                    if 'Master base' in base_ref or base_ref == 'Master base':
                        # Use character-specific master
                        if character == 'Magnus':
                            new_ref = 'MAGNUS-MASTER'
                        elif character == 'Sigrid':
                            new_ref = 'SIGRID-MASTER'
                        elif character == 'Gudrun':
                            new_ref = 'GUDRUN-MASTER'
                        elif character == 'Jon':
                            new_ref = 'JON-MASTER'
                        elif character == 'Lilja':
                            new_ref = 'LILJA-MASTER'
                        else:
                            continue

                        if new_ref in all_plate_ids:
                            desc = desc.replace(f'[{ref}]', f'[{new_ref}]')
                            print(f"Fixed {plate_id}: [{ref}] -> [{new_ref}]")
                            fixes_made += 1
                            fixed = True

                if not fixed:
                    # Try to find a plate that matches the reference
                    ref_upper = ref.upper().replace(' ', '-')

                    # Look for character-specific match
                    if character:
                        char_prefix = character.upper()
                        potential_id = f"{char_prefix}-{ref_upper.replace('-BASE', '')}"

                        if potential_id in all_plate_ids:
                            desc = desc.replace(f'[{ref}]', f'[{potential_id}]')
                            print(f"Fixed {plate_id}: [{ref}] -> [{potential_id}]")
                            fixes_made += 1
                            fixed = True

                    if not fixed:
                        unfixable.append((plate_id, ref, character))

        plate_data['description'] = desc

    # Handle remaining unfixable references
    if unfixable:
        print(f"\n=== ATTEMPTING TO FIX {len(unfixable)} REMAINING REFERENCES ===")

        for plate_id, ref, character in unfixable:
            # For JON-MASTERING, let's check if we need to create it
            if ref == 'JON-MASTERING':
                # This plate doesn't exist, change reference to JON-MASTER
                desc = plates[plate_id]['description']
                desc = desc.replace('[JON-MASTERING]', '[JON-MASTER]')
                plates[plate_id]['description'] = desc
                print(f"Fixed {plate_id}: [JON-MASTERING] -> [JON-MASTER]")
                fixes_made += 1

    # Save the updated file
    with open(filepath, 'w') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"\n=== SUMMARY ===")
    print(f"Made {fixes_made} fixes")

    # Final validation
    invalid_refs = []
    for plate_id, plate_data in plates.items():
        desc = plate_data.get('description', '')
        refs = re.findall(r'\[([^]]+)\]', desc)
        for ref in refs:
            if ref not in all_plate_ids:
                invalid_refs.append((plate_id, ref))

    if invalid_refs:
        print(f"\nWarning: Still have {len(set(invalid_refs))} invalid references:")
        for plate_id, ref in list(set(invalid_refs))[:10]:
            print(f"  {plate_id} -> [{ref}]")
    else:
        print("\n✓ All bracket references are now valid!")

if __name__ == "__main__":
    main()