import SwiftUI

struct RestTimerView: View {
    @Bindable var timer: RestTimerViewModel
    @State private var showCustomPicker = false
    @State private var customSeconds = 90

    var body: some View {
        VStack(spacing: 8) {
            if timer.isRunning {
                // Active timer display
                HStack(spacing: 12) {
                    // Circular progress
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray4), lineWidth: 4)
                            .frame(width: 44, height: 44)
                        Circle()
                            .trim(from: 0, to: 1 - timer.progress)
                            .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: timer.progress)
                        Text(timer.timeString)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rest Timer")
                            .font(.caption.bold())
                        Text("\(timer.totalSeconds)s total")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // +30s button
                    Button {
                        timer.addTime(30)
                    } label: {
                        Text("+30s")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color(.systemGray5)))
                    }
                    .buttonStyle(.plain)

                    // Stop button
                    Button {
                        timer.stop()
                    } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                // Preset buttons
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(RestTimerViewModel.presets, id: \.seconds) { preset in
                        Button {
                            timer.start(seconds: preset.seconds)
                        } label: {
                            Text(preset.label)
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color(.systemGray5)))
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        showCustomPicker = true
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.body)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showCustomPicker) {
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
}
