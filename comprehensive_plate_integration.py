#!/usr/bin/env python3
"""
Comprehensive Plate Integration Script
Extracts plate data from enhancement files and integrates into shot JSON files
with available_plates and selected_plates sections as per PLATE_JSON_INTEGRATION_GUIDE.md
"""

import json
import re
import os
from pathlib import Path
from typing import Dict, List, Tuple, Optional

# Configuration
ENHANCEMENT_FILES = {
    'character': [
        '/Users/ingthor/Documents/stories/enhancements/magnus_advanced_character_plates_system.txt',
        '/Users/ingthor/Documents/stories/enhancements/sigrid_advanced_character_plates_system.txt', 
        '/Users/ingthor/Documents/stories/enhancements/gudrun_advanced_character_plates_system.txt',
        '/Users/ingthor/Documents/stories/enhancements/jon_advanced_character_plates_system.txt',
        '/Users/ingthor/Documents/stories/enhancements/lilja_complete_character_plates_expanded.txt'
    ],
    'environmental': [
        '/Users/ingthor/Documents/stories/enhancements/baðstofa_environmental_plates_bergrisi_transformation.txt',
        '/Users/ingthor/Documents/stories/enhancements/westfjords_exterior_environmental_plates_system.txt',
        '/Users/ingthor/Documents/stories/enhancements/sea_environmental_plates_character_progression.txt'
    ]
}

SHOT_JSON_DIR = '/Users/ingthor/Documents/stories/App/shots/json'
MAPPING_FILE = '/Users/ingthor/Documents/stories/enhancements/MASTER_CHARACTER_INTEGRATION_SHOT_BY_SHOT_MAPPING.txt'

class PlateExtractor:
    def __init__(self):
        self.character_plates = {}  # character -> list of plates
        self.environmental_plates = {}  # category -> list of plates
        self.shot_mappings = {}  # shot_num -> {character_plates: {}, env_plates: {}}
        
    def parse_shot_range(self, shot_range_text: str) -> List[int]:
        """Parse shot ranges like '(Shots 1-9)' or 'Shot 15' into list of shot numbers."""
        if not shot_range_text:
            return []
        
        shot_numbers = []
        
        # Pattern for ranges like "Shots 1-9", "(Shots 1-9)", "Shot 15"
        patterns = [
            r'[Ss]hots?\s*(\d+)\s*-\s*(\d+)',  # Range: Shots 1-9
            r'[Ss]hot\s*(\d+)',                # Single: Shot 15
            r'\(.*[Ss]hots?\s*(\d+)\s*-\s*(\d+)',  # Parentheses range
            r'\(.*[Ss]hot\s*(\d+)'             # Parentheses single
        ]
        
        for pattern in patterns:
            matches = re.findall(pattern, shot_range_text)
            for match in matches:
                if isinstance(match, tuple) and len(match) == 2 and match[1]:
                    # Range match
                    start, end = int(match[0]), int(match[1])
                    shot_numbers.extend(range(start, end + 1))
                elif isinstance(match, str):
                    # Single match
                    shot_numbers.append(int(match))
                elif isinstance(match, tuple) and len(match) >= 1:
                    # Single match from tuple
                    shot_numbers.append(int(match[0]))
                    
        return list(set(shot_numbers))  # Remove duplicates
    
    def extract_character_plates(self, filepath: str) -> None:
        """Extract character plates from enhancement files."""
        print(f"Extracting character plates from {filepath}")
        
        if not os.path.exists(filepath):
            print(f"Warning: File not found: {filepath}")
            return
            
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Extract character name from filename
        character_name = None
        filename = os.path.basename(filepath).lower()
        for name in ['magnus', 'sigrid', 'gudrun', 'jon', 'lilja']:
            if name in filename:
                character_name = name
                break
        
        if not character_name:
            print(f"Could not determine character name from {filepath}")
            return
        
        if character_name not in self.character_plates:
            self.character_plates[character_name] = []
        
        # Extract plates using improved pattern matching
        # Look for patterns like "PLATE X:", "CHARACTER-VARIATION:", etc.
        plate_patterns = [
            r'PLATE\s+(\d+):\s*([^\n]+)\s*\(([^)]*)\).*?\n([A-Z-]+):\s*(.+?)(?=\n\n|\nPLATE|\nACTING|$)',
            r'([A-Z-]+):\s*\[([^\]]+)\]\s*(.+?)(?=\n\n|\n[A-Z-]+:|\nPLATE|\nACTING|$)',
            r'([A-Z-]+):\s*(.+?)(?=\n\n|\n[A-Z-]+:|\nPLATE|\nACTING|$)'
        ]
        
        for pattern in plate_patterns:
            matches = re.finditer(pattern, content, re.DOTALL | re.MULTILINE)
            for match in matches:
                try:
                    if len(match.groups()) >= 5:  # Full plate pattern
                        plate_num, name, shot_range, plate_id, description = match.groups()
                        plate_name = name.strip()
                        shot_range = shot_range.strip()
                    elif len(match.groups()) >= 3 and '[' in match.group(2):  # Master base pattern
                        plate_id, base_info, description = match.groups()
                        plate_name = self.extract_name_from_description(description)
                        shot_range = self.extract_shot_range_from_context(content, match.start())
                    else:  # Simple pattern
                        plate_id, description = match.groups()[:2]
                        plate_name = self.extract_name_from_description(description)
                        shot_range = self.extract_shot_range_from_context(content, match.start())
                    
                    # Clean up description
                    description = self.clean_description(description)
                    
                    # Only add if we have meaningful content
                    if len(description.strip()) > 50:  # Minimum meaningful description
                        plate_data = {
                            'id': plate_id.strip(),
                            'name': plate_name,
                            'description': description.strip(),
                            'shot_range': shot_range,
                            'character': character_name
                        }
                        
                        self.character_plates[character_name].append(plate_data)
                        print(f"  Extracted: {plate_id} - {plate_name}")
                
                except Exception as e:
                    print(f"Error parsing plate match: {e}")
                    continue
    
    def extract_environmental_plates(self, filepath: str) -> None:
        """Extract environmental plates from enhancement files."""
        print(f"Extracting environmental plates from {filepath}")
        
        if not os.path.exists(filepath):
            print(f"Warning: File not found: {filepath}")
            return
            
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Determine category from filename
        category = 'general'
        filename = os.path.basename(filepath).lower()
        if 'baðstofa' in filename or 'interior' in filename:
            category = 'interior'
        elif 'westfjords' in filename or 'exterior' in filename:
            category = 'landscape'
        elif 'sea' in filename:
            category = 'sea'
        elif 'weather' in filename:
            category = 'weather'
        
        if category not in self.environmental_plates:
            self.environmental_plates[category] = []
        
        # Extract environment plates
        env_patterns = [
            r'ENVIRONMENT\s+(\d+):\s*([^\n]+)\s*\(([^)]*)\).*?\n([A-Z-]+):\s*(.+?)(?=\n\n|\nENVIRONMENT|\nACTING|$)',
            r'([A-Z-]+):\s*(.+?)(?=\n\n|\n[A-Z-]+:|\nENVIRONMENT|\nACTING|$)'
        ]
        
        for pattern in env_patterns:
            matches = re.finditer(pattern, content, re.DOTALL | re.MULTILINE)
            for match in matches:
                try:
                    if len(match.groups()) >= 5:
                        env_num, name, shot_range, env_id, description = match.groups()
                        env_name = name.strip()
                        shot_range = shot_range.strip()
                    else:
                        env_id, description = match.groups()[:2]
                        env_name = self.extract_name_from_description(description)
                        shot_range = self.extract_shot_range_from_context(content, match.start())
                    
                    description = self.clean_description(description)
                    
                    if len(description.strip()) > 50:
                        env_data = {
                            'id': env_id.strip(),
                            'name': env_name,
                            'description': description.strip(),
                            'shot_range': shot_range,
                            'category': category
                        }
                        
                        self.environmental_plates[category].append(env_data)
                        print(f"  Extracted: {env_id} - {env_name}")
                
                except Exception as e:
                    print(f"Error parsing environment match: {e}")
                    continue
    
    def extract_name_from_description(self, description: str) -> str:
        """Extract a readable name from the description."""
        # Try to find a descriptive phrase at the beginning
        first_line = description.split('\n')[0].strip()
        first_sentence = first_line.split('.')[0].strip()
        
        # Remove technical prefixes
        name = re.sub(r'^\[Master base\]\s*', '', first_sentence, flags=re.IGNORECASE)
        name = re.sub(r'^.*?:\s*', '', name)  # Remove "CHARACTER-ID:" prefix
        
        # Take first meaningful phrase (up to 50 chars)
        if len(name) > 50:
            words = name.split()[:6]  # First 6 words
            name = ' '.join(words) + '...' if len(words) == 6 else ' '.join(words)
        
        return name if name else "Character Plate"
    
    def extract_shot_range_from_context(self, content: str, match_start: int) -> str:
        """Extract shot range from surrounding context."""
        # Look backwards and forwards for shot range indicators
        context_before = content[max(0, match_start - 200):match_start]
        context_after = content[match_start:match_start + 200]
        
        full_context = context_before + context_after
        
        # Look for shot range patterns
        range_patterns = [
            r'\([^)]*[Ss]hots?\s*\d+[^)]*\)',
            r'[Ss]hots?\s*\d+\s*-\s*\d+',
            r'[Ss]hot\s*\d+'
        ]
        
        for pattern in range_patterns:
            match = re.search(pattern, full_context)
            if match:
                return match.group(0)
        
        return ""
    
    def clean_description(self, description: str) -> str:
        """Clean up description text."""
        # Remove excessive whitespace
        description = re.sub(r'\s+', ' ', description)
        # Remove control characters
        description = re.sub(r'[\x00-\x1f\x7f-\x9f]', '', description)
        # Remove markdown-like formatting
        description = re.sub(r'\*\*([^*]+)\*\*', r'\1', description)
        description = re.sub(r'\*([^*]+)\*', r'\1', description)
        
        return description.strip()
    
    def load_shot_mappings(self) -> None:
        """Load shot-to-plate mappings from the mapping file."""
        print(f"Loading shot mappings from {MAPPING_FILE}")
        
        if not os.path.exists(MAPPING_FILE):
            print(f"Warning: Mapping file not found: {MAPPING_FILE}")
            return
        
        with open(MAPPING_FILE, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Extract shot mappings using pattern matching
        shot_pattern = r'\*\*SHOT\s+([^:]+):\s*([^*]+)\*\*(.+?)(?=\*\*SHOT|\*\*Family|$)'
        matches = re.finditer(shot_pattern, content, re.DOTALL | re.MULTILINE)
        
        for match in matches:
            try:
                shot_id, shot_title, mapping_content = match.groups()
                shot_num = self.extract_shot_number(shot_id)
                
                if shot_num:
                    character_mappings = self.extract_character_mappings(mapping_content)
                    
                    if shot_num not in self.shot_mappings:
                        self.shot_mappings[shot_num] = {'character_plates': {}, 'env_plates': {}}
                    
                    self.shot_mappings[shot_num]['character_plates'] = character_mappings
                    print(f"  Mapped Shot {shot_num}: {len(character_mappings)} characters")
            
            except Exception as e:
                print(f"Error parsing shot mapping: {e}")
                continue
    
    def extract_shot_number(self, shot_id: str) -> Optional[int]:
        """Extract numeric shot number from shot ID."""
        match = re.search(r'(\d+)', shot_id)
        return int(match.group(1)) if match else None
    
    def extract_character_mappings(self, content: str) -> Dict[str, str]:
        """Extract character plate mappings from shot content."""
        mappings = {}
        
        # Look for patterns like "- Magnus: MAGNÚS-AUTHORITY"
        char_pattern = r'-\s*([^:]+):\s*([A-Z-]+)'
        matches = re.finditer(char_pattern, content)
        
        for match in matches:
            char_name, plate_id = match.groups()
            char_name = char_name.strip().lower()
            
            # Normalize character names
            if char_name in ['magnus', 'magnús']:
                char_name = 'magnus'
            elif char_name in ['sigrid']:
                char_name = 'sigrid'
            elif char_name in ['gudrun', 'guðrún']:
                char_name = 'gudrun'
            elif char_name in ['jon', 'jón']:
                char_name = 'jon'
            elif char_name in ['lilja']:
                char_name = 'lilja'
            
            if char_name in ['magnus', 'sigrid', 'gudrun', 'jon', 'lilja']:
                mappings[char_name] = plate_id.strip()
        
        return mappings
    
    def find_plates_for_shot(self, shot_num: int) -> Tuple[Dict, Dict]:
        """Find all available plates for a given shot number."""
        available_char_plates = {}
        available_env_plates = {}
        
        # Find character plates that apply to this shot
        for character, plates in self.character_plates.items():
            char_plates_for_shot = []
            
            for plate in plates:
                shot_range = self.parse_shot_range(plate['shot_range'])
                if not shot_range or shot_num in shot_range:
                    char_plates_for_shot.append({
                        'id': plate['id'],
                        'name': plate['name'],
                        'description': plate['description']
                    })
            
            if char_plates_for_shot:
                available_char_plates[character] = char_plates_for_shot
        
        # Find environmental plates that apply to this shot  
        for category, plates in self.environmental_plates.items():
            env_plates_for_shot = []
            
            for plate in plates:
                shot_range = self.parse_shot_range(plate['shot_range'])
                if not shot_range or shot_num in shot_range:
                    env_plates_for_shot.append({
                        'id': plate['id'],
                        'name': plate['name'],
                        'description': plate['description']
                    })
            
            if env_plates_for_shot:
                available_env_plates[category] = env_plates_for_shot
        
        return available_char_plates, available_env_plates
    
    def get_default_selections(self, shot_num: int, available_char_plates: Dict, available_env_plates: Dict) -> Tuple[Dict, Dict]:
        """Get default plate selections for a shot."""
        char_selections = {}
        env_selections = {}
        
        # Use mapping file selections if available
        if shot_num in self.shot_mappings:
            mapped_chars = self.shot_mappings[shot_num]['character_plates']
            
            for character, plate_id in mapped_chars.items():
                if character in available_char_plates:
                    # Find matching plate
                    for plate in available_char_plates[character]:
                        if plate['id'] == plate_id:
                            char_selections[character] = plate_id
                            break
        
        # Fill in missing characters with first available plate
        for character, plates in available_char_plates.items():
            if character not in char_selections and plates:
                char_selections[character] = plates[0]['id']
        
        # Select first available environmental plate per category
        for category, plates in available_env_plates.items():
            if plates:
                env_selections[category] = plates[0]['id']
        
        return char_selections, env_selections
    
    def process_all_files(self) -> None:
        """Process all enhancement files to extract plate data."""
        print("Starting comprehensive plate extraction...")
        
        # Extract character plates
        for filepath in ENHANCEMENT_FILES['character']:
            self.extract_character_plates(filepath)
        
        # Extract environmental plates
        for filepath in ENHANCEMENT_FILES['environmental']:
            self.extract_environmental_plates(filepath)
        
        # Load shot mappings
        self.load_shot_mappings()
        
        print(f"\nExtraction complete:")
        print(f"- Character plates: {sum(len(plates) for plates in self.character_plates.values())}")
        print(f"- Environmental plates: {sum(len(plates) for plates in self.environmental_plates.values())}")
        print(f"- Shot mappings: {len(self.shot_mappings)}")
    
    def update_shot_json(self, shot_file_path: str) -> bool:
        """Update a single shot JSON file with plate data."""
        with open(shot_file_path, 'r', encoding='utf-8') as f:
            shot_data = json.load(f)
        
        # Extract shot number
        filename = os.path.basename(shot_file_path)
        shot_match = re.search(r'shot_(\d+)', filename)
        if not shot_match:
            return False
        
        shot_num = int(shot_match.group(1))
        print(f"Processing Shot {shot_num}...")
        
        # Find available plates for this shot
        available_char_plates, available_env_plates = self.find_plates_for_shot(shot_num)
        
        # Get default selections
        char_selections, env_selections = self.get_default_selections(
            shot_num, available_char_plates, available_env_plates
        )
        
        # Update each prompt variant
        updated = False
        for variant in shot_data.get('prompt_variants', []):
            # Add available_plates section
            variant['character_plates'] = {
                'available_plates': available_char_plates,
                'selected_plates': char_selections
            }
            
            variant['environmental_plates'] = {
                'available_plates': available_env_plates,
                'selected_plates': env_selections
            }
            
            # Also update the selected_plates section for backward compatibility
            if 'selected_plates' not in variant:
                variant['selected_plates'] = {}
            
            variant['selected_plates']['characters'] = char_selections
            variant['selected_plates']['environment'] = env_selections
            
            updated = True
        
        if updated:
            # Write back the updated file
            with open(shot_file_path, 'w', encoding='utf-8') as f:
                json.dump(shot_data, f, indent=2, ensure_ascii=False)
            
            print(f"  Updated with {len(available_char_plates)} character types, {len(available_env_plates)} environment types")
        
        return updated
    
    def update_all_shot_files(self) -> None:
        """Update all shot JSON files with plate data."""
        total_updated = 0
        
        for shot_dir in SHOT_JSON_DIRS:
            print(f"\nUpdating shot files in {shot_dir}...")
            
            if not os.path.exists(shot_dir):
                print(f"Shot directory not found: {shot_dir}")
                continue
            
            # Get all JSON files that contain "shot_" regardless of naming pattern
            shot_files = [f for f in Path(shot_dir).glob('*.json') if 'shot_' in f.name.lower()]
            print(f"Found {len(shot_files)} potential shot files")
            
            updated_count = 0
            
            for shot_file in shot_files:
                try:
                    if self.update_shot_json(str(shot_file)):
                        updated_count += 1
                        total_updated += 1
                        if updated_count % 20 == 0:
                            print(f"  Progress: {updated_count} files updated...")
                except Exception as e:
                    print(f"Error updating {shot_file}: {e}")
            
            print(f"Directory update complete: {updated_count} shot files updated")
        
        print(f"\nTotal update complete: {total_updated} shot files updated across all directories")

def main():
    """Main integration function."""
    extractor = PlateExtractor()
    
    # Process all enhancement files
    extractor.process_all_files()
    
    # Update all shot JSON files
    extractor.update_all_shot_files()
    
    print("\nComprehensive plate integration complete!")
    print("Shot JSON files now have available_plates and selected_plates sections")
    print("The Film Manager UI should now show populated plate dropdowns")

if __name__ == "__main__":
    main()