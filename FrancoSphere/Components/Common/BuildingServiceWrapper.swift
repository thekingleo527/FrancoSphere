
//  BuildingServiceWrapper.swift
//  FrancoSphere v6.0
//
//  ✅ OBSERVABLE: Wraps actor BuildingService for SwiftUI compatibility
//  ✅ MAINTAINS SAFETY: Preserves actor isolation
//

import Foundation
import Combine

@MainActor
final class BuildingServiceWrapper: ObservableObject {
    static let shared = BuildingServiceWrapper()
    
    private let service = BuildingService.shared
    
    @Published var buildings: [NamedCoordinate] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private init() {}
    
    // MARK: - Wrapped Methods
    
    func getAllBuildings() async throws -> [NamedCoordinate] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await service.getAllBuildings()
            self.buildings = result
            return result
        } catch {
            self.error = error
            throw error
        }
    }
    
    func getBuilding(buildingId: String) async throws -> NamedCoordinate {
        return try await service.getBuilding(buildingId: buildingId)
    }
    
    func getBuildingsForWorker(_ workerId: String) async throws -> [NamedCoordinate] {
        return try await service.getBuildingsForWorker(workerId)
    }
    
    func name(forId buildingId: CoreTypes.BuildingID) async throws -> String {
        return try await service.name(forId: buildingId)
    }
    
    func buildingExists(_ buildingId: String) async throws -> Bool {
        return try await service.buildingExists(buildingId)
    }
    
    func getBuildingMetrics(_ buildingId: String) async throws -> CoreTypes.BuildingMetrics {
        return try await service.getBuildingMetrics(buildingId)
    }
    
    func getBuildingHealthScore(_ buildingId: String) async throws -> Double {
        return try await service.getBuildingHealthScore(buildingId)
    }
    
    func getBuildingStatus(_ buildingId: String) async throws -> BuildingStatus {
        return try await service.getBuildingStatus(buildingId)
    }
    
    func getInventoryItems(for buildingId: String) async throws -> [CoreTypes.InventoryItem] {
        return try await service.getInventoryItems(for: buildingId)
    }
    
    func saveInventoryItem(_ item: CoreTypes.InventoryItem, buildingId: String) async throws {
        try await service.saveInventoryItem(item, buildingId: buildingId)
    }
    
    func deleteInventoryItem(id: String, buildingId: String) async throws {
        try await service.deleteInventoryItem(id: id, buildingId: buildingId)
    }
    
    func updateInventoryItemQuantity(id: String, newQuantity: Int, buildingId: String) async throws {
        try await service.updateInventoryItemQuantity(id: id, newQuantity: newQuantity, buildingId: buildingId)
    }
    
    func searchBuildings(query: String) async throws -> [NamedCoordinate] {
        return try await service.searchBuildings(query: query)
    }
    
    func getBuildingsNearLocation(latitude: Double, longitude: Double, radiusKm: Double) async throws -> [NamedCoordinate] {
        return try await service.getBuildingsNearLocation(latitude: latitude, longitude: longitude, radiusKm: radiusKm)
    }
    
    func updateBuildingData(_ building: NamedCoordinate) async throws {
        try await service.updateBuildingData(building)
    }
    
    func createBuilding(_ building: NamedCoordinate) async throws {
        try await service.createBuilding(building)
    }
    
    func getBuildingAnalytics(for buildingId: String) async throws -> BuildingAnalytics {
        return try await service.getBuildingAnalytics(for: buildingId)
    }
}

// Add these additional method wrappers that ClientContextEngine needs:
extension BuildingService {
    func getClientBuildings() async throws -> [Building] {
        // This is a placeholder - in real implementation, filter by client
        let allBuildings = try await getAllBuildings()
        return allBuildings.map { coord in
            Building(
                id: coord.id,
                name: coord.name,
                address: coord.address,
                latitude: coord.latitude,
                longitude: coord.longitude,
                type: coord.type ?? .office,
                isActive: true
            )
        }
    }
    
    func getBuildingMetrics(for buildingIds: [String]) async throws -> [String: CoreTypes.BuildingMetrics] {
        var results: [String: CoreTypes.BuildingMetrics] = [:]
        
        for buildingId in buildingIds {
            do {
                let metrics = try await getBuildingMetrics(buildingId)
                results[buildingId] = metrics
            } catch {
                // Skip buildings that fail
                print("Failed to get metrics for building \(buildingId): \(error)")
            }
        }
        
        return results
    }
}

// Supporting type for ClientContextEngine
struct Building {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let type: CoreTypes.BuildingType
    let isActive: Bool
}
