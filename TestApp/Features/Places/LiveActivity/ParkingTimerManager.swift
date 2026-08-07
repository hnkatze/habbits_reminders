//
//  ParkingTimerManager.swift
//  TestApp
//
//  Starts and stops the parking-meter Live Activity. The countdown ticks in the
//  widget via Text(timerInterval:), so no background work or updates are needed —
//  start it and let it run. iOS-only under the hood; the API no-ops elsewhere so
//  the views stay guard-free. Mirrors HabitTimerManager.
//

import Foundation

#if os(iOS)
  import ActivityKit
#endif

@MainActor
@Observable
final class ParkingTimerManager {
  // notificationID of the place whose meter is running, or nil.
  private(set) var runningPlaceID: String?

  var isRunning: Bool { runningPlaceID != nil }

  func isRunning(_ place: PlaceReminder) -> Bool {
    runningPlaceID == place.notificationID
  }

  #if os(iOS)
    private var activity: Activity<ParkingActivityAttributes>?
  #endif

  func start(parking place: PlaceReminder, expiry: Date) {
    #if os(iOS)
      guard ActivityAuthorizationInfo().areActivitiesEnabled, activity == nil else { return }
      guard expiry > .now else { return }

      let attributes = ParkingActivityAttributes(
        placeName: place.name, spot: place.parkingSpot,
        iconName: place.iconName, colorHex: place.colorHex)
      let state = ParkingActivityAttributes.ContentState(endDate: expiry)

      do {
        activity = try Activity.request(
          attributes: attributes,
          content: .init(state: state, staleDate: expiry))
        runningPlaceID = place.notificationID
      } catch {
        activity = nil
      }
    #endif
  }

  func stop() async {
    #if os(iOS)
      if let activity {
        await activity.end(
          .init(state: activity.content.state, staleDate: nil),
          dismissalPolicy: .immediate)
      }
      activity = nil
    #endif
    runningPlaceID = nil
  }
}
