#!/usr/bin/env swift

import Foundation

// Test if plate index files exist and are readable
let charPlatesPath = "/Users/ingthor/Documents/stories/appdata/json/5/plate_indices/character_plates.json"
let envPlatesPath = "/Users/ingthor/Documents/stories/appdata/json/5/plate_indices/environmental_plates.json"

print("Testing PlateManager Data Sources")
print(String(repeating: "=", count: 50))

// Check character plates
print("\n📘 Character Plates Index:")
if FileManager.default.fileExists(atPath: charPlatesPath) {
    print("  ✅ File exists at: \(charPlatesPath)")
    
    if let data = FileManager.default.contents(atPath: charPlatesPath),
       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let plateIndex = json["plate_index"] as? [String: Any] {
        
        print("  ✅ Loaded \(plateIndex.count) character plates")
        
        // Check for specific plates
        if plateIndex["MAGNUS-POSSESSOR"] != nil {
            print("  ✅ Found MAGNUS-POSSESSOR")
        } else {
            print("  ❌ MAGNUS-POSSESSOR not found!")
        }
        
        if plateIndex["SIGRID-CORNERED"] != nil {
            print("  ✅ Found SIGRID-CORNERED")
        } else {
            print("  ❌ SIGRID-CORNERED not found!")
        }
        
        // List all Magnus plates
        print("\n  Magnus plates found:")
        for (plateId, _) in plateIndex {
            if plateId.starts(with: "MAGNUS") {
                print("    - \(plateId)")
            }
        }
        
    } else {
        print("  ❌ Failed to parse JSON")
    }
} else {
    print("  ❌ File does not exist!")
}

// Check environment plates
print("\n📘 Environmental Plates Index:")
if FileManager.default.fileExists(atPath: envPlatesPath) {
    print("  ✅ File exists at: \(envPlatesPath)")
    
    if let data = FileManager.default.contents(atPath: envPlatesPath),
       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let plateIndex = json["plate_index"] as? [String: Any] {
        
        print("  ✅ Loaded \(plateIndex.count) environmental plates")
        
        if plateIndex["BADSTOFA-CLIFF"] != nil {
            print("  ✅ Found BADSTOFA-CLIFF")
        } else {
            print("  ❌ BADSTOFA-CLIFF not found!")
        }
        
    } else {
        print("  ❌ Failed to parse JSON")
    }
} else {
    print("  ❌ File does not exist!")
}

// Test a shot file
print("\n📘 Shot 49a Data:")
let shotPath = "/Users/ingthor/Documents/stories/appdata/json/5/shots/json/shot_49a_main_MAGNÃšS_REDIRECTS_RAGE_-_THE_INSPECTION_BEGINS_6_SECONDS.json"

if let data = FileManager.default.contents(atPath: shotPath),
   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
   let variants = json["prompt_variants"] as? [[String: Any]],
   let firstVariant = variants.first {
    
    if let selectedPlates = firstVariant["selected_plates"] as? [String: Any] {
        print("  ✅ Has selected_plates")
        
        if let chars = selectedPlates["characters"] as? [String: String] {
            print("  Characters selected:")
            for (char, plateId) in chars {
                print("    - \(char): \(plateId)")
            }
        }
    } else {
        print("  ❌ No selected_plates found")
    }
    
    if let availablePlates = firstVariant["available_plates"] as? [String: Any] {
        print("  ✅ Has available_plates")
    } else {
        print("  ❌ No available_plates found")
    }
}