import SwiftUI
import Combine
import UniformTypeIdentifiers

struct ShotListWithSystemsView: View {
    @ObservedObject var filmManager: FilmManager
    let draggedSystem: TrackingSystem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with shot reordering controls
            VStack {
                HStack {
                    Text("SHOTS WITH SYSTEM MAPPING")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if let shot = filmManager.selectedShot {
                        Text("Selected: \(shot.id)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                if let shot = filmManager.selectedShot {
                    HStack {
                        Button("Move Up ↑") {
                            filmManager.moveShotUp(shot)
                        }
                        .disabled(isFirstShot(shot))
                        .buttonStyle(.bordered)
                        .font(.caption)
                        
                        Button("Move Down ↓") {
                            filmManager.moveShotDown(shot)
                        }
                        .disabled(isLastShot(shot))
                        .buttonStyle(.bordered)
                        .font(.caption)
                        
                        Button(action: {
                            filmManager.deleteShot(shot)
                        }) {
                            Label("Delete", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                        
                        Button("Copy") {
                            filmManager.copyShotAfterCurrent()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                        
                        Spacer()
                        
                        Text("Position: \(Int(shot.position))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            
            Divider()
            
            // Shot list with enhanced system mapping
            List {
                ForEach(filmManager.shots, id: \.id) { shot in
                    EnhancedShotRow(
                        shot: shot,
                        isSelected: filmManager.selectedShot?.id == shot.id,
                        trackingSystems: filmManager.trackingSystems,
                        draggedSystem: draggedSystem,
                        onSelect: {
                            filmManager.selectedShot = shot
                        },
                        onSystemDrop: { system in
                            filmManager.placeSystemAtShot(system, shot)
                        }
                    )
                }
                .onMove { source, destination in
                    filmManager.reorderShots(from: source, to: destination)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private func isFirstShot(_ shot: FilmShot) -> Bool {
        filmManager.shots.first?.id == shot.id
    }
    
    private func isLastShot(_ shot: FilmShot) -> Bool {
        filmManager.shots.last?.id == shot.id
    }
}

struct EnhancedShotRow: View {
    @ObservedObject var shot: FilmShot
    let isSelected: Bool
    let trackingSystems: [TrackingSystem]
    let draggedSystem: TrackingSystem?
    let onSelect: () -> Void
    let onSystemDrop: (TrackingSystem) -> Void
    @State private var isDropTarget = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Shot information (left side)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(shot.id)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(sequenceColor)
                    
                    Spacer()
                    
                    Text("\(Int(shot.position))%")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                Text(shot.title)
                    .font(.caption2)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                // Shot metadata row
                HStack(spacing: 4) {
                    Text(shot.aspectRatio)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(3)
                    
                    Text("\(shot.duration)s")
                        .font(.caption2)
                        .padding(.horizontal, 3)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(2)
                    
                    if !shot.videos.isEmpty {
                        Text("\(shot.videos.count)📹")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    
                    if !shot.images.isEmpty {
                        Text("\(shot.images.count)🖼")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    
                    if shot.selectedVideo != nil {
                        Text("▶")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .fontWeight(.bold)
                    }
                    
                    if shot.isDirty {
                        Text("●")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
            .frame(width: 180)
            
            Divider()
                .frame(height: 40)
            
            // System indicators and drop zone (right side)
            HStack(spacing: 3) {
                // Show systems affecting this shot
                ForEach(systemsAffectingShot.prefix(4), id: \.id) { system in
                    VStack(spacing: 1) {
                        Text(String(system.name.prefix(6)))
                            .font(.caption2)
                            .fontWeight(.medium)
                        Text("\(Int(system.currentPercentage))%")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 3)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.blue.opacity(0.3))
                    )
                    .foregroundColor(.primary)
                }
                
                // Drop zone for dragged systems
                if let draggedSystem = draggedSystem, !systemsAffectingShot.contains(where: { $0.id == draggedSystem.id }) {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(
                            isDropTarget ? Color.blue : Color.gray.opacity(0.5),
                            style: StrokeStyle(lineWidth: isDropTarget ? 2 : 1, dash: [4])
                        )
                        .frame(width: 80, height: 28)
                        .overlay(
                            VStack {
                                Text("Drop")
                                    .font(.caption2)
                                Text(String(draggedSystem.name.prefix(8)))
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(isDropTarget ? .blue : .gray)
                        )
                        .onDrop(of: [.text], isTargeted: $isDropTarget) { providers in
                            onSystemDrop(draggedSystem)
                            return true
                        }
                }
                
                if systemsAffectingShot.count > 4 {
                    Text("+\(systemsAffectingShot.count - 4)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.blue.opacity(0.15) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
    
    private var sequenceColor: Color {
        switch shot.sequenceType {
        case "prologue":
            return .green
        case "main_story":
            return .blue
        default:
            return .gray
        }
    }
    
    private var systemsAffectingShot: [TrackingSystem] {
        trackingSystems.filter { system in
            abs(system.currentPercentage - shot.position) < 8.0
        }
    }
}

#Preview {
    ShotListWithSystemsView(
        filmManager: FilmManager(),
        draggedSystem: nil
    )
}