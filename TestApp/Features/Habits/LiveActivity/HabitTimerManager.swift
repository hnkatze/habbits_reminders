//
//  HabitTimerManager.swift
//  TestApp
//
//  Starts and stops the habit focus-timer Live Activity. The countdown ticks in
//  the widget via Text(timerInterval:), so no background work or updates are
//  needed — start it and let it run. iOS-only under the hood; the API no-ops
//  elsewhere so the views stay guard-free.
//

import Foundation

#if os(iOS)
  import ActivityKit
#endif

@MainActor
@Observable
final class HabitTimerManager {
  // notificationID of the habit whose timer is running, or nil.
  private(set) var runningHabitID: String?

  var isRunning: Bool { runningHabitID != nil }

  func isRunning(_ habit: Habit) -> Bool {
    runningHabitID == habit.notificationID
  }

  #if os(iOS)
    private var activity: Activity<HabitTimerAttributes>?
  #endif

  func start(habit: Habit, minutes: Int) {
    #if os(iOS)
      guard ActivityAuthorizationInfo().areActivitiesEnabled, activity == nil else { return }

      let end = Date.now.addingTimeInterval(TimeInterval(minutes * 60))
      let attributes = HabitTimerAttributes(
        habitName: habit.name, iconName: habit.iconName, colorHex: habit.colorHex)
      let state = HabitTimerAttributes.ContentState(endDate: end)

      do {
        activity = try Activity.request(
          attributes: attributes,
          content: .init(state: state, staleDate: end))
        runningHabitID = habit.notificationID
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
    runningHabitID = nil
  }
}
