//
//  LocationManager.swift
//  TestApp
//
//  CoreLocation wrapper with two jobs:
//  1. Request "Always" authorization so iOS can monitor geofence regions in the
//     background (a location reminder fires even with the app closed).
//  2. While the app is in the foreground, publish `currentLocation` so the list
//     can show how far each saved place is. Updates are started/stopped by the
//     view lifecycle to avoid draining the battery when nothing is on screen.
//

import CoreLocation
import Foundation
import Observation

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  var status: CLAuthorizationStatus
  var currentLocation: CLLocation?

  override init() {
    status = manager.authorizationStatus
    super.init()
    manager.delegate = self
    // 100 m is plenty to show a "1.2 km" style distance and is cheap.
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
  }

  // "Always" lets iOS keep monitoring regions even when the app isn't running.
  func requestAlwaysAuthorization() {
    manager.requestAlwaysAuthorization()
  }

  // Enough to read the current location while the app is open (distance list).
  func requestWhenInUseAuthorization() {
    manager.requestWhenInUseAuthorization()
  }

  // Authorized to read location. `authorizedWhenInUse` is not a macOS case, so
  // resolve the platform difference here instead of at every call site.
  private var isAuthorized: Bool {
    #if os(macOS)
      return status == .authorizedAlways
    #else
      return status == .authorizedAlways || status == .authorizedWhenInUse
    #endif
  }

  // Start foreground distance updates. No-op until we're authorized.
  func startUpdatingLocation() {
    guard isAuthorized else { return }
    manager.startUpdatingLocation()
  }

  func stopUpdatingLocation() {
    manager.stopUpdatingLocation()
  }

  // Background updates, enabled ONLY while a Live Activity is tracking a place.
  // Requires UIBackgroundModes = location in the app's Info.plist (set) and
  // location authorization. Scoped on/off so we never track in the background
  // when nothing needs it.
  func startBackgroundUpdates() {
    guard isAuthorized else { return }
    #if os(iOS)
      manager.allowsBackgroundLocationUpdates = true
      manager.pausesLocationUpdatesAutomatically = false
    #endif
    manager.startUpdatingLocation()
  }

  func stopBackgroundUpdates() {
    #if os(iOS)
      manager.allowsBackgroundLocationUpdates = false
      manager.pausesLocationUpdatesAutomatically = true
    #endif
  }

  // Delegate callback — fires whenever the permission state changes.
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    status = manager.authorizationStatus
    // If permission arrived while a view is asking for distances, begin now.
    if isAuthorized {
      manager.startUpdatingLocation()
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    currentLocation = locations.last
  }
}
