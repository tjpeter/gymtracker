import SwiftUI

struct ExerciseCardView: View {
    @Bindable var exercise: LoggedExercise
    @Bindable var viewModel: WorkoutViewModel
    var globalExpandState: Bool?
    var onDelete: (() -> Void)?
    var onLinkSuperset: (() -> Void)?
    @State private var isExpanded = false
    @State private var isEditingName = false
    @State private var showRenameAlert = false
    @State private var renameText = ""
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
                                .monospacedDigit()
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
                HStack(spacing: 6) {
                    Text("#")
                        .frame(width: 28, alignment: .center)
                    Text("Weight")
                    Spacer()
                    Text("Reps")
                    Image(systemName: "checkmark")
                        .frame(width: 38)
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
                        workingSetNumber: workingSetNumber(for: set, in: sorted),
                        previousWeight: exercise.previousWeight,
                        previousReps: exercise.previousReps
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
                        .font(.body.bold())
                        .onSubmit { isEditingName = false }
                } else {
                    Text(exercise.name)
                        .font(.body.bold())
                        .onTapGesture(count: 2) {
                            isEditingName = true
                        }
                        .contextMenu {
                            Button {
                                renameText = exercise.name
                                showRenameAlert = true
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            if exercise.supersetGroupId != nil {
                                Button {
                                    viewModel.unlinkSuperset(exercise)
                                } label: {
                                    Label("Unlink Superset", systemImage: "link.badge.plus")
                                }
                            } else {
                                Button {
                                    onLinkSuperset?()
                                } label: {
                                    Label("Link as Superset", systemImage: "link")
                                }
                            }
                        }
                }
                if !exercise.notes.isEmpty {
                    Image(systemName: "text.bubble")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let prev = exercise.previousWeight,
                   exercise.sets.contains(where: { !$0.isWarmup && $0.weight > prev }) {
                    Image(systemName: "trophy.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                        .symbolEffect(.pulse, options: .repeating.speed(0.5))
                }
                Spacer()
                let completedCount = exercise.sets.filter(\.isCompleted).count
                let totalCount = exercise.sets.count
                let warmupCount = exercise.sets.filter(\.isWarmup).count
                let workingCount = totalCount - warmupCount
                HStack(spacing: 4) {
                    Text("\(completedCount)/\(totalCount)")
                        .font(.caption.bold())
                        .monospacedDigit()
                        .foregroundStyle(completedCount == totalCount && totalCount > 0 ? .green : .orange)
                    if warmupCount > 0 {
                        Text("(\(workingCount)+\(warmupCount)W)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                if exercise.supersetGroupId != nil {
                    Image(systemName: "link")
                        .font(.caption2)
                        .foregroundStyle(.purple)
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                showDeleteExerciseAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
            Button {
                renameText = exercise.name
                showRenameAlert = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            .tint(.blue)
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
                onDelete?()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove \(exercise.name) and all its sets from this workout.")
        }
        .alert("Rename Exercise", isPresented: $showRenameAlert) {
            TextField("Exercise name", text: $renameText)
            Button("Save") {
                let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    exercise.name = trimmed
                    viewModel.autosave()
                }
            }
            Button("Cancel", role: .cancel) {}
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
    var previousWeight: Double?
    var previousReps: Int?
    @State private var checkmarkScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 6) {
            // Set number with warmup indicator
            Button {
                set.isWarmup.toggle()
                viewModel.autosave()
            } label: {
                Text(set.isWarmup ? "W" : "\(workingSetNumber)")
                    .font(.subheadline.bold())
                    .foregroundStyle(set.isWarmup ? .orange : .secondary)
                    .frame(width: 28)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(set.isWarmup ? "Warmup set, tap to make working set" : "Set \(workingSetNumber), tap to mark as warmup")

            // Weight input with +/- buttons
            HStack(spacing: 4) {
                Button {
                    set.weight = max(0, set.weight - 2.5)
                    viewModel.autosave()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                        .frame(minWidth: 38, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Decrease weight by 2.5 kg")

                TextField(previousWeight.map { $0.formattedWeight } ?? "0", value: $set.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.body.bold())
                    .monospacedDigit()
                    .frame(width: 50)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.Colors.inputBackground))
                    .accessibilityLabel("Weight, \(set.weight.formattedWeight) kg")

                Button {
                    set.weight += 2.5
                    viewModel.autosave()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                        .frame(minWidth: 38, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Increase weight by 2.5 kg")
            }

            Spacer()

            // Reps input
            HStack(spacing: 2) {
                Button {
                    set.reps = max(0, set.reps - 1)
                    viewModel.autosave()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.body)
                        .frame(minWidth: 30, minHeight: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Decrease reps")

                TextField(previousReps.map { "\($0)" } ?? "0", value: $set.reps, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .monospacedDigit()
                    .frame(width: 30)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.Colors.inputBackground))
                    .accessibilityLabel("Reps, \(set.reps)")

                Button {
                    set.reps += 1
                    viewModel.autosave()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.body)
                        .frame(minWidth: 30, minHeight: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Increase reps")
            }

            // Done toggle
            Button {
                set.isCompleted.toggle()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                viewModel.autosave()
                if set.isCompleted {
                    NotificationCenter.default.post(name: .setCompleted, object: nil)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                        checkmarkScale = 1.3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            checkmarkScale = 1.0
                        }
                    }
                }
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(set.isCompleted ? .green : .secondary.opacity(0.4))
                    .font(.title2)
                    .scaleEffect(checkmarkScale)
                    .frame(minWidth: 38, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(set.isCompleted ? "Set completed, tap to undo" : "Mark set as done")

            // RPE badge
            if set.isCompleted || set.rpe != nil {
                Button {
                    let values: [Double?] = [6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5, 10, nil]
                    if let current = set.rpe, let idx = values.firstIndex(of: current), idx + 1 < values.count {
                        set.rpe = values[idx + 1]
                    } else if set.rpe == nil {
                        set.rpe = 6
                    } else {
                        set.rpe = nil
                    }
                    viewModel.autosave()
                } label: {
                    Text(set.rpe.map { String(format: $0.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", $0) } ?? "RPE")
                        .font(.caption2.bold())
                        .foregroundStyle(set.rpe != nil ? rpeColor(set.rpe!) : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill((set.rpe != nil ? rpeColor(set.rpe!) : Color.secondary).opacity(0.12)))
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(set.rpe.map { "RPE \($0)" } ?? "Set RPE, tap to add")
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(set.isWarmup ? Color.orange.opacity(0.06) : (set.isCompleted ? Color.green.opacity(0.08) : Color.clear))
        )
        .overlay(alignment: .leading) {
            if set.isWarmup {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.orange)
                    .frame(width: 3)
                    .padding(.vertical, 2)
            }
        }
        .opacity(set.isWarmup ? 0.85 : 1.0)
    }

    private func rpeColor(_ rpe: Double) -> Color {
        switch rpe {
        case ..<7.5: return .green
        case ..<8.5: return .yellow
        case ..<9.5: return .orange
        default: return .red
        }
    }
}
