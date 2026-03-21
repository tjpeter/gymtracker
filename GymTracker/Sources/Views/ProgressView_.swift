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
    @State private var metricSelection: MetricSelection = .maxWeight
    @State private var exerciseSearch = ""
    @State private var timeRange: TimeRange = .all

    enum TimeRange: String, CaseIterable, Identifiable {
        case oneMonth = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case all = "All"
        var id: String { rawValue }

        var startDate: Date? {
            let cal = Calendar.current
            switch self {
            case .oneMonth: return cal.date(byAdding: .month, value: -1, to: Date())
            case .threeMonths: return cal.date(byAdding: .month, value: -3, to: Date())
            case .sixMonths: return cal.date(byAdding: .month, value: -6, to: Date())
            case .all: return nil
            }
        }
    }

    enum MetricSelection: String, CaseIterable, Identifiable {
        case maxWeight = "Max Weight"
        case volume = "Volume"
        case estimated1RM = "Est. 1RM"
        var id: String { rawValue }
    }

    var filteredSessions: [WorkoutSession] {
        var result = sessions
        if let gym = selectedGym {
            result = result.filter { $0.gymName == gym }
        }
        if let start = timeRange.startDate {
            result = result.filter { $0.date >= start }
        }
        return result
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

    /// Groups exercises by which workout type(s) they appear in
    var exercisesByWorkoutType: [(label: String, color: Color, names: [String])] {
        var typeMap: [String: Set<WorkoutType>] = [:]
        var counts: [String: Int] = [:]
        for session in filteredSessions {
            for exercise in session.exercises {
                typeMap[exercise.name, default: []].insert(session.workoutType)
                counts[exercise.name, default: 0] += 1
            }
        }
        let sortByFrequency: ([String]) -> [String] = { names in
            names.sorted { (counts[$0] ?? 0) > (counts[$1] ?? 0) }
        }
        var groups: [(label: String, color: Color, names: [String])] = []
        let aOnly = typeMap.filter { $0.value == [.a] }.map(\.key)
        let bOnly = typeMap.filter { $0.value == [.b] }.map(\.key)
        let both = typeMap.filter { $0.value.count > 1 }.map(\.key)
        if !aOnly.isEmpty { groups.append((label: "Workout A", color: WorkoutType.a.color, names: sortByFrequency(aOnly))) }
        if !bOnly.isEmpty { groups.append((label: "Workout B", color: WorkoutType.b.color, names: sortByFrequency(bOnly))) }
        if !both.isEmpty { groups.append((label: "Both A & B", color: .purple, names: sortByFrequency(both))) }
        return groups
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
            // Time range filter
            Section {
                Picker("Time Range", selection: $timeRange) {
                    ForEach(TimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

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

            if filteredSessions.count >= 2 {
                Section("Workout Frequency") {
                    WorkoutFrequencyChart(sessions: filteredSessions)
                        .frame(height: 200)
                }

                Section("Workout Duration") {
                    let durationData = filteredSessions
                        .filter { $0.durationMinutes != nil }
                        .sorted { $0.date < $1.date }
                    if durationData.count >= 2 {
                        Chart(durationData) { session in
                            AreaMark(
                                x: .value("Date", session.date),
                                y: .value("Minutes", session.durationMinutes ?? 0)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.2), Color.green.opacity(0.02)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            LineMark(
                                x: .value("Date", session.date),
                                y: .value("Minutes", session.durationMinutes ?? 0)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(.green)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                            PointMark(
                                x: .value("Date", session.date),
                                y: .value("Minutes", session.durationMinutes ?? 0)
                            )
                            .foregroundStyle(.green)
                        }
                        .chartYAxisLabel("minutes")
                        .frame(height: 200)
                    } else {
                        Text("Complete more workouts to see duration trends")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
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
                }
            } header: {
                Text("Exercise Progress")
            }

            if !allExerciseNames.isEmpty {
                let groups = exercisesByWorkoutType
                ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                    let filtered = exerciseSearch.isEmpty
                        ? group.names
                        : group.names.filter { $0.localizedCaseInsensitiveContains(exerciseSearch) }
                    if !filtered.isEmpty {
                        Section {
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
                                                .foregroundStyle(group.color)
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                        } header: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(group.color)
                                    .frame(width: 8, height: 8)
                                Text(group.label)
                            }
                        }
                    }
                }
            }

            if let exerciseName = selectedExercise {
                let dataPoints = exerciseDataPoints(for: exerciseName)
                if dataPoints.count >= 2 {
                    Section {
                        Picker("Metric", selection: $metricSelection) {
                            ForEach(MetricSelection.allCases) { metric in
                                Text(metric.rawValue).tag(metric)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                        ExerciseProgressChart(dataPoints: dataPoints, metricSelection: metricSelection)
                            .frame(height: 200)

                        // Plateau detection
                        if dataPoints.count >= 4 {
                            let recentWeights = dataPoints.suffix(4).map(\.maxWeight)
                            let maxRecent = recentWeights.max() ?? 0
                            let minRecent = recentWeights.min() ?? 0
                            if maxRecent - minRecent < 1.0 {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                    Text("Plateau — no weight increase in last \(min(dataPoints.count, 4)) sessions")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } header: {
                        Text("\(metricSelection.rawValue) Progress: \(exerciseName)")
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
                // Epley formula: weight × (1 + reps/30)
                let best1RM = workingSets.map { $0.weight * (1.0 + Double($0.reps) / 30.0) }.max() ?? 0
                points.append(ExerciseDataPoint(
                    date: session.date,
                    maxWeight: maxWeight,
                    totalSets: totalSets,
                    volume: volume,
                    estimated1RM: best1RM,
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
    let estimated1RM: Double
    let gym: String
}

struct ExerciseProgressChart: View {
    let dataPoints: [ExerciseDataPoint]
    var metricSelection: ProgressView_.MetricSelection = .maxWeight

    private func metricValue(_ point: ExerciseDataPoint) -> Double {
        switch metricSelection {
        case .maxWeight: return point.maxWeight
        case .volume: return point.volume
        case .estimated1RM: return point.estimated1RM
        }
    }

    private var prValue: Double {
        dataPoints.map { metricValue($0) }.max() ?? 0
    }

    private var trendDirection: TrendDirection {
        guard dataPoints.count >= 2 else { return .flat }
        let recent = Array(dataPoints.suffix(3))
        let older = Array(dataPoints.prefix(max(1, dataPoints.count - 3)))
        let recentAvg = recent.map { metricValue($0) }.reduce(0, +) / Double(recent.count)
        let olderAvg = older.map { metricValue($0) }.reduce(0, +) / Double(older.count)
        let diff = recentAvg - olderAvg
        if diff > olderAvg * 0.02 { return .up }
        if diff < -olderAvg * 0.02 { return .down }
        return .flat
    }

    private var chartColor: Color {
        switch metricSelection {
        case .maxWeight: return .blue
        case .volume: return .orange
        case .estimated1RM: return .purple
        }
    }

    var body: some View {
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
                    let yValue = metricValue(point)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value(metricSelection.rawValue, yValue)
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
                        y: .value(metricSelection.rawValue, yValue)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(chartColor)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value(metricSelection.rawValue, yValue)
                    )
                    .foregroundStyle(chartColor)
                }

                // PR reference line
                RuleMark(y: .value("PR", prValue))
                    .foregroundStyle(.yellow.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("PR \(metricSelection == .volume ? "\(Int(prValue))" : prValue.formattedWeight)")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                            .monospacedDigit()
                    }
            }
            .chartYAxisLabel("kg")
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
