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
    var enableHoverPreview: Bool = true
    @State private var thumbnail: NSImage?
    @State private var isLoading = true
    @State private var isHovering = false
    @State private var hoverLocation: CGPoint = .zero

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
        .onHover { hovering in
            if enableHoverPreview {
                isHovering = hovering
            }
        }
        .overlay(
            Group {
                if enableHoverPreview && isHovering && thumbnail != nil {
                    HoverPreviewView(
                        thumbnail: thumbnail,
                        videoPath: videoPath,
                        isShowing: $isHovering
                    )
                }
            }
        )
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

// MARK: - Hover Preview View
struct HoverPreviewView: View {
    let thumbnail: NSImage?
    let videoPath: String
    @Binding var isShowing: Bool
    @State private var largeThumbnail: NSImage?

    private let previewSize = CGSize(width: 320, height: 180) // Larger preview size

    var body: some View {
        GeometryReader { geometry in
            if isShowing {
                VStack(alignment: .leading, spacing: 8) {
                    // Large thumbnail
                    if let largeThumbnail = largeThumbnail {
                        Image(nsImage: largeThumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: previewSize.width, height: previewSize.height)
                            .cornerRadius(8)
                    } else if let thumbnail = thumbnail {
                        // Fallback to regular thumbnail while loading
                        Image(nsImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: previewSize.width, height: previewSize.height)
                            .cornerRadius(8)
                    }

                    // Video info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(URL(fileURLWithPath: videoPath).lastPathComponent)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        HStack {
                            Label(formatDuration(getDuration()), systemImage: "clock")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Spacer()

                            if let fileSize = getFileSize() {
                                Text(fileSize)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .frame(width: previewSize.width)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .position(
                    x: min(max(previewSize.width/2 + 20, geometry.size.width/2),
                          geometry.frame(in: .global).maxX - previewSize.width/2 - 20),
                    y: max(previewSize.height/2 + 20, geometry.size.height/2 - 100)
                )
                .zIndex(1000)
                .transition(.scale.combined(with: .opacity))
                .animation(.easeOut(duration: 0.15), value: isShowing)
                .onAppear {
                    loadLargeThumbnail()
                }
            }
        }
        .allowsHitTesting(false) // Prevent the overlay from intercepting mouse events
    }

    private func loadLargeThumbnail() {
        // Generate a larger thumbnail for the preview
        DispatchQueue.global(qos: .userInteractive).async {
            let url = URL(fileURLWithPath: videoPath)
            let asset = AVAsset(url: url)

            guard asset.isReadable else { return }

            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: 640, height: 360) // Larger size for preview

            var thumbnailTime = CMTime(seconds: 1.0, preferredTimescale: 600)

            let duration = asset.duration
            if duration.isValid && !duration.isIndefinite {
                let durationSeconds = CMTimeGetSeconds(duration)
                if durationSeconds > 0 && durationSeconds < 1.0 {
                    thumbnailTime = CMTime(seconds: durationSeconds * 0.1, preferredTimescale: 600)
                }
            }

            do {
                let cgImage = try imageGenerator.copyCGImage(at: thumbnailTime, actualTime: nil)
                let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))

                DispatchQueue.main.async {
                    self.largeThumbnail = nsImage
                }
            } catch {
                print("Failed to generate large thumbnail: \(error)")
            }
        }
    }

    private func getDuration() -> Double {
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

    private func getFileSize() -> String? {
        let url = URL(fileURLWithPath: videoPath)

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                let formatter = ByteCountFormatter()
                formatter.countStyle = .file
                return formatter.string(fromByteCount: fileSize)
            }
        } catch {
            print("Error getting file size: \(error)")
        }

        return nil
    }
}

// MARK: - Image Thumbnail View with Hover
struct ImageThumbnailView: View {
    let imagePath: String
    let size: CGSize
    var enableHoverPreview: Bool = true
    @State private var isHovering = false

    var body: some View {
        if let nsImage = NSImage(contentsOfFile: imagePath) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipped()
                .cornerRadius(4)
                .onHover { hovering in
                    if enableHoverPreview {
                        isHovering = hovering
                    }
                }
                .overlay(
                    Group {
                        if enableHoverPreview && isHovering {
                            ImageHoverPreviewView(
                                imagePath: imagePath,
                                isShowing: $isHovering
                            )
                        }
                    }
                )
        } else {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: size.width, height: size.height)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                        .font(.title2)
                )
        }
    }
}

// MARK: - Image Hover Preview View
struct ImageHoverPreviewView: View {
    let imagePath: String
    @Binding var isShowing: Bool

    private let previewSize = CGSize(width: 320, height: 320) // Max size, will maintain aspect ratio

    var body: some View {
        GeometryReader { geometry in
            if isShowing, let nsImage = NSImage(contentsOfFile: imagePath) {
                VStack(alignment: .leading, spacing: 8) {
                    // Large image preview
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: previewSize.width, maxHeight: previewSize.height)
                        .cornerRadius(8)

                    // Image info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(URL(fileURLWithPath: imagePath).lastPathComponent)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        HStack {
                            if let dimensions = getImageDimensions(nsImage) {
                                Text(dimensions)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if let fileSize = getFileSize() {
                                Text(fileSize)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .frame(maxWidth: previewSize.width)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .position(
                    x: min(max(previewSize.width/2 + 20, geometry.size.width/2),
                          geometry.frame(in: .global).maxX - previewSize.width/2 - 20),
                    y: max(previewSize.height/2 + 20, geometry.size.height/2 - 100)
                )
                .zIndex(1000)
                .transition(.scale.combined(with: .opacity))
                .animation(.easeOut(duration: 0.15), value: isShowing)
            }
        }
        .allowsHitTesting(false) // Prevent the overlay from intercepting mouse events
    }

    private func getImageDimensions(_ image: NSImage) -> String? {
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        return "\(width) × \(height)"
    }

    private func getFileSize() -> String? {
        let url = URL(fileURLWithPath: imagePath)

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                let formatter = ByteCountFormatter()
                formatter.countStyle = .file
                return formatter.string(fromByteCount: fileSize)
            }
        } catch {
            print("Error getting file size: \(error)")
        }

        return nil
    }
}

#Preview {
    VideoThumbnailView(
        videoPath: "/Users/test/video.mp4",
        size: CGSize(width: 120, height: 68)
    )
}