import SwiftUI
import AVKit

struct VideoPlaybackWindow: View {
    @ObservedObject var filmManager: FilmManager
    @State private var player: AVPlayer = AVPlayer()
    @State private var currentVideoPath: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar with shot info
            HStack {
                Text("Video Playback - Timeline Sync")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let shot = filmManager.selectedShot {
                    Text("Shot: \(shot.id) - \(shot.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("No Shot Selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                .onChange(of: filmManager.selectedShot) { _ in
                    updateVideoForSelectedShot()
                }
        }
        .frame(minWidth: 480, minHeight: 320)
        .background(Color.black.opacity(0.05))
    }
    
    private func setupVideoPlayer() {
        updateVideoForSelectedShot()
    }
    
    private func updateVideoForSelectedShot() {
        guard let shot = filmManager.selectedShot else {
            // No shot selected, use default video
            loadDefaultVideo()
            return
        }
        
        // Get the selected video from the shot
        if let selectedVideo = shot.selectedVideo {
            let videoPath = selectedVideo.filepath
            
            // Only update if the video path has changed
            if currentVideoPath != videoPath {
                currentVideoPath = videoPath
                loadVideo(at: videoPath)
            }
        } else {
            // Shot has no selected video, use default
            loadDefaultVideo()
        }
    }
    
    private func loadDefaultVideo() {
        let defaultVideoPath = "/Users/ingthor/Documents/stories/appdata/resources/shots/videos/default.mp4"
        if currentVideoPath != defaultVideoPath {
            currentVideoPath = defaultVideoPath
            loadVideo(at: defaultVideoPath)
        }
    }
    
    private func loadVideo(at path: String) {
        let url = URL(fileURLWithPath: path)
        
        // Check if file exists
        if FileManager.default.fileExists(atPath: path) {
            let playerItem = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: playerItem)
            player.pause() // Start paused, user can play manually
        } else {
            print("Video file not found at path: \(path)")
            player.replaceCurrentItem(with: nil)
        }
    }
}

#Preview {
    VideoPlaybackWindow(filmManager: FilmManager())
        .frame(width: 480, height: 320)
}