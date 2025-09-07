#!/usr/bin/env swift

import Foundation

// Test JSON with selected plates
let testJSON = """
{
  "shot_metadata": {
    "id": "test_shot"
  },
  "prompt_variants": [
    {
      "variant_id": "test_variant",
      "variant_name": "Test",
      "subject": "Test subject",
      "action": "Test action",
      "scene": "Test scene",
      "style": "Test style",
      "selected_plates": {
        "characters": {
          "sigrid": "SIGRID-AWAKENING"
        },
        "environment": {
          "landscape": "WESTFJORDS-HOSTILE"
        }
      }
    }
  ]
}
"""

// Parse JSON
if let data = testJSON.data(using: .utf8),
   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
   let variants = json["prompt_variants"] as? [[String: Any]],
   let firstVariant = variants.first,
   let selectedPlates = firstVariant["selected_plates"] as? [String: Any] {
    
    print("✅ Found selected_plates in JSON")
    
    if let charPlates = selectedPlates["characters"] as? [String: String] {
        print("  Characters:")
        for (char, plateId) in charPlates {
            print("    - \(char): \(plateId)")
        }
        
        // This is what the fix does - extract first character plate
        if let firstChar = charPlates.keys.first {
            let plateId = charPlates[firstChar]
            print("  ➡️ Would set selectedCharacterPlateId to: \(plateId ?? "nil")")
        }
    }
    
    if let envPlates = selectedPlates["environment"] as? [String: String] {
        print("  Environment:")
        for (cat, plateId) in envPlates {
            print("    - \(cat): \(plateId)")
        }
        
        // Extract first environment plate
        if let firstEnv = envPlates.keys.first {
            let plateId = envPlates[firstEnv]
            print("  ➡️ Would set selectedEnvironmentPlateId to: \(plateId ?? "nil")")
        }
    }
} else {
    print("❌ Failed to parse JSON or find selected_plates")
}

print("\n✅ The fix should now properly load saved plate selections when switching shots!")