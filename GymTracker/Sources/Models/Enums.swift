import Foundation
import SwiftUI

// MARK: - Gym Presets

/// Known gym locations. The actual gym name is stored as a String on WorkoutSession
/// to support custom gym names (e.g. "Davos"). These presets provide quick selection.
enum GymPreset: String, CaseIterable, Identifiable {
    case waedenswil = "Wädenswil"
    case kreuzlingen = "Kreuzlingen"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .waedenswil: return "building.2.fill"
        case .kreuzlingen: return "building.fill"
        }
    }
}

// MARK: - Workout Type

enum WorkoutType: String, Codable, CaseIterable, Identifiable {
    case a = "A"
    case b = "B"

    var id: String { rawValue }

    var displayName: String {
        "Workout \(rawValue)"
    }

    var subtitle: String {
        switch self {
        case .a: return "Horizontal Push/Pull + Quads"
        case .b: return "Vertical Push/Pull + Posterior Chain"
        }
    }

    var color: Color {
        switch self {
        case .a: return .blue
        case .b: return .teal
        }
    }
}
