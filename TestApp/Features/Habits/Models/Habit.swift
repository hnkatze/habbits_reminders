//
//  Habit.swift
//  TestApp
//
//  SwiftData model for a recurring habit (time-based). Location reminders now
//  live in their own model (PlaceReminder), so Habit stays focused on streaks
//  and daily completion.
//

import Foundation
import SwiftData

@Model
final class Habit {
  var name: String
  var iconName: String
  var colorHex: String
  var createdAt: Date

  // Optional daily reminder time. Optional → automatic SwiftData migration.
  var reminderTime: Date?

  // Days the reminder fires on, as Calendar weekday numbers (1 = Sunday … 7 =
  // Saturday). Defaults to every day → existing habits migrate to "daily" with
  // no change in behavior.
  var weekdays: [Int] = [1, 2, 3, 4, 5, 6, 7]

  // Optional focus-timer length in minutes. Drives the timer Live Activity.
  var durationMinutes: Int?

  // Stable id used to key the scheduled notification.
  var notificationID: String = ""

  // One-to-many: a habit has many completion entries. `.cascade` means
  // deleting the habit also deletes its entries (no orphans left behind).
  @Relationship(deleteRule: .cascade, inverse: \HabitEntry.habit)
  var entries: [HabitEntry] = []

  init(
    name: String,
    iconName: String = "star.fill",
    colorHex: String = "#FB0021",
    reminderTime: Date? = nil,
    weekdays: [Int] = [1, 2, 3, 4, 5, 6, 7],
    durationMinutes: Int? = nil,
    createdAt: Date = .now
  ) {
    self.name = name
    self.iconName = iconName
    self.colorHex = colorHex
    self.reminderTime = reminderTime
    self.weekdays = weekdays
    self.durationMinutes = durationMinutes
    self.notificationID = UUID().uuidString
    self.createdAt = createdAt
  }
}

// Derived values — computed, never stored.
extension Habit {
  func isCompleted(on day: Date, calendar: Calendar = .current) -> Bool {
    entries.contains { calendar.isDate($0.date, inSameDayAs: day) }
  }

  var isCompletedToday: Bool { isCompleted(on: .now) }

  // Consecutive completed days ending today (or yesterday if today isn't done).
  var currentStreak: Int {
    let calendar = Calendar.current
    let completedDays = Set(entries.map { calendar.startOfDay(for: $0.date) })

    var streak = 0
    var day = calendar.startOfDay(for: .now)
    if !completedDays.contains(day) {
      day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
    }
    while completedDays.contains(day) {
      streak += 1
      guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
      day = previous
    }
    return streak
  }
}
