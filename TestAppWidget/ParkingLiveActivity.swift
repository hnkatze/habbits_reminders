//
//  ParkingLiveActivity.swift
//  TestAppWidget
//
//  Parking-meter Live Activity: a self-ticking countdown and progress driven by
//  Text(timerInterval:) / ProgressView(timerInterval:) — no updates from the app
//  needed. Mirrors HabitTimerLiveActivity, with the parking spot as subtitle.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct ParkingLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: ParkingActivityAttributes.self) { context in
      ParkingLockScreenView(context: context)
        .padding()
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      let color = WidgetFormat.color(context.attributes.colorHex)
      let range = Self.range(to: context.state.endDate)

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
          Text(timerInterval: range, countsDown: true)
            .font(.title3.weight(.bold).monospacedDigit())
            .multilineTextAlignment(.trailing)
            .frame(width: 62)
        }
        DynamicIslandExpandedRegion(.bottom) {
          ProgressView(timerInterval: range, countsDown: true) {
            EmptyView()
          } currentValueLabel: {
            EmptyView()
          }
          .tint(color)
          .padding(.top, 2)
        }
      } compactLeading: {
        ProgressView(timerInterval: range, countsDown: true) {
          EmptyView()
        } currentValueLabel: {
          EmptyView()
        }
        .progressViewStyle(.circular)
        .tint(color)
      } compactTrailing: {
        Text(timerInterval: range, countsDown: true)
          .monospacedDigit()
          .frame(width: 44)
      } minimal: {
        ProgressView(timerInterval: range, countsDown: true) {
          EmptyView()
        } currentValueLabel: {
          EmptyView()
        }
        .progressViewStyle(.circular)
        .tint(color)
      }
      .keylineTint(color)
    }
  }

  // Text/ProgressView(timerInterval:) need lowerBound <= upperBound. Once past
  // the end, clamp to end...end so it reads 00:00 instead of crashing.
  static func range(to end: Date) -> ClosedRange<Date> {
    let now = Date.now
    return (now <= end ? now : end)...end
  }
}

private struct ParkingLockScreenView: View {
  let context: ActivityViewContext<ParkingActivityAttributes>

  private var color: Color { WidgetFormat.color(context.attributes.colorHex) }

  private var subtitle: String {
    if let spot = context.attributes.spot, !spot.isEmpty {
      return "Spot \(spot)"
    }
    return "Parking meter"
  }

  var body: some View {
    let range = ParkingLiveActivity.range(to: context.state.endDate)

    return VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 12) {
        Image(systemName: context.attributes.iconName)
          .font(.title3.weight(.semibold))
          .foregroundStyle(.white)
          .frame(width: 40, height: 40)
          .background(color.gradient, in: .rect(cornerRadius: 11, style: .continuous))

        VStack(alignment: .leading, spacing: 1) {
          Text(context.attributes.placeName).font(.headline).lineLimit(1)
          Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }

        Spacer()

        Text(timerInterval: range, countsDown: true)
          .font(.title2.weight(.bold).monospacedDigit())
          .multilineTextAlignment(.trailing)
          .frame(width: 76)
      }

      ProgressView(timerInterval: range, countsDown: true) {
        EmptyView()
      } currentValueLabel: {
        EmptyView()
      }
      .tint(color)
    }
  }
}
