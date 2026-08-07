//
//  PlaceSearchService.swift
//  TestApp
//
//  Native MapKit place lookup — no API key, no paid capability:
//  1. `search` turns free text ("coffee near me") into ranked map results.
//  2. `name` reverse-geocodes a dropped pin into a short human label so the
//     form can auto-fill the reminder name.
//

import CoreLocation
import MapKit

// A single place suggestion: what to show, and where it is.
struct PlaceSearchResult: Identifiable {
  let id = UUID()
  let name: String
  let subtitle: String
  let coordinate: CLLocationCoordinate2D
}

enum PlaceSearchService {
  // Search places by free text, biased toward `center` when we know it.
  static func search(
    _ query: String,
    near center: CLLocationCoordinate2D?
  ) async -> [PlaceSearchResult] {
    let trimmed = query.trimmingCharacters(in: .whitespaces)
    guard trimmed.count > 1 else { return [] }

    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = trimmed
    if let center {
      request.region = MKCoordinateRegion(
        center: center,
        latitudinalMeters: 50_000,
        longitudinalMeters: 50_000
      )
    }

    guard let response = try? await MKLocalSearch(request: request).start() else {
      return []
    }
    return response.mapItems.compactMap { item in
      let coordinate = item.location.coordinate
      return PlaceSearchResult(
        name: item.name ?? "Place",
        subtitle: item.address?.shortAddress ?? "",
        coordinate: coordinate
      )
    }
  }

  // Reverse-geocode a coordinate into a short label (POI, street, or locality).
  static func name(for coordinate: CLLocationCoordinate2D) async -> String? {
    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
    guard let items = try? await request.mapItems else { return nil }
    return items.first?.name
  }
}
