import Foundation
import SwiftData

@Model
final class ExerciseSet {
    var id: UUID
    var setNumber: Int
    var reps: Int
    var weight: Double
    var isCompleted: Bool

    var exercise: LoggedExercise?

    init(setNumber: Int, reps: Int = 0, weight: Double = 0, isCompleted: Bool = false) {
        self.id = UUID()
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.isCompleted = isCompleted
    }
}
