//
//  LiveActivityManager.swift
//  TestApp
//
//  Owns the lifecycle of the place-tracking Live Activity: start it for a place,
//  push distance updates as the user moves, and end it. ActivityKit is iOS-only,
//  so the ActivityKit calls are compiled out elsewhere — the public API stays
//  callable (and no-ops) on other platforms so the views don't need guards.
//

import CoreLocation
import Foundation

#if os(iOS)
  import ActivityKit
#endif

@MainActor
@Observable
final class LiveActivityManager {
  // The notificationID of the place currently being tracked, or nil if none.
  private(set) var trackedPlaceID: String?

  var isTracking: Bool { trackedPlaceID != nil }

  func isTracking(_ place: PlaceReminder) -> Bool {
    trackedPlaceID == place.notificationID
  }

  #if os(iOS)
    private var activity: Activity<TrackingActivityAttributes>?
    private var target: CLLocation?
    private var radius: Double = 0
  #endif

  // Start a Live Activity that tracks the distance to `place`.
  func start(tracking place: PlaceReminder, from userLocation: CLLocation?) {
    #if os(iOS)
      guard ActivityAuthorizationInfo().areActivitiesEnabled, activity == nil else { return }

      let placeLocation = place.location
      target = placeLocation
      radius = place.radius

      let meters = userLocation?.distance(from: placeLocation) ?? 0
      let arrived = userLocation != nil && meters <= place.radius
      // Never zero, so the route track always has a sensible baseline.
      let start = max(meters, place.radius)

      // Snapshot the content for the Lock Screen. Cap the list so the activity
      // payload stays comfortably under ActivityKit's ~4 KB budget.
      let items = place.items.prefix(12).map {
        TrackingActivityAttributes.Item(text: $0.text, done: $0.isDone)
      }
      let attributes = TrackingActivityAttributes(
        placeName: place.name, iconName: place.iconName, colorHex: place.colorHex,
        startDistanceMeters: start,
        isList: place.isList, note: place.note, items: Array(items))
      let state = TrackingActivityAttributes.ContentState(
        distanceMeters: meters, arrived: arrived)

      do {
        activity = try Activity.request(
          attributes: attributes,
          content: .init(state: state, staleDate: nil))
        trackedPlaceID = place.notificationID
      } catch {
        activity = nil
        target = nil
      }
    #endif
  }

  // Push a fresh distance based on the user's latest location.
  func updateFromLocation(_ userLocation: CLLocation) async {
    #if os(iOS)
      guard let activity, let target else { return }
      let meters = userLocation.distance(from: target)
      let arrived = meters <= radius
      let state = TrackingActivityAttributes.ContentState(
        distanceMeters: meters, arrived: arrived)
      await activity.update(.init(state: state, staleDate: nil))
    #endif
  }

  // End the current activity (if any) and clear tracking state.
  func stop() async {
    #if os(iOS)
      if let activity {
        await activity.end(
          .init(state: activity.content.state, staleDate: nil),
          dismissalPolicy: .immediate)
      }
      activity = nil
      target = nil
    #endif
    trackedPlaceID = nil
  }
}
