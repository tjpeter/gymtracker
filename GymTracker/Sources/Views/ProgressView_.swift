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
    @State private var selectedGym: String?
    @State private var showVolume = false

    var filteredSessions: [WorkoutSession] {
        guard let gym = selectedGym else { return sessions }
        return sessions.filter { $0.gymName == gym }
    }

    var allExerciseNames: [String] {
        var names = Set<String>()
        for session in filteredSessions {
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
                if allGymNames.count > 1 {
                    Picker("Gym", selection: $selectedGym) {
                        Text("All Gyms").tag(nil as String?)
                        ForEach(allGymNames, id: \.self) { name in
                            Text(name).tag(name as String?)
                        }
                    }
                }

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
                    Section {
                        Picker("Metric", selection: $showVolume) {
                            Text("Max Weight").tag(false)
                            Text("Volume").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                        ExerciseProgressChart(dataPoints: dataPoints, showVolume: showVolume)
                            .frame(height: 200)
                    } header: {
                        Text("\(showVolume ? "Volume" : "Weight") Progress: \(exerciseName)")
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
                                Text("\(point.maxWeight.formattedWeight) kg")
                                    .font(.subheadline.bold())
                                HStack(spacing: 4) {
                                    Text("\(point.totalSets) sets")
                                    Text("·")
                                    Text("\(Int(point.volume)) kg vol")
                                }
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
        for session in filteredSessions.sorted(by: { $0.date < $1.date }) {
            for exercise in session.exercises where exercise.name == name {
                let workingSets = exercise.sortedSets.filter { !$0.isWarmup }
                let maxWeight = workingSets.map(\.weight).max() ?? exercise.sortedSets.map(\.weight).max() ?? 0
                let totalSets = workingSets.count
                let volume = workingSets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
                points.append(ExerciseDataPoint(
                    date: session.date,
                    maxWeight: maxWeight,
                    totalSets: totalSets,
                    volume: volume,
                    gym: session.gymName
                ))
            }
        }
        return points
    }
}

struct ExerciseDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let maxWeight: Double
    let totalSets: Int
    let volume: Double
    let gym: String
}

struct ExerciseProgressChart: View {
    let dataPoints: [ExerciseDataPoint]
    var showVolume = false

    var body: some View {
        Chart(dataPoints) { point in
            let yValue = showVolume ? point.volume : point.maxWeight
            LineMark(
                x: .value("Date", point.date),
                y: .value(showVolume ? "Volume" : "Weight", yValue)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(showVolume ? .orange : .blue)

            PointMark(
                x: .value("Date", point.date),
                y: .value(showVolume ? "Volume" : "Weight", yValue)
            )
            .foregroundStyle(showVolume ? .orange : .blue)
        }
        .chartYAxisLabel(showVolume ? "kg total" : "kg")
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
