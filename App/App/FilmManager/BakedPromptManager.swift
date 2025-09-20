import Foundation
import AppKit

class BakedPromptManager {
    static let shared = BakedPromptManager()

    private var bakedPromptsDirectory: String {
        let appDataPath = AppDataManager.shared.currentVersionPath
        return "\(appDataPath)/baked_prompts"
    }

    private init() {
        createBakedPromptsDirectory()
    }

    private func createBakedPromptsDirectory() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: bakedPromptsDirectory) {
            try? fm.createDirectory(atPath: bakedPromptsDirectory, withIntermediateDirectories: true, attributes: nil)
            print("📁 Created baked prompts directory at: \(bakedPromptsDirectory)")
        }
    }

    // Get metadata file path for a variant
    private func getMetadataFilepath(for variantId: String) -> String {
        return "\(bakedPromptsDirectory)/\(variantId)_metadata.json"
    }

    // Save baked prompts metadata to JSON file
    func saveBakedPromptsMetadata(_ bakedPrompts: [BakedPrompt], for variantId: String) throws {
        let metadataPath = getMetadataFilepath(for: variantId)

        var metadataArray: [[String: Any]] = []
        for bakedPrompt in bakedPrompts {
            var metadata: [String: Any] = [
                "id": bakedPrompt.id.uuidString,
                "name": bakedPrompt.name,
                "created_date": ISO8601DateFormatter().string(from: bakedPrompt.createdDate),
                "modified_date": ISO8601DateFormatter().string(from: bakedPrompt.modifiedDate)
            ]
            if let generator = bakedPrompt.generator {
                metadata["generator"] = generator
            }
            metadataArray.append(metadata)
        }

        let jsonData = try JSONSerialization.data(withJSONObject: metadataArray, options: .prettyPrinted)
        try jsonData.write(to: URL(fileURLWithPath: metadataPath))
        print("💾 Saved baked prompts metadata for variant \(variantId): \(bakedPrompts.count) prompts")
    }

    // Load baked prompts metadata from JSON file
    func loadBakedPromptsMetadata(for variantId: String) -> [BakedPrompt] {
        let metadataPath = getMetadataFilepath(for: variantId)

        guard let data = FileManager.default.contents(atPath: metadataPath),
              let metadataArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        var bakedPrompts: [BakedPrompt] = []
        let formatter = ISO8601DateFormatter()

        for metadata in metadataArray {
            if let idString = metadata["id"] as? String,
               let id = UUID(uuidString: idString),
               let name = metadata["name"] as? String,
               let createdDateString = metadata["created_date"] as? String,
               let modifiedDateString = metadata["modified_date"] as? String {

                let createdDate = formatter.date(from: createdDateString) ?? Date()
                let modifiedDate = formatter.date(from: modifiedDateString) ?? Date()
                let generator = metadata["generator"] as? String

                let bakedPrompt = BakedPrompt(
                    id: id,
                    name: name,
                    createdDate: createdDate,
                    modifiedDate: modifiedDate,
                    generator: generator
                )
                bakedPrompts.append(bakedPrompt)
            }
        }

        print("📂 Loaded baked prompts metadata for variant \(variantId): \(bakedPrompts.count) prompts")
        return bakedPrompts
    }

    // Delete metadata file for a variant
    func deleteBakedPromptsMetadata(for variantId: String) {
        let metadataPath = getMetadataFilepath(for: variantId)
        try? FileManager.default.removeItem(atPath: metadataPath)
        print("🗑️ Deleted baked prompts metadata for variant \(variantId)")
    }

    // Save baked prompt text to file
    func saveBakedPromptContent(_ content: String, for bakedPrompt: BakedPrompt) throws {
        let filename = "\(bakedPrompt.id.uuidString).txt"
        let filepath = "\(bakedPromptsDirectory)/\(filename)"

        // Embed the name in the first line of the file
        let contentWithName = "# \(bakedPrompt.name)\n\n\(content)"

        guard let data = contentWithName.data(using: .utf8) else {
            throw NSError(domain: "BakedPromptManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode content"])
        }

        try data.write(to: URL(fileURLWithPath: filepath))
        print("💾 Saved baked prompt: \(bakedPrompt.name) to \(filename)")
    }

    // Load baked prompt text from file
    func loadBakedPromptContent(for bakedPrompt: BakedPrompt) -> String? {
        let filename = "\(bakedPrompt.id.uuidString).txt"
        let filepath = "\(bakedPromptsDirectory)/\(filename)"

        guard let data = FileManager.default.contents(atPath: filepath),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }

        // Remove the name header if present (first line starting with #)
        let lines = content.components(separatedBy: "\n")
        if lines.first?.hasPrefix("# ") == true {
            return lines.dropFirst().dropFirst().joined(separator: "\n")
        }

        return content
    }

    // Delete baked prompt file
    func deleteBakedPromptContent(for bakedPrompt: BakedPrompt) {
        let filename = "\(bakedPrompt.id.uuidString).txt"
        let filepath = "\(bakedPromptsDirectory)/\(filename)"

        try? FileManager.default.removeItem(atPath: filepath)
        print("🗑️ Deleted baked prompt file: \(filename)")
    }

    // Check if baked prompt file exists
    func bakedPromptFileExists(for bakedPrompt: BakedPrompt) -> Bool {
        let filename = "\(bakedPrompt.id.uuidString).txt"
        let filepath = "\(bakedPromptsDirectory)/\(filename)"
        return FileManager.default.fileExists(atPath: filepath)
    }

    // Get file path for a baked prompt
    func getFilepath(for bakedPrompt: BakedPrompt) -> String {
        let filename = "\(bakedPrompt.id.uuidString).txt"
        return "\(bakedPromptsDirectory)/\(filename)"
    }

    // Copy baked prompt to clipboard
    func copyToClipboard(_ content: String) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: NSPasteboard.PasteboardType.string)
        #endif
    }
}
