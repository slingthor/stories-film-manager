import SwiftUI
import Combine

struct ComprehensivePromptEditor: View {
    let shot: FilmShot?
    @State private var showingNewVariantDialog = false
    @State private var newVariantName = ""
    @State private var showingGeneratedPrompt = false
    @State private var generatedPrompt = ""
    
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
                            // Character & Environment plates section (placeholder for future)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("CHARACTER & ENVIRONMENT PLATES")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                HStack {
                                    Text("Character: MAGNÚS-AUTHORITY")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(4)
                                    
                                    Text("Environment: WESTFJORDS-SUMMER")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.green.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                            
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
                                
                                Button(prompt.isActive ? "★ ACTIVE PROMPT" : "Set as Active") {
                                    shot.setActivePrompt(at: shot.selectedPromptIndex)
                                }
                                .buttonStyle(.bordered)
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

#Preview {
    ComprehensivePromptEditor(shot: nil)
}