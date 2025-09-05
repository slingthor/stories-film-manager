#!/usr/bin/env python3

import re
import os

def split_shots():
    # Read the V18 file
    input_file = "/Users/ingthor/Documents/stories/App/v18_only_shots_true_orig.txt"
    output_dir = "/Users/ingthor/Documents/stories/App/shots/raw"
    
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Split by "SHOT" followed by space and any identifier
    shots = re.split(r'\n(?=SHOT\s)', content)
    
    for i, shot_content in enumerate(shots):
        if not shot_content.strip():
            continue
            
        lines = shot_content.strip().split('\n')
        if not lines:
            continue
            
        # Get the first line as the shot identifier
        first_line = lines[0].strip()
        
        # Extract shot ID from first line (e.g., "SHOT 0a: THE SHADOW POLE" -> "0a_THE_SHADOW_POLE")
        shot_match = re.match(r'SHOT\s+([^:]+):\s*(.+)', first_line)
        
        if shot_match:
            shot_id = shot_match.group(1).strip()
            shot_title = shot_match.group(2).strip()
            
            # Clean up the shot ID and title for filename
            safe_id = re.sub(r'[^\w-]', '_', shot_id)
            safe_title = re.sub(r'[^\w\s-]', '', shot_title)
            safe_title = re.sub(r'\s+', '_', safe_title)
            
            # Create filename
            filename = f"shot_{safe_id}_{safe_title}.txt"
        else:
            # Fallback naming if pattern doesn't match
            filename = f"shot_unknown_{i}.txt"
        
        # Write the shot content to file
        output_path = os.path.join(output_dir, filename)
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(shot_content.strip())
        
        print(f"Created: {filename}")
    
    print(f"\nTotal shots created: {len([f for f in os.listdir(output_dir) if f.endswith('.txt')])}")

if __name__ == "__main__":
    split_shots()