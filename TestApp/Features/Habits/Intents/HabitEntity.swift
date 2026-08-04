//
//  HabitEntity.swift
//  TestApp
//
//  Exposes habits to App Intents so Siri and Shortcuts can offer "which habit?"
//  Backed by the shared SwiftData store, keyed by the stable notificationID.
//

import AppIntents
import SwiftData

struct HabitEntity: AppEntity {
  let id: String
  let name: String

  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Habit"

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)")
  }

  static var defaultQuery = HabitEntityQuery()
}

struct HabitEntityQuery: EntityQuery {
  @MainActor
  func entities(for identifiers: [HabitEntity.ID]) async throws -> [HabitEntity] {
    try fetchAll().filter { identifiers.contains($0.id) }
  }

  @MainActor
  func suggestedEntities() async throws -> [HabitEntity] {
    try fetchAll()
  }

  @MainActor
  private func fetchAll() throws -> [HabitEntity] {
    let context = AppModelContainer.shared.mainContext
    let habits = try context.fetch(
      FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
    return habits.map { HabitEntity(id: $0.notificationID, name: $0.name) }
  }
}
