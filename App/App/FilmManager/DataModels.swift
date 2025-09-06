import Foundation
import Combine
import SwiftUI

// MARK: - Complete Data Models with Proper ObservableObject Conformance

class FilmManager: ObservableObject {
    @Published var shots: [FilmShot] = []
    @Published var selectedShot: FilmShot? {
        didSet {
            updateSystemsForSelectedShot()
        }
    }
    @Published var trackingSystems: [TrackingSystem] = []
    @Published var timelinePosition: Double = 0.0
    @Published var totalDuration: Double = 0.0
    @Published var isPlaying: Bool = false
    @Published var shouldFollowTimeline: Bool = true
    
    let fileManager = FilmFileManager()
    let plateManager = PlateManager()
    private var autoSaveTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupTrackingSystems()
        loadFilmData()
        setupAutoSave()
        setupNotifications()
    }
    
    private func setupTrackingSystems() {
        trackingSystems = [
            TrackingSystem(name: "breathing_coordination", description: "Family respiratory synchronization progression", currentPercentage: 32.0),
            TrackingSystem(name: "temperature_progression", description: "Environmental and body temperature changes", currentPercentage: 28.0),
            TrackingSystem(name: "klettagja_formation", description: "Cliff cleft development for Sigrid's escape", currentPercentage: 15.0),
            TrackingSystem(name: "spatial_impossibilities", description: "Mathematical physics violations spreading", currentPercentage: 25.0),
            TrackingSystem(name: "house_dimensions", description: "Baðstofa interior space expansion sensation", currentPercentage: 0.0),
            TrackingSystem(name: "house_consciousness", description: "Bergrisi awareness and biological responses", currentPercentage: 35.0),
            TrackingSystem(name: "reality_coherence", description: "Stability of physical laws and logic", currentPercentage: 65.0),
            TrackingSystem(name: "industrial_contamination", description: "British/Danish imperial materials spreading", currentPercentage: 22.0),
            TrackingSystem(name: "hakarl_contamination", description: "Traditional food corruption enabling breakdown", currentPercentage: 18.0),
            TrackingSystem(name: "predatory_landscape", description: "Environmental hostility toward human survival", currentPercentage: 15.0),
            TrackingSystem(name: "weather_hostility", description: "Atmospheric assault on family survival", currentPercentage: 10.0),
            TrackingSystem(name: "light_sources", description: "Illumination evolution organic→industrial→supernatural", currentPercentage: 5.0),
            TrackingSystem(name: "memory_degradation", description: "Collective memory accuracy declining", currentPercentage: 5.0),
            TrackingSystem(name: "color_grading", description: "Film color palette psychological progression", currentPercentage: 15.0),
            TrackingSystem(name: "character_shadow_behavior", description: "Shadow physics revealing animal truth", currentPercentage: 8.0),
            TrackingSystem(name: "stain_progression", description: "F4 Liquid contamination marking progression", currentPercentage: 35.0)
        ]
    }
    
    private func loadFilmData() {
        print("🚀 Starting to load film data...")
        
        // Load ALL shots from the directory
        shots = loadAllShotsFromDirectory()
        
        if shots.isEmpty {
            print("⚠️ No shots loaded, using sample data")
            loadSampleData()
        } else {
            print("✅ Successfully loaded \(shots.count) shots")
            
            // List first few shots for verification
            for (index, shot) in shots.prefix(5).enumerated() {
                print("   Shot \(index + 1): \(shot.id) - \(shot.title)")
            }
        }
        
        // Load tracking system data from main_film_system.json
        loadTrackingSystemsFromMainFile()
        
        selectedShot = shots.first
        calculateTotalDuration()
    }
    
    private func loadAllShotsFromDirectory() -> [FilmShot] {
        var loadedShots: [FilmShot] = []
        
        // Try to load from app bundle first
        if let bundlePath = Bundle.main.resourcePath {
            print("📦 Attempting to load from app bundle")
            
            // Try both possible locations
            let possiblePaths = [
                "\(bundlePath)/Resources/shots/json",  // Our new location
                "\(bundlePath)/shots/json",  // If you kept folder structure
                "\(bundlePath)/json",  // If you added as folder reference
                bundlePath  // If files are at root of resources
            ]
            
            for path in possiblePaths {
                if let files = try? FileManager.default.contentsOfDirectory(atPath: path) {
                    let jsonFiles = files.filter { $0.hasSuffix(".json") && $0.contains("shot_") }
                    if !jsonFiles.isEmpty {
                        print("✅ Found \(jsonFiles.count) shot JSON files in bundle at: \(path)")
                        loadedShots = loadShotsFromFiles(jsonFiles, directory: path)
                        break
                    }
                }
            }
        }
        
        // If no shots loaded from bundle, try the original path (for development)
        if loadedShots.isEmpty {
            let shotsPath = "/Users/ingthor/Documents/stories/App/shots/json"
            print("📁 Trying development path: \(shotsPath)")
            
            guard let files = try? FileManager.default.contentsOfDirectory(atPath: shotsPath) else {
                print("❌ Could not read directory")
                return []
            }
            
            let jsonFiles = files.filter { $0.hasSuffix(".json") }
            loadedShots = loadShotsFromFiles(jsonFiles, directory: shotsPath)
        }
        
        return loadedShots
    }
    
    private func loadShotsFromFiles(_ jsonFiles: [String], directory: String) -> [FilmShot] {
        var loadedShots: [FilmShot] = []
        var seenIds = Set<String>()  // Track loaded shot IDs to prevent duplicates
        
        print("📄 Processing \(jsonFiles.count) JSON files from \(directory)")
        
        for file in jsonFiles {
            let filepath = "\(directory)/\(file)"
            
            guard let data = FileManager.default.contents(atPath: filepath) else {
                print("⚠️ Could not read file: \(file)")
                continue
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("⚠️ Could not parse JSON: \(file)")
                continue
            }
            
            guard let metadata = json["shot_metadata"] as? [String: Any],
                  let id = metadata["id"] as? String else {
                print("⚠️ Missing metadata in: \(file)")
                continue
            }
            
            // Check for duplicate IDs
            if seenIds.contains(id) {
                print("⚠️ Duplicate shot ID detected, skipping: \(id) from file: \(file)")
                continue
            }
            seenIds.insert(id)
            
            let title = (metadata["title"] as? String) ?? 
                       (metadata["name"] as? String) ?? 
                       "Shot \(id)"
            
            let sequenceType = (metadata["sequence_type"] as? String) ?? "main_story"
            
            // Create shot with basic info
            let shot = FilmShot(
                id: id,
                title: title,
                sequenceType: sequenceType,
                position: 0, // Will be set later
                subject: "",
                action: "",
                scene: "",
                style: ""
            )
            
            // Set additional properties
            shot.duration = (metadata["duration_seconds"] as? Int) ?? 8
            shot.narrativeFunction = metadata["narrative_function"] as? String ?? ""
            shot.progressiveState = json["progressive_state"] as? String ?? ""
            
            // Load prompt variants
            if let prompts = json["prompt_variants"] as? [[String: Any]], !prompts.isEmpty {
                shot.promptVariants = []
                for prompt in prompts {
                    let variant = PromptVariant(
                        variantId: prompt["variant_id"] as? String ?? "\(id)_variant",
                        name: prompt["variant_name"] as? String ?? "Primary",
                        subject: prompt["subject"] as? String ?? "",
                        action: prompt["action"] as? String ?? "",
                        scene: prompt["scene"] as? String ?? "",
                        style: prompt["style"] as? String ?? ""
                    )
                    variant.dialogue = prompt["dialogue"] as? String ?? ""
                    variant.cameraPosition = prompt["camera_position"] as? String ?? ""
                    variant.negativePrompt = prompt["negative_prompt"] as? String ?? ""
                    shot.promptVariants.append(variant)
                }
            }
            
            loadedShots.append(shot)
        }
        
        print("📊 Loaded \(loadedShots.count) shots, now sorting...")
        
        // Sort shots: prologue first, then main_story, sorted by ID
        loadedShots.sort { shot1, shot2 in
            if shot1.sequenceType != shot2.sequenceType {
                return shot1.sequenceType == "prologue"
            }
            
            // Extract numeric values for sorting
            let id1 = extractNumericFromId(shot1.id)
            let id2 = extractNumericFromId(shot2.id)
            return id1 < id2
        }
        
        // Update positions based on sorted order
        for (index, shot) in loadedShots.enumerated() {
            shot.position = Double(index) / Double(max(1, loadedShots.count - 1)) * 100.0
        }
        
        return loadedShots
    }
    
    private func extractNumericFromId(_ id: String) -> Double {
        // Handle IDs like "-1", "0a", "0b", "1", "39.5", etc.
        // Check for negative numbers first
        if id.hasPrefix("-") {
            let numericString = id.dropFirst().replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            var value = -(Double(numericString) ?? 0)
            // Add letter offset for suffixes
            if id.contains("a") { value -= 0.3 }
            else if id.contains("b") { value -= 0.2 }
            else if id.contains("c") { value -= 0.1 }
            return value
        }
        
        let numericString = id.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        var value = Double(numericString) ?? 0
        
        // Add small offset for letter suffixes
        if id.hasSuffix("a") { value += 0.1 }
        else if id.hasSuffix("b") { value += 0.2 }
        else if id.hasSuffix("c") { value += 0.3 }
        else if id.hasSuffix("d") { value += 0.4 }
        
        return value
    }
    
    private func loadTrackingSystemsFromMainFile() {
        guard let systemData = fileManager.loadMainSystemData(),
              let trackingData = systemData["tracking_systems"] as? [String: Any] else {
            print("⚠️ Could not load tracking systems from main file, using defaults")
            return
        }
        
        // Update tracking systems with data from main file
        for (index, system) in trackingSystems.enumerated() {
            if let systemInfo = trackingData[system.name] as? [String: Any] {
                if let percentage = systemInfo["current_percentage"] as? Double {
                    trackingSystems[index].currentPercentage = percentage
                }
                
                // Load milestone values if available
                if let milestones = systemInfo["milestone_values"] as? [String: String] {
                    trackingSystems[index].milestoneValues = milestones
                }
                
                // Load affects_shots if available
                if let affectsShots = systemInfo["affects_shots"] as? [String] {
                    trackingSystems[index].affectsShots = affectsShots
                }
            }
        }
        
        print("✅ Updated tracking systems from main_film_system.json")
    }
    
    private func loadSampleData() {
        shots = [
            FilmShot(id: "0a", title: "The Shadow Pole - Curse Establishment", sequenceType: "prologue", position: 0.5, 
                    subject: "A tall piece of grey driftwood standing vertical on a grass-covered headland, rope wrapped around its top section, casting a shadow 200 feet long across green hills while the ocean behind shows red tints under blue surface and purple berries cover distant slopes.",
                    action: "Camera starts 100 feet above pole, descending slowly. The pole is 8 feet tall, weathered grey driftwood, standing perfectly vertical. Old rope wraps the top 2 feet, frayed ends moving slightly. The shadow stretches far beyond natural length - reaching 200 feet across grass.",
                    scene: "Headland in Westfjords, 5 AM June morning. Ocean 300 feet beyond pole. Berry-covered hills to left. Golden cliffs to right. Green grass everywhere. Clear sky, sun just above horizon.",
                    style: "Aerial descent toward pole, camera moving straight down (that's where the camera is), slow smooth movement, wide lens showing all terrains.")
        ]
    }
    
    private func loadShotsDirectly() -> [FilmShot] {
        var directShots: [FilmShot] = []
        let shotsPath = "/Users/ingthor/Documents/stories/App/shots/json"
        
        // Try loading with URL-based approach
        let url = URL(fileURLWithPath: shotsPath)
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "json" }
            
            print("📂 Found \(fileURLs.count) JSON files via URL method")
            
            for fileURL in fileURLs { // Load all files
                do {
                    let data = try Data(contentsOf: fileURL)
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    if let metadata = json?["shot_metadata"] as? [String: Any],
                       let id = metadata["id"] as? String {
                        
                        let title = (metadata["title"] as? String) ?? 
                                   (metadata["name"] as? String) ?? "Untitled"
                        let sequenceType = (metadata["sequence_type"] as? String) ?? "main_story"
                        
                        let shot = FilmShot(
                            id: id,
                            title: title,
                            sequenceType: sequenceType,
                            position: 0,
                            subject: "",
                            action: "",
                            scene: "",
                            style: ""
                        )
                        
                        // Parse first prompt variant if available
                        if let prompts = json?["prompt_variants"] as? [[String: Any]],
                           let firstPrompt = prompts.first {
                            shot.promptVariants[0].subject = firstPrompt["subject"] as? String ?? ""
                            shot.promptVariants[0].action = firstPrompt["action"] as? String ?? ""
                            shot.promptVariants[0].scene = firstPrompt["scene"] as? String ?? ""
                            shot.promptVariants[0].style = firstPrompt["style"] as? String ?? ""
                        }
                        
                        directShots.append(shot)
                        print("   ✅ Loaded: \(id) - \(title)")
                    }
                } catch {
                    print("   ❌ Failed to load \(fileURL.lastPathComponent): \(error)")
                }
            }
        } catch {
            print("❌ Direct loading failed: \(error)")
        }
        
        // Sort the shots
        directShots.sort { shot1, shot2 in
            if shot1.sequenceType != shot2.sequenceType {
                return shot1.sequenceType == "prologue"
            }
            let id1 = self.extractNumericValueSimple(shot1.id)
            let id2 = self.extractNumericValueSimple(shot2.id)
            return id1 < id2
        }
        
        return directShots
    }
    
    private func extractNumericValueSimple(_ id: String) -> Double {
        let numericString = id.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        var value = Double(numericString) ?? 0
        if id.contains("a") { value += 0.1 }
        else if id.contains("b") { value += 0.2 }
        return value
    }
    
    private func setupAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            self.saveAllChanges()
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .saveAll)
            .sink { _ in
                self.saveAllChanges()
            }
            .store(in: &cancellables)
    }
    
    func saveAllChanges() {
        print("💾 Auto-saving all changes...")
        for shot in shots where shot.isDirty {
            fileManager.saveShot(shot)
        }
        fileManager.saveMainSystem(trackingSystems)
        plateManager.savePlates()
    }
    
    func reorderShots(from source: IndexSet, to destination: Int) {
        shots.move(fromOffsets: source, toOffset: destination)
        updateShotPositions()
        calculateTotalDuration()
    }
    
    func moveShotUp(_ shot: FilmShot) {
        guard let index = shots.firstIndex(where: { $0.id == shot.id }), index > 0 else { return }
        shots.swapAt(index, index - 1)
        updateShotPositions()
    }
    
    func moveShotDown(_ shot: FilmShot) {
        guard let index = shots.firstIndex(where: { $0.id == shot.id }), index < shots.count - 1 else { return }
        shots.swapAt(index, index + 1)
        updateShotPositions()
    }
    
    private func updateShotPositions() {
        for (index, shot) in shots.enumerated() {
            shot.position = (Double(index) / Double(shots.count - 1)) * 100.0
            shot.isDirty = true
        }
    }
    
    private func calculateTotalDuration() {
        totalDuration = Double(shots.reduce(0) { $0 + $1.duration })
    }
    
    private func updateSystemsForSelectedShot() {
        guard let shot = selectedShot else { return }
        print("📊 Selected shot \(shot.id) at \(shot.position)%")
    }
    
    func placeSystemAtShot(_ system: TrackingSystem, _ shot: FilmShot) {
        system.currentPercentage = shot.position
        print("📍 Placed \(system.name) at \(shot.position)% (Shot \(shot.id): \(shot.title))")
    }
    
    func getSystemsAffectingShot(_ shot: FilmShot) -> [TrackingSystem] {
        return trackingSystems.filter { system in
            abs(system.currentPercentage - shot.position) < 5.0
        }
    }
    
    func getShotAtPercentage(_ percentage: Double) -> FilmShot? {
        return shots.min { abs($0.position - percentage) < abs($1.position - percentage) }
    }
    
    func updateTimelineFromSelectedVideos() {
        let videoShots = shots.filter { $0.selectedVideo != nil }
        print("🎬 Timeline updated: \(videoShots.count) shots with selected videos")
    }
    
    func deleteShot(_ shot: FilmShot) {
        guard let index = shots.firstIndex(where: { $0.id == shot.id }) else { return }
        
        // Remove the shot
        shots.remove(at: index)
        
        // Update positions for remaining shots
        updateShotPositions()
        
        // Select next shot or previous if last
        if shots.isEmpty {
            selectedShot = nil
        } else if index < shots.count {
            selectedShot = shots[index]
        } else if index > 0 {
            selectedShot = shots[index - 1]
        } else {
            selectedShot = shots.first
        }
        
        // Recalculate total duration
        calculateTotalDuration()
        
        print("🗑️ Deleted shot: \(shot.id) - \(shot.title)")
    }
    
    func copyShotAfterCurrent() {
        guard let currentShot = selectedShot,
              let currentIndex = shots.firstIndex(where: { $0.id == currentShot.id }) else {
            return
        }
        
        // Generate new ID for the copy
        let baseId = currentShot.id
        var newId = "\(baseId).1"
        var counter = 1
        
        // Ensure we create a truly unique ID
        while shots.contains(where: { $0.id == newId }) {
            counter += 1
            newId = "\(baseId).\(counter)"
        }
        
        // Create copy of the shot
        let copiedShot = FilmShot(
            id: newId,
            title: "\(currentShot.title) (Copy)",
            sequenceType: currentShot.sequenceType,
            position: currentShot.position + 0.5, // Position between current and next
            subject: "",
            action: "",
            scene: "",
            style: ""
        )
        
        // Copy all properties
        copiedShot.duration = currentShot.duration
        copiedShot.aspectRatio = currentShot.aspectRatio
        copiedShot.progressiveState = currentShot.progressiveState
        copiedShot.narrativeFunction = currentShot.narrativeFunction
        copiedShot.stitchFrom = currentShot.stitchFrom
        
        // Copy all prompt variants
        for variant in currentShot.promptVariants {
            let copiedVariant = PromptVariant(
                variantId: "\(newId)_\(variant.variantId.split(separator: "_").last ?? "variant")",
                name: variant.name,
                subject: variant.subject,
                action: variant.action,
                scene: variant.scene,
                style: variant.style
            )
            
            copiedVariant.dialogue = variant.dialogue
            copiedVariant.cameraPosition = variant.cameraPosition
            copiedVariant.negativePrompt = variant.negativePrompt
            copiedVariant.progressiveState = variant.progressiveState
            copiedVariant.selectedCharacterPlateId = variant.selectedCharacterPlateId
            copiedVariant.selectedEnvironmentPlateId = variant.selectedEnvironmentPlateId
            copiedVariant.customCharacterPlate = variant.customCharacterPlate
            copiedVariant.customEnvironmentPlate = variant.customEnvironmentPlate
            copiedVariant.isActive = variant.isActive
            
            copiedShot.promptVariants.append(copiedVariant)
        }
        
        // Note: Don't copy videos or images - start with empty media
        
        // Insert the copied shot after the current one
        shots.insert(copiedShot, at: currentIndex + 1)
        
        // Update positions for all shots
        updateShotPositions()
        
        // Select the new copy
        selectedShot = copiedShot
        
        // Mark as dirty for saving
        copiedShot.isDirty = true
        
        print("📋 Created copy of shot \(currentShot.id) as \(newId)")
    }
}

class FilmShot: ObservableObject, Identifiable {
    let id: String
    @Published var title: String
    @Published var sequenceType: String
    @Published var position: Double
    @Published var duration: Int = 8
    @Published var aspectRatio: String = "16:9"
    @Published var promptVariants: [PromptVariant] = []
    @Published var selectedPromptIndex: Int = 0
    @Published var videos: [VideoFile] = []
    @Published var images: [ImageFile] = []
    @Published var selectedVideoIndex: Int?
    @Published var isDirty: Bool = false
    @Published var progressiveState: String = ""
    @Published var stitchFrom: String = ""
    @Published var narrativeFunction: String = ""
    
    init(id: String, title: String, sequenceType: String, position: Double, 
         subject: String, action: String, scene: String, style: String) {
        self.id = id
        self.title = title
        self.sequenceType = sequenceType
        self.position = position
        
        // Create default prompt variant with real data
        let defaultVariant = PromptVariant(
            variantId: "\(id)_primary",
            name: "Primary Narrative",
            subject: subject,
            action: action,
            scene: scene,
            style: style
        )
        
        self.promptVariants = [defaultVariant]
    }
    
    var selectedVideo: VideoFile? {
        guard let index = selectedVideoIndex, index < videos.count else { return nil }
        return videos[index]
    }
    
    func selectVideo(at index: Int) {
        selectedVideoIndex = index
        isDirty = true
        print("🎯 Selected video \(index) for shot \(id)")
    }
    
    func addVideo(_ video: VideoFile) {
        videos.append(video)
        
        // First video becomes selected automatically
        if selectedVideoIndex == nil {
            selectedVideoIndex = 0
            print("🎬 First video auto-selected for shot \(id)")
        }
        
        isDirty = true
    }
    
    func removeVideo(at index: Int) {
        guard index < videos.count else { return }
        videos.remove(at: index)
        
        // Adjust selected index if necessary
        if selectedVideoIndex == index {
            selectedVideoIndex = videos.isEmpty ? nil : min(index, videos.count - 1)
        } else if let selectedIndex = selectedVideoIndex, selectedIndex > index {
            selectedVideoIndex = selectedIndex - 1
        }
        
        isDirty = true
    }
    
    func addImage(_ image: ImageFile) {
        images.append(image)
        isDirty = true
        print("🖼 Added image to shot \(id): \(image.filename)")
    }
    
    func removeImage(at index: Int) {
        guard index < images.count else { return }
        images.remove(at: index)
        isDirty = true
    }
    
    func copyPromptVariant(at index: Int, newName: String? = nil) {
        guard index < promptVariants.count else { return }
        
        let original = promptVariants[index]
        let copy = PromptVariant(
            variantId: "\(id)_\(promptVariants.count)",
            name: newName ?? "\(original.name) (Copy)",
            subject: original.subject,
            action: original.action,
            scene: original.scene,
            style: original.style
        )
        
        copy.dialogue = original.dialogue
        copy.cameraPosition = original.cameraPosition
        copy.negativePrompt = original.negativePrompt
        copy.progressiveState = original.progressiveState
        copy.recommendedPlates = original.recommendedPlates
        copy.selectedPlates = original.selectedPlates
        copy.selectedCharacterPlateId = original.selectedCharacterPlateId
        copy.selectedEnvironmentPlateId = original.selectedEnvironmentPlateId
        
        promptVariants.append(copy)
        selectedPromptIndex = promptVariants.count - 1
        isDirty = true
        
        // Force UI update
        objectWillChange.send()
        
        print("📝 Copied prompt variant: \(copy.name)")
    }
    
    func setActivePrompt(at index: Int) {
        for i in 0..<promptVariants.count {
            promptVariants[i].isActive = (i == index)
        }
        isDirty = true
        objectWillChange.send()
    }
}

class PromptVariant: ObservableObject, Identifiable {
    let id = UUID()
    @Published var variantId: String
    @Published var name: String
    @Published var subject: String
    @Published var action: String
    @Published var scene: String
    @Published var style: String
    @Published var dialogue: String = ""
    @Published var cameraPosition: String = ""
    @Published var negativePrompt: String = ""
    @Published var recommendedPlates: [String: Any] = [:]
    @Published var selectedPlates: [String: Any] = [:]
    @Published var progressiveState: String = ""
    @Published var isActive: Bool = false
    @Published var selectedCharacterPlateId: String?
    @Published var selectedEnvironmentPlateId: String?
    @Published var customCharacterPlate: String = ""
    @Published var customEnvironmentPlate: String = ""
    
    init(variantId: String, name: String, subject: String, action: String, scene: String, style: String) {
        self.variantId = variantId
        self.name = name
        self.subject = subject
        self.action = action
        self.scene = scene
        self.style = style
        
        // Extract camera position from style if present
        if let range = style.range(of: "(that's where the camera is)") {
            self.cameraPosition = String(style[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        } else {
            self.cameraPosition = style
        }
    }
    
    func generateCompletePrompt(for shot: FilmShot, plateManager: PlateManager? = nil, trackingSystems: [TrackingSystem]? = nil) -> String {
        var promptText = ""
        
        // Header with shot title and progressive state
        promptText += "SHOT \(shot.id.uppercased()): \(shot.title.uppercased())\n"
        
        // Build progressive state line with tracking systems
        var progressiveElements: [String] = []
        
        // Add progressive state if available
        if !progressiveState.isEmpty {
            progressiveElements.append(progressiveState)
        }
        
        // Add relevant tracking systems based on shot position
        if let systems = trackingSystems {
            let shotPosition = shot.position
            for system in systems {
                // Check if this system affects this shot based on position
                let systemPercentage = system.currentPercentage
                
                // Include system if shot position is within its range
                // You can adjust this logic based on how systems map to shots
                if abs(shotPosition - systemPercentage) < 20 || 
                   system.affectsShots.contains(shot.id) {
                    // Format system name nicely and include percentage if relevant
                    let systemName = system.displayName
                    if system.currentPercentage > 0 {
                        progressiveElements.append("\(systemName) \(Int(system.currentPercentage))%")
                    } else {
                        progressiveElements.append(systemName)
                    }
                }
            }
        }
        
        if !progressiveElements.isEmpty {
            promptText += "Progressive State: \(progressiveElements.joined(separator: " | "))\n\n"
        }
        
        // SUBJECT section
        promptText += "SUBJECT:\n"
        var subjectContent = subject
        
        // Add character plate description to subject if selected
        if let plateId = selectedCharacterPlateId, 
           let plateManager = plateManager,
           let plate = plateManager.characterPlates.first(where: { $0.plateId == plateId }) {
            if !subjectContent.isEmpty { subjectContent += " " }
            subjectContent += plate.description
        } else if !customCharacterPlate.isEmpty {
            if !subjectContent.isEmpty { subjectContent += " " }
            subjectContent += customCharacterPlate
        }
        
        promptText += "\(subjectContent)\n\n"
        
        // ACTION section
        promptText += "ACTION:\n\(action)\n\n"
        
        // SCENE section
        promptText += "SCENE:\n"
        var sceneContent = scene
        
        // Add environmental plate to scene if selected
        if let plateId = selectedEnvironmentPlateId,
           let plateManager = plateManager,
           let plate = plateManager.environmentalPlates.first(where: { $0.plateId == plateId }) {
            if !sceneContent.isEmpty { sceneContent += " " }
            sceneContent += plate.description
        } else if !customEnvironmentPlate.isEmpty {
            if !sceneContent.isEmpty { sceneContent += " " }
            sceneContent += customEnvironmentPlate
        }
        
        promptText += "\(sceneContent)\n\n"
        
        // STYLE section with camera position
        promptText += "STYLE:\n"
        var styleContent = style
        if !cameraPosition.isEmpty {
            styleContent += " Camera position: \(cameraPosition)"
        }
        promptText += "\(styleContent)\n\n"
        
        // DIALOGUE section (if present)
        if !dialogue.isEmpty {
            promptText += "DIALOGUE:\n\(dialogue)\n\n"
        }
        
        // SOUNDS section (if we have audio notes in negative prompt or elsewhere)
        // For now, we can extract from negative prompt or leave empty
        if !negativePrompt.isEmpty && negativePrompt.lowercased().contains("sound") {
            promptText += "SOUNDS:\n\(negativePrompt)\n\n"
        }
        
        // Technical information at the end
        promptText += """
        
        --- TECHNICAL INFO ---
        Duration: \(shot.duration) seconds
        Aspect Ratio: \(shot.aspectRatio)
        Shot Position: \(Int(shot.position))% through film
        Sequence Type: \(shot.sequenceType)
        """
        
        // Add negative prompt if it doesn't contain sound info
        if !negativePrompt.isEmpty && !negativePrompt.lowercased().contains("sound") {
            promptText += "\nNegative Prompt: \(negativePrompt)"
        }
        
        return promptText
    }
}

class TrackingSystem: ObservableObject, Identifiable {
    let id = UUID()
    @Published var name: String
    @Published var description: String
    @Published var currentPercentage: Double
    @Published var isBeingDragged: Bool = false
    @Published var milestoneValues: [String: String] = [:]
    @Published var affectsShots: [String] = []
    
    let continuousRange: ClosedRange<Double> = 0...100
    
    init(name: String, description: String, currentPercentage: Double) {
        self.name = name
        self.description = description
        self.currentPercentage = currentPercentage
    }
    
    var displayName: String {
        name.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    func getMilestoneDescription(at percentage: Double) -> String {
        // Return description based on percentage for this system
        switch name {
        case "breathing_coordination":
            if percentage < 25 { return "Individual rhythms" }
            else if percentage < 50 { return "Synchronization beginning" }
            else if percentage < 75 { return "Animal rhythms emerging" }
            else { return "Species-appropriate breathing" }
        case "klettagja_formation":
            if percentage < 35 { return "No crack formation" }
            else if percentage < 45 { return "Hairline crack (0.5mm)" }
            else if percentage < 65 { return "Readable KLETTAGJÁ (2mm)" }
            else if percentage < 75 { return "Passable opening (6cm)" }
            else { return "Escape doorway (3ft)" }
        default:
            return "\(Int(percentage))% progression"
        }
    }
}

struct VideoFile: Identifiable {
    let id = UUID()
    let filename: String
    let filepath: String
    let generationDate: String
    var qualityRating: Double?
    var notes: String
    
    init(filename: String, filepath: String) {
        self.filename = filename
        self.filepath = filepath
        self.generationDate = DateFormatter().string(from: Date())
        self.notes = ""
    }
}

struct ImageFile: Identifiable {
    let id = UUID()
    let filename: String
    let filepath: String
    let description: String
    
    init(filename: String, filepath: String, description: String = "") {
        self.filename = filename
        self.filepath = filepath
        self.description = description
    }
}

// MARK: - Plate Management

struct PlateMedia: Identifiable, Codable {
    let id = UUID()
    let type: String // "image" or "video"
    let path: String
    let caption: String?
}

struct CharacterPlateSpecialization: Identifiable, Codable {
    let id = UUID()
    let plateId: String
    let name: String
    let description: String
    let shotRange: String
    let media: [PlateMedia]
}

struct CharacterPlate: Identifiable {
    let id = UUID()
    let plateId: String
    var name: String
    var character: String
    var description: String
    var shotRange: String
    var specializations: [CharacterPlateSpecialization] = []
    var media: [PlateMedia] = []
    var isMainPlate: Bool = false
}

struct EnvironmentalPlate: Identifiable {
    let id = UUID()
    let plateId: String
    var name: String
    var category: String
    var description: String
    var atmosphere: String
    var media: [PlateMedia] = []
}

class PlateManager: ObservableObject {
    @Published var characterPlates: [CharacterPlate] = []
    @Published var environmentalPlates: [EnvironmentalPlate] = []
    @Published var mainCharacterPlates: [CharacterPlate] = [] // Main plates for each character
    @Published var plateRecommendations: [String: Any] = [:]
    
    private let enhancementsPath = "/Users/ingthor/Documents/stories/enhancements"
    
    init() {
        loadPlatesFromJSON()
    }
    
    func loadPlatesFromJSON() {
        loadCharacterPlatesFromJSON()
        loadEnvironmentalPlatesFromJSON()
        loadPlateRecommendations()
    }
    
    func loadPlates() {
        // Fallback to old method if JSON loading fails
        loadCharacterPlates()
        loadEnvironmentalPlates()
    }
    
    private func loadCharacterPlatesFromJSON() {
        // Load from versioned directory
        let path = AppDataManager.shared.characterPlateIndexPath()
        
        if true {  // Keep structure for consistency
            if let data = FileManager.default.contents(atPath: path) {
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    if let plateIndex = json?["plate_index"] as? [String: Any] {
                        // Clear existing plates
                        characterPlates.removeAll()
                        mainCharacterPlates.removeAll()
                        
                        // Group plates by character to build specializations
                        var platesByCharacter: [String: [(plateId: String, plateInfo: [String: Any])]] = [:]
                        
                        // First, organize all plates by character
                        for (plateId, plateData) in plateIndex {
                            if let plateInfo = plateData as? [String: Any],
                               let character = plateInfo["character"] as? String {
                                let charKey = character.lowercased()
                                if platesByCharacter[charKey] == nil {
                                    platesByCharacter[charKey] = []
                                }
                                platesByCharacter[charKey]?.append((plateId, plateInfo))
                            }
                        }
                        
                        // Now create plates with their specializations
                        for (character, plateDatas) in platesByCharacter {
                            // Find the main plate for this character
                            var mainPlateData: (plateId: String, plateInfo: [String: Any])?
                            var specializationDatas: [(plateId: String, plateInfo: [String: Any])] = []
                            
                            for plateData in plateDatas {
                                if plateData.plateInfo["is_master"] as? Bool ?? false {
                                    mainPlateData = plateData
                                } else {
                                    specializationDatas.append(plateData)
                                }
                            }
                            
                            // Create specializations array
                            var specializations: [CharacterPlateSpecialization] = []
                            for specData in specializationDatas {
                                let spec = CharacterPlateSpecialization(
                                    plateId: specData.plateId,
                                    name: specData.plateInfo["name"] as? String ?? specData.plateId,
                                    description: specData.plateInfo["description"] as? String ?? "",
                                    shotRange: specData.plateInfo["shot_range"] as? String ?? "",
                                    media: []
                                )
                                specializations.append(spec)
                            }
                            
                            // Create the main plate with its specializations
                            if let mainData = mainPlateData {
                                let mainPlate = CharacterPlate(
                                    plateId: mainData.plateId,
                                    name: mainData.plateInfo["name"] as? String ?? mainData.plateId,
                                    character: mainData.plateInfo["character"] as? String ?? "",
                                    description: mainData.plateInfo["description"] as? String ?? "",
                                    shotRange: mainData.plateInfo["shot_range"] as? String ?? "",
                                    specializations: specializations,
                                    media: [],
                                    isMainPlate: true
                                )
                                characterPlates.append(mainPlate)
                                mainCharacterPlates.append(mainPlate)
                            }
                            
                            // Also add specializations as individual plates
                            for specData in specializationDatas {
                                let plate = CharacterPlate(
                                    plateId: specData.plateId,
                                    name: specData.plateInfo["name"] as? String ?? specData.plateId,
                                    character: specData.plateInfo["character"] as? String ?? "",
                                    description: specData.plateInfo["description"] as? String ?? "",
                                    shotRange: specData.plateInfo["shot_range"] as? String ?? "",
                                    specializations: [],
                                    media: [],
                                    isMainPlate: false
                                )
                                characterPlates.append(plate)
                            }
                        }
                        
                        print("📚 Loaded \(characterPlates.count) character plates from JSON at: \(path)")
                        print("👤 Found \(mainCharacterPlates.count) main character plates")
                        return
                    }
                } catch {
                    print("❌ Error loading character plates from JSON at \(path): \(error)")
                }
            }
        }
        
        // Fallback to parsing text files
        print("⚠️ Falling back to text file parsing for character plates")
        loadCharacterPlates()
    }
    
    private func loadEnvironmentalPlatesFromJSON() {
        // Load from versioned directory
        let path = AppDataManager.shared.environmentalPlateIndexPath()
        
        if true {  // Keep structure for consistency
            if let data = FileManager.default.contents(atPath: path) {
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    if let plateIndex = json?["plate_index"] as? [String: Any] {
                        // Clear existing plates
                        environmentalPlates.removeAll()
                        
                        for (plateId, plateData) in plateIndex {
                            if let plateInfo = plateData as? [String: Any] {
                                let plate = EnvironmentalPlate(
                                    plateId: plateId,
                                    name: plateInfo["name"] as? String ?? plateId,
                                    category: plateInfo["type"] as? String ?? "",
                                    description: plateInfo["description"] as? String ?? "",
                                    atmosphere: "",
                                    media: []
                                )
                                
                                environmentalPlates.append(plate)
                            }
                        }
                        
                        print("🌍 Loaded \(environmentalPlates.count) environmental plates from JSON at: \(path)")
                        return
                    }
                } catch {
                    print("❌ Error loading environmental plates from JSON at \(path): \(error)")
                }
            }
        }
        
        // Fallback to parsing text files
        print("⚠️ Falling back to text file parsing for environmental plates")
        loadEnvironmentalPlates()
    }
    
    private func loadPlateRecommendations() {
        // Load from versioned directory
        let path = AppDataManager.shared.recommendationsPath()
        
        if true {  // Keep structure for consistency
            if let data = FileManager.default.contents(atPath: path) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        plateRecommendations = json
                        print("📋 Loaded plate recommendations from: \(path)")
                        return
                    }
                } catch {
                    print("❌ Error loading plate recommendations from \(path): \(error)")
                }
            }
        }
        
        print("⚠️ Could not load plate recommendations from any path")
    }
    
    func savePlates() {
        saveCharacterPlates()
        saveEnvironmentalPlates()
    }
    
    func saveCharacterPlates() {
        let path = AppDataManager.shared.characterPlateIndexPath()
        
        var plateIndex: [String: Any] = [:]
        
        // Save all character plates
        for plate in characterPlates {
            plateIndex[plate.plateId] = [
                "name": plate.name,
                "character": plate.character,
                "description": plate.description,
                "shot_range": plate.shotRange,
                "is_master": plate.isMainPlate
            ]
        }
        
        let json: [String: Any] = [
            "plate_index": plateIndex,
            "last_updated": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            try data.write(to: URL(fileURLWithPath: path))
            print("💾 Saved character plates to \(path)")
        } catch {
            print("❌ Error saving character plates: \(error)")
        }
    }
    
    func saveEnvironmentalPlates() {
        let path = AppDataManager.shared.environmentalPlateIndexPath()
        
        var plateIndex: [String: Any] = [:]
        
        // Save all environmental plates
        for plate in environmentalPlates {
            plateIndex[plate.plateId] = [
                "name": plate.name,
                "category": plate.category,
                "description": plate.description
            ]
        }
        
        let json: [String: Any] = [
            "plate_index": plateIndex,
            "last_updated": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            try data.write(to: URL(fileURLWithPath: path))
            print("💾 Saved environmental plates to \(path)")
        } catch {
            print("❌ Error saving environmental plates: \(error)")
        }
    }
    
    private func loadCharacterPlates() {
        // Character plate files
        let characterFiles = [
            "magnus_advanced_character_plates_system.txt",
            "sigrid_advanced_character_plates_system.txt",
            "gudrun_advanced_character_plates_system.txt",
            "jon_advanced_character_plates_system.txt",
            "lilja_complete_character_plates_expanded.txt"
        ]
        
        for file in characterFiles {
            let filepath = "\(enhancementsPath)/\(file)"
            if let content = try? String(contentsOfFile: filepath) {
                let plates = parseCharacterPlates(from: content, filename: file)
                characterPlates.append(contentsOf: plates)
                
                // Extract main plates
                if let mainPlate = plates.first(where: { $0.isMainPlate }) {
                    mainCharacterPlates.append(mainPlate)
                }
            }
        }
        
        print("📚 Loaded \(characterPlates.count) character plates")
        print("👤 Found \(mainCharacterPlates.count) main character plates")
    }
    
    private func parseCharacterPlates(from content: String, filename: String) -> [CharacterPlate] {
        var plates: [CharacterPlate] = []
        let lines = content.components(separatedBy: .newlines)
        
        // Extract character name from filename
        let character = filename.replacingOccurrences(of: "_advanced_character_plates_system.txt", with: "")
            .replacingOccurrences(of: "_complete_character_plates_expanded.txt", with: "")
            .capitalized
        
        var currentPlateId: String?
        var currentName: String?
        var currentDescription = ""
        var currentRange = ""
        var isInMasterSection = false
        var foundMasterPlate = false
        
        for line in lines {
            // Check if we're in the MASTER PLATE section
            if line.contains("MASTER PLATE") || line.contains("Master Template") {
                isInMasterSection = true
            }
            // Check for specific master plate identifiers
            else if line.contains("\(character.uppercased())-MASTER") {
                foundMasterPlate = true
                isInMasterSection = true
            }
            // Look for PLATE patterns
            else if line.contains("PLATE ") && line.contains(":") {
                // Save previous plate if exists
                if let plateId = currentPlateId, let name = currentName, !currentDescription.isEmpty {
                    plates.append(CharacterPlate(
                        plateId: plateId,
                        name: name,
                        character: character,
                        description: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                        shotRange: currentRange,
                        specializations: [],
                        media: [],
                        isMainPlate: foundMasterPlate && !plates.contains(where: { $0.isMainPlate })
                    ))
                    foundMasterPlate = false  // Reset after using
                }
                
                // Start new plate
                let components = line.components(separatedBy: ":")
                if components.count >= 2 {
                    currentName = components[0].trimmingCharacters(in: .whitespaces)
                    currentPlateId = "\(character.lowercased())_\(plates.count + 1)"
                    currentDescription = components[1].trimmingCharacters(in: .whitespaces)
                    
                    // Extract shot range if present
                    if line.contains("(Shots") {
                        if let rangeStart = line.range(of: "(Shots"),
                           let rangeEnd = line.range(of: ")") {
                            currentRange = String(line[rangeStart.lowerBound..<rangeEnd.upperBound])
                        }
                    }
                }
            } else if line.starts(with: character.uppercased()) && line.contains(":") {
                // Handle character-specific plate lines
                let components = line.components(separatedBy: ":")
                if components.count >= 2 {
                    if currentDescription.isEmpty {
                        currentDescription = components[1].trimmingCharacters(in: .whitespaces)
                    } else {
                        currentDescription += " " + components[1].trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        }
        
        // Save last plate
        if let plateId = currentPlateId, let name = currentName, !currentDescription.isEmpty {
            plates.append(CharacterPlate(
                plateId: plateId,
                name: name,
                character: character,
                description: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                shotRange: currentRange,
                specializations: [],
                media: [],
                isMainPlate: foundMasterPlate && !plates.contains(where: { $0.isMainPlate })
            ))
        }
        
        return plates
    }
    
    private func loadEnvironmentalPlates() {
        let environmentFiles = [
            "baðstofa_environmental_plates_bergrisi_transformation.txt",
            "westfjords_exterior_environmental_plates_system.txt",
            "sea_environmental_plates_character_progression.txt",
            "house_exterior_immediate_surroundings_plates.txt"
        ]
        
        for file in environmentFiles {
            let filepath = "\(enhancementsPath)/\(file)"
            if let content = try? String(contentsOfFile: filepath) {
                let plates = parseEnvironmentalPlates(from: content, filename: file)
                environmentalPlates.append(contentsOf: plates)
            }
        }
        
        print("🌍 Loaded \(environmentalPlates.count) environmental plates")
    }
    
    private func parseEnvironmentalPlates(from content: String, filename: String) -> [EnvironmentalPlate] {
        var plates: [EnvironmentalPlate] = []
        
        // Determine category from filename
        let category: String
        if filename.contains("baðstofa") {
            category = "Interior"
        } else if filename.contains("westfjords") {
            category = "Exterior"
        } else if filename.contains("sea") {
            category = "Sea"
        } else {
            category = "Landscape"
        }
        
        let lines = content.components(separatedBy: .newlines)
        var currentPlateId: String?
        var currentName: String?
        var currentDescription = ""
        var currentAtmosphere = ""
        
        for line in lines {
            if line.contains("PLATE") && line.contains(":") {
                // Save previous plate
                if let plateId = currentPlateId, let name = currentName {
                    plates.append(EnvironmentalPlate(
                        plateId: plateId,
                        name: name,
                        category: category,
                        description: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                        atmosphere: currentAtmosphere,
                        media: []
                    ))
                }
                
                // Start new plate
                let components = line.components(separatedBy: ":")
                if components.count >= 2 {
                    currentName = components[0].replacingOccurrences(of: "PLATE", with: "").trimmingCharacters(in: .whitespaces)
                    currentPlateId = "\(category.lowercased())_\(plates.count + 1)"
                    currentDescription = components[1].trimmingCharacters(in: .whitespaces)
                    currentAtmosphere = ""
                }
            } else if !line.trimmingCharacters(in: .whitespaces).isEmpty && currentName != nil {
                if line.contains("atmosphere") || line.contains("lighting") {
                    currentAtmosphere += line + " "
                } else {
                    currentDescription += " " + line
                }
            }
        }
        
        // Save last plate
        if let plateId = currentPlateId, let name = currentName {
            plates.append(EnvironmentalPlate(
                plateId: plateId,
                name: name,
                category: category,
                description: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                atmosphere: currentAtmosphere.trimmingCharacters(in: .whitespacesAndNewlines),
                media: []
            ))
        }
        
        return plates
    }
    
    func getCharacterPlatesFor(_ character: String) -> [CharacterPlate] {
        return characterPlates.filter { $0.character.lowercased() == character.lowercased() }
    }
    
    func getEnvironmentalPlatesFor(_ category: String) -> [EnvironmentalPlate] {
        return environmentalPlates.filter { $0.category == category }
    }
}

// MARK: - File Management

class FilmFileManager {
    private let appDataManager = AppDataManager.shared
    
    private var documentsPath: String {
        return appDataManager.currentVersionPath
    }
    
    private var shotsPath: String {
        return "\(appDataManager.currentVersionPath)/shots"
    }
    
    private var workingDirectory: String {
        return "\(appDataManager.currentVersionPath)/working"
    }
    
    init() {
        initializeWorkspace()
    }
    
    private func initializeWorkspace() {
        let fileManager = FileManager.default
        
        // Create working directory if it doesn't exist
        if !fileManager.fileExists(atPath: workingDirectory) {
            do {
                try fileManager.createDirectory(atPath: workingDirectory, withIntermediateDirectories: true)
                print("📁 Created working directory: \(workingDirectory)")
            } catch {
                print("❌ Failed to create working directory: \(error)")
            }
        }
        
        // Create timestamp-safe filename
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        
        let mainSystemSource = "\(documentsPath)/main_film_system.json"
        let mainSystemDest = "\(workingDirectory)/main_film_system_\(timestamp).json"
        
        if fileManager.fileExists(atPath: mainSystemSource) {
            do {
                try fileManager.copyItem(atPath: mainSystemSource, toPath: mainSystemDest)
                print("📋 Copied main system to: \(mainSystemDest)")
            } catch {
                print("⚠️ Could not copy main system file: \(error)")
            }
        } else {
            print("⚠️ Main system file not found at: \(mainSystemSource)")
        }
    }
    
    func loadShotsFromJSON() -> [FilmShot] {
        let fileManager = FileManager.default
        var shots: [FilmShot] = []
        
        print("🔍 Looking for shots in: \(shotsPath)")
        
        // Check if directory exists
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: shotsPath, isDirectory: &isDirectory)
        
        print("📁 Directory exists: \(exists)")
        print("📁 Is directory: \(isDirectory.boolValue)")
        
        if !exists {
            print("❌ Shots directory does not exist: \(shotsPath)")
            print("💡 Current working directory: \(fileManager.currentDirectoryPath)")
            return []
        }
        
        if !isDirectory.boolValue {
            print("❌ Path is not a directory: \(shotsPath)")
            return []
        }
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: shotsPath)
            let jsonFiles = files.filter { $0.hasSuffix(".json") }
            
            print("📂 Found \(jsonFiles.count) JSON files")
            
            for file in jsonFiles {
                let filePath = "\(shotsPath)/\(file)"
                if let data = fileManager.contents(atPath: filePath) {
                    if let shot = parseShot(from: data, filename: file) {
                        shots.append(shot)
                        print("✅ Loaded shot: \(shot.id) - \(shot.title)")
                    } else {
                        print("⚠️ Failed to parse: \(file)")
                    }
                } else {
                    print("⚠️ Failed to read: \(file)")
                }
            }
            
            // Sort shots by their ID/position
            shots.sort { shot1, shot2 in
                // Extract numeric value from ID for proper sorting
                let id1 = extractNumericValue(from: shot1.id)
                let id2 = extractNumericValue(from: shot2.id)
                return id1 < id2
            }
            
            print("📁 Successfully loaded \(shots.count) shots from JSON files")
        } catch {
            print("❌ Error loading shots: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
        
        return shots
    }
    
    func extractNumericValue(from id: String) -> Double {
        // Handle IDs like "0a", "0b", "1a", "8", "39.5", "61"
        // First try to extract the numeric part
        let numericString = id.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        var baseValue = Double(numericString) ?? 0
        
        // Add small offset for letter suffixes to maintain order (0a before 0b)
        if id.contains("a") {
            baseValue += 0.1
        } else if id.contains("b") {
            baseValue += 0.2
        } else if id.contains("c") {
            baseValue += 0.3
        } else if id.contains("d") {
            baseValue += 0.4
        }
        
        return baseValue
    }
    
    private func parseShot(from data: Data, filename: String) -> FilmShot? {
        do {
            // Try parsing with UTF-8 encoding to handle special characters
            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            
            guard let jsonDict = json as? [String: Any] else {
                print("⚠️ Failed to cast JSON to dictionary for \(filename)")
                return nil
            }
            
            guard let metadata = jsonDict["shot_metadata"] as? [String: Any] else {
                print("⚠️ Missing shot_metadata in \(filename)")
                return nil
            }
            
            guard let id = metadata["id"] as? String else {
                print("⚠️ Missing ID in \(filename)")
                return nil
            }
            
            // Use name if title is not available
            let title = (metadata["title"] as? String) ?? (metadata["name"] as? String) ?? "Untitled"
            
            guard let sequenceType = metadata["sequence_type"] as? String else {
                print("⚠️ Missing sequence_type in \(filename)")
                return nil
            }
            
            let duration = (metadata["duration_seconds"] as? Int) ?? 8
            let narrativeFunction = metadata["narrative_function"] as? String ?? ""
            let stitchFrom = metadata["stitch_from"] as? String ?? ""
            
            // Calculate position based on sequence and order
            let position = calculatePosition(for: id, sequenceType: sequenceType)
            
            // Create base shot
            let shot = FilmShot(
                id: id,
                title: title,
                sequenceType: sequenceType,
                position: position,
                subject: "",
                action: "",
                scene: "",
                style: ""
            )
            
            shot.duration = duration
            shot.narrativeFunction = narrativeFunction
            shot.stitchFrom = stitchFrom
            shot.progressiveState = jsonDict["progressive_state"] as? String ?? ""
            
            // Parse prompt variants
            if let promptVariants = jsonDict["prompt_variants"] as? [[String: Any]] {
                shot.promptVariants = parsePromptVariants(promptVariants, shotId: id)
            } else {
                print("⚠️ No prompt variants found for shot \(id)")
                // Create a default prompt variant
                shot.promptVariants = [createDefaultPromptVariant(for: id)]
            }
            
            return shot
            
        } catch {
            print("❌ Error parsing JSON from \(filename): \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    private func parsePromptVariants(_ variants: [[String: Any]], shotId: String) -> [PromptVariant] {
        var promptVariants: [PromptVariant] = []
        
        for (index, variant) in variants.enumerated() {
            let variantId = variant["variant_id"] as? String ?? "\(shotId)_\(index)"
            let name = variant["variant_name"] as? String ?? "Variant \(index + 1)"
            let subject = variant["subject"] as? String ?? ""
            let action = variant["action"] as? String ?? ""
            let scene = variant["scene"] as? String ?? ""
            let style = variant["style"] as? String ?? ""
            
            let promptVariant = PromptVariant(
                variantId: variantId,
                name: name,
                subject: subject,
                action: action,
                scene: scene,
                style: style
            )
            
            promptVariant.cameraPosition = variant["camera_position"] as? String ?? ""
            promptVariant.dialogue = variant["dialogue"] as? String ?? ""
            promptVariant.negativePrompt = variant["negative_prompt"] as? String ?? ""
            
            // Load plate information
            if let recommendedPlates = variant["recommended_plates"] as? [String: Any] {
                promptVariant.recommendedPlates = recommendedPlates
            }
            if let selectedPlates = variant["selected_plates"] as? [String: Any] {
                promptVariant.selectedPlates = selectedPlates
            }
            
            // Set first variant as active by default
            promptVariant.isActive = (index == 0)
            
            promptVariants.append(promptVariant)
        }
        
        return promptVariants.isEmpty ? [createDefaultPromptVariant(for: shotId)] : promptVariants
    }
    
    private func createDefaultPromptVariant(for shotId: String) -> PromptVariant {
        return PromptVariant(
            variantId: "\(shotId)_primary",
            name: "Primary",
            subject: "",
            action: "",
            scene: "",
            style: ""
        )
    }
    
    private func calculatePosition(for id: String, sequenceType: String) -> Double {
        // Extract numeric value for positioning
        let numericValue = extractNumericValue(from: id)
        
        // Prologue shots: 0-25%
        // Main story shots: 25-100%
        if sequenceType == "prologue" {
            return min(numericValue * 2, 25) // Scale prologue shots to 0-25%
        } else {
            return 25 + (numericValue * 0.75) // Scale main story shots to 25-100%
        }
    }
    
    func saveShot(_ shot: FilmShot) {
        // Build JSON structure
        var json: [String: Any] = [:]
        
        // Shot metadata
        json["shot_metadata"] = [
            "id": shot.id,
            "title": shot.title,
            "sequence_type": shot.sequenceType,
            "duration_seconds": shot.duration,
            "narrative_function": shot.narrativeFunction,
            "stitch_from": shot.stitchFrom
        ]
        
        json["progressive_state"] = shot.progressiveState
        
        // Prompt variants
        var promptVariantsJSON: [[String: Any]] = []
        for variant in shot.promptVariants {
            promptVariantsJSON.append([
                "variant_id": variant.variantId,
                "variant_name": variant.name,
                "subject": variant.subject,
                "action": variant.action,
                "scene": variant.scene,
                "style": variant.style,
                "camera_position": variant.cameraPosition,
                "dialogue": variant.dialogue,
                "negative_prompt": variant.negativePrompt
            ])
        }
        json["prompt_variants"] = promptVariantsJSON
        
        // Write to shots directory
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            let filename = "\(shot.id).json"
            let filepath = appDataManager.shotPath(for: shot.id)
            
            try data.write(to: URL(fileURLWithPath: filepath))
            print("💾 Saved shot: \(filename) to \(filepath)")
            shot.isDirty = false
        } catch {
            print("❌ Error saving shot \(shot.id): \(error)")
        }
    }
    
    func saveMainSystem(_ systems: [TrackingSystem]) {
        var systemsJSON: [String: Any] = [:]
        
        for system in systems {
            systemsJSON[system.name] = [
                "description": system.description,
                "current_percentage": system.currentPercentage
            ]
        }
        
        let json: [String: Any] = [
            "tracking_systems": systemsJSON,
            "last_updated": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            let filepath = appDataManager.mainSystemPath()
            try data.write(to: URL(fileURLWithPath: filepath))
            print("💾 Saved tracking systems state to \(filepath)")
        } catch {
            print("❌ Error saving tracking systems: \(error)")
        }
    }
    
    func loadMainSystemData() -> [String: Any]? {
        // Load from versioned directory
        let mainSystemPath = appDataManager.mainSystemPath()
        
        guard let data = FileManager.default.contents(atPath: mainSystemPath) else {
            print("❌ Could not load main system file from: \(mainSystemPath)")
            return nil
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📋 Loaded main system data")
                return json
            }
        } catch {
            print("❌ Error parsing main system JSON: \(error)")
        }
        
        return nil
    }
}