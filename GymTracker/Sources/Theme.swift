import SwiftUI

enum Theme {
    // MARK: - Corner Radii
    static let cornerRadiusSmall: CGFloat = 6
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 14
    static let cornerRadiusXL: CGFloat = 16
    static let cornerRadiusHero: CGFloat = 20

    // MARK: - Spacing
    static let spacingSmall: CGFloat = 4
    static let spacingMedium: CGFloat = 8
    static let spacingLarge: CGFloat = 12
    static let spacingXL: CGFloat = 16
    static let spacingXXL: CGFloat = 20

    // MARK: - Chart
    static let chartHeight: CGFloat = 200
    static let chartLineWidth: CGFloat = 2.5

    // MARK: - Touch Targets
    static let minTouchTarget: CGFloat = 44

    // MARK: - Colors
    enum Colors {
        static let workoutA: Color = .blue
        static let workoutB: Color = .teal
        static let warmup: Color = .orange
        static let completed: Color = .green
        static let pr: Color = .yellow
        static let destructive: Color = .red
        static let energy: Color = .orange
        static let streak: Color = .purple

        static let cardBackground = Color(.systemGray6)
        static let inputBackground = Color(.systemGray6)
        static let buttonBackground = Color(.systemGray5)
        static let timerTrack = Color(.systemGray4)
        static let dragHandle = Color(.systemGray3)
    }

    // MARK: - Opacity
    enum Opacity {
        static let tintFill: Double = 0.08
        static let tintStroke: Double = 0.15
        static let warmupBackground: Double = 0.06
        static let completedBackground: Double = 0.08
        static let warmupRow: Double = 0.85
        static let warmupDetail: Double = 0.7
    }
}
