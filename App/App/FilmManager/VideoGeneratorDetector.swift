import Foundation
import SwiftUI

enum VideoGenerator: String, CaseIterable {
    case veo = "Veo"
    case sora = "Sora"
    case luma = "Luma"
    case runway = "Runway"
    case pika = "Pika"
    case unknown = "Unknown"

    var color: Color {
        switch self {
        case .veo: return .blue
        case .sora: return .orange
        case .luma: return .green
        case .runway: return .purple
        case .pika: return .pink
        case .unknown: return .gray
        }
    }

    var icon: String {
        switch self {
        case .veo: return "v.circle.fill"
        case .sora: return "s.circle.fill"
        case .luma: return "l.circle.fill"
        case .runway: return "r.circle.fill"
        case .pika: return "p.circle.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}

class VideoGeneratorDetector {
    static func detectGenerator(from filename: String) -> VideoGenerator {
        let lowercased = filename.lowercased()

        // Veo patterns
        // Examples: Subject_massive_fin_202509142256_cnr3o.mp4, Subject_bastofabody_with_202509141845_6t.mp4
        if lowercased.contains("subject_") &&
           filename.range(of: #"_\d{12}_[a-z0-9]+\.mp4"#, options: .regularExpression) != nil {
            return .veo
        }

        // Sora patterns
        // Example: 20250919_2015_Raven's Mystical Journey_simple_compose_01k5jhw4n5e3t9q0ecm920vcd7.mp4
        if filename.range(of: #"^\d{8}_\d{4}_.*_[a-z0-9]{26}\.mp4"#, options: .regularExpression) != nil {
            return .sora
        }

        // Luma patterns
        // Example: 2025-09-20T03-06-25_ancient_raven_in.mp4
        if filename.range(of: #"^\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}_.*\.mp4"#, options: .regularExpression) != nil {
            return .luma
        }

        // Runway patterns (common format)
        if lowercased.contains("runway") ||
           filename.range(of: #"GEN-\d+"#, options: .regularExpression) != nil {
            return .runway
        }

        // Pika patterns
        if lowercased.contains("pika") {
            return .pika
        }

        return .unknown
    }
}