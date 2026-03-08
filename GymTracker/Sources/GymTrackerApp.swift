import SwiftUI
import SwiftData

@main
struct GymTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [
            WorkoutSession.self,
            LoggedExercise.self,
            ExerciseSet.self,
            BodyWeightEntry.self
        ])
    }
}
