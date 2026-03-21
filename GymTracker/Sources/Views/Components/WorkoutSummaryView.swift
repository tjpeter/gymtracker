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
        let avgRPE: Double?
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
            let volume = exercise.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            let isPR = exercise.previousWeight.map { maxWeight > $0 } ?? false
            let rpeValues = workingSets.compactMap(\.rpe)
            let avgRPE = rpeValues.isEmpty ? nil : rpeValues.reduce(0, +) / Double(rpeValues.count)

            return ExerciseSummary(
                name: exercise.name,
                workingSets: workingSets.count,
                completedSets: completedSets.count,
                maxWeight: maxWeight,
                totalVolume: volume,
                previousMaxWeight: exercise.previousWeight,
                isPR: isPR,
                avgRPE: avgRPE
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
    var session: WorkoutSession?
    let onDismiss: () -> Void
    @State private var heroScale: CGFloat = 0.5
    @State private var heroOpacity: Double = 0
    @State private var sessionRating: Int = 0
    @State private var showSaveTemplate = false
    @State private var templateName = ""
    @State private var templateSaved = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.green)
                            .scaleEffect(heroScale)
                            .opacity(heroOpacity)

                        Text("Workout Complete!")
                            .font(.title2.bold())
                            .opacity(heroOpacity)

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

                    // Session rating
                    VStack(spacing: 6) {
                        Text("How was your workout?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    sessionRating = sessionRating == star ? 0 : star
                                    session?.rating = sessionRating > 0 ? sessionRating : nil
                                    try? session?.modelContext?.save()
                                } label: {
                                    Image(systemName: star <= sessionRating ? "star.fill" : "star")
                                        .font(.title2)
                                        .foregroundStyle(star <= sessionRating ? .yellow : .secondary.opacity(0.4))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 4)

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
                                    if let avgRPE = exercise.avgRPE {
                                        Text("RPE \(String(format: "%.1f", avgRPE))")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Theme.Colors.cardBackground)
                            )
                            .padding(.horizontal)
                        }
                    }
                    // Save as template
                    if session != nil {
                        Button {
                            templateName = "\(summary.gymName) \(summary.workoutType.displayName)"
                            showSaveTemplate = true
                        } label: {
                            Label(templateSaved ? "Template Saved" : "Save as Template", systemImage: templateSaved ? "checkmark.circle.fill" : "square.and.arrow.down")
                                .font(.subheadline.bold())
                                .foregroundStyle(templateSaved ? .green : .blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill((templateSaved ? Color.green : Color.blue).opacity(0.1))
                                )
                        }
                        .disabled(templateSaved)
                        .padding(.horizontal)
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
            .alert("Save as Template", isPresented: $showSaveTemplate) {
                TextField("Template name", text: $templateName)
                Button("Save") {
                    if let session = session, !templateName.isEmpty {
                        saveTemplate(session: session, name: templateName)
                        withAnimation { templateSaved = true }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Save this workout's exercises as a reusable template.")
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    heroScale = 1.0
                    heroOpacity = 1.0
                }
                sessionRating = session?.rating ?? 0
            }
        }
    }

    private func saveTemplate(session: WorkoutSession, name: String) {
        guard let context = session.modelContext else { return }
        let template = CustomTemplate(name: name, gymName: session.gymName, workoutType: session.workoutType)
        for (index, exercise) in session.sortedExercises.enumerated() {
            let maxWeight = exercise.sortedSets.map(\.weight).max() ?? 0
            let firstReps = exercise.sortedSets.first?.reps ?? 10
            let te = TemplateExercise(
                name: exercise.name,
                machineName: exercise.machineName,
                order: index,
                sets: exercise.sets.count,
                reps: firstReps,
                weight: maxWeight
            )
            te.template = template
            template.exercises.append(te)
        }
        context.insert(template)
        try? context.save()
    }

    private func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "'"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: volume)) ?? "\(Int(volume))"
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
