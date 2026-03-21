import Foundation
import SwiftData

@Model
final class LoggedExercise {
    var id: UUID
    var name: String
    var order: Int
    var machineName: String
    var notes: String
    var supersetGroupId: UUID?

    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.exercise)
    var sets: [ExerciseSet]

    var session: WorkoutSession?

    // Previous session reference values (for display only)
    var previousWeight: Double?
    var previousReps: Int?

    var sortedSets: [ExerciseSet] {
        sets.sorted { $0.setNumber < $1.setNumber }
    }

    init(
        name: String,
        order: Int,
        machineName: String = "",
        notes: String = "",
        previousWeight: Double? = nil,
        previousReps: Int? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.order = order
        self.machineName = machineName
        self.notes = notes
        self.sets = []
        self.previousWeight = previousWeight
        self.previousReps = previousReps
    }

    func addSet(reps: Int, weight: Double) {
        let setNumber = sets.count + 1
        let newSet = ExerciseSet(setNumber: setNumber, reps: reps, weight: weight)
        sets.append(newSet)
    }
}
