//
//  ClockInManager.swift
//  FrancoSphere
//
//  Manages worker clock-in/out state and location validation
//

import Foundation
import SwiftUI
import CoreLocation

@MainActor
class ClockInManager: ObservableObject {
    static let shared = ClockInManager()
    
    @Published var isClockedIn = false
    @Published var currentBuilding: NamedCoordinate?
    @Published var currentStatus: WorkerStatus = .offsite
    @Published var clockInTime: Date?
    @Published var clockOutTime: Date?
    
    private let authManager = NewAuthManager.shared
    
    enum WorkerStatus {
        case active, offsite, onBreak
        
        var color: Color {
            switch self {
            case .active: return .green
            case .offsite: return .red
            case .onBreak: return .orange
            }
        }
        
        var text: String {
            switch self {
            case .active: return "On Site"
            case .offsite: return "Off Site"
            case .onBreak: return "On Break"
            }
        }
        
        var icon: String {
            switch self {
            case .active: return "checkmark.circle.fill"
            case .offsite: return "xmark.circle.fill"
            case .onBreak: return "pause.circle.fill"
            }
        }
    }
    
    private init() {}
    
    func toggleClockIn() async {
        if isClockedIn {
            await clockOut()
        } else {
            await clockIn()
        }
    }
    
    private func clockIn() async {
        // For now, we'll use a default building since location services aren't set up
        // In production, this would use actual GPS location
        let defaultBuilding = NamedCoordinate.allBuildings.first { $0.id == "1" } ?? NamedCoordinate.allBuildings[0]
        
        // Update state
        isClockedIn = true
        currentBuilding = defaultBuilding
        currentStatus = .active
        clockInTime = Date()
        
        // Log to database
        await logClockIn()
        
        print("✅ Clocked in at \(defaultBuilding.name)")
    }
    
    private func clockOut() async {
        isClockedIn = false
        currentStatus = .offsite
        clockOutTime = Date()
        
        // Log to database
        await logClockOut()
        
        print("✅ Clocked out")
        
        // Reset
        currentBuilding = nil
        clockInTime = nil
    }
    
    private func logClockIn() async {
        // Save to SQLite using existing managers
        guard let workerId = authManager.currentWorkerId,
              let buildingId = currentBuilding?.id else { return }
        
        // Log using existing database structure
        print("📝 Logging clock-in: Worker \(workerId) at Building \(buildingId)")
        
        // You can add actual database logging here using SQLiteManager
    }
    
    private func logClockOut() async {
        // Save to SQLite
        guard let workerId = authManager.currentWorkerId else { return }
        
        print("📝 Logging clock-out: Worker \(workerId)")
        
        // You can add actual database logging here using SQLiteManager
    }
}

// Extension to add currentWorkerId if it doesn't exist
extension NewAuthManager {
    var currentWorkerId: String? {
        // FIXED: All IDs now match the database seeding
        switch currentWorkerName {
        case "Edwin Lema": return "2"     // FIXED: Was "3", now "2"
        case "Greg Hutson": return "1"
        case "Kevin Dutan": return "4"    // FIXED: Was "2", now "4"
        case "Mercedes Inamagua": return "5"
        case "Luis Lopez": return "6"
        case "Angel Guirachocha": return "7"
        case "Shawn Magloire": return "8" // FIXED: Was "7", now "8"
        default: return nil
        }
    }
}
