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
    let context = AppModelContainer.shared.mainContext
    let id = habit.id
    let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.notificationID == id })

    guard let model = try context.fetch(descriptor).first else {
      return .result(dialog: "I couldn't find that habit.")
    }

    let calendar = Calendar.current
    let alreadyDone = model.entries.contains { calendar.isDate($0.date, inSameDayAs: .now) }
    if alreadyDone {
      return .result(
        dialog: "\(model.name) is already done today — \(model.currentStreak)-day streak. 🔥")
    }

    context.insert(HabitEntry(date: .now, habit: model))
    try context.save()
    return .result(dialog: "Marked \(model.name) as done. \(model.currentStreak)-day streak! 🔥")
  }
}
