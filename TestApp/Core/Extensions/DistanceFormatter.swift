//
//  DistanceFormatter.swift
//  TestApp
//
//  Formats a distance in meters as a short "350 m" / "1.2 km" string. Kept in
//  Core so both the place list and (later) the Live Activity render distances
//  the same way.
//

import CoreLocation

enum DistanceFormatter {
  static func string(forMeters meters: CLLocationDistance) -> String {
    if meters < 1000 {
      return "\(Int(meters.rounded())) m"
    }
    return String(format: "%.1f km", meters / 1000)
  }
}
