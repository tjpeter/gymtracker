import Foundation
import SwiftUI
import UserNotifications

@Observable
final class RestTimerViewModel {
    var remainingSeconds: Int = 0
    var totalSeconds: Int = 0
    var isRunning: Bool = false
    var autoStartEnabled: Bool = false
    var lastUsedDuration: Int = 90

    static let presets: [(label: String, seconds: Int)] = [
        ("60s", 60),
        ("90s", 90),
        ("120s", 120),
    ]

    private var timer: Timer?
    private var endDate: Date?

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    var timeString: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        if mins > 0 {
            return String(format: "%d:%02d", mins, secs)
        }
        return "\(secs)s"
    }

    func autoStart() {
        guard autoStartEnabled, !isRunning else { return }
        start(seconds: lastUsedDuration)
    }

    func start(seconds: Int) {
        stop()
        lastUsedDuration = seconds
        totalSeconds = seconds
        remainingSeconds = seconds
        isRunning = true
        endDate = Date().addingTimeInterval(TimeInterval(seconds))

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        scheduleNotification(seconds: seconds)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        remainingSeconds = 0
        totalSeconds = 0
        endDate = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["restTimer"])
    }

    func addTime(_ seconds: Int) {
        guard isRunning else { return }
        remainingSeconds += seconds
        totalSeconds += seconds
        if let end = endDate {
            endDate = end.addingTimeInterval(TimeInterval(seconds))
        }
        // Reschedule notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["restTimer"])
        scheduleNotification(seconds: remainingSeconds)
    }

    private func tick() {
        guard isRunning else { return }

        // Use endDate for accuracy (handles backgrounding)
        if let endDate = endDate {
            let remaining = Int(ceil(endDate.timeIntervalSinceNow))
            remainingSeconds = max(0, remaining)
        } else {
            remainingSeconds = max(0, remainingSeconds - 1)
        }

        if remainingSeconds <= 0 {
            finish()
        }
    }

    private func finish() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        remainingSeconds = 0

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func scheduleNotification(seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Rest Complete"
        content.body = "Time for your next set!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: "restTimer", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
