//
//  AppModelContainer.swift
//  TestApp
//
//  A single shared SwiftData container, so both the SwiftUI app and the
//  App Intents (Siri / Shortcuts), which run outside the view hierarchy, read
//  and write the same store.
//

import SwiftData

enum AppModelContainer {
  static let shared: ModelContainer = {
    do {
      return try ModelContainer(for: Habit.self, PlaceReminder.self)
    } catch {
      fatalError("Failed to create the shared ModelContainer: \(error)")
    }
  }()
}
