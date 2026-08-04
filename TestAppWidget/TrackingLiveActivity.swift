//
//  TrackingLiveActivity.swift
//  TestAppWidget
//
//  The place-tracking Live Activity: a route track (a walker closing in on the
//  destination pin) plus distance, on the Lock Screen / StandBy and across every
//  Dynamic Island presentation. Reads TrackingActivityAttributes (shared).
//

import ActivityKit
import Foundation
import SwiftUI
import WidgetKit

struct TrackingLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: TrackingActivityAttributes.self) { context in
      TrackingLockScreenView(context: context)
        .padding()
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      let color = WidgetFormat.color(context.attributes.colorHex)
      let arrived = context.state.arrived

      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label {
            Text(context.attributes.placeName)
              .font(.caption).fontWeight(.semibold).lineLimit(1)
          } icon: {
            Image(systemName: context.attributes.iconName).foregroundStyle(color)
          }
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(arrived ? "Arrived" : WidgetFormat.distance(context.state.distanceMeters))
            .font(.caption).fontWeight(.bold).monospacedDigit()
            .foregroundStyle(arrived ? AnyShapeStyle(.green) : AnyShapeStyle(color))
        }
        DynamicIslandExpandedRegion(.bottom) {
          RouteTrack(
            progress: TrackingLiveActivity.progress(context),
            color: color, arrived: arrived
          )
          .padding(.top, 4)
        }
      } compactLeading: {
        Image(systemName: arrived ? "checkmark.circle.fill" : "figure.walk")
          .foregroundStyle(arrived ? AnyShapeStyle(.green) : AnyShapeStyle(color))
      } compactTrailing: {
        if arrived {
          Image(systemName: "checkmark").foregroundStyle(.green)
        } else {
          Text(WidgetFormat.distance(context.state.distanceMeters)).monospacedDigit()
        }
      } minimal: {
        Image(systemName: arrived ? "checkmark.circle.fill" : context.attributes.iconName)
          .foregroundStyle(arrived ? AnyShapeStyle(.green) : AnyShapeStyle(color))
      }
      .keylineTint(color)
    }
  }

  // How far along the route we are: 0 at the starting distance, 1 on arrival.
  static func progress(_ context: ActivityViewContext<TrackingActivityAttributes>) -> Double {
    if context.state.arrived { return 1 }
    let start = context.attributes.startDistanceMeters
    guard start > 0 else { return 0 }
    return max(0, min(1, 1 - context.state.distanceMeters / start))
  }
}

private struct TrackingLockScreenView: View {
  let context: ActivityViewContext<TrackingActivityAttributes>

  private var color: Color { WidgetFormat.color(context.attributes.colorHex) }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 12) {
        Image(systemName: context.attributes.iconName)
          .font(.title3.weight(.semibold))
          .foregroundStyle(.white)
          .frame(width: 40, height: 40)
          .background(color.gradient, in: .rect(cornerRadius: 11, style: .continuous))

        VStack(alignment: .leading, spacing: 1) {
          Text(context.attributes.placeName).font(.headline).lineLimit(1)
          Text(context.state.arrived ? "You've arrived" : "On your way")
            .font(.caption).foregroundStyle(.secondary)
        }

        Spacer()

        if context.state.arrived {
          Image(systemName: "checkmark.circle.fill").font(.title).foregroundStyle(.green)
        } else {
          VStack(alignment: .trailing, spacing: 0) {
            Text(WidgetFormat.distance(context.state.distanceMeters))
              .font(.title3.weight(.bold)).monospacedDigit()
            Text("to go").font(.caption2).foregroundStyle(.secondary)
          }
        }
      }

      RouteTrack(
        progress: TrackingLiveActivity.progress(context),
        color: color, arrived: context.state.arrived)
    }
  }
}

// A horizontal route: a filled trail with a walker that slides toward the pin.
private struct RouteTrack: View {
  let progress: Double
  let color: Color
  let arrived: Bool

  var body: some View {
    GeometryReader { geo in
      let width = geo.size.width
      let dot: CGFloat = 24
      let pinGap: CGFloat = 28
      let travel = max(0, width - dot - pinGap)
      let p = max(0, min(1, progress))

      ZStack(alignment: .leading) {
        Capsule().fill(.quaternary).frame(height: 5)
        Capsule().fill(color.gradient)
          .frame(width: max(5, p * travel + dot / 2), height: 5)
        Image(systemName: arrived ? "checkmark.circle.fill" : "figure.walk.circle.fill")
          .font(.system(size: dot))
          .foregroundStyle(arrived ? AnyShapeStyle(Color.green) : AnyShapeStyle(color))
          .background(Circle().fill(.background))
          .offset(x: p * travel)
          .animation(.snappy, value: p)
      }
      .frame(height: dot)
      .overlay(alignment: .trailing) {
        Image(systemName: "mappin.circle.fill")
          .font(.system(size: dot))
          .foregroundStyle(color)
          .background(Circle().fill(.background))
      }
    }
    .frame(height: 24)
  }
}

// Self-contained helpers so the widget target stays independent of the app
// module. The app has its own Color+Hex / DistanceFormatter; keeping tiny copies
// here avoids wiring more cross-target shared files into the project.
enum WidgetFormat {
  static func distance(_ meters: Double) -> String {
    meters < 1000 ? "\(Int(meters.rounded())) m" : String(format: "%.1f km", meters / 1000)
  }

  static func color(_ hex: String) -> Color {
    let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    var value: UInt64 = 0
    Scanner(string: cleaned).scanHexInt64(&value)
    let red = Double((value >> 16) & 0xFF) / 255
    let green = Double((value >> 8) & 0xFF) / 255
    let blue = Double(value & 0xFF) / 255
    return Color(red: red, green: green, blue: blue)
  }
}
