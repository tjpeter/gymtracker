import SwiftUI

struct WorkoutDetailView: View {
    let session: WorkoutSession

    var body: some View {
        List {
            Section {
                LabeledContent("Gym", value: session.gymName)
                LabeledContent("Workout", value: session.workoutType.displayName)
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
                            Text("Set \(set.setNumber)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(set.weight.formattedWeight) kg")
                                .font(.subheadline.bold())
                            Text("×")
                                .foregroundStyle(.secondary)
                            Text("\(set.reps) reps")
                                .font(.subheadline)
                        }
                    }

                    if !exercise.notes.isEmpty {
                        Text(exercise.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
