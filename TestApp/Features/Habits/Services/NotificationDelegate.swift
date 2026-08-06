//
//  NotificationDelegate.swift
//  TestApp
//
//  Handles taps on notification action buttons. Wired at launch in TestAppApp.
//  "Done" marks the habit complete via the shared HabitCompletion helper; the
//  two snooze buttons re-fire the notification later. Also keeps banners
//  visible while the app is in the foreground.
//

import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
  static let shared = NotificationDelegate()

  // Show the banner even when the app is open.
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    [.banner, .sound]
  }

  // Route an action-button tap.
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {
    // Pull the primitives off the (non-Sendable) content before hopping to
    // the main actor, so nothing unsendable crosses the boundary.
    let content = response.notification.request.content
    let title = content.title
    let body = content.body
    let category = content.categoryIdentifier
    let habitID = content.userInfo[Key.habitID] as? String
    let iconName = content.userInfo[Key.iconName] as? String
    let colorHex = content.userInfo[Key.colorHex] as? String

    switch response.actionIdentifier {
    case NotificationManager.Action.done:
      guard let habitID else { break }
      await HabitCompletion.markDone(notificationID: habitID)

    case NotificationManager.Action.snooze10:
      await NotificationManager.snooze(
        title: title, body: body, category: category,
        habitID: habitID, iconName: iconName, colorHex: colorHex, minutes: 10)

    case NotificationManager.Action.snooze60:
      await NotificationManager.snooze(
        title: title, body: body, category: category,
        habitID: habitID, iconName: iconName, colorHex: colorHex, minutes: 60)

    default:
      break
    }
  }

  private enum Key {
    static let habitID = "habitID"
    static let iconName = "iconName"
    static let colorHex = "colorHex"
  }
}
