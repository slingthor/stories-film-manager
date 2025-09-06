import SwiftUI
import Combine

struct ComprehensivePromptEditor: View {
    let shot: FilmShot?
    @ObservedObject var filmManager: FilmManager
    @State private var showingNewVariantDialog = false
    @State private var newVariantName = ""
    @State private var showingGeneratedPrompt = false
    @State private var generatedPrompt = ""
    @State private var showCharacterPlates = false
    @State private var showEnvironmentPlates = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let shot = shot {
                // Shot header with comprehensive info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("SHOT \(shot.id)")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // Aspect ratio picker
                        VStack(alignment: .trailing) {
                            Text("Aspect Ratio:")
                                .font(.caption)
                            Picker("Aspect", selection: Binding(
                                get: { shot.aspectRatio },
                                set: { shot.aspectRatio = $0; shot.isDirty = true }
                            )) {
                                Text("16:9").tag("16:9")
                                Text("1.85:1").tag("1.85:1")
                                Text("4:3").tag("4:3")
                                Text("1:1").tag("1:1")
                                Text("2.39:1").tag("2.39:1")
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 90)
                        }
                    }
                    
                    Text(shot.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Position: \(Int(shot.position))%")
                        Text("•")
                        Text("Duration: \(shot.duration)s")
                        Text("•")
                        Text("Sequence: \(shot.sequenceType)")
                        Text("•")
                        Text("Variants: \(shot.promptVariants.count)")
                        
                        Spacer()
                        
                        if shot.isDirty {
                            HStack {
                                Text("●")
                                    .foregroundColor(.red)
                                Text("Modified")
                            }
                            .font(.caption2)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                
                // Prompt variant tabs with enhanced controls
                HStack(spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(0..<shot.promptVariants.count, id: \.self) { index in
                                Button {
                                    shot.selectedPromptIndex = index
                                    shot.objectWillChange.send()
                                } label: {
                                    HStack {
                                        if shot.promptVariants[index].isActive {
                                            Text("★")
                                                .foregroundColor(.yellow)
                                                .font(.caption2)
                                        }
                                        Text(shot.promptVariants[index].name)
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(shot.selectedPromptIndex == index ? Color.blue : Color.gray.opacity(0.2))
                                )
                                .foregroundColor(shot.selectedPromptIndex == index ? .white : .primary)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Button {
                        showingNewVariantDialog = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    }
                    .help("Copy current prompt variant")
                    .padding(.horizontal)
                }
                .frame(height: 50)
                
                Divider()
                
                // Comprehensive prompt editing
                if shot.selectedPromptIndex < shot.promptVariants.count {
                    let prompt = shot.promptVariants[shot.selectedPromptIndex]
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Integrated Plate Selection
                            PlateSelectionSection(
                                variant: prompt,
                                plateManager: filmManager.plateManager,
                                showCharacterPlates: $showCharacterPlates,
                                showEnvironmentPlates: $showEnvironmentPlates,
                                onUpdate: { shot.isDirty = true }
                            )
                            
                            // All VEO3 prompt fields
                            Group {
                                VEOPromptField(
                                    title: "SUBJECT",
                                    content: Binding(
                                        get: { prompt.subject },
                                        set: { prompt.subject = $0; shot.isDirty = true }
                                    ),
                                    height: 100,
                                    helpText: "Main subject and visual elements"
                                )
                                
                                VEOPromptField(
                                    title: "ACTION", 
                                    content: Binding(
                                        get: { prompt.action },
                                        set: { prompt.action = $0; shot.isDirty = true }
                                    ),
                                    height: 140,
                                    helpText: "Movement, behavior, and sequence of events"
                                )
                                
                                VEOPromptField(
                                    title: "SCENE",
                                    content: Binding(
                                        get: { prompt.scene },
                                        set: { prompt.scene = $0; shot.isDirty = true }
                                    ),
                                    height: 80,
                                    helpText: "Setting, environment, and context"
                                )
                                
                                VEOPromptField(
                                    title: "STYLE",
                                    content: Binding(
                                        get: { prompt.style },
                                        set: { prompt.style = $0; shot.isDirty = true }
                                    ),
                                    height: 80,
                                    helpText: "Visual style and cinematography"
                                )
                                
                                VEOPromptField(
                                    title: "CAMERA POSITION",
                                    content: Binding(
                                        get: { prompt.cameraPosition },
                                        set: { prompt.cameraPosition = $0; shot.isDirty = true }
                                    ),
                                    height: 60,
                                    helpText: "Where the camera is positioned"
                                )
                                
                                VEOPromptField(
                                    title: "DIALOGUE",
                                    content: Binding(
                                        get: { prompt.dialogue },
                                        set: { prompt.dialogue = $0; shot.isDirty = true }
                                    ),
                                    height: 60,
                                    helpText: "Character speech and vocalizations"
                                )
                                
                                VEOPromptField(
                                    title: "NEGATIVE PROMPT",
                                    content: Binding(
                                        get: { prompt.negativePrompt },
                                        set: { prompt.negativePrompt = $0; shot.isDirty = true }
                                    ),
                                    height: 60,
                                    helpText: "Elements to avoid in generation"
                                )
                                
                                VEOPromptField(
                                    title: "PROGRESSIVE STATE",
                                    content: Binding(
                                        get: { prompt.progressiveState },
                                        set: { prompt.progressiveState = $0; shot.isDirty = true }
                                    ),
                                    height: 40,
                                    helpText: "Current state in narrative progression"
                                )
                            }
                            
                            // Action buttons
                            HStack(spacing: 12) {
                                Button("Generate Complete Prompt") {
                                    generatedPrompt = prompt.generateCompletePrompt(for: shot)
                                    showingGeneratedPrompt = true
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button(action: {
                                    if !prompt.isActive {
                                        shot.setActivePrompt(at: shot.selectedPromptIndex)
                                    }
                                }) {
                                    Label(prompt.isActive ? "Active" : "Set as Active", 
                                          systemImage: prompt.isActive ? "star.fill" : "star")
                                }
                                .buttonStyle(.bordered)
                                .disabled(prompt.isActive)
                                .foregroundColor(prompt.isActive ? .yellow : .primary)
                                
                                Button("Save Shot") {
                                    shot.isDirty = false
                                    print("💾 Saved shot \(shot.id)")
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                    }
                }
                
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    VStack {
                        Text("Select a shot to edit prompts")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Choose from the shot list to begin editing")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showingNewVariantDialog) {
            NewVariantDialog(
                baseName: shot?.promptVariants[shot?.selectedPromptIndex ?? 0].name ?? "",
                newVariantName: $newVariantName,
                onCancel: {
                    showingNewVariantDialog = false
                    newVariantName = ""
                },
                onCreate: {
                    if let shot = shot {
                        shot.copyPromptVariant(at: shot.selectedPromptIndex, newName: newVariantName.isEmpty ? nil : newVariantName)
                    }
                    showingNewVariantDialog = false
                    newVariantName = ""
                }
            )
        }
        .sheet(isPresented: $showingGeneratedPrompt) {
            GeneratedPromptViewer(
                prompt: generatedPrompt,
                shotId: shot?.id ?? "",
                onDismiss: { showingGeneratedPrompt = false }
            )
        }
    }
}

struct VEOPromptField: View {
    let title: String
    @Binding var content: String
    let height: CGFloat
    let helpText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(helpText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            TextEditor(text: $content)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .frame(height: height)
        }
    }
}

// MARK: - Plate Selection Section  
struct PlateSelectionSection: View {
    @ObservedObject var variant: PromptVariant
    let plateManager: PlateManager
    @Binding var showCharacterPlates: Bool
    @Binding var showEnvironmentPlates: Bool
    let onUpdate: () -> Void
    
    @State private var hoveredPlateId: String? = nil
    @State private var expandedCharacter: String? = nil
    @State private var specializationSearch: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PLATES")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Show recommended plates if available
            if !variant.recommendedPlates.isEmpty {
                RecommendedPlatesView(
                    recommendedPlates: variant.recommendedPlates,
                    selectedPlates: $variant.selectedPlates,
                    plateManager: plateManager,
                    onUpdate: onUpdate
                )
                
                Divider()
                    .padding(.vertical, 4)
            }
            
            // Character plates with +/- buttons
            VStack(alignment: .leading, spacing: 8) {
                ForEach(plateManager.mainCharacterPlates, id: \.plateId) { mainPlate in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            // Plus/Minus button
                            Button(action: {
                                if variant.selectedCharacterPlateId == mainPlate.plateId {
                                    // Remove character
                                    variant.selectedCharacterPlateId = nil
                                } else {
                                    // Add character (main plate by default)
                                    variant.selectedCharacterPlateId = mainPlate.plateId
                                }
                                onUpdate()
                            }) {
                                Image(systemName: variant.selectedCharacterPlateId == mainPlate.plateId ? "minus.circle.fill" : "plus.circle")
                                    .foregroundColor(variant.selectedCharacterPlateId == mainPlate.plateId ? .blue : .gray)
                                    .font(.system(size: 16))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Character name
                            Text(mainPlate.character)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(variant.selectedCharacterPlateId == mainPlate.plateId ? .blue : .primary)
                            
                            // If character is selected, show specialization selector
                            if variant.selectedCharacterPlateId == mainPlate.plateId || 
                               plateManager.characterPlates.contains(where: { 
                                   $0.character == mainPlate.character && $0.plateId == variant.selectedCharacterPlateId 
                               }) {
                                
                                // Plus button for specialization
                                Button(action: {
                                    expandedCharacter = expandedCharacter == mainPlate.character ? nil : mainPlate.character
                                }) {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 14))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Show current selection
                                if let selectedId = variant.selectedCharacterPlateId,
                                   let selectedPlate = plateManager.characterPlates.first(where: { $0.plateId == selectedId && $0.character == mainPlate.character }) {
                                    HStack(spacing: 4) {
                                        Text(selectedPlate.name)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(3)
                                            .onHover { isHovered in
                                                if isHovered {
                                                    hoveredPlateId = selectedPlate.plateId
                                                } else if hoveredPlateId == selectedPlate.plateId {
                                                    hoveredPlateId = nil
                                                }
                                            }
                                            .popover(isPresented: .constant(hoveredPlateId == selectedPlate.plateId)) {
                                                PlateDescriptionPopover(plate: selectedPlate)
                                            }
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        
                        // Specialization dropdown
                        if expandedCharacter == mainPlate.character {
                            SpecializationPicker(
                                character: mainPlate.character,
                                currentSelection: variant.selectedCharacterPlateId,
                                plateManager: plateManager,
                                searchText: $specializationSearch,
                                onSelect: { plateId in
                                    variant.selectedCharacterPlateId = plateId
                                    expandedCharacter = nil
                                    specializationSearch = ""
                                    onUpdate()
                                }
                            )
                            .padding(.leading, 24)
                        }
                    }
                }
                
                // Environment plate
                HStack {
                    Text("Environment:")
                        .font(.caption)
                        .frame(width: 80, alignment: .leading)
                    
                    if let plateId = variant.selectedEnvironmentPlateId,
                       let plate = plateManager.environmentalPlates.first(where: { $0.plateId == plateId }) {
                        HStack {
                            Text("\(plate.category) - \(plate.name)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(4)
                            
                            Button(action: {
                                variant.selectedEnvironmentPlateId = nil
                                onUpdate()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } else {
                        Button("Select Environment Plate") {
                            showEnvironmentPlates.toggle()
                        }
                        .font(.caption)
                        .buttonStyle(BorderedButtonStyle())
                    }
                    
                    Spacer()
                }
                
                // Show environment plate selector if toggled
                if showEnvironmentPlates {
                    EnvironmentPlateSelector(
                        variant: variant,
                        plateManager: plateManager,
                        onSelect: {
                            showEnvironmentPlates = false
                            onUpdate()
                        }
                    )
                    .padding(.leading, 85)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Specialization Picker
struct SpecializationPicker: View {
    let character: String
    let currentSelection: String?
    let plateManager: PlateManager
    @Binding var searchText: String
    let onSelect: (String) -> Void
    
    var availablePlates: [CharacterPlate] {
        let plates = plateManager.characterPlates.filter { $0.character == character }
        if searchText.isEmpty {
            return plates
        }
        return plates.filter { 
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Search specializations...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.caption)
            }
            .frame(width: 200)
            
            // Plate list
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(availablePlates, id: \.plateId) { plate in
                        Button(action: {
                            onSelect(plate.plateId)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(plate.name)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text(plate.description)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                                if plate.plateId == currentSelection {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(6)
                            .background(plate.plateId == currentSelection ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                            .cornerRadius(4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .frame(maxHeight: 150)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(4)
        }
    }
}

// MARK: - Plate Description Popover
struct PlateDescriptionPopover: View {
    let plate: CharacterPlate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(plate.name)
                .font(.caption)
                .fontWeight(.semibold)
            Text(plate.description)
                .font(.caption2)
                .foregroundColor(.secondary)
            if !plate.shotRange.isEmpty {
                Text(plate.shotRange)
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .frame(maxWidth: 300)
    }
}

// MARK: - Character Plate Selector (Legacy - kept for compatibility)
struct CharacterPlateSelector: View {
    @ObservedObject var variant: PromptVariant
    let plateManager: PlateManager
    let onSelect: () -> Void
    @State private var selectedCharacter = ""
    
    var charactersWithPlates: [String] {
        Array(Set(plateManager.characterPlates.map { $0.character })).sorted()
    }
    
    var platesForSelectedCharacter: [CharacterPlate] {
        plateManager.characterPlates.filter { $0.character == selectedCharacter }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Character picker
            if !charactersWithPlates.isEmpty {
                Picker("Character", selection: $selectedCharacter) {
                    Text("Select Character").tag("")
                    ForEach(charactersWithPlates, id: \.self) { character in
                        Text(character).tag(character)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 200)
            }
            
            // Plates for selected character
            if !selectedCharacter.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(platesForSelectedCharacter) { plate in
                            Button(action: {
                                variant.selectedCharacterPlateId = plate.plateId
                                onSelect()
                            }) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(plate.name)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text(plate.description)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                .padding(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .frame(maxHeight: 150)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(4)
            }
        }
    }
}

// MARK: - Environment Plate Selector
struct EnvironmentPlateSelector: View {
    @ObservedObject var variant: PromptVariant
    let plateManager: PlateManager
    let onSelect: () -> Void
    @State private var selectedCategory = ""
    
    var categoriesWithPlates: [String] {
        Array(Set(plateManager.environmentalPlates.map { $0.category })).sorted()
    }
    
    var platesForSelectedCategory: [EnvironmentalPlate] {
        plateManager.environmentalPlates.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category picker
            if !categoriesWithPlates.isEmpty {
                Picker("Category", selection: $selectedCategory) {
                    Text("Select Category").tag("")
                    ForEach(categoriesWithPlates, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 200)
            }
            
            // Plates for selected category
            if !selectedCategory.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(platesForSelectedCategory) { plate in
                            Button(action: {
                                variant.selectedEnvironmentPlateId = plate.plateId
                                onSelect()
                            }) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(plate.name)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text(plate.description)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                .padding(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .frame(maxHeight: 150)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(4)
            }
        }
    }
}

struct NewVariantDialog: View {
    let baseName: String
    @Binding var newVariantName: String
    let onCancel: () -> Void
    let onCreate: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack {
                Text("Copy Prompt Variant")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Creating copy of: \(baseName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("New variant name:")
                    .font(.caption)
                    .fontWeight(.medium)
                
                TextField("Enter name or leave empty for auto-name", text: $newVariantName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
                
                Text("Leave empty to auto-generate name with '(Copy)' suffix")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape)
                
                Button("Create Copy") {
                    onCreate()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
            }
        }
        .padding(24)
        .frame(width: 420, height: 220)
    }
}

struct GeneratedPromptViewer: View {
    let prompt: String
    let shotId: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Generated VEO3 Prompt - Shot \(shotId)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Copy to Clipboard") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(prompt, forType: .string)
                    print("📋 Copied VEO3 prompt to clipboard")
                }
                .buttonStyle(.bordered)
                
                Button("Close") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            
            ScrollView {
                Text(prompt)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color.gray.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .padding()
        .frame(width: 700, height: 600)
    }
}

// MARK: - Recommended Plates View
struct RecommendedPlatesView: View {
    let recommendedPlates: [String: Any]
    @Binding var selectedPlates: [String: Any]
    let plateManager: PlateManager
    let onUpdate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recommended Plates")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Character recommendations
            if let characterRecs = recommendedPlates["characters"] as? [String: String], !characterRecs.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Characters:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(characterRecs.keys.sorted()), id: \.self) { character in
                        if let plateId = characterRecs[character] {
                            HStack {
                                Button(action: {
                                    // Toggle selection
                                    var chars = selectedPlates["characters"] as? [String: String] ?? [:]
                                    if chars[character] != nil {
                                        chars.removeValue(forKey: character)
                                    } else {
                                        chars[character] = plateId
                                    }
                                    selectedPlates["characters"] = chars
                                    onUpdate()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: isCharacterSelected(character) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 12))
                                        Text("\(character.capitalized): \(plateId)")
                                            .font(.caption)
                                    }
                                    .foregroundColor(isCharacterSelected(character) ? .blue : .primary)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Show plate description on hover
                                if let plate = plateManager.characterPlates.first(where: { $0.plateId == plateId }) {
                                    Text("(\(plate.name))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .help(plate.description)
                                }
                            }
                        }
                    }
                }
            }
            
            // Environment recommendations
            if let envRecs = recommendedPlates["environment"] as? [String: String], !envRecs.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Environment:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(envRecs.keys.sorted()), id: \.self) { category in
                        if let plateId = envRecs[category] {
                            HStack {
                                Button(action: {
                                    // Toggle selection
                                    var envs = selectedPlates["environment"] as? [String: String] ?? [:]
                                    if envs[category] != nil {
                                        envs.removeValue(forKey: category)
                                    } else {
                                        envs[category] = plateId
                                    }
                                    selectedPlates["environment"] = envs
                                    onUpdate()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: isEnvironmentSelected(category) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 12))
                                        Text("\(category.capitalized): \(plateId)")
                                            .font(.caption)
                                    }
                                    .foregroundColor(isEnvironmentSelected(category) ? .blue : .primary)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Show plate description on hover
                                if let plate = plateManager.environmentalPlates.first(where: { $0.plateId == plateId }) {
                                    Text("(\(plate.name))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .help(plate.description)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func isCharacterSelected(_ character: String) -> Bool {
        if let chars = selectedPlates["characters"] as? [String: String] {
            return chars[character] != nil
        }
        return false
    }
    
    private func isEnvironmentSelected(_ category: String) -> Bool {
        if let envs = selectedPlates["environment"] as? [String: String] {
            return envs[category] != nil
        }
        return false
    }
}

#Preview {
    ComprehensivePromptEditor(shot: nil, filmManager: FilmManager())
}