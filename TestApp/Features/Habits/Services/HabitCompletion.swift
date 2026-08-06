//
//  HabitCompletion.swift
//  TestApp
//
//  Marks a habit done for today against the shared SwiftData store, keyed by
//  its notificationID. Shared by MarkHabitDoneIntent (Siri / Shortcuts) and by
//  the notification "Done" action (NotificationDelegate), so the logic lives in
//  exactly one place.
//

import Foundation
import SwiftData

@MainActor
enum HabitCompletion {

  // Outcome of marking a habit done — enough for a Siri dialog or a log line.
  struct Outcome {
    let name: String
    let streak: Int
    let wasAlreadyDone: Bool
  }

  // Inserts today's entry if the habit isn't already done today. Returns nil
  // when no habit matches the id. Idempotent for the same day.
  @discardableResult
  static func markDone(notificationID: String) -> Outcome? {
    let context = AppModelContainer.shared.mainContext
    let descriptor = FetchDescriptor<Habit>(
      predicate: #Predicate { $0.notificationID == notificationID })

    guard let habit = try? context.fetch(descriptor).first else { return nil }

    let calendar = Calendar.current
    let alreadyDone = habit.entries.contains { calendar.isDate($0.date, inSameDayAs: .now) }
    if !alreadyDone {
      context.insert(HabitEntry(date: .now, habit: habit))
      try? context.save()
    }

    return Outcome(name: habit.name, streak: habit.currentStreak, wasAlreadyDone: alreadyDone)
  }
}
