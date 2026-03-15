import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(
        filter: #Predicate<WorkoutSession> { $0.isCompleted == true },
        sort: \WorkoutSession.date,
        order: .reverse
    ) private var sessions: [WorkoutSession]
    @Query(sort: \BodyWeightEntry.date) private var bodyWeightEntries: [BodyWeightEntry]
    @Bindable var viewModel: WorkoutViewModel
    @State private var filterGymName: String?
    @State private var filterWorkout: WorkoutType?
    @State private var sessionToDelete: WorkoutSession?
    @State private var showDeleteAlert = false
    @State private var showExportSheet = false
    @State private var exportFileURL: URL?

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
            return true
        }
    }

    var body: some View {
        List {
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
                            FilterChip(title: type.displayName, isSelected: filterWorkout == type) {
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
                                    .foregroundStyle(.secondary)
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
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(sessions.isEmpty)
            }
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportFileURL {
                ShareSheet(activityItems: [url])
                    .presentationDetents([.medium, .large])
            }
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

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(isSelected ? Color.blue : Color(.systemGray5))
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.borderless)
    }
}
