# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

TestApp is a SwiftUI iOS app for reminders, built on SwiftData. It has two kinds
of reminders:

- **Habits** — recurring habits with streaks, a daily completion toggle, an
  optional daily local notification, and a stats screen (Swift Charts).
- **Places** — location reminders that fire when you arrive at a place
  (geofence), carrying either a text note or a checklist.

The root screen (`HabitsListView`) lists both, plus a theme toggle that cycles
system → light → dark. There are no third-party dependencies and no package
manager — it is a pure Xcode project.

## Requirements

- **Xcode 26+** and the iOS 26 SDK. `IPHONEOS_DEPLOYMENT_TARGET = 26.0`.
- Swift 5 language mode. Supported platforms: iOS, macOS, visionOS
  (`TARGETED_DEVICE_FAMILY = 1,2,7`).
- Geofence reminders need **"Always"** location authorization; local
  notifications need notification authorization. Both work on a free account —
  no paid capability or App Group required. `UNLocationNotificationTrigger` is
  iOS-only; on macOS the geofence scheduling is a no-op.

## Commands

Scheme and target are both `TestApp`.

```bash
# Build for the simulator
xcodebuild -scheme TestApp -destination 'platform=iOS Simulator,name=iPhone 17' build

# Build for a generic device (requires the DEVELOPMENT_TEAM signing to resolve)
xcodebuild -scheme TestApp -destination 'generic/platform=iOS' build

# Clean
xcodebuild -scheme TestApp clean
```

Day-to-day, prefer building/running from Xcode (⌘R) or a SwiftUI `#Preview`,
which is faster than a full `xcodebuild`.

The Xcode project uses **filesystem-synchronized groups**: files added under
`TestApp/` are picked up automatically, so new `.swift` files do not need manual
`.pbxproj` entries.

## Architecture

Feature-first layout under `TestApp/`:

- `App/` — n/a; the `@main` entry point is `TestAppApp.swift` at the root, whose
  single `WindowGroup` hosts `HabitsListView` and installs the SwiftData
  `.modelContainer(for: [Habit.self, PlaceReminder.self])`.
- `Core/` — cross-cutting pieces: `Appearance` (theme enum persisted via
  `@AppStorage`) and `Color+Hex` (build a `Color` from a stored `"#RRGGBB"`
  string).
- `Shared/Views/` — reusable UI shared across create sheets: `IconPickerGrid`
  and `ColorPickerRow`. Both are built from real `Button`s with VoiceOver
  traits (`.isSelected`), not tap gestures — reuse them instead of re-rolling a
  picker.
- `Features/Habits/` and `Features/Places/` — each split into `Models/`,
  `Views/`, `Components/`, and (Habits) `Services/`.

### Data model (SwiftData `@Model`)

- `Habit` ↔ `HabitEntry` (one-to-many, `.cascade`). A `HabitEntry` records "done
  on this date"; `Habit.currentStreak` / `isCompleted(on:)` are computed, never
  stored.
- `PlaceReminder` ↔ `ChecklistItem` (one-to-many, `.cascade`). `isList` picks
  between the `note` string and the `items` checklist.
- Each model owns a stable `notificationID` used to key its scheduled
  notification / geofence.

### Services (Habits/Services)

- `NotificationManager` — `@MainActor` enum wrapping `UNUserNotificationCenter`.
  Schedules the daily reminder (keyed by `notificationID`) and the geofence
  reminder (keyed by `"loc-<notificationID>"` so the two never collide).
  **Deleting a model must cancel its notifications first** (see
  `HabitsListView.deleteHabits` / `deletePlaces`), otherwise repeating triggers
  and monitored regions leak.
- `LocationManager` — minimal `CLLocationManager` wrapper; its only job is to
  request "Always" authorization for background region monitoring.
- `MapLinkParser` / `MapLinkResolver` — turn a pasted Google/Apple Maps link
  into coordinates. `MapLinkParser` extracts coords from a **full** link
  offline (regex); `MapLinkResolver` first tries the parser, then follows a
  network redirect for **short** share links (`maps.app.goo.gl`) and parses the
  resolved URL. iOS limits an app to 20 monitored geofence regions.

### Conventions worth preserving

- **One type per file.** Sub-sections inside a screen are computed `View`
  properties delimited with `// MARK: -`; genuinely reusable pieces are
  top-level `struct`s (in `Shared/` when cross-feature, `Components/` when
  feature-local).
- **State** uses `@Observable` (e.g. `LocationManager`), not
  `ObservableObject`.
- **Theme** is applied via `.preferredColorScheme` from the root view (not from
  a sheet, where it gets stuck).

## Assets

- Images live in `TestApp/Assets.xcassets`.
- `AppIcon` is a custom icon; `AccentColor` is the default template asset set.
