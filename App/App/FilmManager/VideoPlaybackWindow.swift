import SwiftUI
import AVKit

struct VideoPlaybackWindow: View {
    @ObservedObject var filmManager: FilmManager
    @State private var player: AVPlayer = AVPlayer()
    @State private var currentVideoPath: String? = nil
    @State private var timeObserver: Any?
    @State private var seekDebounceTimer: Timer?
    @State private var isSeeking: Bool = false
    @State private var videoStatusObserver: NSKeyValueObservation?
    @State private var isLoading: Bool = false
    @State private var isManualSelection: Bool = false
    @State private var playbackTimer: Timer?
    @State private var isUpdatingFromPlayback: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar with shot info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Video Playback")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if isLoading {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 12, height: 12)
                            Text("Loading...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    if let shot = filmManager.selectedShot {
                        Text("Shot: \(shot.id) - \(shot.title)")
                            .font(.caption)
                            .foregroundColor(.primary)
                    } else {
                        Text("No Shot Selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            
            // Video player
            VideoPlayer(player: player)
                .aspectRatio(16/9, contentMode: .fit)
                .background(Color.black)
                .onAppear {
                    setupVideoPlayer()
                }
                .onChange(of: filmManager.selectedShot) { oldValue, newValue in
                    handleShotSelectionChange(oldShot: oldValue, newShot: newValue)
                }
                .onChange(of: filmManager.timelinePosition) { oldValue, newValue in
                    handleTimelinePositionChange(oldPosition: oldValue, newPosition: newValue)
                }
                .onChange(of: filmManager.isPlaying) { oldValue, newValue in
                    syncPlayPauseState()
                }
        }
        .frame(minWidth: 480, minHeight: 320)
        .background(Color.black.opacity(0.05))
        .onDisappear {
            cleanupTimers()
        }
    }
    
    private func setupVideoPlayer() {
        // Only load video on initial setup if we have a selected shot
        if filmManager.selectedShot != nil {
            updateVideoForSelectedShot()
        }
    }
    
    private func updateVideoForSelectedShot() {
        guard let shot = filmManager.selectedShot else {
            // No shot selected, clear current video
            if currentVideoPath != nil {
                currentVideoPath = nil
                player.replaceCurrentItem(with: nil)
            }
            return
        }
        
        // Get the video path for this shot
        let videoPath: String
        if let selectedVideo = shot.selectedVideo {
            videoPath = selectedVideo.filepath
        } else {
            // Use default video for shots without video
            videoPath = "/Users/ingthor/Documents/stories/appdata/resources/shots/videos/default.mp4"
        }
        
        // Only load new video if path changed
        if currentVideoPath != videoPath {
            print("Loading video for shot \(shot.id): \(videoPath)")
            currentVideoPath = videoPath
            
            // Stop playback timer immediately to prevent interference
            stopPlaybackTimer()
            
            loadVideo(at: videoPath)
        } else if isManualSelection {
            // Same video but manual selection - seek to beginning of shot
            seekToBeginningOfShot()
        } else {
            // Same video, same shot - seek to beginning to reset position
            seekToBeginningOfShot()
        }
    }
    
    private func loadVideo(at path: String) {
        let url = URL(fileURLWithPath: path)
        
        // Check if file exists
        if FileManager.default.fileExists(atPath: path) {
            isLoading = true
            let playerItem = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: playerItem)
            
            // Wait for the video to be ready before seeking
            videoStatusObserver?.invalidate()
            videoStatusObserver = playerItem.observe(\.status, options: [.new]) { item, change in
                DispatchQueue.main.async {
                    self.handleVideoStatusChange(item: item)
                }
            }
            
            // Start paused initially
            player.pause()
        } else {
            print("Video file not found at path: \(path)")
            handleVideoLoadFailure(fallbackPath: path)
        }
    }
    
    private func handleVideoLoadFailure(fallbackPath: String) {
        isLoading = false
        
        // Try to fall back to default video if current attempt wasn't already default
        let defaultVideoPath = "/Users/ingthor/Documents/stories/appdata/resources/shots/videos/default.mp4"
        if fallbackPath != defaultVideoPath && FileManager.default.fileExists(atPath: defaultVideoPath) {
            print("Falling back to default video")
            loadVideo(at: defaultVideoPath)
        } else {
            // No fallback available, clear player
            player.replaceCurrentItem(with: nil)
        }
    }
    
    private func seekToBeginningOfShot() {
        guard player.currentItem != nil else { return }
        
        let videoTime = CMTime(seconds: 0, preferredTimescale: 600)
        player.seek(to: videoTime, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
            if finished && self.filmManager.isPlaying {
                self.player.play()
            }
        }
    }
    
    private func syncVideoToTimelinePosition() {
        guard let shot = filmManager.selectedShot,
              player.currentItem != nil,
              !isSeeking else { return }
        
        // Calculate position within current shot
        let positionInShot = calculatePositionInCurrentShot()
        
        // Debounce the seek operation
        seekDebounceTimer?.invalidate()
        seekDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            self.performSeek(to: positionInShot)
        }
    }
    
    private func performSeek(to timePosition: Double) {
        guard !isSeeking,
              let playerItem = player.currentItem,
              let shot = filmManager.selectedShot else { return }
        
        isSeeking = true
        
        // Clamp the seek position to video duration
        let videoDuration = playerItem.duration.seconds
        let clampedPosition = max(0.0, min(timePosition, videoDuration - 0.1))
        let videoTime = CMTime(seconds: clampedPosition, preferredTimescale: 600)
        
        print("Seeking to \(String(format: "%.2f", clampedPosition))s in shot \(shot.id)")
        
        player.seek(to: videoTime, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
            DispatchQueue.main.async {
                self.isSeeking = false
                if finished && self.filmManager.isPlaying {
                    self.player.play()
                }
            }
        }
    }
    
    private func syncPlayPauseState() {
        if filmManager.isPlaying {
            // Start playback timer to update timeline
            startPlaybackTimer()
            
            // If video at end, restart from current timeline position
            if let playerItem = player.currentItem,
               playerItem.duration.seconds > 0 {
                let currentTime = player.currentTime().seconds
                let duration = playerItem.duration.seconds
                
                if currentTime >= duration - 0.1 {
                    syncVideoToTimelinePosition()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.player.play()
                    }
                } else {
                    player.play()
                }
            } else {
                player.play()
            }
        } else {
            stopPlaybackTimer()
            player.pause()
        }
    }
    
    private func startPlaybackTimer() {
        stopPlaybackTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.updateTimelineFromPlayback()
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func updateTimelineFromPlayback() {
        guard filmManager.isPlaying,
              !isUpdatingFromPlayback,  // Prevent recursive updates
              let shot = filmManager.selectedShot,
              let playerItem = player.currentItem,
              playerItem.status == .readyToPlay,
              playerItem.duration.seconds > 0 else { return }
        
        let currentTime = player.currentTime().seconds
        let videoDuration = playerItem.duration.seconds
        
        // Use the actual video duration or 8 seconds, whichever is shorter
        let shotDuration = min(8.0, videoDuration)
        
        // Check if we've reached the end of the current shot/video
        if currentTime >= shotDuration - 0.2 {
            // Move to next shot
            if let shotIndex = filmManager.shots.firstIndex(where: { $0.id == shot.id }),
               shotIndex < filmManager.shots.count - 1 {
                print("Shot \(shot.id) completed at \(String(format: "%.2f", currentTime))s, moving to next shot")
                let nextShot = filmManager.shots[shotIndex + 1]
                
                // Set flag to prevent feedback loop
                isUpdatingFromPlayback = true
                filmManager.selectedShot = nextShot
                
                // Update timeline to beginning of next shot
                let nextShotStartTime = Double(shotIndex + 1) * 8.0
                filmManager.timelinePosition = (nextShotStartTime / filmManager.totalDuration) * 100.0
                
                // Keep flag set briefly to allow changes to propagate
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.isUpdatingFromPlayback = false
                }
            } else {
                // Reached end of all shots
                print("Reached end of all shots")
                filmManager.isPlaying = false
                isUpdatingFromPlayback = true
                filmManager.timelinePosition = 100.0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.isUpdatingFromPlayback = false
                }
            }
        } else {
            // Update timeline position based on current playback
            if let shotIndex = filmManager.shots.firstIndex(where: { $0.id == shot.id }) {
                let shotStartTime = Double(shotIndex) * 8.0
                let currentTimelineSeconds = shotStartTime + currentTime
                isUpdatingFromPlayback = true
                filmManager.timelinePosition = (currentTimelineSeconds / filmManager.totalDuration) * 100.0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.isUpdatingFromPlayback = false
                }
            }
        }
    }
    
    private func calculatePositionInCurrentShot() -> Double {
        guard let shot = filmManager.selectedShot else { return 0.0 }
        
        // Calculate shot's start time using ALL shots with 8-second duration
        if let shotIndex = filmManager.shots.firstIndex(where: { $0.id == shot.id }) {
            let shotStartTime = Double(shotIndex) * 8.0
            let timelineSeconds = (filmManager.timelinePosition / 100.0) * filmManager.totalDuration
            let positionInShot = timelineSeconds - shotStartTime
            
            // Clamp to shot duration (8 seconds)
            return max(0.0, min(positionInShot, 8.0))
        }
        
        return 0.0
    }
    
    private func findShotAtTimelinePosition(_ timelinePercent: Double) -> FilmShot? {
        // Convert timeline percentage to actual time in seconds
        let timelineSeconds = (timelinePercent / 100.0) * filmManager.totalDuration
        
        // Find which shot contains this time point using 8-second fixed duration
        let shotIndex = Int(timelineSeconds / 8.0)
        
        if shotIndex >= 0 && shotIndex < filmManager.shots.count {
            return filmManager.shots[shotIndex]
        }
        
        // If beyond all shots, return the last one
        return filmManager.shots.last
    }
    
    // MARK: - Change Handlers
    private func handleShotSelectionChange(oldShot: FilmShot?, newShot: FilmShot?) {
        guard let newShot = newShot else { return }
        
        // Check if this was a manual selection (not from timeline)
        let expectedShot = findShotAtTimelinePosition(filmManager.timelinePosition)
        isManualSelection = (expectedShot?.id != newShot.id)
        
        if isManualSelection {
            // User manually selected a shot - update timeline to match
            if let shotIndex = filmManager.shots.firstIndex(where: { $0.id == newShot.id }) {
                let shotStartTime = Double(shotIndex) * 8.0
                let newTimelinePosition = (shotStartTime / filmManager.totalDuration) * 100.0
                filmManager.timelinePosition = newTimelinePosition
            }
        }
        
        updateVideoForSelectedShot()
    }
    
    private func handleTimelinePositionChange(oldPosition: Double, newPosition: Double) {
        // Skip if this update came from playback
        guard !isUpdatingFromPlayback else { return }
        
        // Check if timeline moved to a different shot
        let currentShot = findShotAtTimelinePosition(newPosition)
        
        if currentShot?.id != filmManager.selectedShot?.id {
            // Timeline moved to a different shot
            if let currentShot = currentShot {
                isManualSelection = false
                filmManager.selectedShot = currentShot
            }
        } else if !filmManager.isPlaying {
            // Same shot, just sync video position if not playing
            syncVideoToTimelinePosition()
        }
    }
    
    // MARK: - Video Status Handling
    private func handleVideoStatusChange(item: AVPlayerItem) {
        switch item.status {
        case .readyToPlay:
            print("Video ready for shot: \(filmManager.selectedShot?.id ?? "unknown")")
            isLoading = false
            
            // Always seek to beginning for new videos to reset position
            seekToBeginningOfShot()
            
            // Reset manual selection flag
            isManualSelection = false
            
            // Sync play state
            syncPlayPauseState()
            
        case .failed:
            if let error = item.error {
                print("Video failed to load: \(error.localizedDescription)")
            }
            handleVideoLoadFailure(fallbackPath: currentVideoPath ?? "unknown")
            
        case .unknown:
            break
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Cleanup
    private func cleanupTimers() {
        seekDebounceTimer?.invalidate()
        seekDebounceTimer = nil
        playbackTimer?.invalidate()
        playbackTimer = nil
        videoStatusObserver?.invalidate()
        videoStatusObserver = nil
    }
}

#Preview {
    VideoPlaybackWindow(filmManager: FilmManager())
        .frame(width: 480, height: 320)
}