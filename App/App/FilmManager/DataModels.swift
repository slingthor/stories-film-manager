import Foundation
import Combine
import SwiftUI
import AVFoundation

// MARK: - Complete Data Models with Proper ObservableObject Conformance

class FilmManager: ObservableObject {
    @Published var shots: [FilmShot] = []
    @Published var selectedShot: FilmShot? {
        didSet {
            updateSystemsForSelectedShot()
        }
    }
    @Published var selectedShotId: String? {
        didSet {
            // Update selectedShot when selectedShotId changes
            if let shotId = selectedShotId {
                selectedShot = shots.first { $0.id == shotId }
            }
        }
    }
    @Published var trackingSystems: [TrackingSystem] = []
    @Published var timelinePosition: Double = 0.0
    @Published var totalDuration: Double = 0.0
    @Published var isPlaying: Bool = false
    @Published var shouldFollowTimeline: Bool = true
    @Published var isTimelineAtStart: Bool = true
    
    let fileManager = FilmFileManager()
    let plateManager = PlateManager()
    let appDataManager = AppDataManager.shared
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
        print("\n🎬 ========== FILMMANAGER LOADING DATA ==========")
        print("🚀 Starting to load film data...")
        
        // Load ALL shots from the directory
        shots = loadAllShotsFromDirectory()
        
        if shots.isEmpty {
            print("⚠️ No shots loaded, using sample data")
            loadSampleData()
        } else {
            print("✅ Successfully loaded \(shots.count) shots")
            
            // Print complete shot order for debugging
            print("\n📊 COMPLETE SHOT ORDER AFTER LOADING:")
            for (index, shot) in shots.enumerated() {
                print("   \(index + 1). Shot \(shot.id) (\(shot.sequenceType))")
            }
            print("")
        }
        
        // Load tracking system data from main_film_system.json
        loadTrackingSystemsFromMainFile()
        
        selectedShot = shots.first
        calculateTotalDuration()
    }
    
    private func loadAllShotsFromDirectory() -> [FilmShot] {
        var loadedShots: [FilmShot] = []
        
        // First, try to load from external appdata directory (our updated files)
        let externalShotsPath = "\(appDataManager.currentVersionPath)/shots/json"
        print("📦 Attempting to load from external appdata: \(externalShotsPath)")
        
        // Debug: Check if directory exists and list some contents
        if FileManager.default.fileExists(atPath: externalShotsPath) {
            print("📁 External directory exists")
            if let files = try? FileManager.default.contentsOfDirectory(atPath: externalShotsPath) {
                let shotFiles = files.filter { $0.hasSuffix(".json") && $0.contains("shot_") }
                print("📁 Found \(shotFiles.count) shot files in external directory")
                print("📁 Sample files: \(Array(shotFiles.prefix(3)))")
            }
        } else {
            print("❌ External directory does not exist: \(externalShotsPath)")
        }
        
        if let files = try? FileManager.default.contentsOfDirectory(atPath: externalShotsPath) {
            let jsonFiles = files.filter { $0.hasSuffix(".json") && $0.contains("shot_") }
            if !jsonFiles.isEmpty {
                print("✅ Loading \(jsonFiles.count) shots from external appdata")
                loadedShots = loadShotsFromFiles(jsonFiles, directory: externalShotsPath)
                return loadedShots
            }
        }
        
        // If no external shots, try to load from app bundle as fallback
        if let bundlePath = Bundle.main.resourcePath {
            print("📦 Attempting to load from app bundle (fallback)")
            
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
            
            // Store the original file path so we can save back to the same location
            shot.originalFilePath = filepath
            
            // Set additional properties
            shot.duration = (metadata["duration_seconds"] as? Int) ?? 8
            shot.narrativeFunction = metadata["narrative_function"] as? String ?? ""
            shot.progressiveState = json["progressive_state"] as? String ?? ""
            
            // Load aspect ratio
            let aspectRatio = json["aspect_ratio"] as? String ?? "16:9"
            shot.aspectRatio = aspectRatio
            print("📐 Shot \(id): loaded aspect ratio '\(aspectRatio)' from JSON")
            
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
                    
                    // Load selected plates from the selected_plates array
                    if let selectedPlatesArray = prompt["selected_plates"] as? [String] {
                        variant.selectedPlateIds = selectedPlatesArray
                        print("📚 Shot \(id): loaded \(selectedPlatesArray.count) plates from selected_plates array")
                        print("   Plates: \(selectedPlatesArray.joined(separator: ", "))")
                    } else {
                        // Fallback to old format (both camelCase and snake_case)
                        variant.selectedPlateIds = []
                        if let charPlateId = prompt["selectedCharacterPlateId"] as? String ?? prompt["selected_character_plate_id"] as? String {
                            variant.selectedCharacterPlateId = charPlateId
                            print("🎭 Shot \(id): loaded selectedCharacterPlateId: '\(charPlateId)'")
                        }
                        if let envPlateId = prompt["selectedEnvironmentPlateId"] as? String ?? prompt["selected_environment_plate_id"] as? String {
                            variant.selectedEnvironmentPlateId = envPlateId
                            print("🌍 Shot \(id): loaded selectedEnvironmentPlateId: '\(envPlateId)'")
                        }
                    }
                    
                    // Load videos for this variant
                    if let videosJSON = prompt["videos"] as? [[String: Any]] {
                        variant.videos = []
                        for videoJSON in videosJSON {
                            if let filename = videoJSON["filename"] as? String,
                               let filepath = videoJSON["filepath"] as? String {
                                let duration = videoJSON["duration"] as? Double ?? 0.0
                                let video = VideoFile(filename: filename, filepath: filepath, duration: duration)
                                variant.videos.append(video)
                            }
                        }
                        print("📹 Shot \(id) variant: loaded \(variant.videos.count) videos")
                    }

                    // Load images for this variant
                    if let imagesJSON = prompt["images"] as? [[String: Any]] {
                        variant.images = []
                        for imageJSON in imagesJSON {
                            if let filename = imageJSON["filename"] as? String,
                               let filepath = imageJSON["filepath"] as? String {
                                let image = ImageFile(filename: filename, filepath: filepath)
                                variant.images.append(image)
                            }
                        }
                        print("🖼 Shot \(id) variant: loaded \(variant.images.count) images")
                    }

                    // Load active video index
                    if let activeVideoIndex = prompt["active_video_index"] as? Int {
                        variant.activeVideoIndex = activeVideoIndex
                    }

                    shot.promptVariants.append(variant)
                }
            }

            // Add default video only if the shot doesn't have any videos
            if shot.videos.isEmpty {
                let defaultVideo = VideoFile(filename: "default.mp4", filepath: "/Users/ingthor/Documents/stories/appdata/resources/shots/videos/default.mp4")
                shot.videos = [defaultVideo]
                shot.selectedVideoIndex = 0  // Select the default video automatically
            }
            
            loadedShots.append(shot)
        }
        
        print("📊 Loaded \(loadedShots.count) shots, now sorting...")
        
        // Sort shots: prologue first, then main_story, sorted by ID with improved logic
        loadedShots.sort { shot1, shot2 in
            // Normalize sequence types (handle "main" vs "main_story")
            let seq1 = shot1.sequenceType == "main" ? "main_story" : shot1.sequenceType
            let seq2 = shot2.sequenceType == "main" ? "main_story" : shot2.sequenceType
            
            // First sort by sequence type: prologue comes before main_story
            if seq1 != seq2 {
                // Prologue always comes first
                if seq1 == "prologue" { return true }
                if seq2 == "prologue" { return false }
                // Otherwise alphabetical
                return seq1 < seq2
            }
            
            // Within same sequence type, sort by numeric ID value
            let id1 = self.extractNumericFromId(shot1.id)
            let id2 = self.extractNumericFromId(shot2.id)
            
            // Debug logging to help identify sorting issues
            if id1 == id2 && shot1.id != shot2.id {
                print("⚠️ Same numeric values for different IDs: \(shot1.id) (\(id1)) and \(shot2.id) (\(id2))")
            }
            
            return id1 < id2
        }
        
        print("\n=================== SHOT ORDER: ===================")
        for (index, shot) in loadedShots.enumerated() {
            let numericValue = self.extractNumericFromId(shot.id)
            print("   \(index + 1). Shot \(shot.id) (\(shot.sequenceType)) -> numeric: \(numericValue)")
        }
        print("====================================================\n")
        
        // Update positions based on sorted order
        for (index, shot) in loadedShots.enumerated() {
            shot.position = Double(index) / Double(max(1, loadedShots.count - 1)) * 100.0
        }
        
        return loadedShots
    }
    
    private func extractNumericFromId(_ id: String) -> Double {
        // Handle IDs like "-1", "0a", "0b", "1", "39.5", "16p", etc.
        // This is the unified function that all sorting should use
        
        // Check for negative numbers first
        if id.hasPrefix("-") {
            let numericString = id.dropFirst().replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            var value = -(Double(numericString) ?? 0)
            // Add letter offset for suffixes - negative numbers go in reverse order
            if id.contains("a") { value -= 0.1 }
            else if id.contains("b") { value -= 0.2 }
            else if id.contains("c") { value -= 0.3 }
            else if id.contains("d") { value -= 0.4 }
            return value
        }
        
        // Extract the numeric part more carefully
        let numericPattern = try! NSRegularExpression(pattern: "(\\d+(?:\\.\\d+)?)", options: [])
        let nsString = id as NSString
        let matches = numericPattern.matches(in: id, options: [], range: NSRange(location: 0, length: nsString.length))
        
        var baseValue: Double = 0
        if let firstMatch = matches.first {
            let numericString = nsString.substring(with: firstMatch.range)
            baseValue = Double(numericString) ?? 0
        }
        
        // Handle letter suffixes with proper decimal offset
        if id.hasSuffix("a") { baseValue += 0.1 }
        else if id.hasSuffix("b") { baseValue += 0.2 }
        else if id.hasSuffix("c") { baseValue += 0.3 }
        else if id.hasSuffix("d") { baseValue += 0.4 }
        else if id.contains("p") { baseValue += 0.5 } // Handle "16p" style IDs
        
        return baseValue
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
        
        // Sort the shots using unified sorting function
        directShots.sort { shot1, shot2 in
            // First sort by sequence type (prologue before main)
            if shot1.sequenceType != shot2.sequenceType {
                // Check if either is prologue
                if shot1.sequenceType == "prologue" { return true }
                if shot2.sequenceType == "prologue" { return false }
                // For any other sequence types, use alphabetical order
                return shot1.sequenceType < shot2.sequenceType
            }
            // Within the same sequence type, sort by numeric ID
            let id1 = self.extractNumericFromId(shot1.id)
            let id2 = self.extractNumericFromId(shot2.id)
            return id1 < id2
        }
        
        // Print shot order for debugging
        print("\n=== SHOT ORDER: ===")
        for shot in directShots {
            print("\(shot.id) (\(shot.sequenceType))")
        }
        print("===================\n")
        
        return directShots
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
        // Calculate positions based on cumulative duration
        var cumulativeTime: Double = 0
        
        for shot in shots {
            // Position is the percentage of total timeline where this shot starts
            shot.position = totalDuration > 0 ? (cumulativeTime / totalDuration) * 100.0 : 0
            cumulativeTime += shot.effectiveDuration
            shot.isDirty = true
        }
    }
    
    private func calculateTotalDuration() {
        // Use fixed 8-second duration for all shots
        totalDuration = Double(shots.count) * 8.0
        
        // Update positions after calculating total duration
        updateShotPositions()
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
    
    // MARK: - Temperature System Integration
    
    /// Calculates the actual temperature value from the temperature_progression tracking system percentage
    /// Temperature range: -25°C to +15°C (40-degree range)
    /// 0% = -25°C (deadly cold), 100% = +15°C (unrealistically warm for Westfjords)
    func calculateTemperatureFromPercentage(_ percentage: Double) -> Double {
        // Temperature range from -25°C to +15°C (40-degree span)
        let minTemp = -25.0
        let maxTemp = 15.0
        let tempRange = maxTemp - minTemp
        
        // Clamp percentage between 0 and 100
        let clampedPercentage = max(0, min(100, percentage))
        
        // Calculate temperature
        let temperature = minTemp + (tempRange * (clampedPercentage / 100.0))
        
        return temperature
    }
    
    /// Get the current temperature value from the temperature_progression system
    func getCurrentTemperature() -> Double {
        guard let tempSystem = trackingSystems.first(where: { $0.name == "temperature_progression" }) else {
            return -20.0 // Default harsh winter temperature
        }
        return calculateTemperatureFromPercentage(tempSystem.currentPercentage)
    }
    
    /// Get temperature description string for prompts
    func getTemperatureDescription() -> String {
        let temp = getCurrentTemperature()
        return getTemperatureDescriptionForTemp(temp)
    }
    
    /// Get temperature description string for a specific temperature value
    private func getTemperatureDescriptionForTemp(_ temp: Double) -> String {
        switch temp {
        case ...(-20):
            return "\(Int(temp))°C life-threatening cold"
        case -20...(-10):
            return "\(Int(temp))°C harsh winter cold"
        case -10...(-5):
            return "\(Int(temp))°C bitter cold"
        case -5...0:
            return "\(Int(temp))°C freezing"
        case 0...5:
            return "\(Int(temp))°C near freezing"
        case 5...10:
            return "\(Int(temp))°C cool"
        case 10...15:
            return "\(Int(temp))°C unexpectedly warm"
        default:
            return "\(Int(temp))°C"
        }
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
    
    func goToNextScene() {
        guard let currentIndex = shots.firstIndex(where: { $0.id == selectedShotId }) else { return }
        if currentIndex < shots.count - 1 {
            selectedShotId = shots[currentIndex + 1].id
            selectedShot = shots[currentIndex + 1]
            isTimelineAtStart = false
        }
    }
    
    func goToPreviousScene() {
        guard let currentIndex = shots.firstIndex(where: { $0.id == selectedShotId }) else { return }
        if currentIndex > 0 {
            selectedShotId = shots[currentIndex - 1].id
            selectedShot = shots[currentIndex - 1]
            isTimelineAtStart = (currentIndex - 1 == 0)
        }
    }
    
    func stopAndReturnToStart() {
        isPlaying = false
        timelinePosition = 0.0
        isTimelineAtStart = true
        if let firstShot = shots.first {
            selectedShotId = firstShot.id
            selectedShot = firstShot
        }
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

class FilmShot: ObservableObject, Identifiable, Equatable {
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
    @Published var originalFilePath: String? = nil
    
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
        
        // Add default video for media management and timeline playback
        let defaultVideo = VideoFile(filename: "default.mp4", filepath: "/Users/ingthor/Documents/stories/appdata/resources/shots/videos/default.mp4")
        self.videos = [defaultVideo]
        self.selectedVideoIndex = 0  // Select the default video automatically
    }
    
    var selectedVideo: VideoFile? {
        // First check if active prompt variant has an active video
        if let activeVariant = promptVariants.first(where: { $0.isActive }),
           let activeVideo = activeVariant.activeVideo {
            return activeVideo
        }
        
        // Fallback to shot-level selected video
        guard let index = selectedVideoIndex, index < videos.count else { return nil }
        return videos[index]
    }
    
    // Computed property for effective duration based on selected video
    var effectiveDuration: Double {
        if let video = selectedVideo {
            return video.duration
        }
        return Double(duration)  // Fall back to shot's default duration
    }
    
    func selectVideo(at index: Int) {
        selectedVideoIndex = index
        isDirty = true
        print("🎯 Selected video \(index) for shot \(id)")
    }
    
    func addVideo(_ video: VideoFile) {
        var updatedVideo = video
        // Temporarily disable duration reading to avoid crashes
        // TODO: Re-enable once we have proper video files
        /*
        // Try to read the actual duration from the video file
        if let duration = getVideoDuration(from: video.filepath) {
            updatedVideo.duration = duration
            print("📹 Read duration \(duration)s for video \(video.filename)")
        }
        */
        videos.append(updatedVideo)
        
        // First video becomes selected automatically
        if selectedVideoIndex == nil {
            selectedVideoIndex = 0
            print("🎬 First video auto-selected for shot \(id)")
        }
        
        isDirty = true
    }
    
    private func getVideoDuration(from filepath: String) -> Double? {
        // Check if the file exists first
        guard FileManager.default.fileExists(atPath: filepath) else {
            print("⚠️ Video file does not exist at: \(filepath)")
            return nil
        }
        
        // Check if it's actually a video file
        let url = URL(fileURLWithPath: filepath)
        let pathExtension = url.pathExtension.lowercased()
        let videoExtensions = ["mp4", "mov", "m4v", "avi", "mkv", "webm"]
        
        guard videoExtensions.contains(pathExtension) else {
            print("⚠️ Not a video file: \(filepath)")
            return nil
        }
        
        // Try to create asset and get duration
        let asset = AVAsset(url: url)
        
        // Get duration synchronously (for simplicity)
        let duration = asset.duration
        
        // Check if duration is valid
        guard duration.isValid && !duration.isIndefinite else {
            print("⚠️ Could not determine duration for: \(filepath)")
            return nil
        }
        
        // Convert CMTime to seconds
        let seconds = CMTimeGetSeconds(duration)
        
        // Validate the duration is reasonable (between 0.1 and 3600 seconds)
        guard seconds.isFinite && seconds > 0.1 && seconds < 3600 else {
            print("⚠️ Invalid duration \(seconds)s for: \(filepath)")
            return nil
        }
        
        return seconds
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
    
    // MARK: - Equatable
    static func == (lhs: FilmShot, rhs: FilmShot) -> Bool {
        return lhs.id == rhs.id
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
    @Published var selectedPlateIds: [String] = []  // New array-based plate storage
    @Published var progressiveState: String = ""
    @Published var isActive: Bool = false
    @Published var selectedCharacterPlateId: String?
    @Published var selectedEnvironmentPlateId: String?
    @Published var customCharacterPlate: String = ""
    @Published var customEnvironmentPlate: String = ""
    
    // Per-prompt video collections and active selection
    @Published var videos: [VideoFile] = []
    @Published var images: [ImageFile] = []
    @Published var activeVideoIndex: Int?  // Which video is active for timeline playback
    
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
    
    private func calculateTemperatureFromPercentage(_ percentage: Double) -> Double {
        // Temperature range from -25°C to +15°C (40-degree span)
        let minTemp = -25.0
        let maxTemp = 15.0
        let tempRange = maxTemp - minTemp
        
        // Convert percentage to temperature
        return minTemp + (tempRange * percentage / 100.0)
    }
    
    private func getTemperatureDescriptionForTemp(_ temp: Double) -> String {
        switch temp {
        case ...(-20):
            return "\(Int(temp))°C life-threatening cold"
        case -20...(-10):
            return "\(Int(temp))°C harsh winter cold"
        case -10...(-5):
            return "\(Int(temp))°C severe cold"
        case -5...0:
            return "\(Int(temp))°C freezing"
        case 0...5:
            return "\(Int(temp))°C cold"
        case 5...10:
            return "\(Int(temp))°C cool"
        case 10...15:
            return "\(Int(temp))°C comfortable"
        default:
            return "\(Int(temp))°C"
        }
    }
    
    private func cleanPlateDescription(_ description: String) -> String {
        // Clean up any whitespace formatting - no longer need to remove brackets
        // since plates now use direct plate ID references (like JON-MILD, MAGNUS-MASTER)
        return description.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func processPlateWithMaster(_ description: String, plateId: String, plateManager: PlateManager) -> String {
        // Recursively resolve all plate references in the description
        return resolveAllPlateReferences(description, plateId: plateId, plateManager: plateManager, depth: 0)
    }
    
    private func consolidateAndResolveReferences(_ description: String, plateManager: PlateManager) -> String {
        // First pass: collect all bracketed references and group them by character/environment
        var characterSections: [String: [String]] = [:]
        var processedDescription = description
        
        let bracketPattern = "\\[([^\\]]+)\\]:[^\\[]*"
        let regex = try? NSRegularExpression(pattern: bracketPattern, options: [])
        let range = NSRange(location: 0, length: description.count)
        
        // Find all bracketed sections
        let matches = regex?.matches(in: description, options: [], range: range) ?? []
        
        // Process matches in reverse order to avoid index shifting
        for match in matches.reversed() {
            guard let matchRange = Range(match.range, in: description),
                  let bracketRange = Range(match.range(at: 1), in: description) else { continue }
            
            let fullSection = String(description[matchRange])
            let bracketReference = String(description[bracketRange])
            
            // Group sections by character/environment
            if characterSections[bracketReference] == nil {
                characterSections[bracketReference] = []
            }
            
            // Extract just the description part (after the colon)
            let sectionContent = fullSection.replacingOccurrences(of: "[\(bracketReference)]:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            characterSections[bracketReference]?.append(sectionContent)
            
            // Remove this section from the processed description
            processedDescription = processedDescription.replacingOccurrences(of: fullSection, with: "")
        }
        
        // Second pass: resolve each character's consolidated description and rebuild
        var finalResult = processedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        for (bracketReference, sections) in characterSections {
            let consolidatedContent = sections.joined(separator: " ")
            let mappedPlateId = mapBracketedReferenceToPlateId(bracketReference, plateManager: plateManager)
            
            var resolvedContent = consolidatedContent
            if let plateIdToUse = mappedPlateId {
                // Resolve the consolidated content through the plate system
                resolvedContent = resolveAllPlateReferences(consolidatedContent, plateId: plateIdToUse, plateManager: plateManager, depth: 0)
            }
            
            // Add back with single character label
            let finalSection = "[\(bracketReference)]: \(resolvedContent)"
            
            if !finalResult.isEmpty {
                finalResult += " "
            }
            finalResult += finalSection
        }
        
        return finalResult
    }
    
    private func resolveAllPlateReferences(_ description: String, plateId: String, plateManager: PlateManager, depth: Int = 0) -> String {
        guard depth < 100 else {
            print("   🚫 Maximum recursion depth (100) reached for plate '\(plateId)' - stopping resolution")
            return description
        }

        // First check for bracketed references - could be [PLATE-ID] or [CHARACTER] format
        let bracketPattern = "\\[([^\\]]+)\\]"
        let bracketRegex = try? NSRegularExpression(pattern: bracketPattern, options: [])
        let range = NSRange(location: 0, length: description.count)

        if let bracketMatch = bracketRegex?.firstMatch(in: description, options: [], range: range),
           let bracketRefRange = Range(bracketMatch.range(at: 1), in: description) {
            let bracketReference = String(description[bracketRefRange])
            let fullBracketRange = Range(bracketMatch.range(at: 0), in: description)!
            let fullBracketText = String(description[fullBracketRange])

            print("   🔗 Found bracketed reference '\(bracketReference)' in plate '\(plateId)' (depth \(depth))")

            // First check if the bracketed reference is already a plate ID (like [JON-SEEING])
            var plateIdToUse: String? = nil

            // Check if it matches plate ID pattern (contains hyphen and uppercase)
            if bracketReference.contains("-") && bracketReference == bracketReference.uppercased() {
                // It's likely a direct plate ID reference
                plateIdToUse = bracketReference
                print("   📍 Treating '\(bracketReference)' as direct plate ID")
            } else {
                // Try to map it using the mapping function
                plateIdToUse = mapBracketedReferenceToPlateId(bracketReference, plateManager: plateManager)
                if let mappedId = plateIdToUse {
                    print("   ✅ Mapped '\(bracketReference)' to plate ID: \(mappedId)")
                }
            }

            if let plateIdToUse = plateIdToUse {
                // Find the plate and resolve it
                if let envPlate = plateManager.environmentalPlates.first(where: { $0.plateId == plateIdToUse }) {
                    let baseDescription = getBaseDescriptionFromPlateDescription(envPlate.description, plateId: plateIdToUse)
                    let resolvedDescription = resolveAllPlateReferences(baseDescription, plateId: plateIdToUse, plateManager: plateManager, depth: depth + 1)
                    let newDescription = description.replacingOccurrences(of: fullBracketText, with: resolvedDescription)
                    return resolveAllPlateReferences(newDescription, plateId: plateId, plateManager: plateManager, depth: depth)
                }
                else if let charPlate = plateManager.characterPlates.first(where: { $0.plateId == plateIdToUse }) {
                    let baseDescription = getBaseDescriptionFromPlateDescription(charPlate.description, plateId: plateIdToUse)
                    let resolvedDescription = resolveAllPlateReferences(baseDescription, plateId: plateIdToUse, plateManager: plateManager, depth: depth + 1)
                    let newDescription = description.replacingOccurrences(of: fullBracketText, with: resolvedDescription)
                    return resolveAllPlateReferences(newDescription, plateId: plateId, plateManager: plateManager, depth: depth)
                }
            }

            print("   ⚠️  Could not resolve bracketed reference '\(bracketReference)'")
            // Continue looking for other references
            let remainingDescription = String(description[fullBracketRange.upperBound...])
            if !remainingDescription.isEmpty {
                let resolvedRemaining = resolveAllPlateReferences(remainingDescription, plateId: plateId, plateManager: plateManager, depth: depth)
                let beforeBracket = String(description[..<fullBracketRange.lowerBound])
                return beforeBracket + fullBracketText + resolvedRemaining
            }
            return description
        }
        
        // Then look for direct plate ID references (new format: PLATE-ID appearing as standalone words)
        let plateIdPattern = "\\b([A-Z]+(?:-[A-Z]+)+)\\b"
        let regex = try? NSRegularExpression(pattern: plateIdPattern, options: [])
        
        guard let match = regex?.firstMatch(in: description, options: [], range: range),
              let referenceRange = Range(match.range(at: 1), in: description) else {
            // No more references found
            if depth == 0 {
                print("   ℹ️  No plate references found in plate '\(plateId)': '\(description.prefix(50))...'")
            }
            return description
        }
        
        let reference = String(description[referenceRange])
        let fullMatchRange = Range(match.range(at: 0), in: description)!
        let fullPlateIdText = String(description[fullMatchRange])
        
        // Skip if this reference is the same as the current plate (avoid self-reference)
        guard reference != plateId else {
            // Continue looking for other references in the same description
            let remainingDescription = String(description[fullMatchRange.upperBound...])
            if !remainingDescription.isEmpty {
                let resolvedRemaining = resolveAllPlateReferences(remainingDescription, plateId: plateId, plateManager: plateManager, depth: depth)
                let beforePlateId = String(description[..<fullMatchRange.lowerBound])
                return beforePlateId + fullPlateIdText + resolvedRemaining
            }
            return description
        }
        
        print("   🔗 Found plate ID reference '\(reference)' in plate '\(plateId)' (depth \(depth))")
        
        // Try to find the referenced plate and get its resolved description
        var resolvedReferenceDescription: String? = nil
        
        // Look for the referenced plate
        if let envPlate = plateManager.environmentalPlates.first(where: { $0.plateId == reference }) {
            print("   ✅ Found environmental plate: \(reference)")
            // Get the base description without the plate ID prefix
            let baseDescription = getBaseDescriptionFromPlateDescription(envPlate.description, plateId: reference)
            resolvedReferenceDescription = resolveAllPlateReferences(baseDescription, plateId: reference, plateManager: plateManager, depth: depth + 1)
        }
        else if let charPlate = plateManager.characterPlates.first(where: { $0.plateId == reference }) {
            print("   ✅ Found character plate: \(reference)")
            // Get the base description without the plate ID prefix  
            let baseDescription = getBaseDescriptionFromPlateDescription(charPlate.description, plateId: reference)
            resolvedReferenceDescription = resolveAllPlateReferences(baseDescription, plateId: reference, plateManager: plateManager, depth: depth + 1)
        }
        
        if let resolvedDescription = resolvedReferenceDescription {
            // Replace the plate ID reference with the resolved description and continue recursion
            let newDescription = description.replacingOccurrences(of: fullPlateIdText, with: resolvedDescription)
            print("   🔄 Recursively resolving updated description (depth \(depth))")
            return resolveAllPlateReferences(newDescription, plateId: plateId, plateManager: plateManager, depth: depth)
        } else {
            print("   ⚠️  Plate ID '\(reference)' not found - leaving reference intact")
            // Continue looking for other references in the same description
            let remainingDescription = String(description[fullMatchRange.upperBound...])
            if !remainingDescription.isEmpty {
                let resolvedRemaining = resolveAllPlateReferences(remainingDescription, plateId: plateId, plateManager: plateManager, depth: depth)
                let beforePlateId = String(description[..<fullMatchRange.lowerBound])
                return beforePlateId + fullPlateIdText + resolvedRemaining
            }
            return description
        }
    }
    
    private func getBaseDescriptionFromPlateDescription(_ description: String, plateId: String) -> String {
        // Remove the plate ID if it appears at the start of the description
        // For example: "STOFA-ORGANIC with biological revelation" becomes "with biological revelation"
        let plateIdPattern = "^\\b\(NSRegularExpression.escapedPattern(for: plateId))\\b\\s*"
        let cleanedDescription = description.replacingOccurrences(
            of: plateIdPattern,
            with: "",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanedDescription.isEmpty ? description : cleanedDescription
    }
    
    private func mapBracketedReferenceToPlateId(_ bracketedRef: String, plateManager: PlateManager) -> String? {
        // Map bracketed references to plate IDs based on character system
        switch bracketedRef {
        // Jon's character plate references
        case "Mild base":
            return "JON-MILD"
        case "Wandering base":
            return "JON-WANDERING"
        case "Authority base":
            return "JON-AUTHORITY"
        case "Searching base":
            return "JON-SEARCHING"
        case "Desperate base":
            return "JON-DESPERATE"
        case "Collapse base":
            return "JON-COLLAPSE"
        
        // Magnus's character plate references
        case "Authority base", "Master base":
            return "MAGNUS-AUTHORITY"
        case "Mild base":
            return "MAGNUS-MILD"
        case "Collapse base":
            return "MAGNUS-COLLAPSE"
        case "Wandering base":
            return "MAGNUS-WANDERING"
        case "Searching base":
            return "MAGNUS-SEARCHING"
        case "Desperate base":
            return "MAGNUS-DESPERATE"
        
        // Sigrid's character plate references
        case "Pure base":
            return "SIGRID-PURE"
        case "Conflicted base":
            return "SIGRID-CONFLICTED"
        case "Responsible base":
            return "SIGRID-RESPONSIBLE"
        case "Protective base":
            return "SIGRID-PROTECTIVE"
        case "Transitional base":
            return "SIGRID-TRANSITIONAL"
        case "Final base":
            return "SIGRID-FINAL"
        
        // Gudrun's character plate references
        case "Abundant base":
            return "GUDRUN-ABUNDANT"
        case "Protective base":
            return "GUDRUN-PROTECTIVE"
        case "Desperate base":
            return "GUDRUN-DESPERATE"
        case "Wandering base":
            return "GUDRUN-WANDERING"
        case "Collapse base":
            return "GUDRUN-COLLAPSE"
        
        // Lilja's character plate references
        case "Pure base":
            return "LILJA-PURE"
        case "Sensing base":
            return "LILJA-SENSING"
        case "Harmonic base":
            return "LILJA-HARMONIC"
        case "Mathematical base":
            return "LILJA-MATHEMATICAL"
        case "Communicating base":
            return "LILJA-COMMUNICATING"
        case "Evolving base":
            return "LILJA-EVOLVING"
        case "Accepting base":
            return "LILJA-ACCEPTING"
        case "Final base":
            return "LILJA-FINAL"
        case "Counting base":
            return "LILJA-COUNTING"
        case "Mapping base":
            return "LILJA-MAPPING"
        case "Prophesying base":
            return "LILJA-PROPHESYING"
        case "Producing base":
            return "LILJA-PRODUCING"
        case "Wondering base":
            return "LILJA-WONDERING"
        case "Changing base":
            return "LILJA-CHANGING"
        
        // Legacy character mappings (keep for backward compatibility)
        case "JON":
            return "JON-MILD"
        case "MAGNUS":
            return "MAGNUS-AUTHORITY"
        case "SIGRID":
            return "SIGRID-PURE"
        case "GUDRUN":
            return "GUDRUN-ABUNDANT"
        case "LILJA":
            return "LILJA-PURE"
        
        // Environment mappings
        case "EXTERIOR":
            return "EXTERIOR-MASTER"
        case "SEA":
            return "SEA-MASTER"
        case "WESTFJORDS":
            return "WESTFJORDS-MASTER"
        case "STOFA":
            return "STOFA-DOMESTIC"
        case "BAÐSTOFA":
            return "BAÐSTOFA-DOMESTIC"
        case "HOUSE":
            return "HOUSE-TRADITIONAL"
        
        default:
            // Try to find a matching plate ID directly
            let directId = bracketedRef.uppercased()
            if plateManager.characterPlates.contains(where: { $0.plateId == directId }) ||
               plateManager.environmentalPlates.contains(where: { $0.plateId == directId }) {
                return directId
            }
            return nil
        }
    }
    
    // Character encoding correction function for Icelandic characters
    private func correctCharacterEncoding(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "MAGNÃšS", with: "MAGNÚS")
            .replacingOccurrences(of: "MagnÃºs", with: "Magnús") 
            .replacingOccurrences(of: "JÃN", with: "JÓN")
            .replacingOccurrences(of: "JÃ³n", with: "Jón")
            .replacingOccurrences(of: "GuÃ°rÃºn", with: "Guðrún")
            .replacingOccurrences(of: "SigrÃ­Ã°", with: "Sigrið")
            .replacingOccurrences(of: "Ã", with: "Ó")
            .replacingOccurrences(of: "Ã¡", with: "á")
            .replacingOccurrences(of: "Ã©", with: "é")
            .replacingOccurrences(of: "Ã­", with: "í")
            .replacingOccurrences(of: "Ã³", with: "ó")
            .replacingOccurrences(of: "Ãº", with: "ú")
            .replacingOccurrences(of: "Ã½", with: "ý")
            .replacingOccurrences(of: "Ã¾", with: "þ")
            .replacingOccurrences(of: "Ã°", with: "ð")
            .replacingOccurrences(of: "Ã¦", with: "æ")
            .replacingOccurrences(of: "Å", with: "Å")
            .replacingOccurrences(of: "Ã", with: "Á")
            .replacingOccurrences(of: "Ã‰", with: "É")
            .replacingOccurrences(of: "Ã", with: "Í")
            .replacingOccurrences(of: "Ãš", with: "Ú")
            .replacingOccurrences(of: "Ã", with: "Ý")
            .replacingOccurrences(of: "Ãž", with: "Þ")
            .replacingOccurrences(of: "Ã", with: "Ð")
            .replacingOccurrences(of: "Ã†", with: "Æ")
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
            
            // Always include temperature information as it's environmental context
            if let tempSystem = systems.first(where: { $0.name == "temperature_progression" }) {
                let tempValue = calculateTemperatureFromPercentage(tempSystem.currentPercentage)
                let tempDescription = getTemperatureDescriptionForTemp(tempValue)
                progressiveElements.append("Outdoor temperature: \(tempDescription)")
            }
        }
        
        if !progressiveElements.isEmpty {
            promptText += "Progressive State: \(progressiveElements.joined(separator: " | "))\n\n"
        }
        
        // SUBJECT section
        promptText += "SUBJECT:\n"
        var subjectContent = correctCharacterEncoding(subject)
        
        // Add character and environmental plates at the END of subject section
        var plateAdditions = ""
        
        print("🎬 PLATE RESOLUTION DEBUG:")
        print("   📍 selectedPlateIds: \(selectedPlateIds)")
        print("   📍 selectedCharacterPlateId: \(selectedCharacterPlateId ?? "nil")")
        print("   📍 selectedEnvironmentPlateId: \(selectedEnvironmentPlateId ?? "nil")")
        print("   📍 customCharacterPlate: '\(customCharacterPlate.isEmpty ? "empty" : String(customCharacterPlate.prefix(30)))...'")
        print("   📍 customEnvironmentPlate: '\(customEnvironmentPlate.isEmpty ? "empty" : String(customEnvironmentPlate.prefix(30)))...'")
        print("   📍 plateManager available: \(plateManager != nil)")
        if let plateManager = plateManager {
            print("   📍 characterPlates count: \(plateManager.characterPlates.count)")
            print("   📍 environmentalPlates count: \(plateManager.environmentalPlates.count)")
        }
        
        // Derive plates from all available data sources automatically
        if let plateManager = plateManager {
            // Collect all plate IDs from all sources (no UI dependency)
            var collectedPlateIds = Set<String>()
            
            // 1. From selectedPlateIds array (if populated)
            selectedPlateIds.forEach { collectedPlateIds.insert($0) }
            
            // 2. From individual properties (always check these - the main source)
            if let charPlateId = selectedCharacterPlateId {
                collectedPlateIds.insert(charPlateId)
            }
            if let envPlateId = selectedEnvironmentPlateId {
                collectedPlateIds.insert(envPlateId)
            }
            
            // 3. AUTO-INCLUDE MASTER PLATES: Only add master plates if sub-plates don't already reference them
            //    Check each sub-plate's description to see if it references the master
            let hasEnvironmentalPlates = collectedPlateIds.contains { plateId in
                plateManager.environmentalPlates.contains { $0.plateId == plateId }
            }
            let hasCharacterPlates = collectedPlateIds.contains { plateId in
                plateManager.characterPlates.contains { $0.plateId == plateId }
            }

            if hasEnvironmentalPlates {
                // Check if any environmental plate already references WESTFJORDS-MASTER
                var needsMaster = true
                for plateId in collectedPlateIds {
                    if let envPlate = plateManager.environmentalPlates.first(where: { $0.plateId == plateId }) {
                        if envPlate.description.contains("WESTFJORDS-MASTER") {
                            needsMaster = false
                            print("   🌍 WESTFJORDS-MASTER already referenced in \(plateId)")
                            break
                        }
                    }
                }
                if needsMaster {
                    collectedPlateIds.insert("WESTFJORDS-MASTER")
                    print("   🌍 AUTO-ADDED WESTFJORDS-MASTER as environmental foundation")
                }
            }

            if hasCharacterPlates {
                // Find any character plates and check if they reference their master plates
                var charactersNeedingMasters: Set<String> = []

                for plateId in Array(collectedPlateIds) {
                    if let charPlate = plateManager.characterPlates.first(where: { $0.plateId == plateId }) {
                        let characterName = charPlate.character.uppercased()
                        let mainPlateId = "\(characterName)-MASTER"

                        // Check if this plate references its master
                        if !charPlate.description.contains(mainPlateId) &&
                           !charPlate.description.contains("[\(characterName)]") {
                            charactersNeedingMasters.insert(characterName)
                        } else {
                            print("   👤 \(mainPlateId) already referenced in \(plateId)")
                        }
                    }
                }

                // Add master plates only for characters that need them
                for characterName in charactersNeedingMasters {
                    let mainPlateId = "\(characterName)-MASTER"
                    if plateManager.characterPlates.contains(where: { $0.plateId == mainPlateId }) {
                        collectedPlateIds.insert(mainPlateId)
                        print("   👤 AUTO-ADDED \(mainPlateId) as main character plate for \(characterName)")
                    }
                }
            }
            
            // Note: Custom plates are handled separately below since they contain descriptions, not IDs
            
            print("   🔍 Final collected plate IDs (including auto-added masters): \(Array(collectedPlateIds).sorted().joined(separator: ", "))")
            
            // Process all collected plates, grouping by character/environment to avoid duplicate labels
            let sortedPlateIds = Array(collectedPlateIds).sorted()
            var characterPlatesByCharacter: [String: [String]] = [:]
            var environmentalPlatesByCategory: [String: [String]] = [:]

            // Group plates by character/category first
            for plateId in sortedPlateIds {
                print("   🔍 Processing plate: \(plateId)")

                if let charPlate = plateManager.characterPlates.first(where: { $0.plateId == plateId }) {
                    let character = charPlate.character.uppercased()
                    if characterPlatesByCharacter[character] == nil {
                        characterPlatesByCharacter[character] = []
                    }
                    let plateDescription = processPlateWithMaster(charPlate.description, plateId: plateId, plateManager: plateManager)
                    characterPlatesByCharacter[character]?.append(plateDescription)
                    print("   ✅ Added character plate '\(plateId)' to \(character) group")
                }
                else if let envPlate = plateManager.environmentalPlates.first(where: { $0.plateId == plateId }) {
                    let category = envPlate.category.uppercased()
                    if environmentalPlatesByCategory[category] == nil {
                        environmentalPlatesByCategory[category] = []
                    }
                    let plateDescription = processPlateWithMaster(envPlate.description, plateId: plateId, plateManager: plateManager)
                    environmentalPlatesByCategory[category]?.append(plateDescription)
                    print("   ✅ Added environmental plate '\(plateId)' to \(category) group")
                }
                else {
                    print("   ⚠️  Plate '\(plateId)' not found in any plate collection")
                }
            }

            // Now consolidate plates by character/category to avoid duplicate labels
            for (character, descriptions) in characterPlatesByCharacter.sorted(by: { $0.key < $1.key }) {
                let consolidatedDescription = descriptions.joined(separator: " ")
                plateAdditions += " [\(character)]: " + consolidatedDescription
                print("   ✅ Consolidated \(descriptions.count) plate(s) for character '\(character)'")
            }

            for (category, descriptions) in environmentalPlatesByCategory.sorted(by: { $0.key < $1.key }) {
                let consolidatedDescription = descriptions.joined(separator: " ")
                plateAdditions += " [\(category)]: " + consolidatedDescription
                print("   ✅ Consolidated \(descriptions.count) plate(s) for category '\(category)'")
            }
            
            // Custom plates as fallback
            if !customCharacterPlate.isEmpty {
                let cleanDescription = cleanPlateDescription(customCharacterPlate)
                plateAdditions += " " + cleanDescription
                print("   ✅ Added custom character plate: '\(cleanDescription.prefix(50))...'")
            }
            
            if !customEnvironmentPlate.isEmpty {
                let cleanDescription = cleanPlateDescription(customEnvironmentPlate)
                plateAdditions += " " + cleanDescription
                print("   ✅ Added custom environmental plate: '\(cleanDescription.prefix(50))...'")
            }
            
            if plateAdditions.isEmpty {
                print("   ❌ No plates resolved from any source")
            }
        } else {
            print("   ❌ No plateManager available")
        }
        
        // Combine subject with plates more naturally
        if !plateAdditions.isEmpty {
            // Clean up the plateAdditions to avoid excessive repetition
            let cleanPlateAdditions = plateAdditions.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanPlateAdditions.isEmpty && !subjectContent.contains(cleanPlateAdditions.prefix(50)) {
                subjectContent += " " + cleanPlateAdditions
            }
            print("   🎯 Final subject with plates: '\(subjectContent)'")
        } else {
            print("   🔍 No plate additions made - using original subject")
        }
        
        promptText += "\(subjectContent)\n\n"
        
        // ACTION section
        promptText += "ACTION:\n\(action)\n\n"
        
        // SCENE section with temperature injection
        var sceneContent = scene
        
        // Inject temperature information if tracking systems are available and not already present
        if let systems = trackingSystems,
           let tempSystem = systems.first(where: { $0.name == "temperature_progression" }),
           !scene.lowercased().contains("temperature") && !scene.lowercased().contains("°c") {
            
            let tempValue = calculateTemperatureFromPercentage(tempSystem.currentPercentage)
            let tempDescription = getTemperatureDescriptionForTemp(tempValue)
            
            // Add temperature as environmental context
            sceneContent += " Outdoor temperature: \(tempDescription)."
        }
        
        promptText += "SCENE:\n\(sceneContent)\n\n"
        
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
        
        // SOUNDS section (only if we have actual audio notes)
        if !negativePrompt.isEmpty && negativePrompt.lowercased().contains("sound") {
            promptText += "SOUNDS:\n\(negativePrompt)\n\n"
        }
        // Otherwise omit the SOUNDS section entirely
        
        // ASPECT section
        promptText += "ASPECT:\n\(shot.aspectRatio)\n\n"
        
        // Technical information at the end
        promptText += """
        --- TECHNICAL INFO ---
        Duration: \(shot.duration) seconds
        Shot Position: \(Int(shot.position))% through film
        Sequence Type: \(shot.sequenceType)
        """
        
        // Add negative prompt if it doesn't contain sound info
        if !negativePrompt.isEmpty && !negativePrompt.lowercased().contains("sound") {
            promptText += "\nNegative Prompt: \(negativePrompt)"
        }
        
        return promptText
    }
    
    func generateCleanPrompt(for shot: FilmShot, plateManager: PlateManager? = nil) -> String {
        var promptText = ""
        
        // SUBJECT section
        promptText += "SUBJECT:\n"
        var subjectContent = correctCharacterEncoding(subject)
        
        // Add character and environmental plates at the END of subject section
        var plateAdditions = ""
        
        // Derive plates from all available data sources automatically
        if let plateManager = plateManager {
            // Collect all plate IDs from all sources (no UI dependency)
            var collectedPlateIds = Set<String>()
            
            // 1. From selectedPlateIds array (if populated)
            selectedPlateIds.forEach { collectedPlateIds.insert($0) }
            
            // 2. From individual properties (always check these - the main source)
            if let charPlateId = selectedCharacterPlateId {
                collectedPlateIds.insert(charPlateId)
            }
            if let envPlateId = selectedEnvironmentPlateId {
                collectedPlateIds.insert(envPlateId)
            }
            
            // Process all collected plates (convert Set to sorted Array for consistent order)
            let sortedPlateIds = Array(collectedPlateIds).sorted()
            for plateId in sortedPlateIds {
                // Try character plates first
                if let charPlate = plateManager.characterPlates.first(where: { $0.plateId == plateId }) {
                    let plateDescription = processPlateWithMaster(charPlate.description, plateId: plateId, plateManager: plateManager)
                    plateAdditions += " " + plateDescription
                }
                // Try environmental plates
                else if let envPlate = plateManager.environmentalPlates.first(where: { $0.plateId == plateId }) {
                    let plateDescription = processPlateWithMaster(envPlate.description, plateId: plateId, plateManager: plateManager)
                    plateAdditions += " " + plateDescription
                }
            }
            
            // Custom plates as fallback
            if !customCharacterPlate.isEmpty {
                let cleanDescription = cleanPlateDescription(customCharacterPlate)
                plateAdditions += " " + cleanDescription
            }
            
            if !customEnvironmentPlate.isEmpty {
                let cleanDescription = cleanPlateDescription(customEnvironmentPlate)
                plateAdditions += " " + cleanDescription
            }
        }
        
        // Combine subject with plates more naturally
        if !plateAdditions.isEmpty {
            let cleanPlateAdditions = plateAdditions.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanPlateAdditions.isEmpty && !subjectContent.contains(cleanPlateAdditions.prefix(50)) {
                subjectContent += " " + cleanPlateAdditions
            }
        }
        
        promptText += "\(subjectContent)\n\n"
        
        // ACTION section
        promptText += "ACTION:\n\(action)\n\n"
        
        // STYLE section
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
        
        // SOUNDS section (only if we have actual audio notes)
        if !negativePrompt.isEmpty && negativePrompt.lowercased().contains("sound") {
            promptText += "SOUNDS:\n\(negativePrompt)\n\n"
        }
        
        // ASPECT section
        promptText += "ASPECT:\n\(shot.aspectRatio)"
        
        return promptText
    }
    
    // Get the active video for this prompt variant
    var activeVideo: VideoFile? {
        guard let index = activeVideoIndex, index >= 0 && index < videos.count else {
            return nil
        }
        return videos[index]
    }
    
    // Set a video as active for timeline playback
    func setActiveVideo(at index: Int) {
        if index >= 0 && index < videos.count {
            activeVideoIndex = index
        }
    }

    // Add a video to this prompt variant
    func addVideo(_ video: VideoFile) {
        videos.append(video)
        // First video becomes active automatically
        if activeVideoIndex == nil {
            activeVideoIndex = 0
        }
    }

    // Remove a video from this prompt variant
    func removeVideo(at index: Int) {
        guard index < videos.count else { return }
        videos.remove(at: index)

        // Adjust active index if necessary
        if activeVideoIndex == index {
            activeVideoIndex = videos.isEmpty ? nil : min(index, videos.count - 1)
        } else if let activeIndex = activeVideoIndex, activeIndex > index {
            activeVideoIndex = activeIndex - 1
        }
    }

    // Add an image to this prompt variant
    func addImage(_ image: ImageFile) {
        images.append(image)
    }

    // Remove an image from this prompt variant
    func removeImage(at index: Int) {
        guard index < images.count else { return }
        images.remove(at: index)
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
    var duration: Double = 8.0  // Duration in seconds, default to 8
    
    init(filename: String, filepath: String, duration: Double = 8.0) {
        self.filename = filename
        self.filepath = filepath
        self.generationDate = DateFormatter().string(from: Date())
        self.notes = ""
        self.duration = duration
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
        print("🚀 PlateManager init - loading plates...")
        loadPlatesFromJSON()
        print("📊 PlateManager loaded: \(mainCharacterPlates.count) main character plates")
        if mainCharacterPlates.isEmpty {
            print("⚠️ WARNING: No main character plates loaded!")
        }
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
        print("🔍 Loading character plates from: \(path)")
        print("   File exists: \(FileManager.default.fileExists(atPath: path))")
        
        if true {  // Keep structure for consistency
            if let data = FileManager.default.contents(atPath: path) {
                print("   ✅ Loaded file data (\(data.count) bytes)")
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
                            
                            // If no plate has is_master, use the first one as main
                            var hasExplicitMaster = false
                            for plateData in plateDatas {
                                if plateData.plateInfo["is_master"] as? Bool ?? false {
                                    mainPlateData = plateData
                                    hasExplicitMaster = true
                                } else {
                                    specializationDatas.append(plateData)
                                }
                            }
                            
                            // If no explicit master, look for "PLATE 1" or character_1 pattern
                            if !hasExplicitMaster && !plateDatas.isEmpty {
                                // First try to find PLATE 1
                                for plateData in plateDatas {
                                    let name = plateData.plateInfo["name"] as? String ?? ""
                                    if name == "PLATE 1" || plateData.plateId == "\(character)_1" {
                                        mainPlateData = plateData
                                        specializationDatas = plateDatas.filter { $0.plateId != plateData.plateId }
                                        break
                                    }
                                }
                                
                                // If still no main plate, use first one
                                if mainPlateData == nil {
                                    mainPlateData = plateDatas.first
                                    specializationDatas = Array(plateDatas.dropFirst())
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
                        for plate in mainCharacterPlates {
                            print("   - \(plate.character): \(plate.plateId)")
                        }

                        // Debug: Check for specific VEO3 plates
                        let jonTemporalExists = characterPlates.contains { $0.plateId == "JON-TEMPORAL" }
                        print("🔍 JON-TEMPORAL plate exists: \(jonTemporalExists)")
                        if jonTemporalExists {
                            if let jonTemporal = characterPlates.first(where: { $0.plateId == "JON-TEMPORAL" }) {
                                print("   Description: \(jonTemporal.description.prefix(100))...")
                            }
                        }

                        // List all JON plates
                        let jonPlates = characterPlates.filter { $0.plateId.contains("JON") }.map { $0.plateId }
                        print("📋 All JON plates loaded: \(jonPlates.joined(separator: ", "))")

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
        print("🔍 Loading environmental plates from: \(path)")
        print("   File exists: \(FileManager.default.fileExists(atPath: path))")
        
        if true {  // Keep structure for consistency
            if let data = FileManager.default.contents(atPath: path) {
                print("   ✅ Loaded environmental file data (\(data.count) bytes)")
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    print("   📝 JSON keys: \(json?.keys.joined(separator: ", ") ?? "none")")
                    
                    if let plateIndex = json?["plate_index"] as? [String: Any] {
                        print("   🔍 Found plate_index with \(plateIndex.count) entries")
                        // Clear existing plates
                        environmentalPlates.removeAll()
                        
                        for (plateId, plateData) in plateIndex {
                            if let plateInfo = plateData as? [String: Any] {
                                let category = plateInfo["category"] as? String ?? ""
                                print("   ➕ Adding environmental plate: \(plateId) (category: '\(category)')")
                                
                                let plate = EnvironmentalPlate(
                                    plateId: plateId,
                                    name: plateInfo["name"] as? String ?? plateId,
                                    category: category,
                                    description: plateInfo["description"] as? String ?? "",
                                    atmosphere: "",
                                    media: []
                                )
                                
                                environmentalPlates.append(plate)
                            }
                        }
                        
                        print("🌍 Loaded \(environmentalPlates.count) environmental plates from JSON at: \(path)")

                        // Debug: Check for SEA-BATTLE plate
                        let seaBattleExists = environmentalPlates.contains { $0.plateId == "SEA-BATTLE" }
                        print("🔍 SEA-BATTLE plate exists: \(seaBattleExists)")
                        if seaBattleExists {
                            if let seaBattle = environmentalPlates.first(where: { $0.plateId == "SEA-BATTLE" }) {
                                print("   Description: \(seaBattle.description.prefix(100))...")
                            }
                        }

                        // List all SEA plates
                        let seaPlates = environmentalPlates.filter { $0.plateId.contains("SEA") }.map { $0.plateId }
                        print("📋 All SEA plates loaded: \(seaPlates.joined(separator: ", "))")

                        return
                    } else {
                        print("   ❌ No 'plate_index' found in JSON")
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
        
        // Check if we're using the complete system - don't overwrite complete files with reduced set
        if path.contains("complete.json") && characterPlates.count < 50 {
            print("🚫 Preventing overwrite of complete character plates file (has \(characterPlates.count) plates, expected 100+)")
            return
        }
        
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
            "last_updated": ISO8601DateFormatter().string(from: Date()),
            "_complete_system": characterPlates.count > 50,
            "_total_plates": characterPlates.count
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            try data.write(to: URL(fileURLWithPath: path))
            print("💾 Saved \(characterPlates.count) character plates to \(path)")
        } catch {
            print("❌ Error saving character plates: \(error)")
        }
    }
    
    func saveEnvironmentalPlates() {
        let path = AppDataManager.shared.environmentalPlateIndexPath()
        
        // Check if we're using the complete system - don't overwrite complete files with reduced set
        if path.contains("complete.json") && environmentalPlates.count < 20 {
            print("🚫 Preventing overwrite of complete environmental plates file (has \(environmentalPlates.count) plates, expected 40+)")
            return
        }
        
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
            "last_updated": ISO8601DateFormatter().string(from: Date()),
            "_complete_system": environmentalPlates.count > 20,
            "_total_plates": environmentalPlates.count
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            try data.write(to: URL(fileURLWithPath: path))
            print("💾 Saved \(environmentalPlates.count) environmental plates to \(path)")
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
            
            // Sort shots by their ID/position using unified sorting function
            shots.sort { (shot1: FilmShot, shot2: FilmShot) in
                // First sort by sequence type: prologue comes before main_story
                if shot1.sequenceType != shot2.sequenceType {
                    return shot1.sequenceType == "prologue"
                }
                
                // Within same sequence type, sort by numeric ID value
                let id1 = self.extractNumericFromId(shot1.id)
                let id2 = self.extractNumericFromId(shot2.id)
                return id1 < id2
            }
            
            print("📁 Successfully loaded \(shots.count) shots from JSON files")
        } catch {
            print("❌ Error loading shots: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
        
        return shots
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
            let aspectRatio = jsonDict["aspect_ratio"] as? String ?? "16:9"
            shot.aspectRatio = aspectRatio
            print("📐 Shot \(id): loaded aspect ratio '\(aspectRatio)' from JSON")
            
            // Parse prompt variants inline since this function is only used for OLD format
            if let promptVariants = jsonDict["prompt_variants"] as? [[String: Any]] {
                shot.promptVariants = []
                for variant in promptVariants {
                    let variantId = variant["variant_id"] as? String ?? "\(id)_variant"
                    let name = variant["variant_name"] as? String ?? "Primary"
                    let promptVariant = PromptVariant(
                        variantId: variantId,
                        name: name,
                        subject: variant["subject"] as? String ?? "",
                        action: variant["action"] as? String ?? "",
                        scene: variant["scene"] as? String ?? "",
                        style: variant["style"] as? String ?? ""
                    )
                    promptVariant.selectedPlateIds = []
                    if let selectedPlatesArray = variant["selected_plates"] as? [String] {
                        promptVariant.selectedPlateIds = selectedPlatesArray
                    }
                    shot.promptVariants.append(promptVariant)
                }
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
    
    // REMOVED: parsePromptVariants function - now handled inline in loadShotsFromFiles
    
    private func REMOVED_parsePromptVariants(_ variants: [[String: Any]], shotId: String) -> [PromptVariant] {
        print("🎯 parsePromptVariants called for shot \(shotId) with \(variants.count) variants")
        var promptVariants: [PromptVariant] = []
        
        print("🔍 Parsing \(variants.count) prompt variants for shot: \(shotId)")
        
        for (index, variant) in variants.enumerated() {
            let variantId = variant["variant_id"] as? String ?? "\(shotId)_\(index)"
            let name = variant["variant_name"] as? String ?? "Variant \(index + 1)"
            print("  📄 Parsing variant \(index): \(variantId)")
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
            
            // Initialize selectedPlateIds array
            promptVariant.selectedPlateIds = []
            
            // Load plate information
            if let recommendedPlates = variant["recommended_plates"] as? [String: Any] {
                promptVariant.recommendedPlates = recommendedPlates
            }
            
            // Handle new array-based plate structure
            print("🔍 Looking for selected_plates in variant: \(variant.keys)")
            if let selectedPlatesArray = variant["selected_plates"] as? [String] {
                // This is the new structure - just an array of plate IDs
                print("✅ Found selected_plates array with \(selectedPlatesArray.count) items")
                promptVariant.selectedPlateIds = selectedPlatesArray
                
                // For backward compatibility, set the first plates as character/environment
                // Note: Proper type detection would require plateManager access here
                // For now, we use a simple heuristic based on plate naming
                for plateId in selectedPlatesArray {
                    // Simple heuristic: if the plate contains a character name, it's a character plate
                    let lowerPlateId = plateId.lowercased()
                    if (lowerPlateId.contains("magnus") || lowerPlateId.contains("sigrid") || 
                        lowerPlateId.contains("gudrun") || lowerPlateId.contains("jon") || 
                        lowerPlateId.contains("lilja")) {
                        if promptVariant.selectedCharacterPlateId == nil {
                            promptVariant.selectedCharacterPlateId = plateId
                        }
                    } else {
                        // Otherwise assume it's an environment plate
                        if promptVariant.selectedEnvironmentPlateId == nil {
                            promptVariant.selectedEnvironmentPlateId = plateId
                        }
                    }
                }
                print("📍 Loaded plate IDs for variant \(promptVariant.variantId): \(selectedPlatesArray)")
                
            } else if let selectedPlates = variant["selected_plates"] as? [String: Any] {
                // Handle old nested structure for backward compatibility
                promptVariant.selectedPlates = selectedPlates
                
                // Sync individual plate IDs from the selectedPlates dictionary
                if let charPlates = selectedPlates["characters"] as? [String: String] {
                    // Look for the specialized plate that matches this shot
                    // Check if there's a plate specifically for this shot's main character
                    
                    // First, try to identify the main character from the variant's references
                    var mainCharacter: String? = nil
                    if let charPlatesRef = variant["character_plates"] as? [String: Any],
                       let referenced = charPlatesRef["referenced"] as? [String] {
                        // Extract character from referenced plates (e.g., "MAGNUS-CONFUSED" -> "magnus")
                        for ref in referenced {
                            for charName in ["magnus", "sigrid", "gudrun", "jon", "lilja"] {
                                if ref.lowercased().contains(charName) {
                                    mainCharacter = charName
                                    break
                                }
                            }
                            if mainCharacter != nil { break }
                        }
                    }
                    
                    // If we found a main character, use their specialized plate
                    if let character = mainCharacter,
                       let plateId = charPlates[character] {
                        promptVariant.selectedCharacterPlateId = plateId
                        print("📍 Set selectedCharacterPlateId to specialized plate: \(plateId) for character: \(character) in variant: \(promptVariant.variantId)")
                    } else if let firstEntry = charPlates.first {
                        // Fallback: use the first available specialized plate
                        promptVariant.selectedCharacterPlateId = firstEntry.value
                        print("📍 Set selectedCharacterPlateId to: \(firstEntry.value) (character: \(firstEntry.key)) for variant: \(promptVariant.variantId)")
                    }
                    
                    print("📍 Final selectedCharacterPlateId: \(String(describing: promptVariant.selectedCharacterPlateId))")
                    
                    if !charPlates.isEmpty {
                        print("   All specialized plates for this shot: \(charPlates)")
                    }
                }
                
                // Check both new format (selected_plates) and old format (environmental_plates)
                var envPlates: [String: String] = [:]
                
                // Try new format first
                if let newEnvPlates = selectedPlates["environment"] as? [String: String] {
                    envPlates = newEnvPlates
                }
                // Fallback to old format
                else if let oldEnvPlates = variant["environmental_plates"] as? [String: String] {
                    envPlates = oldEnvPlates
                }
                
                if !envPlates.isEmpty {
                    // Priority for environment: interior > landscape > weather > sea
                    let priorityOrder = ["interior", "landscape", "weather", "sea"]
                    var selectedEnv: String? = nil
                    
                    for priority in priorityOrder {
                        if let plateId = envPlates[priority] {
                            selectedEnv = plateId
                            print("📍 Found environment plate '\(plateId)' for priority '\(priority)'")
                            break
                        }
                    }
                    
                    // Fallback to first if no priority match
                    if selectedEnv == nil, let firstEnv = envPlates.keys.first {
                        selectedEnv = envPlates[firstEnv]
                        print("📍 Using first available environment plate: '\(selectedEnv ?? "nil")'")
                    }
                    
                    if let plateId = selectedEnv {
                        promptVariant.selectedEnvironmentPlateId = plateId
                        print("📍 Set selectedEnvironmentPlateId to: \(plateId) for variant: \(promptVariant.variantId)")
                    } else {
                        print("📍 No environment plate could be selected from: \(envPlates.keys.joined(separator: ", "))")
                    }
                }
            }
            
            // Also check for the individual plate ID fields (both camelCase and snake_case)
            if let charPlateId = variant["selectedCharacterPlateId"] as? String ?? variant["selected_character_plate_id"] as? String {
                promptVariant.selectedCharacterPlateId = charPlateId
                print("🎭 Shot \(shotId): loaded selectedCharacterPlateId: '\(charPlateId)'")
            }
            if let envPlateId = variant["selectedEnvironmentPlateId"] as? String ?? variant["selected_environment_plate_id"] as? String {
                promptVariant.selectedEnvironmentPlateId = envPlateId
                print("🌍 Shot \(shotId): loaded selectedEnvironmentPlateId: '\(envPlateId)'")
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
    
    private func extractNumericFromId(_ id: String) -> Double {
        // Handle IDs like "-1", "0a", "0b", "1", "39.5", "16p", etc.
        // This is the unified function that all sorting should use
        
        // Check for negative numbers first
        if id.hasPrefix("-") {
            let numericString = id.dropFirst().replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            var value = -(Double(numericString) ?? 0)
            // Add letter offset for suffixes - negative numbers go in reverse order
            if id.contains("a") { value -= 0.1 }
            else if id.contains("b") { value -= 0.2 }
            else if id.contains("c") { value -= 0.3 }
            else if id.contains("d") { value -= 0.4 }
            return value
        }
        
        // Extract the numeric part more carefully
        let numericPattern = try! NSRegularExpression(pattern: "(\\d+(?:\\.\\d+)?)", options: [])
        let nsString = id as NSString
        let matches = numericPattern.matches(in: id, options: [], range: NSRange(location: 0, length: nsString.length))
        
        var baseValue: Double = 0
        if let firstMatch = matches.first {
            let numericString = nsString.substring(with: firstMatch.range)
            baseValue = Double(numericString) ?? 0
        }
        
        // Handle letter suffixes with proper decimal offset
        if id.hasSuffix("a") { baseValue += 0.1 }
        else if id.hasSuffix("b") { baseValue += 0.2 }
        else if id.hasSuffix("c") { baseValue += 0.3 }
        else if id.hasSuffix("d") { baseValue += 0.4 }
        else if id.contains("p") { baseValue += 0.5 } // Handle "16p" style IDs
        
        return baseValue
    }

    private func calculatePosition(for id: String, sequenceType: String) -> Double {
        // Extract numeric value for positioning using unified function
        let numericValue = self.extractNumericFromId(id)
        
        // Prologue shots: 0-25%
        // Main story shots: 25-100%
        if sequenceType == "prologue" {
            return min(numericValue * 2, 25) // Scale prologue shots to 0-25%
        } else {
            return 25 + (numericValue * 0.75) // Scale main story shots to 25-100%
        }
    }
    
    func saveShot(_ shot: FilmShot) {
        print("\n=== SAVE SHOT DEBUG ===")
        print("🔍 Starting save for shot \(shot.id)")
        print("🔍 Number of variants: \(shot.promptVariants.count)")
        print("🔍 Shot isDirty: \(shot.isDirty)")
        print("🔍 Selected variant index: \(shot.selectedPromptIndex)")
        print("🔍 Shot originalFilePath: \(shot.originalFilePath ?? "nil")")
        
        // Log the current state of the selected variant BEFORE serialization
        if shot.selectedPromptIndex < shot.promptVariants.count {
            let selectedVariant = shot.promptVariants[shot.selectedPromptIndex]
            print("🔍 SELECTED VARIANT CURRENT STATE:")
            print("  action: '\(selectedVariant.action)'")
            print("  scene: '\(selectedVariant.scene)'")
            print("  style: '\(selectedVariant.style)'")
            print("  dialogue: '\(selectedVariant.dialogue)'")
            print("  selectedPlates: \(selectedVariant.selectedPlateIds)")
        }
        
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
        for (index, variant) in shot.promptVariants.enumerated() {
            print("🔍 Saving variant \(index): action='\(String(variant.action.prefix(50)))...'")
            print("🔍 Variant \(index) FULL action text: '\(variant.action)'")
            print("🔍 Variant \(index) scene text: '\(variant.scene)'")
            print("🔍 Variant \(index) style text: '\(variant.style)'")
            print("🔍 Variant \(index) dialogue text: '\(variant.dialogue)'")
            print("🔍 Variant \(index) plates: \(variant.selectedPlateIds)")
            print("🔍 Variant \(index) isActive: \(variant.isActive)")
            
            var variantDict: [String: Any] = [
                "variant_id": variant.variantId,
                "variant_name": variant.name,
                "subject": variant.subject,
                "action": variant.action,
                "scene": variant.scene,
                "style": variant.style,
                "camera_position": variant.cameraPosition,
                "dialogue": variant.dialogue,
                "negative_prompt": variant.negativePrompt,
                "progressive_state": variant.progressiveState,
                "is_active": variant.isActive
            ]
            
            // Add plate-related fields
            if !variant.recommendedPlates.isEmpty {
                variantDict["recommended_plates"] = variant.recommendedPlates
            }
            
            // Use new array-based structure for selected plates
            if !variant.selectedPlateIds.isEmpty {
                // Use the new array directly
                variantDict["selected_plates"] = variant.selectedPlateIds
            } else {
                // Fallback: build array from individual selections if selectedPlateIds is empty
                var plateIds: [String] = []
                
                if let charPlateId = variant.selectedCharacterPlateId {
                    plateIds.append(charPlateId)
                }
                
                if let envPlateId = variant.selectedEnvironmentPlateId {
                    plateIds.append(envPlateId)
                }
                
                if !plateIds.isEmpty {
                    variantDict["selected_plates"] = plateIds
                }
            }
            
            // Also save individual plate IDs for backward compatibility
            if let plateId = variant.selectedCharacterPlateId {
                variantDict["selected_character_plate_id"] = plateId
            }
            if let plateId = variant.selectedEnvironmentPlateId {
                variantDict["selected_environment_plate_id"] = plateId
            }
            if !variant.customCharacterPlate.isEmpty {
                variantDict["custom_character_plate"] = variant.customCharacterPlate
            }
            if !variant.customEnvironmentPlate.isEmpty {
                variantDict["custom_environment_plate"] = variant.customEnvironmentPlate
            }

            // Save videos for this variant
            if !variant.videos.isEmpty {
                var videosJSON: [[String: Any]] = []
                for video in variant.videos {
                    videosJSON.append([
                        "filename": video.filename,
                        "filepath": video.filepath,
                        "duration": video.duration
                    ])
                }
                variantDict["videos"] = videosJSON
                print("🔍 Saving \(variant.videos.count) videos for variant \(index)")
            }

            // Save images for this variant
            if !variant.images.isEmpty {
                var imagesJSON: [[String: Any]] = []
                for image in variant.images {
                    imagesJSON.append([
                        "filename": image.filename,
                        "filepath": image.filepath
                    ])
                }
                variantDict["images"] = imagesJSON
                print("🔍 Saving \(variant.images.count) images for variant \(index)")
            }

            // Save active video index if set
            if let activeVideoIndex = variant.activeVideoIndex {
                variantDict["active_video_index"] = activeVideoIndex
            }

            promptVariantsJSON.append(variantDict)
        }
        json["prompt_variants"] = promptVariantsJSON
        
        // Also save the selected prompt index and aspect ratio
        json["selected_prompt_index"] = shot.selectedPromptIndex
        json["aspect_ratio"] = shot.aspectRatio
        
        // Write to shots directory
        do {
            print("\n🔍 DEBUG: About to serialize JSON...")
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            print("🔍 DEBUG: JSON serialized, size: \(data.count) bytes")
            
            // Use the original file path if available, otherwise fall back to ID-based path
            let filepath: String
            if let originalPath = shot.originalFilePath, !originalPath.isEmpty {
                filepath = originalPath
                print("🔍 Using original file path: \(filepath)")
            } else {
                filepath = appDataManager.shotPath(for: shot.id)
                print("🔍 Using ID-based path: \(filepath)")
            }
            let filename = (filepath as NSString).lastPathComponent
            print("🔍 DEBUG: Save path: \(filepath)")
            
            // Ensure directory exists
            let dirPath = (filepath as NSString).deletingLastPathComponent
            try FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
            print("🔍 DEBUG: Directory ensured: \(dirPath)")
            
            // Write the file
            try data.write(to: URL(fileURLWithPath: filepath))
            print("💾 Successfully saved shot: \(filename) to \(filepath)")
            
            // Verify the file was written
            if FileManager.default.fileExists(atPath: filepath) {
                let fileSize = try FileManager.default.attributesOfItem(atPath: filepath)[.size] as? Int ?? 0
                print("✅ File verified: \(filepath) (\(fileSize) bytes)")
                
                // Print first 200 chars of saved content for verification
                if let savedData = try? Data(contentsOf: URL(fileURLWithPath: filepath)),
                   let jsonString = String(data: savedData, encoding: .utf8) {
                    let preview = String(jsonString.prefix(200))
                    print("📄 Saved content preview: \(preview)...")
                }
            } else {
                print("⚠️ WARNING: File not found after save: \(filepath)")
            }
            
            shot.isDirty = false
            print("=== END SAVE SHOT DEBUG ===")
        } catch {
            print("❌ Error saving shot \(shot.id): \(error)")
            print("=== END SAVE SHOT DEBUG (ERROR) ===")
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
