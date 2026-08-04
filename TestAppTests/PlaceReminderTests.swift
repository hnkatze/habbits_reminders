//
//  PlaceReminderTests.swift
//  TestAppTests
//
//  Tests the row summary shown for a PlaceReminder in both content modes.
//

import Foundation
import SwiftData
import Testing

@testable import TestApp

@MainActor
@Suite("PlaceReminder summary")
struct PlaceReminderTests {

  private func makeContext() throws -> ModelContext {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: Habit.self, PlaceReminder.self, configurations: config)
    return ModelContext(container)
  }

  @Test("note mode shows the note text")
  func noteSummary() {
    let reminder = PlaceReminder(
      name: "Store", latitude: 0, longitude: 0, isList: false, note: "buy milk")
    #expect(reminder.summary == "buy milk")
  }

  @Test("note mode with empty note shows a placeholder")
  func emptyNoteSummary() {
    let reminder = PlaceReminder(
      name: "Store", latitude: 0, longitude: 0, isList: false, note: "")
    #expect(reminder.summary == "Note")
  }

  @Test("list mode shows done/total item count")
  func listSummary() throws {
    let context = try makeContext()
    let reminder = PlaceReminder(name: "Store", latitude: 0, longitude: 0, isList: true)
    context.insert(reminder)
    context.insert(ChecklistItem(text: "Milk", isDone: true, reminder: reminder))
    context.insert(ChecklistItem(text: "Eggs", isDone: false, reminder: reminder))
    #expect(reminder.summary == "1/2 items")
  }
}
