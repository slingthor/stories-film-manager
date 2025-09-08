import Foundation

struct ShotVariant: Identifiable, Codable {
    let id: String
    let shotId: String
    let variantName: String
    let title: String
    let duration: Int
    let narrativeFunction: String
    let filePath: String
    
    var displayName: String {
        return title.replacingOccurrences(of: "_", with: " ")
    }
}

class ShotVariantManager: ObservableObject {
    @Published var variants: [String: [ShotVariant]] = [:]
    @Published var selectedVariants: [String: String] = [:]
    
    private let shotsPath: String
    
    init(shotsPath: String = "/Users/ingthor/Documents/stories/appdata/json/5/shots/json") {
        self.shotsPath = shotsPath
        loadVariants()
    }
    
    func loadVariants() {
        do {
            let fileManager = FileManager.default
            let files = try fileManager.contentsOfDirectory(atPath: shotsPath)
            let jsonFiles = files.filter { $0.hasSuffix(".json") }
            
            var tempVariants: [String: [ShotVariant]] = [:]
            
            for file in jsonFiles {
                let filePath = "\(shotsPath)/\(file)"
                if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let metadata = json["shot_metadata"] as? [String: Any],
                   let shotId = metadata["id"] as? String,
                   let title = metadata["title"] as? String,
                   let name = metadata["name"] as? String,
                   let duration = metadata["duration_seconds"] as? Int,
                   let narrativeFunction = metadata["narrative_function"] as? String {
                    
                    let variant = ShotVariant(
                        id: UUID().uuidString,
                        shotId: shotId,
                        variantName: name,
                        title: title,
                        duration: duration,
                        narrativeFunction: narrativeFunction,
                        filePath: filePath
                    )
                    
                    if tempVariants[shotId] == nil {
                        tempVariants[shotId] = []
                    }
                    tempVariants[shotId]?.append(variant)
                }
            }
            
            for (shotId, shotVariants) in tempVariants {
                tempVariants[shotId] = shotVariants.sorted { $0.title < $1.title }
                if let first = shotVariants.first {
                    selectedVariants[shotId] = first.variantName
                }
            }
            
            variants = tempVariants
        } catch {
            print("Error loading shot variants: \(error)")
        }
    }
    
    func getVariantsForShot(_ shotId: String) -> [ShotVariant] {
        return variants[shotId] ?? []
    }
    
    func selectVariant(for shotId: String, variantName: String) {
        selectedVariants[shotId] = variantName
    }
    
    func getSelectedVariant(for shotId: String) -> ShotVariant? {
        guard let variantName = selectedVariants[shotId],
              let shotVariants = variants[shotId] else { return nil }
        return shotVariants.first { $0.variantName == variantName }
    }
    
    func compareVariants(for shotId: String) -> String {
        guard let shotVariants = variants[shotId], shotVariants.count > 1 else {
            return "No variants to compare"
        }
        
        var comparison = "Shot \(shotId) Variants Comparison:\n"
        comparison += "="*50 + "\n\n"
        
        for variant in shotVariants {
            comparison += "Title: \(variant.displayName)\n"
            comparison += "Duration: \(variant.duration) seconds\n"
            comparison += "Narrative Function: \(variant.narrativeFunction)\n"
            comparison += "-"*30 + "\n"
        }
        
        return comparison
    }
}