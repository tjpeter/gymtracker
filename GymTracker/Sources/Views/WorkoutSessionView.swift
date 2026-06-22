import SwiftUI

struct WorkoutSessionView: View {
    @Bindable var viewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var showAddExercise = false
    @State private var showDiscardAlert = false
    @State private var showCompleteAlert = false
    @State private var timerVisible = true
    @State private var allExpanded = false
    @State private var globalExpandState: Bool? = nil
    @State private var completionSummary: WorkoutSummaryData? = nil
    @State private var completedSession: WorkoutSession? = nil
    @State private var undoBannerText: String? = nil
    @State private var supersetSourceExercise: LoggedExercise? = nil
    @State private var showQuickNote = false

    var body: some View {
        Group {
            if let session = viewModel.currentSession {
                List {
                    // Header info
                    Section {
                        HStack {
                            Label(session.gymName, systemImage: "building.2.fill")
                            Spacer()
                            Text(session.workoutType.displayName)
                                .font(.subheadline.bold())
                                .foregroundStyle(session.workoutType.color)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(session.workoutType.color.opacity(0.15)))
                        }
                        HStack {
                            Label("Started", systemImage: "clock")
                            Spacer()
                            Text(session.date, style: .time)
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Image(systemName: "icloud.and.arrow.up")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Text("Autosaving")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Exercises
                    Section {
                        ForEach(session.sortedExercises) { exercise in
                            ExerciseCardView(
                                exercise: exercise,
                                viewModel: viewModel,
                                globalExpandState: globalExpandState,
                                onDelete: {
                                    let name = exercise.name
                                    withAnimation {
                                        viewModel.removeExercise(exercise)
                                    }
                                    NotificationCenter.default.post(
                                        name: .exerciseDeleted,
                                        object: nil,
                                        userInfo: ["name": name]
                                    )
                                },
                                onLinkSuperset: {
                                    supersetSourceExercise = exercise
                                }
                            )
                        }
                        .onMove { source, destination in
                            viewModel.moveExercise(from: source, to: destination)
                        }
                    } header: {
                        HStack {
                            Text("Exercises")
                            Spacer()
                            Button {
                                allExpanded.toggle()
                                globalExpandState = allExpanded
                            } label: {
                                Image(systemName: allExpanded ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
                                    .font(.subheadline)
                            }
                            Button {
                                showAddExercise = true
                            } label: {
                                Label("Add", systemImage: "plus.circle.fill")
                                    .font(.subheadline)
                            }
                        }
                    }

                    // Notes
                    Section("Notes") {
                        TextField("Session notes (optional)", text: Binding(
                            get: { session.notes },
                            set: {
                                session.notes = $0
                                viewModel.autosave()
                            }
                        ), axis: .vertical)
                        .lineLimit(2...5)
                    }

                    // Complete button
                    Section {
                        Button {
                            showCompleteAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Complete Workout", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .tint(.green)
                        .disabled(session.exercises.isEmpty)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom) {
                    RestTimerView(timer: viewModel.restTimer, isVisible: $timerVisible)
                        .animation(.spring(duration: 0.3), value: timerVisible)
                }
            } else {
                ContentUnavailableView("No Active Workout", systemImage: "figure.walk", description: Text("Start a workout from the home screen"))
            }
        }
        .overlay(alignment: .top) {
            if let text = undoBannerText {
                HStack {
                    Image(systemName: "trash")
                        .font(.caption)
                    Text(text)
                        .font(.subheadline)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.red.opacity(0.85)))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .fontWeight(.semibold)
            }
            if viewModel.isWorkoutActive {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Note a Bug / Idea", systemImage: "lightbulb") {
                            showQuickNote = true
                        }
                        Button("Discard Workout", systemImage: "trash", role: .destructive) {
                            showDiscardAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showQuickNote) {
            FeedbackCaptureSheet()
        }
        .sheet(isPresented: $showAddExercise) {
            AddExerciseSheet(viewModel: viewModel)
        }
        .sheet(item: $supersetSourceExercise) { source in
            NavigationStack {
                List {
                    let others = (viewModel.currentSession?.sortedExercises ?? []).filter { $0.id != source.id }
                    if others.isEmpty {
                        ContentUnavailableView("No Other Exercises", systemImage: "link", description: Text("Add another exercise to link it as a superset."))
                    } else {
                        ForEach(others) { target in
                            Button {
                                withAnimation {
                                    viewModel.linkSuperset(source, target)
                                }
                                supersetSourceExercise = nil
                            } label: {
                                HStack {
                                    Text(target.name)
                                    Spacer()
                                    if target.supersetGroupId != nil {
                                        Image(systemName: "link")
                                            .font(.caption)
                                            .foregroundStyle(.purple)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Link with...")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            supersetSourceExercise = nil
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .alert("Complete Workout?", isPresented: $showCompleteAlert) {
            Button("Complete", role: .none) {
                viewModel.restTimer.stop()
                if let session = viewModel.currentSession {
                    completedSession = session
                    completionSummary = WorkoutSummaryData.from(session: session)
                }
                viewModel.completeWorkout()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will finalize the workout and save it to your history.")
        }
        .sheet(item: $completionSummary) { summary in
            WorkoutSummaryView(summary: summary, session: completedSession) {
                completionSummary = nil
                completedSession = nil
                dismiss()
            }
            .interactiveDismissDisabled()
        }
        .alert("Discard Workout?", isPresented: $showDiscardAlert) {
            Button("Discard", role: .destructive) {
                viewModel.restTimer.stop()
                viewModel.discardWorkout()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All progress for this session will be lost.")
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                viewModel.autosave()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .setCompleted)) { _ in
            viewModel.restTimer.autoStart()
        }
        .onReceive(NotificationCenter.default.publisher(for: .exerciseDeleted)) { notification in
            if let name = notification.userInfo?["name"] as? String {
                withAnimation(.spring(duration: 0.3)) {
                    undoBannerText = "\(name) deleted"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation {
                        undoBannerText = nil
                    }
                }
            }
        }
        .onChange(of: viewModel.restTimer.isRunning) { _, running in
            if running {
                withAnimation(.spring(duration: 0.3)) {
                    timerVisible = true
                }
            }
        }
    }
}

// MARK: - Add Exercise Sheet

struct AddExerciseSheet: View {
    @Bindable var viewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var sets = 3
    @State private var reps = 10
    @State private var weight: Double = 0
    @State private var knownNames: [String] = []
    /// Set when the typed name exactly matches an exercise done before at this gym.
    /// When present, the new exercise is copied from it (per-set values + notes).
    @State private var matchedExercise: LoggedExercise? = nil

    var suggestions: [String] {
        guard !name.isEmpty else { return [] }
        let query = name.lowercased()
        return knownNames.filter { $0.lowercased().contains(query) }.prefix(5).map { $0 }
    }

    private var matchSummary: String? {
        guard let match = matchedExercise else { return nil }
        let workingSets = match.sortedSets.filter { !$0.isWarmup }
        let count = workingSets.isEmpty ? match.sortedSets.count : workingSets.count
        let maxWeight = match.sortedSets.map(\.weight).max() ?? 0
        let repsAtMax = match.sortedSets.first(where: { $0.weight == maxWeight })?.reps ?? 0
        return "\(count) × \(repsAtMax) @ \(maxWeight.formattedWeight) kg"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Exercise name", text: $name)
                    if !suggestions.isEmpty {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                name = suggestion
                            } label: {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(suggestion)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                    }
                }
                if let summary = matchSummary {
                    Section("From Last Time") {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(.blue)
                            Text("Last at \(viewModel.effectiveGymName): \(summary)")
                                .font(.subheadline)
                            Spacer()
                        }
                        Text("Values from your last session will be loaded. Adjust them during the workout.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("Details") {
                        Stepper("Sets: \(sets)", value: $sets, in: 1...10)
                        Stepper("Reps: \(reps)", value: $reps, in: 1...50)
                        HStack {
                            Text("Weight")
                            Spacer()
                            TextField("kg", value: $weight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("kg")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: name) { _, newName in
                let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                matchedExercise = trimmed.isEmpty ? nil : viewModel.lastPerformance(ofExerciseNamed: trimmed)
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        if let match = matchedExercise, match.name == trimmed {
                            viewModel.addExercise(copyingFrom: match)
                        } else {
                            viewModel.addExercise(name: trimmed, sets: sets, reps: reps, weight: weight)
                        }
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                knownNames = viewModel.allExerciseNames()
            }
        }
    }
}
