#!/usr/bin/env swift

import Foundation

// Shot data structure
struct Shot {
    let id: String
    let sequenceType: String
}

// Extract numeric value from ID
func extractNumericFromId(_ id: String) -> Double {
    // Handle IDs like "-1", "0a", "0b", "1", "39.5", "16p", etc.
    
    // Check for negative numbers first
    if id.hasPrefix("-") {
        let numericString = id.dropFirst().replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        var value = -(Double(numericString) ?? 0)
        // Add letter offset for suffixes - negative numbers go in reverse order
        if id.contains("a") { value -= 0.1 }
        else if id.contains("b") { value -= 0.2 }
        else if id.contains("c") { value -= 0.3 }
        else if id.contains("d") { value -= 0.4 }
        return value
    }
    
    // Extract the numeric part more carefully
    let numericPattern = try! NSRegularExpression(pattern: "(\\d+(?:\\.\\d+)?)", options: [])
    let nsString = id as NSString
    let matches = numericPattern.matches(in: id, options: [], range: NSRange(location: 0, length: nsString.length))
    
    var baseValue: Double = 0
    if let firstMatch = matches.first {
        let numericString = nsString.substring(with: firstMatch.range)
        baseValue = Double(numericString) ?? 0
    }
    
    // Handle letter suffixes with proper decimal offset
    if id.hasSuffix("a") { baseValue += 0.1 }
    else if id.hasSuffix("b") { baseValue += 0.2 }
    else if id.hasSuffix("c") { baseValue += 0.3 }
    else if id.hasSuffix("d") { baseValue += 0.4 }
    else if id.contains("p") { baseValue += 0.5 } // Handle "16p" style IDs
    
    return baseValue
}

// Create test shots based on actual data
var shots: [Shot] = []

// Prologue shots
let prologueShots = ["0a", "0b", "1a", "1b", "2a", "2b", "3a", "3b", "4a", "4b", "5a", "5b", "6a", "6b", "7a", "20", "21", "22", "23"]
for id in prologueShots {
    shots.append(Shot(id: id, sequenceType: "prologue"))
}

// Main story shots (including shot 7)
let mainShots = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19",
                 "22b", "23a", "23b", "23c", "24", "24a", "24b", "24c", "24d", "25", "26", "27", "28", "29", "30",
                 "31", "32", "33", "34", "35a", "35b", "35c", "36", "37", "38a", "38b", "39", "40", "41", "42a", "42b",
                 "42c", "43a", "43b", "43c", "44a", "44b", "44c", "45a", "45b", "45c", "46a", "46b", "46c", "47a",
                 "47b", "47c", "48", "49a", "49b", "49c", "50a", "50b", "50c", "50d", "51a", "51b", "51c", "52a",
                 "52b", "52c", "53a", "53b", "53c", "54a", "54b", "54c", "55a", "55b", "55c", "56a", "56b", "56c",
                 "57a", "57b", "57c", "58a", "58b", "58c", "59a", "59b", "59c", "60a", "60b", "60c", "61a", "61b",
                 "61c", "62a", "62b", "63"]
for id in mainShots {
    shots.append(Shot(id: id, sequenceType: "main_story"))
}

// Sort using the same logic as DataModels.swift
shots.sort { shot1, shot2 in
    // First sort by sequence type (prologue before main)
    if shot1.sequenceType != shot2.sequenceType {
        // Check if either is prologue
        if shot1.sequenceType == "prologue" { return true }
        if shot2.sequenceType == "prologue" { return false }
        // For any other sequence types, use alphabetical order
        return shot1.sequenceType < shot2.sequenceType
    }
    // Within the same sequence type, sort by numeric ID
    let id1 = extractNumericFromId(shot1.id)
    let id2 = extractNumericFromId(shot2.id)
    return id1 < id2
}

// Print the sorted order
print("\n=================== SHOT ORDER: ===================")
for (index, shot) in shots.enumerated() {
    let numericValue = extractNumericFromId(shot.id)
    print("   \(index + 1). Shot \(shot.id) (\(shot.sequenceType)) -> numeric: \(numericValue)")
}
print("====================================================\n")

// Highlight where shot 7 appears
if let index = shots.firstIndex(where: { $0.id == "7" }) {
    print("⚠️  Shot 7 appears at position \(index + 1) in the sorted list")
    print("   Shots before it: \(shots[max(0, index-2)..<index].map { $0.id }.joined(separator: ", "))")
    print("   Shots after it: \(shots[min(index+1, shots.count)..<min(index+3, shots.count)].map { $0.id }.joined(separator: ", "))")
}