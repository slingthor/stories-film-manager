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
    @State private var veo3SanitizationLevel = "medium"
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
                                Text("Split Shot in Two").tag("splitShot")
                                Text("Sanitize for VEO3").tag("sanitizeForVEO3")
                                Text("General Discussion").tag("generalChat")
                            }
                            .pickerStyle(SegmentedPickerStyle())

                            Text(conversationIntent == "modifyShot" ?
                                 "AI will focus on creating and improving prompt variants for the current shot." :
                                 conversationIntent == "shortenForLuma" ?
                                 "AI will shorten the fully resolved prompt to under 1960 characters for Luma Dream Machine." :
                                 conversationIntent == "splitShot" ?
                                 "AI will intelligently split complex shots into two separate prompts while preserving story and visual quality." :
                                 conversationIntent == "sanitizeForVEO3" ?
                                 "AI will sanitize the prompt for VEO3 compliance, removing prohibited content while preserving cinematic quality." :
                                 "AI will engage in general discussion about the film project.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // VEO3 Sanitization Level Section
                    if conversationIntent == "sanitizeForVEO3" {
                        GroupBox("VEO3 Sanitization Settings") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Sanitization Level:")
                                    .font(.headline)

                                Picker("Sanitization Level", selection: $veo3SanitizationLevel) {
                                    Text("Low").tag("low")
                                    Text("Medium").tag("medium")
                                    Text("High").tag("high")
                                }
                                .pickerStyle(SegmentedPickerStyle())

                                Text(veo3SanitizationLevel == "low" ?
                                     "Only removes explicitly prohibited content like graphic violence or illegal activities." :
                                     veo3SanitizationLevel == "medium" ?
                                     "Removes prohibited content and softens potentially risky elements like intense violence or disturbing imagery." :
                                     "Removes all potentially problematic content, prioritizing safe generation over artistic intensity.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    // Shot Info Section (show for modifying shot, Luma shortening, split shot, and VEO3)
                    if conversationIntent == "modifyShot" || conversationIntent == "shortenForLuma" || conversationIntent == "splitShot" || conversationIntent == "sanitizeForVEO3" {
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
                                } else if conversationIntent == "splitShot" {
                                    // For split shot, we'll include the full prompt and context
                                    Text("✓ Full Shot Context & Prompt (automatically included)")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                } else if conversationIntent == "sanitizeForVEO3" {
                                    // For VEO3 sanitization, we'll include the full prompt and VEO3 guidelines
                                    Text("✓ Full Shot Context & Prompt + VEO3 Guidelines (automatically included)")
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
                            } else if conversationIntent == "sanitizeForVEO3" {
                                Text("Note: The fully resolved prompt and VEO3 content policies will be provided for sanitization")
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

    private func prepareConversationContext(completion: (ClaudeContext, String) -> Void) {
        // Force include current shot when modifying, splitting, or sanitizing
        if conversationIntent == "modifyShot" || conversationIntent == "splitShot" || conversationIntent == "sanitizeForVEO3" {
            contextBuilder.includeCurrentShot = true
        }

        var context = contextBuilder.buildContext(for: shot, filmManager: filmManager)

        // For Luma shortening, add the fully resolved prompt to the context
        if conversationIntent == "shortenForLuma" {
            if shot.selectedPromptIndex < shot.promptVariants.count {
                let cleanPrompt = shot.promptVariants[shot.selectedPromptIndex].generateCleanPrompt(
                    for: shot,
                    plateManager: filmManager.plateManager
                )

                // Add the fully resolved prompt to the shot context
                let lumaPrompt = """

                =================================
                FULLY RESOLVED PROMPT TO SHORTEN
                =================================
                Shot: \(shot.id) - \(shot.title)
                Variant: \(shot.promptVariants[shot.selectedPromptIndex].name)
                Current Length: \(cleanPrompt.count) characters
                Target: Under 1960 characters

                =================================
                COMPLETE PROMPT (with all plates resolved):
                =================================

                \(cleanPrompt)

                =================================
                END OF PROMPT TO SHORTEN
                =================================
                """

                // Append to shot context
                context.shotContext += lumaPrompt
            }
        }

        // For split shot, add the fully resolved prompt to analyze for splitting
        if conversationIntent == "splitShot" {
            if shot.selectedPromptIndex < shot.promptVariants.count {
                let cleanPrompt = shot.promptVariants[shot.selectedPromptIndex].generateCleanPrompt(
                    for: shot,
                    plateManager: filmManager.plateManager
                )

                // Add the fully resolved prompt to the shot context
                let splitPrompt = """

                =================================
                CURRENT SHOT TO SPLIT
                =================================
                Shot: \(shot.id) - \(shot.title)
                Variant: \(shot.promptVariants[shot.selectedPromptIndex].name)
                Duration: \(shot.duration) seconds
                Current Length: \(cleanPrompt.count) characters

                =================================
                COMPLETE PROMPT (with all plates resolved):
                =================================

                \(cleanPrompt)

                =================================
                ORIGINAL JSON STRUCTURE:
                =================================
                {
                  "shot_id": "\(shot.id)",
                  "title": "\(shot.title)",
                  "duration": \(shot.duration),
                  "sequence_type": "\(shot.sequenceType)",
                  "aspect_ratio": "\(shot.aspectRatio)"
                }

                =================================
                END OF SHOT TO SPLIT
                =================================
                """

                // Append to shot context
                context.shotContext += splitPrompt
            }
        }

        // For VEO3 sanitization, add the fully resolved prompt and VEO3 guidelines
        if conversationIntent == "sanitizeForVEO3" {
            if shot.selectedPromptIndex < shot.promptVariants.count {
                let cleanPrompt = shot.promptVariants[shot.selectedPromptIndex].generateCleanPrompt(
                    for: shot,
                    plateManager: filmManager.plateManager
                )

                // Add the fully resolved prompt to the shot context
                let veo3Prompt = """

                =================================
                FULLY RENDERED PROMPT TO SANITIZE FOR VEO3
                =================================
                Shot: \(shot.id) - \(shot.title)
                Variant: \(shot.promptVariants[shot.selectedPromptIndex].name)
                Current Length: \(cleanPrompt.count) characters
                Sanitization Level: \(veo3SanitizationLevel.uppercased())

                =================================
                BAKED PROMPT (Ready for video generation):
                =================================

                \(cleanPrompt)

                =================================
                END OF PROMPT TO SANITIZE
                =================================

                Remember: This is the fully expanded, baked prompt with all plates resolved - exactly as it would be copied from the "Copy Prompt" button.
                """

                // Append to shot context
                context.shotContext += veo3Prompt
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
            Your task is to shorten the fully resolved prompt to under 1960 characters.

            The fully resolved prompt (with all plates already expanded) is provided at the end of the shot context section.
            Look for "FULLY RESOLVED PROMPT TO SHORTEN" section.

            SHORTENING PRIORITY (in order):
            1. First: ALWAYS remove the entire DIALOGUE section completely
            2. Second: Reduce descriptions in specialized character/environmental plates while preserving master plates for consistency
            3. Third: Remove non-visual descriptions (internal states, metaphors, abstract concepts)
            4. Fourth: Condense without losing information (combine similar elements, use more concise language)
            5. Fifth: Cut the least important pieces for the shot

            OUTPUT REQUIREMENTS:
            - Output the shortened prompt in a clear format
            - Ensure it's under 1960 characters total
            - Preserve as much visual information as possible
            - Maintain the core narrative and visual elements
            - Show the character count at the end

            Please output the shortened prompt ready to paste into Luma Dream Machine.
            """
        case "splitShot":
            return """
            ✂️ INTENT: SPLIT SHOT IN TWO
            Your task is to intelligently split a complex shot into two separate, cohesive prompts.

            ANALYSIS REQUIREMENTS:
            First, analyze why this shot is too complex for a single prompt. Consider:
            - Multiple distinct actions happening in sequence
            - Too many characters with significant interactions
            - Scene transitions or location changes
            - Complex camera movements that need to be separated
            - Temporal shifts (flashbacks, time jumps)
            - Overwhelming visual detail that needs distribution

            SPLITTING STRATEGY:
            1. Identify the natural narrative breakpoint(s) in the shot
            2. Ensure each split maintains:
               - Visual coherence and quality
               - Story continuity and emotional arc
               - Character consistency using the same plates
               - Environmental continuity
            3. Consider the transition between the two shots:
               - How does Shot A end?
               - How does Shot B begin?
               - Is there visual/narrative continuity?

            OUTPUT REQUIREMENTS:
            Provide TWO complete JSON objects for the split shots, each containing:
            {
              "shot_id": "original_id_a" or "original_id_b",
              "title": "Descriptive title for this portion",
              "duration": appropriate_seconds,
              "subject": "Full subject description with plates",
              "action": "Specific actions for this shot",
              "scene": "Scene setting with environmental details",
              "style": "Camera and visual style",
              "dialogue": "If applicable",
              "sounds": "Audio elements",
              "negative_prompt": "What to avoid"
            }

            EXPLANATION SECTION:
            After the JSON outputs, provide:
            1. INTERNAL REASONING: Your analysis of why and how you split the shot
            2. NARRATIVE JUSTIFICATION: How the split preserves story integrity
            3. VISUAL CONTINUITY: How visual consistency is maintained
            4. IMPROVEMENTS: How the split actually enhances the sequence

            Remember: The goal is not just to divide content but to create two powerful,
            focused prompts that together tell the story better than one overwhelming prompt.
            """
        case "sanitizeForVEO3":
            return """
            🛡️ INTENT: SANITIZE FOR VEO3 COMPLIANCE
            Your task is to sanitize the provided FULLY RENDERED PROMPT (not JSON) for VEO3 compliance while preserving as much cinematic quality as possible.

            IMPORTANT: The prompt provided is already fully expanded with all plates resolved - this is the final baked prompt ready for video generation.

            SANITIZATION LEVEL: \(veo3SanitizationLevel.uppercased())

            VEO3 PROHIBITED CONTENT CATEGORIES:

            🚫 COMPLETELY PROHIBITED (Remove entirely):
            - Child safety violations (minors in harmful/sexual contexts)
            - Non-consensual intimate imagery or sexual content
            - Graphic violence with excessive blood/gore
            - Self-harm or suicide content
            - Illegal activities (drug manufacturing, weapons, etc.)
            - Copyrighted characters or intellectual property
            - Real person faces/likenesses without consent
            - Hate symbols or discriminatory content

            ⚠️ LEVEL-DEPENDENT CONTENT:

            LOW SANITIZATION:
            - Keep: Mild violence, tension, atmospheric horror
            - Remove: Only clearly prohibited content above
            - Modify: Soften extremely graphic descriptions

            MEDIUM SANITIZATION:
            - Keep: Tension, psychological elements, mild conflict
            - Remove: Graphic violence, disturbing imagery, intense horror
            - Modify: Replace violent actions with implications or aftermath

            HIGH SANITIZATION:
            - Keep: General drama, mild tension, character interactions
            - Remove: All violence, horror elements, disturbing content
            - Modify: Focus on emotional drama rather than physical conflict

            REPLACEMENT STRATEGIES:
            1. Violence → Implication/aftermath ("after the confrontation")
            2. Gore/blood → Environmental effects ("dark stains", "shadows")
            3. Weapons → Props or tools in non-violent context
            4. Death → "collapse", "stillness", "departure"
            5. Disturbing imagery → Atmospheric tension
            6. Supernatural horror → Mystery or psychological drama

            OUTPUT REQUIREMENTS:

            1. SAVE THE SANITIZED PROMPT:
               - Save the sanitized prompt as a plain text file (.txt)
               - Filename format: shot_[ID]_veo3_sanitized_[level].txt
               - Location: /Users/ingthor/Documents/stories/appdata/veo3_sanitized/
               - Open the file automatically after saving

            2. FORMAT:
               - Output the sanitized prompt in PLAIN TEXT format (NOT JSON)
               - Use the exact same structure as the original prompt:
                 SUBJECT:
                 ACTION:
                 SCENE:
                 STYLE:
                 DIALOGUE: (if present)
                 SOUNDS: (if present)
                 NEGATIVE PROMPT:
                 ASPECT:
                 Meta setting: Iceland, Westfjords 1888

                 video should be all one scene

            3. AFTER THE SANITIZED PROMPT, PROVIDE:
               ========== SANITIZATION REPORT ==========
               Sanitization Level: \(veo3SanitizationLevel)
               Original Length: [X] characters
               Sanitized Length: [Y] characters

               Changes Made:
               - [Specific change 1]
               - [Specific change 2]

               Content Removed:
               - [Category 1]
               - [Category 2]

               Artistic Preservation:
               [How cinematic quality was maintained]

               VEO3 Compliance Confidence: [High/Medium/Low]
               =========================================

            IMPORTANT:
            - Preserve the narrative core and character development
            - Maintain cinematic language and visual style
            - Keep environmental and atmospheric descriptions when safe
            - Explain your reasoning for each major change
            - If unsure about content, err on the side of safety for higher levels
            - CRITICAL: Character master plates should be the LAST resort for modification - only modify them if absolutely necessary for compliance
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