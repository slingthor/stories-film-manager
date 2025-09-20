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
    @State private var userInstructions = ""
    @State private var conversationIntent = "modifyShot"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AI Conversation Hub")
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
                    // Intent Section
                    GroupBox("Conversation Intent") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What would you like to do?")
                                .font(.headline)

                            Picker("Intent", selection: $conversationIntent) {
                                Text("Modify Current Shot").tag("modifyShot")
                                Text("Shorten for Luma").tag("shortenForLuma")
                                Text("General Discussion").tag("generalChat")
                            }
                            .pickerStyle(SegmentedPickerStyle())

                            Text(conversationIntent == "modifyShot" ?
                                 "AI will focus on creating and improving prompt variants for the current shot." :
                                 conversationIntent == "shortenForLuma" ?
                                 "AI will shorten the fully resolved prompt to under 2015 characters for Luma Dream Machine." :
                                 "AI will engage in general discussion about the film project.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Shot Info Section (show for modifying shot and Luma shortening)
                    if conversationIntent == "modifyShot" || conversationIntent == "shortenForLuma" {
                        GroupBox("Current Shot") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Shot ID: \(shot.id)")
                                    .font(.headline)
                                Text("Title: \(shot.title)")
                                Text("Duration: \(shot.duration) seconds")
                                Text("Sequence: \(shot.sequenceType)")
                                Text("Variants: \(shot.promptVariants.count)")
                                if conversationIntent == "shortenForLuma" && shot.selectedPromptIndex < shot.promptVariants.count {
                                    Text("Selected Variant: \(shot.promptVariants[shot.selectedPromptIndex].name)")
                                        .foregroundColor(.blue)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    // Context Configuration Section
                    GroupBox("Context Configuration") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select what to include in Claude's context:")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 8) {
                                if conversationIntent == "modifyShot" {
                                    Toggle("Current Shot & Variants", isOn: $contextBuilder.includeCurrentShot)
                                        .disabled(true)  // Always include for shot modification
                                } else if conversationIntent == "shortenForLuma" {
                                    // For Luma, we'll generate and include the full prompt
                                    Text("✓ Fully Resolved Prompt (automatically included)")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }

                                if conversationIntent != "shortenForLuma" {
                                    Toggle("Character Plates (Masters)", isOn: $contextBuilder.includeCharacterPlates)
                                    Toggle("Environmental Plates", isOn: $contextBuilder.includeEnvironmentalPlates)
                                }
                            }

                            if conversationIntent == "modifyShot" {
                                Text("Note: Current shot is always included when modifying shots")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if conversationIntent == "shortenForLuma" {
                                Text("Note: The fully resolved prompt will be provided for shortening")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Divider()

                            Text("Prompt Emphasis Style:")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Picker("Select Style", selection: Binding(
                                get: { contextBuilder.selectedPromptEmphasisDoc ?? "None" },
                                set: { contextBuilder.selectedPromptEmphasisDoc = $0 == "None" ? nil : $0 }
                            )) {
                                Text("None").tag("None")
                                ForEach(Array(contextBuilder.promptEmphasisDocuments.keys.sorted()), id: \.self) { key in
                                    Text(key).tag(key)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity)

                            Divider()

                            Text("User Instructions:")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Specific instructions for this Claude session:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                TextEditor(text: $userInstructions)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(minHeight: 80, maxHeight: 120)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(8)

                                Text("Examples: 'Focus on horror elements', 'Make it more cinematic', 'Emphasize the transformation theme'")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .italic()
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
                            // AI Conversation Buttons
                            HStack(spacing: 8) {
                                Button(action: startClaudeConversation) {
                                    VStack(spacing: 4) {
                                        if integrationManager.isConnecting {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "bubble.left.and.bubble.right")
                                        }
                                        Text("Claude")
                                            .font(.caption)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(integrationManager.isConnecting)

                                Button(action: startGeminiConversation) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "sparkles")
                                        Text("Gemini")
                                            .font(.caption)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(integrationManager.isConnecting)

                                Button(action: startCodexConversation) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "curlybraces")
                                        Text("Codex")
                                            .font(.caption)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(integrationManager.isConnecting)
                            }

                            // Copy Context Folder Path Button
                            if let folderPath = integrationManager.contextFolderPath {
                                Button(action: {
                                    let pasteboard = NSPasteboard.general
                                    pasteboard.clearContents()

                                    var instruction = ""

                                    // Add user instructions at the top if provided
                                    if !userInstructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        instruction += """
                                        🎯 USER'S SPECIFIC INSTRUCTIONS FOR THIS SESSION:
                                        Pay special attention to these user requirements:

                                        \(userInstructions.trimmingCharacters(in: .whitespacesAndNewlines))

                                        ========================================

                                        """
                                    }

                                    instruction += """
                                    Please read through all the context files in this folder completely:
                                    \(folderPath)

                                    Start by reading 00_MAIN_CONTEXT.md first for comprehensive instructions, then read all other files in order. Pay special attention to the current shot details and the plate system for creating new prompt variants.
                                    """
                                    pasteboard.setString(instruction, forType: .string)
                                }) {
                                    HStack {
                                        Image(systemName: "doc.on.clipboard")
                                        Text("Copy Context Folder with Instructions")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .help("Copy the context folder path with instructions for Claude to read everything")
                            }

                            // Copy Current Prompt JSON Button
                            Button(action: {
                                if shot.selectedPromptIndex < shot.promptVariants.count {
                                    let currentVariant = shot.promptVariants[shot.selectedPromptIndex]
                                    let jsonData: [String: Any] = [
                                        "variant_id": currentVariant.variantId,
                                        "variant_name": currentVariant.name,
                                        "subject": currentVariant.subject,
                                        "action": currentVariant.action,
                                        "scene": currentVariant.scene,
                                        "style": currentVariant.style,
                                        "camera_position": currentVariant.cameraPosition,
                                        "dialogue": currentVariant.dialogue,
                                        "selected_plates": currentVariant.selectedPlateIds,
                                        "negative_prompt": currentVariant.negativePrompt,
                                        "progressive_state": currentVariant.progressiveState,
                                        "is_active": currentVariant.isActive
                                    ]

                                    if let jsonData = try? JSONSerialization.data(withJSONObject: jsonData, options: [.prettyPrinted, .sortedKeys]),
                                       let jsonString = String(data: jsonData, encoding: .utf8) {
                                        let pasteboard = NSPasteboard.general
                                        pasteboard.clearContents()
                                        pasteboard.setString(jsonString, forType: .string)
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "doc.text")
                                    Text("Copy Current Prompt JSON")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .disabled(shot.promptVariants.isEmpty)
                            .help("Copy the currently selected prompt variant as JSON")

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
        .frame(width: 810, height: 1080)
        .sheet(isPresented: $showJSONEditor) {
            JSONVariantEditor(
                jsonText: $newVariantJSON,
                onAdd: addVariantFromJSON,
                onCancel: { showJSONEditor = false }
            )
        }
    }

    private func startClaudeConversation() {
        prepareConversationContext { context, instructions in
            integrationManager.startClaudeConversation(with: context, filmManager: filmManager, userInstructions: instructions)
        }
    }

    private func startGeminiConversation() {
        prepareConversationContext { context, instructions in
            integrationManager.startGeminiConversation(with: context, filmManager: filmManager, userInstructions: instructions)
        }
    }

    private func startCodexConversation() {
        prepareConversationContext { context, instructions in
            integrationManager.startCodexConversation(with: context, filmManager: filmManager, userInstructions: instructions)
        }
    }

    private func prepareConversationContext(completion: ([String: String], String) -> Void) {
        // Force include current shot when modifying
        if conversationIntent == "modifyShot" {
            contextBuilder.includeCurrentShot = true
        }

        var context = contextBuilder.buildContext(for: shot, filmManager: filmManager)

        // For Luma shortening, generate and add the fully resolved prompt
        if conversationIntent == "shortenForLuma" {
            if shot.selectedPromptIndex < shot.promptVariants.count {
                let cleanPrompt = shot.promptVariants[shot.selectedPromptIndex].generateCleanPrompt(
                    for: shot,
                    plateManager: filmManager.plateManager
                )

                // Add the fully resolved prompt to context
                context["05_LUMA_PROMPT.txt"] = """
                FULLY RESOLVED PROMPT TO SHORTEN
                =================================
                Shot: \(shot.id) - \(shot.title)
                Variant: \(shot.promptVariants[shot.selectedPromptIndex].name)
                Current Length: \(cleanPrompt.count) characters
                Target: Under 2015 characters

                =================================
                COMPLETE PROMPT (with all plates resolved):
                =================================

                \(cleanPrompt)

                =================================
                END OF PROMPT
                """
            }
        }

        let intentInstructions = buildIntentInstructions()
        let fullInstructions = intentInstructions + "\n\n" + userInstructions

        completion(context, fullInstructions)
    }

    private func buildIntentInstructions() -> String {
        switch conversationIntent {
        case "modifyShot":
            return """
            🎬 INTENT: MODIFY CURRENT SHOT
            Your primary goal is to help create, improve, and refine prompt variants for the current shot.
            Focus on:
            - Creating new prompt variants that enhance the shot
            - Improving existing variants
            - Ensuring consistency with the plate system
            - Maintaining the narrative arc of the sequence
            The current shot details are provided in the context.
            """
        case "shortenForLuma":
            return """
            ✂️ INTENT: SHORTEN FOR LUMA DREAM MACHINE
            Your task is to shorten the fully resolved prompt to under 2015 characters.

            The file 05_LUMA_PROMPT.txt contains the complete, fully resolved prompt with all plates already expanded.

            SHORTENING PRIORITY (in order):
            1. First: Reduce descriptions in specialized character/environmental plates while preserving master plates for consistency
            2. Second: Remove non-visual descriptions (internal states, metaphors, abstract concepts)
            3. Third: Condense without losing information (combine similar elements, use more concise language)
            4. Fourth: Cut the least important pieces for the shot

            OUTPUT REQUIREMENTS:
            - Output the shortened prompt in a clear format
            - Ensure it's under 2015 characters total
            - Preserve as much visual information as possible
            - Maintain the core narrative and visual elements
            - Show the character count at the end

            Please output the shortened prompt ready to paste into Luma Dream Machine.
            """
        case "generalChat":
            return """
            💬 INTENT: GENERAL DISCUSSION
            This is a general conversation about the film project.
            You can discuss:
            - Overall narrative themes
            - Character development
            - Visual style and cinematography
            - Technical aspects of video generation
            - Any questions about the project
            """
        default:
            return ""
        }
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