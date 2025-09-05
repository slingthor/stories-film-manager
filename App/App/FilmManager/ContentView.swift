import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var filmManager = FilmManager()
    @State private var draggedSystem: TrackingSystem?
    @State private var visibleSystemRange = 0..<5
    
    var body: some View {
        VStack(spacing: 0) {
            // TOP: Horizontal System Overview Bar
            HStack {
                Text("THE SHEEP IN THE BAÐSTOFA - Production Manager")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Quick system overview (first 5 systems)
                ForEach(Array(filmManager.trackingSystems[visibleSystemRange]), id: \.id) { system in
                    VStack {
                        Text(system.name.replacingOccurrences(of: "_", with: " "))
                            .font(.caption)
                            .lineLimit(1)
                        Text("\(Int(system.currentPercentage))%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .frame(width: 80)
                }
                
                Button("Save All") {
                    filmManager.saveAllChanges()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            HStack(spacing: 0) {
                // LEFT: System Controls
                SystemControlsPanel(
                    filmManager: filmManager,
                    draggedSystem: $draggedSystem
                )
                .frame(width: 280)
                .background(Color.blue.opacity(0.05))
                
                Divider()
                
                // CENTER-LEFT: Tabbed view for Shots/Plates
                TabbedManagementView(
                    filmManager: filmManager,
                    draggedSystem: draggedSystem
                )
                .frame(width: 400)
                .background(Color.green.opacity(0.05))
                
                Divider()
                
                // CENTER-RIGHT: Complete Prompt Editor
                ComprehensivePromptEditor(
                    shot: filmManager.selectedShot,
                    filmManager: filmManager
                )
                .frame(minWidth: 500)
                .background(Color.purple.opacity(0.05))
                
                Divider()
                
                // RIGHT: Media Management Panel
                MediaManagementPanel(
                    shot: filmManager.selectedShot,
                    filmManager: filmManager
                )
                .frame(width: 320)
                .background(Color.orange.opacity(0.05))
            }
            
            Divider()
            
            // BOTTOM: Enhanced Timeline with Selected Videos
            ComprehensiveTimelineView(
                filmManager: filmManager
            )
            .frame(height: 120)
            .background(Color.yellow.opacity(0.1))
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveAll)) { _ in
            filmManager.saveAllChanges()
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 1400, height: 800)
}