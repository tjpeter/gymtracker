# CLAUDE.md 

Build a simple but well-designed native iPhone app to log my gym workouts and track progress.

Use the files in this project as the source of truth:
- `./input/Hypertrophy_Program_V2_Optimized.md` = overall training plan
- `./input/IMG_2493.HEIC` = workout/exercise reference for one gym
- `./input/IMG_2494.HEIC` = workout/exercise reference for the other gym

Your task is to design and implement the app, not just outline it.

## Goal

Create an iPhone app for recording my workouts. My training plan consists of two alternating workouts:
- Workout A
- Workout B

I train in different gyms:
- Wädenswil
- Kreuzlingen / XLingen
- Other / Custom

Because the machines differ between gyms, the exercises and weights differ by location.

The app should let me:
1. select the gym
2. select workout A or B
3. automatically load the exercises and previous weights from the last time I did that same workout at that same gym
4. edit anything before or during the session:
   - overwrite weights
   - add/remove exercises
   - rename exercises if needed
5. save the completed workout
6. track progress over time
7. track body weight over time

## High-level product requirements

### Core workflow
The most important workflow is:
- Open app
- Tap “Start Workout”
- Choose:
  - Gym: Wädenswil / Kreuzlingen / Other
  - Workout: A / B
- App loads the exercise template for that gym + workout
- For each exercise, app pre-fills values from the most recent matching session at that gym/workout
- I can quickly log the current workout
- Save workout

This should feel fast, clean, and low-friction in the gym.

### Design goals
- Native iPhone app
- Simple, modern, polished UI
- Minimal taps
- Large touch targets
- Excellent typography and spacing
- Good dark mode support
- Smooth, responsive interactions
- Local-first app, no account required
- Data should persist between app launches

## Tech requirements

### Preferred stack
Use:
- Swift
- SwiftUI
- SwiftData for persistence

Target:
- Recent iOS version with SwiftUI best practices

Architecture:
- Keep code clean and maintainable
- Use a simple MVVM-style structure where appropriate
- Separate models, views, and persistence logic cleanly

Do not over-engineer.
Do not add backend/cloud/auth unless absolutely necessary.
Start with local storage only.

## Functional requirements

### 1. Gym selection
Support these gyms:
- Wädenswil
- Kreuzlingen
- Other / Custom

Notes:
- Treat “Kreuzlingen” and “XLingen” as the same gym label internally if relevant.
- “Other / Custom” should allow a user-defined session with editable exercises.

### 2. Workout selection
Support:
- Workout A
- Workout B

### 3. Exercise templates
From `Hypertrophy_Program_V2_Optimized.md` and the two images, derive exercise templates for:
- Wädenswil + Workout A
- Wädenswil + Workout B
- Kreuzlingen + Workout A
- Kreuzlingen + Workout B

If the files are ambiguous:
- infer a sensible structure
- document assumptions clearly in comments and README
- make templates easy to edit later in code

For `Other / Custom`:
- start from either an empty session or optionally let user copy from a recent session

### 4. Workout logging
For each exercise in a workout, support logging:
- exercise name
- optional machine / notes
- sets
- reps
- weight
- optional comments

The UI should make weight logging especially easy.

Good default approach:
- each exercise shown in a card or section
- show previous session values clearly
- allow quick editing
- allow adding/removing exercises
- reorder exercises if reasonably easy

### 5. Previous-values autofill
When I select a specific gym + workout combination, load the last saved session for that exact combination and use it to prefill values.

Example:
- If I choose Wädenswil + Workout A, load values from the most recent previous Wädenswil Workout A session.
- If none exists yet, use the default template values from the plan/images.

### 6. Save workout history
Persist every completed workout with:
- date/time
- gym
- workout type (A/B)
- list of exercises
- all logged values
- session notes optional

### 7. Progress tracking
Add a progress section with at least:
- recent workouts list
- exercise history
- simple progress charts

Track at least:
- last used weight per exercise
- progression over time for an exercise
- total workouts completed
- workouts by gym
- workouts by workout type

A clean first version is enough.
Use Swift Charts if appropriate.

### 8. Body weight tracking
Add body weight tracking:
- log body weight with date
- view recent entries
- simple body weight trend chart

### 9. Editing flexibility
The workout templates should be editable by the user during a session:
- remove an exercise
- add a custom exercise
- modify loaded values
- rename custom entries if needed

At minimum, edits should affect the current saved session.
A nice extra is allowing template updates for future sessions, but only add this if it remains simple and reliable.

## UX requirements

### Main screens
Implement at least these screens:

1. **Home**
- Start Workout
- View History
- Progress
- Body Weight

2. **Start Workout flow**
- select gym
- select workout A/B
- begin session

3. **Workout Session screen**
- list of exercises
- each exercise with editable fields
- show previous values
- add/remove exercise
- save workout button

4. **History screen**
- list of past workouts
- filter by gym and/or workout type
- tap into workout details

5. **Progress screen**
- charts or summaries for exercise progress
- recent trends

6. **Body Weight screen**
- add new weight entry
- history list
- trend chart

### Visual style
Aim for:
- Apple-like simplicity
- clean cards/sections
- subtle color accents
- clear hierarchy
- strong usability while training

Avoid clutter.
Avoid overly flashy design.

## Data model suggestions

Create appropriate models, for example:
- Gym
- WorkoutType
- WorkoutTemplate
- WorkoutSession
- LoggedExercise
- ExerciseSet or ExerciseEntry
- BodyWeightEntry

Support relationships cleanly in SwiftData.

A practical structure is:
- `WorkoutSession`
  - id
  - date
  - gym
  - workoutType
  - notes
  - exercises: [LoggedExercise]
- `LoggedExercise`
  - id
  - name
  - order
  - machine/note
  - sets/reps/weight info
  - previousWeight reference value optional

You may simplify set modeling if needed for version 1, but keep it extensible.

## Parsing source files

Use the markdown plan and the two images to extract the initial exercise definitions.

Tasks:
1. inspect `Hypertrophy_Program_V2_Optimized.md`
2. inspect `IMG_2493.HEIC`
3. inspect `IMG_2494.HEIC`
4. map the exercises/weights to:
   - gym
   - workout A/B
5. encode these as initial templates in the app

If OCR/image reading is imperfect, make best-effort interpretations and clearly list assumptions in the README.

## Implementation quality
Please:
- build the actual app code
- ensure it compiles
- keep files organized
- add comments where non-obvious
- include a README with:
  - project overview
  - architecture summary
  - assumptions from the markdown/images
  - how to run
  - future improvements

Also:
- provide sample preview/mock data for SwiftUI previews
- make the app usable without additional setup
- use realistic defaults
- seed initial templates on first launch

## Implemented set features

### Set management
- Sets can be added and removed from any exercise during a session
- Add set appends a new set with values copied from the last set
- Remove set deletes the last set (minimum one set per exercise); requires confirmation
- Deleting an exercise requires confirmation
- Applying previous values requires confirmation to prevent accidental overwrites
- Exercise notes autosave on change and are displayed in the workout history detail view

### Warmup sets
- Any set can be marked as a warmup by tapping the set number
- Warmup sets display "W" in orange with reduced opacity
- Working sets renumber consecutively (1, 2, 3...), skipping warmup sets
- Exercise header shows breakdown (e.g. "3 sets + 2W")
- Warmup status is carried forward when starting a new session from a previous one
- Warmup sets are also shown in the history detail view
- Warmup status is persisted via the `isWarmup` property on `ExerciseSet` (default: `false`)

### Set completion tracking
- Each set has an explicit done/not-done toggle (checkmark) with haptic feedback
- Completed sets are highlighted with a subtle green background tint
- Completion status is preserved accurately when finishing a workout (not force-marked)
- Completion is independent of whether weight/reps are prefilled
- Persisted via the `isCompleted` property on `ExerciseSet` (default: `false`)

### PR indicators
- Trophy icon appears next to exercise name when any working set exceeds previous session's best weight

### Previous value context
- Weight and rep text fields show previous session values as placeholder text
- Gives per-set context without requiring interaction with the "Previous" badge

### Rest timer
- Pinned to bottom of workout screen as a sticky bar (safeAreaInset)
- Always visible while scrolling through exercises
- Preset intervals (60s/90s/120s) and custom duration

### Progress tracking
- Exercise progress charts with toggle between max weight and volume (sets × reps × weight)
- Volume calculation excludes warmup sets
- Searchable exercise list replaces the picker for easier navigation
- Workout frequency chart shows weekly training distribution

### Collapsible exercise groups
- Each exercise's set group can be collapsed/expanded individually
- A global collapse/expand toggle in the exercises header controls all exercises at once

### Keyboard dismissal
- Swipe down on scrollable screens to dismiss the keyboard while editing text fields

### Body weight chart
- Y-axis auto-scales to data range (min-1 to max+1) for visible trends

### Home screen
- Weekly streak counter (consecutive weeks with at least one workout)

## Data compatibility constraints
- Workout history must be preserved across updates
- New persisted properties must have safe defaults so older saved data loads without crashes
- Do not wipe local storage or rename/remove existing persisted fields without safe migration
- The `isWarmup` and `isCompleted` fields on `ExerciseSet` default to `false` for backward compatibility

## Nice-to-have features
Only add these if they do not complicate the app too much:
- duplicate previous workout (copy from any session, including cross-gym)
- mark favorite exercises
- accessibility improvements (VoiceOver labels, Dynamic Type support)

## Important constraints
- Keep the app focused and usable
- Prioritize reliability and speed of logging over feature bloat
- Do not build a backend
- Do not add user accounts
- Do not add unnecessary abstractions
- The app should feel like a real usable product, not a prototype