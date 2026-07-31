# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

TestApp is a single-screen SwiftUI iOS app (a bootstrapped Xcode template). It renders an animated "Have a great day!" greeting screen. There are no tests, no third-party dependencies, and no package manager — it is a pure Xcode project.

## Requirements

- **Xcode 26+** and the iOS 26 SDK. `IPHONEOS_DEPLOYMENT_TARGET = 26.0`.
- The UI relies on iOS 26 **Liquid Glass** APIs (`glassEffect`, `GlassEffectContainer`) and SF Symbols animation APIs (`symbolEffect`). These do not exist on earlier SDKs — building against an older toolchain will fail.
- Swift 5 language mode. Supported platforms: iOS, macOS, visionOS (`TARGETED_DEVICE_FAMILY = 1,2,7`).

## Commands

Scheme and target are both `TestApp`. There is no test target.

```bash
# Build for the simulator
xcodebuild -scheme TestApp -destination 'platform=iOS Simulator,name=iPhone 17' build

# Build for a generic device (requires the DEVELOPMENT_TEAM signing to resolve)
xcodebuild -scheme TestApp -destination 'generic/platform=iOS' build

# Clean
xcodebuild -scheme TestApp clean
```

Day-to-day, prefer building/running from Xcode (⌘R) or the SwiftUI preview (`#Preview` at the bottom of `ContentView.swift`), which is faster than a full `xcodebuild`.

## Architecture

The entire app is two files under `TestApp/`:

- `TestAppApp.swift` — the `@main` `App` entry point. A single `WindowGroup` hosting `ContentView`.
- `ContentView.swift` — the whole UI. The screen is composed as one `ZStack` (background gradient → floating stars → main `VStack`).

Structural conventions in `ContentView.swift` worth preserving when editing:

- **Sub-sections are computed `View` properties** (`heroIconCluster`, `titleBlock`, `badgeRow`, `heroImage`, `ctaLabel`), not separate structs. Reusable pieces (`BadgeView`, `FloatingStarsView`) are extracted as top-level `struct`s. Sections are delimited with `// MARK: -` comments.
- **Animation is state-driven.** Each animated element has its own `@State` boolean flag (`runnerBouncing`, `titleAppeared`, etc.). All flags flip to `true` in `startAnimations()`, called from `.onAppear`, and each view attaches its own `.animation(_:value:)` with a staggered `.delay(...)` to sequence the entrance choreography. To add an animated element, follow the same pattern: add a flag, set it in `startAnimations()`, bind it with `.animation(...value:)`.

## Assets

- Images live in `TestApp/Assets.xcassets`. The custom photo `zerotow` is referenced type-safely as `Image(.zerotow)` (generated asset symbol), not by string name.
- `AccentColor` and `AppIcon` are the default template asset sets.
