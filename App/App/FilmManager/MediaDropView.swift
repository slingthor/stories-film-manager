import SwiftUI
import UniformTypeIdentifiers

struct MediaDropView: View {
    let type: String // "shot" or "plate"
    let id: String
    @ObservedObject var filmManager: FilmManager
    @State private var isDropTarget = false
    
    var body: some View {
        VStack {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundColor(isDropTarget ? .blue : .gray)
            
            Text("Drop images or videos here")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isDropTarget ? Color.blue : Color.gray.opacity(0.3), 
                       style: StrokeStyle(lineWidth: 2, dash: [5]))
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isDropTarget ? Color.blue.opacity(0.1) : Color.clear)
                )
        )
        .onDrop(of: [.fileURL, .image, .movie], isTargeted: $isDropTarget) { providers in
            handleDrop(providers: providers)
            return true
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            processFile(at: url)
                        }
                    }
                }
            }
        }
    }
    
    private func processFile(at url: URL) {
        let fileExtension = url.pathExtension.lowercased()
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic"]
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v", "webm"]
        
        if imageExtensions.contains(fileExtension) || videoExtensions.contains(fileExtension) {
            // Copy to resources folder
            if let destPath = AppDataManager.shared.copyMediaToResources(
                from: url.path,
                type: type == "shot" ? "shots" : "plates",
                id: id
            ) {
                // Update the appropriate data model
                let filename = URL(fileURLWithPath: destPath).lastPathComponent
                let relativePath = "resources/\(type == "shot" ? "shots" : "plates")/\(id)/\(filename)"
                
                if type == "shot" {
                    // Add to shot's media
                    if let shot = filmManager.shots.first(where: { $0.id == id }) {
                        if imageExtensions.contains(fileExtension) {
                            shot.addImage(ImageFile(
                                filename: filename,
                                filepath: relativePath,
                                description: ""
                            ))
                        } else {
                            shot.addVideo(VideoFile(
                                filename: filename,
                                filepath: relativePath
                            ))
                        }
                        filmManager.fileManager.saveShot(shot)
                    }
                } else {
                    // Add to plate's media - would need to extend plate model
                    // For now, just save the reference
                    print("📎 Added media to plate \(id): \(relativePath)")
                    // TODO: Add media array to plate models and save
                }
                
                print("✅ Successfully added media: \(filename)")
            }
        } else {
            print("⚠️ Unsupported file type: \(fileExtension)")
        }
    }
}

// Extension to add media display
struct MediaGalleryView: View {
    let images: [ImageFile]
    let videos: [VideoFile]
    @Binding var selectedVideoIndex: Int?
    let onRemoveImage: (Int) -> Void
    let onRemoveVideo: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !images.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Images", systemImage: "photo.stack")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(images.indices, id: \.self) { index in
                                MediaThumbnail(
                                    path: images[index].filepath,
                                    isImage: true,
                                    onRemove: { onRemoveImage(index) }
                                )
                            }
                        }
                    }
                }
            }
            
            if !videos.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Videos", systemImage: "video.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(videos.indices, id: \.self) { index in
                                MediaThumbnail(
                                    path: videos[index].filepath,
                                    isImage: false,
                                    isSelected: selectedVideoIndex == index,
                                    onSelect: { selectedVideoIndex = index },
                                    onRemove: { onRemoveVideo(index) }
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

struct MediaThumbnail: View {
    let path: String
    let isImage: Bool
    var isSelected: Bool = false
    var onSelect: (() -> Void)? = nil
    let onRemove: () -> Void
    
    @State private var thumbnail: NSImage?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    Group {
                        if let image = thumbnail {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipped()
                                .cornerRadius(6)
                        } else {
                            Image(systemName: isImage ? "photo" : "video")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
                .onTapGesture {
                    onSelect?()
                }
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.red))
            }
            .buttonStyle(PlainButtonStyle())
            .offset(x: 4, y: -4)
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        // Try to load thumbnail from the actual file path
        let fullPath = "/Users/ingthor/Documents/stories/appdata/\(path)"
        if let image = NSImage(contentsOfFile: fullPath) {
            // Create thumbnail
            let size = NSSize(width: 160, height: 160)
            let thumbnail = NSImage(size: size)
            thumbnail.lockFocus()
            image.draw(in: NSRect(origin: .zero, size: size),
                      from: NSRect(origin: .zero, size: image.size),
                      operation: .copy,
                      fraction: 1.0)
            thumbnail.unlockFocus()
            self.thumbnail = thumbnail
        }
    }
}