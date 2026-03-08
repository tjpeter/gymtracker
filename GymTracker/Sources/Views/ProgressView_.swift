import SwiftUI
import SwiftData
import Charts

struct ProgressView_: View {
    @Query(
        filter: #Predicate<WorkoutSession> { $0.isCompleted == true },
        sort: \WorkoutSession.date,
        order: .reverse
    ) private var sessions: [WorkoutSession]
    @State private var selectedExercise: String?

    var allExerciseNames: [String] {
        var names = Set<String>()
        for session in sessions {
            for exercise in session.exercises {
                names.insert(exercise.name)
            }
        }
        return names.sorted()
    }

    var allGymNames: [String] {
        var names = Set<String>()
        for session in sessions { names.insert(session.gymName) }
        return names.sorted()
    }

    var body: some View {
        List {
            Section("Overview") {
                LabeledContent("Total Workouts", value: "\(sessions.count)")

                let gymCounts = Dictionary(grouping: sessions, by: \.gymName)
                ForEach(allGymNames, id: \.self) { name in
                    let count = gymCounts[name]?.count ?? 0
                    if count > 0 {
                        LabeledContent(name, value: "\(count)")
                    }
                }

                let typeCounts = Dictionary(grouping: sessions, by: \.workoutType)
                ForEach(WorkoutType.allCases) { type in
                    let count = typeCounts[type]?.count ?? 0
                    if count > 0 {
                        LabeledContent(type.displayName, value: "\(count)")
                    }
                }
            }

            if sessions.count >= 2 {
                Section("Workout Frequency") {
                    WorkoutFrequencyChart(sessions: sessions)
                        .frame(height: 200)
                }
            }

            Section("Exercise Progress") {
                if allExerciseNames.isEmpty {
                    Text("Complete workouts to track progress")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Exercise", selection: $selectedExercise) {
                        Text("Select an exercise").tag(nil as String?)
                        ForEach(allExerciseNames, id: \.self) { name in
                            Text(name).tag(name as String?)
                        }
                    }
                }
            }

            if let exerciseName = selectedExercise {
                let dataPoints = exerciseDataPoints(for: exerciseName)
                if dataPoints.count >= 2 {
                    Section("Weight Progress: \(exerciseName)") {
                        ExerciseProgressChart(dataPoints: dataPoints)
                            .frame(height: 200)
                    }
                }

                Section("History: \(exerciseName)") {
                    ForEach(dataPoints.reversed()) { point in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(point.date, style: .date)
                                    .font(.subheadline)
                                Text(point.gym)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(formatWeight(point.maxWeight)) kg")
                                    .font(.subheadline.bold())
                                Text("\(point.totalSets) sets")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if point.maxWeight == dataPoints.map(\.maxWeight).max() {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Progress")
        .onAppear {
            if selectedExercise == nil, let first = allExerciseNames.first {
                selectedExercise = first
            }
        }
    }

    private func exerciseDataPoints(for name: String) -> [ExerciseDataPoint] {
        var points: [ExerciseDataPoint] = []
        for session in sessions.sorted(by: { $0.date < $1.date }) {
            for exercise in session.exercises where exercise.name == name {
                let maxWeight = exercise.sortedSets.map(\.weight).max() ?? 0
                let totalSets = exercise.sets.count
                points.append(ExerciseDataPoint(
                    date: session.date,
                    maxWeight: maxWeight,
                    totalSets: totalSets,
                    gym: session.gymName
                ))
            }
        }
        return points
    }

    private func formatWeight(_ weight: Double) -> String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", weight)
            : String(format: "%.1f", weight)
    }
}

struct ExerciseDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let maxWeight: Double
    let totalSets: Int
    let gym: String
}

struct ExerciseProgressChart: View {
    let dataPoints: [ExerciseDataPoint]

    var body: some View {
        Chart(dataPoints) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.maxWeight)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(.blue)

            PointMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.maxWeight)
            )
            .foregroundStyle(.blue)
        }
        .chartYAxisLabel("kg")
    }
}

struct WorkoutFrequencyChart: View {
    let sessions: [WorkoutSession]

    var weeklyData: [(week: Date, count: Int)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.dateInterval(of: .weekOfYear, for: session.date)?.start ?? session.date
        }
        return grouped.map { (week: $0.key, count: $0.value.count) }
            .sorted { $0.week < $1.week }
            .suffix(12)
            .map { $0 }
    }

    var body: some View {
        Chart(weeklyData, id: \.week) { item in
            BarMark(
                x: .value("Week", item.week, unit: .weekOfYear),
                y: .value("Workouts", item.count)
            )
            .foregroundStyle(.blue.gradient)
            .cornerRadius(4)
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4))
        }
    }
}
