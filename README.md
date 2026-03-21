# GymTracker

A simple, native iOS app for logging gym workouts and tracking progress. Built with SwiftUI and SwiftData.

## Features

- **Quick workout logging** — select gym + workout type, start logging immediately
- **Two alternating workouts** (A/B) based on an evidence-based hypertrophy program
- **Gym-specific templates** — exercises and weights tailored to Wädenswil, Kreuzlingen, or custom gyms
- **Custom gym support** — enter any gym name with fuzzy-match suggestions to prevent duplicates
- **Smart auto-fill** — full set scheme (warmups, working sets, drop sets) copied from last session including warmup status; "Previous" badge shows your top weight; per-set placeholder text shows last session's values
- **RPE tracking** — optional Rate of Perceived Exertion (6-10) per set, color-coded and shown in summary/history
- **Session rating** — 5-star post-workout rating displayed in history and detail views
- **Autosave** — every weight/rep change saved immediately; resume after app crash or close
- **Template persistence** — renaming/removing exercises updates the template for that gym+workout
- **In-session editing** — add/remove exercises and sets (with confirmation), rename (swipe, long-press, or double-tap), adjust weights with large +/- buttons (44pt touch targets)
- **Warmup sets** — tap a set number to mark it as a warmup; warmup sets display "W" with orange left border stripe; working sets renumber consecutively; exercise header shows "3/5 (3+2W)" breakdown
- **Set completion tracking** — mark individual sets as done with a checkmark toggle, bounce animation, and haptic feedback; completed sets highlighted with green tint; done status preserved accurately on workout completion
- **Workout completion summary** — after finishing a workout, a summary screen shows duration, total sets, volume, PRs hit, per-exercise breakdown with weight changes and average RPE, session rating, and option to save as reusable template
- **Superset grouping** — link exercises as supersets via context menu; linked exercises shown with purple link icon
- **Workout templates** — save completed workouts as reusable templates; pick templates when starting new workouts
- **Editable workout history** — tap Edit in workout detail view to modify exercise names, weights, reps, and notes for completed workouts
- **Workout A/B color coding** — blue for Workout A, teal for Workout B, applied consistently across home, history, session, and progress screens
- **Collapsible exercises** — collapse/expand individual exercise set groups, or toggle all at once with the global collapse button
- **Exercise autocomplete** — when adding exercises mid-session, suggestions from your workout history appear
- **Quick-apply previous values** — tap the "Previous" badge to apply last session's top weight to all sets (with confirmation)
- **Copy from previous workout** — optionally start a new workout by copying exercises from any previous session, including cross-gym, or from a saved template
- **Workout history** — filterable by gym, workout type, and date range, with swipe-to-delete, session duration, and star ratings
- **Progress tracking** — weight progression, volume, and estimated 1RM charts per exercise with PR reference line, trend indicators (up/down/stable), plateau detection, exercises sorted by training frequency, filterable by gym and date range (1M/3M/6M/All)
- **Workout duration trend** — green line/area chart showing workout duration over time
- **Body weight tracking** — log weight, view trends over time with gradient area chart and 7-day moving average overlay
- **Rest timer** — dismissible bottom panel with preset intervals (60s/90s/120s) or custom, with pause/resume, haptic feedback, and background notifications; auto-start option triggers timer on set completion
- **PR indicators** — pulsing trophy icon appears during workouts when a personal record is set
- **Micro-interactions** — checkmark bounce on set completion, PR trophy pulse, animated workout summary
- **Accessibility** — VoiceOver labels on all interactive elements across home, timer, and body weight views
- **Data export** — export all workout and body weight data as CSV or JSON via the native share sheet
- **Pre-loaded history** — 9 historical workouts imported from handwritten logs

## Tech Stack

- **Swift / SwiftUI** — native iOS UI
- **SwiftData** — local persistence (no backend needed)
- **Swift Charts** — progress and body weight charts with area fills, PR lines, and trend indicators
- **MVVM architecture** — clean separation of models, views, and logic
- **XcodeGen** — project file generation from `project.yml`
- **iOS 17+** target

## Project Structure

```
GymTracker/
├── Sources/
│   ├── GymTrackerApp.swift              # App entry point
│   ├── Theme.swift                      # Centralized design tokens (colors, spacing, radii)
│   ├── Models/
│   │   ├── Enums.swift                  # GymPreset, WorkoutType (with A/B colors)
│   │   ├── WorkoutSession.swift         # Session model with duration, autosave
│   │   ├── LoggedExercise.swift         # Exercise model with sets
│   │   ├── ExerciseSet.swift            # Individual set (weight/reps/warmup/completed/RPE)
│   │   ├── BodyWeightEntry.swift        # Body weight log entry
│   │   └── CustomTemplate.swift         # User-saved workout templates
│   ├── ViewModels/
│   │   ├── WorkoutViewModel.swift       # Workout logic, autosave, gym name normalization
│   │   └── RestTimerViewModel.swift     # Rest timer with auto-start, haptics, notifications
│   ├── Views/
│   │   ├── HomeView.swift               # Dashboard with stats, next workout suggestion
│   │   ├── StartWorkoutView.swift       # Gym + workout selection with fuzzy matching
│   │   ├── WorkoutSessionView.swift     # Active workout with timer and undo banner
│   │   ├── HistoryView.swift            # Past workouts with color-coded filters
│   │   ├── WorkoutDetailView.swift      # Workout detail with edit mode
│   │   ├── ProgressView_.swift          # Exercise charts with PR line and trends
│   │   ├── BodyWeightView.swift         # Body weight tracking with trend chart
│   │   └── Components/
│   │       ├── ExerciseCardView.swift   # Exercise card with redesigned set rows
│   │       ├── RestTimerView.swift      # Dismissible timer with auto-start toggle
│   │       └── WorkoutSummaryView.swift # Post-workout summary with stats and PRs
│   ├── Extensions/
│   │   ├── Double+Format.swift          # Shared weight formatting
│   │   └── Notification+Names.swift     # Custom notification names
│   └── Data/
│       ├── ExerciseTemplates.swift      # Default templates per gym/workout
│       ├── HistoryDataImporter.swift    # Historical workout data seeder
│       └── DataExporter.swift           # CSV and JSON export
├── Resources/
│   └── Assets.xcassets/                 # App icon and colors
├── project.yml                          # XcodeGen project spec
└── GymTracker.xcodeproj/                # Generated Xcode project
```

## How to Run

1. **Prerequisites:** Xcode 15+ with iOS 17+ SDK, XcodeGen (`brew install xcodegen`)
2. `cd GymTracker && xcodegen generate` (or open existing `.xcodeproj`)
3. Open `GymTracker/GymTracker.xcodeproj` in Xcode
4. Select your device or simulator
5. Build and run (⌘R)

## Key Behaviors

### Autosave
Every weight/rep change, exercise edit, and note is saved to SwiftData immediately. If the app crashes or iOS kills it in the background, nothing is lost. When you reopen, a "Resume Workout" banner appears on the home screen.

### Template Persistence
When you rename or remove exercises during a workout and complete it, those changes become the default for the next session of the same gym + workout combination. Changes are scoped per gym — modifying Workout A at Wädenswil won't affect Workout A at Kreuzlingen.

### Previous Values & Autofill
When starting a new workout, the app copies the **full set scheme** from your last matching session (same gym + workout type) — including warmup sets, working sets, drop sets, and warmup status. The blue "Previous" badge shows a compact summary of your **top weight** from last time. Tap "Apply" to quickly set all sets to that previous top weight (with confirmation). Weight and rep text fields show the previous session's values as placeholder text for per-set context.

### Custom Gyms
Selecting "Other" in the gym picker lets you type a custom name. Previously used custom names appear as quick-select chips. Fuzzy matching suggests existing names as you type to prevent duplicates from typos or casing differences. Names are trimmed of whitespace automatically.

### Rest Timer
The rest timer is a dismissible panel at the bottom of the workout screen. Choose a preset (60s, 90s, 120s) or set a custom duration. Swipe down to minimize it into a compact pill. Enable "Auto" to automatically start the timer when you mark a set as complete. The timer can be paused and resumed — a paused timer shows "PAUSED" and the minimized pill turns yellow. The timer provides haptic feedback when starting and completing, and sends a notification if the app is in the background.

### Workout Completion
After completing a workout, a summary screen shows total duration, sets completed, total volume, and any personal records hit. Each exercise shows its max weight, weight change vs previous session, volume, and average RPE. Rate the session with 1-5 stars. Optionally save the workout as a reusable template for future sessions.

### Editable History
Completed workouts can be edited by tapping the Edit button in the workout detail view. Exercise names, weights, reps, and session rating can be modified inline. A summary stats grid at the top shows duration, working sets, volume, and PR count.

### Set Management
Add or remove sets from any exercise during a session. Removing a set and applying previous values require confirmation. Deleting an exercise shows a confirmation alert followed by a temporary feedback banner. Tap the set number to toggle warmup status — working sets renumber consecutively, skipping warmup sets. The exercise header shows completion progress like "3/5" that changes from orange to green as sets complete. Use the checkmark to mark sets as done (with bounce animation and haptic feedback).

### PR Indicators
A pulsing trophy icon appears next to the exercise name during a workout when any working set weight exceeds your previous session's best. Progress charts show a dashed PR reference line, trend direction badges, and plateau detection warnings when weight hasn't increased over 4+ sessions.

### Design System
All colors and spacing values are centralized in `Theme.swift`. Changing the color palette or adjusting spacing across the app requires editing only one file.

### Copy From Previous Workout
When starting a new workout, the default auto-fill uses your last matching session (same gym + workout type). Optionally, tap "Copy" to pick any previous session as the starting point, or tap "Template" to use a saved workout template.

### Data Export
In the History screen, tap the share icon to export all workout and body weight data as CSV or JSON.

### Data Compatibility
New properties (warmup status, completion tracking, RPE, session rating, superset grouping) use safe defaults (`false` for booleans, `nil` for optionals) so existing saved workouts continue to load without issues.

## Imported Workout History

Historical sessions were parsed from handwritten notebook images and imported as seed data. The app includes 9 sample sessions across multiple gyms and workout types.

## Future Improvements

- Full visual refresh with a dark-mode-first brand direction
- iCloud sync (requires paid Apple Developer account)
- Apple Watch companion
- Apple Health integration
- Dynamic Type / large text support
- Favorite exercises
