//
//  PlaceKind.swift
//  TestApp
//
//  The template a place reminder follows. Each kind is a preset (icon, tint,
//  and whether its content leans on a checklist or a note) plus, for some kinds,
//  extra fields on PlaceReminder (e.g. parking spot + meter expiry). Stored as a
//  raw String so adding it to the model is a lightweight SwiftData migration.
//

import Foundation

enum PlaceKind: String, Codable, CaseIterable, Identifiable {
  case generic
  case shopping
  case parking
  case gym
  case travel
  case event

  var id: String { rawValue }

  // Menu/label text.
  var label: String {
    switch self {
    case .generic: "Place"
    case .shopping: "Shopping"
    case .parking: "Parking"
    case .gym: "Gym"
    case .travel: "Travel"
    case .event: "Event"
    }
  }

  // SF Symbol suggested when the user picks this kind (they can still change it).
  var defaultIcon: String {
    switch self {
    case .generic: "mappin.circle.fill"
    case .shopping: "cart.fill"
    case .parking: "parkingsign.circle.fill"
    case .gym: "dumbbell.fill"
    case .travel: "airplane"
    case .event: "ticket.fill"
    }
  }

  // Suggested tint (hex) matching the create form's palette.
  var defaultColorHex: String {
    switch self {
    case .generic: "#007AFF"
    case .shopping: "#34C759"
    case .parking: "#FF9500"
    case .gym: "#AF52DE"
    case .travel: "#007AFF"
    case .event: "#FF2D55"
    }
  }

  // Whether this kind's content is naturally a checklist (vs a free-text note).
  var prefersList: Bool {
    switch self {
    case .shopping, .gym: true
    case .generic, .parking, .travel, .event: false
    }
  }

  // Only parking carries the spot + meter-expiry fields for now.
  var usesParkingDetails: Bool { self == .parking }
}
