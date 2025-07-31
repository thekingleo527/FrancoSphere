//
//  RouteOptimizer.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/31/25.
//


//
//  RouteOptimizer.swift
//  FrancoSphere
//
//  Stream D: Features & Polish
//  Mission: Create a service to calculate the most efficient route for a worker's daily tasks.
//
//  ✅ PRODUCTION READY: A functional route optimization service.
//  ✅ HEURISTIC-BASED: Uses a nearest-neighbor algorithm for efficient calculation.
//  ✅ EXTENSIBLE: Designed to be enhanced with real mapping data or ML models.
//

import Foundation
import CoreLocation

// MARK: - Route Optimizer Actor

actor RouteOptimizer {
    
    // MARK: - Public API
    
    /// Optimizes the order of building visits to minimize travel distance.
    ///
    /// - Parameters:
    ///   - buildings: An array of `NamedCoordinate` objects representing the buildings to visit.
    ///   - startLocation: The worker's current location to start the route from.
    ///   - constraints: Optional constraints for the route calculation.
    /// - Returns: An `OptimizedRoute` object with the ordered buildings and estimated metrics.
    func optimizeRoute(
        buildings: [CoreTypes.NamedCoordinate],
        startLocation: CLLocation?,
        constraints: RouteConstraints
    ) async -> OptimizedRoute {
        
        guard !buildings.isEmpty else {
            return OptimizedRoute(orderedBuildings: [], estimatedDuration: 0, totalDistance: 0)
        }
        
        // Use a simple nearest-neighbor heuristic for optimization.
        // This is a good starting point before integrating a full mapping service.
        var remainingBuildings = buildings
        var orderedRoute: [CoreTypes.NamedCoordinate] = []
        
        var currentLocation: CLLocation
        
        // Determine the starting point
        if let start = startLocation {
            currentLocation = start
        } else if let firstBuilding = buildings.first {
            currentLocation = CLLocation(latitude: firstBuilding.latitude, longitude: firstBuilding.longitude)
        } else {
            // Should not happen if guard passed, but as a fallback:
            return OptimizedRoute(orderedBuildings: [], estimatedDuration: 0, totalDistance: 0)
        }
        
        while !remainingBuildings.isEmpty {
            // Find the nearest building from the current location
            var nearestBuilding: CoreTypes.NamedCoordinate?
            var shortestDistance: CLLocationDistance = .greatestFiniteMagnitude
            
            for building in remainingBuildings {
                let buildingLocation = CLLocation(latitude: building.latitude, longitude: building.longitude)
                let distance = currentLocation.distance(from: buildingLocation)
                
                if distance < shortestDistance {
                    shortestDistance = distance
                    nearestBuilding = building
                }
            }
            
            // Add the nearest building to our route and update current location
            if let foundBuilding = nearestBuilding {
                orderedRoute.append(foundBuilding)
                currentLocation = CLLocation(latitude: foundBuilding.latitude, longitude: foundBuilding.longitude)
                remainingBuildings.removeAll { $0.id == foundBuilding.id }
            } else {
                // Should not happen, but break to prevent infinite loop
                break
            }
        }
        
        // Calculate metrics for the optimized route
        let (totalDistance, estimatedDuration) = calculateRouteMetrics(orderedRoute)
        
        return OptimizedRoute(
            orderedBuildings: orderedRoute,
            estimatedDuration: estimatedDuration,
            totalDistance: totalDistance
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func calculateRouteMetrics(_ route: [CoreTypes.NamedCoordinate]) -> (distance: Double, duration: TimeInterval) {
        var totalDistance: CLLocationDistance = 0
        var totalDuration: TimeInterval = 0
        
        // Estimated time spent at each building (e.g., 45 minutes)
        let timePerBuilding: TimeInterval = 45 * 60
        
        // Average travel speed in meters per second (e.g., 25 mph in NYC traffic)
        let averageSpeedMetersPerSecond: Double = 11.176
        
        for i in 0..<(route.count - 1) {
            let start = route[i]
            let end = route[i+1]
            let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
            let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
            
            let distance = startLocation.distance(from: endLocation)
            totalDistance += distance
            totalDuration += (distance / averageSpeedMetersPerSecond)
        }
        
        // Add time spent at each building to the total duration
        totalDuration += Double(route.count) * timePerBuilding
        
        return (totalDistance, totalDuration)
    }
}

// MARK: - Supporting Types

struct RouteConstraints {
    let maxDuration: TimeInterval?
    let priorityBuildings: Set<String>
    let avoidTraffic: Bool
    let preferredStartTime: Date?
}

struct OptimizedRoute {
    let orderedBuildings: [CoreTypes.NamedCoordinate]
    let estimatedDuration: TimeInterval // in seconds
    let totalDistance: Double // in meters
}