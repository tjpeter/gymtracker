import SwiftUI

struct WorkoutSummaryData: Identifiable {
    let id = UUID()
    let gymName: String
    let workoutType: WorkoutType
    let date: Date
    let duration: Int // minutes
    let exercises: [ExerciseSummary]

    struct ExerciseSummary: Identifiable {
        let id = UUID()
        let name: String
        let workingSets: Int
        let completedSets: Int
        let maxWeight: Double
        let totalVolume: Double
        let previousMaxWeight: Double?
        let isPR: Bool
    }

    var totalExercises: Int { exercises.count }
    var totalSets: Int { exercises.reduce(0) { $0 + $1.completedSets } }
    var totalVolume: Double { exercises.reduce(0) { $0 + $1.totalVolume } }
    var prCount: Int { exercises.filter(\.isPR).count }

    static func from(session: WorkoutSession) -> WorkoutSummaryData {
        let duration = session.durationMinutes ?? Int(Date().timeIntervalSince(session.date) / 60)

        let exerciseSummaries = session.sortedExercises.map { exercise in
            let workingSets = exercise.sets.filter { !$0.isWarmup }
            let completedSets = workingSets.filter(\.isCompleted)
            let maxWeight = workingSets.map(\.weight).max() ?? 0
            let volume = completedSets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            let isPR = exercise.previousWeight.map { maxWeight > $0 } ?? false

            return ExerciseSummary(
                name: exercise.name,
                workingSets: workingSets.count,
                completedSets: completedSets.count,
                maxWeight: maxWeight,
                totalVolume: volume,
                previousMaxWeight: exercise.previousWeight,
                isPR: isPR
            )
        }

        return WorkoutSummaryData(
            gymName: session.gymName,
            workoutType: session.workoutType,
            date: session.date,
            duration: max(1, duration),
            exercises: exerciseSummaries
        )
    }
}

struct WorkoutSummaryView: View {
    let summary: WorkoutSummaryData
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.green)

                        Text("Workout Complete!")
                            .font(.title2.bold())

                        HStack(spacing: 4) {
                            Text(summary.gymName)
                            Text("·")
                                .foregroundStyle(.secondary)
                            Text(summary.workoutType.displayName)
                                .foregroundStyle(summary.workoutType.color)
                        }
                        .font(.subheadline)
                    }
                    .padding(.top, 8)

                    // Stats grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        SummaryStat(
                            value: "\(summary.duration)",
                            label: "Minutes",
                            icon: "clock.fill",
                            color: .blue
                        )
                        SummaryStat(
                            value: "\(summary.totalSets)",
                            label: "Sets",
                            icon: "number",
                            color: .orange
                        )
                        SummaryStat(
                            value: formatVolume(summary.totalVolume),
                            label: "Volume (kg)",
                            icon: "scalemass.fill",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)

                    // PRs banner
                    if summary.prCount > 0 {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.yellow)
                            Text("\(summary.prCount) Personal Record\(summary.prCount == 1 ? "" : "s")!")
                                .font(.headline)
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.yellow.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }

                    // Exercise breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Exercise Breakdown")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(summary.exercises) { exercise in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(exercise.name)
                                            .font(.subheadline.bold())
                                        if exercise.isPR {
                                            Image(systemName: "trophy.fill")
                                                .font(.caption2)
                                                .foregroundStyle(.yellow)
                                        }
                                    }
                                    Text("\(exercise.completedSets)/\(exercise.workingSets) sets completed")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(exercise.maxWeight.formattedWeight) kg")
                                        .font(.subheadline.bold())
                                        .monospacedDigit()
                                    if let prev = exercise.previousMaxWeight, exercise.maxWeight != prev {
                                        let diff = exercise.maxWeight - prev
                                        Text("\(diff >= 0 ? "+" : "")\(diff.formattedWeight) kg")
                                            .font(.caption)
                                            .monospacedDigit()
                                            .foregroundStyle(diff >= 0 ? .green : .red)
                                    }
                                    Text("\(Int(exercise.totalVolume)) kg vol")
                                        .font(.caption)
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return "\(Int(volume))"
    }
}

private struct SummaryStat: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}
