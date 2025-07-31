//
//  WorkerEventOutbox.swift
//  FrancoSphere v6.0
//
//  ✅ CLEAN: No dependency on DataSynchronizationService or WorkerEvent
//  ✅ SELF-CONTAINED: Works independently
//  ✅ V6.0: Phase 2.2 - Enhanced Offline Queue
//

import Foundation

/// An actor that manages a persistent, offline-first queue of worker actions
actor WorkerEventOutbox {
    static let shared = WorkerEventOutbox()

    /// Represents a single worker action that needs to be synced
    struct OutboxEvent: Codable, Identifiable {
        let id: String
        let type: WorkerActionType
        let payload: Data
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
            self.retryCount = 0
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
    }
    
    // In-memory queue for pending events
    private var pendingEvents: [OutboxEvent] = []
    
    // Track last sync time
    private var lastSyncTime: Date?
    
    // Track sync state
    private var isSyncing = false
    
    private init() {
        // Load any persisted events on init
        loadPendingEvents()
    }

    /// Adds a new event to the outbox to be synced
    func addEvent(_ event: OutboxEvent) async {
        print("📬 Adding event to outbox: \(event.type.rawValue) (ID: \(event.id))")
        pendingEvents.append(event)
        savePendingEvents()
        
        // Attempt to flush immediately
        await attemptFlush()
    }
    
    /// Create and queue an event from a task completion
    func recordTaskCompletion(taskId: String, taskTitle: String, workerId: String, buildingId: String) async {
        let event = OutboxEvent(
            type: .taskCompletion,
            workerId: workerId,
            buildingId: buildingId
        )
        await addEvent(event)
    }
    
    /// Create and queue an event from worker clock operations
    func recordClockOperation(workerId: String, buildingId: String, isClockIn: Bool) async {
        let eventType: WorkerActionType = isClockIn ? .clockIn : .clockOut
        let event = OutboxEvent(type: eventType, workerId: workerId, buildingId: buildingId)
        await addEvent(event)
    }

    /// Create and queue an event for building status updates
    func recordBuildingStatusEvent(workerId: String, buildingId: String) async {
        let event = OutboxEvent(type: .buildingStatusUpdate, workerId: workerId, buildingId: buildingId)
        await addEvent(event)
    }
    
    /// Create and queue an event for routine inspections
    func recordRoutineInspectionEvent(workerId: String, buildingId: String) async {
        let event = OutboxEvent(type: .routineInspection, workerId: workerId, buildingId: buildingId)
        await addEvent(event)
    }
    
    /// Create and queue an event for photo uploads
    func recordPhotoUploadEvent(workerId: String, buildingId: String, photoData: Data? = nil) async {
        if let photoData = photoData,
           let event = try? OutboxEvent(type: .photoUpload, workerId: workerId, buildingId: buildingId, payload: photoData) {
            await addEvent(event)
        } else {
            let event = OutboxEvent(type: .photoUpload, workerId: workerId, buildingId: buildingId)
            await addEvent(event)
        }
    }
    
    /// Create and queue an event for emergency reports
    func recordEmergencyReportEvent(workerId: String, buildingId: String, description: String? = nil) async {
        let payload = ["description": description ?? "Emergency reported"]
        if let event = try? OutboxEvent(type: .emergencyReport, workerId: workerId, buildingId: buildingId, payload: payload) {
            await addEvent(event)
        } else {
            let event = OutboxEvent(type: .emergencyReport, workerId: workerId, buildingId: buildingId)
            await addEvent(event)
        }
    }

    /// Attempts to send all pending events to the server
    func attemptFlush() async {
        guard !pendingEvents.isEmpty else { return }
        guard !isSyncing else { return } // Prevent concurrent flushes
        
        isSyncing = true
        defer { isSyncing = false }
        
        print("📤 Attempting to flush \(pendingEvents.count) events...")
        
        var successfullySyncedEvents: [String] = []

        for var event in pendingEvents {
            do {
                // Simulate a network request
                try await submitEventToServer(event)
                
                // If successful, mark for removal
                successfullySyncedEvents.append(event.id)
                
                print("   ✅ Successfully synced event \(event.id)")
                
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
            lastSyncTime = Date()
            print("✅ Flushed \(successfullySyncedEvents.count) events successfully.")
        }
    }
    
    /// Simulates submitting a single event to a remote server
    private func submitEventToServer(_ event: OutboxEvent) async throws {
        // Simple delay to simulate network request
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global().asyncAfter(deadline: .now() + Double.random(in: 0.1...0.5)) {
                // Simulate a potential network failure (10% chance)
                if Double.random(in: 0...1) < 0.1 {
                    continuation.resume(throwing: URLError(.notConnectedToInternet))
                } else {
                    continuation.resume()
                }
            }
        }
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
    
    /// Get last sync time
    func getLastSyncTime() -> Date? {
        return lastSyncTime
    }
    
    /// Check if currently syncing
    func isSyncing() -> Bool {
        return isSyncing
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
        
        // Reset retry counts for high-retry events
        for index in pendingEvents.indices {
            if pendingEvents[index].retryCount >= 5 {
                pendingEvents[index].retryCount = 0
            }
        }
        
        await attemptFlush()
    }
    
    /// Get a summary of queue status
    func getQueueStatus() -> (pending: Int, highRetry: Int, lastSync: Date?) {
        let pending = pendingEvents.count
        let highRetry = pendingEvents.filter { $0.retryCount >= 3 }.count
        return (pending, highRetry, lastSyncTime)
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
    /// Display name for UI
    var displayName: String {
        switch self {
        case .taskComplete, .taskCompletion:
            return "Task Completed"
        case .clockIn:
            return "Clocked In"
        case .clockOut:
            return "Clocked Out"
        case .photoUpload:
            return "Photo Uploaded"
        case .commentUpdate:
            return "Comment Added"
        case .routineInspection:
            return "Routine Inspection"
        case .buildingStatusUpdate:
            return "Building Status Updated"
        case .emergencyReport:
            return "Emergency Reported"
        }
    }
    
    /// Category for grouping similar actions
    var category: String {
        switch self {
        case .taskComplete, .taskCompletion, .routineInspection:
            return "Tasks"
        case .clockIn, .clockOut:
            return "Time Tracking"
        case .photoUpload, .commentUpdate:
            return "Evidence"
        case .buildingStatusUpdate:
            return "Building"
        case .emergencyReport:
            return "Emergency"
        }
    }
}
