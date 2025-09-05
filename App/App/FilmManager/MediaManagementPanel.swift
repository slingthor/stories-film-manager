import SwiftUI
import Combine
import AVKit
import UniformTypeIdentifiers

struct MediaManagementPanel: View {
    let shot: FilmShot?
    @ObservedObject var filmManager: FilmManager
    @State private var showingImageViewer = false
    @State private var selectedImageIndex: Int?
    @State private var player: AVPlayer?
    @State private var showingVideoPlayer = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("MEDIA MANAGEMENT")
                .font(.headline)
                .fontWeight(.semibold)
                .padding()
            
            if let shot = shot {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Video section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("VIDEOS (\(shot.videos.count))")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Button("+ Add Video") {
                                    addTestVideo(to: shot)
                                }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                            }
                            
                            if shot.videos.isEmpty {
                                VStack {
                                    Image(systemName: "video.slash")
                                        .font(.title2)
                                        .foregroundColor(.gray.opacity(0.5))
                                    Text("No videos")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .frame(height: 80)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(6)
                            } else {
                                // Video list with selection
                                LazyVStack(spacing: 4) {
                                    ForEach(0..<shot.videos.count, id: \.self) { index in
                                        VideoRowComplete(
                                            video: shot.videos[index],
                                            isSelected: shot.selectedVideoIndex == index,
                                            isCurrentlyPlaying: player != nil && shot.selectedVideoIndex == index,
                                            onSelect: {
                                                shot.selectVideo(at: index)
                                                filmManager.updateTimelineFromSelectedVideos()
                                            },
                                            onPlay: {
                                                playVideo(shot.videos[index])
                                            },
                                            onDelete: {
                                                shot.removeVideo(at: index)
                                                filmManager.updateTimelineFromSelectedVideos()
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Images section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("REFERENCE IMAGES (\(shot.images.count))")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Button("+ Add Image") {
                                    addTestImage(to: shot)
                                }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                            }
                            
                            if shot.images.isEmpty {
                                VStack {
                                    Image(systemName: "photo.slash")
                                        .font(.title2)
                                        .foregroundColor(.gray.opacity(0.5))
                                    Text("No reference images")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .frame(height: 60)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(6)
                            } else {
                                // Image grid
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 6) {
                                    ForEach(0..<shot.images.count, id: \.self) { index in
                                        ImageThumbnailComplete(
                                            image: shot.images[index],
                                            onTap: {
                                                selectedImageIndex = index
                                                showingImageViewer = true
                                            },
                                            onDelete: {
                                                shot.removeImage(at: index)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Drop zone for new media
                        VStack {
                            Image(systemName: "square.and.arrow.down")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text("Drag videos/images here")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(height: 60)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        )
                        .onDrop(of: [.movie, .image], isTargeted: nil) { providers in
                            handleMediaDrop(providers, for: shot)
                            return true
                        }
                    }
                }
                .padding()
                
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "photo.tv")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    VStack {
                        Text("Select a shot for media")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Videos and images are organized per shot")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showingImageViewer) {
            if let shot = shot, let imageIndex = selectedImageIndex, imageIndex < shot.images.count {
                ComprehensiveImageViewer(
                    image: shot.images[imageIndex],
                    onDismiss: { showingImageViewer = false }
                )
            }
        }
        .sheet(isPresented: $showingVideoPlayer) {
            if let player = player {
                VideoPlayerSheet(player: player, onDismiss: { showingVideoPlayer = false })
            }
        }
    }
    
    private func addTestVideo(to shot: FilmShot) {
        let video = VideoFile(
            filename: "shot_\(shot.id)_v\(shot.videos.count + 1).mp4",
            filepath: "/test/path/shot_\(shot.id)_video_\(shot.videos.count + 1).mp4"
        )
        
        shot.addVideo(video)
        filmManager.updateTimelineFromSelectedVideos()
    }
    
    private func addTestImage(to shot: FilmShot) {
        let image = ImageFile(
            filename: "ref_\(shot.id)_\(shot.images.count + 1).jpg",
            filepath: "/test/path/ref_\(shot.id)_image_\(shot.images.count + 1).jpg",
            description: "Reference image for \(shot.title)"
        )
        
        shot.addImage(image)
    }
    
    private func playVideo(_ video: VideoFile) {
        let url = URL(fileURLWithPath: video.filepath)
        player = AVPlayer(url: url)
        showingVideoPlayer = true
        print("🎬 Playing video: \(video.filename)")
    }
    
    private func handleMediaDrop(_ providers: [NSItemProvider], for shot: FilmShot) {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.movie.identifier, options: nil) { data, error in
                    if let url = data as? URL {
                        DispatchQueue.main.async {
                            let video = VideoFile(filename: url.lastPathComponent, filepath: url.path)
                            shot.addVideo(video)
                            filmManager.updateTimelineFromSelectedVideos()
                        }
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { data, error in
                    if let url = data as? URL {
                        DispatchQueue.main.async {
                            let image = ImageFile(filename: url.lastPathComponent, filepath: url.path)
                            shot.addImage(image)
                        }
                    }
                }
            }
        }
    }
}

struct VideoRowComplete: View {
    let video: VideoFile
    let isSelected: Bool
    let isCurrentlyPlaying: Bool
    let onSelect: () -> Void
    let onPlay: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            // Selection checkbox
            Button {
                onSelect()
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Video info
            VStack(alignment: .leading, spacing: 2) {
                Text(video.filename)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(video.generationDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if let rating = video.qualityRating {
                    HStack {
                        Text("★")
                            .foregroundColor(.yellow)
                        Text("\(rating, specifier: "%.1f")")
                            .font(.caption2)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            VStack {
                Button {
                    onPlay()
                } label: {
                    Image(systemName: isCurrentlyPlaying ? "pause.fill" : "play.fill")
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .onDrag {
            NSItemProvider(object: video.filename as NSString)
        }
    }
}

struct ImageThumbnailComplete: View {
    let image: ImageFile
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 60)
                .overlay(
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(.gray)
                )
                .onTapGesture {
                    onTap()
                }
            
            Text(image.filename)
                .font(.caption2)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
        .contextMenu {
            Button("View Full Size", action: onTap)
            Button("Delete", role: .destructive, action: onDelete)
        }
        .onDrag {
            NSItemProvider(object: image.filename as NSString)
        }
    }
}

struct ComprehensiveImageViewer: View {
    let image: ImageFile
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(image.filename)
                    .font(.headline)
                
                Spacer()
                
                Button("Export") {
                    exportImage()
                }
                .buttonStyle(.bordered)
                
                Button("Close") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Image display area
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .frame(width: 500, height: 400)
                .overlay(
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("Reference Image")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        
                        Text(image.filepath)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                )
            
            if !image.description.isEmpty {
                VStack(alignment: .leading) {
                    Text("Description:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(image.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(width: 600, height: 550)
    }
    
    private func exportImage() {
        // Export image functionality
        print("📤 Exporting image: \(image.filename)")
    }
}

struct VideoPlayerSheet: View {
    let player: AVPlayer
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            VideoPlayer(player: player)
                .frame(width: 600, height: 400)
                .cornerRadius(8)
            
            Button("Close") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .padding()
    }
}

#Preview {
    MediaManagementPanel(
        shot: nil,
        filmManager: FilmManager()
    )
}