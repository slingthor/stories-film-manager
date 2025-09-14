import SwiftUI
import AVFoundation
import AppKit

class VideoThumbnailGenerator {
    private var thumbnailCache: [String: NSImage] = [:]
    private let fileManager = FileManager.default

    static let shared = VideoThumbnailGenerator()

    private init() {}

    func getThumbnail(for videoPath: String, completion: @escaping (NSImage?) -> Void) {
        // Check cache first
        if let cachedThumbnail = thumbnailCache[videoPath] {
            DispatchQueue.main.async {
                completion(cachedThumbnail)
            }
            return
        }

        // Check if file exists
        guard fileManager.fileExists(atPath: videoPath) else {
            print("🚫 Video file does not exist: \(videoPath)")
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }

        // Generate thumbnail asynchronously
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let thumbnail = self?.generateThumbnail(for: videoPath)

            DispatchQueue.main.async {
                // Cache the result
                if let thumbnail = thumbnail {
                    self?.thumbnailCache[videoPath] = thumbnail
                }
                completion(thumbnail)
            }
        }
    }

    private func generateThumbnail(for videoPath: String) -> NSImage? {
        let url = URL(fileURLWithPath: videoPath)
        let asset = AVAsset(url: url)

        // Check if the asset is readable
        guard asset.isReadable else {
            print("⚠️ Cannot read video asset: \(videoPath)")
            return nil
        }

        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 160, height: 90) // 16:9 aspect ratio

        // Try to get thumbnail at 1 second, or at 10% of duration
        var thumbnailTime = CMTime(seconds: 1.0, preferredTimescale: 600)

        // If video is shorter than 1 second, use 10% of duration
        let duration = asset.duration
        if duration.isValid && !duration.isIndefinite {
            let durationSeconds = CMTimeGetSeconds(duration)
            if durationSeconds > 0 && durationSeconds < 1.0 {
                thumbnailTime = CMTime(seconds: durationSeconds * 0.1, preferredTimescale: 600)
            }
        }

        do {
            let cgImage = try imageGenerator.copyCGImage(at: thumbnailTime, actualTime: nil)
            return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        } catch {
            print("⚠️ Failed to generate thumbnail for \(videoPath): \(error)")
            return nil
        }
    }

    func clearCache() {
        thumbnailCache.removeAll()
    }

    func removeThumbnail(for videoPath: String) {
        thumbnailCache.removeValue(forKey: videoPath)
    }
}

// MARK: - Video Thumbnail View
struct VideoThumbnailView: View {
    let videoPath: String
    let size: CGSize
    @State private var thumbnail: NSImage?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .cornerRadius(4)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size.width, height: size.height)
                    .overlay(
                        Group {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "video.slash")
                                    .foregroundColor(.gray)
                                    .font(.title2)
                            }
                        }
                    )
            }

            // Video duration overlay
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if let thumbnail = thumbnail {
                        Text(formatDuration(getDuration(for: videoPath)))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(3)
                            .padding(4)
                    }
                }
            }

        }
        .onAppear {
            loadThumbnail()
        }
        .onChange(of: videoPath) { oldValue, newValue in
            if oldValue != newValue {
                loadThumbnail()
            }
        }
    }

    private func loadThumbnail() {
        isLoading = true
        thumbnail = nil

        VideoThumbnailGenerator.shared.getThumbnail(for: videoPath) { generatedThumbnail in
            self.thumbnail = generatedThumbnail
            self.isLoading = false
        }
    }

    private func getDuration(for videoPath: String) -> Double {
        let url = URL(fileURLWithPath: videoPath)
        let asset = AVAsset(url: url)

        let duration = asset.duration
        guard duration.isValid && !duration.isIndefinite else {
            return 0.0
        }

        return CMTimeGetSeconds(duration)
    }

    private func formatDuration(_ seconds: Double) -> String {
        if seconds < 60 {
            return String(format: "%.1fs", seconds)
        } else {
            let minutes = Int(seconds) / 60
            let remainingSeconds = Int(seconds) % 60
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }
}

#Preview {
    VideoThumbnailView(
        videoPath: "/Users/test/video.mp4",
        size: CGSize(width: 120, height: 68)
    )
}