import SwiftUI
import SwiftData
import Charts

struct BodyWeightView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyWeightEntry.date, order: .reverse) private var entries: [BodyWeightEntry]
    @State private var showAddEntry = false
    @State private var newWeight: Double = 93.0
    /// 0 means "not entered" — saved as nil so waist stays optional.
    @State private var newWaist: Double = 0
    @State private var newDate = Date()
    @State private var newNotes = ""
    @State private var chartMetric: BodyMetric = .weight

    private enum BodyMetric: String, CaseIterable, Identifiable {
        case weight = "Weight"
        case waist = "Waist"
        var id: String { rawValue }
        var unit: String { self == .weight ? "kg" : "cm" }
        var color: Color { self == .weight ? .orange : .teal }
    }

    var body: some View {
        List {
            // Add button
            Section {
                Button {
                    showAddEntry = true
                } label: {
                    Label("Log Weight", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
            }

            // Chart
            let metricEntries = entries
                .filter { metricValue($0) != nil }
                .sorted { $0.date < $1.date }
            if entries.count >= 2 {
                Section {
                    Picker("Metric", selection: $chartMetric) {
                        ForEach(BodyMetric.allCases) { metric in
                            Text(metric.rawValue).tag(metric)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)

                    if metricEntries.count >= 2 {
                    let values = metricEntries.compactMap(metricValue)
                    let minV = (values.min() ?? 0) - 1
                    let maxV = (values.max() ?? 100) + 1
                    let movingAvg = movingAverage(metricEntries, window: 7)
                    let color = chartMetric.color
                    Chart {
                        ForEach(metricEntries) { entry in
                            let v = metricValue(entry) ?? 0
                            AreaMark(
                                x: .value("Date", entry.date),
                                y: .value(chartMetric.rawValue, v)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [color.opacity(0.2), color.opacity(0.02)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                            LineMark(
                                x: .value("Date", entry.date),
                                y: .value(chartMetric.rawValue, v)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(color.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1.5))
                            .symbol(.circle)
                            .symbolSize(20)

                            PointMark(
                                x: .value("Date", entry.date),
                                y: .value(chartMetric.rawValue, v)
                            )
                            .foregroundStyle(color.opacity(0.5))
                            .symbolSize(15)
                        }

                        ForEach(movingAvg, id: \.date) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value(chartMetric.rawValue, point.value),
                                series: .value("Series", "7-day avg")
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(.blue)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                        }
                    }
                    .chartYScale(domain: minV...maxV)
                    .chartYAxisLabel(chartMetric.unit)
                    .chartForegroundStyleScale([
                        "Daily": color.opacity(0.5),
                        "7-day avg": Color.blue
                    ])
                    .frame(height: 200)
                    } else {
                        Text("Not enough \(chartMetric.rawValue.lowercased()) entries yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
                    }
                } header: {
                    Text("Trend")
                }
            }

            // Current stats
            if let latest = entries.first {
                Section("Current") {
                    LabeledContent("Latest Weight") {
                        Text("\(latest.weight.formattedWeight) kg")
                            .font(.headline)
                            .monospacedDigit()
                    }
                    if let latestWaist = entries.first(where: { $0.waist != nil })?.waist {
                        LabeledContent("Latest Waist") {
                            Text("\(latestWaist.formattedWeight) cm")
                                .font(.headline)
                                .monospacedDigit()
                        }
                    }
                    LabeledContent("Date") {
                        Text(latest.date, style: .date)
                    }
                    if entries.count >= 2 {
                        let oldest = entries.last!
                        let change = latest.weight - oldest.weight
                        LabeledContent("Change (all time)") {
                            Text("\(change >= 0 ? "+" : "")\(change.formattedWeight) kg")
                                .monospacedDigit()
                        }
                    }
                }
            }

            // History
            Section("History") {
                if entries.isEmpty {
                    Text("No entries yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entries) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.date, style: .date)
                                    .font(.subheadline)
                                if !entry.notes.isEmpty {
                                    Text(entry.notes)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(entry.weight.formattedWeight) kg")
                                    .font(.subheadline.bold())
                                    .monospacedDigit()
                                if let waist = entry.waist {
                                    Text("\(waist.formattedWeight) cm")
                                        .font(.caption)
                                        .foregroundStyle(Color.teal)
                                        .monospacedDigit()
                                }
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel({
                            let formatter = DateFormatter()
                            formatter.dateStyle = .long
                            formatter.timeStyle = .none
                            let waistText = entry.waist.map { ", waist \($0.formattedWeight) cm" } ?? ""
                            return "Weight \(entry.weight.formattedWeight) kg\(waistText) on \(formatter.string(from: entry.date))"
                        }())
                    }
                    .onDelete(perform: deleteEntries)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Body Weight")
        .sheet(isPresented: $showAddEntry) {
            NavigationStack {
                Form {
                    Section {
                        HStack {
                            Text("Weight")
                            Spacer()
                            TextField("kg", value: $newWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("kg")
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Waist")
                            Spacer()
                            TextField("optional", value: $newWaist, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("cm")
                                .foregroundStyle(.secondary)
                        }
                        DatePicker("Date", selection: $newDate, displayedComponents: .date)
                    }
                    Section {
                        TextField("Notes (optional)", text: $newNotes)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .navigationTitle("Log Weight")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .fontWeight(.semibold)
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showAddEntry = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let entry = BodyWeightEntry(date: newDate, weight: newWeight, waist: newWaist > 0 ? newWaist : nil, notes: newNotes)
                            modelContext.insert(entry)
                            try? modelContext.save()
                            newNotes = ""
                            showAddEntry = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .onAppear {
            if let latest = entries.first {
                newWeight = latest.weight
            }
            if let latestWaist = entries.first(where: { $0.waist != nil })?.waist {
                newWaist = latestWaist
            }
        }
    }

    /// The value of the currently selected chart metric for an entry, or nil
    /// when the entry doesn't track that metric (e.g. an old entry without waist).
    private func metricValue(_ entry: BodyWeightEntry) -> Double? {
        switch chartMetric {
        case .weight: return entry.weight
        case .waist: return entry.waist
        }
    }

    private struct MovingAvgPoint {
        let date: Date
        let value: Double
    }

    /// Moving average over the selected metric. `sorted` must already be filtered
    /// to entries that have a value for the current metric and sorted ascending.
    private func movingAverage(_ sorted: [BodyWeightEntry], window: Int) -> [MovingAvgPoint] {
        guard sorted.count >= 2 else { return [] }
        var result: [MovingAvgPoint] = []
        for (i, entry) in sorted.enumerated() {
            let windowStart = Calendar.current.date(byAdding: .day, value: -(window - 1), to: entry.date)!
            let windowEntries = sorted[0...i].filter { $0.date >= windowStart }
            let vals = windowEntries.compactMap(metricValue)
            guard !vals.isEmpty else { continue }
            let avg = vals.reduce(0, +) / Double(vals.count)
            result.append(MovingAvgPoint(date: entry.date, value: avg))
        }
        return result
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
        try? modelContext.save()
    }
}
