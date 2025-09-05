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
                        seekToBeginning()
                    } label: {
                        Image(systemName: "backward.end.fill")
                    }
                    .help("Go to beginning")
                    
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
                        jumpToNextVideo()
                    } label: {
                        Image(systemName: "forward.end.fill")
                    }
                    .help("Next video shot")
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
                HStack {
                    ForEach(filmManager.shots.filter { $0.selectedVideo != nil }.prefix(12), id: \.id) { shot in
                        VStack {
                            Text(shot.id)
                                .font(.caption2)
                                .fontWeight(filmManager.selectedShot?.id == shot.id ? .bold : .regular)
                                .foregroundColor(filmManager.selectedShot?.id == shot.id ? .blue : .primary)
                            
                            if let video = shot.selectedVideo {
                                Text(String(video.filename.prefix(10)))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .frame(width: max(40, (600.0 / Double(filmManager.shots.count))))
                    }
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
        let shotTime = (shot.position / 100.0) * filmManager.totalDuration
        currentTimeSeconds = shotTime
        filmManager.timelinePosition = shot.position
    }
    
    private func updateSelectedShotFromTime(_ time: Double) {
        let timePercentage = (time / filmManager.totalDuration) * 100.0
        if let nearestShot = filmManager.shots.min(by: { abs($0.position - timePercentage) < abs($1.position - timePercentage) }) {
            filmManager.selectedShot = nearestShot
        }
    }
    
    private func updateTimeDisplay() {
        currentTimeSeconds = (filmManager.timelinePosition / 100.0) * filmManager.totalDuration
    }
    
    private func startPlayback() {
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
            
            if filmManager.shouldFollowTimeline {
                updateSelectedShotFromTime(currentTimeSeconds)
            }
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
            .help("Shot \(shot.id): \(shot.title)" + (shot.selectedVideo != nil ? " (has video)" : ""))
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
            return .green.opacity(0.8)
        } else {
            return .gray.opacity(0.4)
        }
    }
}

#Preview {
    ComprehensiveTimelineView(filmManager: FilmManager())
}