import SwiftUI
import Combine

struct ComprehensiveTimelineView: View {
    @ObservedObject var filmManager: FilmManager
    @State private var currentTimeSeconds: Double = 0
    @State private var isTimelineDragging = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Timeline controls header
            HStack {
                // Playback controls
                HStack(spacing: 12) {
                    Button {
                        filmManager.goToPreviousScene()
                    } label: {
                        Image(systemName: "backward.end.fill")
                    }
                    .help("Previous scene")
                    
                    Button {
                        filmManager.isPlaying.toggle()
                        if filmManager.isPlaying {
                            startPlayback()
                        }
                    } label: {
                        Image(systemName: filmManager.isPlaying ? "pause.fill" : "play.fill")
                    }
                    .help(filmManager.isPlaying ? "Pause" : "Play timeline")
                    
                    Button {
                        filmManager.stopAndReturnToStart()
                    } label: {
                        Image(systemName: "stop.fill")
                    }
                    .help("Stop and return to start")
                    
                    Button {
                        filmManager.goToNextScene()
                    } label: {
                        Image(systemName: "forward.end.fill")
                    }
                    .help("Next scene")
                }
                
                Spacer()
                
                // Timeline info
                VStack(alignment: .center, spacing: 1) {
                    HStack {
                        Text(formatTime(currentTimeSeconds))
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("/")
                            .font(.caption)
                        Text(formatTime(filmManager.totalDuration))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    Text("Videos: \(videoShotCount)/\(filmManager.shots.count) shots")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Timeline options
                VStack(alignment: .trailing) {
                    Toggle("Follow Timeline", isOn: $filmManager.shouldFollowTimeline)
                        .font(.caption)
                    
                    Text("Auto-sync shot selection")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            // Main timeline scrubber
            VStack(spacing: 6) {
                // Timeline track with shot markers
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 8)
                        
                        // Progress track (blue)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue)
                            .frame(width: progressWidth(geometry.size.width), height: 8)
                        
                        // Shot markers
                        ForEach(filmManager.shots, id: \.id) { shot in
                            ShotMarkerEnhanced(
                                shot: shot,
                                totalDuration: filmManager.totalDuration,
                                timelineWidth: geometry.size.width,
                                isSelected: filmManager.selectedShot?.id == shot.id,
                                onSelect: {
                                    filmManager.selectedShot = shot
                                    seekToShot(shot)
                                }
                            )
                        }
                        
                        // Playhead
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                            .offset(x: progressWidth(geometry.size.width) - 6)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        isTimelineDragging = true
                                        let newTime = min(max(0, (value.location.x / geometry.size.width) * filmManager.totalDuration), filmManager.totalDuration)
                                        currentTimeSeconds = newTime
                                        filmManager.timelinePosition = (newTime / filmManager.totalDuration) * 100.0
                                        
                                        if filmManager.shouldFollowTimeline {
                                            updateSelectedShotFromTime(newTime)
                                        }
                                    }
                                    .onEnded { _ in
                                        isTimelineDragging = false
                                    }
                            )
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        let newTime = (location.x / geometry.size.width) * filmManager.totalDuration
                        currentTimeSeconds = newTime
                        filmManager.timelinePosition = (newTime / filmManager.totalDuration) * 100.0
                        updateSelectedShotFromTime(newTime)
                    }
                }
                .frame(height: 20)
                
                // Shot labels
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(filmManager.shots, id: \.id) { shot in
                            VStack {
                                Text(shot.id)
                                    .font(.caption2)
                                    .fontWeight(filmManager.selectedShot?.id == shot.id ? .bold : .regular)
                                    .foregroundColor(filmManager.selectedShot?.id == shot.id ? .blue : .primary)
                                
                                if let video = shot.selectedVideo {
                                    VideoThumbnailView(
                                        videoPath: video.filepath,
                                        size: CGSize(width: 20, height: 11)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 1)
                                            .stroke(filmManager.selectedShot?.id == shot.id ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                } else {
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 20, height: 11)
                                        .overlay(
                                            Image(systemName: "video.slash")
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        )
                                }
                            }
                            .frame(width: max(30, min(60, 400.0 / Double(filmManager.shots.count))))
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            updateTimeDisplay()
        }
        .onChange(of: filmManager.timelinePosition) { oldValue, newValue in
            if !isTimelineDragging {
                currentTimeSeconds = (newValue / 100.0) * filmManager.totalDuration
            }
        }
    }
    
    private var videoShotCount: Int {
        filmManager.shots.filter { $0.selectedVideo != nil }.count
    }
    
    private func progressWidth(_ totalWidth: CGFloat) -> CGFloat {
        guard filmManager.totalDuration > 0 else { return 0 }
        return (currentTimeSeconds / filmManager.totalDuration) * totalWidth
    }
    
    private func seekToBeginning() {
        currentTimeSeconds = 0
        filmManager.timelinePosition = 0
        filmManager.selectedShot = filmManager.shots.first
    }
    
    private func jumpToNextVideo() {
        guard let currentShot = filmManager.selectedShot else { return }
        
        if let nextVideoShot = filmManager.shots.first(where: { 
            $0.position > currentShot.position && $0.selectedVideo != nil 
        }) {
            filmManager.selectedShot = nextVideoShot
            seekToShot(nextVideoShot)
        }
    }
    
    private func seekToShot(_ shot: FilmShot) {
        // Update selectedShotId to match the new shot selection
        filmManager.selectedShotId = shot.id
        // Calculate the actual time position where this shot starts
        // Using fixed 8-second duration for all shots
        if let index = filmManager.shots.firstIndex(where: { $0.id == shot.id }) {
            currentTimeSeconds = Double(index) * 8.0
            filmManager.timelinePosition = (currentTimeSeconds / filmManager.totalDuration) * 100.0
        }
    }
    
    private func updateSelectedShotFromTime(_ time: Double) {
        // Find which shot contains this time point
        // Using fixed 8-second duration for all shots
        let shotIndex = Int(time / 8.0)
        
        if shotIndex >= 0 && shotIndex < filmManager.shots.count {
            let shot = filmManager.shots[shotIndex]
            if filmManager.selectedShotId != shot.id {
                print("Timeline: Switching to shot \(shot.id) at time \(time)s (index: \(shotIndex))")
                filmManager.selectedShotId = shot.id
                filmManager.selectedShot = shot
            }
        } else if let lastShot = filmManager.shots.last {
            // If we're past all shots, select the last one
            filmManager.selectedShotId = lastShot.id
            filmManager.selectedShot = lastShot
        }
    }
    
    private func updateTimeDisplay() {
        currentTimeSeconds = (filmManager.timelinePosition / 100.0) * filmManager.totalDuration
    }
    
    private func startPlayback() {
        print("Starting playback, total duration: \(filmManager.totalDuration)s for \(filmManager.shots.count) shots")
        // Simple auto-advance through shots with videos
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !filmManager.isPlaying {
                timer.invalidate()
                return
            }
            
            currentTimeSeconds += 0.1
            filmManager.timelinePosition = (currentTimeSeconds / filmManager.totalDuration) * 100.0
            
            if currentTimeSeconds >= filmManager.totalDuration {
                filmManager.isPlaying = false
                timer.invalidate()
            }
            
            // Always update selected shot during playback
            updateSelectedShotFromTime(currentTimeSeconds)
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

struct ShotMarkerEnhanced: View {
    let shot: FilmShot
    let totalDuration: Double
    let timelineWidth: CGFloat
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Rectangle()
            .fill(markerColor)
            .frame(width: markerWidth, height: 12)
            .offset(x: markerPosition)
            .cornerRadius(2)
            .onTapGesture {
                onSelect()
            }
            .help("Shot \(shot.id): \(shot.title)" + videoStatusText)
    }
    
    private var markerWidth: CGFloat {
        max(3, (Double(shot.duration) / totalDuration) * timelineWidth)
    }
    
    private var markerPosition: CGFloat {
        (shot.position / 100.0) * timelineWidth
    }
    
    private var markerColor: Color {
        if isSelected {
            return .blue
        } else if shot.selectedVideo != nil {
            // Check if it's an active prompt variant video vs shot-level video
            let hasActiveVariantVideo = shot.promptVariants.contains { variant in
                variant.isActive && variant.activeVideo != nil
            }
            return hasActiveVariantVideo ? .orange.opacity(0.8) : .green.opacity(0.8)
        } else {
            return .gray.opacity(0.4)
        }
    }

    private var videoStatusText: String {
        if shot.selectedVideo != nil {
            let activeVariant = shot.promptVariants.first { $0.isActive }
            if let activeVariant = activeVariant, activeVariant.activeVideo != nil {
                let variantVideoCount = activeVariant.videos.count
                return " (🟠 \(activeVariant.name): \(variantVideoCount) video\(variantVideoCount == 1 ? "" : "s"))"
            } else {
                let shotVideoCount = shot.videos.count
                return " (🟢 Shot level: \(shotVideoCount) video\(shotVideoCount == 1 ? "" : "s"))"
            }
        } else {
            return " (No video)"
        }
    }
}

#Preview {
    ComprehensiveTimelineView(filmManager: FilmManager())
}