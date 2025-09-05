import SwiftUI
import Combine

// MARK: - Plate Management View
struct PlateManagementView: View {
    @ObservedObject var filmManager: FilmManager
    @State private var showingPlateReader = false
    @State private var plateToRead: String = ""
    @State private var plateTypeFilter: PlateType = .character
    
    enum PlateType: String, CaseIterable {
        case character = "Characters"
        case environment = "Environments"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with type selector
            PlateTypeSelector(
                plateTypeFilter: $plateTypeFilter
            )
            .padding()
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // Plate browser panel
            PlateBrowserPanel(
                filmManager: filmManager,
                plateTypeFilter: plateTypeFilter,
                selectedShot: filmManager.selectedShot,
                onReadPlate: { plateId in
                    plateToRead = plateId
                    showingPlateReader = true
                }
            )
        }
        .sheet(isPresented: $showingPlateReader) {
            PlateReaderView(
                plateId: plateToRead,
                plateManager: filmManager.plateManager
            )
        }
    }
}

// MARK: - Plate Type Selector
struct PlateTypeSelector: View {
    @Binding var plateTypeFilter: PlateManagementView.PlateType
    
    var body: some View {
        HStack {
            Label("Plate Browser", systemImage: "rectangle.stack")
                .font(.headline)
            
            Spacer()
            
            // Type picker
            Picker("Plate Type", selection: $plateTypeFilter) {
                ForEach(PlateManagementView.PlateType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 250)
        }
    }
}

// MARK: - Plate Browser Panel
struct PlateBrowserPanel: View {
    @ObservedObject var filmManager: FilmManager
    let plateTypeFilter: PlateManagementView.PlateType
    let selectedShot: FilmShot?
    let onReadPlate: (String) -> Void
    
    var charactersByName: [String: [CharacterPlate]] {
        Dictionary(grouping: filmManager.plateManager.characterPlates) { $0.character }
    }
    
    var environmentsByCategory: [String: [EnvironmentalPlate]] {
        Dictionary(grouping: filmManager.plateManager.environmentalPlates) { $0.category }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Show current shot's plate selections if available
                if let shot = selectedShot,
                   let activeVariant = shot.promptVariants.first(where: { $0.isActive }) ?? shot.promptVariants.first {
                    CurrentShotPlatesView(
                        shot: shot,
                        variant: activeVariant,
                        plateManager: filmManager.plateManager
                    )
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.vertical, 8)
                }
                
                // Character Plates Section
                if plateTypeFilter == .character {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Available Character Plates", systemImage: "person.2")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(charactersByName.keys.sorted(), id: \.self) { character in
                            if let plates = charactersByName[character] {
                                CharacterGroupView(
                                    character: character,
                                    plates: plates,
                                    selectedShot: selectedShot,
                                    filmManager: filmManager,
                                    onReadPlate: onReadPlate
                                )
                            }
                        }
                    }
                }
                
                // Environment Plates Section
                if plateTypeFilter == .environment {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Available Environmental Plates", systemImage: "mountain.2")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(environmentsByCategory.keys.sorted(), id: \.self) { category in
                            if let plates = environmentsByCategory[category] {
                                EnvironmentGroupView(
                                    category: category,
                                    plates: plates,
                                    selectedShot: selectedShot,
                                    filmManager: filmManager,
                                    onReadPlate: onReadPlate
                                )
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Current Shot Plates View
struct CurrentShotPlatesView: View {
    let shot: FilmShot
    let variant: PromptVariant
    let plateManager: PlateManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Current Selection for Shot \(shot.id)", systemImage: "checkmark.circle")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                if let charPlateId = variant.selectedCharacterPlateId,
                   let plate = plateManager.characterPlates.first(where: { $0.plateId == charPlateId }) {
                    PlateTag(text: "\(plate.character): \(plate.name)", color: .blue)
                } else {
                    Text("No character plate selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let envPlateId = variant.selectedEnvironmentPlateId,
                   let plate = plateManager.environmentalPlates.first(where: { $0.plateId == envPlateId }) {
                    PlateTag(text: "\(plate.category): \(plate.name)", color: .green)
                } else {
                    Text("No environment plate selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Character Group View
struct CharacterGroupView: View {
    let character: String
    let plates: [CharacterPlate]
    let selectedShot: FilmShot?
    @ObservedObject var filmManager: FilmManager
    let onReadPlate: (String) -> Void
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Character header
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                    
                    Text(character.uppercased())
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.blue)
                    
                    Text("(\(plates.count) plates)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded plate list
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(plates) { plate in
                        SimplePlateRow(
                            plate: plate,
                            isSelected: isPlateSelectedInShot(plate.plateId),
                            onSelect: {
                                selectPlateForShot(plate.plateId)
                            },
                            onRead: { onReadPlate(plate.plateId) }
                        )
                    }
                }
                .padding(.leading, 24)
            }
        }
        .background(Color.gray.opacity(0.02))
        .cornerRadius(6)
    }
    
    private func isPlateSelectedInShot(_ plateId: String) -> Bool {
        guard let shot = selectedShot,
              let variant = shot.promptVariants.first(where: { $0.isActive }) ?? shot.promptVariants.first else {
            return false
        }
        return variant.selectedCharacterPlateId == plateId
    }
    
    private func selectPlateForShot(_ plateId: String) {
        guard let shot = selectedShot,
              let variant = shot.promptVariants.first(where: { $0.isActive }) ?? shot.promptVariants.first else {
            return
        }
        
        if variant.selectedCharacterPlateId == plateId {
            variant.selectedCharacterPlateId = nil
        } else {
            variant.selectedCharacterPlateId = plateId
        }
        shot.isDirty = true
        filmManager.objectWillChange.send()
    }
}

// MARK: - Environment Group View
struct EnvironmentGroupView: View {
    let category: String
    let plates: [EnvironmentalPlate]
    let selectedShot: FilmShot?
    @ObservedObject var filmManager: FilmManager
    let onReadPlate: (String) -> Void
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Category header
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                    
                    Text(category.uppercased())
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.green)
                    
                    Text("(\(plates.count) plates)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded plate list
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(plates) { plate in
                        SimpleEnvironmentPlateRow(
                            plate: plate,
                            isSelected: isPlateSelectedInShot(plate.plateId),
                            onSelect: {
                                selectPlateForShot(plate.plateId)
                            },
                            onRead: { onReadPlate(plate.plateId) }
                        )
                    }
                }
                .padding(.leading, 24)
            }
        }
        .background(Color.gray.opacity(0.02))
        .cornerRadius(6)
    }
    
    private func isPlateSelectedInShot(_ plateId: String) -> Bool {
        guard let shot = selectedShot,
              let variant = shot.promptVariants.first(where: { $0.isActive }) ?? shot.promptVariants.first else {
            return false
        }
        return variant.selectedEnvironmentPlateId == plateId
    }
    
    private func selectPlateForShot(_ plateId: String) {
        guard let shot = selectedShot,
              let variant = shot.promptVariants.first(where: { $0.isActive }) ?? shot.promptVariants.first else {
            return
        }
        
        if variant.selectedEnvironmentPlateId == plateId {
            variant.selectedEnvironmentPlateId = nil
        } else {
            variant.selectedEnvironmentPlateId = plateId
        }
        shot.isDirty = true
        filmManager.objectWillChange.send()
    }
}

// MARK: - Simple Plate Row
struct SimplePlateRow: View {
    let plate: CharacterPlate
    let isSelected: Bool
    let onSelect: () -> Void
    let onRead: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onSelect) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.system(size: 16))
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(plate.name)
                    .font(.system(size: 12, weight: .medium))
                
                Text(plate.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if !plate.shotRange.isEmpty {
                    Text(plate.shotRange)
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            Button(action: onRead) {
                Text("Read")
                    .font(.caption2)
            }
            .buttonStyle(BorderedButtonStyle())
            .controlSize(.small)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(4)
    }
}

// MARK: - Simple Environment Plate Row
struct SimpleEnvironmentPlateRow: View {
    let plate: EnvironmentalPlate
    let isSelected: Bool
    let onSelect: () -> Void
    let onRead: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onSelect) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
                    .font(.system(size: 16))
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(plate.name)
                    .font(.system(size: 12, weight: .medium))
                
                Text(plate.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if !plate.atmosphere.isEmpty {
                    Text(plate.atmosphere)
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Button(action: onRead) {
                Text("Read")
                    .font(.caption2)
            }
            .buttonStyle(BorderedButtonStyle())
            .controlSize(.small)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isSelected ? Color.green.opacity(0.1) : Color.clear)
        .cornerRadius(4)
    }
}


// MARK: - Plate Tag
struct PlateTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

// MARK: - Plate Reader View
struct PlateReaderView: View {
    let plateId: String
    let plateManager: PlateManager
    @Environment(\.dismiss) var dismiss
    
    var plateContent: (title: String, content: String) {
        if let charPlate = plateManager.characterPlates.first(where: { $0.plateId == plateId }) {
            return (
                title: "\(charPlate.character) - \(charPlate.name)",
                content: """
                Character: \(charPlate.character)
                Plate Name: \(charPlate.name)
                Shot Range: \(charPlate.shotRange)
                
                Description:
                \(charPlate.description)
                """
            )
        } else if let envPlate = plateManager.environmentalPlates.first(where: { $0.plateId == plateId }) {
            return (
                title: "\(envPlate.category) - \(envPlate.name)",
                content: """
                Category: \(envPlate.category)
                Plate Name: \(envPlate.name)
                
                Description:
                \(envPlate.description)
                
                Atmosphere:
                \(envPlate.atmosphere)
                """
            )
        }
        
        return (title: "Unknown Plate", content: "Plate not found")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(plateContent.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // Content
            ScrollView {
                Text(plateContent.content)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: 600, height: 400)
    }
}