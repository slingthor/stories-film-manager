import SwiftUI

// MARK: - Plate Usage View
struct PlateUsageView: View {
    let plateId: String
    @ObservedObject var filmManager: FilmManager
    
    var shotsUsingPlate: [FilmShot] {
        filmManager.shots.filter { shot in
            shot.promptVariants.contains { variant in
                // Check if plate is in recommended or selected plates
                if let charPlates = variant.recommendedPlates["characters"] as? [String: String] {
                    if charPlates.values.contains(plateId) { return true }
                }
                if let envPlates = variant.recommendedPlates["environment"] as? [String: String] {
                    if envPlates.values.contains(plateId) { return true }
                }
                if let charPlates = variant.selectedPlates["characters"] as? [String: String] {
                    if charPlates.values.contains(plateId) { return true }
                }
                if let envPlates = variant.selectedPlates["environment"] as? [String: String] {
                    if envPlates.values.contains(plateId) { return true }
                }
                return false
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Used in \(shotsUsingPlate.count) shots", systemImage: "film.stack")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            if !shotsUsingPlate.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(shotsUsingPlate.sorted(by: { $0.id < $1.id }), id: \.id) { shot in
                            VStack(spacing: 4) {
                                Text(shot.id)
                                    .font(.system(.caption, design: .monospaced))
                                    .fontWeight(.medium)
                                
                                Text(shot.title)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
                .frame(height: 50)
            }
        }
    }
}