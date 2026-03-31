import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<WorkoutSession> { $0.isCompleted == true },
        sort: \WorkoutSession.date,
        order: .reverse
    ) private var sessions: [WorkoutSession]
    @Query(sort: \BodyWeightEntry.date) private var bodyWeightEntries: [BodyWeightEntry]
    @Bindable var viewModel: WorkoutViewModel
    @State private var filterGymName: String?
    @State private var filterWorkout: WorkoutType?
    @State private var timeRange: HistoryTimeRange = .all
    @State private var sessionToDelete: WorkoutSession?
    @State private var showDeleteAlert = false
    @State private var showExportSheet = false
    @State private var exportFileURL: URL?
    @State private var showImportPicker = false
    @State private var importAlertMessage: String?
    @State private var showImportAlert = false

    var allGymNames: [String] {
        var names: [String] = []
        var seen = Set<String>()
        for session in sessions {
            if !seen.contains(session.gymName) {
                names.append(session.gymName)
                seen.insert(session.gymName)
            }
        }
        return names.sorted()
    }

    var filteredSessions: [WorkoutSession] {
        sessions.filter { session in
            if let gym = filterGymName, session.gymName != gym { return false }
            if let workout = filterWorkout, session.workoutType != workout { return false }
            if let start = timeRange.startDate, session.date < start { return false }
            return true
        }
    }

    var body: some View {
        List {
            // Time range
            Section {
                Picker("Time Range", selection: $timeRange) {
                    ForEach(HistoryTimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Filters
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All Gyms", isSelected: filterGymName == nil) {
                            filterGymName = nil
                        }
                        ForEach(allGymNames, id: \.self) { name in
                            FilterChip(title: name, isSelected: filterGymName == name) {
                                filterGymName = filterGymName == name ? nil : name
                            }
                        }

                        Divider().frame(height: 24)

                        FilterChip(title: "All", isSelected: filterWorkout == nil) {
                            filterWorkout = nil
                        }
                        ForEach(WorkoutType.allCases) { type in
                            FilterChip(title: type.displayName, isSelected: filterWorkout == type, color: type.color) {
                                filterWorkout = filterWorkout == type ? nil : type
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

            // Sessions
            if filteredSessions.isEmpty {
                ContentUnavailableView("No Workouts", systemImage: "tray", description: Text("Complete a workout to see it here"))
            } else {
                ForEach(filteredSessions) { session in
                    NavigationLink {
                        WorkoutDetailView(session: session)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(session.gymName)
                                    .font(.subheadline.bold())
                                Text("·")
                                    .foregroundStyle(.secondary)
                                Text(session.workoutType.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(session.workoutType.color)
                                Spacer()
                            }
                            HStack {
                                Text(session.date, style: .date)
                                Text("at")
                                Text(session.date, style: .time)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            HStack {
                                Text("\(session.exercises.count) exercises")
                                if let duration = session.durationMinutes {
                                    Text("·")
                                    Text("\(duration) min")
                                }
                                if let rating = session.rating, rating > 0 {
                                    Text("·")
                                    HStack(spacing: 1) {
                                        ForEach(1...rating, id: \.self) { _ in
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 8))
                                                .foregroundStyle(.yellow)
                                        }
                                    }
                                }
                            }
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            sessionToDelete = session
                            showDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        exportFileURL = DataExporter.createCSVFile(sessions: sessions, bodyWeightEntries: bodyWeightEntries)
                        if exportFileURL != nil { showExportSheet = true }
                    } label: {
                        Label("Export CSV", systemImage: "tablecells")
                    }
                    Button {
                        exportFileURL = DataExporter.createJSONFile(sessions: sessions, bodyWeightEntries: bodyWeightEntries)
                        if exportFileURL != nil { showExportSheet = true }
                    } label: {
                        Label("Export JSON", systemImage: "curlybraces")
                    }
                    Divider()
                    Button {
                        showImportPicker = true
                    } label: {
                        Label("Restore from Backup", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportFileURL {
                ShareSheet(activityItems: [url])
                    .presentationDetents([.medium, .large])
            }
        }
        .fileImporter(isPresented: $showImportPicker, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                guard url.startAccessingSecurityScopedResource() else {
                    importAlertMessage = "Could not access the selected file."
                    showImportAlert = true
                    return
                }
                defer { url.stopAccessingSecurityScopedResource() }
                do {
                    let data = try Data(contentsOf: url)
                    let importResult = try DataExporter.importJSON(from: data, context: modelContext)
                    var parts: [String] = []
                    if importResult.sessionsImported > 0 {
                        parts.append("\(importResult.sessionsImported) workout\(importResult.sessionsImported == 1 ? "" : "s")")
                    }
                    if importResult.bodyWeightImported > 0 {
                        parts.append("\(importResult.bodyWeightImported) body weight entr\(importResult.bodyWeightImported == 1 ? "y" : "ies")")
                    }
                    if parts.isEmpty {
                        importAlertMessage = "No new data to import. All entries already exist."
                    } else {
                        importAlertMessage = "Imported \(parts.joined(separator: " and "))."
                    }
                    if importResult.sessionsSkipped > 0 || importResult.bodyWeightSkipped > 0 {
                        importAlertMessage! += " Skipped \(importResult.sessionsSkipped + importResult.bodyWeightSkipped) duplicate(s)."
                    }
                } catch {
                    importAlertMessage = error.localizedDescription
                }
                showImportAlert = true
            case .failure(let error):
                importAlertMessage = error.localizedDescription
                showImportAlert = true
            }
        }
        .alert("Import", isPresented: $showImportAlert) {
            Button("OK") { importAlertMessage = nil }
        } message: {
            Text(importAlertMessage ?? "")
        }
        .alert("Delete Workout?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let session = sessionToDelete {
                    viewModel.deleteWorkout(session)
                    sessionToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                sessionToDelete = nil
            }
        } message: {
            if let session = sessionToDelete {
                Text("Delete \(session.gymName) \(session.workoutType.displayName) from \(session.date.formatted(date: .abbreviated, time: .omitted))? This cannot be undone.")
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

enum HistoryTimeRange: String, CaseIterable, Identifiable {
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

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(isSelected ? color : Theme.Colors.buttonBackground)
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.borderless)
    }
}
