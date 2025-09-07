#!/usr/bin/env python3

import json
import os
from collections import defaultdict
from pathlib import Path

def analyze_shot_variants(shots_dir="/Users/ingthor/Documents/stories/appdata/json/5/shots/json"):
    """Analyze all shot variants in the directory"""
    
    variants = defaultdict(list)
    all_shots = {}
    
    shots_path = Path(shots_dir)
    
    for json_file in shots_path.glob("*.json"):
        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                
            metadata = data.get('shot_metadata', {})
            shot_id = metadata.get('id', '')
            title = metadata.get('title', '')
            name = metadata.get('name', '')
            duration = metadata.get('duration_seconds', 0)
            narrative = metadata.get('narrative_function', '')
            
            if shot_id:
                variant_info = {
                    'file': json_file.name,
                    'title': title,
                    'name': name,
                    'duration': duration,
                    'narrative': narrative[:50] + '...' if len(narrative) > 50 else narrative
                }
                variants[shot_id].append(variant_info)
                all_shots[shot_id] = True
                
        except Exception as e:
            print(f"Error reading {json_file}: {e}")
    
    print("Shot Variants Analysis")
    print("=" * 60)
    print(f"Total unique shots: {len(all_shots)}")
    print(f"Shots with multiple variants: {sum(1 for v in variants.values() if len(v) > 1)}")
    print()
    
    multi_variants = {k: v for k, v in variants.items() if len(v) > 1}
    
    if multi_variants:
        print("Shots with Multiple Variants:")
        print("-" * 60)
        
        for shot_id in sorted(multi_variants.keys()):
            shot_variants = multi_variants[shot_id]
            print(f"\nShot {shot_id}: {len(shot_variants)} variants")
            
            for i, variant in enumerate(shot_variants, 1):
                print(f"  {i}. {variant['title']}")
                print(f"     Duration: {variant['duration']}s")
                print(f"     Narrative: {variant['narrative']}")
                print(f"     File: {variant['file']}")
                print()
    
    print("\nSpecial Cases Found:")
    print("-" * 60)
    
    print("\nShot 59a (3 variants) - Different narrative approaches:")
    print("  1. House becomes obsidian obelisk (8 seconds)")
    print("  2. Magnús tries to stop her with ram charge (5 seconds)")  
    print("  3. Magnús's final charge through glass (6 seconds)")
    print("\nThese represent different possible climactic moments")
    
    print("\nShot 49a - Authority inspection scene (6 seconds)")
    print("  Shows Magnús redirecting rage toward Sigrid")
    
    print("\nShot 43a - Cane as weapon scene (5 seconds)")
    print("  Authority reassertion through violence")
    
    return variants

if __name__ == "__main__":
    analyze_shot_variants()