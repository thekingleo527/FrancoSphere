//
//  WorkerService.swift
//  FrancoSphere
//
//  🔧 FIXED VERSION - Type conflicts resolved
//  ✅ Removed duplicate type definitions
//  ✅ Uses existing FrancoSphere types
//  ✅ Kevin's Rubin Museum assignment correction maintained
//  ✅ All compilation errors fixed
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

actor WorkerService {
    static let shared = WorkerService()
    
    // MARK: - Dependencies
    private var workersCache: [String: Worker] = [:]
    private let sqliteManager = SQLiteManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties (MainActor)
    @MainActor
    @Published var isLoading = false
    @MainActor
    @Published var error: Error?
    @MainActor
    @Published var currentShift: WSWorkerShift?
    @MainActor
    @Published var assignedBuildings: [FrancoSphere.NamedCoordinate] = []
    @MainActor
    @Published var clockedInStatus: (isClockedIn: Bool, buildingId: Int64?) = (false, nil)
    
    // MARK: - Event Publishers
    let clockInStatusChanged = PassthroughSubject<(Bool, Int64?), Never>()
    let buildingsLoaded = PassthroughSubject<[FrancoSphere.NamedCoordinate], Never>()
    let shiftChanged = PassthroughSubject<WSWorkerShift?, Never>()
    let workerStatusChanged = PassthroughSubject<(String, WSWorkerStatus), Never>()
    
    // MARK: - Static Worker Data (Consolidated from WorkerConstants.swift)
    
    /// Worker IDs as Strings (matching application usage)
    static let workerIds = [
        "1": "Greg Hutson",
        "2": "Edwin Lema",
        "4": "Kevin Dutan",
        "5": "Mercedes Inamagua",
        "6": "Luis Lopez",
        "7": "Angel Guirachocha",
        "8": "Shawn Magloire"
    ]
    
    /// Worker Names
    static let workerNames: [String: String] = [
        "1": "Greg Hutson",
        "2": "Edwin Lema",
        "4": "Kevin Dutan",
        "5": "Mercedes Inamagua",
        "6": "Luis Lopez",
        "7": "Angel Guirachocha",
        "8": "Shawn Magloire"
    ]
    
    /// Worker Emails
    static let workerEmails: [String: String] = [
        "1": "g.hutson1989@gmail.com",
        "2": "edwinlema911@gmail.com",
        "4": "dutankevin1@gmail.com",
        "5": "jneola@gmail.com",
        "6": "luislopez030@yahoo.com",
        "7": "lio.angel71@gmail.com",
        "8": "shawn@francomanagementgroup.com"
    ]
    
    /// Worker Roles
    static let workerRoles: [String: String] = [
        "1": "Lead Technician",
        "2": "Maintenance Specialist",
        "4": "Building Supervisor",
        "5": "Cleaning Specialist",
        "6": "General Maintenance",
        "7": "Building Technician",
        "8": "Facilities Manager"
    ]
    
    /// Worker Skills
    static let workerSkills: [String: [String]] = [
        "1": ["cleaning", "sanitation", "operations", "maintenance"],
        "2": ["painting", "carpentry", "general_maintenance", "landscaping"],
        "4": ["plumbing", "electrical", "hvac", "general_maintenance", "garbage_collection"],
        "5": ["cleaning", "general_maintenance"],
        "6": ["maintenance", "repair", "painting"],
        "7": ["sanitation", "waste_management", "recycling", "evening_garbage"],
        "8": ["management", "inspection", "all_access"]
    ]
    
    /// Worker Schedules (CORRECTED WITH REAL DATA)
    static let workerSchedules: [String: [(start: Int, end: Int, days: [Int])]] = [
        "1": [(start: 9, end: 15, days: [1,2,3,4,5])],     // Greg: 9am-3pm Mon-Fri (reduced hours)
        "2": [(start: 6, end: 15, days: [1,2,3,4,5])],     // Edwin: 6am-3pm Mon-Fri (early morning)
        "4": [(start: 7, end: 15, days: [1,2,3,4,5])],     // Kevin: 7am-3pm Mon-Fri (expanded duties)
        "5": [
            (start: 6, end: 11, days: [1,2,3,4,5]),         // Mercedes: 6:30am-11am mornings
            (start: 13, end: 17, days: [1,2,3,4,5])         // Mercedes: afternoons (split shift)
        ],
        "6": [(start: 7, end: 16, days: [1,2,3,4,5])],     // Luis: 7am-4pm Mon-Fri
        "7": [(start: 18, end: 22, days: [1,2,3,4,5])],    // Angel: 6pm-10pm Mon-Fri (evening garbage)
        "8": [(start: 9, end: 17, days: [1,2,3,4,5])]      // Shawn: Flexible management hours
    ]
    
    /// Building Assignments (Kevin's Rubin Museum Corrected)
    static let workerBuildingAssignments: [String: [String]] = [
        "1": ["12", "15"],  // Greg - Limited buildings (reduced hours)
        "2": ["1", "2", "8", "11", "15", "16", "5"],  // Edwin - Technical specialist
        "4": ["3", "6", "7", "9", "10", "12", "14", "16"],  // Kevin - Expanded (including Rubin Museum)
        "5": ["3", "7"],  // Mercedes - Glass specialist
        "6": ["4", "8", "13"],  // Luis - Building operations
        "7": ["1", "3", "6", "8", "13"],  // Angel - Evening DSNY
        "8": []  // Shawn - Management oversight
    ]
    
    // MARK: - Worker Data Management
    
    func getWorker(_ id: String) async throws -> Worker? {
        // Check cache first
        if let cachedWorker = workersCache[id] {
            return cachedWorker
        }
        
        // Convert String ID to Int64 for database query
        guard let workerIdInt = Int64(id) else {
            print("⚠️ Invalid worker ID format: \(id)")
            return nil
        }
        
        do {
            let query = "SELECT * FROM workers WHERE id = ? AND isActive = 1"
            let rows = try await sqliteManager.query(query, [workerIdInt])
            
            guard let row = rows.first else {
                print("⚠️ Worker \(id) not found in database")
                return nil
            }
            
            let worker = Worker(
                id: row["id"] as? Int64 ?? workerIdInt,
                name: row["name"] as? String ?? Self.workerNames[id] ?? "",
                email: row["email"] as? String ?? Self.workerEmails[id] ?? "",
                password: row["passwordHash"] as? String ?? "",
                role: row["role"] as? String ?? Self.workerRoles[id] ?? "Worker",
                phone: row["phone"] as? String ?? "",
                hourlyRate: row["hourlyRate"] as? Double ?? 0.0,
                skills: Self.workerSkills[id] ?? [],
                isActive: row["isActive"] as? Bool ?? true,
                profileImagePath: row["profileImagePath"] as? String,
                address: row["address"] as? String ?? "",
                emergencyContact: row["emergencyContact"] as? String ?? "",
                notes: row["notes"] as? String ?? "",
                buildingIds: Self.workerBuildingAssignments[id] ?? []
            )
            
            // Cache for performance
            workersCache[id] = worker
            return worker
            
        } catch {
            print("❌ Database error fetching worker \(id): \(error)")
            throw error
        }
    }
    
    // MARK: - Building Assignments with Kevin Rubin Museum Correction
    
    func getAssignedBuildings(_ workerId: String) async throws -> [FrancoSphere.NamedCoordinate] {
        // ✅ CRITICAL: Kevin's corrected assignments (Rubin Museum, not 104 Franklin)
        if workerId == "4" {
            return getKevinBuildingAssignments()
        }
        
        // Try static assignments first (most reliable)
        if let staticAssignments = Self.workerBuildingAssignments[workerId] {
            let buildings = staticAssignments.compactMap { buildingId in
                FrancoSphere.NamedCoordinate.allBuildings.first { $0.id == buildingId }
            }
            
            if !buildings.isEmpty {
                print("✅ Using static assignments for worker \(workerId): \(buildings.count) buildings")
                return buildings
            }
        }
        
        // Fallback to database query
        guard let workerIdInt = Int64(workerId) else {
            print("⚠️ Invalid worker ID format: \(workerId)")
            return getHardcodedAssignments(for: workerId)
        }
        
        let query = """
            SELECT DISTINCT b.* FROM buildings b
            JOIN worker_assignments wa ON b.id = wa.building_id  
            WHERE wa.worker_id = ? AND wa.is_active = 1
            ORDER BY b.name
        """
        
        do {
            let rows = try await sqliteManager.query(query, [workerIdInt])
            
            return rows.compactMap { row in
                let buildingId: String
                if let idInt = row["id"] as? Int64 {
                    buildingId = String(idInt)
                } else if let idString = row["id"] as? String {
                    buildingId = idString
                } else {
                    return nil
                }
                
                guard let name = row["name"] as? String,
                      let lat = row["latitude"] as? Double,
                      let lng = row["longitude"] as? Double else {
                    return nil
                }
                
                return FrancoSphere.NamedCoordinate(
                    id: buildingId,
                    name: name,
                    latitude: lat,
                    longitude: lng,
                    imageAssetName: row["image_asset"] as? String ?? "building_\(buildingId)"
                )
            }
            
        } catch {
            print("❌ Error fetching buildings for worker \(workerId): \(error)")
            return getHardcodedAssignments(for: workerId)
        }
    }
    
    // MARK: - Kevin's Corrected Building Assignments (Rubin Museum Reality Fix)
    
    private func getKevinBuildingAssignments() -> [FrancoSphere.NamedCoordinate] {
        // Kevin's CONFIRMED assignments with Rubin Museum correction
        return [
            FrancoSphere.NamedCoordinate(id: "10", name: "131 Perry Street", latitude: 40.7359, longitude: -74.0059, imageAssetName: "perry_131"),
            FrancoSphere.NamedCoordinate(id: "6", name: "68 Perry Street", latitude: 40.7357, longitude: -74.0055, imageAssetName: "perry_68"),
            FrancoSphere.NamedCoordinate(id: "3", name: "135-139 West 17th Street", latitude: 40.7398, longitude: -73.9972, imageAssetName: "west17_135"),
            FrancoSphere.NamedCoordinate(id: "7", name: "136 West 17th Street", latitude: 40.7399, longitude: -73.9971, imageAssetName: "west17_136"),
            FrancoSphere.NamedCoordinate(id: "9", name: "138 West 17th Street", latitude: 40.7400, longitude: -73.9970, imageAssetName: "west17_138"),
            FrancoSphere.NamedCoordinate(id: "16", name: "29-31 East 20th Street", latitude: 40.7388, longitude: -73.9892, imageAssetName: "east20_29"),
            FrancoSphere.NamedCoordinate(id: "12", name: "178 Spring Street", latitude: 40.7245, longitude: -73.9968, imageAssetName: "spring_178"),
            // ✅ CORRECTED: Rubin Museum instead of 104 Franklin Street
            FrancoSphere.NamedCoordinate(id: "14", name: "Rubin Museum (142–148 W 17th)", latitude: 40.7402, longitude: -73.9980, imageAssetName: "rubin_museum")
        ]
    }
    
    // MARK: - Clock-In/Clock-Out System
    
    func handleClockIn(buildingId: String, workerId: String) async throws {
        guard let buildingIdInt64 = Int64(buildingId),
              let workerIdInt64 = Int64(workerId) else {
            throw WorkerServiceError.invalidAssignment
        }
        
        let worker = try await getWorker(workerId)
        let workerName = worker?.name ?? Self.workerNames[workerId] ?? "Unknown Worker"
        
        // Create shift record
        let shift = WSWorkerShift(
            id: UUID().uuidString,
            workerId: workerId,
            workerName: workerName,
            buildingId: buildingIdInt64,
            startTime: Date(),
            endTime: nil,
            status: .active
        )
        
        // Log clock-in to database
        try await sqliteManager.logClockInAsync(
            workerId: workerIdInt64,
            buildingId: buildingIdInt64,
            timestamp: Date()
        )
        
        // Update state
        await MainActor.run {
            self.currentShift = shift
            self.clockedInStatus = (true, buildingIdInt64)
        }
        
        // Emit events for UI updates
        clockInStatusChanged.send((true, buildingIdInt64))
        shiftChanged.send(shift)
        workerStatusChanged.send((workerId, .clockedIn))
        
        print("✅ Worker \(workerName) clocked in at building \(buildingId)")
    }
    
    func handleClockOut(workerId: String) async throws {
        guard let workerIdInt64 = Int64(workerId) else {
            throw WorkerServiceError.invalidAssignment
        }
        
        guard let shift = await getShift() else {
            throw WorkerServiceError.noActiveShift
        }
        
        // Update shift record
        var updatedShift = shift
        updatedShift.endTime = Date()
        updatedShift.status = .completed
        
        // Log clock-out to database
        try await sqliteManager.logClockOutAsync(
            workerId: workerIdInt64,
            timestamp: Date()
        )
        
        // Update state
        await MainActor.run {
            self.currentShift = nil
            self.clockedInStatus = (false, nil)
        }
        
        // Emit events for UI updates
        clockInStatusChanged.send((false, nil))
        shiftChanged.send(nil)
        workerStatusChanged.send((workerId, .clockedOut))
        
        print("✅ Worker \(shift.workerName) clocked out")
    }
    
    @MainActor
    private func getShift() -> WSWorkerShift? {
        return currentShift
    }
    
    // MARK: - Location-Based Features
    
    func isWithinBuildingRadius(_ building: FrancoSphere.NamedCoordinate, currentLocation: CLLocation?) -> Bool {
        guard let currentLocation = currentLocation else { return false }
        
        let buildingLocation = CLLocation(
            latitude: building.latitude,
            longitude: building.longitude
        )
        
        let distance = currentLocation.distance(from: buildingLocation)
        return distance <= 100.0 // 100 meter radius
    }
    
    func getNearbyBuildings(for workerId: String, currentLocation: CLLocation) async throws -> [FrancoSphere.NamedCoordinate] {
        let assignedBuildings = try await getAssignedBuildings(workerId)
        
        return assignedBuildings.filter { building in
            isWithinBuildingRadius(building, currentLocation: currentLocation)
        }.sorted { building1, building2 in
            let location1 = CLLocation(latitude: building1.latitude, longitude: building1.longitude)
            let location2 = CLLocation(latitude: building2.latitude, longitude: building2.longitude)
            
            let distance1 = currentLocation.distance(from: location1)
            let distance2 = currentLocation.distance(from: location2)
            
            return distance1 < distance2
        }
    }
    
    // MARK: - Enhanced Building Loading
    
    func loadWorkerBuildings(_ workerId: String) async throws -> [FrancoSphere.NamedCoordinate] {
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let buildings = try await getAssignedBuildings(workerId)
            
            // Special handling for Edwin (worker_id 2) - reseed if empty
            if buildings.isEmpty && workerId == "2" {
                print("⚠️ Edwin (worker_id: 2) has 0 buildings - triggering reseed...")
                try await reseedEdwinBuildings()
                
                // Retry after reseed
                let reseededBuildings = try await getAssignedBuildings(workerId)
                
                await MainActor.run {
                    self.assignedBuildings = reseededBuildings
                    self.isLoading = false
                }
                
                buildingsLoaded.send(reseededBuildings)
                print("✅ Edwin reseed complete: \(reseededBuildings.count) buildings loaded")
                return reseededBuildings
            }
            
            await MainActor.run {
                self.assignedBuildings = buildings
                self.isLoading = false
            }
            
            buildingsLoaded.send(buildings)
            print("✅ Buildings loaded for worker \(workerId): \(buildings.count)")
            return buildings
            
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
            
            print("❌ Failed to load buildings for worker \(workerId): \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Edwin Building Reseed Implementation
    
    private func reseedEdwinBuildings() async throws {
        print("🌱 Reseeding Edwin's building assignments...")
        
        // Clear existing assignments for Edwin
        let deleteSQL = "DELETE FROM worker_assignments WHERE worker_id = 2;"
        try await sqliteManager.execute(deleteSQL, [])
        
        // Insert 8 building assignments for Edwin
        let insertSQL = """
            INSERT INTO worker_assignments (worker_id, building_id, is_active) VALUES 
            (2, 1, 1), (2, 2, 1), (2, 8, 1), (2, 11, 1), (2, 15, 1), (2, 16, 1), (2, 5, 1);
        """
        
        try await sqliteManager.execute(insertSQL, [])
        print("✅ Edwin assignments reseeded: 7 buildings")
    }
    
    // MARK: - Worker Schedule Management
    
    func getWorkerSchedule(_ workerId: String, date: Date) async throws -> [ContextualTask] {
        // Priority 1: Real operational data (source of truth)
        let operationalManager = OperationalDataManager.shared
        let operationalTasks = await operationalManager.getTasksForWorker(workerId, date: date)
        
        if !operationalTasks.isEmpty {
            print("✅ Using operational schedule for worker \(workerId): \(operationalTasks.count) tasks")
            return operationalTasks
        }
        
        // Priority 2: Database fallback
        print("⚠️ No operational data for worker \(workerId), falling back to database")
        return try await getDatabaseSchedule(workerId, date: date)
    }
    
    private func getDatabaseSchedule(_ workerId: String, date: Date) async throws -> [ContextualTask] {
        guard let workerIdInt = Int64(workerId) else {
            print("⚠️ Invalid worker ID format: \(workerId)")
            return []
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        let query = """
            SELECT t.*, b.name as building_name FROM AllTasks t
            LEFT JOIN buildings b ON t.building_id = b.id
            WHERE t.assigned_worker_id = ? 
            AND (t.scheduled_date = ? OR t.recurrence != 'one-off')
            ORDER BY t.start_time
        """
        
        let rows = try await sqliteManager.query(query, [workerIdInt, dateString])
        
        return rows.compactMap { row in
            ContextualTask(
                id: row["id"] as? String ?? UUID().uuidString,
                name: row["name"] as? String ?? "",
                buildingId: row["building_id"] as? String ?? "",
                buildingName: row["building_name"] as? String ?? "",
                category: row["category"] as? String ?? "",
                startTime: row["start_time"] as? String ?? "",
                endTime: row["end_time"] as? String ?? "",
                recurrence: row["recurrence"] as? String ?? "one-off",
                skillLevel: row["skill_level"] as? String ?? "Basic",
                status: row["status"] as? String ?? "pending",
                urgencyLevel: row["urgency"] as? String ?? "Medium",
                assignedWorkerName: row["assigned_worker_name"] as? String ?? ""
            )
        }
    }
    
    // MARK: - Worker Availability and Status
    
    func isWorkerAvailable(_ workerId: String, at time: Date) async throws -> Bool {
        let schedule = try await getWorkerSchedule(workerId, date: time)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: time)
        
        for task in schedule {
            if let startTime = task.startTime, let endTime = task.endTime {
                if timeString >= startTime && timeString <= endTime {
                    return false
                }
            }
        }
        
        return true
    }
    
    func isWorkerClockedIn(_ workerId: String) async -> Bool {
        let status = await getClockStatus()
        return status.isClockedIn
    }
    
    @MainActor
    private func getClockStatus() -> (isClockedIn: Bool, buildingId: Int64?) {
        return clockedInStatus
    }
    
    // MARK: - Worker Statistics and Analytics
    
    func getWorkerStatistics(_ workerId: String) async throws -> WSWorkerStatistics {
        guard let workerIdInt = Int64(workerId) else {
            return WSWorkerStatistics(
                totalTasks: 0,
                completedTasks: 0,
                uniqueBuildings: 0,
                completionRate: 0.0,
                averageTasksPerDay: 0.0,
                hoursWorked: 0.0,
                onTimePercentage: 0.0
            )
        }
        
        let query = """
            SELECT 
                COUNT(*) as total_tasks,
                SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_tasks,
                COUNT(DISTINCT building_id) as unique_buildings,
                AVG(CASE WHEN status = 'completed' THEN 1.0 ELSE 0.0 END) as completion_rate
            FROM AllTasks 
            WHERE assigned_worker_id = ?
            AND scheduled_date >= date('now', '-30 days')
        """
        
        let rows = try await sqliteManager.query(query, [workerIdInt])
        
        guard let row = rows.first else {
            return WSWorkerStatistics(
                totalTasks: 0,
                completedTasks: 0,
                uniqueBuildings: 0,
                completionRate: 0.0,
                averageTasksPerDay: 0.0,
                hoursWorked: 0.0,
                onTimePercentage: 0.0
            )
        }
        
        let totalTasks = row["total_tasks"] as? Int64 ?? 0
        let completedTasks = row["completed_tasks"] as? Int64 ?? 0
        let uniqueBuildings = row["unique_buildings"] as? Int64 ?? 0
        let completionRate = row["completion_rate"] as? Double ?? 0.0
        
        // Calculate additional metrics
        let hoursWorked = await calculateHoursWorked(workerId)
        let onTimePercentage = await calculateOnTimePercentage(workerId)
        
        return WSWorkerStatistics(
            totalTasks: Int(totalTasks),
            completedTasks: Int(completedTasks),
            uniqueBuildings: Int(uniqueBuildings),
            completionRate: completionRate,
            averageTasksPerDay: Double(totalTasks) / 30.0,
            hoursWorked: hoursWorked,
            onTimePercentage: onTimePercentage
        )
    }
    
    private func calculateHoursWorked(_ workerId: String) async -> Double {
        // Get weekly hours from static data
        guard let schedules = Self.workerSchedules[workerId] else { return 0.0 }
        
        let totalHours = schedules.reduce(0) { total, schedule in
            let hoursPerDay = schedule.end - schedule.start
            return total + (hoursPerDay * schedule.days.count)
        }
        
        return Double(totalHours)
    }
    
    private func calculateOnTimePercentage(_ workerId: String) async -> Double {
        // Simplified calculation - would integrate with actual time tracking
        return 0.92 // 92% on-time rate
    }
    
    // MARK: - Worker Search and Filtering
    
    func searchWorkers(query: String) async throws -> [Worker] {
        let searchQuery = """
            SELECT * FROM workers 
            WHERE (name LIKE ? OR email LIKE ? OR role LIKE ?) 
            AND isActive = 1
            ORDER BY name
        """
        
        let searchPattern = "%\(query)%"
        let rows = try await sqliteManager.query(searchQuery, [searchPattern, searchPattern, searchPattern])
        
        return rows.compactMap { row in
            Worker(
                id: row["id"] as? Int64 ?? 0,
                name: row["name"] as? String ?? "",
                email: row["email"] as? String ?? "",
                password: row["passwordHash"] as? String ?? "",
                role: row["role"] as? String ?? "Worker",
                phone: row["phone"] as? String ?? "",
                hourlyRate: row["hourlyRate"] as? Double ?? 0.0,
                skills: (row["skills"] as? String ?? "").components(separatedBy: ",").filter { !$0.isEmpty },
                isActive: true,
                profileImagePath: row["profileImagePath"] as? String,
                address: row["address"] as? String ?? "",
                emergencyContact: row["emergencyContact"] as? String ?? "",
                notes: row["notes"] as? String ?? "",
                buildingIds: []
            )
        }
    }
    
    // MARK: - Static Helper Methods
    
    static func getWorkerName(id: String) -> String {
        return workerNames[id] ?? "Unknown Worker"
    }
    
    static func getWorkerEmail(id: String) -> String {
        return workerEmails[id] ?? ""
    }
    
    static func isWorkerAvailable(id: String, at hour: Int) -> Bool {
        guard let schedules = workerSchedules[id] else { return false }
        
        for schedule in schedules {
            if hour >= schedule.start && hour < schedule.end {
                return true
            }
        }
        return false
    }
    
    static func formatSchedule(for workerId: String) -> String {
        guard let schedules = workerSchedules[workerId] else { return "No schedule" }
        
        var scheduleStrings: [String] = []
        
        for schedule in schedules {
            let startHour = schedule.start
            let endHour = schedule.end
            
            let startTime: String
            let endTime: String
            
            if startHour == 6 && workerId == "5" {
                startTime = "6:30am"
            } else if startHour < 12 {
                startTime = "\(startHour)am"
            } else if startHour == 12 {
                startTime = "12pm"
            } else {
                startTime = "\(startHour - 12)pm"
            }
            
            if endHour < 12 {
                endTime = "\(endHour)am"
            } else if endHour == 12 {
                endTime = "12pm"
            } else {
                endTime = "\(endHour - 12)pm"
            }
            
            scheduleStrings.append("\(startTime)-\(endTime)")
        }
        
        return scheduleStrings.joined(separator: " & ")
    }
    
    static func getWorkerShiftType(id: String) -> String {
        switch id {
        case "1": return "Day Shift (Reduced Hours)"
        case "2": return "Early Morning Shift"
        case "4": return "Day Shift + Garbage"
        case "5": return "Split Shift"
        case "6": return "Day Shift"
        case "7": return "Evening Garbage"
        case "8": return "Management"
        default: return "Standard"
        }
    }
    
    static var activeWorkerIds: [String] {
        return ["1", "2", "4", "5", "6", "7", "8"]
    }
    
    // MARK: - Hardcoded Assignment Fallbacks (Real-World Data)
    
    private func getHardcodedAssignments(for workerId: String) -> [FrancoSphere.NamedCoordinate] {
        let allBuildings = FrancoSphere.NamedCoordinate.allBuildings
        let assignedBuildingIds = Self.workerBuildingAssignments[workerId] ?? []
        
        return allBuildings.filter { building in
            assignedBuildingIds.contains(building.id)
        }.sorted { $0.name < $1.name }
    }
    
    // MARK: - Emergency Kevin Data Fix
    
    func ensureKevinRubinMuseumAssignment() async throws {
        print("🔧 Ensuring Kevin has Rubin Museum assignment...")
        
        let kevinBuildings = try await getAssignedBuildings("4")
        let hasRubin = kevinBuildings.contains { $0.id == "14" }
        
        if !hasRubin {
            print("⚠️ Kevin missing Rubin Museum assignment, adding...")
            
            guard let kevinIdInt = Int64("4"), let rubinIdInt = Int64("14") else {
                throw WorkerServiceError.invalidAssignment
            }
            
            let insertQuery = """
                INSERT OR REPLACE INTO worker_assignments (worker_id, building_id, is_active)
                VALUES (?, ?, 1)
            """
            
            try await sqliteManager.execute(insertQuery, [kevinIdInt, rubinIdInt])
            print("✅ Added Kevin's Rubin Museum assignment")
        } else {
            print("✅ Kevin already has Rubin Museum assignment")
        }
    }
    
    // MARK: - Utility Methods
    
    func getTaskCountForBuilding(_ buildingId: String, workerId: String) async -> Int {
        do {
            let tasks = try await getWorkerSchedule(workerId, date: Date())
            return tasks.filter { $0.buildingId == buildingId }.count
        } catch {
            return 0
        }
    }
    
    func getWorkersForBuilding(buildingId: String) async throws -> [Worker] {
        guard let buildingIdInt = Int64(buildingId) else {
            return []
        }
        
        let query = """
            SELECT DISTINCT w.* FROM workers w
            JOIN worker_assignments wa ON w.id = wa.worker_id
            WHERE wa.building_id = ? AND wa.is_active = 1 AND w.isActive = 1
            ORDER BY w.name
        """
        
        let rows = try await sqliteManager.query(query, [buildingIdInt])
        
        return rows.compactMap { row in
            Worker(
                id: row["id"] as? Int64 ?? 0,
                name: row["name"] as? String ?? "",
                email: row["email"] as? String ?? "",
                password: row["passwordHash"] as? String ?? "",
                role: row["role"] as? String ?? "Worker",
                phone: row["phone"] as? String ?? "",
                hourlyRate: row["hourlyRate"] as? Double ?? 0.0,
                skills: (row["skills"] as? String ?? "").components(separatedBy: ",").filter { !$0.isEmpty },
                isActive: row["isActive"] as? Bool ?? true,
                profileImagePath: row["profileImagePath"] as? String,
                address: row["address"] as? String ?? "",
                emergencyContact: row["emergencyContact"] as? String ?? "",
                notes: row["notes"] as? String ?? "",
                buildingIds: []
            )
        }
    }
    
    // MARK: - Worker Profile Management
    
    func updateWorkerProfile(_ worker: Worker) async throws {
        let updateQuery = """
            UPDATE workers 
            SET name = ?, email = ?, role = ?, phone = ?, hourlyRate = ?, 
                skills = ?, profileImagePath = ?, address = ?, 
                emergencyContact = ?, notes = ?
            WHERE id = ?
        """
        
        let skillsString = worker.skills.joined(separator: ",")
        
        try await sqliteManager.execute(updateQuery, [
            worker.name,
            worker.email,
            worker.role,
            worker.phone,
            worker.hourlyRate,
            skillsString,
            worker.profileImagePath ?? "",
            worker.address,
            worker.emergencyContact,
            worker.notes,
            worker.id
        ])
        
        // Update cache
        workersCache[String(worker.id)] = worker
        print("✅ Updated worker profile for \(worker.name)")
    }
    
    func setWorkerActiveStatus(_ workerId: String, isActive: Bool) async throws {
        guard let workerIdInt = Int64(workerId) else {
            throw WorkerServiceError.invalidAssignment
        }
        
        let updateQuery = "UPDATE workers SET isActive = ? WHERE id = ?"
        
        try await sqliteManager.execute(updateQuery, [isActive, workerIdInt])
        
        workersCache.removeValue(forKey: workerId)
        print("✅ Worker \(workerId) active status set to \(isActive)")
    }
}

// MARK: - Supporting Types (Prefixed to avoid conflicts)

enum WSWorkerStatus {
    case clockedIn
    case clockedOut
    case onBreak
    case offShift
}

struct WSWorkerShift {
    let id: String
    let workerId: String
    let workerName: String
    let buildingId: Int64
    let startTime: Date
    var endTime: Date?
    var status: WSShiftStatus
    
    enum WSShiftStatus {
        case active
        case completed
        case cancelled
    }
}

struct WSWorkerStatistics {
    let totalTasks: Int
    let completedTasks: Int
    let uniqueBuildings: Int
    let completionRate: Double
    let averageTasksPerDay: Double
    let hoursWorked: Double
    let onTimePercentage: Double
}

// MARK: - Error Types

enum WorkerServiceError: LocalizedError {
    case workerNotFound(String)
    case invalidAssignment
    case noActiveShift
    case databaseError(String)
    case updateFailed(String)
    case locationRequired
    case buildingNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .workerNotFound(let id):
            return "Worker with ID \(id) not found"
        case .invalidAssignment:
            return "Invalid worker assignment"
        case .noActiveShift:
            return "No active shift found"
        case .databaseError(let message):
            return "Database error: \(message)"
        case .updateFailed(let message):
            return "Update failed: \(message)"
        case .locationRequired:
            return "Location access required for this operation"
        case .buildingNotFound(let id):
            return "Building with ID \(id) not found"
        }
    }
}
