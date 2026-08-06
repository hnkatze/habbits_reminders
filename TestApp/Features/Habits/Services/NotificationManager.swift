//
//  NotificationManager.swift
//  TestApp
//
//  Thin wrapper over UNUserNotificationCenter for habit reminders — both
//  time-based (daily / per-weekday) and location-based (geofence). Local
//  notifications need NO paid capability and NO App Group; they work on a free
//  account.
//
//  Each reminder carries its own SF Symbol + color. We render that symbol onto
//  a rounded, colored tile and attach it (UNNotificationAttachment) so the
//  banner shows the reminder's own icon as a thumbnail. iOS always keeps the
//  app icon in the corner — that part is not ours to change.
//
//  Notifications ship with action buttons (see Category / Action below), handled
//  by NotificationDelegate: habits get "Done" + two snoozes, places get the two
//  snoozes. The reminder's identity + look travel in `content.userInfo` so a
//  snoozed copy can be rebuilt (icon included) without touching the store.
//

import CoreLocation
import Foundation
import UserNotifications

#if canImport(UIKit)
  import SwiftUI
  import UIKit
#endif

@MainActor
enum NotificationManager {

  // Category identifiers wired to the action sets registered in
  // `registerCategories()`. A notification's `categoryIdentifier` picks which
  // buttons it shows.
  enum Category {
    static let habit = "habit-reminder"
    static let place = "place-reminder"
  }

  // Action identifiers matched in NotificationDelegate.
  enum Action {
    static let done = "HABIT_DONE"
    static let snooze10 = "SNOOZE_10"
    static let snooze60 = "SNOOZE_60"
  }

  // Keys used inside `content.userInfo`.
  private enum InfoKey {
    static let habitID = "habitID"
    static let iconName = "iconName"
    static let colorHex = "colorHex"
  }

  // Ask the user for permission. Returns whether it was granted.
  static func requestAuthorization() async -> Bool {
    do {
      return try await UNUserNotificationCenter.current()
        .requestAuthorization(options: [.alert, .sound, .badge])
    } catch {
      return false
    }
  }

  // Register the action buttons. Call once at launch (see TestAppApp).
  static func registerCategories() {
    let done = UNNotificationAction(identifier: Action.done, title: "Done", options: [])
    let snooze10 = UNNotificationAction(
      identifier: Action.snooze10, title: "Snooze 10 min", options: [])
    let snooze60 = UNNotificationAction(
      identifier: Action.snooze60, title: "Snooze 1 h", options: [])

    let habit = UNNotificationCategory(
      identifier: Category.habit,
      actions: [done, snooze10, snooze60],
      intentIdentifiers: [],
      options: []
    )
    let place = UNNotificationCategory(
      identifier: Category.place,
      actions: [snooze10, snooze60],
      intentIdentifiers: [],
      options: []
    )
    UNUserNotificationCenter.current().setNotificationCategories([habit, place])
  }

  // MARK: - Daily / per-weekday reminder

  // Schedules the habit reminder on the given `weekdays` (Calendar numbers,
  // 1 = Sunday … 7 = Saturday). All seven → a single daily trigger (one
  // pending request, friendlier to iOS's 64-request budget); a subset → one
  // trigger per day, keyed "<id>-w<weekday>".
  static func scheduleDailyReminder(
    id: String,
    habitName: String,
    iconName: String,
    colorHex: String,
    weekdays: [Int],
    at time: Date
  ) {
    let center = UNUserNotificationCenter.current()
    cancelReminder(id: id)

    let days = weekdays.isEmpty ? Array(1...7) : weekdays
    let clock = Calendar.current.dateComponents([.hour, .minute], from: time)

    func content() -> UNMutableNotificationContent {
      let content = UNMutableNotificationContent()
      content.title = "Habit reminder"
      content.body = "Time to: \(habitName)"
      content.sound = .default
      content.categoryIdentifier = Category.habit
      content.userInfo = [
        InfoKey.habitID: id,
        InfoKey.iconName: iconName,
        InfoKey.colorHex: colorHex,
      ]
      attachIcon(iconName: iconName, colorHex: colorHex, to: content)
      return content
    }

    if days.count >= 7 {
      let trigger = UNCalendarNotificationTrigger(dateMatching: clock, repeats: true)
      center.add(
        UNNotificationRequest(identifier: "\(id)-w0", content: content(), trigger: trigger))
      return
    }

    for weekday in days {
      var components = clock
      components.weekday = weekday
      let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
      center.add(
        UNNotificationRequest(identifier: "\(id)-w\(weekday)", content: content(), trigger: trigger)
      )
    }
  }

  // Removes every request a habit id might own: the legacy base id, the
  // all-days "-w0" request, and each per-weekday one. Canceling an unknown id
  // is a harmless no-op.
  static func cancelReminder(id: String) {
    var identifiers = [id, "\(id)-w0"]
    identifiers.append(contentsOf: (1...7).map { "\(id)-w\($0)" })
    UNUserNotificationCenter.current().removePendingNotificationRequests(
      withIdentifiers: identifiers)
  }

  // MARK: - Location (geofence) reminder

  // Fires when the user ENTERS a circular region around the coordinate.
  // Keyed by "loc-<id>" so it never collides with the daily reminder's id.
  static func scheduleLocationReminder(
    id: String,
    habitName: String,
    iconName: String,
    colorHex: String,
    latitude: Double,
    longitude: Double,
    radius: Double
  ) {
    // UNLocationNotificationTrigger is iOS-only; on macOS this is a no-op.
    #if os(iOS)
      let center = UNUserNotificationCenter.current()
      let identifier = "loc-\(id)"
      center.removePendingNotificationRequests(withIdentifiers: [identifier])

      let content = UNMutableNotificationContent()
      content.title = "You're nearby"
      content.body = "Don't forget: \(habitName)"
      content.sound = .default
      content.categoryIdentifier = Category.place
      content.userInfo = [InfoKey.iconName: iconName, InfoKey.colorHex: colorHex]
      attachIcon(iconName: iconName, colorHex: colorHex, to: content)

      let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      let region = CLCircularRegion(center: coordinate, radius: radius, identifier: identifier)
      region.notifyOnEntry = true
      region.notifyOnExit = false

      let trigger = UNLocationNotificationTrigger(region: region, repeats: true)
      center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    #endif
  }

  static func cancelLocationReminder(id: String) {
    UNUserNotificationCenter.current()
      .removePendingNotificationRequests(withIdentifiers: ["loc-\(id)"])
  }

  // MARK: - Snooze

  // Re-fire a notification once, `minutes` from now, rebuilding its content
  // (icon included) from the pieces the delegate pulled off the original.
  static func snooze(
    title: String,
    body: String,
    category: String,
    habitID: String?,
    iconName: String?,
    colorHex: String?,
    minutes: Int
  ) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    content.categoryIdentifier = category

    var info: [AnyHashable: Any] = [:]
    if let habitID { info[InfoKey.habitID] = habitID }
    if let iconName { info[InfoKey.iconName] = iconName }
    if let colorHex { info[InfoKey.colorHex] = colorHex }
    content.userInfo = info

    if let iconName, let colorHex {
      attachIcon(iconName: iconName, colorHex: colorHex, to: content)
    }

    let trigger = UNTimeIntervalNotificationTrigger(
      timeInterval: TimeInterval(minutes * 60), repeats: false)
    UNUserNotificationCenter.current().add(
      UNNotificationRequest(
        identifier: "snooze-\(UUID().uuidString)", content: content, trigger: trigger))
  }

  // MARK: - Icon attachment

  // Render the reminder's SF Symbol onto a colored tile and attach it as the
  // banner thumbnail. No-op on platforms without UIKit (e.g. macOS), where the
  // notification still fires, just without the image.
  private static func attachIcon(
    iconName: String,
    colorHex: String,
    to content: UNMutableNotificationContent
  ) {
    #if canImport(UIKit)
      guard let attachment = iconAttachment(iconName: iconName, colorHex: colorHex) else { return }
      content.attachments = [attachment]
    #endif
  }

  #if canImport(UIKit)
    private static func iconAttachment(iconName: String, colorHex: String)
      -> UNNotificationAttachment?
    {
      let side: CGFloat = 180
      let size = CGSize(width: side, height: side)

      let image = UIGraphicsImageRenderer(size: size).image { _ in
        let rect = CGRect(origin: .zero, size: size)
        UIColor(Color(hex: colorHex)).setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: side * 0.22).fill()

        let config = UIImage.SymbolConfiguration(pointSize: side * 0.5, weight: .semibold)
        guard
          let symbol = UIImage(systemName: iconName, withConfiguration: config)?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        else { return }

        // Center the symbol; SF Symbols vary in aspect ratio.
        let origin = CGPoint(
          x: (side - symbol.size.width) / 2,
          y: (side - symbol.size.height) / 2
        )
        symbol.draw(at: origin)
      }

      guard let data = image.pngData() else { return nil }

      let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        .appendingPathComponent("notification-icons", isDirectory: true)
      try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      let fileURL = directory.appendingPathComponent("\(UUID().uuidString).png")

      do {
        try data.write(to: fileURL)
        return try UNNotificationAttachment(
          identifier: UUID().uuidString, url: fileURL, options: nil)
      } catch {
        return nil
      }
    }
  #endif
}
