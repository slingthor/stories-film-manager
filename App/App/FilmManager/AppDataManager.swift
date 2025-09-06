import Foundation

class AppDataManager {
    static let shared = AppDataManager()
    
    private let baseAppDataPath = "/Users/ingthor/Documents/stories/appdata"
    private let jsonPath: String
    private let resourcesPath: String
    
    var currentVersionPath: String {
        return jsonPath
    }
    
    var mediaResourcesPath: String {
        return resourcesPath
    }
    
    private init() {
        self.resourcesPath = "\(baseAppDataPath)/resources"
        
        // Ensure base directories exist
        try? FileManager.default.createDirectory(
            atPath: "\(baseAppDataPath)/json",
            withIntermediateDirectories: true,
            attributes: nil
        )
        try? FileManager.default.createDirectory(
            atPath: resourcesPath,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        // Find or create the current version directory
        self.jsonPath = AppDataManager.findOrCreateCurrentVersion()
    }
    
    private static func findOrCreateCurrentVersion() -> String {
        let jsonBasePath = "/Users/ingthor/Documents/stories/appdata/json"
        let fm = FileManager.default
        
        // Find the highest numbered directory
        var highestVersion = 0
        if let contents = try? fm.contentsOfDirectory(atPath: jsonBasePath) {
            for item in contents {
                if let version = Int(item) {
                    highestVersion = max(highestVersion, version)
                }
            }
        }
        
        // Check if we need to create a new version (based on build)
        let currentVersionPath = "\(jsonBasePath)/\(highestVersion)"
        let needsNewVersion = highestVersion == 0 || shouldCreateNewVersion(currentPath: currentVersionPath)
        
        if needsNewVersion {
            let newVersion = highestVersion + 1
            let newVersionPath = "\(jsonBasePath)/\(newVersion)"
            
            // Create new version directory
            try? fm.createDirectory(
                atPath: newVersionPath,
                withIntermediateDirectories: true,
                attributes: nil
            )
            
            // Create shots subdirectory
            try? fm.createDirectory(
                atPath: "\(newVersionPath)/shots",
                withIntermediateDirectories: true,
                attributes: nil
            )
            
            // Copy from previous version if it exists
            if highestVersion > 0 {
                copyPreviousVersion(from: currentVersionPath, to: newVersionPath)
            }
            
            // Update with latest resources from app bundle
            updateFromAppResources(to: newVersionPath)
            
            print("📁 Created new version directory: \(newVersionPath)")
            return newVersionPath
        }
        
        print("📁 Using existing version directory: \(currentVersionPath)")
        return currentVersionPath
    }
    
    private static func shouldCreateNewVersion(currentPath: String) -> Bool {
        // Check if a marker file exists indicating this is a new build
        let markerPath = "\(currentPath)/.build_marker"
        let fm = FileManager.default
        
        // Get app bundle modification date
        guard let bundlePath = Bundle.main.resourcePath,
              let bundleAttributes = try? fm.attributesOfItem(atPath: bundlePath),
              let bundleModDate = bundleAttributes[.modificationDate] as? Date else {
            return false
        }
        
        // If marker doesn't exist, create new version
        if !fm.fileExists(atPath: markerPath) {
            return true
        }
        
        // Check if bundle is newer than marker
        if let markerAttributes = try? fm.attributesOfItem(atPath: markerPath),
           let markerModDate = markerAttributes[.modificationDate] as? Date {
            return bundleModDate > markerModDate
        }
        
        return true
    }
    
    private static func copyPreviousVersion(from oldPath: String, to newPath: String) {
        let fm = FileManager.default
        
        // Copy all JSON files from previous version
        if let items = try? fm.contentsOfDirectory(atPath: oldPath) {
            for item in items {
                if item.hasSuffix(".json") || item == "shots" {
                    let sourcePath = "\(oldPath)/\(item)"
                    let destPath = "\(newPath)/\(item)"
                    
                    if item == "shots" {
                        // Copy shots directory
                        if let shots = try? fm.contentsOfDirectory(atPath: sourcePath) {
                            try? fm.createDirectory(atPath: destPath, withIntermediateDirectories: true, attributes: nil)
                            for shot in shots {
                                try? fm.copyItem(
                                    atPath: "\(sourcePath)/\(shot)",
                                    toPath: "\(destPath)/\(shot)"
                                )
                            }
                        }
                    } else {
                        // Copy individual JSON files
                        try? fm.copyItem(atPath: sourcePath, toPath: destPath)
                    }
                }
            }
            print("📋 Copied data from version \(oldPath) to \(newPath)")
        }
    }
    
    private static func updateFromAppResources(to versionPath: String) {
        let fm = FileManager.default
        
        // List of resource files to copy
        let resourceFiles = [
            "environmental_plates_index.json",
            "character_plates_index.json",
            "shot_plate_recommendations.json",
            "main_film_system.json"
        ]
        
        // Try to find Resources directory
        let possibleResourcePaths = [
            "\(Bundle.main.resourcePath ?? "")/Resources",
            "/Users/ingthor/Documents/stories/App/App/FilmManager/Resources"
        ]
        
        for resourceBasePath in possibleResourcePaths {
            if fm.fileExists(atPath: resourceBasePath) {
                for file in resourceFiles {
                    let sourcePath = "\(resourceBasePath)/\(file)"
                    let destPath = "\(versionPath)/\(file)"
                    
                    if fm.fileExists(atPath: sourcePath) {
                        // Remove old file if it exists
                        try? fm.removeItem(atPath: destPath)
                        // Copy new file
                        try? fm.copyItem(atPath: sourcePath, toPath: destPath)
                        print("📦 Updated \(file) from app resources")
                    }
                }
                
                // Copy shot files if they exist
                let shotSourcePath = "\(resourceBasePath)/shots"
                if fm.fileExists(atPath: shotSourcePath) {
                    if let shots = try? fm.contentsOfDirectory(atPath: shotSourcePath) {
                        for shot in shots where shot.hasSuffix(".json") {
                            let sourcePath = "\(shotSourcePath)/\(shot)"
                            let destPath = "\(versionPath)/shots/\(shot)"
                            
                            // Only copy if the shot doesn't exist in destination
                            if !fm.fileExists(atPath: destPath) {
                                try? fm.copyItem(atPath: sourcePath, toPath: destPath)
                                print("📦 Added new shot: \(shot)")
                            }
                        }
                    }
                }
                
                break
            }
        }
        
        // Create build marker
        let markerPath = "\(versionPath)/.build_marker"
        fm.createFile(atPath: markerPath, contents: nil, attributes: nil)
    }
    
    // Path helper methods
    func shotPath(for shotId: String) -> String {
        return "\(currentVersionPath)/shots/\(shotId).json"
    }
    
    func characterPlateIndexPath() -> String {
        return "\(currentVersionPath)/character_plates_index.json"
    }
    
    func environmentalPlateIndexPath() -> String {
        return "\(currentVersionPath)/environmental_plates_index.json"
    }
    
    func recommendationsPath() -> String {
        return "\(currentVersionPath)/shot_plate_recommendations.json"
    }
    
    func mainSystemPath() -> String {
        return "\(currentVersionPath)/main_film_system.json"
    }
    
    // Media resource management
    func mediaPath(for type: String, id: String, filename: String) -> String {
        let typePath = "\(resourcesPath)/\(type)/\(id)"
        try? FileManager.default.createDirectory(
            atPath: typePath,
            withIntermediateDirectories: true,
            attributes: nil
        )
        return "\(typePath)/\(filename)"
    }
    
    func copyMediaToResources(from sourcePath: String, type: String, id: String) -> String? {
        let filename = URL(fileURLWithPath: sourcePath).lastPathComponent
        let destPath = mediaPath(for: type, id: id, filename: filename)
        
        do {
            // Remove existing file if it exists
            try? FileManager.default.removeItem(atPath: destPath)
            // Copy new file
            try FileManager.default.copyItem(atPath: sourcePath, toPath: destPath)
            print("📷 Copied media to: \(destPath)")
            return destPath
        } catch {
            print("❌ Failed to copy media: \(error)")
            return nil
        }
    }
}