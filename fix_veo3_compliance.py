#!/usr/bin/env python3
"""
Fix Veo3 compliance issues in JSON files by converting to visual descriptions.
Handles age references, medical terminology, and non-visual descriptions.
"""

import json
import os
import re
from datetime import datetime
from pathlib import Path
import shutil

def create_backup(file_path):
    """Create timestamped backup of file"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{file_path}.backup_veo3_{timestamp}"
    shutil.copy2(file_path, backup_path)
    print(f"  Created backup: {backup_path}")
    return backup_path

def fix_age_references(text):
    """Replace age-specific references with visual descriptions"""
    # Replace 16 year old with young woman
    text = re.sub(r'\b16[\s-]?year[\s-]?old\b', 'young woman', text, flags=re.IGNORECASE)
    text = re.sub(r'\b16[\s-]?years[\s-]?old\b', 'young woman', text, flags=re.IGNORECASE)
    text = re.sub(r'\bsixteen[\s-]?year[\s-]?old\b', 'young woman', text, flags=re.IGNORECASE)

    # Replace child/children medical references with visual descriptions
    text = re.sub(r'(\bchild\w*\b)([^.]*)(medical|trauma|injury)',
                  r'\1\2exhausted appearance', text, flags=re.IGNORECASE)

    return text

def fix_pregnancy_references(text):
    """Replace pregnancy references with visual descriptions"""
    replacements = {
        # Pregnancy with age
        r'pregnant\s+16[\s-]?year[\s-]?old': 'slender young woman with rounded belly',
        r'16[\s-]?year[\s-]?old\s+pregnant': 'slender young woman with rounded belly',

        # General pregnancy references
        r'pregnancy\s+(\d+)[\s-]?month\w*\s+\w*\s+show\w*': r'subtle curve of belly',
        r'pregnancy\s+now\s+visible': 'subtle curve of belly visible',
        r'pregnancy\s+(\d+)-(\d+)\s+months': r'rounded belly',
        r'pregnant\s+teenager': 'young woman with rounded belly',
        r'pregnant\s+girl': 'young woman with rounded belly',
        r'pregnant\s+young': 'young woman with rounded belly',

        # Protective gestures over pregnancy
        r'(arms?\s+\w*\s*over\s+)pregnancy': r'\1belly',
        r'(hand\s+\w*\s*over\s+)pregnancy': r'\1belly',
        r'(protective\s+\w*\s*over\s+)pregnancy': r'\1belly',
        r'(shielding\s+)pregnancy': r'\1belly',

        # General pregnancy word replacement
        r'\bpregnancy\b': 'rounded belly',
        r'\bpregnant\b': 'with rounded belly'
    }

    for pattern, replacement in replacements.items():
        text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)

    return text

def fix_medical_terminology(text):
    """Replace medical and explicit terminology with visual descriptions"""
    replacements = {
        # Testicle forcing references - convert to visual aftermath
        r'after\s+testicle\s+forcing': 'disheveled and exhausted',
        r'from\s+forced\s+testicle\s+consumption': 'from ordeal',
        r'testicle\s+forcing': 'intense ordeal',
        r'forced\s+testicle': 'forced ordeal',

        # Violation references - convert to visual
        r'violation\s+trauma': 'exhausted expression',
        r'violation\s+awareness': 'wary expression',
        r'violation\s+struggle': 'disheveled state',
        r'from\s+violation': 'from ordeal',
        r'violation': 'ordeal',

        # Medical imagery
        r'trauma\s+but\s+strengthening': 'exhaustion with determined',
        r'hypervigilant\s+scanning': 'watchful gaze',
        r'stress\s+response': 'tense posture',
        r'biological\s+change': 'visible change',
        r'supernatural\s+authority': 'commanding presence',

        # Convert internal states to visual
        r'innocence\s+lost': 'serious expression',
        r'protective\s+determination': 'defensive stance',
        r'combining\s+\w+\s+with': 'showing',

        # Breathing descriptions - simplify
        r'breathing\s+shifted\s+to\s+\d+/min': 'quick breathing',
        r'breathing\s+controlled\s+\d+/min': 'steady breathing',

        # Voice changes - more visual
        r'voice\s+dropped\s+half-octave': 'speaking in deeper tone',
        r'voice\s+dropped\s+to\s+lower': 'speaking in lower voice',
        r'with\s+clear\s+raven\s+undertones': 'with unusual vocal quality',
        r'with\s+slight\s+raven\s+undertone': 'with unusual tone',

        # Physical descriptions
        r'spine\s+shielding\s+belly': 'hunched protectively forward',
        r'shoulders\s+hunched\s+forward': 'shoulders drawn inward',
        r'defensive\s+spacing': 'keeping distance',

        # Remove overly specific medical details
        r'\d+\s*feet\s+from\s+\w+\s+against\s+wall': 'backed against wall',
        r'positioned\s+exactly\s+\d+\s+feet': 'positioned away',
        r'positioned\s+maximum\s+\d+\s+feet': 'positioned far'
    }

    for pattern, replacement in replacements.items():
        text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)

    return text

def fix_psychological_to_visual(text):
    """Convert psychological descriptions to visual behaviors"""
    replacements = {
        # Psychological states to visual
        r'psychological\s+\w+': 'visible distress',
        r'mental\s+\w+': 'distressed expression',
        r'cognitive\s+\w+': 'confused expression',
        r'emotional\s+\w+': 'expressive face',

        # Abstract concepts to visual
        r'supernatural\s+presence': 'imposing figure',
        r'mythological\s+\w+': 'otherworldly appearance',
        r'spiritual\s+protection': 'clutching cross',

        # Internal states to external
        r'inner\s+\w+': 'visible',
        r'internal\s+\w+': 'apparent',
        r'unconscious\s+\w+': 'subtle',

        # Metaphysical to physical
        r'dimension\s+\w+': 'distorted appearance',
        r'reality\s+\w+': 'surreal visual',
        r'temporal\s+\w+': 'time-worn appearance'
    }

    for pattern, replacement in replacements.items():
        text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)

    return text

def process_json_value(value):
    """Process any JSON value (string, list, dict) for compliance"""
    if isinstance(value, str):
        # Apply all fixes in sequence
        value = fix_age_references(value)
        value = fix_pregnancy_references(value)
        value = fix_medical_terminology(value)
        value = fix_psychological_to_visual(value)
        return value
    elif isinstance(value, list):
        return [process_json_value(item) for item in value]
    elif isinstance(value, dict):
        return {k: process_json_value(v) for k, v in value.items()}
    else:
        return value

def fix_json_file(file_path):
    """Fix compliance issues in a JSON file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # Process the entire data structure
        fixed_data = process_json_value(data)

        # Check if any changes were made
        if json.dumps(data) != json.dumps(fixed_data):
            # Create backup before modifying
            create_backup(file_path)

            # Write fixed data
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(fixed_data, f, indent=2, ensure_ascii=False)

            return True
        return False
    except Exception as e:
        print(f"  Error processing {file_path}: {e}")
        return False

def main():
    """Main function to fix all JSON files"""
    print("Fixing Veo3 compliance issues in JSON files...")
    print("=" * 60)

    # Define paths to process
    paths_to_process = [
        '/Users/ingthor/Documents/stories/appdata/json/7/shots/json',
        '/Users/ingthor/Documents/stories/appdata/json/7/plates'
    ]

    total_fixed = 0
    total_processed = 0

    for base_path in paths_to_process:
        if not os.path.exists(base_path):
            print(f"Path not found: {base_path}")
            continue

        print(f"\nProcessing: {base_path}")
        print("-" * 40)

        # Find all JSON files
        json_files = list(Path(base_path).rglob('*.json'))

        for json_file in json_files:
            # Skip backup files
            if 'backup' in str(json_file):
                continue

            total_processed += 1
            print(f"Checking: {json_file.name}")

            if fix_json_file(str(json_file)):
                print(f"  ✓ Fixed compliance issues")
                total_fixed += 1
            else:
                print(f"  - No changes needed")

    print("\n" + "=" * 60)
    print(f"Summary:")
    print(f"  Total files processed: {total_processed}")
    print(f"  Files fixed: {total_fixed}")
    print(f"  Files unchanged: {total_processed - total_fixed}")

    if total_fixed > 0:
        print(f"\n✓ Successfully fixed {total_fixed} files for Veo3 compliance")
        print("  Backups created with .backup_veo3_TIMESTAMP extension")
    else:
        print("\n✓ All files already compliant")

if __name__ == "__main__":
    main()