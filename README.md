# GymTracker

A simple, native iOS app for logging gym workouts and tracking progress. Built with SwiftUI and SwiftData.

## Features

- **Quick workout logging** — select gym + workout type, start logging immediately
- **Two alternating workouts** (A/B) based on an evidence-based hypertrophy program
- **Gym-specific templates** — exercises and weights tailored to Wädenswil, Kreuzlingen, or custom gyms
- **Custom gym support** — enter any gym name (e.g. "Davos"), reuse it later
- **Smart auto-fill** — full set scheme (warmups, working sets, drop sets) copied from last session; "Previous" badge shows your top weight
- **Autosave** — every weight/rep change saved immediately; resume after app crash or close
- **Template persistence** — renaming/removing exercises updates the template for that gym+workout
- **In-session editing** — add/remove exercises and sets, rename (long-press or double-tap), adjust weights with +/- buttons
- **Warmup sets** — tap a set number to mark it as a warmup; warmup sets display "W" in orange
- **Set completion tracking** — mark individual sets as done with a checkmark toggle; done status is distinct from prefilled values
- **Collapsible exercises** — collapse/expand individual exercise set groups, or toggle all at once with the global collapse button
- **Exercise autocomplete** — when adding exercises mid-session, suggestions from your workout history appear
- **Quick-apply previous values** — tap the "Previous" badge to apply last session's top weight to all sets
- **Workout history** — filterable by gym and workout type, with swipe-to-delete and session duration
- **Progress tracking** — weight progression charts per exercise, filterable by gym, workout frequency, PR indicators
- **Body weight tracking** — log weight, view trends over time
- **Rest timer** — preset intervals (60s/90s/120s) or custom, with haptic feedback and background notifications
- **Data export** — export all workout and body weight data as CSV or JSON via the native share sheet
- **Pre-loaded history** — 9 historical workouts imported from handwritten logs

## Tech Stack

- **Swift / SwiftUI** — native iOS UI
- **SwiftData** — local persistence (no backend needed)
- **Swift Charts** — progress and body weight charts
- **MVVM architecture** — clean separation of models, views, and logic
- **iOS 17+** target

## Project Structure

```
GymTracker/
├── Sources/
│   ├── GymTrackerApp.swift          # App entry point
│   ├── Models/
│   │   ├── Enums.swift              # GymPreset and WorkoutType
│   │   ├── WorkoutSession.swift     # Session model with autosave support
│   │   ├── LoggedExercise.swift     # Exercise model with sets
│   │   ├── ExerciseSet.swift        # Individual set (weight/reps)
│   │   └── BodyWeightEntry.swift    # Body weight log entry
│   ├── ViewModels/
│   │   ├── WorkoutViewModel.swift   # Workout logic, autosave, custom gyms
│   │   └── RestTimerViewModel.swift # Rest timer with haptics and notifications
│   ├── Views/
│   │   ├── HomeView.swift           # Main dashboard with resume banner
│   │   ├── StartWorkoutView.swift   # Gym + workout selection (incl. custom gyms)
│   │   ├── WorkoutSessionView.swift # Active workout with autosave
│   │   ├── HistoryView.swift        # Past workouts with delete support
│   │   ├── WorkoutDetailView.swift  # Single workout detail
│   │   ├── ProgressView_.swift      # Exercise progress charts
│   │   ├── BodyWeightView.swift     # Body weight tracking
│   │   └── Components/
│   │       ├── ExerciseCardView.swift # Exercise card with set editing
│   │       └── RestTimerView.swift    # Rest timer UI with presets
│   └── Extensions/
│       └── Double+Format.swift    # Shared weight formatting
│   └── Data/
│       ├── ExerciseTemplates.swift   # Default templates per gym/workout
│       ├── HistoryDataImporter.swift # Historical workout data seeder
│       └── DataExporter.swift        # CSV and JSON export
├── Resources/
│   └── Assets.xcassets/             # App icon and colors
├── project.yml                      # XcodeGen project spec
└── GymTracker.xcodeproj/            # Generated Xcode project
```

## How to Run

1. **Prerequisites:** Xcode 15+ with iOS 17+ SDK
2. Open `GymTracker/GymTracker.xcodeproj` in Xcode
3. Select your device or simulator
4. For physical device: go to **Signing & Capabilities**, select your Personal Team
5. Build and run (⌘R)

## Key Behaviors

### Autosave
Every weight/rep change, exercise edit, and note is saved to SwiftData immediately. If the app crashes or iOS kills it in the background, nothing is lost. When you reopen, a "Resume Workout" banner appears on the home screen.

### Template Persistence
When you rename or remove exercises during a workout and complete it, those changes become the default for the next session of the same gym + workout combination. Changes are scoped per gym — modifying Workout A at Wädenswil won't affect Workout A at Kreuzlingen.

### Previous Values & Autofill
When starting a new workout, the app copies the **full set scheme** from your last matching session (same gym + workout type) — including warmup sets, working sets, and drop sets. The blue "Previous" badge shows a compact summary of your **top weight** from last time. Tap "Apply" to quickly set all sets to that previous top weight.

### Custom Gyms
Selecting "Other" in the gym picker lets you type a custom name. Previously used custom names (like "Davos") appear as quick-select chips for reuse.

### Rest Timer
During a workout, use the rest timer section to time rest between sets. Choose a preset (60s, 90s, 120s) or set a custom duration. The timer provides haptic feedback when complete and sends a notification if the app is in the background.

### Set Management
Add or remove sets from any exercise during a session. Tap the set number to toggle warmup status. Use the checkmark to mark sets as done — this is explicit and independent of prefilled weight/rep values.

### Collapsible Exercises
Each exercise's set group can be collapsed or expanded individually. Use the collapse/expand button in the exercises section header to toggle all exercises at once.

### Keyboard Dismissal
Swipe down on any scrollable screen to dismiss the keyboard while editing weights, reps, notes, or other text fields.

### Data Export
In the History screen, tap the share icon in the toolbar to export all workout and body weight data as CSV or JSON. The native iOS share sheet lets you save to Files, AirDrop, email, or any other sharing target.

### Data Compatibility
New properties (warmup status, completion tracking) use safe defaults so existing saved workouts continue to load without issues. Workout history is preserved across updates.

## Imported Workout History

Historical sessions were parsed from handwritten notebook images and imported as seed data. The app includes 9 sample sessions across multiple gyms and workout types to demonstrate the tracking workflow.

## Future Improvements

- iCloud sync (requires paid Apple Developer account)
- Apple Watch companion
- Apple Health integration
- Workout duplication (copy a previous session as starting point)
- PR / personal record indicators in session view
- Favorite exercises
