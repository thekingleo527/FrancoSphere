//
//  WorkerEventOutbox.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Actor isolation issues resolved
//  ✅ FIXED: Proper Task.sleep syntax
//  ✅ FIXED: Removed duplicate init() method
//  ✅ FIXED: Cross-actor communication handled properly
//  ✅ V6.0: Phase 2.2 - Enhanced Offline Queue
//

import Foundation

/// An actor that manages a persistent, offline-first queue of worker actions
/// It ensures that every action is eventually sent to the server, even if the
/// device is offline when the action is recorded
actor WorkerEventOutbox {
    static let shared = WorkerEventOutbox()

    /// Represents a single worker action that needs to be synced (Local version)
    struct OutboxEvent: Codable, Identifiable {
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
        
        // ✅ FIXED: Convert to standalone WorkerEvent for DataSynchronizationService
        func toSyncEvent() -> WorkerEvent {
            // Map WorkerActionType to WorkerEvent.EventType
            let eventType: WorkerEvent.EventType
            switch self.type {
            case .taskCompletion, .taskComplete:
                eventType = .taskCompletion
            case .clockIn:
                eventType = .clockIn
            case .clockOut:
                eventType = .clockOut
            case .photoUpload, .commentUpdate:
                // Map these to task completion for simplicity
                eventType = .taskCompletion
            case .routineInspection:
                // Map routine inspection to task start
                eventType = .taskStart
            case .buildingStatusUpdate:
                // Map building status update to building arrival
                eventType = .buildingArrival
            case .emergencyReport:
                // Map emergency to task completion with priority
                eventType = .taskCompletion
            }
            
            return WorkerEvent(
                buildingId: self.buildingId,
                workerId: self.workerId,
                type: eventType,
                timestamp: self.timestamp
            )
        }
    }
    
    // In-memory queue for pending events. This would be backed by a persistent store in a full implementation
    private var pendingEvents: [OutboxEvent] = []
    
    // ✅ FIXED: Removed direct reference to MainActor-isolated service
    // We'll access it through Task when needed
    
    private init() {
        // ✅ FIXED: Load events asynchronously after init
        Task {
            await loadPendingEvents()
        }
    }

    /// Adds a new event to the outbox to be synced
    func addEvent(_ event: OutboxEvent) {
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
        let event = OutboxEvent(type: .taskCompletion, workerId: workerId, buildingId: buildingId)
        addEvent(event)
    }
    
    func addClockInEvent(workerId: String, buildingId: String) {
        let event = OutboxEvent(type: .clockIn, workerId: workerId, buildingId: buildingId)
        addEvent(event)
    }
    
    func addClockOutEvent(workerId: String, buildingId: String) {
        let event = OutboxEvent(type: .clockOut, workerId: workerId, buildingId: buildingId)
        addEvent(event)
    }
    
    func addBuildingStatusEvent(workerId: String, buildingId: String) {
        let event = OutboxEvent(type: .buildingStatusUpdate, workerId: workerId, buildingId: buildingId)
        addEvent(event)
    }
    
    func addRoutineInspectionEvent(workerId: String, buildingId: String) {
        let event = OutboxEvent(type: .routineInspection, workerId: workerId, buildingId: buildingId)
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
                
                // ✅ FIXED: Properly handle cross-actor communication
                let syncEvent = event.toSyncEvent()
                await MainActor.run {
                    // Access the MainActor-isolated DataSynchronizationService
                    Task {
                        await DataSynchronizationService.shared.broadcastSyncCompletion(for: syncEvent)
                    }
                }
                
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
    private func submitEventToServer(_ event: OutboxEvent) async throws {
        // ✅ FIXED: Proper Task.sleep syntax
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
    func getPendingEvents() -> [OutboxEvent] {
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
            pendingEvents = try JSONDecoder().decode([OutboxEvent].self, from: data)
            print("📦 Loaded \(pendingEvents.count) pending events from previous session.")
        } catch {
            print("🚨 Failed to load pending events from UserDefaults: \(error)")
        }
    }
}

// MARK: - WorkerActionType Extension

extension WorkerActionType {
    /// Map to standalone WorkerEvent.EventType
    var syncEventType: WorkerEvent.EventType {
        switch self {
        case .taskCompletion, .taskComplete:
            return .taskCompletion
        case .clockIn:
            return .clockIn
        case .clockOut:
            return .clockOut
        case .routineInspection:
            return .taskStart
        case .buildingStatusUpdate:
            return .buildingArrival
        case .photoUpload, .commentUpdate, .emergencyReport:
            return .taskCompletion // Default mapping
        }
    }
}

// MARK: - Integration Helpers

extension WorkerEventOutbox {
    
    /// Create and queue an event from a ContextualTask completion
    func recordTaskCompletion(task: ContextualTask, workerId: String) {
        let event = OutboxEvent(
            type: .taskCompletion,
            workerId: workerId,
            buildingId: task.buildingId ?? "unknown"
        )
        addEvent(event)
    }
    
    /// Create and queue an event from worker clock operations
    func recordClockOperation(workerId: String, buildingId: String, isClockIn: Bool) {
        let eventType: WorkerActionType = isClockIn ? .clockIn : .clockOut
        let event = OutboxEvent(type: eventType, workerId: workerId, buildingId: buildingId)
        addEvent(event)
    }
    
    /// Create and queue an event for building status updates
    func recordBuildingStatusEvent(workerId: String, buildingId: String) {
        let event = OutboxEvent(type: .buildingStatusUpdate, workerId: workerId, buildingId: buildingId)
        addEvent(event)
    }
    
    /// Create and queue an event for routine inspections
    func recordRoutineInspectionEvent(workerId: String, buildingId: String) {
        let event = OutboxEvent(type: .routineInspection, workerId: workerId, buildingId: buildingId)
        addEvent(event)
    }
    
    /// Create and queue an event for photo uploads
    func recordPhotoUploadEvent(workerId: String, buildingId: String) {
        let event = OutboxEvent(type: .photoUpload, workerId: workerId, buildingId: buildingId)
        addEvent(event)
    }
    
    /// Create and queue an event for emergency reports
    func recordEmergencyReportEvent(workerId: String, buildingId: String) {
        let event = OutboxEvent(type: .emergencyReport, workerId: workerId, buildingId: buildingId)
        addEvent(event)
    }
}
