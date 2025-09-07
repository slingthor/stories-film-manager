#!/usr/bin/env python3
"""
Comprehensive Plate Extraction
Extract ALL plates from ALL enhancement files to create complete plate system.
"""

import json
import re
import os
from pathlib import Path

class ComprehensivePlateExtractor:
    def __init__(self):
        self.character_plates = {}
        self.environmental_plates = {}
        
        # Plate extraction patterns
        self.plate_patterns = [
            # PLATE X: format
            r'PLATE\s+(\d+):\s*([^\n]+).*?\n([A-Z-]+):\s*(.+?)(?=\n\n|\nPLATE|\nACTING|\nCHARACTER|\nENVIRONMENT|$)',
            # Direct character code format
            r'([A-Z]+-[A-Z]+):\s*(.+?)(?=\n\n|\n[A-Z]+-[A-Z]+:|\nPLATE|\nCHARACTER|\nENVIRONMENT|$)',
            # Environment format
            r'ENVIRONMENT\s+(\d+):\s*([^\n]+).*?\n([A-Z-]+):\s*(.+?)(?=\n\n|\nENVIRONMENT|\nPLATE|$)'
        ]
    
    def extract_from_file(self, filepath: str, character_name: str = None) -> None:
        """Extract plates from a single enhancement file."""
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            print(f"📄 Processing: {os.path.basename(filepath)}")
            
            # Try each pattern
            plates_found = 0
            for pattern in self.plate_patterns:
                matches = re.findall(pattern, content, re.MULTILINE | re.DOTALL)
                
                for match in matches:
                    if len(match) == 4:  # PLATE X format
                        plate_num, description, code, details = match
                        plate_id = f"{code}"
                        name = f"Plate {plate_num}"
                    elif len(match) == 2:  # Direct format
                        code, details = match
                        plate_id = code
                        name = code.replace('-', ' ').title()
                    else:
                        continue
                    
                    # Clean up details
                    details = details.strip()
                    if len(details) > 500:
                        details = details[:500] + "..."
                    
                    # Determine if character or environmental
                    if any(char in filepath.lower() for char in ['magnus', 'sigrid', 'gudrun', 'jon', 'lilja']):
                        # Character plate
                        if character_name:
                            char = character_name
                        else:
                            char = self.extract_character_from_filename(filepath)
                        
                        self.character_plates[plate_id] = {
                            "character": char,
                            "name": name,
                            "description": details,
                            "shot_range": "",
                            "is_master": "master" in name.lower() or "PLATE 1" in name
                        }
                        plates_found += 1
                    else:
                        # Environmental plate
                        category = self.determine_category(filepath, plate_id)
                        self.environmental_plates[plate_id] = {
                            "category": category,
                            "name": name,
                            "description": details
                        }
                        plates_found += 1
            
            print(f"   Extracted {plates_found} plates")
            
        except Exception as e:
            print(f"❌ Error processing {filepath}: {e}")
    
    def extract_character_from_filename(self, filepath: str) -> str:
        """Extract character name from filename."""
        filename = os.path.basename(filepath).lower()
        if 'magnus' in filename:
            return "Magnus"
        elif 'sigrid' in filename:
            return "Sigrid"
        elif 'gudrun' in filename:
            return "Gudrun"
        elif 'jon' in filename:
            return "Jon"
        elif 'lilja' in filename:
            return "Lilja"
        return "Unknown"
    
    def determine_category(self, filepath: str, plate_id: str) -> str:
        """Determine environmental plate category."""
        filename = os.path.basename(filepath).lower()
        if 'baðstofa' in filename or 'interior' in filename:
            return "Interior"
        elif 'westfjords' in filename or 'exterior' in filename:
            return "Exterior"
        elif 'sea' in filename:
            return "Sea"
        else:
            return "Environment"
    
    def extract_all_character_plates(self):
        """Extract plates from all character enhancement files."""
        character_files = [
            ('/Users/ingthor/Documents/stories/enhancements/magnus_advanced_character_plates_system.txt', 'Magnus'),
            ('/Users/ingthor/Documents/stories/enhancements/sigrid_advanced_character_plates_system.txt', 'Sigrid'), 
            ('/Users/ingthor/Documents/stories/enhancements/gudrun_advanced_character_plates_system.txt', 'Gudrun'),
            ('/Users/ingthor/Documents/stories/enhancements/jon_advanced_character_plates_system.txt', 'Jon'),
            ('/Users/ingthor/Documents/stories/enhancements/lilja_advanced_character_plates_system.txt', 'Lilja'),
            ('/Users/ingthor/Documents/stories/enhancements/lilja_complete_character_plates_expanded.txt', 'Lilja')
        ]
        
        print("🎭 Extracting Character Plates:")
        for filepath, character in character_files:
            if os.path.exists(filepath):
                self.extract_from_file(filepath, character)
            else:
                print(f"⚠️  File not found: {filepath}")
    
    def extract_all_environmental_plates(self):
        """Extract plates from all environmental enhancement files."""
        env_files = [
            '/Users/ingthor/Documents/stories/enhancements/baðstofa_environmental_plates_bergrisi_transformation.txt',
            '/Users/ingthor/Documents/stories/enhancements/westfjords_exterior_environmental_plates_system.txt', 
            '/Users/ingthor/Documents/stories/enhancements/sea_environmental_plates_character_progression.txt',
            '/Users/ingthor/Documents/stories/enhancements/house_exterior_immediate_surroundings_plates.txt'
        ]
        
        print("\n🌍 Extracting Environmental Plates:")
        for filepath in env_files:
            if os.path.exists(filepath):
                self.extract_from_file(filepath)
            else:
                print(f"⚠️  File not found: {filepath}")
    
    def save_to_files(self):
        """Save extracted plates to JSON files."""
        output_dir = "/Users/ingthor/Documents/stories/appdata/json/7/plates"
        
        # Save character plates
        char_output = {
            "plate_index": self.character_plates,
            "last_updated": "2025-09-06"
        }
        
        char_path = os.path.join(output_dir, "character_plates_index.json")
        with open(char_path, 'w', encoding='utf-8') as f:
            json.dump(char_output, f, indent=2, ensure_ascii=False)
        
        # Save environmental plates
        env_output = {
            "plate_index": self.environmental_plates,
            "last_updated": "2025-09-06"
        }
        
        env_path = os.path.join(output_dir, "environmental_plates_index.json")
        with open(env_path, 'w', encoding='utf-8') as f:
            json.dump(env_output, f, indent=2, ensure_ascii=False)
        
        print(f"\n📊 Results:")
        print(f"   Character plates: {len(self.character_plates)}")
        print(f"   Environmental plates: {len(self.environmental_plates)}")
        print(f"   Total plates: {len(self.character_plates) + len(self.environmental_plates)}")
        print(f"\n💾 Files saved:")
        print(f"   Character: {char_path}")
        print(f"   Environmental: {env_path}")

if __name__ == "__main__":
    extractor = ComprehensivePlateExtractor()
    extractor.extract_all_character_plates()
    extractor.extract_all_environmental_plates()
    extractor.save_to_files()