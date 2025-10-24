import Foundation
import Combine
import AppKit

// MARK: - VeoImportManager - Central coordinator for Veo/Sora video import workflow

class VeoImportManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isImportModeActive: Bool = false
    @Published var pendingDownloads: [URL] = []
    @Published var modeActivatedAt: Date?
    @Published var lastImportStatus: String = ""
    @Published var pendingDownloadCount: Int = 0

    // MARK: - Dependencies
    private weak var filmManager: FilmManager?
    private let downloadMonitor: DownloadMonitor
    private let promptParser: PromptParser
    private let shotMatcher: ShotMatcher
    private let notificationManager: NotificationManager

    // MARK: - Constants
    private let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    private let downloadTimeout: TimeInterval = 180 // 3 minutes

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(filmManager: FilmManager) {
        self.filmManager = filmManager
        self.downloadMonitor = DownloadMonitor()
        self.promptParser = PromptParser()
        self.shotMatcher = ShotMatcher()
        self.notificationManager = NotificationManager()

        setupObservers()
    }

    private func setupObservers() {
        // Monitor download folder changes (ensure we handle on main thread)
        downloadMonitor.$detectedFiles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] files in
                self?.handleNewDownloads(files)
            }
            .store(in: &cancellables)
    }

    // MARK: - Mode Control
    func toggleImportMode() {
        if isImportModeActive {
            deactivateImportMode()
        } else {
            activateImportMode()
        }
    }

    func activateImportMode() {
        isImportModeActive = true
        modeActivatedAt = Date()
        pendingDownloads.removeAll()

        // Build variant index cache for fast lookups
        if let filmMgr = filmManager {
            shotMatcher.buildVariantIndex(shots: filmMgr.shots)
        }

        // Start monitoring Downloads folder
        downloadMonitor.startMonitoring(downloadsPath: downloadsPath, since: modeActivatedAt!)

        // Request notification permissions
        notificationManager.requestPermissions()

        print("[Sora] ✅ Veo Import Mode ACTIVATED")
        lastImportStatus = "Import mode active - download videos and press ` to import"
    }

    func deactivateImportMode() {
        isImportModeActive = false
        modeActivatedAt = nil
        pendingDownloads.removeAll()

        // Stop monitoring
        downloadMonitor.stopMonitoring()

        print("[Sora] 🛑 Veo Import Mode DEACTIVATED")
        lastImportStatus = "Import mode inactive"
    }

    // MARK: - Download Handling
    private func handleNewDownloads(_ files: [URL]) {
        print("[Sora] 🔔 handleNewDownloads called with \(files.count) files")
        guard isImportModeActive else {
            print("[Sora] ⚠️ Import mode not active, ignoring downloads")
            return
        }

        // All files from DownloadMonitor are already filtered for .mp4
        var newCount = 0
        for file in files {
            if !pendingDownloads.contains(file) {
                pendingDownloads.append(file)
                newCount += 1
                print("[Sora] 📥 NEW download detected: \(file.lastPathComponent)")
            }
        }

        if newCount > 0 {
            pendingDownloadCount = pendingDownloads.count
            print("[Sora] 📊 Total pending downloads now: \(pendingDownloadCount)")
        }
    }

    // MARK: - Main Import Trigger (called when ` pressed)
    func processImport() {
        print("[Sora] ⌨️ Backtick pressed - starting import process...")

        // Show immediate feedback to user
        lastImportStatus = "🔍 Searching for matching shot..."

        // Notify user that processing has started
        Task {
            await notificationManager.sendNotification(
                title: "🔍 Processing Import",
                body: "Searching for matching shot...",
                isError: false
            )
        }

        // Run entire import process on background thread to avoid UI freeze
        Task.detached { [weak self] in
            print("[Sora] 🧵 Import task started on background thread")
            await self?.runImportProcess()
            print("[Sora] 🧵 Import task completed")
        }
    }

    private func runImportProcess() async {
        print("[Sora] 🔄 runImportProcess started")
        // Check mode active (read from main actor)
        let isActive = await MainActor.run { isImportModeActive }
        guard isActive else {
            print("[Sora] ⚠️ Import mode not active")
            return
        }

        // Snapshot current pending downloads (main actor)
        let batchDownloads = await MainActor.run {
            print("[Sora] 📸 Snapshotting downloads: pendingDownloads has \(pendingDownloads.count) files")
            for file in pendingDownloads {
                print("[Sora]    - \(file.lastPathComponent)")
            }
            let downloads = pendingDownloads
            pendingDownloads.removeAll()
            pendingDownloadCount = 0
            print("[Sora] 🧹 Cleared pending downloads")
            return downloads
        }

        guard !batchDownloads.isEmpty else {
            let message = "No videos detected in Downloads folder"
            print("[Sora] ❌ ERROR: batchDownloads is empty!")
            await notificationManager.sendNotification(title: "Import Error", body: message, isError: true)
            await MainActor.run {
                lastImportStatus = "❌ " + message
            }
            return
        }

        print("[Sora] 🎬 Processing import for \(batchDownloads.count) files:")
        for file in batchDownloads {
            print("[Sora]    → \(file.lastPathComponent)")
        }

        // 1. Read clipboard (main actor)
        let clipboardText = await MainActor.run { readClipboard() }
        guard let clipboardText = clipboardText else {
            let message = "Clipboard is empty or invalid"
            await notificationManager.sendNotification(title: "Import Error", body: message, isError: true)
            await MainActor.run {
                lastImportStatus = "❌ " + message
            }
            return
        }

        // 2. Parse prompt (background - no UI interaction)
        guard let promptComponents = promptParser.parse(clipboardText) else {
            let message = "Could not parse prompt from clipboard"
            await notificationManager.sendNotification(title: "Import Error", body: message, isError: true)
            await MainActor.run {
                lastImportStatus = "❌ " + message
            }
            return
        }

        print("[Sora] 📝 Parsed prompt components:")
        let actionPreview = String(promptComponents.action.prefix(100))
        let scenePreview = String(promptComponents.scene.prefix(100))
        print("[Sora]    ACTION (\(promptComponents.action.count) chars): \(actionPreview)")
        print("[Sora]    SCENE (\(promptComponents.scene.count) chars): \(scenePreview)")

        // 3. Find matching shot (background - expensive Levenshtein calculations)
        let filmMgr = await MainActor.run { filmManager }
        guard let filmMgr = filmMgr else {
            print("[Sora] ⚠️ FilmManager reference lost")
            return
        }

        let shots = await MainActor.run { filmMgr.shots }

        print("[Sora] 🔍 About to start matching - current thread: \(Thread.current)")
        print("[Sora] 🔍 Is main thread: \(Thread.isMainThread)")

        let matchResult = await shotMatcher.findMatchingShot(
            promptComponents: promptComponents,
            shots: shots
        )

        print("[Sora] ✅ Matching completed")

        guard let shot = matchResult.shot, let variant = matchResult.variant else {
            let message = "No matching shot found\n\nSearch attempts:\n" + matchResult.attempts.joined(separator: "\n")
            await notificationManager.sendNotification(title: "Import Failed", body: message, isError: true)
            await MainActor.run {
                lastImportStatus = "❌ No match found"
            }
            return
        }

        print("[Sora] 🎯 Matched to shot: \(shot.id) - \(shot.title) - Variant: '\(variant.name)'")
        print("[Sora]    Current variant has \(variant.videos.count) videos")
        print("[Sora]    Variant ID: \(variant.variantId)")
        print("[Sora]    Shot has \(shot.promptVariants.count) total variants")

        // Notify user we found a match (before waiting for downloads)
        let matchMessage = "Found match: Shot #\(shot.id) - \(variant.name)\nWaiting for downloads to complete..."
        await notificationManager.sendNotification(title: "Match Found", body: matchMessage, isError: false)
        await MainActor.run {
            lastImportStatus = "⏳ Waiting for \(batchDownloads.count) download(s)..."
        }

        // Store IDs to look up the ACTUAL objects later (not copies)
        let shotId = shot.id
        let variantId = variant.variantId
        let shotTitle = shot.title
        let variantName = variant.name

        // 4. Wait for downloads to complete (background - can take minutes)
        do {
            let completedFiles = try await waitForDownloadsToComplete(batchDownloads)

            // 5. Import videos - lookup actual objects from FilmManager to ensure UI updates
            await importVideosToVariant(files: completedFiles, shotId: shotId, variantId: variantId)

            let message = "Imported \(completedFiles.count) video(s) to Shot #\(shotId) - Variant '\(variantName)'"
            await notificationManager.sendNotification(title: "✅ Import Successful", body: "\(shotTitle)\n\(message)", isError: false)
            await MainActor.run {
                lastImportStatus = "✅ " + message
            }

        } catch {
            let message = "Failed to complete downloads: \(error.localizedDescription)"
            await notificationManager.sendNotification(title: "Import Error", body: message, isError: true)
            await MainActor.run {
                lastImportStatus = "❌ " + message
            }
        }
    }

    // MARK: - Helper Functions
    private func readClipboard() -> String? {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string)
    }

    private func waitForDownloadsToComplete(_ urls: [URL]) async throws -> [URL] {
        var completedFiles: [URL] = []

        for url in urls {
            let downloadURL = url.appendingPathExtension("download")
            let startTime = Date()

            // Check if file has .download extension
            if FileManager.default.fileExists(atPath: downloadURL.path) {
                print("[Sora] ⏳ Waiting for download to complete: \(url.lastPathComponent)")

                // Poll until .download removed or timeout
                while FileManager.default.fileExists(atPath: downloadURL.path) {
                    if Date().timeIntervalSince(startTime) > downloadTimeout {
                        throw ImportError.downloadTimeout(filename: url.lastPathComponent)
                    }

                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                }

                print("[Sora] ✅ Download completed: \(url.lastPathComponent)")
            }

            // Verify final file exists
            if FileManager.default.fileExists(atPath: url.path) {
                completedFiles.append(url)
            } else {
                print("[Sora] ⚠️ File disappeared: \(url.lastPathComponent)")
            }
        }

        return completedFiles
    }

    private func importVideosToVariant(files: [URL], shotId: String, variantId: String) async {
        // Create video objects (can do this off main thread)
        let videos = files.map { file in
            VideoFile(
                filename: file.lastPathComponent,
                filepath: file.path,
                duration: 8.0 // Default duration, will be updated when played
            )
        }

        print("[Sora] 📝 Looking up actual shot and variant objects from FilmManager...")

        // Update data model on main thread - CRITICAL: Look up the ACTUAL objects that UI observes
        let saveSuccess = await MainActor.run { () -> Bool in
            guard let filmMgr = filmManager else {
                print("[Sora] ⚠️ FilmManager reference lost")
                return false
            }

            // Find the ACTUAL shot object (not a copy)
            guard let shot = filmMgr.shots.first(where: { $0.id == shotId }) else {
                print("[Sora] ❌ Could not find shot with ID: \(shotId)")
                return false
            }

            // Find the ACTUAL variant object (not a copy)
            guard let variant = shot.promptVariants.first(where: { $0.variantId == variantId }) else {
                print("[Sora] ❌ Could not find variant with ID: \(variantId)")
                return false
            }

            print("[Sora] ✅ Found actual objects:")
            print("[Sora]    Shot: \(shot.id) - \(shot.title)")
            print("[Sora]    Variant: \(variant.variantId) - \(variant.name)")
            print("[Sora]    Variant currently has \(variant.videos.count) videos")

            // Add videos to the ACTUAL variant object
            for video in videos {
                variant.addVideo(video)
                print("[Sora]    ➕ Added: \(video.filename)")
            }

            shot.isDirty = true

            print("[Sora] ✅ Finished adding videos to variant '\(variant.name)'")
            print("[Sora]    Variant now has \(variant.videos.count) total videos")
            print("[Sora]    Active video index: \(variant.activeVideoIndex ?? -1)")

            // Force UI refresh by notifying observers
            variant.objectWillChange.send()
            shot.objectWillChange.send()
            filmMgr.objectWillChange.send()

            return true
        }

        if !saveSuccess {
            print("[Sora] ❌ Failed to import videos - could not find shot or variant")
            return
        }

        // Save to disk in background (don't block UI)
        Task.detached { [weak self] in
            guard let self = self else { return }

            // Get references we need (quick main actor reads)
            let (filmMgr, shot) = await MainActor.run { () -> (FilmManager?, FilmShot?) in
                guard let mgr = self.filmManager else { return (nil, nil) }
                let foundShot = mgr.shots.first(where: { $0.id == shotId })
                return (mgr, foundShot)
            }

            guard let filmMgr = filmMgr, let shot = shot else {
                print("[Sora] ⚠️ Could not get shot for save")
                return
            }

            print("[Sora] 💾 Saving shot to disk in background...")
            // File I/O truly in background - saveShot is synchronous so run it off main thread
            // The FileManager should be thread-safe for file writes
            filmMgr.fileManager.saveShot(shot)
            print("[Sora] ✅ Shot saved successfully")
        }
    }
}

// MARK: - Import Error Types
enum ImportError: Error, LocalizedError {
    case downloadTimeout(filename: String)
    case clipboardEmpty
    case promptParseFailed
    case noMatchingShot

    var errorDescription: String? {
        switch self {
        case .downloadTimeout(let filename):
            return "Download timeout for file: \(filename)"
        case .clipboardEmpty:
            return "Clipboard is empty"
        case .promptParseFailed:
            return "Could not parse prompt from clipboard"
        case .noMatchingShot:
            return "No matching shot found"
        }
    }
}

// MARK: - Prompt Components
struct PromptComponents {
    let subject: String
    let action: String
    let scene: String
    let style: String
    let dialogue: String
    let negativePrompt: String
    let aspect: String
}

// MARK: - Shot Match Result
struct ShotMatchResult {
    let shot: FilmShot?
    let variant: PromptVariant?
    let attempts: [String]  // Search attempts for error reporting
    let confidence: Double
}
