//
//  DSNYTaskGenerator.swift
//  FrancoSphere
//
//  ✅ DSNY (Department of Sanitation New York) Task Generator Service
//  ✅ Generates compliance-based trash and recycling collection tasks
//  ✅ Integrates with existing WorkerContextEngine and SQLite data
//  ✅ Supports NYC-specific sanitation schedules and requirements
//

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import SQLite
// FrancoSphere Types Import
// (This comment helps identify our import)


/// Service for generating DSNY-compliant sanitation tasks
actor DSNYTaskGenerator {
    
    // MARK: - Singleton
    static let shared = DSNYTaskGenerator()
    
    // MARK: - Private Properties
    private var sqliteManager: SQLiteManager?
    private let calendar = Calendar.current
    
    // MARK: - NYC DSNY Schedule Constants
    private struct DSNYSchedule {
        static let setoutTimeStart = 72000 // 8:00 PM (20:00) in seconds since midnight
        static let setoutTimeEnd = 86400   // 12:00 AM (24:00) in seconds since midnight
        static let pickupTimeStart = 21600 // 6:00 AM in seconds since midnight
        static let pickupTimeEnd = 43200   // 12:00 PM in seconds since midnight
        static let earlySetoutPenalty = 72000 // Cannot set out before 8:00 PM
    }
    
    private init() {
        self.sqliteManager = SQLiteManager.shared
    }
    
    // MARK: - Public Task Generation Methods
    
    /// Generate DSNY tasks for today based on collection schedules
    /// - Returns: Array of generated DSNY tasks
    func generateTodaysDSNYTasks() async throws -> [ContextualTask] {
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let todayStr = getDayAbbreviation(for: weekday)
        
        guard sqliteManager != nil else {
            throw DSNYError.databaseUnavailable
        }
        
        // Fetch DSNY schedules for today
        let schedules = try await fetchDSNYSchedules(for: todayStr)
        var tasks: [ContextualTask] = []
        
        for schedule in schedules {
            // Generate set-out task (evening before)
            let setoutTask = generateSetoutTask(from: schedule, for: today)
            tasks.append(setoutTask)
            
            // Generate pickup/return task (morning after)
            let pickupTask = generatePickupTask(from: schedule, for: today)
            tasks.append(pickupTask)
            
            // Generate compliance check task if needed
            if isComplianceCheckNeeded(schedule) {
                let complianceTask = generateComplianceTask(from: schedule, for: today)
                tasks.append(complianceTask)
            }
        }
        
        return tasks
    }
    
    /// Generate DSNY tasks for a specific building
    /// - Parameter buildingId: The building ID to generate tasks for
    /// - Returns: Array of DSNY tasks for the building
    func generateDSNYTasksForBuilding(_ buildingId: String) async throws -> [ContextualTask] {
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let todayStr = getDayAbbreviation(for: weekday)
        
        guard sqliteManager != nil else {
            throw DSNYError.databaseUnavailable
        }
        
        // Fetch DSNY schedules for this building and today
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
    /// - Parameters:
    ///   - buildingId: The building ID to check
    ///   - date: The date to check
    /// - Returns: Boolean indicating if collection is scheduled
    func isDSNYCollectionScheduled(for buildingId: String, on date: Date) async throws -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        let dayStr = getDayAbbreviation(for: weekday)
        
        let schedules = try await fetchDSNYSchedules(for: dayStr, buildingId: buildingId)
        return !schedules.isEmpty
    }
    
    /// Get DSNY collection schedule for a building
    /// - Parameter buildingId: The building ID
    /// - Returns: Array of collection days and times
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
        
        // Use async query with proper error handling
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
        let taskId = "dsny_setout_\(schedule.routeId)_\(date.timeIntervalSince1970)"
        let buildingName = getBuildingName(for: schedule.primaryBuildingId)
        
        return ContextualTask(
            id: taskId,
            name: "DSNY Set-out (\(schedule.routeId))",
            buildingId: schedule.primaryBuildingId,
            buildingName: buildingName,
            category: "DSNY Operations",
            startTime: formatTime(from: schedule.earliestSetout),
            endTime: formatTime(from: schedule.earliestSetout + 1800), // 30 minutes
            recurrence: "Weekly",
            skillLevel: "Basic",
            status: "pending",
            urgencyLevel: "high",
            assignedWorkerName: getAssignedWorker(for: schedule.primaryBuildingId)
        )
    }
    
    private func generatePickupTask(from schedule: DSNYScheduleResult, for date: Date) -> ContextualTask {
        let taskId = "dsny_pickup_\(schedule.routeId)_\(date.timeIntervalSince1970)"
        let buildingName = getBuildingName(for: schedule.primaryBuildingId)
        
        return ContextualTask(
            id: taskId,
            name: "DSNY Bin Return (\(schedule.routeId))",
            buildingId: schedule.primaryBuildingId,
            buildingName: buildingName,
            category: "DSNY Operations",
            startTime: formatTime(from: schedule.pickupWindowEnd),
            endTime: formatTime(from: schedule.pickupWindowEnd + 900), // 15 minutes
            recurrence: "Weekly",
            skillLevel: "Basic",
            status: "pending",
            urgencyLevel: "medium",
            assignedWorkerName: getAssignedWorker(for: schedule.primaryBuildingId)
        )
    }
    
    private func generateComplianceTask(from schedule: DSNYScheduleResult, for date: Date) -> ContextualTask {
        let taskId = "dsny_compliance_\(schedule.routeId)_\(date.timeIntervalSince1970)"
        let buildingName = getBuildingName(for: schedule.primaryBuildingId)
        
        return ContextualTask(
            id: taskId,
            name: "DSNY Compliance Check (\(schedule.routeId))",
            buildingId: schedule.primaryBuildingId,
            buildingName: buildingName,
            category: "DSNY Operations",
            startTime: "19:00", // 7:00 PM
            endTime: "19:30", // 7:30 PM
            recurrence: "Weekly",
            skillLevel: "Intermediate",
            status: "pending",
            urgencyLevel: "medium",
            assignedWorkerName: getAssignedWorker(for: schedule.primaryBuildingId)
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
        
        // Use the async query method with proper try await
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
        // Map building IDs to names
        let buildingMap: [String: String] = [
            "1": "12 West 18th Street",
            "2": "29-31 East 20th Street",
            "3": "36 Walker Street",
            "4": "41 Elizabeth Street",
            "5": "68 Perry Street",
            "6": "104 Franklin Street",
            "7": "112 West 18th Street",
            "8": "117 West 17th Street",
            "9": "123 1st Avenue",
            "10": "131 Perry Street",
            "11": "133 East 15th Street",
            "12": "135 West 17th Street",
            "13": "136 West 17th Street",
            "14": "Rubin Museum (142-148 West 17th Street)",
            "15": "138 West 17th Street",
            "16": "Stuyvesant Cove Park"
        ]
        
        return buildingMap[buildingId] ?? "Unknown Building"
    }
    
    private func getAssignedWorker(for buildingId: String) -> String {
        // Assign workers based on building coverage patterns
        switch buildingId {
        case "1", "7": return "Greg Hutson"              // 12 West 18th, 112 West 18th
        case "2", "11": return "Edwin Lema"              // 29-31 East 20th, 133 East 15th
        case "5", "10": return "Kevin Dutan"             // 68 Perry, 131 Perry
        case "8", "12", "13": return "Mercedes Inamagua" // 117, 135, 136 West 17th
        case "3", "4": return "Luis Lopez"               // 36 Walker, 41 Elizabeth
        case "6", "9": return "Angel Guirachocha"        // 104 Franklin, 123 1st Ave
        case "14", "15": return "Shawn Magloire"         // 138 West 17th, Rubin Museum
        case "16": return "Edwin Lema"                   // Stuyvesant Cove Park
        default: return "Unassigned"
        }
    }
    
    private func isComplianceCheckNeeded(_ schedule: DSNYScheduleResult) -> Bool {
        // Generate compliance checks for high-traffic routes or problem areas
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
    
    /// Generate DSNY status summary for dashboard display
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
        guard let nextTask = pendingTasks.min(by: { $0.startTime ?? "" < $1.startTime ?? "" }) else {
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
