#!/usr/bin/env python3

import json

# Update shot 49a with selected plates to test
shot_file = "/Users/ingthor/Documents/stories/appdata/json/5/shots/json/shot_49a_main_MAGNÃšS_REDIRECTS_RAGE_-_THE_INSPECTION_BEGINS_6_SECONDS.json"

with open(shot_file, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Add selected plates to first variant
if 'prompt_variants' in data and len(data['prompt_variants']) > 0:
    variant = data['prompt_variants'][0]
    
    # Add selected plates based on the character plates present
    variant['selected_plates'] = {
        'characters': {
            'sigrid': 'SIGRID-AWAKENING'
        },
        'environment': {
            'interior': 'BAÐSTOFA-CLIFF'
        }
    }
    
    print(f"✅ Added selected plates to {variant.get('variant_name', 'unnamed variant')}")
    print(f"   Characters: sigrid -> SIGRID-AWAKENING")
    print(f"   Environment: interior -> BAÐSTOFA-CLIFF")
    
    # Save the file
    with open(shot_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Saved to {shot_file}")