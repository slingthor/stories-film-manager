#!/usr/bin/env swift

import Foundation

// Script to update DataModels.swift to handle the new plate structure
// where selected_plates is an array of plate IDs

let dataModelsPath = "/Users/ingthor/Documents/stories/App/App/FilmManager/DataModels.swift"

// Read the current file
guard let currentContent = try? String(contentsOfFile: dataModelsPath) else {
    print("Failed to read DataModels.swift")
    exit(1)
}

// Find the section where we load plates (around line 1740)
let lines = currentContent.components(separatedBy: "\n")
var updatedLines: [String] = []
var inPlateLoadingSection = false
var bracketCount = 0

for (index, line) in lines.enumerated() {
    // Look for the plate loading section
    if line.contains("// Load plate information") {
        inPlateLoadingSection = true
        updatedLines.append(line)
        
        // Insert new loading code
        updatedLines.append("""
            // Handle new structure where selected_plates is an array of plate IDs
            if let selectedPlatesArray = variant["selected_plates"] as? [String] {
                // This is the new structure - just an array of plate IDs
                promptVariant.selectedPlateIds = selectedPlatesArray
                
                // For backward compatibility, set the old single plate fields
                // by finding the first character and environment plates
                for plateId in selectedPlatesArray {
                    // Query the plate managers to determine type
                    if let charPlate = self.plateManager.getCharacterPlate(by: plateId) {
                        if promptVariant.selectedCharacterPlateId == nil {
                            promptVariant.selectedCharacterPlateId = plateId
                        }
                    } else if let envPlate = self.plateManager.getEnvironmentPlate(by: plateId) {
                        if promptVariant.selectedEnvironmentPlateId == nil {
                            promptVariant.selectedEnvironmentPlateId = plateId
                        }
                    }
                }
            } else if let selectedPlates = variant["selected_plates"] as? [String: Any] {
                // Handle old nested structure for backward compatibility
""")
        continue
    }
    
    // Skip the old plate loading code until we find the end
    if inPlateLoadingSection {
        // Count brackets to find the end of the section
        for char in line {
            if char == "{" { bracketCount += 1 }
            if char == "}" { bracketCount -= 1 }
        }
        
        // Check if we've reached the end of the plate loading section
        if line.contains("// Also check for the individual plate ID fields") {
            inPlateLoadingSection = false
            bracketCount = 0
        }
        
        if !inPlateLoadingSection {
            updatedLines.append(line)
        }
    } else {
        updatedLines.append(line)
    }
}

// Write the updated content
let updatedContent = updatedLines.joined(separator: "\n")

// Save to a new file first for safety
let outputPath = dataModelsPath + ".updated"
try? updatedContent.write(toFile: outputPath, atomically: true, encoding: .utf8)

print("Updated DataModels saved to: \(outputPath)")
print("Review the changes and then replace the original file")