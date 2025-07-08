//
//  DSNYTaskGenerator.swift
//  FrancoSphere
//
//  ✅ V6.0 REFACTOR: Updated for new ContextualTask structure and actor architecture
//  ✅ Uses correct ContextualTask initializer with title, buildingName, etc.
//  ✅ Integrates with CoreTypes and follows established patterns
//  ✅ Maintains DSNY compliance and real NYC sanitation schedules
//

import Foundation
import SQLite

/// Actor for generating DSNY-compliant sanitation tasks with thread safety
public actor DSNYTaskGenerator {
    
    // MARK: - Singleton
    public static let shared = DSNYTaskGenerator()
    
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
    public func generateTodaysDSNYTasks() async throws -> [ContextualTask] {
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
    public func generateDSNYTasksForBuilding(_ buildingId: CoreTypes.BuildingID) async throws -> [ContextualTask] {
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
    public func isDSNYCollectionScheduled(for buildingId: CoreTypes.BuildingID, on date: Date) async throws -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        let dayStr = getDayAbbreviation(for: weekday)
        
        let schedules = try await fetchDSNYSchedules(for: dayStr, buildingId: buildingId)
        return !schedules.isEmpty
    }
    
    /// Get DSNY collection schedule for a building
    public func getDSNYSchedule(for buildingId: CoreTypes.BuildingID) async throws -> [DSNYCollectionInfo] {
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
    
    // MARK: - Private Task Generation Methods (Using V6.0 ContextualTask Structure)
    
    private func generateSetoutTask(from schedule: DSNYScheduleResult, for date: Date) -> ContextualTask {
        let buildingName = getBuildingName(for: schedule.primaryBuildingId)
        let assignedWorker = getAssignedWorker(for: schedule.primaryBuildingId)
        
        // Calculate setout time (after 8 PM)
        let setoutTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: date) ?? date
        
        return ContextualTask(
            title: "DSNY Set-out",
            description: "Set out trash and recycling containers for DSNY collection according to route \(schedule.routeId)",
            category: .sanitation,
            urgency: .high,
            buildingId: schedule.primaryBuildingId,
            buildingName: buildingName,
            assignedWorkerId: assignedWorker?.id,
            assignedWorkerName: assignedWorker?.name,
            isCompleted: false,
            completedDate: nil,
            dueDate: setoutTime,
            estimatedDuration: 1800, // 30 minutes
            recurrence: getRecurrenceFromSchedule(schedule.collectionDays),
            notes: "DSNY collection route \(schedule.routeId). Must be set out after 8:00 PM."
        )
    }
    
    private func generatePickupTask(from schedule: DSNYScheduleResult, for date: Date) -> ContextualTask {
        let buildingName = getBuildingName(for: schedule.primaryBuildingId)
        let assignedWorker = getAssignedWorker(for: schedule.primaryBuildingId)
        
        // Calculate pickup time (after collection window)
        let pickupTime = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: date) ?? date
        
        return ContextualTask(
            title: "DSNY Container Return",
            description: "Return empty trash and recycling containers after DSNY collection",
            category: .sanitation,
            urgency: .medium,
            buildingId: schedule.primaryBuildingId,
            buildingName: buildingName,
            assignedWorkerId: assignedWorker?.id,
            assignedWorkerName: assignedWorker?.name,
            isCompleted: false,
            completedDate: nil,
            dueDate: pickupTime,
            estimatedDuration: 900, // 15 minutes
            recurrence: getRecurrenceFromSchedule(schedule.collectionDays),
            notes: "Return containers after DSNY collection. Route \(schedule.routeId)."
        )
    }
    
    private func generateComplianceTask(from schedule: DSNYScheduleResult, for date: Date) -> ContextualTask {
        let buildingName = getBuildingName(for: schedule.primaryBuildingId)
        let assignedWorker = getAssignedWorker(for: schedule.primaryBuildingId)
        
        // Compliance check should happen in the morning
        let complianceTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
        
        return ContextualTask(
            title: "DSNY Compliance Check",
            description: "Ensure DSNY collection compliance and proper container placement according to NYC regulations",
            category: .inspection,
            urgency: .medium,
            buildingId: schedule.primaryBuildingId,
            buildingName: buildingName,
            assignedWorkerId: assignedWorker?.id,
            assignedWorkerName: assignedWorker?.name,
            isCompleted: false,
            completedDate: nil,
            dueDate: complianceTime,
            estimatedDuration: 1200, // 20 minutes
            recurrence: .weekly,
            notes: "Weekly compliance check for route \(schedule.routeId). Verify proper placement and timing."
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
        // Real building mappings from our V6.0 system
        let buildingMap: [String: String] = [
            "1": "12 West 18th Street",
            "2": "29-31 East 20th Street",
            "3": "36 Walker Street",
            "4": "104 Franklin Street",
            "5": "138 West 17th Street",
            "6": "68 Perry Street",
            "7": "136 West 17th Street",
            "8": "41 Elizabeth Street",
            "9": "117 West 17th Street",
            "10": "131 Perry Street",
            "11": "123 1st Avenue",
            "13": "104 Franklin Street",
            "14": "Rubin Museum (142–148 W 17th)",
            "15": "133 East 15th Street",
            "16": "Stuyvesant Cove Park",
            "17": "178 Spring Street",
            "18": "36 Walker Street",
            "19": "115 7th Avenue",
            "20": "FrancoSphere HQ"
        ]
        
        return buildingMap[buildingId] ?? "Building \(buildingId)"
    }
    
    private func getAssignedWorker(for buildingId: String) -> (id: CoreTypes.WorkerID, name: String)? {
        // Real worker assignments from our V6.0 system
        switch buildingId {
        case "1", "7": // Greg Hutson's buildings
            return (id: "1", name: "Greg Hutson")
        case "2", "8", "11", "15", "18": // Edwin Lema's buildings
            return (id: "2", name: "Edwin Lema")
        case "3", "4", "5", "6", "9", "10", "13", "14", "16", "17": // Kevin Dutan's expanded assignments
            return (id: "4", name: "Kevin Dutan")
        case "19": // Mercedes territory
            return (id: "5", name: "Mercedes Inamagua")
        case "20": // Luis territory
            return (id: "6", name: "Luis Lopez")
        default:
            return nil // Will be assigned by system
        }
    }
    
    private func isComplianceCheckNeeded(_ schedule: DSNYScheduleResult) -> Bool {
        // High-traffic routes require additional compliance monitoring
        let highTrafficRoutes = ["R1-MON-WED-FRI", "R2-TUE-THU", "R3-MON-WED-FRI"]
        return highTrafficRoutes.contains(schedule.routeId)
    }
    
    private func getRecurrenceFromSchedule(_ collectionDays: String) -> TaskRecurrence {
        let days = collectionDays.components(separatedBy: ",")
        
        if days.count >= 5 {
            return .daily
        } else if days.count >= 2 {
            return .weekly
        } else {
            return .weekly // Default for single-day collections
        }
    }
}

// MARK: - Supporting Models

public struct DSNYScheduleResult {
    let routeId: String
    let primaryBuildingId: String
    let collectionDays: String
    let earliestSetout: Int
    let latestPickup: Int
    let pickupWindowStart: Int
    let pickupWindowEnd: Int
}

public struct DSNYCollectionInfo {
    let routeId: String
    let collectionDays: [String]
    let setoutTime: String
    let pickupTime: String
    let buildingId: String
}

// MARK: - Error Types

public enum DSNYError: Error, LocalizedError {
    case databaseUnavailable
    case invalidSchedule
    case noCollectionScheduled
    
    public var errorDescription: String? {
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
    /// Get comprehensive DSNY status summary for dashboard display
    public func getDSNYStatusSummary() async throws -> DSNYStatusSummary {
        let todaysTasks = try await generateTodaysDSNYTasks()
        
        let setoutTasks = todaysTasks.filter { $0.title.contains("Set-out") }
        let pickupTasks = todaysTasks.filter { $0.title.contains("Return") }
        let completedTasks = todaysTasks.filter { $0.isCompleted }
        
        return DSNYStatusSummary(
            totalCollections: setoutTasks.count,
            completedCollections: completedTasks.count,
            pendingSetouts: setoutTasks.filter { !$0.isCompleted }.count,
            pendingReturns: pickupTasks.filter { !$0.isCompleted }.count,
            nextCollection: getNextCollectionTime(from: todaysTasks)
        )
    }
    
    private func getNextCollectionTime(from tasks: [ContextualTask]) -> String {
        let pendingTasks = tasks.filter { !$0.isCompleted }
        
        // Find next task by due date
        guard let nextTask = pendingTasks.min(by: {
            ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture)
        }) else {
            return "No upcoming collections"
        }
        
        if let dueDate = nextTask.dueDate {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: dueDate)
        }
        
        return "Time TBD"
    }
    
    /// Integration with TaskService for automatic DSNY task creation
    public func createDSNYTasksInSystem(taskService: TaskService) async throws {
        let dsnyTasks = try await generateTodaysDSNYTasks()
        
        for task in dsnyTasks {
            do {
                try await taskService.createTask(task)
                print("✅ Created DSNY task: \(task.title) for \(task.buildingName)")
            } catch {
                print("❌ Failed to create DSNY task: \(error)")
            }
        }
    }
}

public struct DSNYStatusSummary {
    public let totalCollections: Int
    public let completedCollections: Int
    public let pendingSetouts: Int
    public let pendingReturns: Int
    public let nextCollection: String
    
    public init(totalCollections: Int, completedCollections: Int, pendingSetouts: Int, pendingReturns: Int, nextCollection: String) {
        self.totalCollections = totalCollections
        self.completedCollections = completedCollections
        self.pendingSetouts = pendingSetouts
        self.pendingReturns = pendingReturns
        self.nextCollection = nextCollection
    }
}
