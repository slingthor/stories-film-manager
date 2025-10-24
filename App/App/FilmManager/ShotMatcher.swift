import Foundation

// MARK: - ShotMatcher - Finds matching shots using fuzzy text matching

class ShotMatcher {

    // MARK: - Matching Thresholds
    private let actionThreshold: Double = 0.30    // 30% similarity for ACTION (most unique)
    private let sceneThreshold: Double = 0.25     // 25% similarity for SCENE
    private let dialogueThreshold: Double = 0.40  // 40% similarity for DIALOGUE (when present)
    private let styleThreshold: Double = 0.25     // 25% similarity for STYLE

    // MARK: - Variant Index Cache
    private struct VariantReference {
        let shot: FilmShot
        let variantIndex: Int
        let variant: PromptVariant
    }

    private var variantIndex: [String: [VariantReference]] = [:]

    // MARK: - Cache Building
    func buildVariantIndex(shots: [FilmShot]) {
        print("[Sora] 🔨 Building variant index cache...")
        variantIndex.removeAll()
        var totalVariants = 0

        for shot in shots {
            for (index, variant) in shot.promptVariants.enumerated() {
                totalVariants += 1

                // Extract first 5 words from each component
                let actionKey = extractFirstWords(variant.action, count: 5)
                let sceneKey = extractFirstWords(variant.scene, count: 5)
                let styleKey = extractFirstWords(variant.style, count: 5)
                let dialogueKey = extractFirstWords(variant.dialogue, count: 5)

                let reference = VariantReference(shot: shot, variantIndex: index, variant: variant)

                // Index by action words
                if !actionKey.isEmpty {
                    variantIndex[actionKey, default: []].append(reference)
                }

                // Index by scene words
                if !sceneKey.isEmpty {
                    variantIndex[sceneKey, default: []].append(reference)
                }

                // Index by style words
                if !styleKey.isEmpty {
                    variantIndex[styleKey, default: []].append(reference)
                }

                // Index by dialogue words
                if !dialogueKey.isEmpty {
                    variantIndex[dialogueKey, default: []].append(reference)
                }
            }
        }

        print("[Sora] ✅ Built index with \(variantIndex.count) unique keys for \(totalVariants) variants")
    }

    private func extractFirstWords(_ text: String, count: Int) -> String {
        let words = text.lowercased()
            .split(separator: " ")
            .prefix(count)
            .map(String.init)
        return words.joined(separator: " ")
    }

    // MARK: - String Normalization (removes noise without losing meaning)
    private func normalizeString(_ text: String) -> String {
        // Common stop words that add no semantic value for matching
        let stopWords = Set(["the", "a", "an", "is", "are", "was", "were", "been", "be", "being",
                            "have", "has", "had", "do", "does", "did", "will", "would", "should",
                            "could", "may", "might", "must", "can", "with", "from", "into", "during",
                            "including", "until", "against", "among", "throughout", "despite", "towards",
                            "upon", "of", "for", "on", "at", "by", "as", "in", "to"])

        // Remove punctuation and normalize whitespace
        var normalized = text.lowercased()
            .replacingOccurrences(of: "[", with: " ")
            .replacingOccurrences(of: "]", with: " ")
            .replacingOccurrences(of: ":", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: "(", with: " ")
            .replacingOccurrences(of: ")", with: " ")

        // Remove stop words
        let words = normalized.split(separator: " ")
            .map(String.init)
            .filter { !stopWords.contains($0) && !$0.isEmpty }

        return words.joined(separator: " ")
    }

    // MARK: - Character Frequency Fast Reject
    private func characterFrequencyDifference(_ str1: String, _ str2: String) -> Double {
        var freq1: [Character: Int] = [:]
        var freq2: [Character: Int] = [:]

        // Build frequency maps
        for char in str1.lowercased() {
            freq1[char, default: 0] += 1
        }
        for char in str2.lowercased() {
            freq2[char, default: 0] += 1
        }

        // Calculate total difference
        var totalDiff = 0
        let allChars = Set(freq1.keys).union(Set(freq2.keys))

        for char in allChars {
            let count1 = freq1[char] ?? 0
            let count2 = freq2[char] ?? 0
            totalDiff += abs(count1 - count2)
        }

        // Normalize by max possible difference
        let maxLength = max(str1.count, str2.count)
        return maxLength > 0 ? Double(totalDiff) / Double(maxLength * 2) : 0.0
    }

    // MARK: - Main Matching Function
    func findMatchingShot(
        promptComponents: PromptComponents,
        shots: [FilmShot]
    ) async -> ShotMatchResult {
        print("[Sora] 🔍 Searching \(shots.count) shots for match...")

        // Log prompt sizes for performance monitoring
        let totalPromptChars = promptComponents.action.count + promptComponents.scene.count +
                              promptComponents.style.count + promptComponents.dialogue.count
        print("[Sora] 📏 Prompt size: ACTION=\(promptComponents.action.count), SCENE=\(promptComponents.scene.count), STYLE=\(promptComponents.style.count), DIALOGUE=\(promptComponents.dialogue.count) (total: \(totalPromptChars) chars)")

        if totalPromptChars > 2000 {
            print("[Sora] ⚡️ Large prompt detected - using 500 char truncation for fast matching")
        }

        var attempts: [String] = []
        var bestMatch: (shot: FilmShot, variant: PromptVariant, score: Double)?
        var bestActionScore: Double = 0.0
        var bestSceneScore: Double = 0.0

        // PASS 1: Search cache-indexed variants (fast path)
        let actionKey = extractFirstWords(promptComponents.action, count: 5)
        let sceneKey = extractFirstWords(promptComponents.scene, count: 5)
        let styleKey = extractFirstWords(promptComponents.style, count: 5)
        let dialogueKey = extractFirstWords(promptComponents.dialogue, count: 5)

        // Collect variants that match each key
        var actionRefs: Set<String> = []
        var sceneRefs: Set<String> = []
        var styleRefs: Set<String> = []
        var dialogueRefs: Set<String> = []

        if !actionKey.isEmpty, let refs = variantIndex[actionKey] {
            for ref in refs {
                actionRefs.insert("\(ref.shot.id)_\(ref.variantIndex)")
            }
        }

        if !sceneKey.isEmpty, let refs = variantIndex[sceneKey] {
            for ref in refs {
                sceneRefs.insert("\(ref.shot.id)_\(ref.variantIndex)")
            }
        }

        if !styleKey.isEmpty, let refs = variantIndex[styleKey] {
            for ref in refs {
                styleRefs.insert("\(ref.shot.id)_\(ref.variantIndex)")
            }
        }

        if !dialogueKey.isEmpty, let refs = variantIndex[dialogueKey] {
            for ref in refs {
                dialogueRefs.insert("\(ref.shot.id)_\(ref.variantIndex)")
            }
        }

        // Find variants that match ALL non-empty keys
        var candidateIds: Set<String>?

        // Start with first non-empty key's results
        if !actionKey.isEmpty {
            candidateIds = actionRefs
        }

        // Intersect with each additional non-empty key
        if !sceneKey.isEmpty {
            if candidateIds == nil {
                candidateIds = sceneRefs
            } else {
                candidateIds = candidateIds!.intersection(sceneRefs)
            }
        }

        if !styleKey.isEmpty {
            if candidateIds == nil {
                candidateIds = styleRefs
            } else {
                candidateIds = candidateIds!.intersection(styleRefs)
            }
        }

        if !dialogueKey.isEmpty {
            if candidateIds == nil {
                candidateIds = dialogueRefs
            } else {
                candidateIds = candidateIds!.intersection(dialogueRefs)
            }
        }

        // Convert IDs back to VariantReferences
        var candidates: [VariantReference] = []

        if let finalCandidateIds = candidateIds {
            for candidateId in finalCandidateIds {
                // Find the reference from any of the index lookups
                if !actionKey.isEmpty, let refs = variantIndex[actionKey] {
                    if let ref = refs.first(where: { "\($0.shot.id)_\($0.variantIndex)" == candidateId }) {
                        candidates.append(ref)
                        continue
                    }
                }
                if !sceneKey.isEmpty, let refs = variantIndex[sceneKey] {
                    if let ref = refs.first(where: { "\($0.shot.id)_\($0.variantIndex)" == candidateId }) {
                        candidates.append(ref)
                        continue
                    }
                }
                if !styleKey.isEmpty, let refs = variantIndex[styleKey] {
                    if let ref = refs.first(where: { "\($0.shot.id)_\($0.variantIndex)" == candidateId }) {
                        candidates.append(ref)
                        continue
                    }
                }
                if !dialogueKey.isEmpty, let refs = variantIndex[dialogueKey] {
                    if let ref = refs.first(where: { "\($0.shot.id)_\($0.variantIndex)" == candidateId }) {
                        candidates.append(ref)
                        continue
                    }
                }
            }
            print("[Sora] 📋 Found \(candidates.count) candidate variants matching ALL non-empty keys from index")
        } else {
            print("[Sora] 📋 No search keys provided, skipping cache lookup")
        }

        // Search candidates first (PARALLEL for speed)
        if !candidates.isEmpty {
            print("[Sora] 🚀 Parallel matching \(candidates.count) candidates...")
            let candidateResults = await withTaskGroup(of: (shot: FilmShot, variant: PromptVariant, score: Double, actionScore: Double, sceneScore: Double, log: String).self) { group in
                for candidate in candidates {
                    group.addTask {
                        self.matchVariant(
                            shot: candidate.shot,
                            variantIndex: candidate.variantIndex,
                            variant: candidate.variant,
                            promptComponents: promptComponents
                        )
                    }
                }

                var results: [(shot: FilmShot, variant: PromptVariant, score: Double, actionScore: Double, sceneScore: Double, log: String)] = []
                for await result in group {
                    results.append(result)
                }
                return results
            }

            // Process results
            for result in candidateResults {
                attempts.append(result.log)

                if bestMatch == nil || result.score > bestMatch!.score {
                    bestMatch = (result.shot, result.variant, result.score)
                    bestActionScore = result.actionScore
                    bestSceneScore = result.sceneScore
                }
            }
        }

        // PASS 2: If no good match from cache, search remaining variants (PARALLEL)
        if bestMatch == nil || bestMatch!.score < 0.50 {
            print("[Sora] 🔄 Expanding search to all variants (parallel)...")
            print("[Sora]    Thread check - is main: \(Thread.isMainThread)")

            // Build list of variants to search (excluding already searched)
            var variantsToSearch: [(shot: FilmShot, variantIndex: Int, variant: PromptVariant)] = []
            for shot in shots {
                for (variantIndex, variant) in shot.promptVariants.enumerated() {
                    let uniqueId = "\(shot.id)_\(variantIndex)"
                    // Skip if already searched in pass 1
                    if let ids = candidateIds, ids.contains(uniqueId) {
                        continue
                    }
                    variantsToSearch.append((shot, variantIndex, variant))
                }
            }

            print("[Sora] 🚀 Parallel matching \(variantsToSearch.count) remaining variants...")

            // Search all variants in parallel
            let allResults = await withTaskGroup(of: (shot: FilmShot, variant: PromptVariant, score: Double, actionScore: Double, sceneScore: Double, log: String).self) { group in
                var processedCount = 0
                for item in variantsToSearch {
                    group.addTask {
                        self.matchVariant(
                            shot: item.shot,
                            variantIndex: item.variantIndex,
                            variant: item.variant,
                            promptComponents: promptComponents
                        )
                    }
                }

                var results: [(shot: FilmShot, variant: PromptVariant, score: Double, actionScore: Double, sceneScore: Double, log: String)] = []
                for await result in group {
                    results.append(result)
                    processedCount += 1
                    if processedCount % 50 == 0 {
                        print("[Sora]    Processed \(processedCount)/\(variantsToSearch.count) variants...")
                    }
                }
                return results
            }

            // Process results
            for result in allResults {
                attempts.append(result.log)

                if bestMatch == nil || result.score > bestMatch!.score {
                    bestMatch = (result.shot, result.variant, result.score)
                    bestActionScore = result.actionScore
                    bestSceneScore = result.sceneScore
                }
            }
        }

        // Check if best match meets minimum thresholds (using cached scores)
        if let best = bestMatch {
            let variant = best.variant

            // Must meet ACTION threshold OR combined ACTION+SCENE threshold
            let meetsActionThreshold = bestActionScore >= actionThreshold
            let meetsCombinedThreshold = (bestActionScore >= 0.20 && bestSceneScore >= sceneThreshold)

            if meetsActionThreshold || meetsCombinedThreshold {
                print("[Sora] ✅ Found match: Shot \(best.shot.id) - Variant '\(variant.name)' (confidence: \(String(format: "%.1f%%", best.score * 100)))")
                return ShotMatchResult(
                    shot: best.shot,
                    variant: best.variant,
                    attempts: attempts,
                    confidence: best.score
                )
            }
        }

        // No acceptable match found
        print("[Sora] ❌ No matching shot found above thresholds")
        return ShotMatchResult(
            shot: nil,
            variant: nil,
            attempts: attempts,
            confidence: 0.0
        )
    }

    // MARK: - Helper: Match Single Variant
    private func matchVariant(
        shot: FilmShot,
        variantIndex: Int,
        variant: PromptVariant,
        promptComponents: PromptComponents
    ) -> (shot: FilmShot, variant: PromptVariant, score: Double, actionScore: Double, sceneScore: Double, log: String) {

        // Truncate strings to 500 chars for performance (Levenshtein is O(m×n))
        // This prevents 8000×8000 = 64M operations per comparison
        let maxLength = 500

        // Truncate first, then normalize (removes stop words + punctuation)
        let promptAction = normalizeString(String(promptComponents.action.prefix(maxLength)))
        let promptScene = normalizeString(String(promptComponents.scene.prefix(maxLength)))
        let promptStyle = normalizeString(String(promptComponents.style.prefix(maxLength)))
        let promptDialogue = normalizeString(String(promptComponents.dialogue.prefix(maxLength)))

        let variantAction = normalizeString(String(variant.action.prefix(maxLength)))
        let variantScene = normalizeString(String(variant.scene.prefix(maxLength)))
        let variantStyle = normalizeString(String(variant.style.prefix(maxLength)))
        let variantDialogue = normalizeString(String(variant.dialogue.prefix(maxLength)))

        // Fast-reject using character frequency (avoids expensive Levenshtein on clearly non-matching strings)
        let actionFreqDiff = characterFrequencyDifference(promptAction, variantAction)
        let sceneFreqDiff = characterFrequencyDifference(promptScene, variantScene)

        // If character frequency difference > 60%, strings are too different to match - skip Levenshtein
        if actionFreqDiff > 0.6 && sceneFreqDiff > 0.6 {
            // Quick reject - no need for expensive Levenshtein
            return (shot, variant, 0.0, 0.0, 0.0, "Shot \(shot.id) - Quick reject (char freq diff: A=\(Int(actionFreqDiff*100))%, S=\(Int(sceneFreqDiff*100))%)")
        }

        // Calculate similarity scores for each component (now much faster with normalized strings!)
        let actionScore = promptAction.similarity(to: variantAction)
        let sceneScore = promptScene.similarity(to: variantScene)
        let styleScore = promptStyle.similarity(to: variantStyle)
        let dialogueScore = promptDialogue.similarity(to: variantDialogue)

        // Log attempt
        let attemptLog = """
        Shot \(shot.id) - "\(shot.title)" - Variant \(variantIndex) "\(variant.name)":
          ACTION: \(String(format: "%.1f%%", actionScore * 100))
          SCENE:  \(String(format: "%.1f%%", sceneScore * 100))
          STYLE:  \(String(format: "%.1f%%", styleScore * 100))
          DIALOGUE: \(String(format: "%.1f%%", dialogueScore * 100))
        """

        // Calculate weighted overall score
        var overallScore = (actionScore * 0.5) + (sceneScore * 0.3) + (styleScore * 0.2)

        // Bonus for dialogue match if both have dialogue
        if !promptComponents.dialogue.isEmpty && !variant.dialogue.isEmpty {
            overallScore += dialogueScore * 0.1
        }

        return (shot, variant, overallScore, actionScore, sceneScore, attemptLog)
    }

    // MARK: - Helper: Extract Camera Position
    /// Extracts camera position from style text (removes "that's where the camera is" marker)
    func extractCameraPosition(from style: String) -> String {
        if let range = style.range(of: "(that's where the camera is)", options: .caseInsensitive) {
            return String(style[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        return style
    }
}
