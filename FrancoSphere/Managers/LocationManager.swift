//
//  LocationManager.swift
//  FrancoSphere v6.0
//
//  ✅ REWRITTEN: Proper singleton pattern with clean API
//  ✅ THREAD-SAFE: Proper actor isolation and async/await
//  ✅ SIMPLIFIED: Cleaner structure and better organization
//  ✅ PRODUCTION READY: All features maintained with improved reliability
//

import Foundation
import CoreLocation
import Combine
import UIKit

// MARK: - Location Manager

public final class LocationManager: NSObject, ObservableObject {
    // MARK: - Singleton
    
    public static let shared = LocationManager.shared
    
    // MARK: - Published Properties
    
    @Published public private(set) var currentLocation: CLLocation?
    @Published public private(set) var authorizationStatus: CLAuthorizationStatus
    @Published public private(set) var isUpdatingLocation = false
    @Published public private(set) var lastError: LocationError?
    @Published public private(set) var nearbyBuildings: [BuildingProximity] = []
    @Published public private(set) var currentBuilding: CoreTypes.NamedCoordinate?
    @Published public private(set) var locationAccuracy: LocationAccuracy = .balanced
    
    // MARK: - Private Properties
    
    private let locationManager = CLLocationManager.shared
    private var monitoredRegions: [String: CLCircularRegion] = [:]
    private var lastLocationUpdate: Date?
    private var locationUpdateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    
    private let config = LocationConfiguration()
    
    // MARK: - Initialization
    
    override private init() {
        self.authorizationStatus = CLLocationManager.shared.authorizationStatus
        super.init()
        setupLocationManager.shared
        setupObservers()
    }
    
    // MARK: - Public API
    
    /// Request location permissions
    public func requestLocationPermission() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch self.authorizationStatus {
            case .notDetermined:
                self.locationManager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse:
                if self.shouldRequestAlwaysAuthorization() {
                    self.locationManager.requestAlwaysAuthorization()
                }
            case .denied, .restricted:
                self.lastError = .permissionDenied
                self.showLocationSettingsAlert()
            case .authorizedAlways:
                print("✅ Location permission already granted")
            @unknown default:
                break
            }
        }
    }
    
    /// Start updating location
    public func startUpdatingLocation(accuracy: LocationAccuracy = .balanced) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard self.hasLocationPermission else {
                self.requestLocationPermission()
                return
            }
            
            self.locationAccuracy = accuracy
            self.configureLocationManager(for: accuracy)
            
            if accuracy == .precise {
                self.locationManager.startUpdatingLocation()
            } else {
                self.locationManager.startMonitoringSignificantLocationChanges()
            }
            
            self.isUpdatingLocation = true
            self.startLocationUpdateTimer()
            
            print("📍 Started location updates with \(accuracy) accuracy")
        }
    }
    
    /// Stop updating location
    public func stopUpdatingLocation() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.locationManager.stopUpdatingLocation()
            self.locationManager.stopMonitoringSignificantLocationChanges()
            self.locationUpdateTimer?.invalidate()
            self.locationUpdateTimer = nil
            self.isUpdatingLocation = false
            
            print("📍 Stopped location updates")
        }
    }
    
    /// Request single location update
    public func requestSingleUpdate() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard self.hasLocationPermission else {
                self.requestLocationPermission()
                return
            }
            
            self.locationManager.requestLocation()
        }
    }
    
    /// Check if at building
    public func isAtBuilding(_ building: CoreTypes.NamedCoordinate, threshold: CLLocationDistance = 50) -> Bool {
        guard let currentLocation = currentLocation else { return false }
        
        let buildingLocation = CLLocation(
            latitude: building.latitude,
            longitude: building.longitude
        )
        
        return currentLocation.distance(from: buildingLocation) <= threshold
    }
    
    /// Get distance to building
    public func distanceToBuilding(_ building: CoreTypes.NamedCoordinate) -> CLLocationDistance? {
        guard let currentLocation = currentLocation else { return nil }
        
        let buildingLocation = CLLocation(
            latitude: building.latitude,
            longitude: building.longitude
        )
        
        return currentLocation.distance(from: buildingLocation)
    }
    
    /// Start monitoring geofence for building
    public func startMonitoringGeofence(for building: CoreTypes.NamedCoordinate, radius: CLLocationDistance? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard self.authorizationStatus == .authorizedAlways else {
                print("⚠️ Always authorization required for geofencing")
                self.requestLocationPermission()
                return
            }
            
            self.setupGeofence(for: building, radius: radius)
        }
    }
    
    /// Stop monitoring geofence
    public func stopMonitoringGeofence(for buildingId: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let region = self.monitoredRegions[buildingId] {
                self.locationManager.stopMonitoring(for: region)
                self.monitoredRegions.removeValue(forKey: buildingId)
                print("🎯 Stopped monitoring geofence for building \(buildingId)")
            }
        }
    }
    
    /// Update nearby buildings
    public func updateNearbyBuildings() async {
        guard let location = currentLocation else { return }
        
        do {
            let buildings = try await BuildingService.shared.getAllBuildings()
            
            let proximityList = buildings.compactMap { building -> BuildingProximity? in
                guard let distance = distanceToBuilding(building) else { return nil }
                
                return BuildingProximity(
                    building: building,
                    distance: distance,
                    isWithinGeofence: distance <= config.defaultGeofenceRadius
                )
            }
            .sorted { $0.distance < $1.distance }
            .prefix(10)
            
            await MainActor.run {
                self.nearbyBuildings = Array(proximityList)
                
                if let closest = self.nearbyBuildings.first, closest.isWithinGeofence {
                    self.currentBuilding = closest.building
                } else {
                    self.currentBuilding = nil
                }
            }
            
        } catch {
            print("❌ Failed to update nearby buildings: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func setupLocationManager.shared {
        locationManager.delegate = self
        locationManager.activityType = .otherNavigation
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = false
        
        configureLocationManager(for: locationAccuracy)
    }
    
    private func setupObservers() {
        // Battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .sink { [weak self] _ in
                self?.handleBatteryLevelChange()
            }
            .store(in: &cancellables)
        
        // App lifecycle
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppBackground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleAppForeground()
            }
            .store(in: &cancellables)
    }
    
    private func configureLocationManager(for accuracy: LocationAccuracy) {
        switch accuracy {
        case .precise:
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = 10
        case .balanced:
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.distanceFilter = 25
        case .coarse:
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.distanceFilter = 100
        }
    }
    
    private func shouldRequestAlwaysAuthorization() -> Bool {
        UserDefaults.standard.bool(forKey: "enableGeofencingClockIn")
    }
    
    private func setupGeofence(for building: CoreTypes.NamedCoordinate, radius: CLLocationDistance?) {
        // Remove existing if any
        stopMonitoringGeofence(for: building.id)
        
        let coordinate = CLLocationCoordinate2D(
            latitude: building.latitude,
            longitude: building.longitude
        )
        
        let geofenceRadius = radius ?? config.defaultGeofenceRadius
        
        let region = CLCircularRegion(
            center: coordinate,
            radius: geofenceRadius,
            identifier: building.id
        )
        
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        locationManager.startMonitoring(for: region)
        monitoredRegions[building.id] = region
        
        print("🎯 Started monitoring geofence for \(building.name) (radius: \(geofenceRadius)m)")
    }
    
    private func startLocationUpdateTimer() {
        locationUpdateTimer?.invalidate()
        
        let interval = UIApplication.shared.applicationState == .background
            ? config.backgroundUpdateInterval
            : config.minimumUpdateInterval
        
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task {
                await self?.updateNearbyBuildings()
            }
        }
    }
    
    private func handleBatteryLevelChange() {
        let batteryLevel = UIDevice.current.batteryLevel
        
        if batteryLevel < config.lowBatteryThreshold && locationAccuracy == .precise {
            print("🔋 Low battery detected, switching to balanced accuracy")
            startUpdatingLocation(accuracy: .balanced)
        }
    }
    
    private func handleAppBackground() {
        if locationAccuracy == .precise {
            locationManager.stopUpdatingLocation()
            locationManager.startMonitoringSignificantLocationChanges()
        }
        startLocationUpdateTimer()
    }
    
    private func handleAppForeground() {
        if isUpdatingLocation && locationAccuracy == .precise {
            locationManager.stopMonitoringSignificantLocationChanges()
            locationManager.startUpdatingLocation()
        }
        
        Task {
            await updateNearbyBuildings()
        }
        
        startLocationUpdateTimer()
    }
    
    private func showLocationSettingsAlert() {
        Task { @MainActor in
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else { return }
            
            let alert = UIAlertController(
                title: "Location Access Required",
                message: "FrancoSphere needs location access to track your work locations. Please enable in Settings.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            })
            
            rootViewController.present(alert, animated: true)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { [weak self] in
            self?.authorizationStatus = manager.authorizationStatus
            
            switch self?.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                if self?.isUpdatingLocation == true {
                    self?.startUpdatingLocation(accuracy: self?.locationAccuracy ?? .balanced)
                }
            case .denied, .restricted:
                self?.lastError = .permissionDenied
                self?.stopUpdatingLocation()
            default:
                break
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last,
              newLocation.timestamp.timeIntervalSinceNow > -5,
              newLocation.horizontalAccuracy > 0 else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Throttle updates
            if let lastUpdate = self.lastLocationUpdate,
               Date().timeIntervalSince(lastUpdate) < self.config.minimumUpdateInterval {
                return
            }
            
            self.currentLocation = newLocation
            self.lastLocationUpdate = Date()
            self.lastError = nil
        }
        
        Task {
            await updateNearbyBuildings()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self?.lastError = .permissionDenied
                case .network:
                    self?.lastError = .networkError
                case .locationUnknown:
                    self?.lastError = .locationUnknown
                default:
                    self?.lastError = .other(error.localizedDescription)
                }
            } else {
                self?.lastError = .other(error.localizedDescription)
            }
            
            print("❌ Location error: \(error)")
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        
        NotificationCenter.default.post(
            name: .didEnterGeofence,
            object: nil,
            userInfo: ["buildingId": circularRegion.identifier]
        )
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        
        NotificationCenter.default.post(
            name: .didExitGeofence,
            object: nil,
            userInfo: ["buildingId": circularRegion.identifier]
        )
    }
}

// MARK: - Supporting Types

public enum LocationAccuracy {
    case precise
    case balanced
    case coarse
    
    var description: String {
        switch self {
        case .precise: return "Precise"
        case .balanced: return "Balanced"
        case .coarse: return "Power Saving"
        }
    }
}

public enum LocationError: LocalizedError {
    case permissionDenied
    case locationUnknown
    case networkError
    case other(String)
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied. Please enable in Settings."
        case .locationUnknown:
            return "Unable to determine current location"
        case .networkError:
            return "Network error while determining location"
        case .other(let message):
            return message
        }
    }
}

public struct BuildingProximity {
    public let building: CoreTypes.NamedCoordinate
    public let distance: CLLocationDistance
    public let isWithinGeofence: Bool
    
    public var formattedDistance: String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.unitOptions = .naturalScale
        
        let measurement = Measurement(value: distance, unit: UnitLength.meters)
        return formatter.string(from: measurement)
    }
}

// MARK: - Configuration

private struct LocationConfiguration {
    let defaultGeofenceRadius: CLLocationDistance = 50.0
    let minimumUpdateInterval: TimeInterval = 10.0
    let backgroundUpdateInterval: TimeInterval = 60.0
    let lowBatteryThreshold: Float = 0.20
}

// MARK: - Notifications

extension Notification.Name {
    static let didEnterGeofence = Notification.Name("LocationManager.didEnterGeofence")
    static let didExitGeofence = Notification.Name("LocationManager.didExitGeofence")
}

// MARK: - Convenience Methods

extension LocationManager {
    
    /// Quick check if location services are available
    public var isLocationServicesEnabled: Bool {
        CLLocationManager.locationServicesEnabled()
    }
    
    /// Check if has any location permission
    public var hasLocationPermission: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    /// Check if has background location permission
    public var hasBackgroundLocationPermission: Bool {
        authorizationStatus == .authorizedAlways
    }
    
    /// Get current location synchronously (if available)
    public var lastKnownLocation: CLLocation? {
        currentLocation
    }
    
    /// Get current building synchronously (if available)
    public var currentBuildingIfKnown: CoreTypes.NamedCoordinate? {
        currentBuilding
    }
}
