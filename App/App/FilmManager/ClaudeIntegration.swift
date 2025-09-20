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
    @Published var selectedPromptEmphasisDoc: String? = nil  // Which prompt emphasis to include

    private let researchDocuments = [
        "final_compaction_doc_and_notes": "/Users/ingthor/Documents/stories/MegaPrompt/compaction/final_compaction_doc_and_notes",
        "condensed_additional_docs": "/Users/ingthor/Documents/stories/MegaPrompt/compaction/condensed_additional_docs",
        "compacted_google_opinions": "/Users/ingthor/Documents/stories/MegaPrompt/compaction/compacted_google_opinions",
        "thinking_notes_compacted": "/Users/ingthor/Documents/stories/MegaPrompt/compaction/thinking_notes_compacted",
        "final_compaction_research": "/Users/ingthor/Documents/stories/MegaPrompt/compaction/final_compaction_research.txt",
        "compacted_old_research": "/Users/ingthor/Documents/stories/MegaPrompt/compaction/compacted_old_research",
        "condensed_cinematic_analysis": "/Users/ingthor/Documents/stories/MegaPrompt/compaction/condensed_cinematic_analysis",
        "compacted_veo_3_guide": "/Users/ingthor/Documents/stories/MegaPrompt/compaction/compacted_veo_3_guide",
        "degradation_protocol": "/Users/ingthor/Documents/stories/Degradation_protocol.txt",
        "novel": "/Users/ingthor/Documents/stories/MegaPrompt/novel.txt",
        "screenplay1": "/Users/ingthor/Documents/stories/MegaPrompt/screenplay1.txt"
    ]

    // Prompt emphasis documents - different styles for AI generation
    let promptEmphasisDocuments = [
        "AI Impossibility": "/Users/ingthor/Documents/Documents - Ingthor's MacBook Pro (2)/stories/promptTypes/ai_impossibility.txt",
        "Cinematography": "/Users/ingthor/Documents/Documents - Ingthor's MacBook Pro (2)/stories/promptTypes/cinematography.txt",
        "Liquids": "/Users/ingthor/Documents/Documents - Ingthor's MacBook Pro (2)/stories/promptTypes/liquids.txt",
        "Simple": "/Users/ingthor/Documents/Documents - Ingthor's MacBook Pro (2)/stories/promptTypes/simple.txt",
        "Uncanny Body": "/Users/ingthor/Documents/Documents - Ingthor's MacBook Pro (2)/stories/promptTypes/uncanny_body.txt",
        "Dread": "/Users/ingthor/Documents/Documents - Ingthor's MacBook Pro (2)/stories/promptTypes/dread.txt",
        "Weather Atmosphere Tactile": "/Users/ingthor/Documents/Documents - Ingthor's MacBook Pro (2)/stories/promptTypes/weather_atmosphere_tactile.txt"
    ] as [String: String?]

    init() {
        // Initialize research docs - novel and screenplay unchecked by default
        for (key, _) in researchDocuments {
            if key == "novel" || key == "screenplay1" {
                includeResearchDocs[key] = false
            } else {
                includeResearchDocs[key] = true
            }
        }
    }

    func buildContext(for shot: FilmShot, filmManager: FilmManager) -> ClaudeContext {
        var context = ClaudeContext()

        // Add system prompt with comprehensive instructions
        context.systemPrompt = buildSystemPrompt()

        // ALWAYS add the complete movie context for understanding
        context.completeMovieContext = buildCompleteMovieContext(filmManager: filmManager)

        // Add current shot context - THIS IS THE MAIN FOCUS
        if includeCurrentShot {
            context.shotContext = buildShotContext(shot: shot, filmManager: filmManager)
        }

        // Add MASTER character plates (not just current shot's plates)
        if includeCharacterPlates {
            context.characterPlatesContext = buildMasterCharacterPlatesContext(filmManager: filmManager)
        }

        // Add MASTER environmental plates (not just current shot's plates)
        if includeEnvironmentalPlates {
            context.environmentalPlatesContext = buildMasterEnvironmentalPlatesContext(filmManager: filmManager)
        }

        // Add tracking systems for narrative progression
        context.trackingSystemsContext = buildTrackingSystemsContext(filmManager: filmManager)

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

        // Add selected prompt emphasis document
        if let selectedEmphasis = selectedPromptEmphasisDoc,
           selectedEmphasis != "None",
           let path = promptEmphasisDocuments[selectedEmphasis] as? String {
            context.promptEmphasisDoc = loadPromptEmphasisDoc(from: path)
        }

        return context
    }

    private func buildSystemPrompt() -> String {
        return """
        You are an expert at creating Google Veo 3 AI video generation prompts for "THE SHEEP IN THE BAÐSTOFA", an Icelandic psychological horror film about family transformation and environmental consciousness.

        🎬 CRITICAL CONTEXT - THIS IS YOUR PRIMARY TASK:
        You are creating GOOGLE VEO 3 VIDEO GENERATION PROMPTS. These prompts will be fed to Veo 3 AI to generate 8-second video clips.
        You are being shown a SPECIFIC SHOT with one SELECTED PROMPT VARIANT marked with ⭐️.
        CREATE NEW VEO 3 PROMPT VARIATIONS OF THE SELECTED VARIANT ONLY - not the other variants shown.
        The selected variant is your foundation - enhance, vary, or reimagine it for better Veo 3 generation.

        📍 HOW THE PLATE SYSTEM WORKS:
        - Each prompt variant can select from available character and environmental plates
        - Plates are visual references that ensure consistency across AI-generated videos
        - Character plates show specific emotional/transformation states (e.g., MAGNUS-AUTHORITY, SIGRID-CALCULATING)
        - Environmental plates set location and atmosphere (e.g., BAÐSTOFA-ORGANIC, SEA-DIVINE)
        - When you select plates for a prompt, you're telling the AI video generator what visual references to use
        - The selected_plates array in each prompt variant determines which visual elements appear

        ⚡️ IMPORTANT - PLATE INJECTION SYSTEM:
        - The selected plates (character descriptions + environment descriptions) are AUTOMATICALLY INJECTED into the subject field
        - Plates provide BASE descriptions, but you MUST add compelling specifics for THIS shot
        - Focus on what makes THIS MOMENT visually powerful - the horror, drama, transformation
        - The system will combine plate descriptions + your specific details for Veo3

        🔥 CRITICAL VEO 3 DISCOVERY - NEVER SKIP THIS:
        ALWAYS include "(that's where the camera is)" when specifying camera position in the style field.
        This triggers Veo 3's camera-aware processing and dramatically improves results.

        ❌ WRONG: "Close-up shot of Magnus's terrified face"
        ✅ CORRECT: "Close-up shot from across the table (that's where the camera is) capturing Magnus's terrified expression"

        🎯 EMPHASIS ON VISUAL DESCRIPTIONS:
        - ALWAYS provide RICH VISUAL DETAILS in the 'action' and 'scene' fields
        - Describe camera movements, angles, lighting, color grading
        - Include specific visual cues: textures, materials, weather conditions, time of day
        - Reference physical positioning and blocking of characters
        - Describe facial expressions, body language, and subtle movements
        - Include atmospheric details: fog, breath visibility, light quality
        - Specify any visual effects or impossible physics

        🎭 THE FILM'S VISUAL PROGRESSION:
        - Early shots: naturalistic, documentary-style observation
        - Middle shots: reality begins breaking, mathematical impossibilities appear
        - Later shots: full transformation, supernatural elements dominant
        - Camera frost progression: starts at 0%, reaches 35% by end
        - House breathing: 13/min normal, slows to 3/min dying, stops at transformation

        📊 CONTEXT PROVIDED:
        1. CURRENT SHOT - The specific shot we're working on
        2. SELECTED VARIANT (⭐️) - The SPECIFIC prompt variant to create variations of
        3. OTHER VARIANTS - Shown for context only, NOT to be varied unless explicitly requested
        4. ALL MOVIE PROMPTS - Every selected prompt from the entire film for narrative context
        5. MASTER PLATES - Complete character and environmental plate definitions
        6. NARRATIVE SYSTEMS - Tracking systems showing story progression

        ✅ YOUR DELIVERABLES - VEO 3 PROMPT IN JSON FORMAT:
        When creating new Veo 3 prompt variants, provide this EXACT JSON structure that can be copied directly into the app.
        Remember: This will be used to generate 8-second videos in Google Veo 3:

        🔥 CRITICAL - AUTO-SAVE JSON FUNCTIONALITY:
        After providing the JSON, you MUST also save it to a file in the same context folder and open it for the user.
        Use these exact commands after showing the JSON:
        1. Write the JSON to a file named "generated_variant_[timestamp].json" in the current context folder
        2. Open the file automatically for the user with the system open command
        3. This ensures the user can easily access and copy the JSON for use in the app

        ```json
        {
          "variant_id": "shot_number_descriptive_name_v1",
          "variant_name": "Human Readable Variant Name",
          "subject": "The COMPELLING VISUAL that makes this shot work. Include the specific horror/dramatic element, emotional states, key objects, transformations happening. Plates provide base descriptions, you add what makes THIS MOMENT unique. Example: 'Magnus's hands trembling as he discovers the ram's horn has grown through his palm, blood dripping in impossible spirals that match the counting pattern, his mouth forming numbers against his will while Gudrun watches in silent horror'",
          "action": "DETAILED visual action description. Include: camera movements, character blocking, specific timing (e.g., 'at 3 seconds'), transitions, facial expressions, body language, environmental changes. Be EXTREMELY specific about visual elements.",
          "scene": "Location, time of day, weather conditions, atmospheric details. Include: temperature, wind direction/speed, ambient sounds, lighting quality, color palette. Specify exact location in Westfjords if applicable.",
          "style": "Camera work and visual approach. MUST end with '(that's where the camera is)'. Include: lens type (e.g., 14mm ultra-wide), movement style, framing, visual effects, color grading approach.",
          "camera_position": "Specific camera placement and movement path",
          "dialogue": "(Character, tone): \"Spoken words\" (delivery notes, breath visibility, timing) OR empty string if no dialogue",
          "selected_plates": [
            "MAGNUS-AUTHORITY",
            "SIGRID-CALCULATING",
            "BAÐSTOFA-ORGANIC",
            "SEA-DIVINE"
          ],
          "negative_prompt": "no modern elements, no text overlays, no purple in aurora, maintain 1888 authenticity",
          "progressive_state": "House 12/min | Klettagjá none | Contamination 0% | Camera frost 0% | Sorting none | Landvættir sleeping",
          "is_active": false
        }
        ```

        🎯 CRITICAL JSON REQUIREMENTS:
        - **variant_id**: Unique identifier, format: "shotnumber_description_version"
        - **subject**: Composition and action ONLY - plates inject character/environment descriptions automatically
        - **action**: The MAIN visual storytelling - detailed movements, timing, transformations
        - **scene**: Environmental context beyond what plates provide - weather, time, specific conditions
        - **selected_plates**: IMPORTANT - Use the SAME plate IDs as the current variant you're improving UNLESS the narrative specifically requires different character/environment states. The plates maintain visual consistency - don't change them arbitrarily. Look at the current variant's selected_plates array and reuse those exact plate IDs.
        - **style**: MUST end with "(that's where the camera is)"
        - **All fields required**: Use empty string "" if no content
        - **is_active**: Always false for new variants
        - **Proper JSON**: Escape quotes in dialogue, no trailing commas

        📝 FIELD RESPONSIBILITIES WITH PLATE INJECTION:
        Plates provide base character/environment descriptions, but you MUST add compelling specifics:

        - **subject**: The VISUAL HOOK that makes this shot compelling. Include:
          • WHO is in frame and their specific emotional/physical state for THIS moment
          • WHAT makes this shot visually interesting (the key visual element)
          • Specific details that aren't in the plates (wounds, objects held, expressions, transformations)
          • The dramatic/horror element that sells the shot
          • Example: "Magnus's face contorting as invisible mathematics force his mouth to count sheep that don't exist, his jaw moving against his will, terror in his eyes as his body betrays him"

        - **action**: The COMPLETE VISUAL STORY:
          • Detailed movements and their progression
          • Micro-expressions and subtle body language
          • Environmental reactions and changes
          • Physics and material behaviors
          • The narrative arc within the 8-second shot

        - **scene**: FULL ENVIRONMENTAL CONTEXT beyond plates:
          • Exact time, temperature, weather conditions
          • Specific props and their states
          • Lighting conditions and shadows
          • Atmospheric elements (fog, breath visibility, frost)
          • Sounds and ambient details

        - **style**: COMPLETE CAMERA DIRECTION:
          • MUST include "(that's where the camera is)"
          • Shot type, lens choice, movement path
          • Framing, composition, depth of field
          • Visual aesthetic and color grading
          • Any special techniques or effects

        ⚠️ PLATE SELECTION RULE:
        When creating a new variant, DEFAULT to using the SAME selected_plates array as shown in the SELECTED VARIANT (⭐️). Only change plates if:
        1. The narrative explicitly requires a different character state (e.g., MAGNUS moves from AUTHORITY to CONFUSED)
        2. The scene moves to a different location requiring different environmental plates
        3. The user specifically requests different plates
        Otherwise, copy the exact selected_plates array from the current variant to maintain visual consistency.

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

        🎯 ONGOING CONVERSATION WORKFLOW:
        Every time you generate a JSON variant (whether first time or in follow-up conversation):
        1. Display the JSON in a code block for the user to see
        2. IMMEDIATELY save the JSON to "generated_variant_[timestamp].json" in the context folder
        3. AUTOMATICALLY open the saved JSON file for the user
        4. This creates a seamless workflow where users always have easy access to generated JSON files

        When the user asks for "another variant" or "a different version" or continues the conversation about variations:
        - Create a new JSON variant based on their request
        - Save it to a new timestamped file in the same context folder
        - Open the new file automatically
        - Each conversation turn that produces JSON gets its own saved and opened file
        """
    }

    private func buildCompleteMovieContext(filmManager: FilmManager) -> String {
        var movieContext = "🎬 COMPLETE MOVIE CONTEXT - ALL SELECTED PROMPTS\n"
        movieContext += "================================================\n\n"
        movieContext += "This shows every selected prompt from the entire film in sequence.\n"
        movieContext += "Use this to understand narrative flow, visual progression, and continuity.\n\n"

        for shot in filmManager.shots {
            if shot.selectedPromptIndex < shot.promptVariants.count {
                let selectedPrompt = shot.promptVariants[shot.selectedPromptIndex]
                movieContext += "SHOT \(shot.id): \(shot.title) (\(shot.sequenceType))\n"
                movieContext += "Duration: \(shot.duration)s\n"
                movieContext += "Selected Variant: \(selectedPrompt.name)\n"
                movieContext += "Subject: \(selectedPrompt.subject)\n"
                movieContext += "Action: \(selectedPrompt.action)\n"
                movieContext += "Scene: \(selectedPrompt.scene)\n"
                movieContext += "Style: \(selectedPrompt.style)\n"
                movieContext += "Camera: \(selectedPrompt.cameraPosition)\n"
                movieContext += "Dialogue: \(selectedPrompt.dialogue)\n"
                movieContext += "Selected Plates: \(selectedPrompt.selectedPlateIds.joined(separator: ", "))\n"
                movieContext += "Progressive State: \(selectedPrompt.progressiveState)\n"
                movieContext += "---\n\n"
            }
        }

        return movieContext
    }

    private func buildShotContext(shot: FilmShot, filmManager: FilmManager) -> String {
        var context = "🎬 CURRENT SHOT - THIS IS WHAT WE'RE WORKING ON\n"
        context += "================================================\n\n"
        context += "⚠️ PRIMARY DIRECTIVE: We are creating a NEW VARIANT based on the SELECTED prompt below.\n"
        context += "The selected prompt is what needs enhancement/variation. Other variants shown are for context only.\n\n"

        context += "Shot ID: \(shot.id)\n"
        context += "Title: \(shot.title)\n"
        context += "Duration: \(shot.duration) seconds\n"
        context += "Sequence: \(shot.sequenceType)\n"
        context += "Aspect Ratio: \(shot.aspectRatio)\n"
        context += "Position in Film: \(shot.position)%\n"

        // Find previous and next shots in the sorted array
        if let currentIndex = filmManager.shots.firstIndex(where: { $0.id == shot.id }) {
            context += "\n🔄 SHOT CONTEXT IN FILM SEQUENCE:\n"

            // Previous shot
            if currentIndex > 0 {
                let previousShot = filmManager.shots[currentIndex - 1]
                context += "👈 PREVIOUS: Shot \(previousShot.id) - \(previousShot.title) (\(previousShot.sequenceType))\n"
                context += "   See this shot in 'Complete Movie Context' section below\n"
            } else {
                context += "👈 PREVIOUS: [This is the opening shot]\n"
            }

            // Next shot
            if currentIndex < filmManager.shots.count - 1 {
                let nextShot = filmManager.shots[currentIndex + 1]
                context += "👉 NEXT: Shot \(nextShot.id) - \(nextShot.title) (\(nextShot.sequenceType))\n"
                context += "   See this shot in 'Complete Movie Context' section below\n"
            } else {
                context += "👉 NEXT: [This is the final shot]\n"
            }
            context += "\n"
        }

        if !shot.progressiveState.isEmpty {
            context += "Progressive State: \(shot.progressiveState)\n"
        }

        context += "\n🎯 CURRENTLY SELECTED PROMPT VARIANT - THIS IS YOUR STARTING POINT:\n"
        context += "════════════════════════════════════════════════════════════\n"
        context += "⚡️ IMPORTANT: Create a NEW VARIANT based on THIS selected prompt specifically.\n"
        context += "Use this as your foundation - enhance, vary, or reimagine it.\n\n"

        if shot.selectedPromptIndex < shot.promptVariants.count {
            let selectedVariant = shot.promptVariants[shot.selectedPromptIndex]
            context += "⭐️ SELECTED VARIANT TO BUILD FROM: \(selectedVariant.name) ⭐️\n"
            context += "Variant ID: \(selectedVariant.variantId)\n"
            context += "Index: \(shot.selectedPromptIndex + 1) of \(shot.promptVariants.count) total variants\n\n"

            context += "📝 VISUAL ELEMENTS TO ENHANCE/VARY:\n"
            context += "Subject: \(selectedVariant.subject)\n\n"
            context += "Action (KEY VISUAL DESCRIPTION):\n\(selectedVariant.action)\n\n"
            context += "Scene (ENVIRONMENTAL CONTEXT):\n\(selectedVariant.scene)\n\n"
            context += "Style (CINEMATOGRAPHIC APPROACH):\n\(selectedVariant.style)\n\n"
            context += "Camera Position:\n\(selectedVariant.cameraPosition)\n\n"

            if !selectedVariant.dialogue.isEmpty {
                context += "Dialogue:\n\(selectedVariant.dialogue)\n\n"
            }

            context += "Selected Plates: \(selectedVariant.selectedPlateIds.joined(separator: ", "))\n"

            // Add plate breakdown for clarity
            context += "\n🎭 PLATE BREAKDOWN (These get auto-injected into the subject):\n"
            let characterPlates = selectedVariant.selectedPlateIds.filter { plateId in
                plateId.contains("MAGNUS") || plateId.contains("SIGRID") ||
                plateId.contains("LILJA") || plateId.contains("JON") || plateId.contains("GUDRUN")
            }
            let environmentalPlates = selectedVariant.selectedPlateIds.filter { plateId in
                !characterPlates.contains(plateId)
            }

            if !characterPlates.isEmpty {
                context += "  CHARACTER PLATES: \(characterPlates.joined(separator: ", "))\n"
                for plate in characterPlates {
                    if let character = plate.components(separatedBy: "-").first {
                        let state = plate.components(separatedBy: "-").dropFirst().joined(separator: "-")
                        context += "    • \(character) is in \(state) state\n"
                    }
                }
            }

            if !environmentalPlates.isEmpty {
                context += "  ENVIRONMENTAL PLATES: \(environmentalPlates.joined(separator: ", "))\n"
                for plate in environmentalPlates {
                    if let location = plate.components(separatedBy: "-").first {
                        let condition = plate.components(separatedBy: "-").dropFirst().joined(separator: "-")
                        context += "    • \(location) environment in \(condition) state\n"
                    }
                }
            }
            context += "\n"

            if !selectedVariant.negativePrompt.isEmpty {
                context += "Negative Prompt: \(selectedVariant.negativePrompt)\n"
            }

            if !selectedVariant.progressiveState.isEmpty {
                context += "Progressive State: \(selectedVariant.progressiveState)\n"
            }

            context += "\nGenerated Media: \(selectedVariant.videos.count) videos, \(selectedVariant.images.count) images\n"
        }

        context += "\n\n📚 OTHER VARIANTS IN THIS SHOT (SUPPLEMENTARY CONTEXT ONLY):\n"
        context += "───────────────────────────────────────────────────\n"
        context += "⚠️ NOTE: These are shown for context only. They help you understand the shot,\n"
        context += "but you should create variations of the SELECTED variant above, not these.\n"
        context += "Total Variants in Shot: \(shot.promptVariants.count)\n\n"

        for (index, variant) in shot.promptVariants.enumerated() {
            let isSelected = (index == shot.selectedPromptIndex)
            let activeStatus = variant.isActive ? " [ACTIVE]" : ""

            if isSelected {
                context += "════ ⭐️ VARIANT \(index + 1) (THIS IS THE SELECTED ONE - SEE ABOVE) ⭐️ ════\n"
                context += "*** THIS IS THE VARIANT WE'RE CREATING NEW VARIATIONS OF ***\n"
                context += "Full details already shown in the SELECTED PROMPT section above.\n"
            } else {
                context += "──── Variant \(index + 1): \(variant.name)\(activeStatus) [CONTEXT ONLY] ────\n"
                context += "ID: \(variant.variantId)\n"
                context += "Subject: \(String(variant.subject.prefix(150)))\(variant.subject.count > 150 ? "..." : "")\n"
                context += "Action Preview: \(String(variant.action.prefix(200)))\(variant.action.count > 200 ? "..." : "")\n"
                context += "Scene Preview: \(String(variant.scene.prefix(150)))\(variant.scene.count > 150 ? "..." : "")\n"
                context += "Style: \(variant.style)\n"
                context += "Selected Plates: \(variant.selectedPlateIds.joined(separator: ", "))\n"
                context += "Media: \(variant.videos.count) videos, \(variant.images.count) images\n"
            }

            context += "\n"
        }

        return context
    }

    private func buildTrackingSystemsContext(filmManager: FilmManager) -> String {
        var context = "📊 NARRATIVE TRACKING SYSTEMS\n"
        context += "===========================\n\n"
        context += "These systems track the progression of various narrative elements through the film.\n\n"

        for system in filmManager.trackingSystems {
            let percentage = Int(system.currentPercentage)
            let bar = String(repeating: "█", count: percentage / 10) + String(repeating: "░", count: (100 - percentage) / 10)
            context += "\(system.name): \(percentage)%\n"
            context += "  [\(bar)]\n"
            context += "  \(system.description)\n\n"
        }

        return context
    }

    private func buildMasterCharacterPlatesContext(filmManager: FilmManager) -> String {
        var context = "🎭 MASTER CHARACTER PLATES - COMPLETE DEFINITIONS\n"
        context += "==============================================\n\n"
        context += "These are ALL available character plates with their full visual descriptions.\n"
        context += "Select appropriate plates for each prompt variant based on the emotional/transformation state needed.\n\n"

        // Group plates by character
        let characterGroups = [
            "MAGNUS": ["MAGNUS-AUTHORITY", "MAGNUS-CONFUSED", "MAGNUS-PROVIDER", "MAGNUS-PREDATOR", "MAGNUS-ENFORCER", "MAGNUS-RAM"],
            "SIGRID": ["SIGRID-PURE", "SIGRID-OBSERVING", "SIGRID-CALCULATING", "SIGRID-RESISTING", "SIGRID-CORNERED", "SIGRID-TRANSCENDENT"],
            "LILJA": ["LILJA-PURE", "LILJA-CURIOUS", "LILJA-MATHEMATICAL", "LILJA-ACCEPTING", "LILJA-EVOLVED", "LILJA-ORACLE"],
            "JON": ["JON-MILD", "JON-WATCHING", "JON-UNDERSTANDING", "JON-PROPHET", "JON-TEMPORAL", "JON-SEER"],
            "GUDRUN": ["GUDRUN-ABUNDANT", "GUDRUN-SUSPICIOUS", "GUDRUN-COUNTING", "GUDRUN-SUBMISSIVE", "GUDRUN-BEATEN", "GUDRUN-EWE"]
        ]

        let characterPlates = filmManager.plateManager.characterPlates
        for (character, plateIds) in characterGroups {
            context += "\n📍 \(character) PROGRESSION:\n"
            for plateId in plateIds {
                if let plate = characterPlates.first(where: { $0.plateId == plateId }) {
                    context += "\n  \(plateId):\n"
                    context += "    Description: \(plate.description)\n"
                    context += "    Shot Range: \(plate.shotRange)\n"
                }
            }
            context += "\n"
        }

        return context
    }


    private func buildMasterEnvironmentalPlatesContext(filmManager: FilmManager) -> String {
        var context = "🏔️ MASTER ENVIRONMENTAL PLATES - COMPLETE DEFINITIONS\n"
        context += "================================================\n\n"
        context += "These are MASTER environmental plates with their full atmospheric descriptions.\n"
        context += "Select appropriate plates to establish location, mood, and environmental progression.\n\n"

        // Filter for only master plates (containing "-MASTER" in plateId)
        let allEnvPlates = filmManager.plateManager.environmentalPlates
        let masterPlates = allEnvPlates.filter { $0.plateId.contains("-MASTER") }

        // Group master plates by category
        var platesByCategory: [String: [EnvironmentalPlate]] = [:]
        for plate in masterPlates {
            let category = plate.category ?? "Other"
            if platesByCategory[category] == nil {
                platesByCategory[category] = []
            }
            platesByCategory[category]?.append(plate)
        }

        // Output plates grouped by category
        for (category, plates) in platesByCategory.sorted(by: { $0.key < $1.key }) {
            context += "\n🌍 \(category):\n"
            for plate in plates.sorted(by: { $0.plateId < $1.plateId }) {
                context += "\n  \(plate.plateId):\n"
                context += "    Description: \(plate.description)\n"
                context += "    Atmosphere: \(plate.atmosphere)\n"
                context += "    Category: \(plate.category ?? "N/A")\n"
            }
            context += "\n"
        }

        // If no master plates found, include all the predefined environmental progression plates
        if masterPlates.isEmpty {
            context += "\n📌 Note: No master environmental plates found. Showing environmental progressions:\n\n"

            // Group plates by location/type
            let environmentGroups = [
                "BAÐSTOFA (House Interior)": [
                    "BAÐSTOFA-DOMESTIC", "BAÐSTOFA-STIRRING", "BAÐSTOFA-ORGANIC",
                    "BAÐSTOFA-BODY", "BAÐSTOFA-CLEFT", "BAÐSTOFA-CRYSTALLIZING",
                    "BAÐSTOFA-CLIFF", "BAÐSTOFA-MONUMENT"
                ],
                "SEA": [
                    "SEA-DIVINE", "SEA-ABUNDANT", "SEA-EXTRACTED", "SEA-BATTLE",
                    "SEA-CONTAMINATED", "SEA-SEDUCTIVE", "SEA-ACCUSATION", "SEA-ETERNAL"
                ],
                "WESTFJORDS": [
                    "WESTFJORDS-SUMMER", "WESTFJORDS-AUTUMN", "WESTFJORDS-WINTER",
                    "WESTFJORDS-IMPOSSIBLE", "WESTFJORDS-BEACH", "WESTFJORDS-CLIFF",
                    "WESTFJORDS-SETTLEMENT", "WESTFJORDS-ETERNAL"
                ],
                "SPECIALIZED": [
                    "STOFA-FORMAL", "STOFA-BREATHING", "STOFA-RECORDING", "STOFA-DISSOLVING",
                    "TILBERI-CORNER", "TILBERI-ACTIVE", "TILBERI-MULTIPLYING", "TILBERI-CONSUMING",
                    "POLYNYA-FORMING", "POLYNYA-BREATHING", "POLYNYA-CALLING", "POLYNYA-ETERNAL",
                    "TRAWLER-DISTANT", "TRAWLER-APPROACHING", "TRAWLER-CIRCLING", "TRAWLER-ETERNAL"
                ]
            ]

            for (groupName, plateIds) in environmentGroups {
                context += "\n🌍 \(groupName):\n"
                for plateId in plateIds {
                    if let plate = allEnvPlates.first(where: { $0.plateId == plateId }) {
                        context += "\n  \(plateId):\n"
                        context += "    Description: \(plate.description)\n"
                        context += "    Atmosphere: \(plate.atmosphere)\n"
                        context += "    Category: \(plate.category ?? "N/A")\n"
                    }
                }
                context += "\n"
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

    private func loadPromptEmphasisDoc(from path: String) -> String {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return ""
        }
        return """
        🎯 PROMPT EMPHASIS DOCUMENT
        ========================
        This document provides specific style emphasis for AI video generation.
        Apply these guidelines to all prompt variants.

        \(content)
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
    var completeMovieContext: String = ""  // ALL selected prompts from entire movie
    var shotContext: String = ""  // Current shot we're working on with ALL its variants
    var characterPlatesContext: String = ""  // Master character plates
    var environmentalPlatesContext: String = ""  // Master environmental plates
    var trackingSystemsContext: String = ""  // Narrative progression tracking
    var researchDocuments: [String: String] = [:]
    var cinematicGuide: String = ""
    var aiGuide: String = ""
    var characterDepthGuide: String = ""
    var promptEmphasisDoc: String = ""  // Selected prompt emphasis document

    func buildFullPrompt() -> String {
        var prompt = systemPrompt + "\n\n"

        // First show the current shot context - THIS IS THE FOCUS
        if !shotContext.isEmpty {
            prompt += shotContext + "\n\n"
        }

        // Then show the complete movie for context
        if !completeMovieContext.isEmpty {
            prompt += completeMovieContext + "\n\n"
        }

        // Add master plates
        if !characterPlatesContext.isEmpty {
            prompt += characterPlatesContext + "\n\n"
        }

        if !environmentalPlatesContext.isEmpty {
            prompt += environmentalPlatesContext + "\n\n"
        }

        // Add tracking systems
        if !trackingSystemsContext.isEmpty {
            prompt += trackingSystemsContext + "\n\n"
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

        if !promptEmphasisDoc.isEmpty {
            prompt += promptEmphasisDoc + "\n\n"
        }

        prompt += """
        Please help me improve this shot or create new variants. If you're creating a new prompt variant, provide the complete JSON in the exact format shown above.

        What would you like to discuss about this shot?
        """

        return prompt
    }

    func buildMainPromptWithoutBulkData() -> String {
        var prompt = ""

        // Add system prompt first
        if !systemPrompt.isEmpty {
            prompt += systemPrompt + "\n\n"
        }

        // Add reference to separate files
        prompt += "📁 CONTEXT FILES STRUCTURE:\n"
        prompt += "================================\n"
        prompt += "⚠️ CRITICAL: YOU MUST READ ALL FILES IN THIS FOLDER COMPLETELY AND FULLY ⚠️\n"
        prompt += "Do NOT skim or partially read. Every file contains essential information.\n\n"
        prompt += "This folder contains multiple files with different aspects of the context:\n\n"
        prompt += "• 01a_complete_movie_shots_part1.json - First part of all shots as JSON (READ FULLY)\n"
        prompt += "• 01b_complete_movie_shots_part2.json - Second part of all shots as JSON (READ FULLY)\n"
        prompt += "• 01c_complete_movie_shots_part3.json - Third part of all shots as JSON (READ FULLY)\n"
        prompt += "• 01d_complete_movie_shots_part4.json - Fourth part of all shots as JSON (READ FULLY)\n"
        prompt += "• 01e_complete_movie_shots_part5.json - Fifth part of all shots as JSON (READ FULLY)\n"
        prompt += "• 02_all_plates.md - Complete character and environmental plate definitions (READ FULLY)\n"
        prompt += "• 03_current_shot.md - The shot we're currently working on (PRIMARY FOCUS - READ FULLY)\n"
        prompt += "• 04_cinematic_guide.md - Cinematic shot creation guide (if included - READ FULLY)\n"
        prompt += "• 05_ai_generation_guide.md - AI video generation guide (if included - READ FULLY)\n"
        prompt += "• 06_character_depth_guide.md - Character depth guide (if included - READ FULLY)\n"

        // Only mention prompt emphasis if it exists
        if !promptEmphasisDoc.isEmpty {
            prompt += "• 07_prompt_emphasis_ESSENTIAL.md - CRITICAL style guide for new variants (MUST READ AND FOLLOW)\n"
        }

        prompt += "• research_documents/ - Additional research materials folder (READ ALL FILES INSIDE FULLY)\n\n"
        prompt += "🔴 READING ORDER AND REQUIREMENTS:\n"
        prompt += "1. FIRST: Read 03_current_shot.md COMPLETELY - this is the shot we're working on\n"

        // Add prompt emphasis as priority if it exists
        if !promptEmphasisDoc.isEmpty {
            prompt += "2. CRITICAL: Read 07_prompt_emphasis_ESSENTIAL.md COMPLETELY - this defines how to create new variants\n"
            prompt += "3. THIRD: Read 01a_complete_movie_shots_part1.json COMPLETELY\n"
            prompt += "4. FOURTH: Read 01b_complete_movie_shots_part2.json COMPLETELY\n"
            prompt += "5. FIFTH: Read 01c_complete_movie_shots_part3.json COMPLETELY\n"
            prompt += "6. SIXTH: Read 01d_complete_movie_shots_part4.json COMPLETELY\n"
            prompt += "7. SEVENTH: Read 01e_complete_movie_shots_part5.json COMPLETELY\n"
            prompt += "8. EIGHTH: Read 02_all_plates.md COMPLETELY to understand available plates\n"
            prompt += "9. NINTH: Read ALL files in research_documents/ folder COMPLETELY if present\n"
            prompt += "10. THEN: Read all other numbered files (04, 05, 06) COMPLETELY if present\n\n"
        } else {
            prompt += "2. SECOND: Read 01a_complete_movie_shots_part1.json COMPLETELY\n"
            prompt += "3. THIRD: Read 01b_complete_movie_shots_part2.json COMPLETELY\n"
            prompt += "4. FOURTH: Read 01c_complete_movie_shots_part3.json COMPLETELY\n"
            prompt += "5. FIFTH: Read 01d_complete_movie_shots_part4.json COMPLETELY\n"
            prompt += "6. SIXTH: Read 01e_complete_movie_shots_part5.json COMPLETELY\n"
            prompt += "7. SEVENTH: Read 02_all_plates.md COMPLETELY to understand available plates\n"
            prompt += "8. EIGHTH: Read ALL files in research_documents/ folder COMPLETELY if present\n"
            prompt += "9. THEN: Read all other numbered files (04, 05, 06) COMPLETELY if present\n\n"
        }
        prompt += "⚠️ DO NOT PROCEED until you have read ALL files FULLY. The movie context is split into five JSON parts (01a through 01e) to handle file size limits - you MUST read ALL FIVE parts in order. The research_documents folder contains critical story and character analysis that you MUST read.\n\n"

        // Add tracking systems (smaller, keep in main file)
        if !trackingSystemsContext.isEmpty {
            prompt += trackingSystemsContext + "\n\n"
        }

        return prompt
    }
}

// MARK: - Terminal Helper Functions
extension Process {
    func which(_ command: String) -> String? {
        // First check common locations directly
        let commonPaths = [
            "/opt/homebrew/bin/\(command)",  // Apple Silicon homebrew
            "/usr/local/bin/\(command)",      // Intel homebrew
            "/usr/bin/\(command)",
            "/bin/\(command)"
        ]

        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        // Fallback to using which with full PATH
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["bash", "-l", "-c", "which \(command)"]

        let pipe = Pipe()
        process.standardOutput = pipe

        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()

        if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
            return path
        }
        return nil
    }
}

func openTerminalWithAI(aiCommand: String, instructions: String) -> Bool {
    // First, find the AI executable
    guard let aiPath = Process().which(aiCommand) else {
        print("❌ Error: '\(aiCommand)' command not found in PATH")
        print("Please ensure \(aiCommand) CLI is installed and in your PATH")
        print("Checked locations: /opt/homebrew/bin/\(aiCommand), /usr/local/bin/\(aiCommand)")
        return false
    }

    print("✅ Found \(aiCommand) at: \(aiPath)")

    // Create a script that will run the AI with the initial prompt
    let tempDir = FileManager.default.temporaryDirectory
    let timestamp = Int(Date().timeIntervalSince1970)

    // Escape double quotes in the instructions for the shell script
    let escapedInstructions = instructions
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "$", with: "\\$")
        .replacingOccurrences(of: "`", with: "\\`")

    // Create a bash script that launches the AI interactively with the initial prompt
    let scriptContent = """
    #!/bin/bash
    echo "🚀 Starting \(aiCommand) with context instructions..."
    echo "========================================="
    echo ""

    # Start AI interactively with the initial prompt as an argument
    # Claude needs --dangerously-skip-permissions
    # Gemini needs -i flag for interactive mode and --yolo
    if [ "\(aiCommand)" = "claude" ]; then
        '\(aiPath)' --dangerously-skip-permissions "\(escapedInstructions)"
    elif [ "\(aiCommand)" = "gemini" ]; then
        '\(aiPath)' -i --yolo "\(escapedInstructions)"
    else
        '\(aiPath)' "\(escapedInstructions)"
    fi

    # Keep terminal open after AI exits
    echo ""
    echo "\(aiCommand) session ended. Press any key to close this terminal."
    read -n 1
    """

    do {
        let scriptFile = tempDir.appendingPathComponent("\(aiCommand)_launcher_\(timestamp).sh")
        try scriptContent.write(to: scriptFile, atomically: true, encoding: .utf8)

        // Make script executable
        let chmodProcess = Process()
        chmodProcess.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmodProcess.arguments = ["+x", scriptFile.path]
        try chmodProcess.run()
        chmodProcess.waitUntilExit()

        // Use 'open' to launch Terminal with the script
        let openProcess = Process()
        openProcess.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        openProcess.arguments = [
            "-a", "Terminal.app",
            scriptFile.path
        ]

        try openProcess.run()

        // Clean up temp file after a delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 60) {
            try? FileManager.default.removeItem(at: scriptFile)
        }

        print("🚀 Launched Terminal with \(aiCommand) script: \(scriptFile.path)")
        return true

    } catch {
        print("❌ Error: \(error)")
        return false
    }
}

// Legacy function for backward compatibility
func openTerminalWithClaudeAndInstructions(instructions: String) -> Bool {
    return openTerminalWithAI(aiCommand: "claude", instructions: instructions)
}

// Original specific Claude function (can be removed if not used elsewhere)
func openTerminalWithClaudeAndInstructionsOld(instructions: String) -> Bool {
    // First, find the claude executable
    guard let claudePath = Process().which("claude") else {
        print("❌ Error: 'claude' command not found in PATH")
        print("Please ensure Claude CLI is installed and in your PATH")
        print("Checked locations: /opt/homebrew/bin/claude, /usr/local/bin/claude")
        return false
    }

    print("✅ Found Claude at: \(claudePath)")

    // Create a script that will run Claude with the initial prompt
    let tempDir = FileManager.default.temporaryDirectory
    let timestamp = Int(Date().timeIntervalSince1970)

    // Escape double quotes in the instructions for the shell script
    let escapedInstructions = instructions
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "$", with: "\\$")
        .replacingOccurrences(of: "`", with: "\\`")

    // Create a bash script that launches Claude interactively with the initial prompt
    let scriptContent = """
    #!/bin/bash
    echo "🚀 Starting Claude with context instructions..."
    echo "========================================="
    echo ""

    # Start Claude interactively with the initial prompt as an argument
    '\(claudePath)' --dangerously-skip-permissions "\(escapedInstructions)"

    # Keep terminal open after Claude exits
    echo ""
    echo "Claude session ended. Press any key to close this terminal."
    read -n 1
    """

    do {
        let scriptFile = tempDir.appendingPathComponent("claude_launcher_\(timestamp).sh")
        try scriptContent.write(to: scriptFile, atomically: true, encoding: .utf8)

        // Make script executable
        let chmodProcess = Process()
        chmodProcess.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmodProcess.arguments = ["+x", scriptFile.path]
        try chmodProcess.run()
        chmodProcess.waitUntilExit()

        // Use 'open' to launch Terminal with the script
        let openProcess = Process()
        openProcess.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        openProcess.arguments = [
            "-a", "Terminal.app",
            scriptFile.path
        ]

        try openProcess.run()

        // Clean up temp file after a delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 60) {
            try? FileManager.default.removeItem(at: scriptFile)
        }

        print("🚀 Launched Terminal with Claude script: \(scriptFile.path)")
        return true
    } catch {
        print("❌ Error launching terminal with Claude: \(error)")
        return false
    }
}

// MARK: - Claude Integration Manager
class ClaudeIntegrationManager: ObservableObject {
    @Published var isConnecting = false
    @Published var isConnected = false
    @Published var connectionError: String?
    @Published var contextFolderPath: String?

    func startClaudeConversation(with context: ClaudeContext, filmManager: FilmManager, userInstructions: String = "") {
        isConnecting = true
        connectionError = nil
        contextFolderPath = nil

        // Create a comprehensive context folder with all necessary files
        do {
            // Create a unique folder for this Claude session in user's tmp directory
            let timestamp = Date().timeIntervalSince1970
            let userTmpDir = URL(fileURLWithPath: "/Users/ingthor/tmp")

            // Create the tmp directory if it doesn't exist
            try FileManager.default.createDirectory(at: userTmpDir, withIntermediateDirectories: true, attributes: nil)

            let sessionFolder = userTmpDir.appendingPathComponent("claude_film_context_\(Int(timestamp))")

            try FileManager.default.createDirectory(at: sessionFolder, withIntermediateDirectories: true, attributes: nil)

            // Write main instructions/context file (without the complete movie)
            let mainContextFile = sessionFolder.appendingPathComponent("00_MAIN_CONTEXT.md")
            let mainPromptWithoutMovie = context.buildMainPromptWithoutBulkData()
            try mainPromptWithoutMovie.write(to: mainContextFile, atomically: true, encoding: .utf8)

            // 01 - Write complete movie context split into five JSON files for size management
            if !filmManager.shots.isEmpty {
                let allShots = filmManager.shots
                let partSize = max(1, allShots.count / 5)

                for part in 0..<5 {
                    let startIndex = part * partSize
                    let endIndex = (part == 4) ? allShots.count : min((part + 1) * partSize, allShots.count)

                    guard startIndex < allShots.count else { break }

                    let shotsInPart = Array(allShots[startIndex..<endIndex])
                    var shotJsonArray: [[String: Any]] = []

                    for shot in shotsInPart {
                        if shot.selectedPromptIndex < shot.promptVariants.count {
                            let selectedPrompt = shot.promptVariants[shot.selectedPromptIndex]
                            let shotJson: [String: Any] = [
                                "shot_id": shot.id,
                                "shot_title": shot.title,
                                "sequence_type": shot.sequenceType,
                                "duration": shot.duration,
                                "aspect_ratio": shot.aspectRatio,
                                "position": shot.position,
                                "progressive_state": shot.progressiveState,
                                "selected_variant": [
                                    "variant_id": selectedPrompt.variantId,
                                    "variant_name": selectedPrompt.name,
                                    "subject": selectedPrompt.subject,
                                    "action": selectedPrompt.action,
                                    "scene": selectedPrompt.scene,
                                    "style": selectedPrompt.style,
                                    "camera_position": selectedPrompt.cameraPosition,
                                    "dialogue": selectedPrompt.dialogue,
                                    "selected_plates": selectedPrompt.selectedPlateIds,
                                    "negative_prompt": selectedPrompt.negativePrompt,
                                    "progressive_state": selectedPrompt.progressiveState,
                                    "is_active": selectedPrompt.isActive
                                ]
                            ]
                            shotJsonArray.append(shotJson)
                        }
                    }

                    let partData: [String: Any] = [
                        "part_info": [
                            "part_number": part + 1,
                            "total_parts": 5,
                            "description": "Complete movie context - Part \(part + 1) of 5. This contains selected prompt variants from shots \(startIndex + 1) to \(endIndex) of the entire film."
                        ],
                        "shots": shotJsonArray
                    ]

                    if let jsonData = try? JSONSerialization.data(withJSONObject: partData, options: [.prettyPrinted, .sortedKeys]) {
                        let partLetter = String(UnicodeScalar(97 + part)!) // a, b, c, d, e
                        let movieFile = sessionFolder.appendingPathComponent("01\(partLetter)_complete_movie_shots_part\(part + 1).json")
                        try jsonData.write(to: movieFile)
                    }
                }
            }

            // 02 - Write all plates (character and environmental) in one file
            var platesContent = ""
            if !context.characterPlatesContext.isEmpty {
                platesContent += context.characterPlatesContext + "\n\n"
            }
            if !context.environmentalPlatesContext.isEmpty {
                platesContent += context.environmentalPlatesContext
            }
            if !platesContent.isEmpty {
                let platesFile = sessionFolder.appendingPathComponent("02_all_plates.md")
                try platesContent.write(to: platesFile, atomically: true, encoding: .utf8)
            }

            // 03 - Write current shot context
            if !context.shotContext.isEmpty {
                let shotFile = sessionFolder.appendingPathComponent("03_current_shot.md")
                try context.shotContext.write(to: shotFile, atomically: true, encoding: .utf8)
            }

            // Write research documents
            if !context.researchDocuments.isEmpty {
                let researchFolder = sessionFolder.appendingPathComponent("research_documents")
                try FileManager.default.createDirectory(at: researchFolder, withIntermediateDirectories: true, attributes: nil)

                for (name, content) in context.researchDocuments {
                    let docFile = researchFolder.appendingPathComponent("\(name).txt")
                    try content.write(to: docFile, atomically: true, encoding: .utf8)
                }
            }

            // Write enhancement guides
            if !context.cinematicGuide.isEmpty {
                let cinematicFile = sessionFolder.appendingPathComponent("04_cinematic_guide.md")
                try context.cinematicGuide.write(to: cinematicFile, atomically: true, encoding: .utf8)
            }

            if !context.aiGuide.isEmpty {
                let aiFile = sessionFolder.appendingPathComponent("05_ai_generation_guide.md")
                try context.aiGuide.write(to: aiFile, atomically: true, encoding: .utf8)
            }

            if !context.characterDepthGuide.isEmpty {
                let depthFile = sessionFolder.appendingPathComponent("06_character_depth_guide.md")
                try context.characterDepthGuide.write(to: depthFile, atomically: true, encoding: .utf8)
            }

            // Write prompt emphasis if selected - CRITICAL for new variants
            if !context.promptEmphasisDoc.isEmpty {
                var emphasisContent = "🎯 PROMPT EMPHASIS STYLE - CRITICAL FOR NEW VARIANTS\n"
                emphasisContent += "================================================\n\n"
                emphasisContent += "⚠️ ESSENTIAL: This emphasis style was specifically selected to guide the creation of new prompt variants.\n"
                emphasisContent += "The new prompts MUST heavily incorporate the stylistic elements, focus areas, and techniques described below.\n"
                emphasisContent += "This is not optional guidance - it is the PRIMARY DIRECTIVE for how new variants should be crafted.\n\n"
                emphasisContent += "When creating new prompt variants:\n"
                emphasisContent += "1. PRIORITIZE the emphasis elements below in your descriptions\n"
                emphasisContent += "2. FOCUS on the specific aspects this style highlights\n"
                emphasisContent += "3. INTEGRATE these techniques throughout all prompt fields\n"
                emphasisContent += "4. ENSURE the variant strongly reflects this chosen emphasis\n\n"
                emphasisContent += "---\n\n"
                emphasisContent += context.promptEmphasisDoc

                let emphasisFile = sessionFolder.appendingPathComponent("07_prompt_emphasis_ESSENTIAL.md")
                try emphasisContent.write(to: emphasisFile, atomically: true, encoding: .utf8)
            }

            // Prepare the Claude instruction text
            var claudeInstruction = ""

            // Add user instructions at the top if provided
            if !userInstructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                claudeInstruction += """
                🎯 USER'S SPECIFIC INSTRUCTIONS FOR THIS SESSION:
                Pay special attention to these user requirements:

                \(userInstructions.trimmingCharacters(in: .whitespacesAndNewlines))

                ========================================

                """
            }

            claudeInstruction += """
            Please read through all the context files in this folder completely:
            \(sessionFolder.path)

            Start by reading 00_MAIN_CONTEXT.md first for comprehensive instructions, then read ALL other files in their numbered order:
            - 03_current_shot.md (PRIMARY FOCUS - read this first after main context)
            """

            if !context.promptEmphasisDoc.isEmpty {
                claudeInstruction += "\n- 07_prompt_emphasis_ESSENTIAL.md (CRITICAL - defines how to create new variants)"
            }

            claudeInstruction += """

            - 01a_complete_movie_shots_part1.json (first part of shots as JSON)
            - 01b_complete_movie_shots_part2.json (second part of shots as JSON)
            - 01c_complete_movie_shots_part3.json (third part of shots as JSON)
            - 01d_complete_movie_shots_part4.json (fourth part of shots as JSON)
            - 01e_complete_movie_shots_part5.json (fifth part of shots as JSON)
            - 02_all_plates.md
            - research_documents/ folder (read ALL files inside)
            - Any other numbered files (04, 05, 06)

            Pay special attention to the current shot details and the plate system for creating new prompt variants.
            """

            // Open Terminal, start Claude, and execute the instruction automatically
            let success = openTerminalWithClaudeAndInstructions(instructions: claudeInstruction)

            if success {
                print("🚀 Terminal opened with Claude started and instructions sent!")
            } else {
                print("❌ Failed to open terminal, using fallback")
                // Fallback: open folder in Finder and copy to clipboard
                NSWorkspace.shared.selectFile(mainContextFile.path, inFileViewerRootedAtPath: sessionFolder.path)
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(claudeInstruction, forType: .string)
                print("📋 Fallback: Opened folder in Finder and copied instructions to clipboard")
            }

            DispatchQueue.main.async {
                self.isConnecting = false
                self.isConnected = true
                self.contextFolderPath = sessionFolder.path
            }

            print("📁 Claude context folder created: \(sessionFolder.path)")
            print("📋 Folder path copied to clipboard!")
            print("📝 Files created:")
            let files = try FileManager.default.contentsOfDirectory(at: sessionFolder, includingPropertiesForKeys: nil)
            for file in files {
                print("  - \(file.lastPathComponent)")
            }

        } catch {
            DispatchQueue.main.async {
                self.isConnecting = false
                self.connectionError = "Failed to create context folder: \(error.localizedDescription)"
            }
        }
    }

    func startGeminiConversation(with context: ClaudeContext, filmManager: FilmManager, userInstructions: String = "") {
        isConnecting = true
        connectionError = nil
        contextFolderPath = nil

        // Create a comprehensive context folder with all necessary files
        do {
            // Create a unique folder for this Gemini session in user's tmp directory
            let timestamp = Date().timeIntervalSince1970
            let userTmpDir = URL(fileURLWithPath: "/Users/ingthor/tmp")

            // Create the tmp directory if it doesn't exist
            try FileManager.default.createDirectory(at: userTmpDir, withIntermediateDirectories: true, attributes: nil)

            let sessionFolder = userTmpDir.appendingPathComponent("gemini_film_context_\(Int(timestamp))")

            try FileManager.default.createDirectory(at: sessionFolder, withIntermediateDirectories: true, attributes: nil)

            // Write all the same context files as Claude
            // (reusing the same file creation logic)
            createContextFiles(context: context, filmManager: filmManager, sessionFolder: sessionFolder)

            // Prepare the Gemini instruction text
            var geminiInstruction = ""

            // Add user instructions at the top if provided
            if !userInstructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                geminiInstruction += """
                🎯 USER'S SPECIFIC INSTRUCTIONS FOR THIS SESSION:
                Pay special attention to these user requirements:

                \(userInstructions.trimmingCharacters(in: .whitespacesAndNewlines))

                ========================================

                """
            }

            geminiInstruction += """
            Please read through all the context files in this folder completely:
            \(sessionFolder.path)

            Start by reading 00_MAIN_CONTEXT.md first for comprehensive instructions, then read ALL other files in their numbered order.
            Pay special attention to the current shot details and the plate system for creating new prompt variants.
            """

            // Open Terminal and start Gemini
            let success = openTerminalWithAI(aiCommand: "gemini", instructions: geminiInstruction)

            if success {
                print("🚀 Terminal opened with Gemini started and instructions sent!")
            } else {
                print("❌ Failed to open terminal with Gemini, using fallback")
                // Fallback: open folder in Finder and copy to clipboard
                let mainContextFile = sessionFolder.appendingPathComponent("00_MAIN_CONTEXT.md")
                NSWorkspace.shared.selectFile(mainContextFile.path, inFileViewerRootedAtPath: sessionFolder.path)
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(geminiInstruction, forType: .string)
                print("📋 Fallback: Opened folder in Finder and copied instructions to clipboard")
            }

            DispatchQueue.main.async {
                self.isConnecting = false
                self.isConnected = true
                self.contextFolderPath = sessionFolder.path
            }

            print("📁 Gemini context folder created: \(sessionFolder.path)")

        } catch {
            DispatchQueue.main.async {
                self.isConnecting = false
                self.connectionError = "Failed to create context folder: \(error.localizedDescription)"
            }
        }
    }

    func startCodexConversation(with context: ClaudeContext, filmManager: FilmManager, userInstructions: String = "") {
        isConnecting = true
        connectionError = nil
        contextFolderPath = nil

        // Create a comprehensive context folder with all necessary files
        do {
            // Create a unique folder for this Codex session in user's tmp directory
            let timestamp = Date().timeIntervalSince1970
            let userTmpDir = URL(fileURLWithPath: "/Users/ingthor/tmp")

            // Create the tmp directory if it doesn't exist
            try FileManager.default.createDirectory(at: userTmpDir, withIntermediateDirectories: true, attributes: nil)

            let sessionFolder = userTmpDir.appendingPathComponent("codex_film_context_\(Int(timestamp))")

            try FileManager.default.createDirectory(at: sessionFolder, withIntermediateDirectories: true, attributes: nil)

            // Write all the same context files as Claude
            createContextFiles(context: context, filmManager: filmManager, sessionFolder: sessionFolder)

            // Prepare the Codex instruction text
            var codexInstruction = ""

            // Add user instructions at the top if provided
            if !userInstructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                codexInstruction += """
                🎯 USER'S SPECIFIC INSTRUCTIONS FOR THIS SESSION:
                Pay special attention to these user requirements:

                \(userInstructions.trimmingCharacters(in: .whitespacesAndNewlines))

                ========================================

                """
            }

            codexInstruction += """
            Please read through all the context files in this folder completely:
            \(sessionFolder.path)

            Start by reading 00_MAIN_CONTEXT.md first for comprehensive instructions, then read ALL other files in their numbered order.
            Pay special attention to the current shot details and the plate system for creating new prompt variants.
            """

            // Open Terminal and start Codex
            let success = openTerminalWithAI(aiCommand: "codex", instructions: codexInstruction)

            if success {
                print("🚀 Terminal opened with Codex started and instructions sent!")
            } else {
                print("❌ Failed to open terminal with Codex, using fallback")
                // Fallback: open folder in Finder and copy to clipboard
                let mainContextFile = sessionFolder.appendingPathComponent("00_MAIN_CONTEXT.md")
                NSWorkspace.shared.selectFile(mainContextFile.path, inFileViewerRootedAtPath: sessionFolder.path)
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(codexInstruction, forType: .string)
                print("📋 Fallback: Opened folder in Finder and copied instructions to clipboard")
            }

            DispatchQueue.main.async {
                self.isConnecting = false
                self.isConnected = true
                self.contextFolderPath = sessionFolder.path
            }

            print("📁 Codex context folder created: \(sessionFolder.path)")

        } catch {
            DispatchQueue.main.async {
                self.isConnecting = false
                self.connectionError = "Failed to create context folder: \(error.localizedDescription)"
            }
        }
    }

    private func createContextFiles(context: ClaudeContext, filmManager: FilmManager, sessionFolder: URL) {
        do {
            // Write main instructions/context file (without the complete movie)
            let mainContextFile = sessionFolder.appendingPathComponent("00_MAIN_CONTEXT.md")
            let mainPromptWithoutMovie = context.buildMainPromptWithoutBulkData()
            try mainPromptWithoutMovie.write(to: mainContextFile, atomically: true, encoding: .utf8)

            // 01 - Write complete movie context split into five JSON files for size management
            if !filmManager.shots.isEmpty {
                let allShots = filmManager.shots
                let partSize = max(1, allShots.count / 5)

                for part in 0..<5 {
                    let startIndex = part * partSize
                    let endIndex = (part == 4) ? allShots.count : min((part + 1) * partSize, allShots.count)

                    guard startIndex < allShots.count else { break }

                    let shotsInPart = Array(allShots[startIndex..<endIndex])
                    var shotJsonArray: [[String: Any]] = []

                    for shot in shotsInPart {
                        if shot.selectedPromptIndex < shot.promptVariants.count {
                            let selectedPrompt = shot.promptVariants[shot.selectedPromptIndex]
                            let shotJson: [String: Any] = [
                                "shot_id": shot.id,
                                "shot_title": shot.title,
                                "sequence_type": shot.sequenceType,
                                "duration": shot.duration,
                                "aspect_ratio": shot.aspectRatio,
                                "position": shot.position,
                                "progressive_state": shot.progressiveState,
                                "selected_variant": [
                                    "variant_id": selectedPrompt.variantId,
                                    "variant_name": selectedPrompt.name,
                                    "subject": selectedPrompt.subject,
                                    "action": selectedPrompt.action,
                                    "scene": selectedPrompt.scene,
                                    "style": selectedPrompt.style,
                                    "camera_position": selectedPrompt.cameraPosition,
                                    "dialogue": selectedPrompt.dialogue,
                                    "selected_plates": selectedPrompt.selectedPlateIds,
                                    "negative_prompt": selectedPrompt.negativePrompt,
                                    "progressive_state": selectedPrompt.progressiveState,
                                    "is_active": selectedPrompt.isActive
                                ]
                            ]
                            shotJsonArray.append(shotJson)
                        }
                    }

                    // Write as JSON
                    if let jsonData = try? JSONSerialization.data(withJSONObject: shotJsonArray, options: [.prettyPrinted, .sortedKeys]) {
                        let letter = String(Character(UnicodeScalar(97 + part)!)) // a, b, c, d, e
                        let fileName = "01\(letter)_complete_movie_shots_part\(part + 1).json"
                        let fileURL = sessionFolder.appendingPathComponent(fileName)
                        try jsonData.write(to: fileURL)
                    }
                }
            }

            // 02 - Write all plates (character and environmental)
            var allPlatesContent = "# COMPLETE PLATE DEFINITIONS\n\n"

            if !context.characterPlatesContext.isEmpty {
                allPlatesContent += context.characterPlatesContext + "\n\n"
            }

            if !context.environmentalPlatesContext.isEmpty {
                allPlatesContent += context.environmentalPlatesContext + "\n\n"
            }

            if !allPlatesContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let platesFile = sessionFolder.appendingPathComponent("02_all_plates.md")
                try allPlatesContent.write(to: platesFile, atomically: true, encoding: .utf8)
            }

            // 03 - Write current shot context separately (this is the PRIMARY focus)
            if !context.shotContext.isEmpty {
                let currentShotFile = sessionFolder.appendingPathComponent("03_current_shot.md")
                try context.shotContext.write(to: currentShotFile, atomically: true, encoding: .utf8)
            }

            // Write research documents
            if !context.researchDocuments.isEmpty {
                let researchFolder = sessionFolder.appendingPathComponent("research_documents")
                try FileManager.default.createDirectory(at: researchFolder, withIntermediateDirectories: true, attributes: nil)

                for (name, content) in context.researchDocuments {
                    let fileName = "\(name.replacingOccurrences(of: " ", with: "_")).md"
                    let fileURL = researchFolder.appendingPathComponent(fileName)
                    try content.write(to: fileURL, atomically: true, encoding: .utf8)
                }
            }

            // Write enhancement guides
            if !context.cinematicGuide.isEmpty {
                let cinematicFile = sessionFolder.appendingPathComponent("04_cinematic_guide.md")
                try context.cinematicGuide.write(to: cinematicFile, atomically: true, encoding: .utf8)
            }

            if !context.aiGuide.isEmpty {
                let aiFile = sessionFolder.appendingPathComponent("05_ai_generation_guide.md")
                try context.aiGuide.write(to: aiFile, atomically: true, encoding: .utf8)
            }

            if !context.characterDepthGuide.isEmpty {
                let depthFile = sessionFolder.appendingPathComponent("06_character_depth_guide.md")
                try context.characterDepthGuide.write(to: depthFile, atomically: true, encoding: .utf8)
            }

            // Write prompt emphasis if selected - CRITICAL for new variants
            if !context.promptEmphasisDoc.isEmpty {
                var emphasisContent = "🎯 PROMPT EMPHASIS STYLE - CRITICAL FOR NEW VARIANTS\n"
                emphasisContent += "================================================\n\n"
                emphasisContent += "⚠️ ESSENTIAL: This emphasis style was specifically selected to guide the creation of new prompt variants.\n"
                emphasisContent += "The new prompts MUST heavily incorporate the stylistic elements, focus areas, and techniques described below.\n"
                emphasisContent += "This is not optional guidance - it is the PRIMARY DIRECTIVE for how new variants should be crafted.\n\n"
                emphasisContent += "When creating new prompt variants:\n"
                emphasisContent += "1. PRIORITIZE the emphasis elements below in your descriptions\n"
                emphasisContent += "2. FOCUS on the specific aspects this style highlights\n"
                emphasisContent += "3. INTEGRATE these techniques throughout all prompt fields\n"
                emphasisContent += "4. ENSURE the variant strongly reflects this chosen emphasis\n\n"
                emphasisContent += "---\n\n"
                emphasisContent += context.promptEmphasisDoc

                let emphasisFile = sessionFolder.appendingPathComponent("07_prompt_emphasis_ESSENTIAL.md")
                try emphasisContent.write(to: emphasisFile, atomically: true, encoding: .utf8)
            }

        } catch {
            print("Error creating context files: \(error)")
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