//
//  LocationManager.swift
//  Chat
//
//  Created by Malik on 21/07/2025.
//


import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    let locationPublisher = PassthroughSubject<CLLocationCoordinate2D, Never>()

    @Published var currentLocation: CLLocationCoordinate2D?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
          if let coord = locations.last?.coordinate {
              currentLocation = coord
              locationPublisher.send(coord) // 🔄 Send live updates
          }
      }

    func requestLocation() {
        manager.requestLocation()
    }
}
