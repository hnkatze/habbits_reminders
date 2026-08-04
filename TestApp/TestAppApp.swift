//
//  TestAppApp.swift
//  TestApp
//
//  Created by Hector  on 31/7/26.
//

import SwiftData
import SwiftUI

@main
struct TestAppApp: App {
  var body: some Scene {
    WindowGroup {
      HabitsListView()
    }
    // Inject the SHARED SwiftData store (see AppModelContainer) so the App
    // Intents, which run outside the view hierarchy, read/write the same
    // data. SwiftData discovers HabitEntry and ChecklistItem via relations.
    .modelContainer(AppModelContainer.shared)
  }
}
