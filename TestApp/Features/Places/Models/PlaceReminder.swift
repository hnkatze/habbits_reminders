//
//  PlaceReminder.swift
//  TestApp
//
//  A location-based reminder: fires when you ARRIVE at a place. Its content is
//  either a text note or a checklist (isList == true → use `items`).
//

import CoreLocation
import Foundation
import SwiftData

@Model
final class PlaceReminder {
  // Most active geofences we arm at once. iOS caps an app at 20 monitored
  // regions; we stay well under that so there's always headroom.
  static let activeLimit = 10

  var name: String
  var iconName: String
  var colorHex: String
  var createdAt: Date

  var latitude: Double
  var longitude: Double
  var radius: Double
  var notificationID: String = ""

  // Which template this place follows. Stored as the raw String (see `kind`);
  // defaults to generic so existing rows migrate automatically (lightweight).
  var kindRaw: String = PlaceKind.generic.rawValue

  // Parking-only extras. Optional with a nil default → lightweight migration.
  var parkingSpot: String?
  var parkingExpiresAt: Date?

  // Content mode: a free-text note, or a checklist of items.
  var isList: Bool
  var note: String

  // Whether the arrival geofence is armed. Muting keeps the place but stops its
  // reminder — handy once you've already been there. Defaults true → new places
  // are active, and existing rows migrate to active automatically.
  var isActive: Bool = true

  @Relationship(deleteRule: .cascade, inverse: \ChecklistItem.reminder)
  var items: [ChecklistItem] = []

  init(
    name: String,
    iconName: String = "mappin.circle.fill",
    colorHex: String = "#007AFF",
    latitude: Double,
    longitude: Double,
    radius: Double = 150,
    kind: PlaceKind = .generic,
    isList: Bool = false,
    note: String = "",
    parkingSpot: String? = nil,
    parkingExpiresAt: Date? = nil,
    createdAt: Date = .now
  ) {
    self.name = name
    self.iconName = iconName
    self.colorHex = colorHex
    self.latitude = latitude
    self.longitude = longitude
    self.radius = radius
    self.kindRaw = kind.rawValue
    self.isList = isList
    self.note = note
    self.parkingSpot = parkingSpot
    self.parkingExpiresAt = parkingExpiresAt
    self.notificationID = UUID().uuidString
    self.createdAt = createdAt
  }
}

extension PlaceReminder {
  // The template this place follows, backed by `kindRaw`.
  var kind: PlaceKind {
    get { PlaceKind(rawValue: kindRaw) ?? .generic }
    set { kindRaw = newValue.rawValue }
  }

  // Whether a parking place has a meter time set that is still in the future.
  var hasActiveParkingMeter: Bool {
    guard kind == .parking, let expiry = parkingExpiresAt else { return false }
    return expiry > .now
  }

  // Short description for the list row.
  var summary: String {
    if kind == .parking, let expiry = parkingExpiresAt {
      let spot = parkingSpot.map { "Spot \($0) · " } ?? ""
      return spot
        + (expiry > .now
          ? "expires \(expiry.formatted(.relative(presentation: .named)))" : "expired")
    }
    if isList {
      let done = items.filter(\.isDone).count
      return "\(done)/\(items.count) items"
    }
    return note.isEmpty ? "Note" : note
  }

  // The place as a CLLocation, for distance math.
  var location: CLLocation {
    CLLocation(latitude: latitude, longitude: longitude)
  }

  // The place as a map coordinate, for MapKit annotations and circles.
  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }

  // Distance in meters from a given location (e.g. the user's current one).
  func distance(from other: CLLocation) -> CLLocationDistance {
    location.distance(from: other)
  }
}
