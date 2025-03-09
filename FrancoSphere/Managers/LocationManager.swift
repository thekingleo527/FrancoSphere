//
//  LocationManager.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/13/25.
//


import Foundation
import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var locationStatus: LocationStatus = .unknown
    
    enum LocationStatus {
        case unknown
        case notDetermined
        case denied
        case authorized
        case restricted
    }
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func requestLocation() {
        manager.requestLocation()
    }
    
    // MARK: - CLLocationManagerDelegate Methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationStatus = .notDetermined
        case .restricted:
            locationStatus = .restricted
        case .denied:
            locationStatus = .denied
        case .authorizedAlways, .authorizedWhenInUse:
            locationStatus = .authorized
        @unknown default:
            locationStatus = .unknown
        }
    }
    
    // MARK: - Helper Methods
    
    func isWithinRange(of coordinate: CLLocationCoordinate2D, radius: Double) -> Bool {
        guard let userLocation = location else {
            return false
        }
        
        let buildingLocation = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        
        // Check if within specified radius (in meters)
        let distance = userLocation.distance(from: buildingLocation)
        return distance < radius
    }
}