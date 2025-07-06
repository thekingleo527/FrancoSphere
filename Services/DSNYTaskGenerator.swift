//
//  DSNYTaskGenerator.swift
//  FrancoSphere
//
//  ✅ STRUCTURAL FIX: All scope issues resolved
//  ✅ Proper function declarations and closures
//  ✅ Fixed missing helper methods
//

import Foundation
import SQLite

/// Service for generating DSNY-compliant sanitation tasks
actor DSNYTaskGenerator {
    
    // MARK: - Singleton
    static let shared = DSNYTaskGenerator()
    
    // MARK: - Private Properties
    private var sqliteManager: SQLiteManager?
    private let calendar = Calendar.current
    
    // MARK: - NYC DSNY Schedule Constants
    private struct DSNYSchedule {
        static let setoutTimeStart = 72000 // 8:00 PM in seconds since midnight
        static let setoutTimeEnd = 86400   // 12:00 AM in seconds since midnight
        static let pickupTimeStart = 21600 // 6:00 AM in seconds since midnight
        static let pickupTimeEnd = 43200   // 12:00 PM in seconds since midnight
    }
    
    private init() {
        self.sqliteManager = SQLiteManager.shared
    }
    
    // MARK: - Public Task Generation Methods
    
    /// Generate DSNY tasks for today based on collection schedules
    func generateTodaysDSNYTasks() async throws -> [ContextualTask] {
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let todayStr = getDayAbbreviation(for: weekday)
        
        guard sqliteManager != nil else {
            throw DSNYError.databaseUnavailable
        }
        
        let schedules = try await fetchDSNYSchedules(for: todayStr)
        var tasks: [ContextualTask] = []
        
        for schedule in schedules {
            let setoutTask = generateSetoutTask(from: schedule, for: today)
            tasks.append(setoutTask)
            
            let pickupTask = generatePickupTask(from: schedule, for: today)
            tasks.append(pickupTask)
            
            if isComplianceCheckNeeded(schedule) {
                let complianceTask = generateComplianceTask(from: schedule, for: today)
                tasks.append(complianceTask)
            }
        }
        
        return tasks
    }
    
    /// Generate DSNY tasks for a specific building
    func generateDSNYTasksForBuilding(_ buildingId: String) async throws -> [ContextualTask] {
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let todayStr = getDayAbbreviation(for: weekday)
        
        guard sqliteManager != nil else {
            throw DSNYError.databaseUnavailable
        }
        
        let schedules = try await fetchDSNYSchedules(for: todayStr, buildingId: buildingId)
        var tasks: [ContextualTask] = []
        
        for schedule in schedules {
            let setoutTask = generateSetoutTask(from: schedule, for: today)
            let pickupTask = generatePickupTask(from: schedule, for: today)
            
            tasks.append(setoutTask)
            tasks.append(pickupTask)
        }
        
        return tasks
    }
    
    /// Check if DSNY collection is scheduled for a specific day and building
    func isDSNYCollectionScheduled(for buildingId: String, on date: Date) async throws -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        let dayStr = getDayAbbreviation(for: weekday)
        
        let schedules = try await fetchDSNYSchedules(for: dayStr, buildingId: buildingId)
        return !schedules.isEmpty
    }
    
    /// Get DSNY collection schedule for a building
    func getDSNYSchedule(for buildingId: String) async throws -> [DSNYCollectionInfo] {
        guard let sqliteManager = sqliteManager else {
            throw DSNYError.databaseUnavailable
        }
        
        let query = """
            SELECT route_id, collection_days, earliest_setout, latest_pickup, 
                   pickup_window_start, pickup_window_end
            FROM dsny_schedules 
            WHERE building_ids LIKE ? AND route_status = 'active'
        """
        
        let parameters: [Binding] = ["%\(buildingId)%"]
        let results = try await sqliteManager.query(query, parameters)
        
        var collectionInfos: [DSNYCollectionInfo] = []
        
        for row in results {
            guard let routeId = row["route_id"] as? String,
                  let collectionDays = row["collection_days"] as? String,
                  let earliestSetout = row["earliest_setout"] as? Int,
                  let latestPickup = row["latest_pickup"] as? Int else {
                continue
            }
            
            let info = DSNYCollectionInfo(
                routeId: routeId,
                collectionDays: collectionDays.components(separatedBy: ","),
                setoutTime: formatTime(from: earliestSetout),
                pickupTime: formatTime(from: latestPickup),
                buildingId: buildingId
            )
            
            collectionInfos.append(info)
        }
        
        return collectionInfos
    }
    
    // MARK: - Private Task Generation Methods
    
    private func generateSetoutTask(from schedule: DSNYScheduleResult, for date: Date) -> ContextualTask {
        let buildingName = getBuildingName(for: schedule.primaryBuildingId)
        
        return ContextualTask(
            name: "DSNY Set-out: \(buildingName)",
            description: "Set out trash and recycling containers for DSNY collection",
            buildingId: schedule.primaryBuildingId,
            workerId: getAssignedWorker(for: schedule.primaryBuildingId) ?? "system",
            category: .sanitation,
            urgency: .high
        )
    }
    
    private func generatePickupTask(from schedule: DSNYScheduleResult, for date: Date) -> ContextualTask {
        let buildingName = getBuildingName(for: schedule.primaryBuildingId)
        
        return ContextualTask(
            name: "DSNY Return: \(buildingName)",
            description: "Return empty trash and recycling containers after DSNY collection",
            buildingId: schedule.primaryBuildingId,
            workerId: getAssignedWorker(for: schedule.primaryBuildingId) ?? "system",
            category: .sanitation,
            urgency: .medium
        )
    }
    
    private func generateComplianceTask(from schedule: DSNYScheduleResult, for date: Date) -> ContextualTask {
        let buildingName = getBuildingName(for: schedule.primaryBuildingId)
        
        return ContextualTask(
            name: "DSNY Compliance Check: \(buildingName)",
            description: "Ensure DSNY collection compliance and proper container placement",
            buildingId: schedule.primaryBuildingId,
            workerId: getAssignedWorker(for: schedule.primaryBuildingId) ?? "system",
            category: .sanitation,
            urgency: .medium
        )
    }
    
    // MARK: - Database Query Methods
    
    private func fetchDSNYSchedules(for dayAbbreviation: String, buildingId: String? = nil) async throws -> [DSNYScheduleResult] {
        guard let sqliteManager = sqliteManager else {
            throw DSNYError.databaseUnavailable
        }
        
        var query = """
            SELECT route_id, building_ids, collection_days, earliest_setout, 
                   latest_pickup, pickup_window_start, pickup_window_end
            FROM dsny_schedules 
            WHERE collection_days LIKE ? AND route_status = 'active'
        """
        
        var parameters: [Binding] = ["%\(dayAbbreviation)%"]
        
        if let buildingId = buildingId {
            query += " AND building_ids LIKE ?"
            parameters.append("%\(buildingId)%")
        }
        
        let results = try await sqliteManager.query(query, parameters)
        var scheduleResults: [DSNYScheduleResult] = []
        
        for row in results {
            guard let routeId = row["route_id"] as? String,
                  let buildingIds = row["building_ids"] as? String,
                  let collectionDays = row["collection_days"] as? String,
                  let earliestSetout = row["earliest_setout"] as? Int,
                  let latestPickup = row["latest_pickup"] as? Int,
                  let pickupWindowStart = row["pickup_window_start"] as? Int,
                  let pickupWindowEnd = row["pickup_window_end"] as? Int else {
                continue
            }
            
            let primaryBuildingId = buildingIds.components(separatedBy: ",").first ?? ""
            
            let schedule = DSNYScheduleResult(
                routeId: routeId,
                primaryBuildingId: primaryBuildingId,
                collectionDays: collectionDays,
                earliestSetout: earliestSetout,
                latestPickup: latestPickup,
                pickupWindowStart: pickupWindowStart,
                pickupWindowEnd: pickupWindowEnd
            )
            
            scheduleResults.append(schedule)
        }
        
        return scheduleResults
    }
    
    // MARK: - Helper Methods
    
    private func getDayAbbreviation(for weekday: Int) -> String {
        let dayAbbreviations = ["", "SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
        return dayAbbreviations[weekday]
    }
    
    private func formatTime(from seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
    
    private func getBuildingName(for buildingId: String) -> String {
        let buildingMap: [String: String] = [
            "1": "12 West 18th Street",
            "2": "29-31 East 20th Street",
            "3": "36 Walker Street",
            "4": "41 Elizabeth Street",
            "14": "Rubin Museum"
        ]
        
        return buildingMap[buildingId] ?? "Building \(buildingId)"
    }
    
    private func getAssignedWorker(for buildingId: String) -> String? {
        switch buildingId {
        case "1", "7": return "Greg Hutson"
        case "2", "11": return "Edwin Lema"
        case "5", "10": return "Kevin Dutan"
        case "14", "15": return "Shawn Magloire"
        default: return "Unassigned"
        }
    }
    
    private func isComplianceCheckNeeded(_ schedule: DSNYScheduleResult) -> Bool {
        let highTrafficRoutes = ["R1-MON-WED-FRI", "R2-TUE-THU", "R3-MON-WED-FRI"]
        return highTrafficRoutes.contains(schedule.routeId)
    }
}

// MARK: - Supporting Models

struct DSNYScheduleResult {
    let routeId: String
    let primaryBuildingId: String
    let collectionDays: String
    let earliestSetout: Int
    let latestPickup: Int
    let pickupWindowStart: Int
    let pickupWindowEnd: Int
}

struct DSNYCollectionInfo {
    let routeId: String
    let collectionDays: [String]
    let setoutTime: String
    let pickupTime: String
    let buildingId: String
}

// MARK: - Error Types

enum DSNYError: Error, LocalizedError {
    case databaseUnavailable
    case invalidSchedule
    case noCollectionScheduled
    
    var errorDescription: String? {
        switch self {
        case .databaseUnavailable:
            return "Database connection is not available"
        case .invalidSchedule:
            return "Invalid DSNY collection schedule"
        case .noCollectionScheduled:
            return "No collection scheduled for the specified date"
        }
    }
}

// MARK: - Extensions for Integration

extension DSNYTaskGenerator {
    func getDSNYStatusSummary() async throws -> DSNYStatusSummary {
        let todaysTasks = try await generateTodaysDSNYTasks()
        
        let setoutTasks = todaysTasks.filter { $0.name.contains("Set-out") }
        let pickupTasks = todaysTasks.filter { $0.name.contains("Return") }
        let completedTasks = todaysTasks.filter { $0.status == "completed" }
        
        return DSNYStatusSummary(
            totalCollections: setoutTasks.count,
            completedCollections: completedTasks.count,
            pendingSetouts: setoutTasks.filter { $0.status == "pending" }.count,
            pendingReturns: pickupTasks.filter { $0.status == "pending" }.count,
            nextCollection: getNextCollectionTime(from: todaysTasks)
        )
    }
    
    private func getNextCollectionTime(from tasks: [ContextualTask]) -> String {
        let pendingTasks = tasks.filter { $0.status == "pending" }
        guard let nextTask = pendingTasks.min(by: { ($0.startTime ?? "") < ($1.startTime ?? "") }) else {
            return "No upcoming collections"
        }
        
        return nextTask.startTime ?? "Time TBD"
    }
}

struct DSNYStatusSummary {
    let totalCollections: Int
    let completedCollections: Int
    let pendingSetouts: Int
    let pendingReturns: Int
    let nextCollection: String
}
