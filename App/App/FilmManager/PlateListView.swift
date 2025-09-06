import SwiftUI

// MARK: - Plate List View (for tabbed area)
struct PlateListView: View {
    @ObservedObject var filmManager: FilmManager
    @Binding var selectedPlateId: String?
    @Binding var selectedPlateType: PlateType
    @State private var plateTypeFilter: PlateType = .character
    @State private var searchText: String = ""
    @State private var selectedCharacter: String? = nil
    @State private var expandedMainPlate: String? = nil
    
    var availableCharacters: [String] {
        Array(Set(filmManager.plateManager.mainCharacterPlates.map { $0.character })).sorted()
    }
    
    var filteredCharacterPlates: [CharacterPlate] {
        if let selectedChar = selectedCharacter {
            // Show main plate and its specializations for selected character
            return filmManager.plateManager.characterPlates
                .filter { plate in
                    plate.character.lowercased() == selectedChar.lowercased() &&
                    (searchText.isEmpty || 
                     plate.name.localizedCaseInsensitiveContains(searchText) ||
                     plate.description.localizedCaseInsensitiveContains(searchText) ||
                     plate.plateId.localizedCaseInsensitiveContains(searchText))
                }
                .sorted { p1, p2 in
                    // Main plates first, then specializations
                    if p1.isMainPlate != p2.isMainPlate {
                        return p1.isMainPlate
                    }
                    return p1.plateId < p2.plateId
                }
        } else {
            // Show only main plates when no character selected
            return filmManager.plateManager.mainCharacterPlates
                .filter { searchText.isEmpty || 
                         $0.name.localizedCaseInsensitiveContains(searchText) ||
                         $0.description.localizedCaseInsensitiveContains(searchText) ||
                         $0.character.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.character < $1.character }
        }
    }
    
    var filteredEnvironmentalPlates: [(id: String, name: String, description: String, category: String)] {
        filmManager.plateManager.environmentalPlates
            .filter { searchText.isEmpty || 
                     $0.name.localizedCaseInsensitiveContains(searchText) ||
                     $0.description.localizedCaseInsensitiveContains(searchText) ||
                     $0.category.localizedCaseInsensitiveContains(searchText) }
            .map { (id: $0.plateId, name: $0.name, description: $0.description, category: $0.category) }
    }
    
    var groupedEnvironmentalPlates: [String: [(id: String, name: String, description: String, category: String)]] {
        Dictionary(grouping: filteredEnvironmentalPlates) { $0.category }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    Label("Plates", systemImage: "rectangle.stack")
                        .font(.headline)
                    Spacer()
                    Text("\(filteredPlates.count) plates")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Type selector
                Picker("Type", selection: $plateTypeFilter) {
                    ForEach(PlateType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: plateTypeFilter) { newValue in
                    selectedPlateType = newValue
                    selectedPlateId = nil // Clear selection when switching types
                }
                
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search plates...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            
            Divider()
            
            // Character selector for character plates
            if plateTypeFilter == .character && !availableCharacters.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Character")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableCharacters, id: \.self) { character in
                                Button(action: {
                                    selectedCharacter = selectedCharacter == character ? nil : character
                                    selectedPlateId = nil
                                }) {
                                    Text(character.capitalized)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedCharacter == character ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundColor(selectedCharacter == character ? .white : .primary)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.05))
                
                Divider()
            }
            
            // Plate list
            ScrollView {
                if plateTypeFilter == .character {
                    // Character plates display
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredCharacterPlates, id: \.id) { plate in
                            CharacterPlateRow(
                                plate: plate,
                                isSelected: selectedPlateId == plate.plateId,
                                isExpanded: expandedMainPlate == plate.plateId,
                                showSpecializationIndicator: plate.isMainPlate && !plate.specializations.isEmpty,
                                indentLevel: plate.isMainPlate ? 0 : 1,
                                onSelect: {
                                    selectedPlateId = plate.plateId
                                    selectedPlateType = plateTypeFilter
                                },
                                onToggleExpand: {
                                    if plate.isMainPlate && !plate.specializations.isEmpty {
                                        expandedMainPlate = expandedMainPlate == plate.plateId ? nil : plate.plateId
                                    }
                                }
                            )
                            
                            // Show specializations if this main plate is expanded
                            if plate.isMainPlate && expandedMainPlate == plate.plateId {
                                ForEach(plate.specializations, id: \.plateId) { spec in
                                    SpecializationRow(
                                        specialization: spec,
                                        isSelected: selectedPlateId == spec.plateId,
                                        onSelect: {
                                            selectedPlateId = spec.plateId
                                            selectedPlateType = plateTypeFilter
                                        }
                                    )
                                }
                            }
                        }
                    }
                } else {
                    // Environmental plates display
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(groupedEnvironmentalPlates.keys.sorted(), id: \.self) { category in
                            // Category header
                            HStack {
                                Text(category.isEmpty ? "Uncategorized" : category.capitalized)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.08))
                            
                            // Plates in category
                            ForEach(groupedEnvironmentalPlates[category] ?? [], id: \.id) { plate in
                                PlateListRow(
                                    plateId: plate.id,
                                    plateName: plate.name,
                                    plateDescription: plate.description,
                                    isSelected: selectedPlateId == plate.id,
                                    onSelect: {
                                        selectedPlateId = plate.id
                                        selectedPlateType = plateTypeFilter
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Plate List Row
struct PlateListRow: View {
    let plateId: String
    let plateName: String
    let plateDescription: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plateId)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(plateName)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Character Plate Row
struct CharacterPlateRow: View {
    let plate: CharacterPlate
    let isSelected: Bool
    let isExpanded: Bool
    let showSpecializationIndicator: Bool
    let indentLevel: Int
    let onSelect: () -> Void
    let onToggleExpand: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                // Expansion indicator for main plates with specializations
                if showSpecializationIndicator {
                    Button(action: onToggleExpand) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                            .frame(width: 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // Indent for alignment
                    Color.clear
                        .frame(width: 16 + CGFloat(indentLevel * 20))
                }
                
                // Main plate indicator
                if plate.isMainPlate {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(plate.plateId)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(plate.name)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Specialization Row
struct SpecializationRow: View {
    let specialization: CharacterPlateSpecialization
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                // Indentation for specializations
                Color.clear
                    .frame(width: 36)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(specialization.plateId)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(specialization.name)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.05))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

