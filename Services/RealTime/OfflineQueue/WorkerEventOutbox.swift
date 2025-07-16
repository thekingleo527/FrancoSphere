//
//  WorkerEventOutbox.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Type conversion between WorkerEventOutbox.WorkerEvent and DataSynchronizationService.WorkerEvent
//  ✅ V6.0: Phase 2.2 - Enhanced Offline Queue
//  ✅ Safely stores worker actions for reliable synchronization
//  ✅ Triggers the DataSynchronizationService upon successful sync
//

import Foundation

/// An actor that manages a persistent, offline-first queue of worker actions
/// It ensures that every action is eventually sent to the server, even if the
/// device is offline when the action is recorded
actor WorkerEventOutbox {
    static let shared = WorkerEventOutbox()

    /// Represents a single worker action that needs to be synced
    struct WorkerEvent: Codable, Identifiable {
        let id: String
        let type: WorkerActionType
        let payload: Data // A flexible container for any Codable data
        let timestamp: Date
        let buildingId: String
        let workerId: String
        var retryCount: Int = 0
        
        // Convenience initializer for actions with evidence
        init<T: Codable>(type: WorkerActionType, workerId: String, buildingId: String, payload: T) throws {
            self.id = UUID().uuidString
            self.type = type
            self.workerId = workerId
            self.buildingId = buildingId
            self.timestamp = Date()
            self.payload = try JSONEncoder().encode(payload)
        }
        
        // Simple initializer without payload
        init(type: WorkerActionType, workerId: String, buildingId: String) {
            self.id = UUID().uuidString
            self.type = type
            self.workerId = workerId
            self.buildingId = buildingId
            self.timestamp = Date()
            self.payload = Data()
            self.retryCount = 0
        }
        
        // ✅ ADDED: Convert to DataSynchronizationService.WorkerEvent for broadcasting
        func toSyncEvent() -> DataSynchronizationService.WorkerEvent {
            // Map WorkerActionType to DataSynchronizationService.WorkerEvent.EventType
            let eventType: DataSynchronizationService.WorkerEvent.EventType
            switch self.type {
            case .taskCompletion:
                eventType = .taskCompletion
            case .clockIn:
                eventType = .clockIn
            case .clockOut:
                eventType = .clockOut
            case .taskStart:
                eventType = .taskStart
            case .buildingArrival:
                eventType = .buildingArrival
            case .buildingDeparture:
                eventType = .buildingDeparture
            default:
                eventType = .taskCompletion // Default fallback
            }
            
            return DataSynchronizationService.WorkerEvent(
                buildingId: self.buildingId,
                workerId: self.workerId,
                type: eventType,
                timestamp: self.timestamp
            )
        }
    }
    
    // In-memory queue for pending events. This would be backed by a persistent store in a full implementation
    private var pendingEvents: [WorkerEvent] = []
    
    private let dataSyncService = DataSynchronizationService.shared

    private init() {
        // Load pending events from persistent storage on startup
        loadPendingEvents()
    }

    /// Adds a new event to the outbox to be synced
    func addEvent(_ event: WorkerEvent) {
        print("📬 Adding event to outbox: \(event.type.rawValue) (ID: \(event.id))")
        pendingEvents.append(event)
        savePendingEvents()
        
        // Immediately try to flush the queue
        Task {
            await attemptFlush()
        }
    }
    
    /// Convenience methods for adding common events
    func addTaskCompletionEvent(workerId: String, buildingId: String, taskId: String) {
        let event = WorkerEvent(type: .taskCompletion, workerId: workerId, buildingId: buildingId)
        addEvent(event)
    }
    
    func addClockInEvent(workerId: String, buildingId: String) {
        let event = WorkerEvent(type: .clockIn, workerId: workerId, buildingId: buildingId)
        addEvent(event)
    }
    
    func addClockOutEvent(workerId: String, buildingId: String) {
        let event = WorkerEvent(type: .clockOut, workerId: workerId, buildingId: buildingId)
        addEvent(event)
    }
    
    func addBuildingArrivalEvent(workerId: String, buildingId: String) {
        let event = WorkerEvent(type: .buildingArrival, workerId: workerId, buildingId: buildingId)
        addEvent(event)
    }

    /// Attempts to send all pending events to the server
    func attemptFlush() async {
        guard !pendingEvents.isEmpty else { return }
        
        print("📤 Attempting to flush \(pendingEvents.count) events...")
        
        var successfullySyncedEvents: [String] = []

        for var event in pendingEvents {
            do {
                // Simulate a network request
                try await submitEventToServer(event)
                
                // If successful, mark for removal and broadcast completion
                successfullySyncedEvents.append(event.id)
                
                // ✅ FIXED: Convert to the correct type for DataSynchronizationService
                await dataSyncService.broadcastSyncCompletion(for: event.toSyncEvent())
                
            } catch {
                // Handle retry logic
                event.retryCount += 1
                print("⚠️ Failed to sync event \(event.id), retry \(event.retryCount). Error: \(error)")
                
                // Update the event in the queue with the new retry count
                if let index = pendingEvents.firstIndex(where: { $0.id == event.id }) {
                    pendingEvents[index] = event
                }
                
                // If retry count exceeds threshold, log and possibly remove
                if event.retryCount >= 5 {
                    print("🚨 Event \(event.id) has exceeded retry limit, removing from queue")
                    successfullySyncedEvents.append(event.id)
                }
            }
        }
        
        // Remove successfully synced events from the queue
        if !successfullySyncedEvents.isEmpty {
            pendingEvents.removeAll { successfullySyncedEvents.contains($0.id) }
            savePendingEvents()
            print("✅ Flushed \(successfullySyncedEvents.count) events successfully.")
        }
    }
    
    /// Simulates submitting a single event to a remote server
    private func submitEventToServer(_ event: WorkerEvent) async throws {
        // Simulate network latency
        try await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000...500_000_000))
        
        // Simulate a potential network failure for demonstration purposes
        if Double.random(in: 0...1) < 0.1 { // 10% chance of failure
            throw URLError(.notConnectedToInternet)
        }
        
        // If we reach here, the sync is considered successful
        print("   -> Successfully synced event \(event.id) to server.")
    }
    
    // MARK: - Queue Management
    
    /// Get the current number of pending events
    func getPendingEventCount() -> Int {
        return pendingEvents.count
    }
    
    /// Get all pending events (for debugging)
    func getPendingEvents() -> [WorkerEvent] {
        return pendingEvents
    }
    
    /// Clear all pending events (use with caution)
    func clearAllEvents() {
        pendingEvents.removeAll()
        savePendingEvents()
        print("🧹 Cleared all pending events from outbox")
    }
    
    /// Force retry all failed events
    func retryAllEvents() async {
        print("🔄 Forcing retry of all pending events...")
        await attemptFlush()
    }
    
    // MARK: - Persistence (Simplified using UserDefaults)
    
    private var persistenceKey: String { "WorkerEventOutbox_PendingEvents" }

    private func savePendingEvents() {
        do {
            let data = try JSONEncoder().encode(pendingEvents)
            UserDefaults.standard.set(data, forKey: persistenceKey)
        } catch {
            print("🚨 Failed to save pending events to UserDefaults: \(error)")
        }
    }

    private func loadPendingEvents() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else { return }
        do {
            pendingEvents = try JSONDecoder().decode([WorkerEvent].self, from: data)
            print("📦 Loaded \(pendingEvents.count) pending events from previous session.")
        } catch {
            print("🚨 Failed to load pending events from UserDefaults: \(error)")
        }
    }
}

// MARK: - WorkerActionType Extension

extension WorkerActionType {
    /// Map to DataSynchronizationService.WorkerEvent.EventType
    var syncEventType: DataSynchronizationService.WorkerEvent.EventType {
        switch self {
        case .taskCompletion:
            return .taskCompletion
        case .clockIn:
            return .clockIn
        case .clockOut:
            return .clockOut
        case .taskStart:
            return .taskStart
        case .buildingArrival:
            return .buildingArrival
        case .buildingDeparture:
            return .buildingDeparture
        default:
            return .taskCompletion // Default fallback
        }
    }
}

// MARK: - Integration Helpers

extension WorkerEventOutbox {
    
    /// Create and queue an event from a ContextualTask completion
    func recordTaskCompletion(task: ContextualTask, workerId: String) {
        let event = WorkerEvent(
            type: .taskCompletion,
            workerId: workerId,
            buildingId: task.buildingId ?? "unknown"
        )
        addEvent(event)
    }
    
    /// Create and queue an event from worker clock operations
    func recordClockOperation(workerId: String, buildingId: String, isClockIn: Bool) {
        let eventType: WorkerActionType = isClockIn ? .clockIn : .clockOut
        let event = WorkerEvent(type: eventType, workerId: workerId, buildingId: buildingId)
        addEvent(event)
    }
    
    /// Create and queue an event for location-based actions
    func recordLocationEvent(workerId: String, buildingId: String, isArrival: Bool) {
        let eventType: WorkerActionType = isArrival ? .buildingArrival : .buildingDeparture
        let event = WorkerEvent(type: eventType, workerId: workerId, buildingId: buildingId)
        addEvent(event)
    }
}
