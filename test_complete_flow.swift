#!/usr/bin/env swift

import Foundation

print("🔍 COMPLETE PLATE FLOW DIAGNOSTIC")
print(String(repeating: "=", count: 60))

// 1. Check plate index files exist
print("\n1️⃣ PLATE INDEX FILES:")
let charIndexPath = "/Users/ingthor/Documents/stories/appdata/json/5/plate_indices/character_plates.json"
let envIndexPath = "/Users/ingthor/Documents/stories/appdata/json/5/plate_indices/environmental_plates.json"

print("  Character plates: \(FileManager.default.fileExists(atPath: charIndexPath) ? "✅ EXISTS" : "❌ MISSING")")
print("  Environment plates: \(FileManager.default.fileExists(atPath: envIndexPath) ? "✅ EXISTS" : "❌ MISSING")")

// 2. Check if plates have is_master flag
print("\n2️⃣ MASTER PLATES IN INDEX:")
if let data = FileManager.default.contents(atPath: charIndexPath),
   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
   let plateIndex = json["plate_index"] as? [String: Any] {
    
    var masterPlates: [String] = []
    for (plateId, plateData) in plateIndex {
        if let plate = plateData as? [String: Any],
           let isMaster = plate["is_master"] as? Bool,
           isMaster {
            masterPlates.append(plateId)
        }
    }
    
    if masterPlates.isEmpty {
        print("  ❌ NO master plates found!")
    } else {
        print("  ✅ Found \(masterPlates.count) master plates:")
        for plate in masterPlates {
            print("     - \(plate)")
        }
    }
}

// 3. Check shot 49a has selected_plates
print("\n3️⃣ SHOT 49a SELECTED PLATES:")
let shotPath = "/Users/ingthor/Documents/stories/appdata/json/5/shots/json/shot_49a_main_MAGNÃšS_REDIRECTS_RAGE_-_THE_INSPECTION_BEGINS_6_SECONDS.json"

if let data = FileManager.default.contents(atPath: shotPath),
   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
   let variants = json["prompt_variants"] as? [[String: Any]],
   let firstVariant = variants.first {
    
    if let selectedPlates = firstVariant["selected_plates"] as? [String: Any] {
        print("  ✅ Has selected_plates:")
        
        if let chars = selectedPlates["characters"] as? [String: String] {
            print("     Characters:")
            for (char, plateId) in chars {
                print("       - \(char): \(plateId)")
            }
        }
        
        if let envs = selectedPlates["environment"] as? [String: String] {
            print("     Environment:")
            for (env, plateId) in envs {
                print("       - \(env): \(plateId)")
            }
        }
    } else {
        print("  ❌ No selected_plates")
    }
}

// 4. Simulate the UI's plate selection logic
print("\n4️⃣ UI SELECTION LOGIC TEST:")

// Helper function matching the UI
func isCharacterSelected(_ character: String, selectedPlates: [String: Any]) -> Bool {
    if let charPlates = selectedPlates["characters"] as? [String: String] {
        return charPlates[character.lowercased()] != nil
    }
    return false
}

// Test with shot data
if let data = FileManager.default.contents(atPath: shotPath),
   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
   let variants = json["prompt_variants"] as? [[String: Any]],
   let firstVariant = variants.first,
   let selectedPlates = firstVariant["selected_plates"] as? [String: Any] {
    
    let characters = ["Magnus", "Sigrid", "Gudrun", "Jon", "Lilja"]
    
    for char in characters {
        let isSelected = isCharacterSelected(char, selectedPlates: selectedPlates)
        print("  \(char): \(isSelected ? "✅ SELECTED" : "❌ NOT SELECTED")")
    }
}

// 5. Check AppDataManager paths
print("\n5️⃣ APPDATAMANAGER PATHS:")
print("  Character plate index would be at:")
print("    /Users/ingthor/Documents/stories/appdata/json/5/plate_indices/character_plates.json")
print("  This file exists: \(FileManager.default.fileExists(atPath: charIndexPath) ? "✅" : "❌")")

// 6. Check if PlateManager would find the plates
print("\n6️⃣ PLATEMANAGER SIMULATION:")
if let data = FileManager.default.contents(atPath: charIndexPath),
   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
   let plateIndex = json["plate_index"] as? [String: Any] {
    
    // Simulate grouping by character
    var platesByCharacter: [String: Int] = [:]
    
    for (_, plateData) in plateIndex {
        if let plate = plateData as? [String: Any],
           let character = plate["character"] as? String {
            let charKey = character.lowercased()
            platesByCharacter[charKey] = (platesByCharacter[charKey] ?? 0) + 1
        }
    }
    
    print("  Plates grouped by character:")
    for (char, count) in platesByCharacter {
        print("    - \(char): \(count) plates")
    }
}

print("\n" + String(repeating: "=", count: 60))
print("🎯 DIAGNOSIS COMPLETE")
print("\nIf all checks pass but UI doesn't work, the issue is likely:")
print("1. PlateManager not being initialized properly")
print("2. mainCharacterPlates array is empty") 
print("3. UI not refreshing when shot changes")
print("4. Binding/ObservableObject not updating")