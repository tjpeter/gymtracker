import SwiftUI

struct ExerciseCardView: View {
    @Bindable var exercise: LoggedExercise
    @Bindable var viewModel: WorkoutViewModel
    var globalExpandState: Bool?
    @State private var isExpanded = true
    @State private var isEditingName = false
    @State private var showRemoveSetAlert = false
    @State private var showApplyPreviousAlert = false
    @State private var showDeleteExerciseAlert = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 8) {
                // Machine / notes
                if !exercise.machineName.isEmpty {
                    HStack {
                        Image(systemName: "gearshape")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(exercise.machineName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }

                // Previous values
                if let prevWeight = exercise.previousWeight {
                    Button {
                        showApplyPreviousAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.caption2)
                            Text("Previous: \(prevWeight.formattedWeight) kg")
                                .font(.caption)
                            if let prevReps = exercise.previousReps {
                                Text("× \(prevReps)")
                                    .font(.caption)
                            }
                            Spacer()
                            Text("Apply")
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(.blue.opacity(0.15)))
                        }
                        .foregroundStyle(.blue)
                    }
                    .buttonStyle(.borderless)
                }

                // Sets header
                HStack {
                    Text("#")
                        .frame(width: 36)
                    Spacer()
                    Text("Weight (kg)")
                        .frame(width: 110)
                    Text("Reps")
                        .frame(width: 70)
                    Image(systemName: "checkmark")
                        .font(.caption2.bold())
                        .frame(width: 30)
                }
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
                .padding(.top, 4)

                // Individual sets
                let sorted = exercise.sortedSets
                ForEach(sorted) { set in
                    SetRowView(
                        set: set,
                        viewModel: viewModel,
                        workingSetNumber: workingSetNumber(for: set, in: sorted)
                    )
                }

                // Add/remove set buttons
                HStack {
                    Button {
                        viewModel.addSetToExercise(exercise)
                    } label: {
                        Label("Add Set", systemImage: "plus.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    Spacer()
                    if exercise.sets.count > 1 {
                        Button(role: .destructive) {
                            showRemoveSetAlert = true
                        } label: {
                            Label("Remove Set", systemImage: "minus.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.top, 4)

                // Notes field
                TextField("Notes", text: $exercise.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .onChange(of: exercise.notes) { _, _ in
                        viewModel.autosave()
                    }
            }
        } label: {
            HStack {
                if isEditingName {
                    TextField("Exercise name", text: $exercise.name)
                        .font(.subheadline.bold())
                        .onSubmit { isEditingName = false }
                } else {
                    Text(exercise.name)
                        .font(.subheadline.bold())
                        .onTapGesture(count: 2) {
                            isEditingName = true
                        }
                        .contextMenu {
                            Button {
                                isEditingName = true
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                        }
                }
                Spacer()
                let warmupCount = exercise.sets.filter(\.isWarmup).count
                let workingCount = exercise.sets.count - warmupCount
                if warmupCount > 0 {
                    Text("\(workingCount) sets + \(warmupCount)W")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(exercise.sets.count) sets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showDeleteExerciseAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .onChange(of: globalExpandState) { _, newValue in
            if let newValue {
                withAnimation { isExpanded = newValue }
            }
        }
        .alert("Remove Last Set?", isPresented: $showRemoveSetAlert) {
            Button("Remove", role: .destructive) {
                if let last = exercise.sortedSets.last {
                    viewModel.removeSetFromExercise(exercise, set: last)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the last set from \(exercise.name).")
        }
        .alert("Delete Exercise?", isPresented: $showDeleteExerciseAlert) {
            Button("Delete", role: .destructive) {
                viewModel.removeExercise(exercise)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove \(exercise.name) and all its sets from this workout.")
        }
        .alert("Apply Previous Values?", isPresented: $showApplyPreviousAlert) {
            Button("Apply", role: .none) {
                if let prevWeight = exercise.previousWeight {
                    for set in exercise.sets {
                        set.weight = prevWeight
                        if let prevReps = exercise.previousReps {
                            set.reps = prevReps
                        }
                    }
                    viewModel.autosave()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let prevWeight = exercise.previousWeight {
                Text("This will overwrite all sets with \(prevWeight.formattedWeight) kg\(exercise.previousReps.map { " × \($0) reps" } ?? "").")
            }
        }
    }

    private func workingSetNumber(for set: ExerciseSet, in sets: [ExerciseSet]) -> Int {
        var count = 0
        for s in sets {
            if !s.isWarmup { count += 1 }
            if s.id == set.id { return count }
        }
        return count
    }
}

// MARK: - Set Row

struct SetRowView: View {
    @Bindable var set: ExerciseSet
    @Bindable var viewModel: WorkoutViewModel
    var workingSetNumber: Int

    var body: some View {
        HStack {
            // Set number with warmup indicator
            Button {
                set.isWarmup.toggle()
                viewModel.autosave()
            } label: {
                Text(set.isWarmup ? "W" : "\(workingSetNumber)")
                    .font(.subheadline.bold())
                    .foregroundStyle(set.isWarmup ? .orange : .secondary)
                    .frame(width: 36)
            }
            .buttonStyle(.borderless)

            Spacer()

            // Weight input with +/- buttons
            HStack(spacing: 4) {
                Button {
                    set.weight = max(0, set.weight - 2.5)
                    viewModel.autosave()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.body)
                }
                .buttonStyle(.borderless)

                TextField("0", value: $set.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 50)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))

                Button {
                    set.weight += 2.5
                    viewModel.autosave()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.body)
                }
                .buttonStyle(.borderless)
            }
            .frame(width: 110)

            // Reps input
            HStack(spacing: 4) {
                Button {
                    set.reps = max(0, set.reps - 1)
                    viewModel.autosave()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .buttonStyle(.borderless)

                TextField("0", value: $set.reps, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 32)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))

                Button {
                    set.reps += 1
                    viewModel.autosave()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            .frame(width: 70)

            // Done toggle
            Button {
                set.isCompleted.toggle()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                viewModel.autosave()
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(set.isCompleted ? .green : .secondary.opacity(0.4))
                    .font(.title3)
            }
            .buttonStyle(.borderless)
            .frame(width: 30)
        }
        .opacity(set.isWarmup ? 0.7 : 1.0)
    }
}
