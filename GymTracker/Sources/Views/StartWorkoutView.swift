import SwiftUI

struct StartWorkoutView: View {
    @Bindable var viewModel: WorkoutViewModel
    var onStart: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showCopyFromSheet = false
    @State private var copyFromSession: WorkoutSession?
    @State private var showTemplateSheet = false
    @State private var selectedTemplate: CustomTemplate?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Gym selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Gym")
                        .font(.headline)

                    // Preset gyms
                    HStack(spacing: 10) {
                        ForEach(GymPreset.allCases) { preset in
                            Button {
                                viewModel.isCustomGym = false
                                viewModel.selectedGymName = preset.rawValue
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: preset.icon)
                                        .font(.title2)
                                    Text(preset.displayName)
                                        .font(.subheadline.bold())
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(!viewModel.isCustomGym && viewModel.selectedGymName == preset.rawValue
                                              ? Color.blue.opacity(0.15)
                                              : Theme.Colors.cardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(!viewModel.isCustomGym && viewModel.selectedGymName == preset.rawValue
                                                ? Color.blue : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        // Other / Custom
                        Button {
                            viewModel.isCustomGym = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2)
                                Text("Other")
                                    .font(.subheadline.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(viewModel.isCustomGym
                                          ? Color.blue.opacity(0.15)
                                          : Theme.Colors.cardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(viewModel.isCustomGym ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Custom gym name input + previously used names
                    if viewModel.isCustomGym {
                        let customNames = viewModel.allUsedGymNames()
                        let fuzzyMatches = customNames.filter {
                            !viewModel.customGymName.isEmpty &&
                            $0.localizedCaseInsensitiveContains(viewModel.customGymName) &&
                            $0 != viewModel.customGymName
                        }

                        TextField("Enter gym name", text: $viewModel.customGymName)
                            .textFieldStyle(.roundedBorder)
                            .padding(.top, 4)
                            .autocorrectionDisabled()

                        // Fuzzy match suggestions
                        if !fuzzyMatches.isEmpty {
                            ForEach(fuzzyMatches, id: \.self) { match in
                                Button {
                                    viewModel.customGymName = match
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "magnifyingglass")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text("Did you mean: **\(match)**?")
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if !customNames.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(customNames, id: \.self) { name in
                                        Button {
                                            viewModel.customGymName = name
                                        } label: {
                                            Text(name)
                                                .font(.caption.bold())
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    Capsule().fill(viewModel.customGymName == name
                                                                   ? Color.blue : Theme.Colors.buttonBackground)
                                                )
                                                .foregroundStyle(viewModel.customGymName == name ? .white : .primary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }

                // Workout selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Workout")
                        .font(.headline)

                    HStack(spacing: 12) {
                        ForEach(WorkoutType.allCases) { type in
                            Button {
                                viewModel.selectedWorkoutType = type
                            } label: {
                                VStack(spacing: 8) {
                                    Text(type.rawValue)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                    Text(type.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(viewModel.selectedWorkoutType == type
                                              ? type.color.opacity(0.15)
                                              : Theme.Colors.cardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(viewModel.selectedWorkoutType == type ? type.color : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Exercise preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercises")
                        .font(.headline)

                    let templates = TemplateProvider.templates(for: viewModel.effectiveGymName, workoutType: viewModel.selectedWorkoutType)
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(Array(templates.enumerated()), id: \.offset) { index, template in
                                HStack {
                                    Text("\(index + 1).")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24)
                                    Text(template.name)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(template.defaultSets)×\(template.defaultReps)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.Colors.cardBackground)
                        )
                    }
                }

                Spacer()

                // Source indicator
                if copyFromSession != nil || selectedTemplate != nil {
                    HStack(spacing: 8) {
                        Image(systemName: selectedTemplate != nil ? "doc.text" : "doc.on.doc")
                            .font(.caption)
                        if let template = selectedTemplate {
                            Text("Template: \(template.name)")
                                .font(.caption)
                        } else if let session = copyFromSession {
                            Text("Copying from: \(session.gymName) \(session.workoutType.displayName)")
                                .font(.caption)
                        }
                        Spacer()
                        Button {
                            copyFromSession = nil
                            selectedTemplate = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.orange.opacity(0.1)))
                }

                // Start buttons
                HStack(spacing: 8) {
                    Button {
                        showCopyFromSheet = true
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.blue, lineWidth: 1.5)
                            )
                    }

                    Button {
                        showTemplateSheet = true
                    } label: {
                        Label("Template", systemImage: "doc.text")
                            .font(.caption.bold())
                            .foregroundStyle(.purple)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.purple, lineWidth: 1.5)
                            )
                    }

                    Button {
                        if let template = selectedTemplate {
                            viewModel.startWorkout(fromTemplate: template)
                        } else if let source = copyFromSession {
                            viewModel.startWorkout(copyingFrom: source)
                        } else {
                            viewModel.startWorkout()
                        }
                        onStart()
                    } label: {
                        Text("Begin")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(canStart ? .blue : .gray)
                            )
                    }
                    .disabled(!canStart)
                }
            }
            .padding()
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showCopyFromSheet) {
                CopyFromSessionSheet(viewModel: viewModel) { session in
                    copyFromSession = session
                    selectedTemplate = nil
                    showCopyFromSheet = false
                }
            }
            .sheet(isPresented: $showTemplateSheet) {
                TemplatePickerSheet(viewModel: viewModel) { template in
                    selectedTemplate = template
                    copyFromSession = nil
                    showTemplateSheet = false
                }
            }
        }
    }

    private var canStart: Bool {
        !viewModel.effectiveGymName.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

// MARK: - Copy From Session Sheet

struct CopyFromSessionSheet: View {
    @Bindable var viewModel: WorkoutViewModel
    var onSelect: (WorkoutSession) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var sessions: [WorkoutSession] = []

    var body: some View {
        NavigationStack {
            List {
                if sessions.isEmpty {
                    Text("No completed workouts yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sessions) { session in
                        Button {
                            onSelect(session)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(session.gymName)
                                        .font(.subheadline.bold())
                                    Text("·")
                                        .foregroundStyle(.secondary)
                                    Text(session.workoutType.displayName)
                                        .font(.subheadline)
                                        .foregroundStyle(session.workoutType.color)
                                }
                                HStack {
                                    Text(session.date, style: .date)
                                    Text("·")
                                    Text("\(session.exercises.count) exercises")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Copy From")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                sessions = viewModel.recentCompletedSessions()
            }
        }
    }
}

// MARK: - Template Picker Sheet

struct TemplatePickerSheet: View {
    @Bindable var viewModel: WorkoutViewModel
    var onSelect: (CustomTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var templates: [CustomTemplate] = []
    @State private var templateToDelete: CustomTemplate?
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            List {
                if templates.isEmpty {
                    ContentUnavailableView(
                        "No Templates",
                        systemImage: "doc.text",
                        description: Text("Save a template after completing a workout")
                    )
                } else {
                    ForEach(templates) { template in
                        Button {
                            onSelect(template)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(template.name)
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Text(template.workoutType.displayName)
                                        .font(.caption)
                                        .foregroundStyle(template.workoutType.color)
                                }
                                HStack {
                                    Text(template.gymName)
                                    Text("·")
                                    Text("\(template.exercises.count) exercises")
                                    Text("·")
                                    Text(template.createdDate, style: .date)
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .foregroundStyle(.primary)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                templateToDelete = template
                                showDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Delete Template?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let template = templateToDelete {
                        viewModel.deleteTemplate(template)
                        templates.removeAll { $0.id == template.id }
                        templateToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    templateToDelete = nil
                }
            } message: {
                if let template = templateToDelete {
                    Text("Delete template \"\(template.name)\"? This cannot be undone.")
                }
            }
            .onAppear {
                templates = viewModel.fetchCustomTemplates()
            }
        }
    }
}
