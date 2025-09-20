#!/usr/bin/env python3
"""
Fix character and environmental plates to be more atmospheric and less medical/gruesome.
Focus on visual atmosphere rather than clinical symptoms.
"""

import json
import re
from datetime import datetime
import shutil

def create_backup(file_path):
    """Create timestamped backup of file"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{file_path}.backup_atmospheric_{timestamp}"
    shutil.copy2(file_path, backup_path)
    print(f"Created backup: {backup_path}")
    return backup_path

def fix_medical_content(text):
    """Apply atmospheric fixes to remove medical/gruesome imagery"""

    # Fix fever references - make them visual not medical
    text = re.sub(r'41°C fever|42°C fever|43°C fever', 'flushed with warmth', text)
    text = re.sub(r'fever (\d+)°C', 'warmth', text)
    text = re.sub(r'(\d+)°C fever', 'flushed warmth', text)
    text = re.sub(r'fever heat', 'warm flush', text)
    text = re.sub(r'dangerous fever heat', 'intense warmth', text)
    text = re.sub(r'fever-driven', 'energy-driven', text)
    text = re.sub(r'fever visions', 'distant visions', text)
    text = re.sub(r'fever sweat', 'perspiration', text)
    text = re.sub(r'fever elevation', 'warm state', text)

    # Fix tooth/bleeding references
    text = re.sub(r'three empty tooth sockets bleeding', 'gaps visible where teeth were', text)
    text = re.sub(r'empty tooth sockets bleeding', 'gaps in smile', text)
    text = re.sub(r'tooth sockets bleeding', 'gaps showing', text)
    text = re.sub(r'bleeding tooth sockets', 'visible gaps', text)
    text = re.sub(r'empty tooth sockets clean', 'gaps in teeth arrangement', text)
    text = re.sub(r'bleeding frozen in beard', 'red frost in beard', text)
    text = re.sub(r'nose bleeding', 'nose showing redness', text)

    # Fix blood references - make them color/visual references
    text = re.sub(r'blood specks', 'red droplets', text)
    text = re.sub(r'producing blood', 'showing redness', text)
    text = re.sub(r'cough producing blood', 'cough with red traces', text)
    text = re.sub(r'with dried blood', 'with dark stains', text)
    text = re.sub(r'blood vessel patterns', 'red vein-like patterns', text)
    text = re.sub(r'divine blood', 'divine essence', text)

    # Fix medical terminology
    text = re.sub(r'skeletal frame', 'thin frame', text)
    text = re.sub(r'tooth eruption', 'teeth appearing', text)
    text = re.sub(r'healing gums', 'mouth changes', text)
    text = re.sub(r'sheep teeth beginning emergence through healing gums', 'teeth changing shape', text)
    text = re.sub(r'dental capability', 'new teeth', text)
    text = re.sub(r'dental function', 'eating ability', text)
    text = re.sub(r'respiratory efficiency', 'breathing changes', text)
    text = re.sub(r'hyperactive fever rate', 'rapid energy', text)
    text = re.sub(r'hypothermia effects', 'cold exposure', text)
    text = re.sub(r'advanced hypothermia', 'extreme cold', text)
    text = re.sub(r'esophageal sphincter', 'throat passage', text)
    text = re.sub(r'burst vessel', 'red coloring', text)

    # Fix contamination references - make them visual/atmospheric
    text = re.sub(r'black fibers pulsing', 'dark veining visible', text)
    text = re.sub(r'Industrial contamination', 'Foreign elements', text)
    text = re.sub(r'industrial contamination', 'strange materials', text)
    text = re.sub(r'contaminated divine', 'transformed sacred', text)
    text = re.sub(r'contaminated god', 'changed deity', text)
    text = re.sub(r'contamination spreading', 'darkness spreading', text)

    # Fix gruesome body references
    text = re.sub(r'skull changes', 'head shape', text)
    text = re.sub(r'changing skull', 'changing appearance', text)
    text = re.sub(r'skull proportions', 'head proportions', text)
    text = re.sub(r'revealing changing skull shape', 'showing different appearance', text)
    text = re.sub(r'flesh texture', 'organic texture', text)
    text = re.sub(r'chest cavity', 'interior space', text)
    text = re.sub(r'circulatory patterns', 'flowing patterns', text)

    # Fix age references for young characters
    text = re.sub(r'8-year-old', 'young boy', text)
    text = re.sub(r'5-year-old', 'small child', text)

    # Fix injury descriptions
    text = re.sub(r'rope burns across palms \(red welts with raw skin\)', 'rope marks on palms', text)
    text = re.sub(r'hook puncture in right palm', 'mark on right palm', text)
    text = re.sub(r'frostbite on exposed fingers showing white then blue discoloration', 'cold-affected fingers showing pale coloring', text)
    text = re.sub(r'raw skin', 'marked skin', text)
    text = re.sub(r'puncture', 'mark', text)

    # Fix other problematic terms
    text = re.sub(r'trembling constant from', 'slight trembling from', text)
    text = re.sub(r'swollen crimson', 'reddened', text)
    text = re.sub(r'red-purple with', 'deeply flushed with', text)
    text = re.sub(r'matted with fever sweat', 'disheveled and damp', text)
    text = re.sub(r'glazed with temporal awareness', 'showing distant awareness', text)
    text = re.sub(r'temporal awareness overload', 'overwhelming visions', text)

    # Clean up any double spaces
    text = re.sub(r'\s+', ' ', text)

    return text

def fix_json_recursively(data):
    """Recursively fix all strings in JSON data"""
    if isinstance(data, str):
        return fix_medical_content(data)
    elif isinstance(data, list):
        return [fix_json_recursively(item) for item in data]
    elif isinstance(data, dict):
        return {k: fix_json_recursively(v) for k, v in data.items()}
    else:
        return data

def main():
    """Fix character and environmental plates for atmospheric visuals"""
    files = [
        '/Users/ingthor/Documents/stories/appdata/json/7/plates/character_plates_complete.json',
        '/Users/ingthor/Documents/stories/appdata/json/7/plates/environmental_plates_complete.json'
    ]

    for file_path in files:
        print(f"\nProcessing: {file_path}")
        print("-" * 50)

        try:
            # Create backup
            create_backup(file_path)

            # Read JSON
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)

            # Count fixes for reporting
            original_str = json.dumps(data)

            # Fix all content
            fixed_data = fix_json_recursively(data)

            # Count changes made
            fixed_str = json.dumps(fixed_data)
            if original_str != fixed_str:
                print(f"✓ Made atmospheric improvements to {file_path}")
            else:
                print(f"  No changes needed for {file_path}")

            # Write back
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(fixed_data, f, indent=2, ensure_ascii=False)

            print(f"✓ Successfully processed {file_path}")

        except Exception as e:
            print(f"Error processing {file_path}: {e}")

    print("\n✓ Atmospheric visual fixes complete")
    print("  - Medical terminology replaced with visual descriptions")
    print("  - Gruesome imagery made atmospheric")
    print("  - Clinical symptoms converted to visual cues")

if __name__ == "__main__":
    main()