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
        let name = isCustomGym ? customGymName : selectedGymName
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
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
                        weight: prevSet.weight,
                        isWarmup: prevSet.isWarmup
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

    func startWorkout(copyingFrom sourceSession: WorkoutSession) {
        guard let context = modelContext else { return }
        let gymName = effectiveGymName
        guard !gymName.isEmpty else { return }

        let session = WorkoutSession(gymName: gymName, workoutType: selectedWorkoutType)

        for (index, prev) in sourceSession.sortedExercises.enumerated() {
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
                    weight: prevSet.weight,
                    isWarmup: prevSet.isWarmup
                )
                exercise.sets.append(set)
            }
            exercise.session = session
            session.exercises.append(exercise)
        }

        context.insert(session)
        autosave()
        currentSession = session
        isWorkoutActive = true
    }

    func recentCompletedSessions(limit: Int = 20) -> [WorkoutSession] {
        guard let context = modelContext else { return [] }
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Complete Workout

    func completeWorkout() {
        guard let session = currentSession else { return }
        session.isCompleted = true
        session.endDate = Date()
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
        let exerciseID = exercise.id
        session.exercises.removeAll { $0.id == exerciseID }
        for (index, ex) in session.sortedExercises.enumerated() {
            ex.order = index
        }
        context.delete(exercise)
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
        guard let context = modelContext else { return }
        let lastSet = exercise.sortedSets.last
        let newSet = ExerciseSet(
            setNumber: exercise.sets.count + 1,
            reps: lastSet?.reps ?? 10,
            weight: lastSet?.weight ?? 0
        )
        context.insert(newSet)
        newSet.exercise = exercise
        exercise.sets.append(newSet)
        autosave()
    }

    func removeSetFromExercise(_ exercise: LoggedExercise, set: ExerciseSet) {
        guard let context = modelContext, exercise.sets.count > 1 else { return }
        set.exercise = nil
        exercise.sets.removeAll { $0.id == set.id }
        context.delete(set)
        for (index, s) in exercise.sortedSets.enumerated() {
            s.setNumber = index + 1
        }
        autosave()
    }

    // MARK: - Superset Management

    func linkSuperset(_ exercise1: LoggedExercise, _ exercise2: LoggedExercise) {
        let groupId = exercise1.supersetGroupId ?? exercise2.supersetGroupId ?? UUID()
        exercise1.supersetGroupId = groupId
        exercise2.supersetGroupId = groupId
        autosave()
    }

    func unlinkSuperset(_ exercise: LoggedExercise) {
        guard let groupId = exercise.supersetGroupId, let session = currentSession else { return }
        exercise.supersetGroupId = nil
        // If only one exercise remains in the group, unlink it too
        let remaining = session.exercises.filter { $0.supersetGroupId == groupId }
        if remaining.count == 1 {
            remaining.first?.supersetGroupId = nil
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

    // MARK: - Template Management

    func saveAsTemplate(session: WorkoutSession, name: String) {
        guard let context = modelContext else { return }
        let template = CustomTemplate(name: name, gymName: session.gymName, workoutType: session.workoutType)
        for (index, exercise) in session.sortedExercises.enumerated() {
            let maxWeight = exercise.sortedSets.map(\.weight).max() ?? 0
            let firstReps = exercise.sortedSets.first?.reps ?? 10
            let te = TemplateExercise(
                name: exercise.name,
                machineName: exercise.machineName,
                order: index,
                sets: exercise.sets.count,
                reps: firstReps,
                weight: maxWeight
            )
            te.template = template
            template.exercises.append(te)
        }
        context.insert(template)
        try? context.save()
    }

    func fetchCustomTemplates() -> [CustomTemplate] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<CustomTemplate>(
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func deleteTemplate(_ template: CustomTemplate) {
        guard let context = modelContext else { return }
        context.delete(template)
        try? context.save()
    }

    func startWorkout(fromTemplate template: CustomTemplate) {
        guard let context = modelContext else { return }
        let gymName = effectiveGymName
        guard !gymName.isEmpty else { return }

        let session = WorkoutSession(gymName: gymName, workoutType: selectedWorkoutType)

        for (index, te) in template.sortedExercises.enumerated() {
            let exercise = LoggedExercise(
                name: te.name,
                order: index,
                machineName: te.machineName
            )
            for i in 1...max(1, te.sets) {
                let set = ExerciseSet(setNumber: i, reps: te.reps, weight: te.weight)
                exercise.sets.append(set)
            }
            exercise.session = session
            session.exercises.append(exercise)
        }

        context.insert(session)
        autosave()
        currentSession = session
        isWorkoutActive = true
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
