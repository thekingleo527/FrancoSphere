//
//  DataSynchronizationService.swift
//  FrancoSphere
//
//  ✅ V6.0: Phase 2.1 - Cross-Dashboard Broadcasting
//  ✅ The central hub for real-time updates across the application.
//  ✅ Uses a Combine pipeline to broadcast events.
//

import Foundation
import Combine

/// A struct representing a synced worker event, to be broadcast across the app.
struct WorkerEventSynced {
    let buildingId: CoreTypes.BuildingID
    let workerId: CoreTypes.WorkerID
    let eventType: String // e.g., "task_completion", "clock_in"
    let timestamp: Date
}

/// An observable object that acts as the central nervous system for real-time data flow.
/// It broadcasts events when worker actions are synced, allowing different dashboards
/// to update their state automatically without manual refreshes.
@MainActor
class DataSynchronizationService: ObservableObject {
    static let shared = DataSynchronizationService()

    // A Combine subject to push events through the pipeline.
    private let workerEventSyncedSubject = PassthroughSubject<WorkerEventSynced, Never>()
    
    /// A publisher that any view or view model can subscribe to, to receive live updates.
    var workerEventSynced: AnyPublisher<WorkerEventSynced, Never> {
        workerEventSyncedSubject.eraseToAnyPublisher()
    }
    
    // A stream for broadcasting the full, updated intelligence DTOs.
    @Published private(set) var buildingIntelligenceUpdates: [CoreTypes.BuildingID: BuildingIntelligenceDTO] = [:]

    private init() {}

    /// Called by the `WorkerEventOutbox` after an event is successfully synced to the server.
    /// This is the entry point for broadcasting updates.
    func broadcastSyncCompletion(for event: WorkerEventOutbox.WorkerEvent) async {
        let syncedEvent = WorkerEventSynced(
            buildingId: event.buildingId,
            workerId: event.workerId,
            eventType: event.type.rawValue,
            timestamp: Date()
        )
        
        print("📡 Broadcasting sync completion for event: \(event.type.rawValue) at building \(event.buildingId)")
        
        // Push the event into the Combine pipeline.
        workerEventSyncedSubject.send(syncedEvent)
        
        // After broadcasting the event, refresh the intelligence for the affected building.
        await refreshBuildingIntelligence(for: event.buildingId)
    }
    
    /// Refreshes the intelligence for a specific building and broadcasts the update.
    private func refreshBuildingIntelligence(for buildingId: CoreTypes.BuildingID) async {
        print("🧠 Refreshing intelligence for building \(buildingId)...")
        
        // In a real implementation, this would call the BuildingService.
        // For now, we use the StubFactory to generate fresh data.
        do {
            // let freshIntelligence = try await BuildingService.shared.getBuildingIntelligence(buildingId)
            
            // For development, we'll generate stubbed data.
            // We need to know which workers are assigned to this building.
            // This would typically come from a service.
            let assignedWorkerIds = ["1", "4"] // Placeholder
            let freshIntelligence = StubFactory.makeBuildingIntelligence(for: buildingId, workerIds: assignedWorkerIds)
            
            // Update our published dictionary, which will notify any subscribed views.
            buildingIntelligenceUpdates[buildingId] = freshIntelligence
            
            print("✅ Successfully refreshed and broadcasted intelligence for building \(buildingId).")
            
        } catch {
            print("🚨 Failed to refresh intelligence for building \(buildingId): \(error)")
        }
    }
}
