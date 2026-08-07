//
//  PlaceReminderRow.swift
//  TestApp
//
//  List row for a location reminder: a gradient icon chip, the name, its content
//  summary, and a distance pill that lights up and pulses when you get close.
//

import CoreLocation
import SwiftUI

struct PlaceReminderRow: View {
  let reminder: PlaceReminder
  var userLocation: CLLocation?

  private var color: Color { Color(hex: reminder.colorHex) }

  private var distanceMeters: Double? {
    guard let userLocation else { return nil }
    return reminder.distance(from: userLocation)
  }

  // "Getting close" once within twice the geofence radius.
  private var isNear: Bool {
    guard let distanceMeters else { return false }
    return distanceMeters <= reminder.radius * 2
  }

  // Summary glyph reflects the kind: a running meter, a checklist, or a note.
  private var summaryIcon: String {
    switch reminder.kind {
    case .parking: reminder.parkingExpiresAt != nil ? "timer" : "parkingsign"
    default: reminder.isList ? "checklist" : "note.text"
    }
  }

  var body: some View {
    HStack(spacing: 14) {
      iconChip

      VStack(alignment: .leading, spacing: 3) {
        HStack(spacing: 5) {
          Text(reminder.name)
            .font(.body.weight(.semibold))
          if reminder.kind != .generic {
            Text(reminder.kind.label)
              .font(.caption2.weight(.semibold))
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(color.opacity(0.15), in: .capsule)
              .foregroundStyle(color)
          }
          if !reminder.isActive {
            Image(systemName: "bell.slash.fill")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }
        Label(reminder.summary, systemImage: summaryIcon)
          .font(.caption)
          .foregroundStyle(.secondary)
          .labelStyle(.titleAndIcon)
          .lineLimit(1)
      }

      Spacer()

      if let distanceMeters {
        distancePill(distanceMeters)
      }
    }
    .padding(.vertical, 6)
  }

  private var iconChip: some View {
    Image(systemName: reminder.iconName)
      .font(.title3.weight(.semibold))
      .foregroundStyle(.white)
      .frame(width: 46, height: 46)
      .background(
        LinearGradient(
          colors: [color, color.opacity(0.7)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing),
        in: .rect(cornerRadius: 13, style: .continuous)
      )
      .shadow(color: color.opacity(0.35), radius: 5, y: 3)
      .opacity(reminder.isActive ? 1 : 0.55)
      .grayscale(reminder.isActive ? 0 : 0.6)
  }

  private func distancePill(_ meters: Double) -> some View {
    HStack(spacing: 4) {
      Image(systemName: "location.fill")
        .symbolEffect(.variableColor.iterative, isActive: isNear)
      Text(DistanceFormatter.string(forMeters: meters))
        .contentTransition(.numericText())
        .monospacedDigit()
    }
    .font(.caption.weight(.medium))
    .foregroundStyle(isNear ? AnyShapeStyle(color) : AnyShapeStyle(.secondary))
    .padding(.horizontal, 10)
    .padding(.vertical, 5)
    .background(
      isNear ? AnyShapeStyle(color.opacity(0.15)) : AnyShapeStyle(.quaternary),
      in: .capsule
    )
    .animation(.snappy, value: isNear)
  }
}
