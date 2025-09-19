import Foundation
import SwiftUI
import Combine
// TODO: Uncomment when ClaudeCodeSDK is added as package dependency
// import ClaudeCodeSDK

// MARK: - Claude Context Builder
class ClaudeContextBuilder: ObservableObject {
    @Published var includeCurrentShot = true
    @Published var includeCharacterPlates = true
    @Published var includeEnvironmentalPlates = true
    @Published var includeCinematicGuide = false
    @Published var includeAIGuide = false
    @Published var includeCharacterDepthGuide = false
    @Published var includeResearchDocs = [String: Bool]()

    private let researchDocuments = [
        "final_compaction_doc_and_notes": "/Users/ingthor/Documents/stories/MegaPrompt/compaction/final_compaction_doc_and_notes",
        "condensed_additional_docs": "/Users/ingthor/Documents/stories/MegaPrompt/compaction/condensed_additional_docs",
        "compacted_google_opinions": "/Users/ingthor/Documents/stories/MegaPrompt/compaction/compacted_google_opinions",
        "thinking_notes_compacted": "/Users/ingthor/Documents/stories/MegaPrompt/compaction/thinking_notes_compacted",
        "final_compaction_research": "/Users/ingthor/Documents/stories/MegaPrompt/compaction/final_compaction_research.txt",
        "compacted_old_research": "/Users/ingthor/Documents/stories/MegaPrompt/compaction/compacted_old_research",
        "condensed_cinematic_analysis": "/Users/ingthor/Documents/stories/MegaPrompt/compaction/condensed_cinematic_analysis",
        "compacted_veo_3_guide": "/Users/ingthor/Documents/stories/MegaPrompt/compaction/compacted_veo_3_guide",
        "degradation_protocol": "/Users/ingthor/Documents/stories/Degradation_protocol.txt"
    ]

    init() {
        // Initialize all research docs as included by default
        for (key, _) in researchDocuments {
            includeResearchDocs[key] = true
        }
    }

    func buildContext(for shot: FilmShot, filmManager: FilmManager) -> ClaudeContext {
        var context = ClaudeContext()

        // Add system prompt
        context.systemPrompt = buildSystemPrompt()

        // Add current shot context
        if includeCurrentShot {
            context.shotContext = buildShotContext(shot: shot)
        }

        // Add character plates context
        if includeCharacterPlates {
            context.characterPlatesContext = buildCharacterPlatesContext(filmManager: filmManager)
        }

        // Add environmental plates context
        if includeEnvironmentalPlates {
            context.environmentalPlatesContext = buildEnvironmentalPlatesContext(filmManager: filmManager)
        }

        // Add research documents
        context.researchDocuments = buildResearchDocumentsContext()

        // Add specialty guides
        if includeCinematicGuide {
            context.cinematicGuide = loadCinematicGuide()
        }

        if includeAIGuide {
            context.aiGuide = loadAIGuide()
        }

        if includeCharacterDepthGuide {
            context.characterDepthGuide = loadCharacterDepthGuide()
        }

        return context
    }

    private func buildSystemPrompt() -> String {
        return """
        You are an expert film director, cinematographer, and narrative consultant working on "THE SHEEP IN THE BAÐSTOFA", an Icelandic psychological horror film about family transformation and environmental consciousness.

        CONTEXT OVERVIEW:
        - This is a film management system for creating AI-generated video prompts
        - Each shot has multiple "prompt variants" that describe how to generate the video
        - Character and environmental "plates" provide consistent visual reference for AI generation
        - The film follows a family's transformation from human to sheep-like beings
        - The story involves mathematical impossibilities, house consciousness, and divine intervention

        YOUR ROLE:
        - Help refine existing prompts and create new prompt variants
        - Understand the shot's place in the narrative arc
        - Suggest improvements to camera angles, lighting, and visual composition
        - When creating new variants, provide valid JSON in the exact format shown in context
        - Respect the plate system for character and environmental consistency
        - Understand the progressive transformation themes throughout the film

        PROMPT VARIANT JSON STRUCTURE:
        Each variant needs these fields:
        - variant_id: unique identifier
        - variant_name: descriptive name
        - subject: brief description of main visual elements
        - action: detailed description of what happens in the shot
        - style: camera position, lighting, and visual approach
        - camera_position: specific camera placement description
        - scene: context and setting information
        - dialogue: any spoken words (often empty)
        - selected_plates: array of character and environmental plate IDs
        - available_character_plates: object mapping character names to plate IDs
        - available_environmental_plates: array of environmental plate IDs
        - negative_prompt: things to avoid in generation
        - is_active: boolean (usually false for new variants)

        CHARACTER PLATES SYSTEM:
        Characters progress through transformation states:
        - MAGNUS: AUTHORITY → CONFUSED → PROVIDER → PREDATOR → ENFORCER → RAM
        - SIGRID: PURE → MARKED → CALCULATING → SUMMONING → CORNERED → CORVID → MASTER
        - LILJA: PURE → MATHEMATICAL → HARMONIC → ACCEPTING → EVOLVING → EWE
        - JON: MILD → PROPHET → TEMPORAL → ENERGETIC → LAMB
        - GUDRUN: ABUNDANT → COUNTING → PRODUCING → RITUAL → BEATEN → DIVINE

        ENVIRONMENTAL PLATES SYSTEM:
        House transformation: BAÐSTOFA-DOMESTIC → STIRRING → ORGANIC → BODY → CLEFT → CRYSTALLIZING → CLIFF → MONUMENT
        Sea transformation: SEA-DIVINE → ABUNDANT → EXTRACTED → BATTLE → CONTAMINATED → SEDUCTIVE → ACCUSATION → ETERNAL

        Always consider the narrative context and transformation progression when suggesting improvements or new variants.
        """
    }

    private func buildShotContext(shot: FilmShot) -> String {
        var context = """
        CURRENT SHOT CONTEXT:
        Shot ID: \(shot.id)
        Title: \(shot.title)
        Duration: \(shot.duration) seconds
        Sequence: \(shot.sequenceType)
        Aspect Ratio: \(shot.aspectRatio)
        Position: \(shot.position)%

        PROMPT VARIANTS (\(shot.promptVariants.count) total):
        """

        for (index, variant) in shot.promptVariants.enumerated() {
            let activeStatus = variant.isActive ? " [ACTIVE]" : ""
            let selectedStatus = (index == shot.selectedPromptIndex) ? " [SELECTED]" : ""

            context += """

            --- Variant \(index + 1): \(variant.name)\(activeStatus)\(selectedStatus) ---
            Variant ID: \(variant.variantId)
            Subject: \(variant.subject)
            Action: \(variant.action)
            Style: \(variant.style)
            Scene: \(variant.scene)
            Camera Position: \(variant.cameraPosition)
            Dialogue: \(variant.dialogue)
            Negative Prompt: \(variant.negativePrompt)
            Selected Plates: \(variant.selectedPlateIds.joined(separator: ", "))
            Videos: \(variant.videos.count) files
            Images: \(variant.images.count) files
            """
        }

        return context
    }

    private func buildCharacterPlatesContext(filmManager: FilmManager) -> String {
        let characterPlates = filmManager.plateManager.characterPlates
        var context = """
        CHARACTER PLATES CONTEXT:
        These are the master character plates available for consistent AI generation.
        Each character has multiple transformation states throughout the film.

        CHARACTER PLATES (\(characterPlates.count) total):
        """

        // Group plates by character
        let groupedPlates = Dictionary(grouping: characterPlates) { $0.character }

        for (character, plates) in groupedPlates.sorted(by: { $0.key < $1.key }) {
            context += "\n\n--- \(character.uppercased()) PLATES ---"
            for plate in plates.sorted(by: { $0.plateId < $1.plateId }) {
                context += """

                ID: \(plate.plateId)
                Name: \(plate.name)
                Description: \(plate.description)
                Character: \(plate.character)
                """
            }
        }

        return context
    }

    private func buildEnvironmentalPlatesContext(filmManager: FilmManager) -> String {
        let environmentalPlates = filmManager.plateManager.environmentalPlates
        var context = """
        ENVIRONMENTAL PLATES CONTEXT:
        These are the environmental plates that show the transformation of locations.
        The house (baðstofa) and sea progress through stages matching the narrative.

        ENVIRONMENTAL PLATES (\(environmentalPlates.count) total):
        """

        // Group plates by category
        let groupedPlates = Dictionary(grouping: environmentalPlates) { $0.category }

        for (category, plates) in groupedPlates.sorted(by: { $0.key < $1.key }) {
            context += "\n\n--- \(category.uppercased()) PLATES ---"
            for plate in plates.sorted(by: { $0.plateId < $1.plateId }) {
                context += """

                ID: \(plate.plateId)
                Name: \(plate.name)
                Description: \(plate.description)
                """
            }
        }

        return context
    }

    private func buildResearchDocumentsContext() -> [String: String] {
        var docs = [String: String]()

        for (key, path) in researchDocuments {
            if includeResearchDocs[key] == true {
                if let content = loadFile(at: path) {
                    docs[key] = content
                } else {
                    docs[key] = "Could not load file at: \(path)"
                }
            }
        }

        return docs
    }

    private func loadFile(at path: String) -> String? {
        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            print("Error loading file at \(path): \(error)")
            return nil
        }
    }

    private func loadCinematicGuide() -> String {
        return """
        GENIUS CINEMATIC SHOTS GUIDE:

        - Use impossible camera positions that enhance narrative meaning
        - Employ lighting that reveals psychological states
        - Create compositions that suggest transformation
        - Use depth of field to guide viewer attention
        - Implement camera movement that follows emotional arcs
        - Consider how traditional Icelandic landscape interacts with interior psychology
        - Use shadow and reflection to reveal hidden truths
        - Employ color temperature to indicate supernatural presence
        - Create visual rhythms that match the family's breathing patterns
        - Use architectural elements as narrative metaphors
        """
    }

    private func loadAIGuide() -> String {
        return """
        GENIUS AI VIDEO GENERATION GUIDE:

        - Specify camera positions precisely for AI understanding
        - Use clear subject-action-style structure
        - Provide specific lighting instructions
        - Include material and texture details
        - Specify timing and pacing for actions
        - Use negative prompts to avoid common AI artifacts
        - Describe impossible perspectives clearly for AI interpretation
        - Include atmospheric and environmental details
        - Specify character positioning and interaction clearly
        - Use consistent terminology for AI model recognition
        """
    }

    private func loadCharacterDepthGuide() -> String {
        return """
        GENIUS CHARACTER DEPTH GUIDE:

        - Show internal states through external behavior
        - Use micro-expressions to reveal transformation
        - Create contradiction between human appearance and animal behavior
        - Show family hierarchy through spatial positioning
        - Use breathing patterns to indicate collective consciousness
        - Reveal character psychology through interaction with environment
        - Show transformation progression through subtle physical changes
        - Use eye contact and gaze direction to reveal relationships
        - Employ character-specific movement patterns
        - Create moments of recognition between transformed and untransformed states
        """
    }
}

// MARK: - Claude Context Data Structure
struct ClaudeContext {
    var systemPrompt: String = ""
    var shotContext: String = ""
    var characterPlatesContext: String = ""
    var environmentalPlatesContext: String = ""
    var researchDocuments: [String: String] = [:]
    var cinematicGuide: String = ""
    var aiGuide: String = ""
    var characterDepthGuide: String = ""

    func buildFullPrompt() -> String {
        var prompt = systemPrompt + "\n\n"

        if !shotContext.isEmpty {
            prompt += shotContext + "\n\n"
        }

        if !characterPlatesContext.isEmpty {
            prompt += characterPlatesContext + "\n\n"
        }

        if !environmentalPlatesContext.isEmpty {
            prompt += environmentalPlatesContext + "\n\n"
        }

        if !researchDocuments.isEmpty {
            prompt += "RESEARCH DOCUMENTS:\n"
            for (name, content) in researchDocuments {
                prompt += "=== \(name.uppercased()) ===\n\(content)\n\n"
            }
        }

        if !cinematicGuide.isEmpty {
            prompt += cinematicGuide + "\n\n"
        }

        if !aiGuide.isEmpty {
            prompt += aiGuide + "\n\n"
        }

        if !characterDepthGuide.isEmpty {
            prompt += characterDepthGuide + "\n\n"
        }

        prompt += """
        Please help me improve this shot or create new variants. If you're creating a new prompt variant, provide the complete JSON in the exact format shown above.

        What would you like to discuss about this shot?
        """

        return prompt
    }
}

// MARK: - Claude Integration Manager
class ClaudeIntegrationManager: ObservableObject {
    @Published var isConnecting = false
    @Published var isConnected = false
    @Published var connectionError: String?

    func startClaudeConversation(with context: ClaudeContext) {
        isConnecting = true
        connectionError = nil

        // TODO: Integrate with ClaudeCodeSDK when package is added
        // The SDK integration would look like this:

        /*
        do {
            let claudeSDK = ClaudeCodeSDK()
            let fullPrompt = context.buildFullPrompt()

            // Start a new Claude conversation with the built context
            try claudeSDK.startConversation(
                initialPrompt: fullPrompt,
                title: "Film Manager Context - Shot Discussion"
            )

            DispatchQueue.main.async {
                self.isConnecting = false
                self.isConnected = true
            }
        } catch {
            DispatchQueue.main.async {
                self.isConnecting = false
                self.connectionError = "Failed to start Claude conversation: \(error.localizedDescription)"
            }
        }
        */

        // For now, create a text file with the context and open it
        // This allows you to copy-paste into Claude manually
        do {
            let fullPrompt = context.buildFullPrompt()
            let tempDir = FileManager.default.temporaryDirectory
            let contextFile = tempDir.appendingPathComponent("claude_context_\(Date().timeIntervalSince1970).txt")

            try fullPrompt.write(to: contextFile, atomically: true, encoding: .utf8)

            // Open the file in default text editor
            NSWorkspace.shared.open(contextFile)

            DispatchQueue.main.async {
                self.isConnecting = false
                self.isConnected = true
            }

            print("📝 Claude context saved to: \(contextFile.path)")
            print("📋 Context preview (first 500 chars):")
            print(String(fullPrompt.prefix(500)) + "...")

        } catch {
            DispatchQueue.main.async {
                self.isConnecting = false
                self.connectionError = "Failed to create context file: \(error.localizedDescription)"
            }
        }
    }

    func addPromptVariantToShot(_ variantJSON: String, to shot: inout FilmShot) -> Bool {
        // Parse the JSON and create a new variant manually
        // Note: This is a simplified implementation - in a real app you'd want proper JSON parsing

        guard let jsonData = variantJSON.data(using: .utf8) else {
            print("Failed to convert JSON string to data")
            return false
        }

        do {
            // Parse as a dictionary first
            guard let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                print("Failed to parse JSON as dictionary")
                return false
            }

            // Create a new PromptVariant with the parsed data
            let variant = PromptVariant(
                variantId: jsonDict["variant_id"] as? String ?? "new_variant_\(Date().timeIntervalSince1970)",
                name: jsonDict["variant_name"] as? String ?? "New Variant",
                subject: jsonDict["subject"] as? String ?? "",
                action: jsonDict["action"] as? String ?? "",
                scene: jsonDict["scene"] as? String ?? "",
                style: jsonDict["style"] as? String ?? ""
            )

            // Set additional properties after initialization
            variant.dialogue = jsonDict["dialogue"] as? String ?? ""
            variant.cameraPosition = jsonDict["camera_position"] as? String ?? ""
            variant.negativePrompt = jsonDict["negative_prompt"] as? String ?? ""

            // Set additional properties if they exist
            if let selectedPlates = jsonDict["selected_plates"] as? [String] {
                variant.selectedPlateIds = selectedPlates
            }

            shot.promptVariants.append(variant)
            return true

        } catch {
            print("Error parsing variant JSON: \(error)")
            return false
        }
    }
}