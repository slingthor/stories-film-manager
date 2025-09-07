#!/usr/bin/env python3

import json
import os
from pathlib import Path

# Default negative prompt for this dark Icelandic film
DEFAULT_NEGATIVE_PROMPT = """modern technology, smartphones, cars, electric lights, neon, urban cityscape, 
anime style, cartoon style, 3D render, CGI look, oversaturated colors, 
Hollywood glamour, makeup, contemporary clothing post-1900, 
smiling, happiness, warmth, comfort, safety, comic elements, 
digital artifacts, lens flare, chromatic aberration unless specified,
tropical elements, palm trees, desert, non-Nordic elements,
Asian architecture, Mediterranean elements, American suburbia,
plastic, synthetic materials, industrial materials unless specified"""

def update_json_file(filepath):
    """Update the negative prompt in a single JSON file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        filename = os.path.basename(filepath)
        shot_id = filename.replace('.json', '')
        
        # Update each prompt variant
        if 'prompt_variants' in data:
            updated = False
            for variant in data['prompt_variants']:
                # Only update if negative_prompt is empty or not present
                current_negative = variant.get('negative_prompt', '').strip()
                
                if not current_negative:
                    variant['negative_prompt'] = DEFAULT_NEGATIVE_PROMPT
                    updated = True
                    print(f"Added default negative prompt to {shot_id} - {variant.get('variant_name', 'unnamed variant')}")
                elif current_negative == "none" or current_negative == "None":
                    # Replace placeholder text
                    variant['negative_prompt'] = DEFAULT_NEGATIVE_PROMPT
                    updated = True
                    print(f"Replaced placeholder in {shot_id} - {variant.get('variant_name', 'unnamed variant')}")
            
            if updated:
                # Write back to file
                with open(filepath, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2, ensure_ascii=False)
                return True
            else:
                print(f"Skipped {shot_id} - already has negative prompts")
                return False
        else:
            print(f"Warning: No prompt_variants in {filename}")
            return False
            
    except Exception as e:
        print(f"Error processing {filepath}: {e}")
        return False

def main():
    # Path to the shots directory
    shots_dir = Path("/Users/ingthor/Documents/stories/appdata/json/5/shots/json")
    
    if not shots_dir.exists():
        print(f"Directory not found: {shots_dir}")
        # Try to find the latest version
        for version in range(10, 0, -1):
            alt_path = Path(f"/Users/ingthor/Documents/stories/appdata/json/{version}/shots/json")
            if alt_path.exists():
                print(f"Found version {version} at: {alt_path}")
                shots_dir = alt_path
                break
        else:
            print("No valid shots directory found!")
            return
    
    print(f"Processing shots in: {shots_dir}")
    print("=" * 80)
    print("DEFAULT NEGATIVE PROMPT FOR 'THE SHEEP IN THE BAÐSTOFA':")
    print("-" * 80)
    print(DEFAULT_NEGATIVE_PROMPT)
    print("=" * 80)
    print("\nThis ensures:")
    print("- No modern anachronisms")
    print("- No stylistic inconsistencies (anime, CGI, etc.)")
    print("- No mood-breaking elements (happiness, warmth)")
    print("- No non-Nordic geographical elements")
    print("- Maintains the dark, isolated Icelandic atmosphere")
    print("=" * 80)
    
    # Get all JSON files
    json_files = list(shots_dir.glob("*.json"))
    print(f"\nFound {len(json_files)} JSON files")
    
    # Auto-proceed
    print("\nProceeding to add default negative prompts to shots that don't have them...")
    
    # Update each file
    success_count = 0
    for filepath in sorted(json_files):
        if update_json_file(filepath):
            success_count += 1
    
    print("=" * 80)
    print(f"Successfully updated {success_count} files")
    
    # Optionally, create a reference file with the negative prompt
    reference_file = shots_dir.parent / "default_negative_prompt.txt"
    with open(reference_file, 'w', encoding='utf-8') as f:
        f.write("DEFAULT NEGATIVE PROMPT FOR 'THE SHEEP IN THE BAÐSTOFA'\n")
        f.write("=" * 80 + "\n\n")
        f.write(DEFAULT_NEGATIVE_PROMPT)
        f.write("\n\n" + "=" * 80 + "\n")
        f.write("This negative prompt ensures consistency across all shots by preventing:\n")
        f.write("- Modern technology and anachronisms\n")
        f.write("- Inappropriate artistic styles\n")
        f.write("- Mood-breaking elements\n")
        f.write("- Non-Nordic geographical elements\n")
    
    print(f"\nReference file created at: {reference_file}")

if __name__ == "__main__":
    main()