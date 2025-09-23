import SwiftUI
import Combine

struct PromptGenerationPanel: View {
    @ObservedObject var filmManager: FilmManager
    @State private var showingGeneratedPrompt = false
    @State private var generatedPrompt = ""
    @State private var generatedCleanPrompt = ""
    
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
    }
}

#Preview {
    PromptGenerationPanel(filmManager: FilmManager())
        .frame(width: 800, height: 60)
}