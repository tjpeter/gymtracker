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
                    sets.append([
                        "set_number": set.setNumber,
                        "reps": set.reps,
                        "weight_kg": set.weight,
                    ])
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
