//
//  DataSynchronizationService.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Circular reference resolved - proper singleton pattern
//  ✅ V6.0: Phase 2.1 - Cross-Dashboard Broadcasting
//  ✅ The central hub for real-time updates across the application
//  ✅ Uses a Combine pipeline to broadcast events
//

import Foundation
import Combine

/// A struct representing a synced worker event, to be broadcast across the app
struct WorkerEventSynced {
    let buildingId: String
    let workerId: String
    let eventType: String // e.g., "task_completion", "clock_in"
    let timestamp: Date
    
    init(buildingId: String, workerId: String, eventType: String, timestamp: Date = Date()) {
        self.buildingId = buildingId
        self.workerId = workerId
        self.eventType = eventType
        self.timestamp = timestamp
    }
}

/// A simple worker event structure for internal use
struct WorkerEvent {
    let buildingId: String
    let workerId: String
    let type: EventType
    let timestamp: Date
    
    enum EventType: String, CaseIterable {
        case taskCompletion = "task_completion"
        case clockIn = "clock_in"
        case clockOut = "clock_out"
        case taskStart = "task_start"
        case buildingArrival = "building_arrival"
        case buildingDeparture = "building_departure"
    }
    
    init(buildingId: String, workerId: String, type: EventType, timestamp: Date = Date()) {
        self.buildingId = buildingId
        self.workerId = workerId
        self.type = type
        self.timestamp = timestamp
    }
}

/// An observable object that acts as the central nervous system for real-time data flow
/// It broadcasts events when worker actions are synced, allowing different dashboards
/// to update their state automatically without manual refreshes
@MainActor
class DataSynchronizationService: ObservableObject {
    // ✅ FIXED: Proper singleton pattern - creates new instance, not circular reference
    static let shared = DataSynchronizationService()

    // A Combine subject to push events through the pipeline
    private let workerEventSyncedSubject = PassthroughSubject<WorkerEventSynced, Never>()
    
    /// A publisher that any view or view model can subscribe to, to receive live updates
    var workerEventSynced: AnyPublisher<WorkerEventSynced, Never> {
        workerEventSyncedSubject.eraseToAnyPublisher()
    }
    
    // A stream for broadcasting building intelligence updates
    @Published private(set) var buildingIntelligenceUpdates: [String: [CoreTypes.IntelligenceInsight]] = [:]
    
    // Services - using shared instances
    private let buildingService = BuildingService.shared
    private let intelligenceService = IntelligenceService.shared

    private init() {}

    /// Called when an event needs to be broadcast across the application
    /// This is the entry point for broadcasting updates
    func broadcastSyncCompletion(for event: WorkerEvent) async {
        let syncedEvent = WorkerEventSynced(
            buildingId: event.buildingId,
            workerId: event.workerId,
            eventType: event.type.rawValue,
            timestamp: event.timestamp
        )
        
        print("📡 Broadcasting sync completion for event: \(event.type.rawValue) at building \(event.buildingId)")
        
        // Push the event into the Combine pipeline
        workerEventSyncedSubject.send(syncedEvent)
        
        // After broadcasting the event, refresh the intelligence for the affected building
        await refreshBuildingIntelligence(for: event.buildingId)
    }
    
    /// Convenience method for broadcasting different types of events
    func broadcastTaskCompletion(buildingId: String, workerId: String) async {
        let event = WorkerEvent(buildingId: buildingId, workerId: workerId, type: .taskCompletion)
        await broadcastSyncCompletion(for: event)
    }
    
    func broadcastClockIn(buildingId: String, workerId: String) async {
        let event = WorkerEvent(buildingId: buildingId, workerId: workerId, type: .clockIn)
        await broadcastSyncCompletion(for: event)
    }
    
    func broadcastClockOut(buildingId: String, workerId: String) async {
        let event = WorkerEvent(buildingId: buildingId, workerId: workerId, type: .clockOut)
        await broadcastSyncCompletion(for: event)
    }
    
    func broadcastTaskStart(buildingId: String, workerId: String) async {
        let event = WorkerEvent(buildingId: buildingId, workerId: workerId, type: .taskStart)
        await broadcastSyncCompletion(for: event)
    }
    
    func broadcastBuildingArrival(buildingId: String, workerId: String) async {
        let event = WorkerEvent(buildingId: buildingId, workerId: workerId, type: .buildingArrival)
        await broadcastSyncCompletion(for: event)
    }
    
    /// Refreshes the intelligence for a specific building and broadcasts the update
    private func refreshBuildingIntelligence(for buildingId: String) async {
        print("🧠 Refreshing intelligence for building \(buildingId)...")
        
        do {
            // Use the existing IntelligenceService to generate fresh insights
            let freshInsights = try await intelligenceService.generateBuildingInsights(for: buildingId)
            
            // Update our published dictionary, which will notify any subscribed views
            buildingIntelligenceUpdates[buildingId] = freshInsights
            
            print("✅ Successfully refreshed and broadcasted intelligence for building \(buildingId): \(freshInsights.count) insights")
            
        } catch {
            print("🚨 Failed to refresh intelligence for building \(buildingId): \(error)")
        }
    }
    
    /// Force refresh intelligence for a specific building (can be called manually)
    func refreshIntelligence(for buildingId: String) async {
        await refreshBuildingIntelligence(for: buildingId)
    }
    
    /// Refresh intelligence for all buildings
    func refreshAllBuildingIntelligence() async {
        print("🔄 Refreshing intelligence for all buildings...")
        
        do {
            let buildings = try await buildingService.getAllBuildings()
            
            for building in buildings {
                await refreshBuildingIntelligence(for: building.id)
            }
            
            print("✅ Completed intelligence refresh for \(buildings.count) buildings")
            
        } catch {
            print("🚨 Failed to refresh intelligence for all buildings: \(error)")
        }
    }
    
    /// Get the latest intelligence for a building
    func getLatestIntelligence(for buildingId: String) -> [CoreTypes.IntelligenceInsight] {
        return buildingIntelligenceUpdates[buildingId] ?? []
    }
    
    /// Check if there are any urgent insights across all buildings
    func hasUrgentInsights() -> Bool {
        return buildingIntelligenceUpdates.values.contains { insights in
            insights.contains { $0.priority == .critical || $0.priority == .high }
        }
    }
    
    /// Get count of critical insights across all buildings
    func getCriticalInsightsCount() -> Int {
        return buildingIntelligenceUpdates.values.flatMap { $0 }.filter { $0.priority == .critical }.count
    }
    
    /// Get all high priority insights across buildings
    func getHighPriorityInsights() -> [CoreTypes.IntelligenceInsight] {
        return buildingIntelligenceUpdates.values.flatMap { $0 }.filter {
            $0.priority == .critical || $0.priority == .high
        }.sorted { $0.priority.priorityValue > $1.priority.priorityValue }
    }
    
    /// Clear intelligence updates (useful for testing or reset)
    func clearIntelligenceUpdates() {
        buildingIntelligenceUpdates.removeAll()
        print("🧹 Cleared all building intelligence updates")
    }
    
    /// Subscribe to worker events with a custom handler
    func subscribeToWorkerEvents() -> AnyPublisher<WorkerEventSynced, Never> {
        return workerEventSynced
    }
    
    /// Manual event broadcasting for testing
    func simulateEvent(buildingId: String, workerId: String, eventType: WorkerEvent.EventType) async {
        let event = WorkerEvent(buildingId: buildingId, workerId: workerId, type: eventType)
        await broadcastSyncCompletion(for: event)
    }
}

// MARK: - Extension for Real-time Dashboard Updates

extension DataSynchronizationService {
    
    /// Get insights that affect a specific building
    func getInsightsForBuilding(_ buildingId: String) -> [CoreTypes.IntelligenceInsight] {
        return buildingIntelligenceUpdates[buildingId] ?? []
    }
    
    /// Check if a building has critical issues
    func buildingHasCriticalIssues(_ buildingId: String) -> Bool {
        let insights = getInsightsForBuilding(buildingId)
        return insights.contains { $0.priority == .critical }
    }
    
    /// Get the health score for a building based on its insights
    func getBuildingHealthScore(_ buildingId: String) -> Double {
        let insights = getInsightsForBuilding(buildingId)
        
        if insights.isEmpty { return 100.0 }
        
        let criticalCount = insights.filter { $0.priority == .critical }.count
        let highCount = insights.filter { $0.priority == .high }.count
        let mediumCount = insights.filter { $0.priority == .medium }.count
        
        // Calculate health score (lower is worse)
        let totalIssues = criticalCount * 3 + highCount * 2 + mediumCount * 1
        let maxPossibleIssues = insights.count * 3
        
        if maxPossibleIssues == 0 { return 100.0 }
        
        let healthRatio = 1.0 - (Double(totalIssues) / Double(maxPossibleIssues))
        return max(0.0, min(100.0, healthRatio * 100.0))
    }
}
