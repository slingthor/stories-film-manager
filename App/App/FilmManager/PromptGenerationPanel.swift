import SwiftUI
import Combine

struct PromptGenerationPanel: View {
    @ObservedObject var filmManager: FilmManager
    @State private var showingGeneratedPrompt = false
    @State private var generatedPrompt = ""
    @State private var generatedCleanPrompt = ""
    @State private var showingBakeProgress = false
    @State private var bakeProgress = 0.0
    @State private var bakeStatusMessage = ""
    @State private var totalPromptsCount = 0
    @State private var bakedPromptsCount = 0

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                // Shot info
                if let shot = filmManager.selectedShot {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SHOT \(shot.id)")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text(shot.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if shot.selectedPromptIndex < shot.promptVariants.count {
                            Text("Variant: \(shot.promptVariants[shot.selectedPromptIndex].name)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        Button("Generate Complete Prompt") {
                            guard shot.selectedPromptIndex < shot.promptVariants.count else { return }
                            
                            generatedPrompt = shot.promptVariants[shot.selectedPromptIndex].generateCompletePrompt(
                                for: shot,
                                plateManager: filmManager.plateManager,
                                trackingSystems: filmManager.trackingSystems
                            )
                            generatedCleanPrompt = shot.promptVariants[shot.selectedPromptIndex].generateCleanPrompt(
                                for: shot,
                                plateManager: filmManager.plateManager
                            )
                            showingGeneratedPrompt = true
                            print("🎬 Generated prompt (\(generatedPrompt.count) chars)")
                            print(generatedPrompt)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(shot.promptVariants.isEmpty)
                        
                        Button(action: {
                            if shot.selectedPromptIndex < shot.promptVariants.count &&
                               !shot.promptVariants[shot.selectedPromptIndex].isActive {
                                shot.setActivePrompt(at: shot.selectedPromptIndex)
                                filmManager.fileManager.saveShot(shot)
                            }
                        }) {
                            Label(
                                shot.selectedPromptIndex < shot.promptVariants.count && shot.promptVariants[shot.selectedPromptIndex].isActive ? "Active" : "Set as Active", 
                                systemImage: shot.selectedPromptIndex < shot.promptVariants.count && shot.promptVariants[shot.selectedPromptIndex].isActive ? "star.fill" : "star"
                            )
                        }
                        .buttonStyle(.bordered)
                        .disabled(shot.selectedPromptIndex >= shot.promptVariants.count || 
                                 shot.promptVariants[shot.selectedPromptIndex].isActive)
                        .foregroundColor(shot.selectedPromptIndex < shot.promptVariants.count && shot.promptVariants[shot.selectedPromptIndex].isActive ? .yellow : .primary)
                        
                        Button("Save Shot") {
                            // Force save by marking as dirty then triggering save
                            shot.isDirty = true
                            filmManager.fileManager.saveShot(shot)
                            shot.isDirty = false
                            print("💾 Manually saved shot \(shot.id)")
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Save All") {
                            filmManager.saveAllChanges()
                        }
                        .buttonStyle(.bordered)

                        Menu {
                            Button("Bake All Prompts") {
                                bakeAllPrompts()
                            }
                        } label: {
                            Label("Actions", systemImage: "ellipsis.circle")
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 24))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("Select a shot to generate prompts")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.05))
        }
        .sheet(isPresented: $showingGeneratedPrompt) {
            GeneratedPromptViewer(
                prompt: generatedPrompt,
                shotId: filmManager.selectedShot?.id ?? "",
                cleanPrompt: generatedCleanPrompt,
                shot: filmManager.selectedShot,
                plateManager: filmManager.plateManager,
                onDismiss: { showingGeneratedPrompt = false }
            )
        }
        .sheet(isPresented: $showingBakeProgress) {
            BakeProgressView(
                progress: bakeProgress,
                statusMessage: bakeStatusMessage,
                bakedCount: bakedPromptsCount,
                totalCount: totalPromptsCount
            )
        }
    }

    private func bakeAllPrompts() {
        print("🍞 Starting to bake all prompts...")

        // Calculate total number of prompts to bake (all shots × all variants)
        totalPromptsCount = filmManager.shots.reduce(0) { $0 + $1.promptVariants.count }
        bakedPromptsCount = 0
        bakeProgress = 0.0
        bakeStatusMessage = "Preparing to bake \(totalPromptsCount) prompts..."

        showingBakeProgress = true

        // Ensure the output directory exists
        let outputPath = "/Volumes/share/media/MovieMaking/nidstong/Prompts"
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: outputPath) {
            do {
                try fileManager.createDirectory(atPath: outputPath, withIntermediateDirectories: true)
                print("📁 Created output directory: \(outputPath)")
            } catch {
                print("❌ Failed to create directory: \(error.localizedDescription)")
                bakeStatusMessage = "Error: Failed to create output directory"
                return
            }
        }

        // Process each shot and variant
        DispatchQueue.global(qos: .userInitiated).async {
            for shot in filmManager.shots {
                for (variantIndex, variant) in shot.promptVariants.enumerated() {
                    DispatchQueue.main.async {
                        bakeStatusMessage = "Baking shot \(shot.id) - \(variant.name)..."
                    }

                    // Generate complete and clean prompts
                    let completePrompt = variant.generateCompletePrompt(
                        for: shot,
                        plateManager: filmManager.plateManager,
                        trackingSystems: filmManager.trackingSystems
                    )

                    let cleanPrompt = variant.generateCleanPrompt(
                        for: shot,
                        plateManager: filmManager.plateManager
                    )

                    // Create safe filenames using shot.id and variant.variantId for easy mapping back to JSON
                    let safeVariantId = variant.variantId
                        .replacingOccurrences(of: " ", with: "_")
                        .replacingOccurrences(of: "/", with: "-")
                        .replacingOccurrences(of: ":", with: "-")

                    let completeFilename = "\(shot.id)_\(safeVariantId)_complete.txt"
                    let cleanFilename = "\(shot.id)_\(safeVariantId)_clean.txt"
                    let metadataFilename = "\(shot.id)_\(safeVariantId)_metadata.json"

                    let completeFilePath = "\(outputPath)/\(completeFilename)"
                    let cleanFilePath = "\(outputPath)/\(cleanFilename)"
                    let metadataFilePath = "\(outputPath)/\(metadataFilename)"

                    // Create minimal metadata for mapping back to shot JSON
                    let metadata: [String: Any] = [
                        "shot_id": shot.id,
                        "variant_id": variant.variantId
                    ]

                    // Write prompts and metadata to files
                    do {
                        try completePrompt.write(toFile: completeFilePath, atomically: true, encoding: .utf8)
                        try cleanPrompt.write(toFile: cleanFilePath, atomically: true, encoding: .utf8)

                        // Write metadata JSON
                        let metadataData = try JSONSerialization.data(withJSONObject: metadata, options: [.prettyPrinted, .sortedKeys])
                        try metadataData.write(to: URL(fileURLWithPath: metadataFilePath))

                        print("✅ Baked shot \(shot.id) - \(variant.name)")
                        print("   📄 Complete: \(completeFilename)")
                        print("   📄 Clean: \(cleanFilename)")
                        print("   📋 Metadata: \(metadataFilename)")
                    } catch {
                        print("❌ Failed to write prompts for shot \(shot.id) - \(variant.name): \(error.localizedDescription)")
                    }

                    // Update progress
                    DispatchQueue.main.async {
                        bakedPromptsCount += 1
                        bakeProgress = Double(bakedPromptsCount) / Double(totalPromptsCount)
                    }
                }
            }

            // Complete
            DispatchQueue.main.async {
                bakeStatusMessage = "✅ Completed! Baked \(bakedPromptsCount) prompts"
                print("🎉 Baking complete! Total prompts baked: \(bakedPromptsCount)")

                // Auto-dismiss after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showingBakeProgress = false
                }
            }
        }
    }
}

// MARK: - Bake Progress View
struct BakeProgressView: View {
    let progress: Double
    let statusMessage: String
    let bakedCount: Int
    let totalCount: Int

    var body: some View {
        VStack(spacing: 20) {
            Text("Baking Prompts")
                .font(.title2)
                .fontWeight(.bold)

            ProgressView(value: progress) {
                Text(statusMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .progressViewStyle(.linear)
            .frame(width: 400)

            HStack {
                Text("\(bakedCount) of \(totalCount) prompts baked")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .frame(width: 400)

            if progress >= 1.0 {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("All prompts baked successfully!")
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(40)
        .frame(width: 500, height: 250)
    }
}

#Preview {
    PromptGenerationPanel(filmManager: FilmManager())
        .frame(width: 800, height: 60)
}