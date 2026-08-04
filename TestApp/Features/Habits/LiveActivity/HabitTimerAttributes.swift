//
//  HabitTimerAttributes.swift
//  TestApp
//
//  Shared contract for the habit focus-timer Live Activity. Compiled into both
//  the app and the widget (like TrackingActivityAttributes). iOS-only because
//  ActivityAttributes is unavailable on macOS.
//

#if os(iOS)
  import ActivityKit
  import Foundation

  struct HabitTimerAttributes: ActivityAttributes {
    // The countdown target. The widget renders it with Text(timerInterval:),
    // which ticks on its own — no periodic updates from the app needed.
    public struct ContentState: Codable, Hashable {
      public var endDate: Date

      public init(endDate: Date) {
        self.endDate = endDate
      }
    }

    public var habitName: String
    public var iconName: String
    public var colorHex: String

    public init(habitName: String, iconName: String, colorHex: String) {
      self.habitName = habitName
      self.iconName = iconName
      self.colorHex = colorHex
    }
  }
#endif
