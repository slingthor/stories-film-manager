import SwiftUI
import AVKit
import AppKit

struct VideoPlayerWindow: View {
    let videoPath: String
    let videoTitle: String
    @State private var player: AVPlayer?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text(videoTitle)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.large)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            // Video player
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                    }
            } else {
                Text("Loading video...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
            }

            // Controls bar
            HStack {
                Button(action: togglePlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                }
                .buttonStyle(BorderedButtonStyle())

                Button(action: restart) {
                    Image(systemName: "backward.end.fill")
                }
                .buttonStyle(BorderedButtonStyle())

                Spacer()

                Text(currentTimeString)
                    .font(.caption)
                    .monospacedDigit()

                Text("/")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(durationString)
                    .font(.caption)
                    .monospacedDigit()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 640, minHeight: 480)
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    @State private var isPlaying = true
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0

    private var currentTimeString: String {
        formatTime(currentTime)
    }

    private var durationString: String {
        formatTime(duration)
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func setupPlayer() {
        let url = URL(fileURLWithPath: videoPath)
        player = AVPlayer(url: url)

        // Add time observer
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { time in
            currentTime = time.seconds

            if let duration = player?.currentItem?.duration {
                self.duration = duration.seconds
            }

            // Update playing state
            isPlaying = player?.rate != 0
        }
    }

    private func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }

    private func restart() {
        player?.seek(to: .zero)
        player?.play()
        isPlaying = true
    }
}

// Helper to open video player in a new window
class VideoPlayerWindowController {
    static func openVideoPlayer(for videoPath: String, title: String) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Video Player - \(title)"
        window.center()
        window.setFrameAutosaveName("VideoPlayerWindow")

        let contentView = VideoPlayerWindow(
            videoPath: videoPath,
            videoTitle: title
        )

        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)

        // Keep window reference alive
        let controller = NSWindowController(window: window)
        controller.showWindow(nil)
    }
}