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
    
    private let fileManager = FilmFileManager()
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
        // Load real shot data from JSON files
        shots = [
            FilmShot(id: "0a", title: "The Shadow Pole - Curse Establishment", sequenceType: "prologue", position: 0.5, 
                    subject: "A tall piece of grey driftwood standing vertical on a grass-covered headland, rope wrapped around its top section, casting a shadow 200 feet long across green hills while the ocean behind shows red tints under blue surface and purple berries cover distant slopes.",
                    action: "Camera starts 100 feet above pole, descending slowly. The pole is 8 feet tall, weathered grey driftwood, standing perfectly vertical. Old rope wraps the top 2 feet, frayed ends moving slightly. The shadow stretches far beyond natural length - reaching 200 feet across grass.",
                    scene: "Headland in Westfjords, 5 AM June morning. Ocean 300 feet beyond pole. Berry-covered hills to left. Golden cliffs to right. Green grass everywhere. Clear sky, sun just above horizon.",
                    style: "Aerial descent toward pole, camera moving straight down (that's where the camera is), slow smooth movement, wide lens showing all terrains."),
            
            FilmShot(id: "1a", title: "Black Boats on Red Water - Hunt Begins", sequenceType: "prologue", position: 2.0,
                    subject: "Twelve men pushing three wooden rowing boats across black sand into ocean water that appears red-tinted in dawn light, [MAGNÚS] 45 years old with brown beard carrying iron-pointed spear, boats arranged pointing toward whale spouts visible in distance.",
                    action: "Men's boots sink into black sand as they push boats. Three boats, each 18 feet long, wooden, dark with age. Four men per boat. Magnús leads first boat, carries 7-foot spear with iron point, shaft dark wood. Other men carry similar spears.",
                    scene: "Black sand beach, dawn. Ocean calm except for whale spouts. Red-tinted water from sun angle. Mountains behind beach. Women and children watching from shore.",
                    style: "Wide shot from elevated position on beach showing boats entering water (that's where the camera is), seeing both boats and distant whales."),
                    
            FilmShot(id: "8", title: "Danish Counting Violence - EN TO", sequenceType: "main_story", position: 32.0,
                    subject: "[MAGNÚS] beginning the Danish counting while simultaneously distributing hákarl, his tremoring hand (3.5Hz) pointing at each family member with a piece of the grey-green fermented shark, the counting and poisoning revealed as the same act - administrative violence IS physical poisoning.",
                    action: "Magnús shifts to Danish, voice becoming mechanical, administrative. Points at Guðrún with first piece of hákarl: 'En' (One). She takes it, puts in mouth immediately, begins chewing. The meat is 13 days into 90-day fermentation - visible green spots, ammonia vapor rising.",
                    scene: "Morning sorting ritual, 5:49 AM, light growing outside but still dim. Temperature drops from -8°C to -9°C as Danish spoken. Frost spreading on north wall in dendritic patterns where Danish words hit.",
                    style: "Medium shot from Sigrid's position showing counting/poisoning combination (that's where the camera is), her POV of colonial administration as feeding ritual."),
                    
            FilmShot(id: "17", title: "Three-Frame Flash - Reality Simultaneous", sequenceType: "main_story", position: 42.0,
                    subject: "In the absolute darkness, three frames flash in succession - Frame 1: Family normal at table (2 seconds), Frame 2: Five sheep in their exact positions wearing their clothes (1/24 second), Frame 3: Double exposure of both realities overlapping (1/24 second) - revealing all realities simultaneously true.",
                    action: "FRAME 1 (2 seconds): Emergency match strikes. Magnús lighting candle stub. Family at table normal - five humans in their positions. FRAME 2 (1/24 second): Five sheep standing on hind legs in exact positions. FRAME 3 (1/24 second): Double exposure - both realities overlapping.",
                    scene: "Absolute darkness with three-frame intrusion. No temperature (darkness has no temperature). No breath visible (darkness shows nothing). Just three frames of impossible truth stabbing through void.",
                    style: "Three distinct frames exactly as described, camera locked in position (that's where the camera is), documentary capturing reality failure."),
                    
            FilmShot(id: "56", title: "Family as Sheep - Central Horror Image", sequenceType: "main_story", position: 85.0,
                    subject: "Five white Icelandic sheep standing upright around table, wearing family's clothes, human teeth visible in sheep mouths, [GUÐRÚN] with faldbúningur headdress fitting perfectly on sheep head, all breathing at 8/min synchronized rhythm while human consciousness clearly visible through sheep eyes.",
                    action: "Family arranged in traditional positions but as sheep - Magnús-ram at table head wearing brown vaðmál sweater, curved horns visible, steel-blue eyes showing human intelligence and frustration. Guðrún-ewe with traditional headdress impossible but perfect on sheep skull.",
                    scene: "Baðstofa interior with family as conscious livestock, furniture arrangements maintained for bipedal use with quadruped anatomy, impossible cultural preservation through species transformation.",
                    style: "Wide shot showing complete family transformation while maintaining domestic arrangements (that's where the camera is), documentary of impossible anatomy with cultural continuity."),
                    
            FilmShot(id: "61", title: "Camera Recognizes Itself - Iceland Awareness", sequenceType: "main_story", position: 95.0,
                    subject: "30-second forensic examination of Guðrún-ewe with faldbúningur headdress, revealing impossible anatomy while camera/Iceland recognizes itself as dying witness, building to curse transfer finale.",
                    action: "0-5s: Camera approaches from 8 feet examining anatomical impossibility. 20-25s: Direct camera address - 'Þú sérð þetta núna... þú ert vitni...' 25-30s: Single human tear from sheep eye anatomy, curse transfer to audience completing witness burden inheritance.",
                    scene: "Monument interior with family conscious within transparent obsidian walls, forensic examination lighting revealing impossible anatomy preservation.",
                    style: "Forensic documentary examination building to direct address, camera receiving curse transfer (that's where the camera is), 30-second sustained hold impossible with traditional cinema.")
        ]
        
        selectedShot = shots.first
        calculateTotalDuration()
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
        
        promptVariants.append(copy)
        selectedPromptIndex = promptVariants.count - 1
        isDirty = true
        
        print("📝 Copied prompt variant: \(copy.name)")
    }
    
    func setActivePrompt(at index: Int) {
        for i in 0..<promptVariants.count {
            promptVariants[i].isActive = (i == index)
        }
        isDirty = true
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
    @Published var progressiveState: String = ""
    @Published var isActive: Bool = false
    
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
    
    func generateCompletePrompt(for shot: FilmShot) -> String {
        return """
        Subject: \(subject)
        Action: \(action)
        Scene: \(scene)
        Style: \(style)
        Camera Position: \(cameraPosition)
        Dialogue: \(dialogue)
        
        --- AUXILIARY INFORMATION ---
        Duration: \(shot.duration) seconds
        Aspect Ratio: \(shot.aspectRatio)
        Shot ID: \(shot.id)
        Sequence: \(shot.sequenceType)
        Position: \(Int(shot.position))% through film
        Progressive State: \(progressiveState)
        
        Technical (Negative Prompt): \(negativePrompt)
        """
    }
}

class TrackingSystem: ObservableObject, Identifiable {
    let id = UUID()
    @Published var name: String
    @Published var description: String
    @Published var currentPercentage: Double
    @Published var isBeingDragged: Bool = false
    
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

class FilmFileManager {
    private let documentsPath = "/Users/ingthor/Documents/stories/App"
    
    func saveShot(_ shot: FilmShot) {
        let filename = "\(shot.id)_\(shot.sequenceType).json"
        print("💾 Saving shot: \(filename)")
        shot.isDirty = false
    }
    
    func saveMainSystem(_ systems: [TrackingSystem]) {
        print("💾 Saving main system with \(systems.count) tracking systems")
    }
    
    func loadShotsFromJSON() -> [FilmShot] {
        // In real implementation, load from JSON files
        return []
    }
}