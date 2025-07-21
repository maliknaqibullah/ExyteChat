//
//  LocationManager.swift
//  ChatExample
//
//  Created by Malik on 20/07/2025.
//


import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    private var completion: ((Result<CLLocation, Error>) -> Void)?
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            completion(true)
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            // Actual permission result will come in locationManagerDidChangeAuthorization
        default:
            completion(false)
        }
    }
    
    func getCurrentLocation(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        self.completion = completion
        manager.requestLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            completion?(.success(location))
            completion = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion?(.failure(error))
        completion = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Permission granted, you might want to notify the view model
            break
        default:
            // Permission denied
            break
        }
    }
}