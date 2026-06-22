import Foundation
import SwiftData

/// A quick bug report or feature idea captured in-app (e.g. mid-workout) so it
/// isn't forgotten before the next development pass. Local-only, like everything else.
@Model
final class FeedbackItem {
    var id: UUID
    var createdDate: Date
    /// Stored as a raw string for SwiftData; see `kind`.
    var kindRaw: String
    var text: String
    var isResolved: Bool

    var kind: FeedbackKind {
        get { FeedbackKind(rawValue: kindRaw) ?? .bug }
        set { kindRaw = newValue.rawValue }
    }

    init(kind: FeedbackKind, text: String, createdDate: Date = Date(), isResolved: Bool = false) {
        self.id = UUID()
        self.createdDate = createdDate
        self.kindRaw = kind.rawValue
        self.text = text
        self.isResolved = isResolved
    }
}

enum FeedbackKind: String, CaseIterable, Identifiable {
    case bug = "Bug"
    case idea = "Idea"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .bug: return "ladybug.fill"
        case .idea: return "lightbulb.fill"
        }
    }
}
