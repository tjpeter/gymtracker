import SwiftUI
import SwiftData
import Charts

struct BodyWeightView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyWeightEntry.date, order: .reverse) private var entries: [BodyWeightEntry]
    @State private var showAddEntry = false
    @State private var newWeight: Double = 85.0
    @State private var newDate = Date()
    @State private var newNotes = ""

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
            if entries.count >= 2 {
                Section("Trend") {
                    let sorted = entries.sorted { $0.date < $1.date }
                    Chart(sorted) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.weight)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.orange)

                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(.orange)
                    }
                    .chartYAxisLabel("kg")
                    .frame(height: 200)
                }
            }

            // Current stats
            if let latest = entries.first {
                Section("Current") {
                    LabeledContent("Latest Weight") {
                        Text("\(latest.weight.formattedWeight) kg")
                            .font(.headline)
                    }
                    LabeledContent("Date") {
                        Text(latest.date, style: .date)
                    }
                    if entries.count >= 2 {
                        let oldest = entries.last!
                        let change = latest.weight - oldest.weight
                        LabeledContent("Change (all time)") {
                            Text("\(change >= 0 ? "+" : "")\(change.formattedWeight) kg")
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
                            Text("\(entry.weight.formattedWeight) kg")
                                .font(.subheadline.bold())
                        }
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
                        DatePicker("Date", selection: $newDate, displayedComponents: .date)
                    }
                    Section {
                        TextField("Notes (optional)", text: $newNotes)
                    }
                }
                .navigationTitle("Log Weight")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showAddEntry = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let entry = BodyWeightEntry(date: newDate, weight: newWeight, notes: newNotes)
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
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
        try? modelContext.save()
    }
}
