import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID
    var date: Date
    var gymName: String
    var workoutTypeRaw: String
    var notes: String
    var isCompleted: Bool
    var endDate: Date?
    var rating: Int?

    @Relationship(deleteRule: .cascade, inverse: \LoggedExercise.session)
    var exercises: [LoggedExercise]

    var workoutType: WorkoutType {
        get { WorkoutType(rawValue: workoutTypeRaw) ?? .a }
        set { workoutTypeRaw = newValue.rawValue }
    }

    var durationMinutes: Int? {
        guard let end = endDate else { return nil }
        return max(1, Int(end.timeIntervalSince(date) / 60))
    }

    var sortedExercises: [LoggedExercise] {
        exercises.sorted { $0.order < $1.order }
    }

    init(gymName: String, workoutType: WorkoutType, date: Date = Date(), notes: String = "", isCompleted: Bool = false, endDate: Date? = nil) {
        self.id = UUID()
        self.date = date
        self.gymName = gymName
        self.workoutTypeRaw = workoutType.rawValue
        self.notes = notes
        self.isCompleted = isCompleted
        self.endDate = endDate
        self.exercises = []
    }
}
