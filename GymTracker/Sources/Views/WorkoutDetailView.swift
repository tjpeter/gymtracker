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
                if let rating = session.rating, rating > 0, !isEditing {
                    LabeledContent("Rating") {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundStyle(star <= rating ? .yellow : .secondary.opacity(0.3))
                            }
                        }
                    }
                }
                if isEditing {
                    LabeledContent("Rating") {
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    session.rating = session.rating == star ? nil : star
                                } label: {
                                    Image(systemName: star <= (session.rating ?? 0) ? "star.fill" : "star")
                                        .font(.body)
                                        .foregroundStyle(star <= (session.rating ?? 0) ? .yellow : .secondary.opacity(0.3))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
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

            // Summary stats
            Section("Summary") {
                let summary = WorkoutSummaryData.from(session: session)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCell(label: "Duration", value: "\(summary.duration) min", icon: "clock.fill", color: .blue)
                    StatCell(label: "Working Sets", value: "\(summary.totalSets)", icon: "number", color: .orange)
                    StatCell(label: "Volume", value: formatVolume(summary.totalVolume), icon: "scalemass.fill", color: .green)
                    StatCell(label: "PRs", value: "\(summary.prCount)", icon: "trophy.fill", color: .yellow)
                }
                .padding(.vertical, 4)
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
                                if let rpe = set.rpe {
                                    Text("RPE \(String(format: rpe.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", rpe))")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.orange)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.orange.opacity(0.12)))
                                }
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

    private func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "'"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: volume)) ?? "\(Int(volume))"
    }
}

private struct StatCell: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.headline.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.08)))
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
