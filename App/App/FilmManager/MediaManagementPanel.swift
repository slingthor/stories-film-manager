import SwiftUI
import Combine
import UniformTypeIdentifiers
import AppKit
import AVFoundation

struct MediaManagementPanel: View {
    let shot: FilmShot?
    @ObservedObject var filmManager: FilmManager
    @State private var showingImageViewer = false
    @State private var selectedImage: ImageFile?
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
                            onAddVideo: { addVideosFromFilePicker(to: shot) },
                            onAddImage: { addImagesFromFilePicker(to: shot) },
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

                        // Prompt Variants Media Section
                        PromptVariantsMediaSection(
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
    }
    
    private func addVideosFromFilePicker(to shot: FilmShot) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.movie, .mpeg4Movie, .quickTimeMovie, .avi]
        panel.message = "Select one or more video files"
        panel.prompt = "Add Videos"

        if panel.runModal() == .OK {
            for url in panel.urls {
                // Get video duration
                let asset = AVAsset(url: url)
                let duration = CMTimeGetSeconds(asset.duration)
                let finalDuration = duration.isFinite ? duration : 0.0

                let video = VideoFile(
                    filename: url.lastPathComponent,
                    filepath: url.path,
                    duration: finalDuration
                )
                shot.addVideo(video)
                print("✅ Added video via picker: \(video.filename) (duration: \(video.duration)s)")
            }

            // Mark shot as dirty and save
            shot.isDirty = true
            filmManager.fileManager.saveShot(shot)

            // Update timeline if needed
            filmManager.updateTimelineFromSelectedVideos()

            // Force UI refresh
            shot.objectWillChange.send()
            filmManager.objectWillChange.send()
        }
    }

    private func addImagesFromFilePicker(to shot: FilmShot) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image, .jpeg, .png, .gif, .bmp, .tiff, .heic]
        panel.message = "Select one or more image files"
        panel.prompt = "Add Images"

        if panel.runModal() == .OK {
            for url in panel.urls {
                let image = ImageFile(
                    filename: url.lastPathComponent,
                    filepath: url.path,
                    description: "Reference image for \(shot.title)"
                )
                shot.addImage(image)
                print("✅ Added image via picker: \(image.filename)")
            }

            // Mark shot as dirty and save
            shot.isDirty = true
            filmManager.fileManager.saveShot(shot)

            // Force UI refresh
            shot.objectWillChange.send()
            filmManager.objectWillChange.send()
        }
    }
    
    private func playVideo(_ video: VideoFile) {
        VideoPlayerWindowController.openVideoPlayer(
            for: video.filepath,
            title: video.filename
        )
        print("🎬 Playing video: \(video.filename)")
    }

    private func playVideo(_ path: String) {
        let filename = URL(fileURLWithPath: path).lastPathComponent
        VideoPlayerWindowController.openVideoPlayer(
            for: path,
            title: filename
        )
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

// MARK: - Prompt Variants Media Section
struct PromptVariantsMediaSection: View {
    let shot: FilmShot
    @ObservedObject var filmManager: FilmManager
    let onPlayVideo: (VideoFile) -> Void
    let onSelectImage: (ImageFile) -> Void
    let onShowInFinder: (String) -> Void
    @Binding var draggedMediaType: String?
    @Binding var draggedMediaPath: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("PROMPT VARIANTS MEDIA", systemImage: "rectangle.stack.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)

                Spacer()

                Text("\(shot.promptVariants.count) variants")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(4)
            }

            if shot.promptVariants.isEmpty {
                VStack {
                    Image(systemName: "rectangle.stack.badge.questionmark")
                        .font(.title2)
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No prompt variants")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(6)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(Array(shot.promptVariants.enumerated()), id: \.element.id) { index, variant in
                            PromptVariantMediaItem(
                                variant: variant,
                                variantIndex: index,
                                isActive: variant.isActive,
                                shot: shot,
                                filmManager: filmManager,
                                onPlayVideo: onPlayVideo,
                                onSelectImage: onSelectImage,
                                onShowInFinder: onShowInFinder,
                                draggedMediaType: $draggedMediaType,
                                draggedMediaPath: $draggedMediaPath
                            )
                        }
                    }
                }
                .frame(maxHeight: 300) // Limit height to prevent overflow
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Prompt Variant Media Item
struct PromptVariantMediaItem: View {
    @ObservedObject var variant: PromptVariant
    let variantIndex: Int
    let isActive: Bool
    let shot: FilmShot
    @ObservedObject var filmManager: FilmManager
    let onPlayVideo: (VideoFile) -> Void
    let onSelectImage: (ImageFile) -> Void
    let onShowInFinder: (String) -> Void
    @Binding var draggedMediaType: String?
    @Binding var draggedMediaPath: String?

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, error in
                    if let data = data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        self.processDroppedFile(at: url)
                    }
                }
            }
        }
        return true
    }

    private func processDroppedFile(at url: URL) {
        print("   ✅ Processing file: \(url.path)")

        DispatchQueue.main.async {
            let fileExtension = url.pathExtension.lowercased()
            let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v", "webm"]
            let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic"]

            if videoExtensions.contains(fileExtension) {
                // Generate duration for video
                let duration = self.getVideoDuration(at: url) ?? 0.0

                let video = VideoFile(
                    filename: url.lastPathComponent,
                    filepath: url.path,
                    duration: duration
                )

                // Add video and trigger all necessary updates
                self.variant.addVideo(video)
                print("✅ Added video to variant '\(self.variant.name)': \(video.filename) (duration: \(video.duration)s)")
                print("   Variant now has \(self.variant.videos.count) videos")

                // Mark shot as dirty BEFORE saving
                self.shot.isDirty = true

                // Save to JSON immediately
                self.filmManager.fileManager.saveShot(self.shot)
                print("   💾 Saved shot to JSON")

                // Now trigger UI updates
                if self.variant.isActive {
                    self.filmManager.updateTimelineFromSelectedVideos()
                }

                // Force refresh at all levels
                self.variant.objectWillChange.send()
                self.shot.objectWillChange.send()
                self.filmManager.objectWillChange.send()

            } else if imageExtensions.contains(fileExtension) {
                let image = ImageFile(filename: url.lastPathComponent, filepath: url.path)

                // Add image and trigger all necessary updates
                self.variant.addImage(image)
                print("✅ Added image to variant '\(self.variant.name)': \(image.filename)")
                print("   Variant now has \(self.variant.images.count) images")

                // Mark shot as dirty BEFORE saving
                self.shot.isDirty = true

                // Save to JSON immediately
                self.filmManager.fileManager.saveShot(self.shot)
                print("   💾 Saved shot to JSON")

                // Force refresh at all levels
                self.variant.objectWillChange.send()
                self.shot.objectWillChange.send()
                self.filmManager.objectWillChange.send()

            } else {
                print("⚠️ Unsupported file type: \(fileExtension)")
            }
        }
    }

    private func getVideoDuration(at url: URL) -> Double? {
        let asset = AVAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        return duration.isFinite ? duration : nil
    }

    @ViewBuilder
    private var variantHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(variant.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isActive ? .orange : .primary)

                if isActive {
                    Text("ACTIVE FOR TIMELINE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            mediaCountIndicators

            Button("Set Active") {
                shot.setActivePrompt(at: variantIndex)
                filmManager.fileManager.saveShot(shot)
                filmManager.updateTimelineFromSelectedVideos()
            }
            .buttonStyle(.bordered)
            .font(.caption2)
            .disabled(isActive)
        }
    }

    @ViewBuilder
    private var mediaCountIndicators: some View {
        HStack(spacing: 8) {
            if !variant.videos.isEmpty {
                HStack(spacing: 2) {
                    Image(systemName: "video.fill")
                        .font(.caption2)
                    Text("\(variant.videos.count)")
                        .font(.caption2)
                }
                .foregroundColor(.blue)

                if let activeIndex = variant.activeVideoIndex {
                    Text("(#\(activeIndex + 1) active)")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }

            if !variant.images.isEmpty {
                HStack(spacing: 2) {
                    Image(systemName: "photo.fill")
                        .font(.caption2)
                    Text("\(variant.images.count)")
                        .font(.caption2)
                }
                .foregroundColor(.purple)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            variantHeader

            // Videos section
            if !variant.videos.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Videos")
                        .font(.caption2)
                        .foregroundColor(.blue)

                    LazyVStack(spacing: 2) {
                        ForEach(Array(variant.videos.enumerated()), id: \.element.id) { videoIndex, video in
                            PromptVideoRow(
                                video: video,
                                videoIndex: videoIndex,
                                variant: variant,
                                isActive: variant.activeVideoIndex == videoIndex,
                                onSelect: {
                                    variant.setActiveVideo(at: videoIndex)
                                    if isActive { // Only update timeline if this variant is active
                                        filmManager.updateTimelineFromSelectedVideos()
                                    }
                                },
                                onPlay: { onPlayVideo(video) },
                                onDelete: {
                                    variant.removeVideo(at: videoIndex)
                                    if isActive { // Only update timeline if this variant is active
                                        filmManager.updateTimelineFromSelectedVideos()
                                    }
                                },
                                onShowInFinder: { onShowInFinder(video.filepath) }
                            )
                        }
                    }
                }
            }

            // Images section
            if !variant.images.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Images")
                        .font(.caption2)
                        .foregroundColor(.purple)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 4) {
                        ForEach(Array(variant.images.enumerated()), id: \.element.id) { imageIndex, image in
                            PromptImageThumbnail(
                                image: image,
                                imageIndex: imageIndex,
                                variant: variant,
                                onTap: { onSelectImage(image) },
                                onShowInFinder: { onShowInFinder(image.filepath) }
                            )
                        }
                    }
                }
            }

            // Baked Prompts section
            BakedPromptsSection(variant: variant, shot: shot, filmManager: filmManager)

            // Drop zone - always visible
            VStack {
                Image(systemName: "square.and.arrow.down.on.square")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("Drop media for \(variant.name)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [2]))
            )
            .onDrop(of: [.fileURL], isTargeted: .constant(false), perform: handleDrop)
        }
        .padding(8)
        .background(isActive ? Color.orange.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isActive ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Prompt Video Row
struct PromptVideoRow: View {
    let video: VideoFile
    let videoIndex: Int
    @ObservedObject var variant: PromptVariant
    let isActive: Bool
    let onSelect: () -> Void
    let onPlay: () -> Void
    let onDelete: () -> Void
    let onShowInFinder: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Active indicator
            Circle()
                .fill(isActive ? Color.green : Color.clear)
                .frame(width: 6, height: 6)
                .overlay(
                    Circle().stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )

            // Video thumbnail
            VideoThumbnailView(
                videoPath: video.filepath,
                size: CGSize(width: 24, height: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(isActive ? Color.green : Color.gray.opacity(0.3), lineWidth: isActive ? 2 : 1)
            )
            .onTapGesture(count: 1) {
                onSelect()
            }
            .onTapGesture(count: 2) {
                onPlay()
            }

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text(video.filename)
                        .font(.caption2)
                        .lineLimit(1)
                        .fontWeight(isActive ? .semibold : .regular)

                    // Generator label
                    let generator = VideoGeneratorDetector.detectGenerator(from: video.filename)
                    if generator != .unknown {
                        Text(generator.rawValue)
                            .font(.system(size: 9))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(generator.color)
                            .cornerRadius(3)
                    }
                }

                Text("\(String(format: "%.1f", video.duration))s")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Action buttons
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
        .padding(4)
        .background(isActive ? Color.green.opacity(0.1) : Color.clear)
        .cornerRadius(3)
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - Prompt Image Thumbnail
struct PromptImageThumbnail: View {
    let image: ImageFile
    let imageIndex: Int
    @ObservedObject var variant: PromptVariant
    let onTap: () -> Void
    let onShowInFinder: () -> Void
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 2) {
            // Use ImageThumbnailView with hover preview
            ImageThumbnailView(
                imagePath: image.filepath,
                size: CGSize(width: 40, height: 40),
                enableHoverPreview: true
            )
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isHovered ? Color.blue : Color.clear, lineWidth: 1)
            )

            Text(image.filename)
                .font(.caption2)
                .lineLimit(1)
                .frame(width: 40)
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button("Show in Finder") {
                onShowInFinder()
            }
            Button("Remove") {
                variant.removeImage(at: imageIndex)
            }
        }
    }
}

// MARK: - Drop Delegate for Shot Videos
struct ShotVideoDropDelegate: DropDelegate {
    let shot: FilmShot
    let targetIndex: Int
    @ObservedObject var filmManager: FilmManager

    func performDrop(info: DropInfo) -> Bool {
        // Check if this is a video from a prompt variant being dragged to shot level
        guard let itemProvider = info.itemProviders(for: [.text]).first else {
            return false
        }

        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, error in
            if let data = data as? Data,
               let draggedPath = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    // Find if this video exists in any prompt variant
                    for variant in shot.promptVariants {
                        if let videoIndex = variant.videos.firstIndex(where: { $0.filepath == draggedPath }) {
                            let video = variant.videos[videoIndex]

                            // Copy video to shot level (don't remove from variant)
                            if !shot.videos.contains(where: { $0.filepath == video.filepath }) {
                                shot.addVideo(video)
                                filmManager.updateTimelineFromSelectedVideos()
                                print("📋 Copied video from variant '\(variant.name)' to shot level: \(video.filename)")
                            }
                            break
                        }
                    }
                }
            }
        }

        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .copy)
    }
}

// MARK: - Drop Delegate for Prompt Variants
struct PromptVariantDropDelegate: DropDelegate {
    @ObservedObject var variant: PromptVariant
    @ObservedObject var filmManager: FilmManager

    func performDrop(info: DropInfo) -> Bool {
        print("🎯 performDrop called for variant: \(variant.name)")
        print("   Available type identifiers: \(info.itemProviders(for: [.fileURL]).count) fileURL providers")

        // First check for file URLs (when dragging from Finder)
        if let itemProvider = info.itemProviders(for: [.fileURL]).first {
            print("   Found fileURL provider, attempting to load...")

            // Try loading as URL first (more reliable)
            itemProvider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
                if let error = error {
                    print("❌ Error loading file URL: \(error.localizedDescription)")
                    return
                }

                print("   Item loaded, type: \(type(of: item))")

                // Try different ways to get the URL
                var url: URL?

                if let urlItem = item as? URL {
                    url = urlItem
                    print("   ✅ Direct URL cast successful: \(urlItem.path)")
                } else if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                    print("   ℹ️ URL from data representation: \(url?.path ?? "nil")")
                } else if let string = item as? String {
                    url = URL(fileURLWithPath: string)
                    print("   ℹ️ URL from string path: \(url?.path ?? "nil")")
                } else if let nsurl = item as? NSURL {
                    url = nsurl as URL
                    print("   ℹ️ URL from NSURL: \(url?.path ?? "nil")")
                }

                guard let finalURL = url else {
                    print("❌ Failed to extract URL from drop data of type: \(type(of: item))")
                    return
                }

                DispatchQueue.main.async {
                    let fileExtension = finalURL.pathExtension.lowercased()
                    let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v", "webm"]
                    let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic"]

                    print("   File: \(finalURL.lastPathComponent), Extension: \(fileExtension)")

                    if videoExtensions.contains(fileExtension) {
                        let video = VideoFile(filename: finalURL.lastPathComponent, filepath: finalURL.path)
                        variant.addVideo(video)
                        if variant.isActive {
                            filmManager.updateTimelineFromSelectedVideos()
                        }
                        print("✅ Added video to variant '\(variant.name)': \(video.filename)")
                    } else if imageExtensions.contains(fileExtension) {
                        let image = ImageFile(filename: finalURL.lastPathComponent, filepath: finalURL.path)
                        variant.addImage(image)
                        print("✅ Added image to variant '\(variant.name)': \(image.filename)")
                    } else {
                        print("⚠️ Unsupported file type: \(fileExtension)")
                    }
                }
            }
            return true
        } else {
            print("⚠️ No fileURL providers found in drop info")
        }

        // Then check for internal drag from shot-level videos
        if let itemProvider = info.itemProviders(for: [.text]).first {
            itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, error in
                if let data = data as? Data,
                   let draggedPath = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        // Find the shot containing this variant to access shot-level videos
                        if let shot = filmManager.shots.first(where: { shot in
                            shot.promptVariants.contains { $0.id == variant.id }
                        }) {
                            // Find the video in shot-level videos
                            if let video = shot.videos.first(where: { $0.filepath == draggedPath }) {
                                // Copy video to this variant (don't remove from shot)
                                if !variant.videos.contains(where: { $0.filepath == video.filepath }) {
                                    variant.addVideo(video)
                                    if variant.isActive {
                                        filmManager.updateTimelineFromSelectedVideos()
                                    }
                                    print("📋 Copied video from shot to variant '\(variant.name)': \(video.filename)")
                                }
                            }
                        }
                    }
                }
            }
            return true
        }

        return false
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        print("📍 dropUpdated called for variant: \(variant.name)")
        return DropProposal(operation: .copy)
    }

    func dropEntered(info: DropInfo) {
        print("➡️ dropEntered for variant: \(variant.name)")
    }

    func dropExited(info: DropInfo) {
        print("⬅️ dropExited for variant: \(variant.name)")
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
            if type == "video" {
                VideoThumbnailView(
                    videoPath: path,
                    size: CGSize(width: 32, height: 18)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                )
                .onTapGesture(count: 2) {
                    onPlay()
                }
            } else {
                Image(systemName: "photo.fill")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .frame(width: 32, height: 18)
            }

            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .lineLimit(1)

                // Generator label for videos
                if type == "video" {
                    let generator = VideoGeneratorDetector.detectGenerator(from: title)
                    if generator != .unknown {
                        Text(generator.rawValue)
                            .font(.system(size: 9))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(generator.color)
                            .cornerRadius(3)
                    }
                }
            }

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
            // Use ImageThumbnailView with hover preview
            ImageThumbnailView(
                imagePath: image.filepath,
                size: CGSize(width: 60, height: 60),
                enableHoverPreview: true
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


// MARK: - Baked Prompts Section
struct BakedPromptsSection: View {
    @ObservedObject var variant: PromptVariant
    let shot: FilmShot
    @ObservedObject var filmManager: FilmManager
    @State private var showingBakedPromptEditor = false
    @State private var editingBakedPrompt: BakedPrompt?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Baked Prompts")
                    .font(.caption2)
                    .foregroundColor(.green)

                Spacer()

                Button(action: {
                    let newBakedPrompt = BakedPrompt(name: "Baked Prompt \(variant.bakedPrompts.count + 1)")
                    variant.bakedPrompts.append(newBakedPrompt)
                    editingBakedPrompt = newBakedPrompt
                    showingBakedPromptEditor = true

                    // Save baked prompts metadata and shot
                    do {
                        try BakedPromptManager.shared.saveBakedPromptsMetadata(variant.bakedPrompts, for: variant.variantId)
                        shot.isDirty = true
                        filmManager.fileManager.saveShot(shot)
                    } catch {
                        print("❌ Failed to save baked prompts metadata: \(error)")
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }

            if !variant.bakedPrompts.isEmpty {
                VStack(spacing: 2) {
                    ForEach(variant.bakedPrompts) { bakedPrompt in
                        BakedPromptRow(
                            bakedPrompt: bakedPrompt,
                            variant: variant,
                            shot: shot,
                            filmManager: filmManager,
                            onEdit: {
                                editingBakedPrompt = bakedPrompt
                                showingBakedPromptEditor = true
                            }
                        )
                    }
                }
            } else {
                Text("No baked prompts")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.vertical, 4)
            }
        }
        .sheet(isPresented: $showingBakedPromptEditor) {
            if let bakedPrompt = editingBakedPrompt {
                BakedPromptEditor(
                    bakedPrompt: bakedPrompt,
                    variant: variant,
                    shot: shot,
                    filmManager: filmManager,
                    onDismiss: {
                        showingBakedPromptEditor = false
                        editingBakedPrompt = nil
                    }
                )
            }
        }
    }
}

// MARK: - Baked Prompt Row
struct BakedPromptRow: View {
    let bakedPrompt: BakedPrompt
    @ObservedObject var variant: PromptVariant
    let shot: FilmShot
    @ObservedObject var filmManager: FilmManager
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.text.fill")
                .font(.caption2)
                .foregroundColor(.green)

            Text(bakedPrompt.name)
                .font(.caption2)
                .lineLimit(1)

            if let generator = bakedPrompt.generator {
                Text("(\(generator))")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)

            Button(action: {
                if let content = BakedPromptManager.shared.loadBakedPromptContent(for: bakedPrompt) {
                    BakedPromptManager.shared.copyToClipboard(content)
                    print("📋 Copied baked prompt to clipboard")
                }
            }) {
                Image(systemName: "doc.on.clipboard")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
            .buttonStyle(.plain)

            Button(action: {
                // Delete baked prompt
                if let index = variant.bakedPrompts.firstIndex(where: { $0.id == bakedPrompt.id }) {
                    BakedPromptManager.shared.deleteBakedPromptContent(for: bakedPrompt)
                    variant.bakedPrompts.remove(at: index)

                    // Save updated metadata and shot
                    do {
                        try BakedPromptManager.shared.saveBakedPromptsMetadata(variant.bakedPrompts, for: variant.variantId)
                        shot.isDirty = true
                        filmManager.fileManager.saveShot(shot)
                    } catch {
                        print("❌ Failed to save baked prompts metadata after deletion: \(error)")
                    }
                }
            }) {
                Image(systemName: "trash")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Color.green.opacity(0.05))
        .cornerRadius(4)
    }
}

#Preview {
    MediaManagementPanel(
        shot: nil,
        filmManager: FilmManager()
    )
}