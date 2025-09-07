#!/usr/bin/env swift

import Foundation

// Simulate the UI logic for checking character selection
func isCharacterSelected(_ character: String, in selectedPlates: [String: Any]) -> Bool {
    if let charPlates = selectedPlates["characters"] as? [String: String] {
        return charPlates[character.lowercased()] != nil
    }
    return false
}

func getSelectedPlateForCharacter(_ character: String, in selectedPlates: [String: Any]) -> String? {
    if let charPlates = selectedPlates["characters"] as? [String: String] {
        return charPlates[character.lowercased()]
    }
    return nil
}

// Test with shot 49a data
let selectedPlates: [String: Any] = [
    "characters": [
        "magnus": "MAGNUS-POSSESSOR",
        "sigrid": "SIGRID-CORNERED"
    ],
    "environment": [
        "interior": "BADSTOFA-CLIFF"
    ]
]

print("Testing UI Selection Logic")
print(String(repeating: "=", count: 40))

// Test Magnus (should be selected)
let magnusSelected = isCharacterSelected("Magnus", in: selectedPlates)
let magnusPlate = getSelectedPlateForCharacter("Magnus", in: selectedPlates)
print("Magnus:")
print("  Selected: \(magnusSelected) ✅")
print("  Plate: \(magnusPlate ?? "none")")

// Test Sigrid (should be selected)
let sigridSelected = isCharacterSelected("Sigrid", in: selectedPlates)
let sigridPlate = getSelectedPlateForCharacter("Sigrid", in: selectedPlates)
print("\nSigrid:")
print("  Selected: \(sigridSelected) ✅")
print("  Plate: \(sigridPlate ?? "none")")

// Test Gudrun (should NOT be selected)
let gudrunSelected = isCharacterSelected("Gudrun", in: selectedPlates)
let gudrunPlate = getSelectedPlateForCharacter("Gudrun", in: selectedPlates)
print("\nGudrun:")
print("  Selected: \(gudrunSelected) ❌")
print("  Plate: \(gudrunPlate ?? "none")")

print("\n✅ UI should now show:")
print("  - Magnus with minus button and MAGNUS-POSSESSOR selected")
print("  - Sigrid with minus button and SIGRID-CORNERED selected")
print("  - Gudrun with plus button (not selected)")