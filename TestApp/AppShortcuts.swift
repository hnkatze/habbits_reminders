//
//  AppShortcuts.swift
//  TestApp
//
//  Registers the app's App Intents as ready-made Siri phrases and Shortcuts.
//

import AppIntents

struct TestAppShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: MarkHabitDoneIntent(),
      phrases: [
        "Mark a habit done in \(.applicationName)",
        "Complete a \(.applicationName) habit",
      ],
      shortTitle: "Mark Habit Done",
      systemImageName: "checkmark.circle.fill"
    )
  }
}
