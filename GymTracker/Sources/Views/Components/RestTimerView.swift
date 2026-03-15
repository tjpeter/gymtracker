import SwiftUI

struct RestTimerView: View {
    @Bindable var timer: RestTimerViewModel
    @Binding var isVisible: Bool
    @State private var showCustomPicker = false
    @State private var customSeconds = 90
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        if isVisible {
            expandedTimer
                .offset(y: max(0, dragOffset))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 0 {
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 60 {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    isVisible = false
                                }
                            }
                            withAnimation(.easeOut(duration: 0.2)) {
                                dragOffset = 0
                            }
                        }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            minimizedPill
                .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Expanded Timer

    private var expandedTimer: some View {
        VStack(spacing: 12) {
            // Drag handle
            Capsule()
                .fill(Color(.systemGray3))
                .frame(width: 36, height: 5)
                .padding(.top, 6)

            if timer.isRunning {
                activeTimerDisplay
            } else {
                presetButtons
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showCustomPicker) {
            customPickerSheet
        }
    }

    private var activeTimerDisplay: some View {
        VStack(spacing: 12) {
            // Large circular timer
            ZStack {
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: 1 - timer.progress)
                    .stroke(
                        timer.remainingSeconds <= 5 ? Color.red : Color.orange,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timer.progress)

                VStack(spacing: 2) {
                    Text(timer.timeString)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .monospacedDigit()
                    Text("of \(timer.totalSeconds)s")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 100, height: 100)

            // Controls
            HStack(spacing: 16) {
                Button {
                    timer.addTime(30)
                } label: {
                    Text("+30s")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color(.systemGray5)))
                }
                .buttonStyle(.plain)

                Button {
                    timer.stop()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.red.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var presetButtons: some View {
        VStack(spacing: 8) {
            Text("Rest Timer")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(RestTimerViewModel.presets, id: \.seconds) { preset in
                    Button {
                        timer.start(seconds: preset.seconds)
                    } label: {
                        Text(preset.label)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray5))
                            )
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    showCustomPicker = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.headline)
                        .frame(width: 48)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray5))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Minimized Pill

    private var minimizedPill: some View {
        HStack {
            Spacer()
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    isVisible = true
                }
            } label: {
                HStack(spacing: 6) {
                    if timer.isRunning {
                        Image(systemName: "timer")
                            .font(.caption.bold())
                        Text(timer.timeString)
                            .font(.system(.caption, design: .monospaced, weight: .bold))
                            .monospacedDigit()
                    } else {
                        Image(systemName: "timer")
                            .font(.caption.bold())
                        Text("Rest")
                            .font(.caption.bold())
                    }
                }
                .foregroundStyle(timer.isRunning ? .orange : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                )
            }
            .buttonStyle(.plain)
            .padding(.trailing, 16)
            .padding(.bottom, 4)
        }
    }

    // MARK: - Custom Picker Sheet

    private var customPickerSheet: some View {
        NavigationStack {
            Form {
                Section("Custom Rest Duration") {
                    Stepper("\(customSeconds) seconds", value: $customSeconds, in: 10...600, step: 10)
                }
            }
            .navigationTitle("Custom Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCustomPicker = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        showCustomPicker = false
                        timer.start(seconds: customSeconds)
                    }
                }
            }
        }
        .presentationDetents([.height(200)])
    }
}
