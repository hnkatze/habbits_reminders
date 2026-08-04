//
//  PlacesMapView.swift
//  TestApp
//
//  A map of every saved place: colored pins, their geofence radius drawn as a
//  circle, and the user's location. Muted places render dimmed. Uses native
//  MapKit — no API key, no paid capability.
//

import MapKit
import SwiftData
import SwiftUI

struct PlacesMapView: View {
  @Query(sort: \PlaceReminder.createdAt, order: .reverse) private var places: [PlaceReminder]
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Group {
        if places.isEmpty {
          ContentUnavailableView(
            "No places yet",
            systemImage: "mappin.slash",
            description: Text("Add a location reminder to see it on the map.")
          )
        } else {
          map
        }
      }
      .navigationTitle("Places")
      .toolbarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
  }

  private var map: some View {
    Map {
      UserAnnotation()

      ForEach(places) { place in
        Annotation(place.name, coordinate: place.coordinate) {
          pin(for: place)
        }

        MapCircle(center: place.coordinate, radius: place.radius)
          .foregroundStyle(Color(hex: place.colorHex).opacity(place.isActive ? 0.18 : 0.08))
          .stroke(Color(hex: place.colorHex).opacity(place.isActive ? 0.8 : 0.4), lineWidth: 1.5)
      }
    }
    .mapControls {
      MapUserLocationButton()
      MapCompass()
    }
  }

  private func pin(for place: PlaceReminder) -> some View {
    Image(systemName: place.iconName)
      .font(.caption.weight(.bold))
      .foregroundStyle(.white)
      .padding(8)
      .background(Color(hex: place.colorHex).gradient, in: .circle)
      .overlay(Circle().strokeBorder(.white, lineWidth: 2))
      .shadow(radius: 3, y: 1)
      .opacity(place.isActive ? 1 : 0.5)
  }
}
