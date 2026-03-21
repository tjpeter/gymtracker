import Foundation
import SwiftData

@Model
final class CustomTemplate {
    var id: UUID
    var name: String
    var gymName: String
    var workoutTypeRaw: String
    var createdDate: Date

    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var exercises: [TemplateExercise]

    var workoutType: WorkoutType {
        get { WorkoutType(rawValue: workoutTypeRaw) ?? .a }
        set { workoutTypeRaw = newValue.rawValue }
    }

    var sortedExercises: [TemplateExercise] {
        exercises.sorted { $0.order < $1.order }
    }

    init(name: String, gymName: String, workoutType: WorkoutType) {
        self.id = UUID()
        self.name = name
        self.gymName = gymName
        self.workoutTypeRaw = workoutType.rawValue
        self.createdDate = Date()
        self.exercises = []
    }
}

@Model
final class TemplateExercise {
    var id: UUID
    var name: String
    var machineName: String
    var order: Int
    var sets: Int
    var reps: Int
    var weight: Double

    var template: CustomTemplate?

    init(name: String, machineName: String = "", order: Int, sets: Int, reps: Int, weight: Double) {
        self.id = UUID()
        self.name = name
        self.machineName = machineName
        self.order = order
        self.sets = sets
        self.reps = reps
        self.weight = weight
    }
}
