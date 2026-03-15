import SwiftUI

struct WorkoutDetailView: View {
    let session: WorkoutSession

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
                if !session.notes.isEmpty {
                    LabeledContent("Notes", value: session.notes)
                }
            }

            ForEach(session.sortedExercises) { exercise in
                Section(exercise.name) {
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

                    if !exercise.notes.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "note.text")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(exercise.notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
