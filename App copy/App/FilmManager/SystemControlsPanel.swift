import SwiftUI
import Combine

struct SystemControlsPanel: View {
    @ObservedObject var filmManager: FilmManager
    @Binding var draggedSystem: TrackingSystem?
    @State private var visibleRange = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack {
                Text("TRACKING SYSTEMS")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Button("◀") {
                        visibleRange = max(0, visibleRange - 5)
                    }
                    .disabled(visibleRange == 0)
                    
                    Text("\(visibleRange + 1)-\(min(visibleRange + 5, filmManager.trackingSystems.count)) of \(filmManager.trackingSystems.count)")
                        .font(.caption)
                    
                    Button("▶") {
                        visibleRange = min(filmManager.trackingSystems.count - 5, visibleRange + 5)
                    }
                    .disabled(visibleRange + 5 >= filmManager.trackingSystems.count)
                }
                
                Text("Drag systems → shots")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Divider()
            
            // System list with enhanced controls
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(filmManager.trackingSystems) { system in
                        EnhancedSystemControl(
                            system: system,
                            shots: filmManager.shots,
                            onDragStart: { 
                                draggedSystem = system
                                system.isBeingDragged = true
                            },
                            onDragEnd: {
                                draggedSystem = nil
                                system.isBeingDragged = false
                            }
                        )
                        .padding(.horizontal, 8)
                    }
                }
            }
        }
    }
}

struct EnhancedSystemControl: View {
    @ObservedObject var system: TrackingSystem
    let shots: [FilmShot]
    let onDragStart: () -> Void
    let onDragEnd: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // System header with drag handle and current shot info
            HStack {
                Image(systemName: "line.horizontal.3")
                    .foregroundColor(.gray)
                    .font(.caption)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(system.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text(currentShotInfo)
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(system.currentPercentage))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("film pos")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // System description
            Text(system.description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Slider with shot position indicators
            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { system.currentPercentage },
                        set: { system.currentPercentage = $0 }
                    ),
                    in: system.continuousRange,
                    step: 1.0
                )
                .accentColor(.blue)
                
                // Mini timeline showing where system is positioned
                HStack(spacing: 1) {
                    ForEach(shots.prefix(20), id: \.id) { shot in
                        Rectangle()
                            .fill(isSystemNearShot(shot) ? .blue : .gray.opacity(0.3))
                            .frame(width: max(2, 240.0 / Double(shots.count)), height: 4)
                            .cornerRadius(1)
                    }
                }
            }
            
            // Current milestone description
            Text(system.getMilestoneDescription(at: system.currentPercentage))
                .font(.caption2)
                .foregroundColor(.primary)
                .lineLimit(2)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(system.isBeingDragged ? Color.blue.opacity(0.1) : Color.white)
                .shadow(radius: system.isBeingDragged ? 3 : 1)
        )
        .onDrag {
            onDragStart()
            return NSItemProvider(object: system.name as NSString)
        }
    }
    
    private var currentShotInfo: String {
        if let nearestShot = shots.min(by: { abs($0.position - system.currentPercentage) < abs($1.position - system.currentPercentage) }) {
            let distance = abs(nearestShot.position - system.currentPercentage)
            if distance < 3.0 {
                return "At \(nearestShot.id): \(String(nearestShot.title.prefix(25)))..."
            } else {
                return "Near \(nearestShot.id) (\(String(format: "%.1f", distance))% away)"
            }
        }
        return "Position \(Int(system.currentPercentage))%"
    }
    
    private func isSystemNearShot(_ shot: FilmShot) -> Bool {
        abs(shot.position - system.currentPercentage) < 3.0
    }
}

#Preview {
    SystemControlsPanel(
        filmManager: FilmManager(),
        draggedSystem: .constant(nil)
    )
}