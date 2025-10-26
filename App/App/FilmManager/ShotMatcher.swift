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
        // Pre-computed normalized strings (avoids re-normalizing hundreds of times)
        let normalizedAction: String
        let normalizedScene: String
        let normalizedStyle: String
        let normalizedDialogue: String

        // Pre-computed metadata for ultra-fast rejection checks
        let actionLength: Int
        let sceneLength: Int
        let actionWordCount: Int
        let sceneWordCount: Int
        let actionCharSet: Set<Character>
        let sceneCharSet: Set<Character>
        let actionCharFreq: [Character: Int]
        let sceneCharFreq: [Character: Int]
        let criticalTokens: Set<String>  // Shot numbers, character names, etc.
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

                // Pre-compute normalized strings (500 char truncation + normalization)
                let maxLength = 500
                let normalizedAction = normalizeString(String(variant.action.prefix(maxLength)))
                let normalizedScene = normalizeString(String(variant.scene.prefix(maxLength)))
                let normalizedStyle = normalizeString(String(variant.style.prefix(maxLength)))
                let normalizedDialogue = normalizeString(String(variant.dialogue.prefix(maxLength)))

                // Pre-compute metadata for fast rejection checks
                let actionLength = normalizedAction.count
                let sceneLength = normalizedScene.count
                let actionWordCount = normalizedAction.components(separatedBy: .whitespaces).count
                let sceneWordCount = normalizedScene.components(separatedBy: .whitespaces).count
                let actionCharSet = Set(normalizedAction.lowercased())
                let sceneCharSet = Set(normalizedScene.lowercased())
                let actionCharFreq = buildCharacterFrequency(normalizedAction)
                let sceneCharFreq = buildCharacterFrequency(normalizedScene)
                let criticalTokens = extractCriticalTokens(from: variant.action)

                let reference = VariantReference(
                    shot: shot,
                    variantIndex: index,
                    variant: variant,
                    normalizedAction: normalizedAction,
                    normalizedScene: normalizedScene,
                    normalizedStyle: normalizedStyle,
                    normalizedDialogue: normalizedDialogue,
                    actionLength: actionLength,
                    sceneLength: sceneLength,
                    actionWordCount: actionWordCount,
                    sceneWordCount: sceneWordCount,
                    actionCharSet: actionCharSet,
                    sceneCharSet: sceneCharSet,
                    actionCharFreq: actionCharFreq,
                    sceneCharFreq: sceneCharFreq,
                    criticalTokens: criticalTokens
                )

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
        let normalized = text.lowercased()
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

    // MARK: - Helper Functions for Caching
    private func buildCharacterFrequency(_ text: String) -> [Character: Int] {
        var freq: [Character: Int] = [:]
        for char in text.lowercased() {
            freq[char, default: 0] += 1
        }
        return freq
    }

    private func extractCriticalTokens(from text: String) -> Set<String> {
        var tokens = Set<String>()
        let lowercased = text.lowercased()

        // Extract numbers (shot numbers, durations like "8 seconds")
        let numberPattern = /\d+/
        for match in lowercased.matches(of: numberPattern) {
            tokens.insert(String(match.output))
        }

        // Extract capitalized names and important words (SIGRID, MAGNÚS, etc.)
        // Look for uppercase words in original text
        let namePattern = /[A-ZÞÐÆ][A-ZÞÐÆa-zþðæ]{2,}/
        for match in text.matches(of: namePattern) {
            tokens.insert(String(match.output).lowercased())
        }

        return tokens
    }

    // MARK: - Ultra-Fast Rejection Checks

    /// Calculate theoretical maximum possible similarity given length difference
    /// This is a mathematical lower bound - if this fails, full Levenshtein will definitely fail
    private func maxPossibleSimilarity(len1: Int, len2: Int) -> Double {
        guard len1 > 0 && len2 > 0 else { return 0.0 }
        let minLen = min(len1, len2)
        let maxLen = max(len1, len2)
        // Best case: all characters of shorter string match
        // Levenshtein similarity = 1 - (editDistance / maxLen)
        // Best edit distance = maxLen - minLen (only insertions/deletions)
        let bestDistance = maxLen - minLen
        return 1.0 - (Double(bestDistance) / Double(maxLen))
    }

    /// Check if word count ratio is acceptable
    private func passesWordCountCheck(promptCount: Int, variantCount: Int) -> Bool {
        guard promptCount > 0 && variantCount > 0 else { return false }
        let ratio = Double(min(promptCount, variantCount)) / Double(max(promptCount, variantCount))
        return ratio >= 0.30  // Allow 3.3:1 ratio (balanced)
    }

    /// Calculate Jaccard similarity of character sets (fast set operations)
    private func characterSetJaccard(_ set1: Set<Character>, _ set2: Set<Character>) -> Double {
        guard !set1.isEmpty && !set2.isEmpty else { return 0.0 }
        let intersection = set1.intersection(set2).count
        let union = set1.union(set2).count
        return Double(intersection) / Double(union)
    }

    /// Check if critical tokens overlap sufficiently
    private func hasCriticalTokenOverlap(_ tokens1: Set<String>, _ tokens2: Set<String>) -> Bool {
        // If both have tokens, they must share at least one
        if !tokens1.isEmpty && !tokens2.isEmpty {
            return !tokens1.intersection(tokens2).isEmpty
        }
        // If one or both have no tokens, pass the check
        return true
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
        let isSubjectOnly = promptComponents.isSubjectOnlyMode
        print("[Sora] 🔍 Searching \(shots.count) shots for match using cached metadata...")

        if isSubjectOnly {
            print("[Sora] ⚠️ SUBJECT-ONLY mode detected - using lenient matching strategy")
        }

        // Pre-process prompt once for all comparisons
        let maxLength = 500
        let promptAction = normalizeString(String(promptComponents.action.prefix(maxLength)))
        let promptScene = normalizeString(String(promptComponents.scene.prefix(maxLength)))
        let promptStyle = normalizeString(String(promptComponents.style.prefix(maxLength)))
        let promptDialogue = normalizeString(String(promptComponents.dialogue.prefix(maxLength)))

        let promptActionLength = promptAction.count
        let promptSceneLength = promptScene.count
        let promptActionWordCount = promptAction.components(separatedBy: .whitespaces).count
        let promptSceneWordCount = promptScene.components(separatedBy: .whitespaces).count
        let promptActionCharSet = Set(promptAction.lowercased())
        let promptSceneCharSet = Set(promptScene.lowercased())
        let promptCriticalTokens = extractCriticalTokens(from: promptComponents.action)

        var attempts: [String] = []
        var bestMatch: (shot: FilmShot, variant: PromptVariant, score: Double)?
        var bestActionScore: Double = 0.0
        var bestSceneScore: Double = 0.0
        var pass0Candidates: Set<String> = []  // Declare outside for Pass 2 access

        // Skip Pass 0 for SUBJECT-only mode (won't work with duplicate keys)
        if !isSubjectOnly {
            // ═══════════════════════════════════════════════════════════
            // PASS 0: WORD-BASED INDEX LOOKUP (Fastest - exact phrase matching)
            // Require 3 out of 4 sections to have matching first 5 words
            // ═══════════════════════════════════════════════════════════
            let actionKey = extractFirstWords(promptComponents.action, count: 5)
        let sceneKey = extractFirstWords(promptComponents.scene, count: 5)
        let styleKey = extractFirstWords(promptComponents.style, count: 5)
        let dialogueKey = extractFirstWords(promptComponents.dialogue, count: 5)

        // Count section matches for each variant
        var variantSectionMatches: [String: Int] = [:] // variantId -> match count

        if !actionKey.isEmpty, let refs = variantIndex[actionKey] {
            for ref in refs {
                let id = "\(ref.shot.id)_\(ref.variantIndex)"
                variantSectionMatches[id, default: 0] += 1
            }
        }

        if !sceneKey.isEmpty, let refs = variantIndex[sceneKey] {
            for ref in refs {
                let id = "\(ref.shot.id)_\(ref.variantIndex)"
                variantSectionMatches[id, default: 0] += 1
            }
        }

        if !styleKey.isEmpty, let refs = variantIndex[styleKey] {
            for ref in refs {
                let id = "\(ref.shot.id)_\(ref.variantIndex)"
                variantSectionMatches[id, default: 0] += 1
            }
        }

        if !dialogueKey.isEmpty, let refs = variantIndex[dialogueKey] {
            for ref in refs {
                let id = "\(ref.shot.id)_\(ref.variantIndex)"
                variantSectionMatches[id, default: 0] += 1
            }
        }

        // Filter variants that have 3+ section matches
        pass0Candidates = Set(variantSectionMatches.filter { $0.value >= 3 }.keys)

        if !pass0Candidates.isEmpty {
            print("[Sora] 📚 Pass 0: Found \(pass0Candidates.count) variants with 3+ section matches")

            // Collect VariantReference objects for these candidates
            var candidateRefs: [VariantReference] = []
            for candidateId in pass0Candidates {
                // Find the reference from index
                if !actionKey.isEmpty, let refs = variantIndex[actionKey] {
                    if let ref = refs.first(where: { "\($0.shot.id)_\($0.variantIndex)" == candidateId }) {
                        candidateRefs.append(ref)
                        continue
                    }
                }
                if !sceneKey.isEmpty, let refs = variantIndex[sceneKey] {
                    if let ref = refs.first(where: { "\($0.shot.id)_\($0.variantIndex)" == candidateId }) {
                        candidateRefs.append(ref)
                        continue
                    }
                }
                if !styleKey.isEmpty, let refs = variantIndex[styleKey] {
                    if let ref = refs.first(where: { "\($0.shot.id)_\($0.variantIndex)" == candidateId }) {
                        candidateRefs.append(ref)
                        continue
                    }
                }
                if !dialogueKey.isEmpty, let refs = variantIndex[dialogueKey] {
                    if let ref = refs.first(where: { "\($0.shot.id)_\($0.variantIndex)" == candidateId }) {
                        candidateRefs.append(ref)
                        continue
                    }
                }
            }

            // Run full Levenshtein on Pass 0 candidates
            let pass0Results = await withTaskGroup(of: (shot: FilmShot, variant: PromptVariant, score: Double, actionScore: Double, sceneScore: Double, log: String).self) { group in
                for candidate in candidateRefs {
                    group.addTask {
                        self.matchVariantFull(
                            cached: candidate,
                            promptAction: promptAction,
                            promptScene: promptScene,
                            promptStyle: promptStyle,
                            promptDialogue: promptDialogue,
                            promptComponents: promptComponents
                        )
                    }
                }

                var results: [(shot: FilmShot, variant: PromptVariant, score: Double, actionScore: Double, sceneScore: Double, log: String)] = []
                for await result in group {
                    results.append(result)
                    // Early termination on excellent match
                    if result.score > 0.90 {
                        return [result]
                    }
                }
                return results
            }

            // Process Pass 0 results
            for result in pass0Results {
                attempts.append(result.log)
                if bestMatch == nil || result.score > bestMatch!.score {
                    bestMatch = (result.shot, result.variant, result.score)
                    bestActionScore = result.actionScore
                    bestSceneScore = result.sceneScore
                }
            }

            // If Pass 0 found an acceptable match, return it
            if let best = bestMatch {
                let meetsActionThreshold = bestActionScore >= actionThreshold
                let meetsCombinedThreshold = (bestActionScore >= 0.20 && bestSceneScore >= sceneThreshold)

                if meetsActionThreshold || meetsCombinedThreshold {
                    print("[Sora] ✅ Pass 0 SUCCESS: Found match via word index!")
                    print("[Sora] ✅ Match: Shot \(best.shot.id) - Variant '\(best.variant.name)' (confidence: \(String(format: "%.1f%%", best.score * 100)))")
                    return ShotMatchResult(
                        shot: best.shot,
                        variant: best.variant,
                        attempts: attempts,
                        confidence: best.score
                    )
                }
            }
        }
        } else {
            print("[Sora] ⏭️ Skipping Pass 0 for SUBJECT-only mode - going to full search")
        }

        // ═══════════════════════════════════════════════════════════
        // PASS 1: ULTRA-FAST REJECTION PASS
        // Use pre-cached metadata for lightning-fast elimination
        // Skip for SUBJECT-only mode - go straight to exhaustive search
        // ═══════════════════════════════════════════════════════════
        var pass1Candidates: [VariantReference] = []

        if !isSubjectOnly {

        // Collect all variant references from index
        var allVariantRefs: [VariantReference] = []
        for refs in variantIndex.values {
            allVariantRefs.append(contentsOf: refs)
        }
        // Deduplicate by shot_variant ID
        var seenIds = Set<String>()
        var uniqueRefs: [VariantReference] = []
        for ref in allVariantRefs {
            let id = "\(ref.shot.id)_\(ref.variantIndex)"
            if !seenIds.contains(id) {
                seenIds.insert(id)
                uniqueRefs.append(ref)
            }
        }

        // Run Pass 1 filtering in parallel batches to avoid blocking
        pass1Candidates = await withTaskGroup(of: [VariantReference].self) { group in
            // Process in batches of 50 to allow yielding
            let batchSize = 50
            for batchStart in stride(from: 0, to: uniqueRefs.count, by: batchSize) {
                let batchEnd = min(batchStart + batchSize, uniqueRefs.count)
                let batch = Array(uniqueRefs[batchStart..<batchEnd])

                group.addTask {
                    var candidates: [VariantReference] = []
                    for cached in batch {
                        // Check 1: Maximum possible similarity (MUST be mathematically possible)
                        let maxSimAction = self.maxPossibleSimilarity(len1: promptActionLength, len2: cached.actionLength)
                        let maxSimScene = self.maxPossibleSimilarity(len1: promptSceneLength, len2: cached.sceneLength)

                        // Reject if BOTH are below their respective thresholds
                        if maxSimAction < self.actionThreshold && maxSimScene < self.sceneThreshold {
                            continue  // Impossible to meet either threshold
                        }

                        // Check 2: Word count ratio
                        if !self.passesWordCountCheck(promptCount: promptActionWordCount, variantCount: cached.actionWordCount) &&
                           !self.passesWordCountCheck(promptCount: promptSceneWordCount, variantCount: cached.sceneWordCount) {
                            continue
                        }

                        // Check 3: Character set overlap (Jaccard similarity)
                        let actionJaccard = self.characterSetJaccard(promptActionCharSet, cached.actionCharSet)
                        let sceneJaccard = self.characterSetJaccard(promptSceneCharSet, cached.sceneCharSet)

                        if actionJaccard < 0.45 && sceneJaccard < 0.45 {
                            continue  // Less than 45% character overlap in both (balanced)
                        }

                        // Check 4: Critical token overlap
                        if !self.hasCriticalTokenOverlap(promptCriticalTokens, cached.criticalTokens) {
                            continue
                        }

                        // Passed all rejection checks!
                        candidates.append(cached)
                    }
                    return candidates
                }
            }

            var allCandidates: [VariantReference] = []
            for await batchCandidates in group {
                allCandidates.append(contentsOf: batchCandidates)
            }
            return allCandidates
        }

        // If we have candidates from fast pass, do full comparison on them
        if !pass1Candidates.isEmpty {

            let pass1Results = await withTaskGroup(of: (shot: FilmShot, variant: PromptVariant, score: Double, actionScore: Double, sceneScore: Double, log: String).self) { group in
                for candidate in pass1Candidates {
                    group.addTask {
                        self.matchVariantFull(
                            cached: candidate,
                            promptAction: promptAction,
                            promptScene: promptScene,
                            promptStyle: promptStyle,
                            promptDialogue: promptDialogue,
                            promptComponents: promptComponents
                        )
                    }
                }

                var results: [(shot: FilmShot, variant: PromptVariant, score: Double, actionScore: Double, sceneScore: Double, log: String)] = []
                for await result in group {
                    results.append(result)
                    // Early termination on excellent match
                    if result.score > 0.90 {
                        return [result]
                    }
                }
                return results
            }

            // Process Pass 1 results
            for result in pass1Results {
                attempts.append(result.log)
                if bestMatch == nil || result.score > bestMatch!.score {
                    bestMatch = (result.shot, result.variant, result.score)
                    bestActionScore = result.actionScore
                    bestSceneScore = result.sceneScore
                }
            }

            // If Pass 1 found an acceptable match, return it
            if let best = bestMatch {
                let meetsActionThreshold = bestActionScore >= actionThreshold
                let meetsCombinedThreshold = (bestActionScore >= 0.20 && bestSceneScore >= sceneThreshold)

                if meetsActionThreshold || meetsCombinedThreshold {
                    print("[Sora] ✅ Found match: Shot \(best.shot.id) - Variant '\(best.variant.name)' (confidence: \(String(format: "%.1f%%", best.score * 100)))")
                    return ShotMatchResult(
                        shot: best.shot,
                        variant: best.variant,
                        attempts: attempts,
                        confidence: best.score
                    )
                }
            }
        }
        } else {
            print("[Sora] ⏭️ Skipping Pass 1 for SUBJECT-only mode")
        }

        // ═══════════════════════════════════════════════════════════
        // PASS 2: FULL SEARCH (Exhaustive fallback or SUBJECT-only search)
        // Search all variants if Pass 0 and Pass 1 found nothing
        // ═══════════════════════════════════════════════════════════
        if bestMatch == nil || bestMatch!.score < 0.50 {

            // Build list of variants to search (excluding already searched in Pass 0 and Pass 1)
            var alreadySearched = Set<String>()

            // Add Pass 0 candidates
            for candidateId in pass0Candidates {
                alreadySearched.insert(candidateId)
            }

            // Add Pass 1 candidates
            for ref in pass1Candidates {
                alreadySearched.insert("\(ref.shot.id)_\(ref.variantIndex)")
            }

            var variantsToSearch: [(shot: FilmShot, variantIndex: Int, variant: PromptVariant)] = []
            for shot in shots {
                for (variantIndex, variant) in shot.promptVariants.enumerated() {
                    let uniqueId = "\(shot.id)_\(variantIndex)"
                    // Skip if already searched in Pass 0 or Pass 1
                    if alreadySearched.contains(uniqueId) {
                        continue
                    }
                    variantsToSearch.append((shot, variantIndex, variant))
                }
            }

            // Search all variants in parallel
            let allResults = await withTaskGroup(of: (shot: FilmShot, variant: PromptVariant, score: Double, actionScore: Double, sceneScore: Double, log: String).self) { group in
                var processedCount = 0
                for item in variantsToSearch {
                    group.addTask {
                        self.matchVariant(
                            shot: item.shot,
                            variantIndex: item.variantIndex,
                            variant: item.variant,
                            promptComponents: promptComponents,
                            cachedReference: nil  // No cached reference for full search
                        )
                    }
                }

                var results: [(shot: FilmShot, variant: PromptVariant, score: Double, actionScore: Double, sceneScore: Double, log: String)] = []
                for await result in group {
                    results.append(result)
                    processedCount += 1

                    // Early termination: If we find a >90% match, stop searching
                    if result.score > 0.90 {
                        print("[Sora] 🎯 Found high-confidence match (>90%) - stopping full search early")
                        return [result]
                    }

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

            // For SUBJECT-only mode, use more lenient threshold (30% match is acceptable for truncated prompts)
            if isSubjectOnly {
                if best.score >= 0.30 {
                    print("[Sora] ✅ Found SUBJECT-only match: Shot \(best.shot.id) - Variant '\(variant.name)' (confidence: \(String(format: "%.1f%%", best.score * 100)))")
                    return ShotMatchResult(
                        shot: best.shot,
                        variant: best.variant,
                        attempts: attempts,
                        confidence: best.score
                    )
                }
            } else {
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
        promptComponents: PromptComponents,
        cachedReference: VariantReference? = nil
    ) -> (shot: FilmShot, variant: PromptVariant, score: Double, actionScore: Double, sceneScore: Double, log: String) {

        // SUBJECT-ONLY MODE: Compare only SUBJECT fields for truncated prompts
        if promptComponents.isSubjectOnlyMode {
            let maxLength = 500
            let promptSubject = normalizeString(String(promptComponents.subject.prefix(maxLength)))
            let variantSubject = normalizeString(String(variant.subject.prefix(maxLength)))

            let subjectScore = promptSubject.similarity(to: variantSubject)

            let attemptLog = """
            Shot \(shot.id) - "\(shot.title)" - Variant \(variantIndex) "\(variant.name)" [SUBJECT-ONLY]:
              SUBJECT: \(String(format: "%.1f%%", subjectScore * 100))
            """

            // For SUBJECT-only mode, use the subject score directly
            return (shot, variant, subjectScore, subjectScore, subjectScore, attemptLog)
        }

        // Truncate strings to 500 chars for performance (Levenshtein is O(m×n))
        // This prevents 8000×8000 = 64M operations per comparison
        let maxLength = 500

        // Truncate first, then normalize (removes stop words + punctuation)
        let promptAction = normalizeString(String(promptComponents.action.prefix(maxLength)))
        let promptScene = normalizeString(String(promptComponents.scene.prefix(maxLength)))
        let promptStyle = normalizeString(String(promptComponents.style.prefix(maxLength)))
        let promptDialogue = normalizeString(String(promptComponents.dialogue.prefix(maxLength)))

        // Use pre-computed normalized strings if available (much faster!)
        let variantAction: String
        let variantScene: String
        let variantStyle: String
        let variantDialogue: String

        if let cached = cachedReference {
            variantAction = cached.normalizedAction
            variantScene = cached.normalizedScene
            variantStyle = cached.normalizedStyle
            variantDialogue = cached.normalizedDialogue
        } else {
            variantAction = normalizeString(String(variant.action.prefix(maxLength)))
            variantScene = normalizeString(String(variant.scene.prefix(maxLength)))
            variantStyle = normalizeString(String(variant.style.prefix(maxLength)))
            variantDialogue = normalizeString(String(variant.dialogue.prefix(maxLength)))
        }

        // Length-based fast reject (non-lossy: strings differing by >50% length can't match well)
        let actionLengthRatio = Double(min(promptAction.count, variantAction.count)) /
                                Double(max(max(promptAction.count, variantAction.count), 1))
        let sceneLengthRatio = Double(min(promptScene.count, variantScene.count)) /
                               Double(max(max(promptScene.count, variantScene.count), 1))

        if actionLengthRatio < 0.5 && sceneLengthRatio < 0.5 {
            return (shot, variant, 0.0, 0.0, 0.0, "Shot \(shot.id) - Quick reject (length mismatch)")
        }

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

    // MARK: - Helper: Match Variant with Pre-Processed Prompt (for Pass 1)
    private func matchVariantFull(
        cached: VariantReference,
        promptAction: String,
        promptScene: String,
        promptStyle: String,
        promptDialogue: String,
        promptComponents: PromptComponents
    ) -> (shot: FilmShot, variant: PromptVariant, score: Double, actionScore: Double, sceneScore: Double, log: String) {

        // Use cached normalized strings (already computed!)
        let variantAction = cached.normalizedAction
        let variantScene = cached.normalizedScene
        let variantStyle = cached.normalizedStyle
        let variantDialogue = cached.normalizedDialogue

        // Calculate similarity scores using Levenshtein
        let actionScore = promptAction.similarity(to: variantAction)
        let sceneScore = promptScene.similarity(to: variantScene)
        let styleScore = promptStyle.similarity(to: variantStyle)
        let dialogueScore = promptDialogue.similarity(to: variantDialogue)

        // Log attempt
        let attemptLog = """
        Shot \(cached.shot.id) - "\(cached.shot.title)" - Variant \(cached.variantIndex) "\(cached.variant.name)":
          ACTION: \(String(format: "%.1f%%", actionScore * 100))
          SCENE:  \(String(format: "%.1f%%", sceneScore * 100))
          STYLE:  \(String(format: "%.1f%%", styleScore * 100))
          DIALOGUE: \(String(format: "%.1f%%", dialogueScore * 100))
        """

        // Calculate weighted overall score
        var overallScore = (actionScore * 0.5) + (sceneScore * 0.3) + (styleScore * 0.2)

        // Bonus for dialogue match if both have dialogue
        if !promptComponents.dialogue.isEmpty && !cached.variant.dialogue.isEmpty {
            overallScore += dialogueScore * 0.1
        }

        return (cached.shot, cached.variant, overallScore, actionScore, sceneScore, attemptLog)
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
