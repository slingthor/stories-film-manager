#!/usr/bin/env swift

import Foundation

// Test loading shot 49a which we know has plates
let shotFile = "/Users/ingthor/Documents/stories/appdata/json/5/shots/json/shot_49a_main_MAGNÃšS_REDIRECTS_RAGE_-_THE_INSPECTION_BEGINS_6_SECONDS.json"

if let data = try? Data(contentsOf: URL(fileURLWithPath: shotFile)),
   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
   let variants = json["prompt_variants"] as? [[String: Any]],
   let firstVariant = variants.first {
    
    print("📘 Analyzing shot 49a variant structure:")
    print(String(repeating: "=", count: 50))
    
    // Check selected_plates
    if let selectedPlates = firstVariant["selected_plates"] as? [String: Any] {
        print("\n✅ Found selected_plates:")
        
        if let chars = selectedPlates["characters"] as? [String: String] {
            print("  Characters:")
            for (char, plateId) in chars {
                print("    - \(char): \(plateId)")
            }
            
            // Simulate priority selection
            let priorityOrder = ["magnus", "sigrid", "gudrun", "jon", "lilja"]
            for priority in priorityOrder {
                if let plateId = chars[priority] {
                    print("  ➡️ Would select character plate: \(plateId) (for \(priority))")
                    break
                }
            }
        }
        
        if let envs = selectedPlates["environment"] as? [String: String] {
            print("\n  Environment:")
            for (env, plateId) in envs {
                print("    - \(env): \(plateId)")
            }
            
            // Simulate priority selection
            let priorityOrder = ["interior", "landscape", "weather", "sea"]
            for priority in priorityOrder {
                if let plateId = envs[priority] {
                    print("  ➡️ Would select environment plate: \(plateId) (for \(priority))")
                    break
                }
            }
        }
    }
    
    // Check if individual fields exist
    print("\n📌 Individual plate fields:")
    if let charPlateId = firstVariant["selected_character_plate_id"] as? String {
        print("  selected_character_plate_id: \(charPlateId)")
    } else {
        print("  selected_character_plate_id: NOT FOUND")
    }
    
    if let envPlateId = firstVariant["selected_environment_plate_id"] as? String {
        print("  selected_environment_plate_id: \(envPlateId)")
    } else {
        print("  selected_environment_plate_id: NOT FOUND")
    }
    
    // Check available_plates
    if let availablePlates = firstVariant["available_plates"] as? [String: Any] {
        print("\n📚 Available plates:")
        if let chars = availablePlates["characters"] as? [String: [[String: Any]]] {
            print("  Character categories: \(chars.keys.joined(separator: ", "))")
        }
        if let envs = availablePlates["environment"] as? [String: [[String: Any]]] {
            print("  Environment categories: \(envs.keys.joined(separator: ", "))")
        }
    }
    
} else {
    print("❌ Failed to load shot file")
}