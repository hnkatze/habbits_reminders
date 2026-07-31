//
//  NotificationManager.swift
//  TestApp
//
//  Thin wrapper over UNUserNotificationCenter for habit reminders — both
//  time-based (daily) and location-based (geofence). Local notifications need
//  NO paid capability and NO App Group; they work on a free account.
//

import Foundation
import UserNotifications
import CoreLocation

@MainActor
enum NotificationManager {

    // Ask the user for permission. Returns whether it was granted.
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Daily time reminder

    static func scheduleDailyReminder(id: String, habitName: String, at time: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = "Habit reminder"
        content.body = "Time to: \(habitName)"
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    static func cancelReminder(id: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [id])
    }

    // MARK: - Location (geofence) reminder

    // Fires when the user ENTERS a circular region around the coordinate.
    // Keyed by "loc-<id>" so it never collides with the daily reminder's id.
    static func scheduleLocationReminder(
        id: String,
        habitName: String,
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
}
