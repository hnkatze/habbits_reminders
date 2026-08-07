//
//  LocationPickerMap.swift
//  TestApp
//
//  Interactive map to pick a coordinate for a place reminder. Tap anywhere to
//  drop or move the pin; the geofence radius is drawn as a circle around it.
//  When the coordinate is set from outside (search result or "my location"),
//  the camera recenters; a tap does not recenter, so the map stays put where
//  you touched. Native MapKit — no API key.
//

import MapKit
import SwiftUI

struct LocationPickerMap: View {
  @Binding var coordinate: CLLocationCoordinate2D?
  let radius: Double
  let tintHex: String

  @State private var position: MapCameraPosition = .automatic
  // The last coordinate we set from a tap, so external changes can be told
  // apart from taps and only external ones recenter the camera.
  @State private var lastTapped: CLLocationCoordinate2D?

  var body: some View {
    MapReader { proxy in
      Map(position: $position) {
        UserAnnotation()

        if let coordinate {
          Annotation("", coordinate: coordinate) { pin }
          MapCircle(center: coordinate, radius: radius)
            .foregroundStyle(Color(hex: tintHex).opacity(0.18))
            .stroke(Color(hex: tintHex).opacity(0.8), lineWidth: 1.5)
        }
      }
      .mapControls { MapUserLocationButton() }
      .onTapGesture { screenPoint in
        guard let tapped = proxy.convert(screenPoint, from: .local) else { return }
        lastTapped = tapped
        coordinate = tapped
      }
    }
    .frame(height: 240)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .overlay(alignment: .topLeading) { hint }
    .onChange(of: coordinate?.latitude) { recenterIfExternal() }
    .onChange(of: coordinate?.longitude) { recenterIfExternal() }
    .onAppear { recenterIfExternal() }
  }

  private var pin: some View {
    Image(systemName: "mappin.circle.fill")
      .font(.title)
      .foregroundStyle(Color(hex: tintHex))
      .background(.white, in: .circle)
      .shadow(radius: 2, y: 1)
  }

  @ViewBuilder
  private var hint: some View {
    if coordinate == nil {
      Text("Tap the map to drop a pin")
        .font(.caption2.weight(.medium))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(8)
    }
  }

  // Recenter only when the coordinate arrived from outside a tap.
  private func recenterIfExternal() {
    guard let coordinate else { return }
    if let lastTapped,
      lastTapped.latitude == coordinate.latitude,
      lastTapped.longitude == coordinate.longitude
    {
      return
    }
    withAnimation {
      position = .region(
        MKCoordinateRegion(
          center: coordinate,
          latitudinalMeters: 800,
          longitudinalMeters: 800
        )
      )
    }
  }
}
