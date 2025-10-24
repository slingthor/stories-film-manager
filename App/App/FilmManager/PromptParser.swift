import Foundation

// MARK: - PromptParser - Extracts prompt components from clipboard text

class PromptParser {

    // MARK: - Main Parsing Function
    func parse(_ text: String) -> PromptComponents? {
        // Remove extra whitespace and normalize
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else {
            print("[Sora] ⚠️ Clipboard text is empty")
            return nil
        }

        // Extract each component
        guard let action = extractSection(from: normalized, sectionName: "ACTION") else {
            print("[Sora] ⚠️ Could not extract ACTION from prompt")
            return nil
        }

        guard let scene = extractSection(from: normalized, sectionName: "SCENE") else {
            print("[Sora] ⚠️ Could not extract SCENE from prompt")
            return nil
        }

        // These are optional but we'll provide defaults
        let style = extractSection(from: normalized, sectionName: "STYLE") ?? ""
        let dialogue = extractSection(from: normalized, sectionName: "DIALOGUE") ?? ""
        let subject = extractSection(from: normalized, sectionName: "SUBJECT") ?? ""
        let negativePrompt = extractSection(from: normalized, sectionName: "NEGATIVE PROMPT") ?? ""
        let aspect = extractSection(from: normalized, sectionName: "ASPECT") ?? ""

        let components = PromptComponents(
            subject: subject,
            action: action,
            scene: scene,
            style: style,
            dialogue: dialogue,
            negativePrompt: negativePrompt,
            aspect: aspect
        )

        print("[Sora] ✅ Successfully parsed prompt components")
        return components
    }

    // MARK: - Section Extraction
    private func extractSection(from text: String, sectionName: String) -> String? {
        // Pattern to match section header and capture content until next section or end
        // Matches: SECTION:\n content \n\n NEXT_SECTION: or end
        let pattern = "\(sectionName):\\s*([\\s\\S]*?)(?=\\n\\n[A-Z ]+:|$)"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        guard let match = matches.first,
              match.numberOfRanges > 1 else {
            return nil
        }

        let captureRange = match.range(at: 1)
        var content = nsString.substring(with: captureRange)

        // Clean up the content
        content = cleanExtractedContent(content, sectionName: sectionName)

        return content.isEmpty ? nil : content
    }

    // MARK: - Content Cleaning
    private func cleanExtractedContent(_ content: String, sectionName: String) -> String {
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)

        // Special handling for SUBJECT - remove SUBJECT REFERENCE PLATES section
        if sectionName == "SUBJECT" {
            if let referencePlatesRange = cleaned.range(of: "SUBJECT REFERENCE PLATES:", options: .caseInsensitive) {
                // Remove everything from "SUBJECT REFERENCE PLATES:" onwards
                cleaned = String(cleaned[..<referencePlatesRange.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Remove extra internal whitespace (multiple spaces/newlines to single space)
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        return cleaned
    }
}

// MARK: - Helper Extensions
extension String {
    /// Calculates Levenshtein distance between two strings
    /// Used for fuzzy matching in ShotMatcher
    func levenshteinDistance(to other: String) -> Int {
        let m = self.count
        let n = other.count

        if m == 0 { return n }
        if n == 0 { return m }

        var matrix = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m {
            matrix[i][0] = i
        }

        for j in 0...n {
            matrix[0][j] = j
        }

        for i in 1...m {
            for j in 1...n {
                let cost = self[self.index(self.startIndex, offsetBy: i - 1)] ==
                          other[other.index(other.startIndex, offsetBy: j - 1)] ? 0 : 1

                matrix[i][j] = Swift.min(
                    matrix[i - 1][j] + 1,      // deletion
                    matrix[i][j - 1] + 1,      // insertion
                    matrix[i - 1][j - 1] + cost // substitution
                )
            }
        }

        return matrix[m][n]
    }

    /// Returns similarity score between 0.0 (completely different) and 1.0 (identical)
    func similarity(to other: String) -> Double {
        let distance = Double(self.levenshteinDistance(to: other))
        let maxLength = Double(Swift.max(self.count, other.count))

        guard maxLength > 0 else { return 1.0 }

        return 1.0 - (distance / maxLength)
    }
}
