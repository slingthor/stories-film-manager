#!/usr/bin/env swift

import Foundation

// Test the versioning system
let baseAppDataPath = "/Users/ingthor/Documents/stories/appdata"
let jsonBasePath = "\(baseAppDataPath)/json"
let resourcesPath = "\(baseAppDataPath)/resources"

// Create base directories
try? FileManager.default.createDirectory(
    atPath: jsonBasePath,
    withIntermediateDirectories: true,
    attributes: nil
)
try? FileManager.default.createDirectory(
    atPath: resourcesPath,
    withIntermediateDirectories: true,
    attributes: nil
)

// Find the highest numbered directory
var highestVersion = 0
if let contents = try? FileManager.default.contentsOfDirectory(atPath: jsonBasePath) {
    for item in contents {
        if let version = Int(item) {
            highestVersion = max(highestVersion, version)
        }
    }
}

print("Current highest version: \(highestVersion)")

// Check if version 1 exists, if not create it
if highestVersion == 0 {
    let version1Path = "\(jsonBasePath)/1"
    let shotsPath = "\(version1Path)/shots"
    
    try? FileManager.default.createDirectory(
        atPath: shotsPath,
        withIntermediateDirectories: true,
        attributes: nil
    )
    
    print("Created initial version directory: \(version1Path)")
    
    // Copy resource files from App Resources to version 1
    let resourceFiles = [
        "environmental_plates_index.json",
        "character_plates_index.json",
        "shot_plate_recommendations.json",
        "main_film_system.json"
    ]
    
    let sourcePath = "/Users/ingthor/Documents/stories/App/App/FilmManager/Resources"
    
    for file in resourceFiles {
        let source = "\(sourcePath)/\(file)"
        let dest = "\(version1Path)/\(file)"
        
        if FileManager.default.fileExists(atPath: source) {
            try? FileManager.default.copyItem(atPath: source, toPath: dest)
            print("Copied \(file) to version 1")
        } else {
            print("Warning: \(file) not found at \(source)")
        }
    }
    
    // Copy shot files
    let shotSourcePath = "\(sourcePath)/shots"
    if FileManager.default.fileExists(atPath: shotSourcePath) {
        if let shots = try? FileManager.default.contentsOfDirectory(atPath: shotSourcePath) {
            for shot in shots where shot.hasSuffix(".json") {
                let source = "\(shotSourcePath)/\(shot)"
                let dest = "\(shotsPath)/\(shot)"
                try? FileManager.default.copyItem(atPath: source, toPath: dest)
                print("Copied shot: \(shot)")
            }
        }
    }
    
    // Create build marker
    FileManager.default.createFile(
        atPath: "\(version1Path)/.build_marker",
        contents: nil,
        attributes: nil
    )
    
    print("\n✅ Version 1 created successfully!")
} else {
    print("Version \(highestVersion) already exists")
}

// List contents of the latest version
let latestPath = "\(jsonBasePath)/\(max(1, highestVersion))"
print("\nContents of \(latestPath):")
if let contents = try? FileManager.default.contentsOfDirectory(atPath: latestPath) {
    for item in contents {
        print("  - \(item)")
    }
}