import SwiftUI

// MARK: - Plate Detail Editor
struct PlateDetailEditor: View {
    let plateId: String
    let plateType: PlateType
    @ObservedObject var filmManager: FilmManager
    @State private var editedName: String = ""
    @State private var editedDescription: String = ""
    @State private var editedShotRange: String = ""
    @State private var editedCategory: String = ""
    @State private var hasChanges: Bool = false
    
    var currentPlate: (name: String, description: String, shotRange: String, category: String, isMain: Bool)? {
        if plateType == .character {
            if let plate = filmManager.plateManager.characterPlates.first(where: { $0.plateId == plateId }) {
                return (plate.name, plate.description, plate.shotRange, plate.character, plate.isMainPlate)
            }
        } else {
            if let plate = filmManager.plateManager.environmentalPlates.first(where: { $0.plateId == plateId }) {
                return (plate.name, plate.description, "", plate.category, false)
            }
        }
        return nil
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(plateId)
                            .font(.system(.title2, design: .monospaced))
                            .fontWeight(.bold)
                        
                        if let plate = currentPlate, plate.isMain {
                            Label("Main Plate", systemImage: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.yellow.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        if hasChanges {
                            Button("Save Changes") {
                                saveChanges()
                            }
                            .buttonStyle(BorderedProminentButtonStyle())
                            
                            Button("Discard") {
                                loadPlateData()
                                hasChanges = false
                            }
                            .buttonStyle(BorderedButtonStyle())
                        }
                    }
                    
                    if let plate = currentPlate {
                        Text(plate.category.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                
                // Editable fields
                VStack(alignment: .leading, spacing: 16) {
                    // Name field
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Name", systemImage: "textformat")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        TextField("Plate name...", text: $editedName, onEditingChanged: { _ in
                            checkForChanges()
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Category field (for environmental plates)
                    if plateType == .environment {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Category", systemImage: "folder")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            TextField("Category...", text: $editedCategory, onEditingChanged: { _ in
                                checkForChanges()
                            })
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    // Shot range field (for character plates)
                    if plateType == .character {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Shot Range", systemImage: "film")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            TextField("Shot range...", text: $editedShotRange, onEditingChanged: { _ in
                                checkForChanges()
                            })
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    // Description field
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Description", systemImage: "text.alignleft")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $editedDescription)
                            .font(.system(.body))
                            .frame(minHeight: 200)
                            .padding(8)
                            .background(Color.gray.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .onChange(of: editedDescription) { _ in
                                checkForChanges()
                            }
                    }
                    
                    // Specializations (for main character plates)
                    if plateType == .character,
                       let plate = filmManager.plateManager.characterPlates.first(where: { $0.plateId == plateId }),
                       plate.isMainPlate && !plate.specializations.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Specializations", systemImage: "star.lefthalf.fill")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(plate.specializations, id: \.plateId) { spec in
                                    HStack {
                                        Text(spec.plateId)
                                            .font(.system(.caption, design: .monospaced))
                                            .fontWeight(.medium)
                                        
                                        Text(spec.name)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                    }
                                    .padding(8)
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(4)
                                }
                            }
                        }
                    }
                    
                    // Usage in shots
                    PlateUsageView(
                        plateId: plateId,
                        filmManager: filmManager
                    )
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            loadPlateData()
        }
        .onChange(of: plateId) { _ in
            loadPlateData()
        }
    }
    
    private func loadPlateData() {
        if let plate = currentPlate {
            editedName = plate.name
            editedDescription = plate.description
            editedShotRange = plate.shotRange
            editedCategory = plate.category
            hasChanges = false
        }
    }
    
    private func checkForChanges() {
        if let plate = currentPlate {
            hasChanges = editedName != plate.name ||
                        editedDescription != plate.description ||
                        editedShotRange != plate.shotRange ||
                        editedCategory != plate.category
        }
    }
    
    private func saveChanges() {
        // Update the plate in the manager
        if plateType == .character {
            if let index = filmManager.plateManager.characterPlates.firstIndex(where: { $0.plateId == plateId }) {
                var plate = filmManager.plateManager.characterPlates[index]
                plate.name = editedName
                plate.description = editedDescription
                plate.shotRange = editedShotRange
                filmManager.plateManager.characterPlates[index] = plate
            }
        } else {
            if let index = filmManager.plateManager.environmentalPlates.firstIndex(where: { $0.plateId == plateId }) {
                var plate = filmManager.plateManager.environmentalPlates[index]
                plate.name = editedName
                plate.description = editedDescription
                plate.category = editedCategory
                filmManager.plateManager.environmentalPlates[index] = plate
            }
        }
        
        filmManager.plateManager.objectWillChange.send()
        hasChanges = false
    }
}

// MARK: - Plate Usage View
struct PlateUsageView: View {
    let plateId: String
    @ObservedObject var filmManager: FilmManager
    
    var shotsUsingPlate: [FilmShot] {
        filmManager.shots.filter { shot in
            shot.promptVariants.contains { variant in
                // Check if plate is in recommended or selected plates
                if let charPlates = variant.recommendedPlates["characters"] as? [String: String] {
                    if charPlates.values.contains(plateId) { return true }
                }
                if let envPlates = variant.recommendedPlates["environment"] as? [String: String] {
                    if envPlates.values.contains(plateId) { return true }
                }
                if let charPlates = variant.selectedPlates["characters"] as? [String: String] {
                    if charPlates.values.contains(plateId) { return true }
                }
                if let envPlates = variant.selectedPlates["environment"] as? [String: String] {
                    if envPlates.values.contains(plateId) { return true }
                }
                return false
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Used in \(shotsUsingPlate.count) shots", systemImage: "film.stack")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            if !shotsUsingPlate.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(shotsUsingPlate.sorted(by: { $0.id < $1.id }), id: \.id) { shot in
                            VStack(spacing: 4) {
                                Text(shot.id)
                                    .font(.system(.caption, design: .monospaced))
                                    .fontWeight(.medium)
                                
                                Text(shot.title)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
                .frame(height: 50)
            }
        }
    }
}