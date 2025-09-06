import SwiftUI
import Combine

// MARK: - Enhanced Plate Management View
struct PlateManagementViewNew: View {
    @ObservedObject var filmManager: FilmManager
    @State private var selectedPlateId: String? = nil
    @State private var plateTypeFilter: PlateType = .character
    @State private var searchText: String = ""
    
    enum PlateType: String, CaseIterable {
        case character = "Characters"
        case environment = "Environments"
    }
    
    var body: some View {
        HSplitView {
            // Left panel - Plate list
            PlateListPanel(
                filmManager: filmManager,
                selectedPlateId: $selectedPlateId,
                plateTypeFilter: $plateTypeFilter,
                searchText: $searchText
            )
            .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
            
            // Right panel - Plate detail editor
            if let plateId = selectedPlateId {
                PlateDetailEditor(
                    plateId: plateId,
                    plateType: plateTypeFilter,
                    filmManager: filmManager
                )
                .frame(minWidth: 500)
            } else {
                VStack {
                    Spacer()
                    Text("Select a plate to view details")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.05))
            }
        }
    }
}

// MARK: - Plate List Panel
struct PlateListPanel: View {
    @ObservedObject var filmManager: FilmManager
    @Binding var selectedPlateId: String?
    @Binding var plateTypeFilter: PlateManagementViewNew.PlateType
    @Binding var searchText: String
    
    var filteredPlates: [(id: String, name: String, description: String, category: String)] {
        if plateTypeFilter == .character {
            let plates = filmManager.plateManager.characterPlates
                .filter { searchText.isEmpty || 
                         $0.name.localizedCaseInsensitiveContains(searchText) ||
                         $0.description.localizedCaseInsensitiveContains(searchText) ||
                         $0.character.localizedCaseInsensitiveContains(searchText) }
                .map { (id: $0.plateId, name: $0.name, description: $0.description, category: $0.character) }
            return plates
        } else {
            let plates = filmManager.plateManager.environmentalPlates
                .filter { searchText.isEmpty || 
                         $0.name.localizedCaseInsensitiveContains(searchText) ||
                         $0.description.localizedCaseInsensitiveContains(searchText) ||
                         $0.category.localizedCaseInsensitiveContains(searchText) }
                .map { (id: $0.plateId, name: $0.name, description: $0.description, category: $0.category) }
            return plates
        }
    }
    
    var groupedPlates: [String: [(id: String, name: String, description: String, category: String)]] {
        Dictionary(grouping: filteredPlates) { $0.category }
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
                    ForEach(PlateManagementViewNew.PlateType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
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
            
            // Plate list
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(groupedPlates.keys.sorted(), id: \.self) { category in
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
                        ForEach(groupedPlates[category] ?? [], id: \.id) { plate in
                            PlateListItem(
                                plateId: plate.id,
                                plateName: plate.name,
                                plateDescription: plate.description,
                                isSelected: selectedPlateId == plate.id,
                                onSelect: {
                                    selectedPlateId = plate.id
                                }
                            )
                        }
                    }
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Plate List Item
struct PlateListItem: View {
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

// MARK: - Plate Detail Editor
struct PlateDetailEditor: View {
    let plateId: String
    let plateType: PlateManagementViewNew.PlateType
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


// Preview
struct PlateManagementViewNew_Previews: PreviewProvider {
    static var previews: some View {
        PlateManagementViewNew(filmManager: FilmManager())
            .frame(width: 1000, height: 700)
    }
}