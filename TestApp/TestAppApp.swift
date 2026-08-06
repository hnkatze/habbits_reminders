//
//  TestAppApp.swift
//  TestApp
//
//  Created by Hector  on 31/7/26.
//

import SwiftData
import SwiftUI
import UserNotifications

@main
struct TestAppApp: App {
  init() {
    // Handle notification action buttons ("Done" / snooze) and register the
    // action sets. Cross-platform: no UIApplicationDelegate needed.
    UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    NotificationManager.registerCategories()
  }

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
