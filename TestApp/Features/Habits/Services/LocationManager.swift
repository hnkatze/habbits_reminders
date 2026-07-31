//
//  LocationManager.swift
//  TestApp
//
//  Minimal CoreLocation wrapper. Its only job here is to ask for "Always"
//  authorization, which iOS requires to monitor geofence regions in the
//  background (so a location reminder can fire even with the app closed).
//

import Foundation
import CoreLocation
import Observation

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var status: CLAuthorizationStatus

    override init() {
        status = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    // "Always" lets iOS keep monitoring regions even when the app isn't running.
    func requestAlwaysAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    // Delegate callback — fires whenever the permission state changes.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
    }
}
