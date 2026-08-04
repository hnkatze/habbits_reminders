<!-- Last updated: 2026-08-04 -->

# Habits

A SwiftUI reminders app that blends **daily habits** with **place-based reminders** — build streaks, run focus sessions, and get nudged the moment you arrive somewhere. Everything runs on a **free** Apple Developer account: no paid capabilities, no API keys.

## Overview

Habits is a single iOS app with two kinds of reminders:

- **Habits** — recurring routines with streaks, an optional daily notification, and an optional focus timer that shows a live countdown.
- **Places** — geofenced reminders that fire when you arrive at a saved location, each carrying a note or a checklist.

It leans on modern, first-party iOS frameworks (SwiftData, ActivityKit, MapKit, App Intents) and deliberately avoids anything that requires a paid membership.

## Features

**Habits**

- ✅ Streak tracking with a 7-day history strip
- ✅ Optional daily reminder (local notification)
- ✅ Optional focus timer with a **Live Activity** countdown on the Lock Screen and Dynamic Island
- ✅ Stats screen powered by Swift Charts
- ✅ "Mark a habit done" from **Siri & Shortcuts** (App Intent)

**Places (location reminders)**

- ✅ Geofenced arrival reminders — fire when you get to the place
- ✅ Note or checklist content per place
- ✅ Live distance to each place in the list
- ✅ Active / mute toggle to arm or silence a place without deleting it
- ✅ **Map** of all places with geofence radius circles — native MapKit, no API key
- ✅ **Track** Live Activity: a route track and live distance in the Dynamic Island, using background location only while tracking
- ✅ Create a place by pasting a Google/Apple Maps link — the coordinate is resolved automatically

**App-wide**

- ✅ Light / dark / system theme toggle
- ✅ Share a place (as a Maps link) or a habit (streak) from the share sheet
- ✅ SwiftData persistence

## Tech Stack

| Category        | Technology                       |
| --------------- | -------------------------------- |
| UI              | SwiftUI                          |
| Persistence     | SwiftData                        |
| Live Activities | ActivityKit + WidgetKit          |
| Maps & location | MapKit + Core Location           |
| Notifications   | UserNotifications (local)        |
| Charts          | Swift Charts                     |
| Automation      | App Intents (Siri / Shortcuts)   |
| Testing         | Swift Testing                    |
| Language        | Swift 5 language mode (Xcode 26) |

## Requirements

- **Xcode 26+** with the iOS 26 SDK
- Deployment target **iOS 26**
- A **free** Apple Developer account is enough — local notifications, ActivityKit, MapKit, and App Intents need no paid capability

## Getting Started

### 1. Clone

```bash
git clone https://github.com/hnkatze/habbits_reminders.git
cd habbits_reminders
```

### 2. Open in Xcode

```bash
open TestApp.xcodeproj
```

Select the **`TestApp`** scheme and an iPhone (iOS 26) destination, then run with ⌘R.

### 3. Or build from the command line

```bash
xcodebuild -scheme TestApp -destination 'platform=iOS Simulator,name=iPhone 17' build
```

> Live Activities, geofencing, and the live distance are best experienced on a real device. In the Simulator, use **Features → Location** to simulate movement.

## Testing

```bash
xcodebuild test -scheme TestApp -destination 'platform=iOS Simulator,name=iPhone 17'
```

The suite (Swift Testing) covers the pure logic: streak calculation, Maps-link parsing, place summaries, and distance formatting.

## Project Structure

The project is feature-first. Files are picked up automatically via Xcode's filesystem-synchronized groups.

```
TestApp/
├── TestAppApp.swift          # @main entry point + shared SwiftData container
├── AppShortcuts.swift        # Siri / Shortcuts registration
├── Core/                     # Theme, extensions, shared model container
├── Shared/Views/             # Reusable icon & color pickers
└── Features/
    ├── Habits/               # Models, Views, Components, Services, LiveActivity, Intents
    └── Places/               # Models, Views, Components, LiveActivity

TestAppWidget/                # Widget extension — the two Live Activities
TestAppTests/                 # Swift Testing suites
```

## Architecture Notes

- **State** uses `@Observable` and SwiftUI's native property wrappers; view models are plain observable classes.
- **Live Activities** live in a widget extension (`TestAppWidget`). Their `ActivityAttributes` are shared source files compiled into both the app and the widget so ActivityKit can match them.
- **App Intents** run in the app process against a shared `ModelContainer`, so Siri/Shortcuts work without an App Group.
- **Everything is free-tier**: no App Groups, no push server, no paid entitlements.

## Contributing

This is a personal project, but if you fork it:

1. Create a branch: `git checkout -b feat/my-feature`
2. Use Conventional Commits: `git commit -m "feat(places): add ..."`
3. Open a pull request

## License

No license file yet — all rights reserved by default. Add a `LICENSE` if you intend to share or open-source it.
