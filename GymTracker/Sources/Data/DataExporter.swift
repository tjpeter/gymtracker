import Foundation
import SwiftData

struct DataExporter {

    // MARK: - CSV Export

    static func exportCSV(sessions: [WorkoutSession], bodyWeightEntries: [BodyWeightEntry]) -> String {
        var csv = ""

        // Workout data
        csv += "WORKOUTS\n"
        csv += "Date,Time,Gym,Workout Type,Exercise,Set,Reps,Weight (kg),Exercise Notes,Session Notes\n"

        let sortedSessions = sessions.sorted { $0.date < $1.date }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        for session in sortedSessions {
            let dateStr = dateFormatter.string(from: session.date)
            let timeStr = timeFormatter.string(from: session.date)
            let gymStr = escapeCSV(session.gymName)
            let workoutStr = session.workoutType.displayName
            let sessionNotes = escapeCSV(session.notes)

            for exercise in session.sortedExercises {
                let exerciseNotes = escapeCSV(exercise.notes)
                for set in exercise.sortedSets {
                    let weightStr = set.weight.formattedWeight
                    csv += "\(dateStr),\(timeStr),\(gymStr),\(workoutStr),\(escapeCSV(exercise.name)),\(set.setNumber),\(set.reps),\(weightStr),\(exerciseNotes),\(sessionNotes)\n"
                }
            }
        }

        // Body weight data
        if !bodyWeightEntries.isEmpty {
            csv += "\nBODY WEIGHT\n"
            csv += "Date,Weight (kg),Notes\n"
            let sortedEntries = bodyWeightEntries.sorted { $0.date < $1.date }
            for entry in sortedEntries {
                let dateStr = dateFormatter.string(from: entry.date)
                csv += "\(dateStr),\(entry.weight.formattedWeight),\(escapeCSV(entry.notes))\n"
            }
        }

        return csv
    }

    // MARK: - JSON Export

    static func exportJSON(sessions: [WorkoutSession], bodyWeightEntries: [BodyWeightEntry]) -> String {
        let sortedSessions = sessions.sorted { $0.date < $1.date }
        let dateFormatter = ISO8601DateFormatter()

        var workouts: [[String: Any]] = []
        for session in sortedSessions {
            var exercises: [[String: Any]] = []
            for exercise in session.sortedExercises {
                var sets: [[String: Any]] = []
                for set in exercise.sortedSets {
                    var setDict: [String: Any] = [
                        "set_number": set.setNumber,
                        "reps": set.reps,
                        "weight_kg": set.weight,
                        "is_completed": set.isCompleted,
                        "is_warmup": set.isWarmup,
                    ]
                    if let rpe = set.rpe {
                        setDict["rpe"] = rpe
                    }
                    sets.append(setDict)
                }
                var exerciseDict: [String: Any] = [
                    "name": exercise.name,
                    "order": exercise.order,
                    "sets": sets,
                ]
                if !exercise.machineName.isEmpty {
                    exerciseDict["machine"] = exercise.machineName
                }
                if !exercise.notes.isEmpty {
                    exerciseDict["notes"] = exercise.notes
                }
                exercises.append(exerciseDict)
            }

            var sessionDict: [String: Any] = [
                "date": dateFormatter.string(from: session.date),
                "gym": session.gymName,
                "workout_type": session.workoutTypeRaw,
                "exercises": exercises,
            ]
            if !session.notes.isEmpty {
                sessionDict["notes"] = session.notes
            }
            workouts.append(sessionDict)
        }

        var bodyWeights: [[String: Any]] = []
        let sortedEntries = bodyWeightEntries.sorted { $0.date < $1.date }
        for entry in sortedEntries {
            var entryDict: [String: Any] = [
                "date": dateFormatter.string(from: entry.date),
                "weight_kg": entry.weight,
            ]
            if !entry.notes.isEmpty {
                entryDict["notes"] = entry.notes
            }
            bodyWeights.append(entryDict)
        }

        let root: [String: Any] = [
            "exported_at": dateFormatter.string(from: Date()),
            "workouts": workouts,
            "body_weight": bodyWeights,
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys]) else {
            return "{}"
        }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    // MARK: - File Creation

    static func createCSVFile(sessions: [WorkoutSession], bodyWeightEntries: [BodyWeightEntry]) -> URL? {
        let csv = exportCSV(sessions: sessions, bodyWeightEntries: bodyWeightEntries)
        let fileName = "GymTracker_Export_\(dateStamp()).csv"
        return writeToTemp(content: csv, fileName: fileName)
    }

    static func createJSONFile(sessions: [WorkoutSession], bodyWeightEntries: [BodyWeightEntry]) -> URL? {
        let json = exportJSON(sessions: sessions, bodyWeightEntries: bodyWeightEntries)
        let fileName = "GymTracker_Export_\(dateStamp()).json"
        return writeToTemp(content: json, fileName: fileName)
    }

    // MARK: - JSON Import

    struct ImportResult {
        var sessionsImported: Int = 0
        var bodyWeightImported: Int = 0
        var sessionsSkipped: Int = 0
        var bodyWeightSkipped: Int = 0
    }

    static func importJSON(from data: Data, context: ModelContext) throws -> ImportResult {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ImportError.invalidFormat
        }

        var result = ImportResult()
        let dateFormatter = ISO8601DateFormatter()

        // Fetch existing sessions for duplicate detection
        let existingSessions = (try? context.fetch(FetchDescriptor<WorkoutSession>())) ?? []
        let existingBodyWeights = (try? context.fetch(FetchDescriptor<BodyWeightEntry>())) ?? []

        // Import workouts
        if let workouts = root["workouts"] as? [[String: Any]] {
            for workoutDict in workouts {
                guard let dateStr = workoutDict["date"] as? String,
                      let date = dateFormatter.date(from: dateStr),
                      let gym = workoutDict["gym"] as? String,
                      let workoutTypeRaw = workoutDict["workout_type"] as? String,
                      let workoutType = WorkoutType(rawValue: workoutTypeRaw) else {
                    continue
                }

                // Skip duplicates: same date (within 60s), gym, and workout type
                let isDuplicate = existingSessions.contains { existing in
                    abs(existing.date.timeIntervalSince(date)) < 60
                    && existing.gymName == gym
                    && existing.workoutTypeRaw == workoutTypeRaw
                }
                if isDuplicate {
                    result.sessionsSkipped += 1
                    continue
                }

                let session = WorkoutSession(gymName: gym, workoutType: workoutType, date: date, isCompleted: true)
                if let notes = workoutDict["notes"] as? String {
                    session.notes = notes
                }

                if let exercises = workoutDict["exercises"] as? [[String: Any]] {
                    for exerciseDict in exercises {
                        guard let name = exerciseDict["name"] as? String,
                              let order = exerciseDict["order"] as? Int else { continue }

                        let machine = exerciseDict["machine"] as? String ?? ""
                        let notes = exerciseDict["notes"] as? String ?? ""
                        let exercise = LoggedExercise(name: name, order: order, machineName: machine, notes: notes)

                        if let sets = exerciseDict["sets"] as? [[String: Any]] {
                            for setDict in sets {
                                guard let setNumber = setDict["set_number"] as? Int,
                                      let reps = setDict["reps"] as? Int else { continue }
                                let weight = setDict["weight_kg"] as? Double ?? 0
                                let isWarmup = setDict["is_warmup"] as? Bool ?? false
                                let isCompleted = setDict["is_completed"] as? Bool ?? true
                                let rpe = setDict["rpe"] as? Double
                                let exerciseSet = ExerciseSet(
                                    setNumber: setNumber,
                                    reps: reps,
                                    weight: weight,
                                    isCompleted: isCompleted,
                                    isWarmup: isWarmup,
                                    rpe: rpe
                                )
                                exercise.sets.append(exerciseSet)
                            }
                        }

                        exercise.session = session
                        session.exercises.append(exercise)
                    }
                }

                context.insert(session)
                result.sessionsImported += 1
            }
        }

        // Import body weight
        if let bodyWeights = root["body_weight"] as? [[String: Any]] {
            let calendar = Calendar.current
            for entryDict in bodyWeights {
                guard let dateStr = entryDict["date"] as? String,
                      let date = dateFormatter.date(from: dateStr),
                      let weight = entryDict["weight_kg"] as? Double else { continue }

                // Skip duplicates: same day
                let isDuplicate = existingBodyWeights.contains { existing in
                    calendar.isDate(existing.date, inSameDayAs: date)
                }
                if isDuplicate {
                    result.bodyWeightSkipped += 1
                    continue
                }

                let notes = entryDict["notes"] as? String ?? ""
                let entry = BodyWeightEntry(date: date, weight: weight, notes: notes)
                context.insert(entry)
                result.bodyWeightImported += 1
            }
        }

        try context.save()
        return result
    }

    enum ImportError: LocalizedError {
        case invalidFormat

        var errorDescription: String? {
            switch self {
            case .invalidFormat: return "The file is not a valid GymTracker JSON export."
            }
        }
    }

    // MARK: - Helpers

    private static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }


    private static func dateStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private static func writeToTemp(content: String, fileName: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
