//
//  ParkingActivityAttributes.swift
//  TestApp
//
//  Shared contract for the parking-meter Live Activity. Compiled into both the
//  app and the widget (like HabitTimerAttributes / TrackingActivityAttributes).
//  iOS-only because ActivityAttributes is unavailable on macOS.
//

#if os(iOS)
  import ActivityKit
  import Foundation

  struct ParkingActivityAttributes: ActivityAttributes {
    // The meter's expiry. The widget renders it with Text(timerInterval:), which
    // ticks on its own — no periodic updates from the app needed.
    public struct ContentState: Codable, Hashable {
      public var endDate: Date

      public init(endDate: Date) {
        self.endDate = endDate
      }
    }

    public var placeName: String
    public var spot: String?
    public var iconName: String
    public var colorHex: String

    public init(placeName: String, spot: String?, iconName: String, colorHex: String) {
      self.placeName = placeName
      self.spot = spot
      self.iconName = iconName
      self.colorHex = colorHex
    }
  }
#endif
