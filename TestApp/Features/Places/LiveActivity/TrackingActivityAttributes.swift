//
//  TrackingActivityAttributes.swift
//  TestApp
//
//  Shared Live Activity contract between the app (which starts/updates the
//  activity) and the widget extension (which renders it). This one file is
//  compiled into BOTH targets — ActivityKit matches the running activity to the
//  widget by the attributes type's name.
//
//  Guarded to iOS: ActivityKit's module imports on macOS, but the
//  ActivityAttributes protocol is unavailable there, so a canImport check is not
//  enough — the macOS build of the app needs this compiled out entirely.
//

#if os(iOS)
  import ActivityKit
  import Foundation

  struct TrackingActivityAttributes: ActivityAttributes {
    // The parts that change while tracking.
    public struct ContentState: Codable, Hashable {
      public var distanceMeters: Double
      public var arrived: Bool

      public init(distanceMeters: Double, arrived: Bool) {
        self.distanceMeters = distanceMeters
        self.arrived = arrived
      }
    }

    // Fixed for the life of the activity.
    public var placeName: String
    public var iconName: String
    public var colorHex: String
    // Distance (meters) when tracking began — the baseline for the route track.
    public var startDistanceMeters: Double

    public init(
      placeName: String, iconName: String, colorHex: String, startDistanceMeters: Double
    ) {
      self.placeName = placeName
      self.iconName = iconName
      self.colorHex = colorHex
      self.startDistanceMeters = startDistanceMeters
    }
  }
#endif
