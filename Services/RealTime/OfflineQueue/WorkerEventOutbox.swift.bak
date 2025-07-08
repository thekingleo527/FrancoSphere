//
//  WorkerEventOutbox.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/7/25.
//
//
//  WorkerEventOutbox.swift
//  FrancoSphere
//
//  ✅ V6.0: Phase 2.2 - Enhanced Offline Queue
//  ✅ Safely stores worker actions for reliable synchronization.
//  ✅ Triggers the DataSynchronizationService upon successful sync.
//

import Foundation

/// An actor that manages a persistent, offline-first queue of worker actions.
/// It ensures that every action is eventually sent to the server, even if the
/// device is offline when the action is recorded.
actor WorkerEventOutbox {
    static let shared = WorkerEventOutbox()

    /// Represents a single worker action that needs to be synced.
    struct WorkerEvent: Codable, Identifiable {
        let id: String
        let type: WorkerActionType
        let payload: Data // A flexible container for any Codable data
        let timestamp: Date
        let buildingId: CoreTypes.BuildingID
        let workerId: CoreTypes.WorkerID
        var retryCount: Int = 0
        
        // Convenience initializer for actions with evidence
        init<T: Codable>(type: WorkerActionType, workerId: CoreTypes.WorkerID, buildingId: CoreTypes.BuildingID, payload: T) throws {
            self.id = UUID().uuidString
            self.type = type
            self.workerId = workerId
            self.buildingId = buildingId
            self.timestamp = Date()
            self.payload = try JSONEncoder().encode(payload)
        }
    }
    
    // In-memory queue for pending events. This would be backed by a persistent store in a full implementation.
    private var pendingEvents: [WorkerEvent] = []
    
    private let dataSyncService = DataSynchronizationService.shared

    private init() {
        // Load pending events from persistent storage on startup
        loadPendingEvents()
    }

    /// Adds a new event to the outbox to be synced.
    func addEvent(_ event: WorkerEvent) {
        print("📬 Adding event to outbox: \(event.type.rawValue) (ID: \(event.id))")
        pendingEvents.append(event)
        savePendingEvents()
        
        // Immediately try to flush the queue
        Task {
            await attemptFlush()
        }
    }

    /// Attempts to send all pending events to the server.
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
                await dataSyncService.broadcastSyncCompletion(for: event)
                
            } catch {
                // Handle retry logic
                event.retryCount += 1
                print("⚠️ Failed to sync event \(event.id), retry \(event.retryCount). Error: \(error)")
                // Update the event in the queue with the new retry count
                if let index = pendingEvents.firstIndex(where: { $0.id == event.id }) {
                    pendingEvents[index] = event
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
    
    /// Simulates submitting a single event to a remote server.
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
