import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<WorkoutSession> { $0.isCompleted == true },
        sort: \WorkoutSession.date,
        order: .reverse
    ) private var completedSessions: [WorkoutSession]
    @State private var workoutVM = WorkoutViewModel()
    @State private var showStartWorkout = false
    @State private var navigateToSession = false
    @State private var hasCheckedResume = false

    var totalWorkouts: Int { completedSessions.count }

    var lastWorkoutText: String {
        guard let last = completedSessions.first else { return "No workouts yet" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return "\(last.gymName) · \(last.workoutType.displayName) · \(formatter.localizedString(for: last.date, relativeTo: Date()))"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Resume banner (if incomplete workout exists)
                    if workoutVM.isWorkoutActive {
                        Button {
                            navigateToSession = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.uturn.forward.circle.fill")
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Resume Workout")
                                        .font(.headline)
                                    if let session = workoutVM.currentSession {
                                        Text("\(session.gymName) · \(session.workoutType.displayName)")
                                            .font(.caption)
                                            .opacity(0.8)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.orange.gradient)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Hero card - Start Workout
                    Button {
                        showStartWorkout = true
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 44))
                                .foregroundStyle(.white)
                            Text("Start Workout")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            if totalWorkouts > 0 {
                                Text(lastWorkoutText)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.blue.gradient)
                        )
                    }
                    .buttonStyle(.plain)

                    // Stats row
                    if totalWorkouts > 0 {
                        HStack(spacing: 12) {
                            StatCard(title: "Total", value: "\(totalWorkouts)", icon: "flame.fill", color: .orange)
                            StatCard(title: "This Week", value: "\(workoutsThisWeek)", icon: "calendar", color: .green)
                            StatCard(title: "Streak", value: "\(currentStreak)", icon: "bolt.fill", color: .purple)
                        }
                    }

                    // Quick links
                    VStack(spacing: 12) {
                        NavigationLink {
                            HistoryView(viewModel: workoutVM)
                        } label: {
                            QuickLinkRow(icon: "clock.fill", title: "History", subtitle: "\(totalWorkouts) workouts logged", color: .blue)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ProgressView_()
                        } label: {
                            QuickLinkRow(icon: "chart.line.uptrend.xyaxis", title: "Progress", subtitle: "Track your gains", color: .green)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            BodyWeightView()
                        } label: {
                            QuickLinkRow(icon: "scalemass.fill", title: "Body Weight", subtitle: "Track your weight", color: .orange)
                        }
                        .buttonStyle(.plain)
                    }

                    // Recent workouts
                    if !completedSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Workouts")
                                .font(.headline)
                                .padding(.horizontal, 4)

                            ForEach(completedSessions.prefix(3)) { session in
                                NavigationLink {
                                    WorkoutDetailView(session: session)
                                } label: {
                                    RecentWorkoutRow(session: session)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("GymTracker")
            .sheet(isPresented: $showStartWorkout) {
                StartWorkoutView(viewModel: workoutVM, onStart: {
                    showStartWorkout = false
                    navigateToSession = true
                })
            }
            .navigationDestination(isPresented: $navigateToSession) {
                WorkoutSessionView(viewModel: workoutVM)
            }
            .onAppear {
                workoutVM.setModelContext(modelContext)
                // Import historical data on first launch
                HistoryDataImporter.importIfNeeded(context: modelContext)
                // Check for incomplete workout to resume
                if !hasCheckedResume {
                    hasCheckedResume = true
                    _ = workoutVM.resumeIncompleteWorkout()
                }
            }
        }
    }

    private var workoutsThisWeek: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return completedSessions.filter { $0.date >= startOfWeek }.count
    }

    private var currentStreak: Int {
        guard !completedSessions.isEmpty else { return 0 }
        let calendar = Calendar.current
        var streak = 0
        var weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()

        for _ in 0..<52 {
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
            let hasWorkout = completedSessions.contains { $0.date >= weekStart && $0.date < weekEnd }
            if hasWorkout {
                streak += 1
            } else if streak > 0 {
                break
            }
            weekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart)!
        }
        return streak
    }
}

// MARK: - Subviews

struct StatCard: View {
    let title: String
    let value: String
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
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
        )
    }
}

struct QuickLinkRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
        )
    }
}

struct RecentWorkoutRow: View {
    let session: WorkoutSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(session.gymName) · \(session.workoutType.displayName)")
                    .font(.subheadline.bold())
                Text(session.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(session.exercises.count) exercises")
                .font(.caption)
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}
