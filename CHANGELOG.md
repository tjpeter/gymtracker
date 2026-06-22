# Changelog

All notable changes to GymTracker are recorded here.

## [1.1.0] — 2026-06-22

Build 2

### Added
- **Waist tracking.** Body Weight now records an optional waist measurement (cm)
  alongside weight. The trend chart has a Weight / Waist toggle, and waist appears
  in the history list and the "Current" stats.
- **Smarter autofill across workout types.** When starting a workout, each exercise
  pre-fills from the most recent time you performed it *at that gym* — regardless of
  whether it was Workout A or B — including its sets, reps, weights, and notes.
- **Last-values when adding an exercise.** Adding an exercise you've done before at
  the current gym loads its previous sets, reps, weights, and notes as defaults.
- **One-swipe supersets.** A leading swipe links or unlinks an exercise as a superset.
  Connected exercises now show a colored group badge (SS A, SS B, …) so each pairing
  is easy to see at a glance. Linking automatically reorders the list so superset
  partners sit next to each other, and superset groupings carry forward into the next
  session.
- **In-app notes & ideas.** Capture a bug or feature idea in seconds — a quick-note
  button on the Home screen and in the active workout's menu opens a one-line form
  (Bug / Idea + text). A "Notes & Ideas" screen lists them, lets you mark items
  resolved or delete them, and can share the whole list as text to hand off for
  fixing/implementing. Stored locally like everything else.
- **Clearer workout history.** Set repetitions are shown. Sets that aren't real
  working sets — zero reps or never checked off — are de-emphasized (muted, de-bolded,
  faded) and labelled "skipped" instead of showing their pre-filled reps, and an
  exercise where none of the sets were logged is dimmed and marked "not logged".
  Exercise notes are shown. Unchecked sets are still saved to history, just shown
  less prominently than completed working sets.

### Changed
- **Stats count only completed sets.** Volume, max weight, estimated 1RM, and PR
  detection (in the post-workout summary, history detail, and progress charts) now
  include a set only if it was checked off. A skipped exercise left at its pre-filled
  values no longer inflates your progress. Existing/imported history is unaffected
  (its sets are already marked completed).
- Body weight tracking was reset to a fresh starting point of **93 kg / 103 cm waist**.
  This one-time reset runs once on launch and preserves any entries logged afterward.

### Notes
- All new persisted fields (`waist` on body weight entries) default safely, so existing
  workout and body weight history loads without migration.
