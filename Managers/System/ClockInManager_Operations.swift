//
//  ClockInManager.swift
//  CyntientOps v6.0 - PORTFOLIO ACCESS FIXED
//
//  ✅ FIXED: Portfolio-wide access for clock-in (no building restrictions)
//  ✅ ADDED: Separate methods for assigned vs all buildings
//  ✅ REMOVED: Building validation restrictions
//

import Foundation
import SwiftUI
import CoreLocation

public actor ClockInManager {
    public static let shared = ClockInManager()

    private var activeSessions: [CoreTypes.WorkerID: ClockInSession] = [:]

    private init() {
        print("⏰ ClockInManager (Portfolio Access) initialized")
    }

    public struct ClockInSession {
        let workerId: CoreTypes.WorkerID
        let buildingId: CoreTypes.BuildingID
        let buildingName: String
        let startTime: Date
        let location: CLLocationCoordinate2D?
    }

    // MARK: - Portfolio Access Methods

    /// Get ALL buildings in portfolio for clock-in (coverage capability)
    public func getAvailableBuildings(for workerId: CoreTypes.WorkerID) async -> [NamedCoordinate] {
        do {
            // Workers can clock in anywhere for coverage
            let allBuildings = try await BuildingService.shared.getAllBuildings()
            print("✅ Available buildings for clock-in: \(allBuildings.count) (portfolio-wide)")
            return allBuildings
        } catch {
            print("❌ Failed to get available buildings: \(error)")
            return []
        }
    }

    /// Get assigned buildings separately for UI display
    public func getAssignedBuildings(for workerId: CoreTypes.WorkerID) async -> [NamedCoordinate] {
        do {
            let assignedBuildings = try await BuildingService.shared.getBuildingsForWorker(workerId)
            print("✅ Assigned buildings: \(assignedBuildings.count)")
            return assignedBuildings
        } catch {
            print("❌ Failed to get assigned buildings: \(error)")
            return []
        }
    }

    // MARK: - Clock In/Out Methods (NO RESTRICTIONS)

    /// Clock in at ANY building - no validation needed for coverage
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
        
        print("✅ Worker \(workerId) clocked IN at \(building.name) (portfolio access)")
        
        // Notify UI
        await MainActor.run {
            NotificationCenter.default.post(name: .workerClockInChanged, object: nil, userInfo: [
                "workerId": workerId,
                "isClockedIn": true,
                "buildingId": building.id,
                "buildingName": building.name
            ])
        }
    }

    public func clockOut(workerId: CoreTypes.WorkerID) async throws {
        guard let session = activeSessions[workerId] else {
            throw ClockInError.notClockedIn
        }

        activeSessions.removeValue(forKey: workerId)
        
        print("✅ Worker \(workerId) clocked OUT from \(session.buildingName)")

        await MainActor.run {
            NotificationCenter.default.post(name: .workerClockInChanged, object: nil, userInfo: [
                "workerId": workerId,
                "isClockedIn": false
            ])
        }
    }

    public func getClockInStatus(for workerId: CoreTypes.WorkerID) -> (isClockedIn: Bool, session: ClockInSession?) {
        let session = activeSessions[workerId]
        return (session != nil, session)
    }

    // MARK: - Session Management

    public func getAllActiveSessions() -> [ClockInSession] {
        return Array(activeSessions.values)
    }

    public func getActiveSessionsForBuilding(_ buildingId: CoreTypes.BuildingID) -> [ClockInSession] {
        return activeSessions.values.filter { $0.buildingId == buildingId }
    }
}

// MARK: - Error Types (Simplified)

public enum ClockInError: LocalizedError {
    case alreadyClockedIn
    case notClockedIn
    case locationMismatch
    
    public var errorDescription: String? {
        switch self {
        case .alreadyClockedIn:
            return "Worker is already clocked in"
        case .notClockedIn:
            return "Worker is not clocked in"
        case .locationMismatch:
            return "Location does not match building"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let workerClockInChanged = Notification.Name("workerClockInChanged")
}
