import SwiftUI
import SwiftData

/// Review screen for captured bugs and ideas. Open items are listed first;
/// resolved ones are tucked into a collapsible section. Everything can be shared
/// as plain text so the list can be handed off for fixing/implementing.
struct FeedbackView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FeedbackItem.createdDate, order: .reverse) private var items: [FeedbackItem]
    @State private var showCapture = false
    @State private var showResolved = false
    @State private var shareText: ShareableText?

    private var openItems: [FeedbackItem] { items.filter { !$0.isResolved } }
    private var resolvedItems: [FeedbackItem] { items.filter { $0.isResolved } }

    var body: some View {
        List {
            Section {
                Button {
                    showCapture = true
                } label: {
                    Label("New Note", systemImage: "square.and.pencil")
                        .font(.headline)
                }
            }

            if items.isEmpty {
                ContentUnavailableView(
                    "No Notes Yet",
                    systemImage: "lightbulb",
                    description: Text("Jot down bugs and ideas as they come to you in the gym.")
                )
            } else {
                Section("Open (\(openItems.count))") {
                    if openItems.isEmpty {
                        Text("All caught up 🎉")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(openItems) { item in
                            FeedbackRow(item: item)
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    resolveButton(item)
                                }
                                .swipeActions(edge: .trailing) {
                                    deleteButton(item)
                                }
                        }
                    }
                }

                if !resolvedItems.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $showResolved) {
                            ForEach(resolvedItems) { item in
                                FeedbackRow(item: item)
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        resolveButton(item)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        deleteButton(item)
                                    }
                            }
                        } label: {
                            Text("Resolved (\(resolvedItems.count))")
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notes & Ideas")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    shareText = ShareableText(text: exportText())
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(items.isEmpty)
                .accessibilityLabel("Share notes")
            }
        }
        .sheet(isPresented: $showCapture) {
            FeedbackCaptureSheet()
        }
        .sheet(item: $shareText) { item in
            ShareSheet(activityItems: [item.text])
                .presentationDetents([.medium, .large])
        }
    }

    private func resolveButton(_ item: FeedbackItem) -> some View {
        Button {
            item.isResolved.toggle()
            try? modelContext.save()
        } label: {
            Label(item.isResolved ? "Reopen" : "Done",
                  systemImage: item.isResolved ? "arrow.uturn.left" : "checkmark")
        }
        .tint(item.isResolved ? .orange : .green)
    }

    private func deleteButton(_ item: FeedbackItem) -> some View {
        Button(role: .destructive) {
            modelContext.delete(item)
            try? modelContext.save()
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func exportText() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        var lines = ["GymTracker — Notes & Ideas", ""]
        for kind in FeedbackKind.allCases {
            let group = items.filter { $0.kind == kind }
            guard !group.isEmpty else { continue }
            lines.append("\(kind.rawValue)s:")
            for item in group {
                let status = item.isResolved ? "[done] " : "[ ] "
                lines.append("- \(status)\(item.text) (\(formatter.string(from: item.createdDate)))")
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}

/// Wraps shareable text in an Identifiable so it can drive `.sheet(item:)`.
struct ShareableText: Identifiable {
    let id = UUID()
    let text: String
}

private struct FeedbackRow: View {
    @Bindable var item: FeedbackItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.kind.systemImage)
                .font(.headline)
                .foregroundStyle(item.kind == .bug ? .red : .yellow)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.text)
                    .font(.subheadline)
                    .strikethrough(item.isResolved)
                    .foregroundStyle(item.isResolved ? .secondary : .primary)
                Text(item.createdDate, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.kind.rawValue): \(item.text)\(item.isResolved ? ", resolved" : "")")
    }
}

/// Minimal, fast capture form — type a line, pick Bug or Idea, save.
struct FeedbackCaptureSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var kind: FeedbackKind = .bug
    @State private var text = ""
    @FocusState private var fieldFocused: Bool

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $kind) {
                    ForEach(FeedbackKind.allCases) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                .pickerStyle(.segmented)

                Section {
                    TextField("What happened, or what's the idea?", text: $text, axis: .vertical)
                        .lineLimit(3...8)
                        .focused($fieldFocused)
                }
            }
            .navigationTitle("Quick Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !trimmed.isEmpty else { return }
                        modelContext.insert(FeedbackItem(kind: kind, text: trimmed))
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(trimmed.isEmpty)
                }
            }
            .onAppear { fieldFocused = true }
        }
        .presentationDetents([.medium])
    }
}
