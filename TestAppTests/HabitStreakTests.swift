//
//  HabitStreakTests.swift
//  TestAppTests
//
//  Pure-logic tests for Habit's derived streak/completion values. Uses an
//  in-memory SwiftData container so relationships behave exactly like at runtime
//  without touching disk.
//

import Foundation
import SwiftData
import Testing

@testable import TestApp

@MainActor
@Suite("Habit streak")
struct HabitStreakTests {

  private func makeContext() throws -> ModelContext {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: Habit.self, PlaceReminder.self, configurations: config)
    return ModelContext(container)
  }

  private func complete(_ habit: Habit, daysAgo offsets: [Int], in context: ModelContext) {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)
    for offset in offsets {
      let day = calendar.date(byAdding: .day, value: -offset, to: today)!
      context.insert(HabitEntry(date: day, habit: habit))
    }
  }

  @Test("no entries means no streak")
  func emptyStreak() throws {
    let context = try makeContext()
    let habit = Habit(name: "Read")
    context.insert(habit)
    #expect(habit.currentStreak == 0)
    #expect(habit.isCompletedToday == false)
  }

  @Test("counts consecutive days ending today")
  func consecutiveEndingToday() throws {
    let context = try makeContext()
    let habit = Habit(name: "Read")
    context.insert(habit)
    complete(habit, daysAgo: [0, 1, 2], in: context)
    #expect(habit.currentStreak == 3)
    #expect(habit.isCompletedToday == true)
  }

  @Test("today not done yet, but yesterday keeps the streak alive")
  func streakFromYesterday() throws {
    let context = try makeContext()
    let habit = Habit(name: "Read")
    context.insert(habit)
    complete(habit, daysAgo: [1, 2], in: context)
    #expect(habit.currentStreak == 2)
    #expect(habit.isCompletedToday == false)
  }

  @Test("a gap breaks the streak")
  func gapBreaksStreak() throws {
    let context = try makeContext()
    let habit = Habit(name: "Read")
    context.insert(habit)
    // Done today and two days ago, but NOT yesterday.
    complete(habit, daysAgo: [0, 2], in: context)
    #expect(habit.currentStreak == 1)
  }

  @Test("duplicate entries on the same day count once")
  func duplicateSameDay() throws {
    let context = try makeContext()
    let habit = Habit(name: "Read")
    context.insert(habit)
    complete(habit, daysAgo: [0, 0, 1], in: context)
    #expect(habit.currentStreak == 2)
  }
}
