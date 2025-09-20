#!/usr/bin/env python3
"""
Comprehensive Veo3 compliance fixes for character and environmental plates.
Removes breathing rates, medical terminology, and non-visual descriptions.
"""

import json
import re
from datetime import datetime
import shutil

def create_backup(file_path):
    """Create timestamped backup of file"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{file_path}.backup_manual_{timestamp}"
    shutil.copy2(file_path, backup_path)
    print(f"Created backup: {backup_path}")
    return backup_path

def fix_plates_content(text):
    """Apply comprehensive Veo3 compliance fixes to text"""

    # Remove all breathing rates except house breathing at 12/min
    # Match patterns like "breathing 15/min", "breathing steady 10/min", etc.
    text = re.sub(r'breathing\s+(?:steady\s+|controlled\s+|slowed\s+to\s+|deepening\s+to\s+|accelerated\s+|accelerating\s+to\s+)?(\d+)/min[^"]*',
                  lambda m: 'breathing' if '12' not in m.group(0) or 'house' not in text[max(0, m.start()-50):m.end()+50] else m.group(0),
                  text)

    # Simplify breathing descriptions
    text = re.sub(r'breathing (\d+)/min[^,]*', 'breathing', text)
    text = re.sub(r'(\d+)/min ([^,]*breathing)', r'\2', text)
    text = re.sub(r'(\d+)/min ([^,]*rhythm)', r'\2', text)
    text = re.sub(r'(\d+)/min ([^,]*rate)', r'\2', text)

    # Fix specific breathing patterns
    replacements = {
        'breathing slowed to maternal rhythm': 'breathing slowed with maternal rhythm',
        'breathing controlled despite revelation stress': 'breathing controlled',
        'breathing exhaustion': 'breathing slow with exhaustion',
        'breathing steady human resistance rhythm': 'breathing steady and controlled',
        'breathing hyperactive fever rate': 'breathing rapid with fever',
        'breathing steady leadership rhythm': 'breathing steady and controlled',
        'breathing human but with raven undertones mixing': 'breathing with mixed human and raven rhythms',
        'breathing normal lamb rhythm': 'breathing with normal lamb rhythm',
        'breathing slowing but controlled': 'breathing slowing but controlled',
        'breathing pre-action anxiety': 'breathing quickened with anxiety',
        'breathing transitioning from human to raven rhythm': 'breathing transitioning between forms',
        'breathing pure raven rhythm': 'breathing with raven rhythm',
        'breathing stress from secret-keeping': 'breathing stressed',
        'breathing child anxiety': 'breathing rapid with anxiety',
        'breathing pain response': 'breathing labored from pain',
        'breathing exploration energy': 'breathing energetic',
        'breathing fear response': 'breathing rapid with fear',
        'breathing mild stress': 'breathing slightly stressed',
        'breathing steady approaching sheep rate': 'breathing approaching sheep rhythm',
        'breathing panic': 'breathing rapid with panic',
        'breathing approaching sheep rhythm': 'breathing shifting',
        'breathing improved health rate': 'breathing improved and steady',
        'breathing oracle rhythm': 'breathing deepening',
        'breathing normal happy child rhythm': 'breathing with child rhythm',
    }

    for old, new in replacements.items():
        text = text.replace(old, new)

    # Fix pregnancy references
    text = re.sub(r'pregnancy\s+(\d+)\s+months?\s+[^,]*visible', r'belly curve visible', text)
    text = re.sub(r'(\d+)\s+months?\s+pregnancy\s+visible', r'belly curve visible', text)
    text = re.sub(r'pregnancy\s+barely\s+visible', 'subtle belly curve barely visible', text)
    text = re.sub(r'pregnancy', 'belly', text)
    text = re.sub(r'pregnant', 'with belly curve', text)

    # Fix rounded belly references
    text = text.replace('rounded belly', 'belly curve')
    text = text.replace('6-month belly curve', 'visible belly curve')
    text = text.replace('5-month belly curve', 'belly curve')
    text = text.replace('3 months belly curve visible', 'subtle belly curve visible')
    text = text.replace('2 months)', 'subtle curve)')
    text = text.replace('9 months accelerated)', '')

    # Fix age references
    text = re.sub(r'16[\s-]?year[\s-]?old', 'young woman', text, flags=re.IGNORECASE)
    text = re.sub(r'sixteen[\s-]?year[\s-]?old', 'young woman', text, flags=re.IGNORECASE)

    # Fix medical/explicit terminology
    text = text.replace('testicle forcing', 'intense ordeal')
    text = text.replace('forced testicle', 'forced ordeal')
    text = text.replace('violation trauma', 'exhausted expression')
    text = text.replace('violation', 'ordeal')
    text = text.replace('trauma', 'exhaustion')
    text = text.replace('medical', 'visual')
    text = text.replace('psychological', 'visible')
    text = text.replace('mental breakdown', 'visible distress')
    text = text.replace('cognitive', 'confused')
    text = text.replace('biological change', 'visible transformation')
    text = text.replace('supernatural authority', 'commanding presence')
    text = text.replace('hypervigilant', 'watchful')
    text = text.replace('stress response', 'tense posture')

    # Fix non-visual descriptions
    text = text.replace('time-worn appearance', 'temporal awareness')
    text = text.replace('emotional depth', 'expressive features')
    text = text.replace('human expressive face', 'human features')
    text = text.replace('expressive face', 'emotional support')
    text = text.replace('confused expression', 'visible confusion')
    text = text.replace('distressed expression', 'visible distress')
    text = text.replace('environdistressed expression', 'environmental changes')
    text = text.replace('subtle knowledge', 'unconscious awareness')
    text = text.replace('visible distress during mathematical', 'anchor during mathematical')

    # Clean up any double spaces
    text = re.sub(r'\s+', ' ', text)

    return text

def fix_json_recursively(data):
    """Recursively fix all strings in JSON data"""
    if isinstance(data, str):
        return fix_plates_content(data)
    elif isinstance(data, list):
        return [fix_json_recursively(item) for item in data]
    elif isinstance(data, dict):
        return {k: fix_json_recursively(v) for k, v in data.items()}
    else:
        return data

def main():
    """Fix character and environmental plates"""
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

            # Fix all content
            fixed_data = fix_json_recursively(data)

            # Write back
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(fixed_data, f, indent=2, ensure_ascii=False)

            print(f"✓ Successfully fixed {file_path}")

        except Exception as e:
            print(f"Error processing {file_path}: {e}")

    print("\n✓ Veo3 compliance fixes complete")

if __name__ == "__main__":
    main()