import SwiftUI
import Combine
import AVKit
import UniformTypeIdentifiers
import AppKit

struct MediaManagementPanel: View {
    let shot: FilmShot?
    @ObservedObject var filmManager: FilmManager
    @State private var showingImageViewer = false
    @State private var selectedImage: ImageFile?
    @State private var player: AVPlayer?
    @State private var showingVideoPlayer = false
    @State private var draggedMediaType: String?
    @State private var draggedMediaPath: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("MEDIA MANAGEMENT")
                .font(.headline)
                .fontWeight(.semibold)
                .padding()
            
            if let shot = shot {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Shot Media Section
                        MediaSection(
                            title: "SHOT MEDIA",
                            icon: "film",
                            videos: shot.videos,
                            images: shot.images,
                            color: .blue,
                            onAddVideo: { addTestVideo(to: shot) },
                            onAddImage: { addTestImage(to: shot) },
                            onSelectVideo: { index in
                                shot.selectVideo(at: index)
                                filmManager.updateTimelineFromSelectedVideos()
                            },
                            onPlayVideo: { video in playVideo(video) },
                            onDeleteVideo: { index in
                                shot.removeVideo(at: index)
                                filmManager.updateTimelineFromSelectedVideos()
                            },
                            onSelectImage: { image in
                                selectedImage = image
                                showingImageViewer = true
                            },
                            onDeleteImage: { index in
                                shot.removeImage(at: index)
                            },
                            onShowInFinder: { path in showInFinder(path) },
                            selectedVideoIndex: shot.selectedVideoIndex,
                            draggedMediaType: $draggedMediaType,
                            draggedMediaPath: $draggedMediaPath
                        )
                        
                        Divider()
                        
                        // Character Media Section
                        CharacterMediaSection(
                            shot: shot,
                            filmManager: filmManager,
                            onPlayVideo: { video in playVideo(video) },
                            onSelectImage: { image in
                                selectedImage = image
                                showingImageViewer = true
                            },
                            onShowInFinder: { path in showInFinder(path) },
                            draggedMediaType: $draggedMediaType,
                            draggedMediaPath: $draggedMediaPath
                        )
                        
                        Divider()
                        
                        // Environment Media Section
                        EnvironmentMediaSection(
                            shot: shot,
                            filmManager: filmManager,
                            onPlayVideo: { video in playVideo(video) },
                            onSelectImage: { image in
                                selectedImage = image
                                showingImageViewer = true
                            },
                            onShowInFinder: { path in showInFinder(path) },
                            draggedMediaType: $draggedMediaType,
                            draggedMediaPath: $draggedMediaPath
                        )
                    }
                    .padding()
                }
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
            if let image = selectedImage {
                ComprehensiveImageViewer(
                    image: image,
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
    
    private func playVideo(_ path: String) {
        let url = URL(fileURLWithPath: path)
        player = AVPlayer(url: url)
        showingVideoPlayer = true
        print("🎬 Playing video from path: \(path)")
    }
    
    private func showInFinder(_ path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    private func openInPreview(_ path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(url)
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

// MARK: - Generic Media Section
struct MediaSection: View {
    let title: String
    let icon: String
    let videos: [VideoFile]
    let images: [ImageFile]
    let color: Color
    let onAddVideo: () -> Void
    let onAddImage: () -> Void
    let onSelectVideo: (Int) -> Void
    let onPlayVideo: (VideoFile) -> Void
    let onDeleteVideo: (Int) -> Void
    let onSelectImage: (ImageFile) -> Void
    let onDeleteImage: (Int) -> Void
    let onShowInFinder: (String) -> Void
    let selectedVideoIndex: Int?
    @Binding var draggedMediaType: String?
    @Binding var draggedMediaPath: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: onAddVideo) {
                        Label("Add Video", systemImage: "video.badge.plus")
                            .font(.caption)
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Button(action: onAddImage) {
                        Label("Add Image", systemImage: "photo.badge.plus")
                            .font(.caption)
                    }
                    .buttonStyle(BorderedButtonStyle())
                }
            }
            
            // Videos
            if !videos.isEmpty {
                Text("Videos (\(videos.count))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVStack(spacing: 4) {
                    ForEach(0..<videos.count, id: \.self) { index in
                        MediaRow(
                            title: videos[index].filename,
                            path: videos[index].filepath,
                            type: "video",
                            isSelected: selectedVideoIndex == index,
                            onSelect: { onSelectVideo(index) },
                            onPlay: { onPlayVideo(videos[index]) },
                            onDelete: { onDeleteVideo(index) },
                            onShowInFinder: { onShowInFinder(videos[index].filepath) },
                            draggedMediaType: $draggedMediaType,
                            draggedMediaPath: $draggedMediaPath
                        )
                    }
                }
            }
            
            // Images
            if !images.isEmpty {
                Text("Images (\(images.count))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 6) {
                    ForEach(0..<images.count, id: \.self) { index in
                        ImageThumbnail(
                            image: images[index],
                            onTap: { onSelectImage(images[index]) },
                            onDoubleTap: {
                                NSWorkspace.shared.open(URL(fileURLWithPath: images[index].filepath))
                            },
                            onDelete: { onDeleteImage(index) },
                            onShowInFinder: { onShowInFinder(images[index].filepath) },
                            draggedMediaType: $draggedMediaType,
                            draggedMediaPath: $draggedMediaPath
                        )
                    }
                }
            }
            
            // Drop zone
            if videos.isEmpty && images.isEmpty {
                VStack {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Text("Drop media here")
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
            }
        }
        .padding()
        .background(color.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Character Media Section
struct CharacterMediaSection: View {
    let shot: FilmShot
    @ObservedObject var filmManager: FilmManager
    let onPlayVideo: (String) -> Void
    let onSelectImage: (ImageFile) -> Void
    let onShowInFinder: (String) -> Void
    @Binding var draggedMediaType: String?
    @Binding var draggedMediaPath: String?
    
    var activeVariant: PromptVariant? {
        shot.promptVariants.first(where: { $0.isActive }) ?? shot.promptVariants.first
    }
    
    var selectedCharacterPlate: CharacterPlate? {
        guard let variant = activeVariant,
              let plateId = variant.selectedCharacterPlateId else { return nil }
        return filmManager.plateManager.characterPlates.first(where: { $0.plateId == plateId })
    }
    
    var characterMedia: [(String, [PlateMedia])] {
        guard let plate = selectedCharacterPlate else { return [] }
        
        var mediaGroups: [(String, [PlateMedia])] = []
        
        // Specialization media first
        if let spec = plate.specializations.first(where: { $0.plateId == plate.plateId }) {
            if !spec.media.isEmpty {
                mediaGroups.append(("\(plate.name) (Specialization)", spec.media))
            }
        }
        
        // Main character media
        if let mainPlate = filmManager.plateManager.mainCharacterPlates.first(where: { $0.character == plate.character }) {
            if !mainPlate.media.isEmpty {
                mediaGroups.append(("\(plate.character) (Main)", mainPlate.media))
            }
        }
        
        // Current plate media if different from above
        if !plate.media.isEmpty && !plate.isMainPlate {
            mediaGroups.append((plate.name, plate.media))
        }
        
        return mediaGroups
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("CHARACTER MEDIA", systemImage: "person.2.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.purple)
                
                Spacer()
                
                if let plate = selectedCharacterPlate {
                    Text(plate.character)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            if characterMedia.isEmpty {
                VStack {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.title2)
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No character media")
                        .font(.caption)
                        .foregroundColor(.gray)
                    if selectedCharacterPlate == nil {
                        Text("Select a character plate first")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(6)
            } else {
                ForEach(characterMedia, id: \.0) { groupName, media in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(groupName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(media, id: \.id) { item in
                                    PlateMediaItem(
                                        media: item,
                                        onPlay: { if item.type == "video" { onPlayVideo(item.path) } },
                                        onShowInFinder: { onShowInFinder(item.path) },
                                        draggedMediaType: $draggedMediaType,
                                        draggedMediaPath: $draggedMediaPath
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Environment Media Section
struct EnvironmentMediaSection: View {
    let shot: FilmShot
    @ObservedObject var filmManager: FilmManager
    let onPlayVideo: (String) -> Void
    let onSelectImage: (ImageFile) -> Void
    let onShowInFinder: (String) -> Void
    @Binding var draggedMediaType: String?
    @Binding var draggedMediaPath: String?
    
    var activeVariant: PromptVariant? {
        shot.promptVariants.first(where: { $0.isActive }) ?? shot.promptVariants.first
    }
    
    var selectedEnvironmentPlate: EnvironmentalPlate? {
        guard let variant = activeVariant,
              let plateId = variant.selectedEnvironmentPlateId else { return nil }
        return filmManager.plateManager.environmentalPlates.first(where: { $0.plateId == plateId })
    }
    
    var environmentMedia: [(String, [PlateMedia])] {
        guard let plate = selectedEnvironmentPlate else { return [] }
        
        var mediaGroups: [(String, [PlateMedia])] = []
        
        // Specific environment media
        if !plate.media.isEmpty {
            mediaGroups.append((plate.name, plate.media))
        }
        
        // General category media (if exists)
        let categoryPlates = filmManager.plateManager.environmentalPlates.filter { 
            $0.category == plate.category && $0.plateId != plate.plateId
        }
        for catPlate in categoryPlates {
            if !catPlate.media.isEmpty {
                mediaGroups.append(("\(catPlate.name) (Category)", catPlate.media))
            }
        }
        
        return mediaGroups
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("ENVIRONMENT MEDIA", systemImage: "mountain.2.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Spacer()
                
                if let plate = selectedEnvironmentPlate {
                    Text(plate.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            if environmentMedia.isEmpty {
                VStack {
                    Image(systemName: "mountain.2.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No environment media")
                        .font(.caption)
                        .foregroundColor(.gray)
                    if selectedEnvironmentPlate == nil {
                        Text("Select an environment plate first")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(6)
            } else {
                ForEach(environmentMedia, id: \.0) { groupName, media in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(groupName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(media, id: \.id) { item in
                                    PlateMediaItem(
                                        media: item,
                                        onPlay: { if item.type == "video" { onPlayVideo(item.path) } },
                                        onShowInFinder: { onShowInFinder(item.path) },
                                        draggedMediaType: $draggedMediaType,
                                        draggedMediaPath: $draggedMediaPath
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Media Row
struct MediaRow: View {
    let title: String
    let path: String
    let type: String
    let isSelected: Bool
    let onSelect: () -> Void
    let onPlay: () -> Void
    let onDelete: () -> Void
    let onShowInFinder: () -> Void
    @Binding var draggedMediaType: String?
    @Binding var draggedMediaPath: String?
    
    var body: some View {
        HStack {
            Image(systemName: type == "video" ? "video.fill" : "photo.fill")
                .foregroundColor(isSelected ? .blue : .gray)
            
            Text(title)
                .font(.caption)
                .lineLimit(1)
            
            Spacer()
            
            HStack(spacing: 4) {
                Button(action: onPlay) {
                    Image(systemName: "play.circle")
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onShowInFinder) {
                    Image(systemName: "folder")
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(6)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(4)
        .onTapGesture {
            onSelect()
        }
        .draggable(path) {
            Text(title)
                .onAppear {
                    draggedMediaType = type
                    draggedMediaPath = path
                }
        }
    }
}

// MARK: - Image Thumbnail
struct ImageThumbnail: View {
    let image: ImageFile
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let onDelete: () -> Void
    let onShowInFinder: () -> Void
    @Binding var draggedMediaType: String?
    @Binding var draggedMediaPath: String?
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isHovered ? Color.blue : Color.clear, lineWidth: 2)
                )
                .overlay(
                    // Action buttons on hover
                    Group {
                        if isHovered {
                            VStack {
                                HStack {
                                    Spacer()
                                    Button(action: onShowInFinder) {
                                        Image(systemName: "folder")
                                            .font(.caption2)
                                            .padding(2)
                                            .background(Color.black.opacity(0.5))
                                            .cornerRadius(2)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                Spacer()
                            }
                            .padding(2)
                        }
                    }
                )
            
            Text(image.filename)
                .font(.caption2)
                .lineLimit(1)
                .frame(width: 60)
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture(count: 2) {
            onDoubleTap()
        }
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button("Open in Preview") {
                onDoubleTap()
            }
            Button("Show in Finder") {
                onShowInFinder()
            }
            Divider()
            Button("Delete") {
                onDelete()
            }
        }
        .draggable(image.filepath) {
            Text(image.filename)
                .onAppear {
                    draggedMediaType = "image"
                    draggedMediaPath = image.filepath
                }
        }
    }
}

// MARK: - Plate Media Item
struct PlateMediaItem: View {
    let media: PlateMedia
    let onPlay: () -> Void
    let onShowInFinder: () -> Void
    @Binding var draggedMediaType: String?
    @Binding var draggedMediaPath: String?
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: media.type == "video" ? "video.fill" : "photo.fill")
                        .foregroundColor(.gray)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isHovered ? Color.blue : Color.clear, lineWidth: 2)
                )
            
            Text(URL(fileURLWithPath: media.path).lastPathComponent)
                .font(.caption2)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 60)
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture(count: 2) {
            if media.type == "image" {
                NSWorkspace.shared.open(URL(fileURLWithPath: media.path))
            } else {
                onPlay()
            }
        }
        .onTapGesture {
            if media.type == "video" {
                onPlay()
            }
        }
        .contextMenu {
            Button("Show in Finder") {
                onShowInFinder()
            }
            if media.type == "image" {
                Button("Open in Preview") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: media.path))
                }
            }
        }
        .popover(isPresented: .constant(isHovered && media.caption != nil)) {
            if let caption = media.caption {
                Text(caption)
                    .font(.caption)
                    .padding()
                    .frame(maxWidth: 200)
            }
        }
        .draggable(media.path) {
            Text(URL(fileURLWithPath: media.path).lastPathComponent)
                .onAppear {
                    draggedMediaType = media.type
                    draggedMediaPath = media.path
                }
        }
    }
}

// MARK: - Supporting Views
struct ComprehensiveImageViewer: View {
    let image: ImageFile
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text(image.filename)
                .font(.title2)
                .padding()
            
            Text(image.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 400, height: 300)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                )
            
            Spacer()
            
            HStack {
                Button("Open in Preview") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: image.filepath))
                }
                .buttonStyle(.bordered)
                
                Button("Show in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: image.filepath)])
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Close") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 600, height: 500)
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