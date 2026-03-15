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
    @State private var exerciseSearch = ""

    var filteredSessions: [WorkoutSession] {
        guard let gym = selectedGym else { return sessions }
        return sessions.filter { $0.gymName == gym }
    }

    var allExerciseNames: [String] {
        var counts: [String: Int] = [:]
        for session in filteredSessions {
            for exercise in session.exercises {
                counts[exercise.name, default: 0] += 1
            }
        }
        return counts.sorted { $0.value > $1.value }.map(\.key)
    }

    func exerciseFrequency(_ name: String) -> Int {
        filteredSessions.reduce(0) { count, session in
            count + (session.exercises.contains { $0.name == name } ? 1 : 0)
        }
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
                    TextField("Search exercises", text: $exerciseSearch)
                        .textFieldStyle(.roundedBorder)

                    let filtered = exerciseSearch.isEmpty
                        ? allExerciseNames
                        : allExerciseNames.filter { $0.localizedCaseInsensitiveContains(exerciseSearch) }
                    ForEach(filtered, id: \.self) { name in
                        Button {
                            selectedExercise = name
                            exerciseSearch = ""
                        } label: {
                            HStack {
                                Text(name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("×\(exerciseFrequency(name))")
                                    .font(.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                if selectedExercise == name {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                        .font(.caption)
                                }
                            }
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
                                    .monospacedDigit()
                                HStack(spacing: 4) {
                                    Text("\(point.totalSets) sets")
                                    Text("·")
                                    Text("\(Int(point.volume)) kg vol")
                                }
                                .font(.caption)
                                .monospacedDigit()
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
            if selectedExercise == nil, let mostTrained = allExerciseNames.first {
                selectedExercise = mostTrained
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

    private var prValue: Double {
        dataPoints.map { showVolume ? $0.volume : $0.maxWeight }.max() ?? 0
    }

    private var trendDirection: TrendDirection {
        guard dataPoints.count >= 2 else { return .flat }
        let recent = Array(dataPoints.suffix(3))
        let older = Array(dataPoints.prefix(max(1, dataPoints.count - 3)))
        let recentAvg = recent.map { showVolume ? $0.volume : $0.maxWeight }.reduce(0, +) / Double(recent.count)
        let olderAvg = older.map { showVolume ? $0.volume : $0.maxWeight }.reduce(0, +) / Double(older.count)
        let diff = recentAvg - olderAvg
        if diff > olderAvg * 0.02 { return .up }
        if diff < -olderAvg * 0.02 { return .down }
        return .flat
    }

    var body: some View {
        let chartColor: Color = showVolume ? .orange : .blue
        VStack(alignment: .trailing, spacing: 4) {
            // Trend badge
            HStack(spacing: 4) {
                Image(systemName: trendDirection.icon)
                    .font(.caption2)
                Text(trendDirection.label)
                    .font(.caption2.bold())
            }
            .foregroundStyle(trendDirection.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(trendDirection.color.opacity(0.12)))

            Chart {
                ForEach(dataPoints) { point in
                    let yValue = showVolume ? point.volume : point.maxWeight

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value(showVolume ? "Volume" : "Weight", yValue)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [chartColor.opacity(0.2), chartColor.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(showVolume ? "Volume" : "Weight", yValue)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(chartColor)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value(showVolume ? "Volume" : "Weight", yValue)
                    )
                    .foregroundStyle(chartColor)
                }

                // PR reference line
                RuleMark(y: .value("PR", prValue))
                    .foregroundStyle(.yellow.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("PR \(showVolume ? "\(Int(prValue))" : prValue.formattedWeight)")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                            .monospacedDigit()
                    }
            }
            .chartYAxisLabel(showVolume ? "kg total" : "kg")
        }
    }
}

enum TrendDirection {
    case up, down, flat

    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .flat: return "arrow.right"
        }
    }

    var label: String {
        switch self {
        case .up: return "Trending up"
        case .down: return "Trending down"
        case .flat: return "Stable"
        }
    }

    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .flat: return .secondary
        }
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
