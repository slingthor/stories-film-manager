#!/usr/bin/env python3
"""
Populate Central PlateManager Script
Extracts all character and environmental plates from enhancement files 
and creates a comprehensive central plate index for the PlateManager.
"""

import json
import os
import re
from pathlib import Path
from typing import Dict, List, Any

APPDATA_DIR = '/Users/ingthor/Documents/stories/appdata/json/7'
PLATES_DIR = os.path.join(APPDATA_DIR, 'plates')
ENHANCEMENTS_DIR = '/Users/ingthor/Documents/stories/VEO3-CHARACTER-ENHANCEMENTS'

def extract_character_plates_from_file(filepath: str) -> List[Dict[str, Any]]:
    """Extract all character plates from an enhancement file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    plates = []
    character_name = os.path.basename(filepath).replace('_enhancement.md', '').upper()
    
    # Primary pattern for PLATE X: format
    plate_patterns = [
        r'PLATE\s+(\d+):\s*([^\n]+)\s*\(([^)]*)\).*?\n([A-Z-]+):\s*(.+?)(?=\n\n|\nPLATE|\nACTING|$)',
        r'([A-Z-]+):\s*\[([^\]]+)\]\s*(.+?)(?=\n\n|\n[A-Z-]+:|\nPLATE|\nACTING|$)',
        r'([A-Z-]+):\s*(.+?)(?=\n\n|\n[A-Z-]+:|\nPLATE|\nACTING|$)'
    ]
    
    for pattern in plate_patterns:
        matches = re.finditer(pattern, content, re.DOTALL | re.MULTILINE)
        for match in matches:
            if len(match.groups()) >= 3:
                if pattern == plate_patterns[0]:  # PLATE X: format
                    plate_num = match.group(1)
                    plate_title = match.group(2).strip()
                    shot_range = match.group(3).strip()
                    plate_id = match.group(4).strip()
                    description = match.group(5).strip()
                else:
                    plate_id = match.group(1).strip()
                    if len(match.groups()) == 3:
                        shot_range = match.group(2).strip() if '[' in pattern else ""
                        description = match.group(3).strip() if '[' in pattern else match.group(2).strip()
                    else:
                        shot_range = ""
                        description = match.group(2).strip()
                
                # Clean up description
                description = re.sub(r'\n+', ' ', description).strip()
                description = re.sub(r'\s+', ' ', description)
                
                # Skip if too short or invalid
                if len(description) < 20 or plate_id in ['ACTING', 'NOTES']:
                    continue
                
                plate = {
                    "plateId": plate_id,
                    "character": character_name,
                    "name": plate_id.replace('-', ' ').title(),
                    "description": description,
                    "shotRange": shot_range,
                    "is_master": plate_id == "FOUNDATION" or "PLATE 1" in (plate_title if 'plate_title' in locals() else "")
                }
                
                plates.append(plate)
    
    return plates

def extract_environmental_plates_from_file(filepath: str) -> List[Dict[str, Any]]:
    """Extract environmental plates from enhancement files."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    plates = []
    filename = os.path.basename(filepath)
    
    # Determine category from filename
    if 'house' in filename.lower():
        category = 'HOUSE'
    elif 'westfjords' in filename.lower() or 'environment' in filename.lower():
        category = 'WESTFJORDS'
    else:
        category = 'ENVIRONMENT'
    
    # Extract environmental descriptions
    env_patterns = [
        r'([A-Z][A-Z_-]+):\s*(.+?)(?=\n\n|\n[A-Z][A-Z_-]+:|\n[A-Z]+\s+PLATE|\n[A-Z]+\s+BASE|$)',
        r'ENVIRONMENT\s+(\d+):\s*([^\n]+)\n(.+?)(?=\nENVIRONMENT|\n[A-Z]+\s+PLATE|$)',
        r'BASE\s*([A-Z_-]*)\s*:\s*(.+?)(?=\n\n|\nBASE|\n[A-Z]+:|\n[A-Z]+\s+PLATE|$)'
    ]
    
    for pattern in env_patterns:
        matches = re.finditer(pattern, content, re.DOTALL | re.MULTILINE)
        for match in matches:
            if len(match.groups()) >= 2:
                if 'ENVIRONMENT' in pattern:
                    env_id = f"ENV_{match.group(1)}"
                    name = match.group(2).strip()
                    description = match.group(3).strip()
                else:
                    env_id = match.group(1).strip()
                    description = match.group(2).strip()
                    name = env_id.replace('_', ' ').title()
                
                # Clean description
                description = re.sub(r'\n+', ' ', description).strip()
                description = re.sub(r'\s+', ' ', description)
                
                if len(description) < 20:
                    continue
                
                plate = {
                    "plateId": env_id,
                    "category": category,
                    "name": name,
                    "description": description,
                    "atmosphere": "Westfjords 1888"  # Default atmosphere
                }
                
                plates.append(plate)
    
    return plates

def create_comprehensive_plate_index():
    """Create comprehensive plate indices from enhancement files."""
    
    character_plates = []
    environmental_plates = []
    
    # Process character enhancement files
    if os.path.exists(ENHANCEMENTS_DIR):
        print(f"Extracting character plates from {ENHANCEMENTS_DIR}...")
        
        for file in os.listdir(ENHANCEMENTS_DIR):
            if file.endswith('_enhancement.md'):
                filepath = os.path.join(ENHANCEMENTS_DIR, file)
                print(f"  Processing {file}...")
                
                plates = extract_character_plates_from_file(filepath)
                character_plates.extend(plates)
                print(f"    Found {len(plates)} character plates")
        
        # Also extract environmental data from character files
        for file in os.listdir(ENHANCEMENTS_DIR):
            if file.endswith('_enhancement.md'):
                filepath = os.path.join(ENHANCEMENTS_DIR, file)
                env_plates = extract_environmental_plates_from_file(filepath)
                environmental_plates.extend(env_plates)
    
    print(f"\nTotal extracted:")
    print(f"  Character plates: {len(character_plates)}")
    print(f"  Environmental plates: {len(environmental_plates)}")
    
    # Create plates directory if it doesn't exist
    os.makedirs(PLATES_DIR, exist_ok=True)
    
    # Create character plate index
    char_index_path = os.path.join(PLATES_DIR, 'character_plates_index.json')
    with open(char_index_path, 'w', encoding='utf-8') as f:
        json.dump({
            "plates": character_plates,
            "count": len(character_plates),
            "last_updated": "2025-09-06"
        }, f, indent=2, ensure_ascii=False)
    
    print(f"Created character plate index: {char_index_path}")
    
    # Create environmental plate index
    env_index_path = os.path.join(PLATES_DIR, 'environmental_plates_index.json')
    with open(env_index_path, 'w', encoding='utf-8') as f:
        json.dump({
            "plates": environmental_plates,
            "count": len(environmental_plates),
            "last_updated": "2025-09-06"
        }, f, indent=2, ensure_ascii=False)
    
    print(f"Created environmental plate index: {env_index_path}")
    
    # Show sample plates
    if character_plates:
        print(f"\nSample character plate:")
        sample = character_plates[0]
        print(f"  ID: {sample['plateId']}")
        print(f"  Character: {sample['character']}")
        print(f"  Name: {sample['name']}")
        print(f"  Description: {sample['description'][:100]}...")
    
    if environmental_plates:
        print(f"\nSample environmental plate:")
        sample = environmental_plates[0]
        print(f"  ID: {sample['plateId']}")
        print(f"  Category: {sample['category']}")
        print(f"  Name: {sample['name']}")
        print(f"  Description: {sample['description'][:100]}...")

if __name__ == "__main__":
    create_comprehensive_plate_index()