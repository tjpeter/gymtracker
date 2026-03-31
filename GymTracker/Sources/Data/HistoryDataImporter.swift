import Foundation
import SwiftData

/// Imports historical workout data as seed data for the app.
/// Provides sample sessions across multiple gyms and workout types.
struct HistoryDataImporter {

    static func importIfNeeded(context: ModelContext) {
        // Only import once — check if any completed sessions exist
        let sessionDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true }
        )
        if let count = try? context.fetchCount(sessionDescriptor), count == 0 {
            let sessions = buildHistoricalSessions()
            for session in sessions {
                context.insert(session)
            }
        }

        // Seed body weight entries if none exist
        let bwDescriptor = FetchDescriptor<BodyWeightEntry>()
        if let count = try? context.fetchCount(bwDescriptor), count == 0 {
            let entries = buildSeedBodyWeightEntries()
            for entry in entries {
                context.insert(entry)
            }
        }

        try? context.save()
    }

    // MARK: - Build Sessions

    private static func buildHistoricalSessions() -> [WorkoutSession] {
        var sessions: [WorkoutSession] = []

        // Session 1: Thu 14.2.2026 - Kreuzlingen - Workout A
        sessions.append(buildSession(
            date: makeDate(day: 14, month: 2, year: 2026),
            gymName: "Kreuzlingen",
            workoutType: .a,
            exercises: [
                ("Leg Press", "Leg Press Machine", [(8, 100.0), (8, 100.0), (8, 100.0)]),
                ("Lying Leg Curl", "Leg Curl Machine", [(8, 40.0), (8, 40.0), (8, 40.0)]),
                ("Flat DB Bench Press", "Dumbbells", [(10, 10.0), (10, 10.0), (10, 10.0)]),
                ("DB Single-Arm Row", "Dumbbells", [(10, 8.0), (6, 8.0), (10, 8.0)]),
                ("Seated DB Overhead Press", "Dumbbells", [(6, 6.0), (6, 6.0)]),
                ("Machine Chest Press", "Chest Press Machine", [(12, 25.0)]),
                ("Face Pull", "Cable Rope", [(12, 10.0), (12, 10.0)]),
                ("Plank", "Bodyweight", [(30, 0.0), (30, 0.0)]),
            ]
        ))

        // Session 2: Mon 16.2.2026 - Wädenswil - Workout A
        sessions.append(buildSession(
            date: makeDate(day: 16, month: 2, year: 2026),
            gymName: "Wädenswil",
            workoutType: .a,
            exercises: [
                ("Flat DB Bench Press", "Dumbbells", [(10, 18.0), (8, 18.0), (8, 18.0)]),
                ("Chest-Supported Row", "Machine", [(10, 18.0), (10, 18.0), (10, 18.0)]),
                ("Leg Press", "Leg Press Machine", [(10, 80.0), (10, 80.0), (10, 80.0)]),
                ("Lying Leg Curl", "Leg Curl Machine", [(8, 30.0), (8, 30.0), (8, 30.0)]),
                ("Standing OH Press", "Dumbbells", [(8, 10.0), (8, 10.0)]),
                ("BB Curls", "Barbell", [(8, 0.0), (8, 0.0), (5, 0.0)]),
                ("Machine Chest Press", "Machine", [(10, 20.0), (10, 20.0)]),
                ("Face Pull", "Cable Rope", [(12, 25.0), (12, 25.0)]),
                ("Plank", "Bodyweight", [(20, 0.0), (20, 0.0)]),
            ]
        ))

        // Session 3: Tue 18.2.2026 - Kreuzlingen (XLingen) - Workout B
        sessions.append(buildSession(
            date: makeDate(day: 18, month: 2, year: 2026),
            gymName: "Kreuzlingen",
            workoutType: .b,
            exercises: [
                ("Lat Pulldown", "Neutral Grip", [(10, 35.0), (8, 35.0), (5, 35.0)]),
                ("Seated DB Shoulder Press", "Dumbbells", [(8, 8.0), (8, 8.0), (5, 8.0)]),
                ("Leg Extension", "Leg Extension Machine", [(12, 41.0), (12, 41.0), (12, 41.0)]),
                ("DB Romanian Deadlift", "Dumbbells", [(6, 20.0), (6, 20.0), (7, 20.0)]),
                ("Smith Machine Press", "Smith Machine", [(10, 0.0), (10, 0.0), (10, 0.0)]),
                ("Seated Cable Row", "Cable Row Machine", [(10, 5.0), (10, 5.0)]),
                ("Tricep Pushdown", "Cable Rope", [(15, 10.0), (12, 10.0)]),
                ("Incline DB Curl", "Incline Bench + DBs", [(12, 3.0)]),
                ("Reverse Fly Machine", "Machine", [(12, 9.0), (12, 9.0)]),
                ("Pallof Press", "Cable Station", [(13, 9.0), (12, 9.0)]),
            ]
        ))

        // Session 4: Mon 23.2.2026 - Wädenswil - Workout B (from text file)
        sessions.append(buildSession(
            date: makeDate(day: 23, month: 2, year: 2026),
            gymName: "Wädenswil",
            workoutType: .b,
            exercises: [
                ("DB Romanian Deadlift", "Dumbbells", [(8, 10.0), (10, 10.0), (10, 10.0)]),
                ("Leg Extension", "Leg Extension Machine", [(10, 35.0), (12, 35.0), (12, 35.0)]),
                ("Lat Pulldown", "Neutral Grip", [(10, 35.0), (12, 35.0), (12, 35.0)]),
                ("Machine Chest Press", "Machine", [(10, 35.0), (12, 35.0), (12, 35.0)]),
                ("Incline DB Press", "30° Incline Bench", [(10, 10.0), (10, 10.0)]),
                ("Seated Cable Row", "Cable Row Machine", [(12, 20.0), (12, 25.0), (12, 30.0)]),
                ("Tricep Pushdown", "Cable Rope", [(15, 7.5), (15, 10.0)]),
                ("Incline DB Curl", "Incline Bench + DBs", [(12, 8.0), (12, 8.0)]),
                ("Band Pull-Apart", "Resistance Band", [(20, 0.0), (20, 0.0)]),
            ]
        ))

        // Session 5: Tue 24.2.2026 - Kreuzlingen - Workout A
        sessions.append(buildSession(
            date: makeDate(day: 24, month: 2, year: 2026),
            gymName: "Kreuzlingen",
            workoutType: .a,
            exercises: [
                ("Leg Press", "Leg Press Machine", [(5, 80.0), (8, 70.0), (8, 70.0), (8, 70.0)]),
                ("Lying Leg Curl", "Leg Curl Machine", [(10, 40.0), (10, 40.0), (10, 40.0)]),
                ("Flat DB Bench Press", "Dumbbells", [(10, 10.0), (10, 10.0)]),
                ("Chest-Supported Row", "Machine", [(10, 20.0), (10, 20.0)]),
            ]
        ))

        // Session 6: Sat 28.2.2026 - Davos - Workout B
        sessions.append(buildSession(
            date: makeDate(day: 28, month: 2, year: 2026),
            gymName: "Davos",
            workoutType: .b,
            exercises: [
                ("Leg Extension", "Leg Extension Machine", [(13, 50.0), (13, 50.0), (13, 50.0)]),
                ("Back Extension", "Fixed Machine", [(10, 100.0), (10, 100.0)]),
                ("Lat Pulldown", "Lat Pulldown Machine", [(10, 90.0), (10, 90.0), (10, 90.0)]),
                ("Machine Shoulder Press", "Shoulder Press Machine", [(12, 20.0), (12, 20.0), (12, 20.0), (12, 20.0)]),
                ("Seated Cable Row", "Cable Row Machine", [(10, 20.0), (12, 10.0), (12, 10.0)]),
                ("DB Bench Press 30°", "30° Incline Bench", [(10, 10.0), (10, 12.0)]),
                ("Incline DB Curl", "Incline Bench + DBs", [(12, 8.0), (12, 8.0)]),
                ("Tricep Pushdown", "Cable Rope", [(15, 10.0), (14, 12.0)]),
                ("Reverse Pec Deck", "Pec Deck (reverse)", [(15, 12.5)]),
                ("Pallof Press", "Cable Station", [(10, 5.0), (10, 5.0)]),
                ("Band Face Pull", "Resistance Band", [(10, 0.0), (10, 0.0)]),
            ]
        ))

        // Session 7: Mon 2.3.2026 - Wädenswil - Workout A
        sessions.append(buildSession(
            date: makeDate(day: 2, month: 3, year: 2026),
            gymName: "Wädenswil",
            workoutType: .a,
            exercises: [
                ("Leg Press", "Leg Press Machine", [(10, 100.0), (10, 100.0), (10, 100.0)]),
                ("Leg Curl", "Leg Curl Machine", [(10, 65.0), (10, 60.0), (10, 60.0)]),
                ("Flat DB Bench Press", "Dumbbells", [(10, 20.0), (10, 20.0), (10, 20.0)]),
                ("Single-Arm DB Row", "Dumbbells", [(10, 16.0), (10, 18.0), (10, 18.0)]),
                ("Machine Chest Press", "Chest Press Machine", [(12, 30.0), (12, 30.0)]),
                ("Face Pull", "Cable Rope", [(10, 25.0), (8, 25.0)]),
                ("Seated DB Overhead Press", "Dumbbells", [(8, 10.0), (8, 10.0), (8, 10.0)]),
                ("BB Curls", "Barbell", [(10, 10.0), (10, 10.0)]),
            ]
        ))

        // Session 8: Fri 6.3.2026 - Kreuzlingen - Workout B (short session)
        sessions.append(buildSession(
            date: makeDate(day: 6, month: 3, year: 2026, hour: 10),
            gymName: "Kreuzlingen",
            workoutType: .b,
            notes: "Short session",
            exercises: [
                ("Lat Pulldown", "Neutral Grip", [(10, 25.0), (10, 25.0), (10, 25.0)]),
                ("Machine Shoulder Press", "Shoulder Press Machine", [(8, 15.0), (8, 15.0)]),
                ("Tricep Pushdown", "Cable Rope", [(10, 8.0), (15, 8.0)]),
                ("Pallof Press", "Cable Station", [(8, 4.0), (12, 4.0)]),
                ("Incline DB Curl", "Incline Bench + DBs", [(12, 5.0), (8, 5.0)]),
            ]
        ))

        // Session 9: Fri 6.3.2026 - Kreuzlingen - Workout A (later same day)
        sessions.append(buildSession(
            date: makeDate(day: 6, month: 3, year: 2026, hour: 17),
            gymName: "Kreuzlingen",
            workoutType: .a,
            exercises: [
                ("Flat DB Bench Press", "Dumbbells", [(10, 10.0), (10, 20.0), (10, 20.0)]),
                ("Chest-Supported Row", "Machine", [(10, 25.0), (10, 25.0)]),
                ("DB Single-Arm Row", "Dumbbells", [(10, 25.0), (10, 25.0)]),
                ("Leg Press", "Leg Press Machine", [(10, 80.0), (10, 80.0), (10, 80.0)]),
                ("Lying Leg Curl", "Leg Curl Machine", [(10, 40.0), (10, 40.0), (8, 40.0)]),
                ("Shoulder Press", "Machine", [(8, 15.0), (13, 15.0), (5, 15.0)]),
                ("Plank", "Bodyweight", [(40, 0.0), (30, 0.0)]),
                ("BB Curls", "Barbell", [(14, 0.0), (12, 0.0)]),
            ]
        ))

        return sessions
    }

    // MARK: - Seed Body Weight

    private static func buildSeedBodyWeightEntries() -> [BodyWeightEntry] {
        // Realistic body weight entries spanning the same date range as seed workouts
        let data: [(day: Int, month: Int, weight: Double)] = [
            (14, 2, 78.5),
            (17, 2, 78.3),
            (20, 2, 78.6),
            (23, 2, 78.2),
            (26, 2, 78.0),
            (1, 3, 77.8),
            (4, 3, 77.9),
            (7, 3, 77.5),
        ]
        return data.map { item in
            BodyWeightEntry(
                date: makeDate(day: item.day, month: item.month, year: 2026, hour: 7),
                weight: item.weight
            )
        }
    }

    // MARK: - Helpers

    private static func buildSession(
        date: Date,
        gymName: String,
        workoutType: WorkoutType,
        notes: String = "",
        exercises: [(name: String, machine: String, sets: [(reps: Int, weight: Double)])]
    ) -> WorkoutSession {
        let session = WorkoutSession(
            gymName: gymName,
            workoutType: workoutType,
            date: date,
            notes: notes,
            isCompleted: true
        )
        for (index, ex) in exercises.enumerated() {
            let exercise = LoggedExercise(name: ex.name, order: index, machineName: ex.machine)
            for (setIndex, setData) in ex.sets.enumerated() {
                let set = ExerciseSet(
                    setNumber: setIndex + 1,
                    reps: setData.reps,
                    weight: setData.weight,
                    isCompleted: true
                )
                exercise.sets.append(set)
            }
            exercise.session = session
            session.exercises.append(exercise)
        }
        return session
    }

    private static func makeDate(day: Int, month: Int, year: Int, hour: Int = 9) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}
