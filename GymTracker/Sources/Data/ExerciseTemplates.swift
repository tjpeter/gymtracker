import Foundation

// MARK: - Exercise Template

struct ExerciseTemplate {
    let name: String
    let machineName: String
    let defaultSets: Int
    let defaultReps: Int
    let defaultWeight: Double

    func toLoggedExercise(order: Int, previousWeight: Double? = nil, previousReps: Int? = nil) -> LoggedExercise {
        let exercise = LoggedExercise(
            name: name,
            order: order,
            machineName: machineName,
            previousWeight: previousWeight,
            previousReps: previousReps
        )
        let weight = previousWeight ?? defaultWeight
        let reps = previousReps ?? defaultReps
        for i in 1...defaultSets {
            let set = ExerciseSet(setNumber: i, reps: reps, weight: weight)
            exercise.sets.append(set)
        }
        return exercise
    }
}

// MARK: - Template Provider

struct TemplateProvider {

    /// Returns default templates for a gym name + workout type.
    /// Uses preset templates for known gyms, falls back to generic defaults.
    static func templates(for gymName: String, workoutType: WorkoutType) -> [ExerciseTemplate] {
        if let preset = GymPreset(rawValue: gymName) {
            switch (preset, workoutType) {
            case (.waedenswil, .a): return waedenswilWorkoutA
            case (.waedenswil, .b): return waedenswilWorkoutB
            case (.kreuzlingen, .a): return kreuzlingenWorkoutA
            case (.kreuzlingen, .b): return kreuzlingenWorkoutB
            }
        }
        switch workoutType {
        case .a: return defaultWorkoutA
        case .b: return defaultWorkoutB
        }
    }

    // MARK: - Wädenswil Workout A

    static let waedenswilWorkoutA: [ExerciseTemplate] = [
        ExerciseTemplate(name: "Flat DB Bench Press", machineName: "Dumbbells", defaultSets: 3, defaultReps: 10, defaultWeight: 20),
        ExerciseTemplate(name: "Chest-Supported Row", machineName: "Machine", defaultSets: 3, defaultReps: 10, defaultWeight: 30),
        ExerciseTemplate(name: "Leg Press", machineName: "Leg Press Machine", defaultSets: 3, defaultReps: 10, defaultWeight: 100),
        ExerciseTemplate(name: "Lying Leg Curl", machineName: "Leg Curl Machine", defaultSets: 3, defaultReps: 12, defaultWeight: 40),
        ExerciseTemplate(name: "Seated DB Overhead Press", machineName: "Dumbbells + Bench", defaultSets: 3, defaultReps: 12, defaultWeight: 14),
        ExerciseTemplate(name: "EZ-Bar Curl", machineName: "EZ-Bar", defaultSets: 3, defaultReps: 12, defaultWeight: 20),
        ExerciseTemplate(name: "Cable Fly", machineName: "Cable Station", defaultSets: 2, defaultReps: 15, defaultWeight: 10),
        ExerciseTemplate(name: "Face Pull", machineName: "Cable Rope", defaultSets: 2, defaultReps: 20, defaultWeight: 15),
        ExerciseTemplate(name: "Ab Wheel Rollout", machineName: "Ab Wheel / Plank", defaultSets: 2, defaultReps: 12, defaultWeight: 0),
    ]

    static let waedenswilWorkoutB: [ExerciseTemplate] = [
        ExerciseTemplate(name: "Lat Pulldown", machineName: "Neutral Grip", defaultSets: 3, defaultReps: 10, defaultWeight: 50),
        ExerciseTemplate(name: "Machine Shoulder Press", machineName: "Shoulder Press Machine", defaultSets: 3, defaultReps: 12, defaultWeight: 30),
        ExerciseTemplate(name: "DB Romanian Deadlift", machineName: "Dumbbells", defaultSets: 3, defaultReps: 12, defaultWeight: 20),
        ExerciseTemplate(name: "Leg Extension", machineName: "Leg Extension Machine", defaultSets: 3, defaultReps: 15, defaultWeight: 40),
        ExerciseTemplate(name: "Incline DB Press", machineName: "30° Incline Bench", defaultSets: 3, defaultReps: 12, defaultWeight: 16),
        ExerciseTemplate(name: "Seated Cable Row", machineName: "Cable Row Machine", defaultSets: 3, defaultReps: 12, defaultWeight: 40),
        ExerciseTemplate(name: "Tricep Pushdown", machineName: "Cable Rope", defaultSets: 2, defaultReps: 15, defaultWeight: 15),
        ExerciseTemplate(name: "Incline DB Curl", machineName: "Incline Bench + DBs", defaultSets: 2, defaultReps: 15, defaultWeight: 8),
        ExerciseTemplate(name: "Reverse Pec Deck", machineName: "Pec Deck (reverse)", defaultSets: 2, defaultReps: 20, defaultWeight: 20),
        ExerciseTemplate(name: "Pallof Press", machineName: "Cable Station", defaultSets: 2, defaultReps: 12, defaultWeight: 10),
    ]

    static let kreuzlingenWorkoutA: [ExerciseTemplate] = [
        ExerciseTemplate(name: "Flat DB Bench Press", machineName: "Dumbbells", defaultSets: 3, defaultReps: 10, defaultWeight: 18),
        ExerciseTemplate(name: "Chest-Supported Row", machineName: "Machine", defaultSets: 3, defaultReps: 10, defaultWeight: 25),
        ExerciseTemplate(name: "Leg Press", machineName: "Leg Press Machine", defaultSets: 3, defaultReps: 10, defaultWeight: 90),
        ExerciseTemplate(name: "Lying Leg Curl", machineName: "Leg Curl Machine", defaultSets: 3, defaultReps: 12, defaultWeight: 35),
        ExerciseTemplate(name: "Seated DB Overhead Press", machineName: "Dumbbells + Bench", defaultSets: 3, defaultReps: 12, defaultWeight: 12),
        ExerciseTemplate(name: "EZ-Bar Curl", machineName: "EZ-Bar", defaultSets: 3, defaultReps: 12, defaultWeight: 20),
        ExerciseTemplate(name: "Pec Deck", machineName: "Pec Deck Machine", defaultSets: 2, defaultReps: 15, defaultWeight: 25),
        ExerciseTemplate(name: "Face Pull", machineName: "Cable Rope", defaultSets: 2, defaultReps: 20, defaultWeight: 12),
        ExerciseTemplate(name: "Plank", machineName: "Bodyweight", defaultSets: 2, defaultReps: 40, defaultWeight: 0),
    ]

    static let kreuzlingenWorkoutB: [ExerciseTemplate] = [
        ExerciseTemplate(name: "Lat Pulldown", machineName: "Neutral Grip", defaultSets: 3, defaultReps: 10, defaultWeight: 45),
        ExerciseTemplate(name: "Machine Shoulder Press", machineName: "Shoulder Press Machine", defaultSets: 3, defaultReps: 12, defaultWeight: 25),
        ExerciseTemplate(name: "DB Romanian Deadlift", machineName: "Dumbbells", defaultSets: 3, defaultReps: 12, defaultWeight: 18),
        ExerciseTemplate(name: "Leg Extension", machineName: "Leg Extension Machine", defaultSets: 3, defaultReps: 15, defaultWeight: 25),
        ExerciseTemplate(name: "Incline DB Press", machineName: "30° Incline Bench", defaultSets: 3, defaultReps: 12, defaultWeight: 14),
        ExerciseTemplate(name: "Seated Cable Row", machineName: "Cable Row Machine", defaultSets: 3, defaultReps: 12, defaultWeight: 35),
        ExerciseTemplate(name: "Tricep Pushdown", machineName: "Cable Rope", defaultSets: 2, defaultReps: 15, defaultWeight: 12),
        ExerciseTemplate(name: "Incline DB Curl", machineName: "Incline Bench + DBs", defaultSets: 2, defaultReps: 15, defaultWeight: 7),
        ExerciseTemplate(name: "Reverse Pec Deck", machineName: "Pec Deck (reverse)", defaultSets: 2, defaultReps: 20, defaultWeight: 18),
        ExerciseTemplate(name: "Pallof Press", machineName: "Cable Station", defaultSets: 2, defaultReps: 12, defaultWeight: 8),
    ]

    static let defaultWorkoutA: [ExerciseTemplate] = [
        ExerciseTemplate(name: "Flat DB Bench Press", machineName: "Dumbbells", defaultSets: 3, defaultReps: 10, defaultWeight: 16),
        ExerciseTemplate(name: "Chest-Supported Row", machineName: "Machine / T-Bar", defaultSets: 3, defaultReps: 10, defaultWeight: 20),
        ExerciseTemplate(name: "Leg Press", machineName: "Leg Press", defaultSets: 3, defaultReps: 10, defaultWeight: 80),
        ExerciseTemplate(name: "Lying Leg Curl", machineName: "Leg Curl", defaultSets: 3, defaultReps: 12, defaultWeight: 30),
        ExerciseTemplate(name: "Seated DB Overhead Press", machineName: "Dumbbells", defaultSets: 3, defaultReps: 12, defaultWeight: 12),
        ExerciseTemplate(name: "EZ-Bar Curl", machineName: "EZ-Bar", defaultSets: 3, defaultReps: 12, defaultWeight: 15),
        ExerciseTemplate(name: "Cable Fly", machineName: "Cable / Pec Deck", defaultSets: 2, defaultReps: 15, defaultWeight: 8),
        ExerciseTemplate(name: "Face Pull", machineName: "Cable Rope", defaultSets: 2, defaultReps: 20, defaultWeight: 10),
        ExerciseTemplate(name: "Ab Wheel Rollout", machineName: "Ab Wheel / Plank", defaultSets: 2, defaultReps: 12, defaultWeight: 0),
    ]

    static let defaultWorkoutB: [ExerciseTemplate] = [
        ExerciseTemplate(name: "Lat Pulldown", machineName: "Neutral Grip", defaultSets: 3, defaultReps: 10, defaultWeight: 40),
        ExerciseTemplate(name: "Machine Shoulder Press", machineName: "Shoulder Press", defaultSets: 3, defaultReps: 12, defaultWeight: 20),
        ExerciseTemplate(name: "DB Romanian Deadlift", machineName: "Dumbbells", defaultSets: 3, defaultReps: 12, defaultWeight: 16),
        ExerciseTemplate(name: "Leg Extension", machineName: "Leg Extension", defaultSets: 3, defaultReps: 15, defaultWeight: 25),
        ExerciseTemplate(name: "Incline DB Press", machineName: "30° Incline", defaultSets: 3, defaultReps: 12, defaultWeight: 14),
        ExerciseTemplate(name: "Seated Cable Row", machineName: "Cable Row", defaultSets: 3, defaultReps: 12, defaultWeight: 30),
        ExerciseTemplate(name: "Tricep Pushdown", machineName: "Cable Rope", defaultSets: 2, defaultReps: 15, defaultWeight: 12),
        ExerciseTemplate(name: "Incline DB Curl", machineName: "Incline Bench + DBs", defaultSets: 2, defaultReps: 15, defaultWeight: 6),
        ExerciseTemplate(name: "Reverse Pec Deck", machineName: "Pec Deck (reverse)", defaultSets: 2, defaultReps: 20, defaultWeight: 15),
        ExerciseTemplate(name: "Pallof Press", machineName: "Cable Station", defaultSets: 2, defaultReps: 12, defaultWeight: 8),
    ]
}
