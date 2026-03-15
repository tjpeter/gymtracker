import SwiftUI

struct WorkoutSessionView: View {
    @Bindable var viewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var showAddExercise = false
    @State private var showDiscardAlert = false
    @State private var showCompleteAlert = false
    @State private var restTimer = RestTimerViewModel()

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
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(.blue.opacity(0.15)))
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

                    // Rest timer
                    Section {
                        RestTimerView(timer: restTimer)
                    } header: {
                        Text("Rest Timer")
                    }

                    // Exercises
                    Section {
                        ForEach(session.sortedExercises) { exercise in
                            ExerciseCardView(exercise: exercise, viewModel: viewModel)
                        }
                        .onMove { source, destination in
                            viewModel.moveExercise(from: source, to: destination)
                        }
                    } header: {
                        HStack {
                            Text("Exercises")
                            Spacer()
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
            } else {
                ContentUnavailableView("No Active Workout", systemImage: "figure.walk", description: Text("Start a workout from the home screen"))
            }
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isWorkoutActive)
        .toolbar {
            if viewModel.isWorkoutActive {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard", role: .destructive) {
                        showDiscardAlert = true
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .sheet(isPresented: $showAddExercise) {
            AddExerciseSheet(viewModel: viewModel)
        }
        .alert("Complete Workout?", isPresented: $showCompleteAlert) {
            Button("Complete", role: .none) {
                restTimer.stop()
                viewModel.completeWorkout()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will finalize the workout and save it to your history.")
        }
        .alert("Discard Workout?", isPresented: $showDiscardAlert) {
            Button("Discard", role: .destructive) {
                restTimer.stop()
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
        .onAppear {
            RestTimerViewModel.requestNotificationPermission()
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

    var suggestions: [String] {
        guard !name.isEmpty else { return [] }
        let query = name.lowercased()
        return knownNames.filter { $0.lowercased().contains(query) }.prefix(5).map { $0 }
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
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !name.isEmpty else { return }
                        viewModel.addExercise(name: name, sets: sets, reps: reps, weight: weight)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                knownNames = viewModel.allExerciseNames()
            }
        }
    }
}
