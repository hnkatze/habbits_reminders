//
//  TestAppWidgetBundle.swift
//  TestAppWidget
//
//  Entry point for the widget extension. Vends the Live Activities; home-screen
//  widgets can be added to the bundle later.
//

import SwiftUI
import WidgetKit

@main
struct TestAppWidgetBundle: WidgetBundle {
  var body: some Widget {
    TrackingLiveActivity()
    HabitTimerLiveActivity()
    ParkingLiveActivity()
  }
}
