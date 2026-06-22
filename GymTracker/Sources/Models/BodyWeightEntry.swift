import Foundation
import SwiftData

@Model
final class BodyWeightEntry {
    var id: UUID
    var date: Date
    var weight: Double
    /// Waist circumference in cm. Optional for backward compatibility with
    /// entries logged before waist tracking existed.
    var waist: Double?
    var notes: String

    init(date: Date = Date(), weight: Double, waist: Double? = nil, notes: String = "") {
        self.id = UUID()
        self.date = date
        self.weight = weight
        self.waist = waist
        self.notes = notes
    }
}
