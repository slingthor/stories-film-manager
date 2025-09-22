import SwiftUI
import Combine
import UniformTypeIdentifiers
import AVFoundation

struct ComprehensivePromptEditor: View {
    let shot: FilmShot?
    @ObservedObject var filmManager: FilmManager
    @State private var showingNewVariantDialog = false
    @State private var newVariantName = ""
    @State private var showingGeneratedPrompt = false
    @State private var generatedPrompt = ""
    @State private var generatedCleanPrompt = ""
    @State private var showCharacterPlates = false
    @State private var showEnvironmentPlates = false
    @State private var showClaudeConversation = false

    private func variantVideoThumbnail(video: VideoFile, index: Int, variant: PromptVariant, shot: FilmShot) -> some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                VideoThumbnailView(
                    videoPath: video.filepath,
                    size: CGSize(width: 80, height: 60),
                    enableHoverPreview: true
                )
                .frame(width: 80, height: 60)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(variant.activeVideoIndex == index ? Color.green : Color.clear, lineWidth: 2)
                )
                .onTapGesture {
                    variant.setActiveVideo(at: index)
                    filmManager.fileManager.saveShot(shot)
                    if variant.isActive {
                        filmManager.updateTimelineFromSelectedVideos()
                    }
                }

                Button(action: {
                    variant.removeVideo(at: index)
                    filmManager.fileManager.saveShot(shot)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.red))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Remove video")
                .offset(x: 5, y: -5)
            }

            HStack(spacing: 2) {
                if variant.activeVideoIndex == index {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 10))
                }
                Text("\(String(format: "%.1f", video.duration))s")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var variantMediaSection: some View {
        if let shot = shot, shot.selectedPromptIndex < shot.promptVariants.count {
            let currentVariant = shot.promptVariants[shot.selectedPromptIndex]

            VStack(alignment: .leading, spacing: 12) {
                Label("Variant Media Assets", systemImage: "photo.on.rectangle")
                    .font(.headline)
                    .foregroundColor(.orange)

                Text("Current variant: \(currentVariant.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Variant videos with thumbnails
                if !currentVariant.videos.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Variant Videos (\(currentVariant.videos.count))")
                            .font(.caption)
                            .fontWeight(.medium)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(currentVariant.videos.enumerated()), id: \.element.id) { index, video in
                                    variantVideoThumbnail(video: video, index: index, variant: currentVariant, shot: shot)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Variant images with thumbnails
                if !currentVariant.images.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Variant Images (\(currentVariant.images.count))")
                            .font(.caption)
                            .fontWeight(.medium)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(currentVariant.images.enumerated()), id: \.element.id) { index, image in
                                    ZStack(alignment: .topTrailing) {
                                        // Image thumbnail with hover preview
                                        ImageThumbnailView(
                                            imagePath: image.filepath,
                                            size: CGSize(width: 80, height: 60),
                                            enableHoverPreview: true
                                        )
                                        .frame(width: 80, height: 60)
                                        .cornerRadius(4)

                                        // Delete button
                                        Button(action: {
                                            currentVariant.removeImage(at: index)
                                            filmManager.fileManager.saveShot(shot)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .background(Circle().fill(Color.red))
                                                .frame(width: 20, height: 20)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .help("Remove image")
                                        .offset(x: 5, y: -5)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Shot videos (available to add to variant) with thumbnails
                if !shot.videos.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Shot Videos (click to add to variant)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(shot.videos, id: \.id) { video in
                                    let isInVariant = currentVariant.videos.contains(where: { $0.filepath == video.filepath })

                                    VStack(spacing: 4) {
                                        VideoThumbnailView(
                                            videoPath: video.filepath,
                                            size: CGSize(width: 80, height: 60),
                                            enableHoverPreview: true
                                        )
                                        .frame(width: 80, height: 60)
                                        .cornerRadius(4)
                                        .opacity(isInVariant ? 0.5 : 1.0)
                                        .overlay(
                                            Group {
                                                if isInVariant {
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(Color.gray.opacity(0.3))
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.gray)
                                                        .font(.title2)
                                                }
                                            }
                                        )
                                        .onTapGesture {
                                            if !isInVariant {
                                                currentVariant.addVideo(video)
                                                filmManager.fileManager.saveShot(shot)
                                            }
                                        }

                                        Text("\(String(format: "%.1f", video.duration))s")
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Shot images (available to add to variant) with thumbnails
                if !shot.images.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Shot Images (click to add to variant)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(shot.images, id: \.id) { image in
                                    let isInVariant = currentVariant.images.contains(where: { $0.filepath == image.filepath })

                                    ImageThumbnailView(
                                        imagePath: image.filepath,
                                        size: CGSize(width: 80, height: 60),
                                        enableHoverPreview: true
                                    )
                                    .frame(width: 80, height: 60)
                                    .cornerRadius(4)
                                    .opacity(isInVariant ? 0.5 : 1.0)
                                    .overlay(
                                        Group {
                                            if isInVariant {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.gray.opacity(0.3))
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.gray)
                                                    .font(.title2)
                                            }
                                        }
                                    )
                                    .onTapGesture {
                                        if !isInVariant {
                                            currentVariant.addImage(image)
                                            filmManager.fileManager.saveShot(shot)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Baked Prompts section
                BakedPromptsSection(variant: currentVariant, shot: shot, filmManager: filmManager)

                // Drop zone for variant
                VStack {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title3)
                        .foregroundColor(.gray)
                    Text("Drop media for variant")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(height: 60)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                )
                .onDrop(of: [.fileURL], isTargeted: .constant(false)) { providers in
                    handleVariantDrop(providers: providers, variant: currentVariant, shot: shot)
                    return true
                }
            }
            .padding()
            .background(Color.orange.opacity(0.05))
            .cornerRadius(8)
        }
    }

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
                            ForEach(Array(shot.promptVariants.enumerated()), id: \.element.id) { index, variant in
                                Button {
                                    shot.selectedPromptIndex = index
                                    shot.isDirty = true
                                    shot.objectWillChange.send()
                                    filmManager.objectWillChange.send()
                                    filmManager.fileManager.saveShot(shot)
                                } label: {
                                    HStack {
                                        if variant.isActive {
                                            Text("★")
                                                .foregroundColor(.yellow)
                                                .font(.caption2)
                                        }
                                        Text(variant.name)
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

                    Button {
                        showClaudeConversation = true
                    } label: {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                    .help("Converse with Claude about this shot")
                    .padding(.horizontal)
                }
                .frame(height: 50)
                
                Divider()
                
                // Comprehensive prompt editing
                if shot.selectedPromptIndex < shot.promptVariants.count {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Integrated Plate Selection
                            PlateSelectionSection(
                                variant: shot.promptVariants[shot.selectedPromptIndex],
                                plateManager: filmManager.plateManager,
                                showCharacterPlates: $showCharacterPlates,
                                showEnvironmentPlates: $showEnvironmentPlates,
                                onUpdate: { 
                                    shot.isDirty = true
                                    filmManager.objectWillChange.send()
                                }
                            )
                            .id("\(shot.id)-\(shot.selectedPromptIndex)") // Force re-render on shot/variant change
                            
                            // All VEO3 prompt fields
                            Group {
                                VEOPromptField(
                                    title: "SUBJECT",
                                    content: Binding(
                                        get: { shot.promptVariants[shot.selectedPromptIndex].subject },
                                        set: { shot.promptVariants[shot.selectedPromptIndex].subject = $0; shot.isDirty = true }
                                    ),
                                    height: 100,
                                    helpText: "Main subject and visual elements"
                                )
                                
                                VEOPromptField(
                                    title: "ACTION", 
                                    content: Binding(
                                        get: { shot.promptVariants[shot.selectedPromptIndex].action },
                                        set: { shot.promptVariants[shot.selectedPromptIndex].action = $0; shot.isDirty = true }
                                    ),
                                    height: 140,
                                    helpText: "Movement, behavior, and sequence of events"
                                )
                                
                                VEOPromptField(
                                    title: "SCENE",
                                    content: Binding(
                                        get: { shot.promptVariants[shot.selectedPromptIndex].scene },
                                        set: { shot.promptVariants[shot.selectedPromptIndex].scene = $0; shot.isDirty = true }
                                    ),
                                    height: 80,
                                    helpText: "Setting, environment, and context"
                                )
                                
                                VEOPromptField(
                                    title: "STYLE",
                                    content: Binding(
                                        get: { shot.promptVariants[shot.selectedPromptIndex].style },
                                        set: { shot.promptVariants[shot.selectedPromptIndex].style = $0; shot.isDirty = true }
                                    ),
                                    height: 80,
                                    helpText: "Visual style and cinematography"
                                )
                                
                                VEOPromptField(
                                    title: "CAMERA POSITION",
                                    content: Binding(
                                        get: { shot.promptVariants[shot.selectedPromptIndex].cameraPosition },
                                        set: { shot.promptVariants[shot.selectedPromptIndex].cameraPosition = $0; shot.isDirty = true }
                                    ),
                                    height: 60,
                                    helpText: "Where the camera is positioned"
                                )
                                
                                VEOPromptField(
                                    title: "DIALOGUE",
                                    content: Binding(
                                        get: { shot.promptVariants[shot.selectedPromptIndex].dialogue },
                                        set: { shot.promptVariants[shot.selectedPromptIndex].dialogue = $0; shot.isDirty = true }
                                    ),
                                    height: 60,
                                    helpText: "Character speech and vocalizations"
                                )
                                
                                VEOPromptField(
                                    title: "NEGATIVE PROMPT",
                                    content: Binding(
                                        get: { shot.promptVariants[shot.selectedPromptIndex].negativePrompt },
                                        set: { shot.promptVariants[shot.selectedPromptIndex].negativePrompt = $0; shot.isDirty = true }
                                    ),
                                    height: 60,
                                    helpText: "Elements to avoid in generation"
                                )
                                
                                VEOPromptField(
                                    title: "PROGRESSIVE STATE",
                                    content: Binding(
                                        get: { shot.promptVariants[shot.selectedPromptIndex].progressiveState },
                                        set: { shot.promptVariants[shot.selectedPromptIndex].progressiveState = $0; shot.isDirty = true }
                                    ),
                                    height: 40,
                                    helpText: "Current state in narrative progression"
                                )
                            }

                            // Variant Media Section
                            variantMediaSection
                            
                            // Generated Prompt Display (inline)
                            if showingGeneratedPrompt && !generatedPrompt.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Label("Generated VEO3 Prompt", systemImage: "doc.text")
                                            .font(.headline)
                                        
                                        Spacer()
                                        
                                        Button("Copy") {
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(generatedPrompt, forType: .string)
                                        }
                                        .buttonStyle(.bordered)
                                        
                                        Button("Hide") {
                                            showingGeneratedPrompt = false
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    
                                    ScrollView {
                                        Text(generatedPrompt)
                                            .font(.system(.body, design: .monospaced))
                                            .textSelection(.enabled)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding()
                                    }
                                    .frame(height: 300)
                                    .background(Color.black.opacity(0.03))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .padding()
                                .background(Color.blue.opacity(0.05))
                                .cornerRadius(8)
                            }
                            
                            // Action buttons moved to fixed bottom panel
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
        .onChange(of: filmManager.selectedShot?.id) { _ in
            // Reset expansion states when switching shots
            showCharacterPlates = false
            showEnvironmentPlates = false
        }
        .onChange(of: filmManager.selectedShot?.selectedPromptIndex) { _ in
            // Reset expansion states when switching variants
            showCharacterPlates = false
            showEnvironmentPlates = false
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
                        // Force UI update for new prompt variant
                        filmManager.objectWillChange.send()
                        // Save the shot immediately after copying the variant
                        filmManager.fileManager.saveShot(shot)
                        print("💾 Saved shot after copying prompt variant")
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
                cleanPrompt: generatedCleanPrompt,
                onDismiss: { showingGeneratedPrompt = false }
            )
        }
        .sheet(isPresented: $showClaudeConversation) {
            if let shot = shot {
                ClaudeConversationWindow(filmManager: filmManager, shot: shot)
            }
        }
    }

    private func handleVariantDrop(providers: [NSItemProvider], variant: PromptVariant, shot: FilmShot) {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, error in
                    if let data = data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            let fileExtension = url.pathExtension.lowercased()
                            let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v", "webm"]
                            let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic"]

                            if videoExtensions.contains(fileExtension) {
                                // Get video duration
                                let asset = AVAsset(url: url)
                                let duration = CMTimeGetSeconds(asset.duration)
                                let finalDuration = duration.isFinite ? duration : 0.0

                                let video = VideoFile(
                                    filename: url.lastPathComponent,
                                    filepath: url.path,
                                    duration: finalDuration
                                )

                                variant.addVideo(video)
                                shot.isDirty = true
                                filmManager.fileManager.saveShot(shot)

                                print("✅ Added video to variant via prompt editor: \(video.filename)")

                                // Update UI
                                variant.objectWillChange.send()
                                shot.objectWillChange.send()
                                filmManager.objectWillChange.send()

                            } else if imageExtensions.contains(fileExtension) {
                                let image = ImageFile(
                                    filename: url.lastPathComponent,
                                    filepath: url.path
                                )

                                variant.addImage(image)
                                shot.isDirty = true
                                filmManager.fileManager.saveShot(shot)

                                print("✅ Added image to variant via prompt editor: \(image.filename)")

                                // Update UI
                                variant.objectWillChange.send()
                                shot.objectWillChange.send()
                                filmManager.objectWillChange.send()
                            }
                        }
                    }
                }
            }
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
    @State private var lastVariantId: String = ""
    
    // Helper to check if a character has a selected plate
    private func isCharacterSelected(_ character: String) -> Bool {
        // Check in the new array structure
        let charLower = character.lowercased()
        return variant.selectedPlateIds.contains { plateId in
            plateId.lowercased().contains(charLower)
        }
    }
    
    // Helper to get selected plate ID for a character
    private func getSelectedPlateForCharacter(_ character: String) -> String? {
        // Find in the new array structure
        let charLower = character.lowercased()
        return variant.selectedPlateIds.first { plateId in
            plateId.lowercased().contains(charLower)
        }
    }
    
    // Helper to get all environment plates
    private func getEnvironmentPlates() -> [String] {
        // Get all plates that are NOT character plates
        return variant.selectedPlateIds.filter { plateId in
            let lower = plateId.lowercased()
            return !lower.contains("magnus") && !lower.contains("sigrid") &&
                   !lower.contains("gudrun") && !lower.contains("jon") &&
                   !lower.contains("lilja")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PLATES")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // DEBUG: Show what's actually in selectedPlateIds
            Text("DEBUG: \(variant.selectedPlateIds.count) plates: \(variant.selectedPlateIds.joined(separator: ", "))")
                .font(.caption2)
                .foregroundColor(.red)
            
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
                                let charLower = mainPlate.character.lowercased()
                                
                                if isCharacterSelected(mainPlate.character) {
                                    // Remove all plates for this character
                                    variant.selectedPlateIds.removeAll { plateId in
                                        plateId.lowercased().contains(charLower)
                                    }
                                    if variant.selectedCharacterPlateId?.lowercased().contains(charLower) == true {
                                        variant.selectedCharacterPlateId = nil
                                    }
                                } else {
                                    // Add character's main plate
                                    variant.selectedPlateIds.append(mainPlate.plateId)
                                    variant.selectedCharacterPlateId = mainPlate.plateId
                                }
                                
                                onUpdate()
                            }) {
                                Image(systemName: isCharacterSelected(mainPlate.character) ? "minus.circle.fill" : "plus.circle")
                                    .foregroundColor(isCharacterSelected(mainPlate.character) ? .blue : .gray)
                                    .font(.system(size: 16))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Character name
                            Text(mainPlate.character)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(isCharacterSelected(mainPlate.character) ? .blue : .primary)
                            
                            // If character is selected, show specialization selector
                            if isCharacterSelected(mainPlate.character) {
                                
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
                                if let selectedId = getSelectedPlateForCharacter(mainPlate.character),
                                   let selectedPlate = plateManager.characterPlates.first(where: { $0.plateId == selectedId }) {
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
                                currentSelection: getSelectedPlateForCharacter(mainPlate.character),
                                plateManager: plateManager,
                                searchText: $specializationSearch,
                                onSelect: { plateId in
                                    // Remove old plate for this character
                                    let charLower = mainPlate.character.lowercased()
                                    variant.selectedPlateIds.removeAll { $0.lowercased().contains(charLower) }
                                    
                                    // Add new plate
                                    variant.selectedPlateIds.append(plateId)
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
                
                // Environment plates - show ALL selected
                HStack(alignment: .top) {
                    Text("Environment:")
                        .font(.caption)
                        .frame(width: 80, alignment: .leading)
                        .padding(.top, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Show all selected environment plates
                        let envPlates = getEnvironmentPlates()
                        if !envPlates.isEmpty {
                            ForEach(envPlates, id: \.self) { plateId in
                                if let plate = plateManager.environmentalPlates.first(where: { $0.plateId == plateId }) {
                                    HStack(spacing: 2) {
                                        Text("\(plate.category): \(plate.name)")
                                            .font(.caption2)
                                            .lineLimit(1)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color.green.opacity(0.2))
                                            .cornerRadius(3)
                                            .help(plate.description) // Native tooltip
                                        
                                        Button(action: {
                                            // Remove this environment plate
                                            variant.selectedPlateIds.removeAll { $0 == plateId }
                                            if variant.selectedEnvironmentPlateId == plateId {
                                                variant.selectedEnvironmentPlateId = nil
                                            }
                                            onUpdate()
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 11))
                                                .foregroundColor(.gray)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        
                        // Always show the add button
                        Button(action: { showEnvironmentPlates.toggle() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 12))
                                Text("Add Environment Plate")
                                    .font(.caption2)
                            }
                        }
                        .buttonStyle(BorderedButtonStyle())
                        .controlSize(.small)
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
        .onAppear {
            lastVariantId = variant.variantId
        }
        .onChange(of: variant.variantId) { newVariantId in
            if newVariantId != lastVariantId {
                // Reset expansion states when variant changes
                expandedCharacter = nil
                hoveredPlateId = nil
                specializationSearch = ""
                lastVariantId = newVariantId
            }
        }
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
                                // Add to the selectedPlateIds array
                                if !variant.selectedPlateIds.contains(plate.plateId) {
                                    variant.selectedPlateIds.append(plate.plateId)
                                }
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
                                // Add to the selectedPlateIds array
                                if !variant.selectedPlateIds.contains(plate.plateId) {
                                    variant.selectedPlateIds.append(plate.plateId)
                                }
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
    let cleanPrompt: String
    let onDismiss: () -> Void

    private func sanitizeForPG18(_ text: String) -> String {
        var sanitized = text

        // Only replace age-related terms - change 16 to 18
        sanitized = sanitized.replacingOccurrences(of: "16-year-old", with: "18-year-old", options: .caseInsensitive)
        sanitized = sanitized.replacingOccurrences(of: "16 year old", with: "18 year old", options: .caseInsensitive)
        sanitized = sanitized.replacingOccurrences(of: "age 16", with: "age 18", options: .caseInsensitive)
        sanitized = sanitized.replacingOccurrences(of: "sixteen", with: "eighteen", options: .caseInsensitive)
        sanitized = sanitized.replacingOccurrences(of: "16 years", with: "18 years", options: .caseInsensitive)

        // Also update any other young ages to be 18+
        sanitized = sanitized.replacingOccurrences(of: "15-year-old", with: "18-year-old", options: .caseInsensitive)
        sanitized = sanitized.replacingOccurrences(of: "15 year old", with: "18 year old", options: .caseInsensitive)
        sanitized = sanitized.replacingOccurrences(of: "14-year-old", with: "18-year-old", options: .caseInsensitive)
        sanitized = sanitized.replacingOccurrences(of: "14 year old", with: "18 year old", options: .caseInsensitive)

        return sanitized
    }

    private func removeCharacterPlates(_ text: String) -> String {
        // Find where character plates start and ACTION: begins
        // Character plates typically come after SUBJECT: and before ACTION:

        // Look for the start of character descriptions (usually after "SUBJECT:")
        // and the start of ACTION: section
        guard let actionRange = text.range(of: "ACTION:", options: .caseInsensitive) else {
            // If no ACTION: found, return the original text
            return text
        }

        // Find SUBJECT: section
        guard let subjectRange = text.range(of: "SUBJECT:", options: .caseInsensitive) else {
            // If no SUBJECT: found, return the original text
            return text
        }

        // Extract the part before SUBJECT:
        let beforeSubject = String(text[..<subjectRange.lowerBound])

        // Extract the part from ACTION: onwards
        let fromAction = String(text[actionRange.lowerBound...])

        // Combine them, effectively removing the character plate section
        return beforeSubject + fromAction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Generated VEO3 Prompt - Shot \(shotId)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()

                Button("Copy Prompt") {
                    // Copy the clean prompt without headers and technical info
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(cleanPrompt, forType: .string)
                    print("📋 Copied clean VEO3 prompt to clipboard")
                }
                .buttonStyle(.bordered)

                Button("Copy Prompt PG18") {
                    // Copy sanitized version for VEO3 compliance
                    let sanitizedPrompt = sanitizeForPG18(cleanPrompt)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(sanitizedPrompt, forType: .string)
                    print("📋 Copied PG18-sanitized VEO3 prompt to clipboard")
                }
                .buttonStyle(.bordered)
                .foregroundColor(.orange)

                Button("Copy No Chars") {
                    // Copy prompt without character plates
                    let promptWithoutChars = removeCharacterPlates(cleanPrompt)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(promptWithoutChars, forType: .string)
                    print("📋 Copied prompt without character plates to clipboard")
                }
                .buttonStyle(.bordered)
                .foregroundColor(.green)

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