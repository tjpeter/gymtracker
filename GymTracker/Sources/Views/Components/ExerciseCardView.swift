import SwiftUI

struct ExerciseCardView: View {
    @Bindable var exercise: LoggedExercise
    @Bindable var viewModel: WorkoutViewModel
    @State private var isExpanded = true
    @State private var isEditingName = false

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
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text("Previous: \(formatWeight(prevWeight)) kg")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        if let prevReps = exercise.previousReps {
                            Text("× \(prevReps)")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        Spacer()
                    }
                }

                // Sets header
                HStack {
                    Text("Set")
                        .frame(width: 36)
                    Spacer()
                    Text("Weight (kg)")
                        .frame(width: 110)
                    Text("Reps")
                        .frame(width: 70)
                }
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
                .padding(.top, 4)

                // Individual sets
                ForEach(exercise.sortedSets) { set in
                    SetRowView(set: set)
                }

                // Add/remove set buttons
                HStack {
                    Button {
                        viewModel.addSetToExercise(exercise)
                    } label: {
                        Label("Add Set", systemImage: "plus.circle")
                            .font(.caption)
                    }
                    Spacer()
                    if exercise.sets.count > 1 {
                        Button(role: .destructive) {
                            if let last = exercise.sortedSets.last {
                                viewModel.removeSetFromExercise(exercise, set: last)
                            }
                        } label: {
                            Label("Remove Set", systemImage: "minus.circle")
                                .font(.caption)
                        }
                    }
                }
                .padding(.top, 4)

                // Notes field
                TextField("Notes", text: $exercise.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                }
                Spacer()
                Text("\(exercise.sets.count) sets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                viewModel.removeExercise(exercise)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func formatWeight(_ weight: Double) -> String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", weight)
            : String(format: "%.1f", weight)
    }
}

// MARK: - Set Row

struct SetRowView: View {
    @Bindable var set: ExerciseSet

    var body: some View {
        HStack {
            Text("\(set.setNumber)")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .frame(width: 36)

            Spacer()

            // Weight input with +/- buttons
            HStack(spacing: 4) {
                Button {
                    set.weight = max(0, set.weight - 2.5)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.body)
                }
                .buttonStyle(.plain)

                TextField("0", value: $set.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 50)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))

                Button {
                    set.weight += 2.5
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.body)
                }
                .buttonStyle(.plain)
            }
            .frame(width: 110)

            // Reps input
            HStack(spacing: 4) {
                Button {
                    set.reps = max(0, set.reps - 1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .buttonStyle(.plain)

                TextField("0", value: $set.reps, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 32)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))

                Button {
                    set.reps += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            .frame(width: 70)
        }
    }
}
