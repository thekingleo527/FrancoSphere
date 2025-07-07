//
//  ClockInManager.swift
//  FrancoSphere
//
//  ✅ V6.0 REFACTOR: Converted to an actor to prevent race conditions.
//  ✅ FIXED: Removed redundant @MainActor declaration.
//

import Foundation
import SwiftUI
import CoreLocation

// ✅ FIXED: The @MainActor attribute is removed. Actors manage their own concurrency.
public actor ClockInManager {
    public static let shared = ClockInManager()

    // Internal state, now protected by the actor.
    private var activeSessions: [CoreTypes.WorkerID: ClockInSession] = [:]

    private init() {
        print("⏰ ClockInManager (Actor) initialized and ready.")
    }

    /// Represents an active clock-in session for a worker.
    public struct ClockInSession {
        let workerId: CoreTypes.WorkerID
        let buildingId: CoreTypes.BuildingID
        let buildingName: String
        let startTime: Date
        let location: CLLocationCoordinate2D?
    }

    // MARK: - Public API

    /// Clocks a worker into a specific building. Throws an error if the worker is already clocked in.
    public func clockIn(workerId: CoreTypes.WorkerID, building: NamedCoordinate, location: CLLocationCoordinate2D? = nil) async throws {
        guard activeSessions[workerId] == nil else {
            throw ClockInError.alreadyClockedIn
        }

        let session = ClockInSession(
            workerId: workerId,
            buildingId: building.id,
            buildingName: building.name,
            startTime: Date(),
            location: location
        )
        
        activeSessions[workerId] = session
        
        print("✅ Worker \(workerId) clocked IN at \(building.name).")
        
        // Post a notification for the UI to update
        await MainActor.run {
            NotificationCenter.default.post(name: .workerClockInChanged, object: nil, userInfo: [
                "workerId": workerId,
                "isClockedIn": true,
                "buildingId": building.id,
                "buildingName": building.name
            ])
        }
    }

    /// Clocks a worker out. Throws an error if the worker was not clocked in.
    public func clockOut(workerId: CoreTypes.WorkerID) async throws {
        guard let session = activeSessions[workerId] else {
            throw ClockInError.notClockedIn
        }

        activeSessions.removeValue(forKey: workerId)
        
        print("✅ Worker \(workerId) clocked OUT from \(session.buildingName).")

        // Post a notification for the UI to update
        await MainActor.run {
            NotificationCenter.default.post(name: .workerClockInChanged, object: nil, userInfo: [
                "workerId": workerId,
                "isClockedIn": false
            ])
        }
    }

    /// Retrieves the current clock-in status for a given worker.
    public func getClockInStatus(for workerId: CoreTypes.WorkerID) -> (isClockedIn: Bool, session: ClockInSession?) {
        if let session = activeSessions[workerId] {
            return (true, session)
        }
        return (false, nil)
    }
}

// MARK: - Error Types
public enum ClockInError: LocalizedError {
    case alreadyClockedIn
    case notClockedIn
    case locationMismatch

    public var errorDescription: String? {
        switch self {
        case .alreadyClockedIn:
            return "This worker is already clocked in at another location."
        case .notClockedIn:
            return "This worker is not currently clocked in."
        case .locationMismatch:
            return "You must be at the building location to perform this action."
        }
    }
}
