import SwiftUI

struct ClaudeConversationWindow: View {
    @StateObject private var contextBuilder = ClaudeContextBuilder()
    @StateObject private var integrationManager = ClaudeIntegrationManager()
    @ObservedObject var filmManager: FilmManager
    let shot: FilmShot
    @State private var newVariantJSON = ""
    @State private var showJSONEditor = false
    @State private var addVariantSuccess = false
    @State private var addVariantError = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Converse with Claude")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color.gray.opacity(0.1))

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Shot Info Section
                    GroupBox("Current Shot") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Shot ID: \(shot.id)")
                                .font(.headline)
                            Text("Title: \(shot.title)")
                            Text("Duration: \(shot.duration) seconds")
                            Text("Sequence: \(shot.sequenceType)")
                            Text("Variants: \(shot.promptVariants.count)")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Context Configuration Section
                    GroupBox("Context Configuration") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select what to include in Claude's context:")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Current Shot & Variants", isOn: $contextBuilder.includeCurrentShot)
                                Toggle("Character Plates (Masters)", isOn: $contextBuilder.includeCharacterPlates)
                                Toggle("Environmental Plates", isOn: $contextBuilder.includeEnvironmentalPlates)
                            }

                            Divider()

                            Text("Enhancement Guides:")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Genius Cinematic Shots Guide", isOn: $contextBuilder.includeCinematicGuide)
                                Toggle("Genius AI Video Generation Guide", isOn: $contextBuilder.includeAIGuide)
                                Toggle("Genius Character Depth Guide", isOn: $contextBuilder.includeCharacterDepthGuide)
                            }

                            Divider()

                            Text("Research Documents:")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(Array(contextBuilder.includeResearchDocs.keys.sorted()), id: \.self) { key in
                                    Toggle(key.replacingOccurrences(of: "_", with: " ").capitalized,
                                           isOn: Binding(
                                            get: { contextBuilder.includeResearchDocs[key] ?? false },
                                            set: { contextBuilder.includeResearchDocs[key] = $0 }
                                           ))
                                    .font(.caption)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Action Buttons Section
                    GroupBox("Actions") {
                        VStack(spacing: 12) {
                            Button(action: startClaudeConversation) {
                                HStack {
                                    if integrationManager.isConnecting {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "bubble.left.and.bubble.right")
                                    }
                                    Text(integrationManager.isConnecting ? "Connecting..." : "Start Claude Conversation")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(integrationManager.isConnecting)

                            Button("Add JSON Prompt Variant") {
                                showJSONEditor = true
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)

                            if !addVariantError.isEmpty {
                                Text(addVariantError)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }

                            if addVariantSuccess {
                                Text("Variant added successfully!")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                    }

                    // Connection Status
                    if let error = integrationManager.connectionError {
                        GroupBox("Connection Error") {
                            Text(error)
                                .foregroundColor(.red)
                        }
                    }

                    if integrationManager.isConnected {
                        GroupBox("Connected") {
                            Text("Claude conversation started successfully. Check your Claude Code window.")
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 600, height: 800)
        .sheet(isPresented: $showJSONEditor) {
            JSONVariantEditor(
                jsonText: $newVariantJSON,
                onAdd: addVariantFromJSON,
                onCancel: { showJSONEditor = false }
            )
        }
    }

    private func startClaudeConversation() {
        let context = contextBuilder.buildContext(for: shot, filmManager: filmManager)
        integrationManager.startClaudeConversation(with: context)
    }

    private func addVariantFromJSON() {
        addVariantError = ""
        addVariantSuccess = false

        var mutableShot = shot
        let success = integrationManager.addPromptVariantToShot(newVariantJSON, to: &mutableShot)

        if success {
            // Update the shot in the film manager
            if let index = filmManager.shots.firstIndex(where: { $0.id == shot.id }) {
                filmManager.shots[index] = mutableShot
                filmManager.saveAllChanges()
                addVariantSuccess = true
                newVariantJSON = ""
                showJSONEditor = false
            }
        } else {
            addVariantError = "Failed to parse JSON. Please check the format."
        }
    }
}

struct JSONVariantEditor: View {
    @Binding var jsonText: String
    let onAdd: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack {
            HStack {
                Text("Add New Prompt Variant (JSON)")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
            }
            .padding()

            Text("Paste the JSON for your new prompt variant here:")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            TextEditor(text: $jsonText)
                .font(.system(.body, design: .monospaced))
                .border(Color.gray, width: 1)
                .padding()

            HStack {
                Button("Add Variant") {
                    onAdd()
                }
                .buttonStyle(.borderedProminent)
                .disabled(jsonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()

                Text("Format: Complete PromptVariant JSON object")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .frame(width: 700, height: 500)
    }
}

#Preview {
    ClaudeConversationWindow(
        filmManager: FilmManager(),
        shot: FilmShot(
            id: "test",
            title: "Test Shot",
            sequenceType: "main_story",
            position: 50.0,
            subject: "Test subject",
            action: "Test action",
            scene: "Test scene",
            style: "Test style"
        )
    )
}