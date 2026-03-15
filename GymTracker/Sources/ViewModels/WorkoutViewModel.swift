import Foundation
import SwiftData
import SwiftUI

@MainActor @Observable
final class WorkoutViewModel {
    var selectedGymName: String = GymPreset.waedenswil.rawValue
    var selectedWorkoutType: WorkoutType = .a
    var customGymName: String = ""
    var isCustomGym: Bool = false
    var currentSession: WorkoutSession?
    var isWorkoutActive = false

    private var modelContext: ModelContext?

    var effectiveGymName: String {
        isCustomGym ? customGymName : selectedGymName
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Resume Incomplete Workout

    func resumeIncompleteWorkout() -> Bool {
        guard let context = modelContext else { return false }
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { session in
                session.isCompleted == false
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        if let sessions = try? context.fetch(descriptor), let incomplete = sessions.first {
            currentSession = incomplete
            isWorkoutActive = true
            return true
        }
        return false
    }

    // MARK: - Start Workout

    func startWorkout() {
        guard let context = modelContext else { return }
        let gymName = effectiveGymName
        guard !gymName.isEmpty else { return }

        let session = WorkoutSession(gymName: gymName, workoutType: selectedWorkoutType)

        // Load exercise list from previous completed session (carries forward renames/removals)
        let previousExercises = fetchPreviousSession(gymName: gymName, workoutType: selectedWorkoutType)

        if let prevExercises = previousExercises, !prevExercises.isEmpty {
            for (index, prev) in prevExercises.enumerated() {
                let prevWeight = prev.sortedSets.map(\.weight).max()
                let prevReps = prev.sortedSets.first(where: { $0.weight == prevWeight })?.reps
                let exercise = LoggedExercise(
                    name: prev.name,
                    order: index,
                    machineName: prev.machineName,
                    previousWeight: prevWeight,
                    previousReps: prevReps
                )
                for prevSet in prev.sortedSets {
                    let set = ExerciseSet(
                        setNumber: prevSet.setNumber,
                        reps: prevSet.reps,
                        weight: prevSet.weight
                    )
                    exercise.sets.append(set)
                }
                exercise.session = session
                session.exercises.append(exercise)
            }
        } else {
            let templates = TemplateProvider.templates(for: gymName, workoutType: selectedWorkoutType)
            for (index, template) in templates.enumerated() {
                let exercise = template.toLoggedExercise(order: index)
                exercise.session = session
                session.exercises.append(exercise)
            }
        }

        context.insert(session)
        autosave()
        currentSession = session
        isWorkoutActive = true
    }

    // MARK: - Complete Workout

    func completeWorkout() {
        guard let session = currentSession else { return }
        session.isCompleted = true
        session.endDate = Date()
        for exercise in session.exercises {
            for set in exercise.sets {
                set.isCompleted = true
            }
        }
        autosave()
        isWorkoutActive = false
        currentSession = nil
    }

    // MARK: - Discard Workout

    func discardWorkout() {
        guard let context = modelContext, let session = currentSession else { return }
        context.delete(session)
        try? context.save()
        isWorkoutActive = false
        currentSession = nil
    }

    // MARK: - Autosave

    func autosave() {
        guard let context = modelContext else { return }
        try? context.save()
    }

    // MARK: - Exercise Management

    func addExercise(name: String, sets: Int, reps: Int, weight: Double) {
        guard let session = currentSession else { return }
        let order = session.exercises.count
        let exercise = LoggedExercise(name: name, order: order)
        for i in 1...max(1, sets) {
            let set = ExerciseSet(setNumber: i, reps: reps, weight: weight)
            exercise.sets.append(set)
        }
        exercise.session = session
        session.exercises.append(exercise)
        autosave()
    }

    func removeExercise(_ exercise: LoggedExercise) {
        guard let context = modelContext, let session = currentSession else { return }
        session.exercises.removeAll { $0.id == exercise.id }
        context.delete(exercise)
        for (index, ex) in session.sortedExercises.enumerated() {
            ex.order = index
        }
        autosave()
    }

    func moveExercise(from source: IndexSet, to destination: Int) {
        guard let session = currentSession else { return }
        var sorted = session.sortedExercises
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, exercise) in sorted.enumerated() {
            exercise.order = index
        }
        autosave()
    }

    func addSetToExercise(_ exercise: LoggedExercise) {
        let lastSet = exercise.sortedSets.last
        let newSet = ExerciseSet(
            setNumber: exercise.sets.count + 1,
            reps: lastSet?.reps ?? 10,
            weight: lastSet?.weight ?? 0
        )
        exercise.sets.append(newSet)
        autosave()
    }

    func removeSetFromExercise(_ exercise: LoggedExercise, set: ExerciseSet) {
        guard let context = modelContext else { return }
        exercise.sets.removeAll { $0.id == set.id }
        context.delete(set)
        for (index, s) in exercise.sortedSets.enumerated() {
            s.setNumber = index + 1
        }
        autosave()
    }

    // MARK: - Custom Gym Names

    func allUsedGymNames() -> [String] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        guard let sessions = try? context.fetch(descriptor) else { return [] }
        let presetNames = Set(GymPreset.allCases.map(\.rawValue))
        var customNames: [String] = []
        var seen = Set<String>()
        for session in sessions {
            if !presetNames.contains(session.gymName) && !seen.contains(session.gymName) {
                customNames.append(session.gymName)
                seen.insert(session.gymName)
            }
        }
        return customNames
    }

    // MARK: - Exercise Names

    func allExerciseNames() -> [String] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        guard let sessions = try? context.fetch(descriptor) else { return [] }
        var names: [String] = []
        var seen = Set<String>()
        for session in sessions {
            for exercise in session.exercises {
                if !seen.contains(exercise.name) {
                    names.append(exercise.name)
                    seen.insert(exercise.name)
                }
            }
        }
        return names.sorted()
    }

    // MARK: - Delete Workout

    func deleteWorkout(_ session: WorkoutSession) {
        guard let context = modelContext else { return }
        context.delete(session)
        try? context.save()
    }

    // MARK: - Fetch Previous Session

    private func fetchPreviousSession(gymName: String, workoutType: WorkoutType) -> [LoggedExercise]? {
        guard let context = modelContext else { return nil }
        let workoutRaw = workoutType.rawValue

        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { session in
                session.gymName == gymName &&
                session.workoutTypeRaw == workoutRaw &&
                session.isCompleted == true
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        guard let sessions = try? context.fetch(descriptor),
              let lastSession = sessions.first else {
            return nil
        }
        return lastSession.sortedExercises
    }
}
