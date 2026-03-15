import SwiftUI

struct WorkoutDetailView: View {
    let session: WorkoutSession
    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false

    var body: some View {
        List {
            Section {
                LabeledContent("Gym", value: session.gymName)
                LabeledContent("Workout") {
                    Text(session.workoutType.displayName)
                        .foregroundStyle(session.workoutType.color)
                }
                LabeledContent("Date") {
                    Text(session.date, style: .date)
                }
                LabeledContent("Time") {
                    Text(session.date, style: .time)
                }
                if let duration = session.durationMinutes {
                    LabeledContent("Duration", value: "\(duration) min")
                }
                if isEditing {
                    TextField("Notes", text: Binding(
                        get: { session.notes },
                        set: { session.notes = $0 }
                    ), axis: .vertical)
                    .lineLimit(1...4)
                } else if !session.notes.isEmpty {
                    LabeledContent("Notes", value: session.notes)
                }
            }

            ForEach(session.sortedExercises) { exercise in
                Section {
                    if !exercise.machineName.isEmpty {
                        HStack {
                            Image(systemName: "gearshape")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(exercise.machineName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    ForEach(exercise.sortedSets) { set in
                        if isEditing {
                            EditableSetRow(set: set)
                        } else {
                            HStack {
                                Text(set.isWarmup ? "W" : "Set \(set.setNumber)")
                                    .font(.subheadline)
                                    .foregroundStyle(set.isWarmup ? .orange : .secondary)
                                Spacer()
                                Text("\(set.weight.formattedWeight) kg")
                                    .font(.body.bold())
                                    .monospacedDigit()
                                Text("×")
                                    .foregroundStyle(.secondary)
                                Text("\(set.reps) reps")
                                    .font(.subheadline)
                                    .monospacedDigit()
                            }
                            .opacity(set.isWarmup ? 0.7 : 1.0)
                        }
                    }

                    if !exercise.notes.isEmpty && !isEditing {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "note.text")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(exercise.notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    if isEditing {
                        TextField("Exercise name", text: Binding(
                            get: { exercise.name },
                            set: { exercise.name = $0 }
                        ))
                        .textCase(nil)
                    } else {
                        Text(exercise.name)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        try? modelContext.save()
                    }
                    isEditing.toggle()
                }
            }
            if isEditing {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Editable Set Row

private struct EditableSetRow: View {
    @Bindable var set: ExerciseSet

    var body: some View {
        HStack {
            Text(set.isWarmup ? "W" : "Set \(set.setNumber)")
                .font(.subheadline)
                .foregroundStyle(set.isWarmup ? .orange : .secondary)
                .frame(width: 50, alignment: .leading)

            Spacer()

            HStack(spacing: 4) {
                TextField("0", value: $set.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .frame(width: 60)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.Colors.inputBackground))
                Text("kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("×")
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            HStack(spacing: 4) {
                TextField("0", value: $set.reps, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .frame(width: 40)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.Colors.inputBackground))
                Text("reps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .opacity(set.isWarmup ? 0.7 : 1.0)
    }
}
