import SwiftUI
import Combine

// MARK: - Enhanced Plate Management View
struct PlateManagementViewNew: View {
    @ObservedObject var filmManager: FilmManager
    @State private var selectedPlateId: String? = nil
    @State private var plateTypeFilter: PlateType = .character
    @State private var searchText: String = ""
    
    
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
    @Binding var plateTypeFilter: PlateType
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
                    ForEach(PlateType.allCases, id: \.self) { type in
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



// Preview
struct PlateManagementViewNew_Previews: PreviewProvider {
    static var previews: some View {
        PlateManagementViewNew(filmManager: FilmManager())
            .frame(width: 1000, height: 700)
    }
}