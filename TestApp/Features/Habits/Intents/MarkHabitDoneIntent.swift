//
//  MarkHabitDoneIntent.swift
//  TestApp
//
//  "Mark <habit> done" for Siri and Shortcuts. Runs in the app process against
//  the shared SwiftData store, so it works without opening the app.
//

import AppIntents
import SwiftData

struct MarkHabitDoneIntent: AppIntent {
  static var title: LocalizedStringResource = "Mark Habit Done"
  static var description = IntentDescription("Marks a habit as completed for today.")

  @Parameter(title: "Habit")
  var habit: HabitEntity

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    guard let outcome = HabitCompletion.markDone(notificationID: habit.id) else {
      return .result(dialog: "I couldn't find that habit.")
    }

    if outcome.wasAlreadyDone {
      return .result(
        dialog: "\(outcome.name) is already done today — \(outcome.streak)-day streak. 🔥")
    }
    return .result(dialog: "Marked \(outcome.name) as done. \(outcome.streak)-day streak! 🔥")
  }
}
