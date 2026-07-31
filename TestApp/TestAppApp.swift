//
//  TestAppApp.swift
//  TestApp
//
//  Created by Hector  on 31/7/26.
//

import SwiftUI
import SwiftData

@main
struct TestAppApp: App {
    var body: some Scene {
        WindowGroup {
            HabitsListView()
        }
        // Creates the SwiftData store and injects the modelContext into the
        // environment. SwiftData discovers HabitEntry and ChecklistItem through
        // their relationships.
        .modelContainer(for: [Habit.self, PlaceReminder.self])
    }
}
