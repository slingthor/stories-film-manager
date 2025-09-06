import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var filmManager = FilmManager()
    @State private var draggedSystem: TrackingSystem?
    @State private var visibleSystemRange = 0..<5
    @State private var selectedPlateId: String? = nil
    @State private var selectedPlateType: PlateType = .character
    @State private var currentTab: Int = 0  // 0 = shots, 1 = plates
    
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
                    draggedSystem: draggedSystem,
                    selectedPlateId: $selectedPlateId,
                    selectedPlateType: $selectedPlateType
                )
                .frame(width: 400)
                .background(Color.green.opacity(0.05))
                .onChange(of: selectedPlateId) { _ in
                    // When a plate is selected, we're in plate mode
                    if selectedPlateId != nil {
                        currentTab = 1
                    }
                }
                
                Divider()
                
                // CENTER-RIGHT: Show either Prompt Editor or Plate Editor based on context
                if selectedPlateId != nil && currentTab == 1 {
                    // Show Plate Editor when a plate is selected
                    PlateDetailEditor(
                        plateId: selectedPlateId!,
                        plateType: selectedPlateType,
                        filmManager: filmManager
                    )
                    .frame(minWidth: 500)
                    .background(Color.purple.opacity(0.05))
                } else {
                    // Show Prompt Editor for shots
                    ComprehensivePromptEditor(
                        shot: filmManager.selectedShot,
                        filmManager: filmManager
                    )
                    .frame(minWidth: 500)
                    .background(Color.purple.opacity(0.05))
                }
                
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