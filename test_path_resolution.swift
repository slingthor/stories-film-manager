#!/usr/bin/env swift

import Foundation

// Simulate AppDataManager path resolution
let jsonBasePath = "/Users/ingthor/Documents/stories/appdata/json"
let fm = FileManager.default

// Find highest version
var highestVersion = 0
if let contents = try? fm.contentsOfDirectory(atPath: jsonBasePath) {
    for item in contents {
        if let version = Int(item) {
            highestVersion = max(highestVersion, version)
        }
    }
}

print("Highest version found: \(highestVersion)")

let currentVersionPath = "\(jsonBasePath)/\(highestVersion)"
print("Current version path: \(currentVersionPath)")

let characterPlateIndexPath = "\(currentVersionPath)/plate_indices/character_plates.json"
print("Character plate index path: \(characterPlateIndexPath)")
print("File exists: \(fm.fileExists(atPath: characterPlateIndexPath))")

// Also check the old path it might be looking for
let oldPath = "\(currentVersionPath)/character_plates_index.json"
print("\nOld path (incorrect): \(oldPath)")
print("File exists: \(fm.fileExists(atPath: oldPath))")