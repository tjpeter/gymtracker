# GymTracker

A simple, native iOS app for logging gym workouts and tracking progress. Built with SwiftUI and SwiftData.

## Features

- **Quick workout logging** — select gym + workout type, start logging immediately
- **Two alternating workouts** (A/B) based on an evidence-based hypertrophy program
- **Gym-specific templates** — exercises and weights tailored to Wädenswil, Kreuzlingen, or custom gyms
- **Custom gym support** — enter any gym name (e.g. "Davos"), reuse it later
- **Auto-fill from last session** — previous weights/reps pre-loaded for each gym+workout combo
- **Autosave** — workout data saved continuously; resume after app crash or close
- **Template persistence** — renaming/removing exercises updates the template for that gym+workout
- **In-session editing** — add/remove exercises, rename, adjust weights with +/- buttons
- **Workout history** — filterable by gym and workout type, with swipe-to-delete
- **Progress tracking** — weight progression charts per exercise, workout frequency, PR indicators
- **Body weight tracking** — log weight, view trends over time
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
│   │   └── WorkoutViewModel.swift   # Workout logic, autosave, custom gyms
│   ├── Views/
│   │   ├── HomeView.swift           # Main dashboard with resume banner
│   │   ├── StartWorkoutView.swift   # Gym + workout selection (incl. custom gyms)
│   │   ├── WorkoutSessionView.swift # Active workout with autosave
│   │   ├── HistoryView.swift        # Past workouts with delete support
│   │   ├── WorkoutDetailView.swift  # Single workout detail
│   │   ├── ProgressView_.swift      # Exercise progress charts
│   │   ├── BodyWeightView.swift     # Body weight tracking
│   │   └── Components/
│   │       └── ExerciseCardView.swift # Exercise card with set editing
│   └── Data/
│       ├── ExerciseTemplates.swift  # Default templates per gym/workout
│       └── HistoryDataImporter.swift # Historical workout data seeder
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
Active workouts are saved continuously to SwiftData. If you close the app or it crashes, the incomplete workout persists. When you reopen the app, a "Resume Workout" banner appears on the home screen.

### Template Persistence
When you rename or remove exercises during a workout and complete it, those changes become the default for the next session of the same gym + workout combination. Changes are scoped per gym — modifying Workout A at Wädenswil won't affect Workout A at Kreuzlingen.

### Custom Gyms
Selecting "Other" in the gym picker lets you type a custom name. Previously used custom names (like "Davos") appear as quick-select chips for reuse.

## Imported Workout History

9 historical sessions were parsed from handwritten notebook images and imported:

| Date | Gym | Workout | Notes |
|------|-----|---------|-------|
| 14.2.2026 | Kreuzlingen | A | First tracked session |
| 16.2.2026 | Wädenswil | A | |
| 18.2.2026 | Kreuzlingen | B | |
| 23.2.2026 | Wädenswil | B | From text file |
| 24.2.2026 | Kreuzlingen | A | |
| 28.2.2026 | Davos | B | Custom gym |
| 2.3.2026 | Wädenswil | A | Body weight: 80 kg |
| 6.3.2026 | Kreuzlingen | B | Short session |
| 6.3.2026 | Kreuzlingen | A | Later same day |

### Parsing Assumptions
- Dates are DD.MM.YYYY format from 2026
- "XLingen" = Kreuzlingen
- Workout type inferred from exercise selection matching the A/B program
- Weights read as best-effort from handwriting; some values are approximate
- Warmup sets (lower weights) excluded; only working sets imported
- Where reps were unclear, prescribed rep range midpoint was used

## Future Improvements

- Rest timer between sets
- Export workout data (CSV/JSON)
- Apple Watch companion
- Apple Health integration
- iCloud sync
