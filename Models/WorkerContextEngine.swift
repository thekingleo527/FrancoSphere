//
//  WorkerContextEngine.swift
//  FrancoSphere
//
//  🔧 ACCESS CONTROL COMPLETELY FIXED:
//  ✅ NO public exposure of internal types (ContextualTask, etc.)
//  ✅ ALL public APIs use only basic types or verified public types
//  ✅ Internal properties kept internal with safe public accessors
//  ✅ HF-24: ROUTINE CONTEXT ENGINE fully implemented
//  ✅ Weather postponement system and all Phase-2 features preserved
//  🔧 HF-33: Today's workers helper methods and DetailedWorker struct - FIXED
//  ✅ CRITICAL FIX: All property access issues resolved (assignedWorkerName vs assignedWorker)
//

import Foundation
import Combine
import CoreLocation

// MARK: - Internal Supporting Types (NOT exposed publicly)

internal struct InternalWorkerContext {
    let workerId: String
    let workerName: String
    let email: String
    let role: String
    let primaryBuildingId: String?
}

internal enum DatabaseError: Error, LocalizedError {
    case notInitialized
    case invalidData(String)
    case queryFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Database not initialized"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .queryFailed(let message):
            return "Query failed: \(message)"
        }
    }
}

// MARK: - HF-33: DetailedWorker struct
public struct DetailedWorker: Identifiable {
    public let id: String
    public let name: String
    public let role: String
    public let shift: String
    public let buildingId: String
    public let isOnSite: Bool
    
    public init(id: String, name: String, role: String, shift: String, buildingId: String, isOnSite: Bool) {
        self.id = id
        self.name = name
        self.role = role
        self.shift = shift
        self.buildingId = buildingId
        self.isOnSite = isOnSite
    }
}

@MainActor
public class WorkerContextEngine: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = WorkerContextEngine()
    
    // MARK: - Published Properties (Only basic types and verified public types)
    @Published public var isLoading = false
    @Published public var error: Error?

    // ──────────────────────────────────────────────────────────────────────────────
    //  🔧 HF-24: ROUTINE CONTEXT ENGINE (REAL-WORLD OPERATIONAL AWARENESS)
    //  🔧 ADD-ON ②: Weather postponement system
    //  🔧 FIX #3: Cold start weather handling
    //  ✅ INTERNAL PROPERTIES - accessed via public methods only
    // ──────────────────────────────────────────────────────────────────────────────

    @Published internal var dailyRoutines: [ContextualTask] = []
    @Published internal var dsnySchedule: [(day: String, time: String, status: String)] = []
    @Published internal var routineOverrides: [String: String] = [:] // routineId -> override reason

    // MARK: - Internal Properties (accessed via public methods only)
    @Published internal var currentWorker: InternalWorkerContext?
    @Published internal var assignedBuildings: [FrancoSphere.NamedCoordinate] = []
    @Published internal var todaysTasks: [ContextualTask] = []
    @Published internal var upcomingTasks: [ContextualTask] = []
    
    // 🔧 FIX #3: Weather listener for cold start handling
    private var weatherCancellable: AnyCancellable?

    // MARK: - Private Properties
    private var sqliteManager: SQLiteManager?
    private var cancellables = Set<AnyCancellable>()
    private var migrationRun = false
    
    // BEGIN PATCH(HF-07): Enhanced WorkerAssignmentManager integration
    private var assignmentManager: WorkerAssignmentManager {
        return WorkerAssignmentManager.shared
    }
    // END PATCH(HF-07)
    
    // MARK: - ⭐ PHASE-2: Auth manager reference
    private var authManager: NewAuthManager {
        return NewAuthManager.shared
    }
    
    private init() {
        setupSQLiteManager()
        
        // 🔧 FIX #3: Listen for weather updates to re-evaluate postponements
        weatherCancellable = WeatherManager.shared.$currentWeather
            .compactMap { $0 }
            .removeDuplicates { $0.condition == $1.condition && abs($0.temperature - $1.temperature) < 5 }
            .sink { [weak self] weather in
                Task { @MainActor in
                    await self?.reapplyWeatherOverrides()
                }
            }
    }
    
    // MARK: - Setup
    
    private func setupSQLiteManager() {
        sqliteManager = SQLiteManager.shared
    }
    
    // MARK: - ✅ INTERNAL ACCESS METHODS (For Extensions & Internal Use)

    /// Internal method to get merged tasks (for extensions only)
    internal func getMergedTasks() -> [ContextualTask] {
        return todaysTasks + dailyRoutines
    }

    /// Internal method to get tasks for building (for extensions only)
    internal func getTasksForBuilding(_ buildingId: String) -> [ContextualTask] {
        return todaysTasks.filter { $0.buildingId == buildingId }
    }

    /// Internal method to get routines for building (for extensions only)
    internal func getRoutinesForBuilding(_ buildingId: String) -> [ContextualTask] {
        return dailyRoutines.filter { $0.buildingId == buildingId }
    }

    /// Internal method to get assigned buildings (for extensions only)
    internal func getAssignedBuildings() -> [FrancoSphere.NamedCoordinate] {
        return assignedBuildings
    }

    /// Internal method to get today's tasks (for extensions only)
    internal func getTodaysTasks() -> [ContextualTask] {
        return todaysTasks
    }

    /// Internal method to get upcoming tasks (for extensions only)
    internal func getUpcomingTasks() -> [ContextualTask] {
        return upcomingTasks
    }
    
    // MARK: - ⭐ HF-33: BUILDING ROUTINE COUNT METHODS (CRITICAL FIXES APPLIED)
    
    /// Get daily routine count for building (for HF-30 tappable routines)
    public func getDailyRoutineCount(for buildingId: String) -> Int {
        return todaysTasks.filter { task in
            task.buildingId == buildingId &&
            task.recurrence.lowercased().contains("daily")
        }.count
    }
    
    /// Get weekly routine count for building (for HF-30 tappable routines)
    public func getWeeklyRoutineCount(for buildingId: String) -> Int {
        return todaysTasks.filter { task in
            task.buildingId == buildingId &&
            task.recurrence.lowercased().contains("weekly")
        }.count
    }
    
    /// Get workers currently assigned to a building today (HF-31 & HF-32)
    /// ✅ CRITICAL FIX: Use assignedWorkerName property correctly
    public func todayWorkers(for buildingId: String, includeDSNY: Bool = false) -> [String] {
        // Get all tasks for this building today
        let buildingTasks = todaysTasks.filter { $0.buildingId == buildingId }
        
        // Extract unique worker names from tasks
        var workerNames = Set<String>()
        
        for task in buildingTasks {
            // ✅ CRITICAL FIX: Use assignedWorkerName instead of assignedWorker
            if let assignedWorker = task.assignedWorkerName, !assignedWorker.isEmpty {
                workerNames.insert(assignedWorker)
            }
        }
        
        // Add DSNY workers if requested
        if includeDSNY {
            let dsnyWorkers = getDSNYWorkersForBuilding(buildingId)
            workerNames.formUnion(dsnyWorkers)
        }
        
        return Array(workerNames).sorted()
    }
    
    /// Get current shift workers for a building
    public func getCurrentShiftWorkers(for buildingId: String) -> [String] {
        let allWorkers = todayWorkers(for: buildingId, includeDSNY: true)
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        return allWorkers.filter { workerName in
            isWorkerCurrentlyOnShift(workerName, currentHour: currentHour)
        }
    }
    
    /// Get routine breakdown for building detail view
    public func getRoutineBreakdown(for buildingId: String) -> (daily: Int, weekly: Int, monthly: Int) {
        let buildingTasks = todaysTasks.filter { $0.buildingId == buildingId }
        
        let daily = buildingTasks.filter { $0.recurrence.lowercased().contains("daily") }.count
        let weekly = buildingTasks.filter { $0.recurrence.lowercased().contains("weekly") }.count
        let monthly = buildingTasks.filter { $0.recurrence.lowercased().contains("monthly") }.count
        
        return (daily: daily, weekly: weekly, monthly: monthly)
    }
    
    /// Check if a building has specific routine types
    public func hasRoutineType(_ routineType: String, for buildingId: String) -> Bool {
        return todaysTasks.contains { task in
            task.buildingId == buildingId &&
            task.recurrence.lowercased().contains(routineType.lowercased())
        }
    }
    
    // MARK: - ⭐ HF-33: PRIVATE HELPER METHODS (CRITICAL FIXES APPLIED)
    
    private func isWorkerCurrentlyOnShift(_ workerName: String, currentHour: Int) -> Bool {
        // Map worker names to their typical shifts
        switch workerName.lowercased() {
        case let n where n.contains("mercedes"):
            return currentHour >= 6 && currentHour <= 11  // Mercedes: 6 AM - 11 AM
        case let n where n.contains("angel"):
            return currentHour >= 18 && currentHour <= 22  // Angel: 6 PM - 10 PM
        case let n where n.contains("edwin"):
            return currentHour >= 7 && currentHour <= 15  // Edwin: 7 AM - 3 PM
        case let n where n.contains("kevin"):
            return currentHour >= 9 && currentHour <= 17  // Kevin: 9 AM - 5 PM
        default:
            return currentHour >= 9 && currentHour <= 17  // Default shift
        }
    }
    
    /// ✅ CRITICAL FIX: Use assignedWorkerName property correctly
    private func getDSNYWorkersForBuilding(_ buildingId: String) -> Set<String> {
        // Get DSNY tasks for this building
        let dsnyTasks = todaysTasks.filter { task in
            task.buildingId == buildingId &&
            (task.name.lowercased().contains("trash") ||
             task.name.lowercased().contains("recycle") ||
             task.name.lowercased().contains("dsny"))
        }
        
        var dsnyWorkers = Set<String>()
        for task in dsnyTasks {
            // ✅ CRITICAL FIX: Use assignedWorkerName instead of assignedWorker
            if let worker = task.assignedWorkerName, !worker.isEmpty {
                dsnyWorkers.insert(worker)
            }
        }
        
        return dsnyWorkers
    }
    
    // MARK: - HF-33: Today's Workers Helper Methods
    
    /// Get list of worker names scheduled for a specific building today
    public func todayWorkersV2(for buildingId: String, includeDSNY: Bool = false) -> [String] {
        let todayAbbr = DateFormatter().shortWeekdaySymbols[
            Calendar.current.component(.weekday, from: Date()) - 1]
        
        let merged = getMergedTasks()
            .filter { $0.buildingId == buildingId }
        
        var names: Set<String> = []
        merged.forEach { task in
            guard let workerName = task.assignedWorkerName, !workerName.isEmpty else { return }
            if task.category.lowercased().contains("dsny") && !includeDSNY { return }
            names.insert(workerName)
        }
        
        dailyRoutines.filter { $0.buildingId == buildingId }.forEach { routine in
            guard let workerName = routine.assignedWorkerName, !workerName.isEmpty else { return }
            if routine.category.lowercased().contains("dsny") && !includeDSNY { return }
            names.insert(workerName)
        }
        
        return names.sorted()
    }
    
    /// Get detailed worker information for a specific building
    public func getDetailedWorkers(for buildingId: String, includeDSNY: Bool = false) -> [DetailedWorker] {
        let workerNames = todayWorkers(for: buildingId, includeDSNY: includeDSNY)
        
        return workerNames.compactMap { name in
            DetailedWorker(
                id: generateWorkerId(from: name),
                name: name,
                role: inferWorkerRole(from: name),
                shift: inferWorkerShift(from: name),
                buildingId: buildingId,
                isOnSite: isWorkerOnSite(name)
            )
        }
    }
    
    /// Get worker names across all buildings for today
    public func getAllTodayWorkers(includeDSNY: Bool = false) -> [String] {
        let allBuildingIds = Set(getMergedTasks().map { $0.buildingId })
        
        var allWorkers: Set<String> = []
        for buildingId in allBuildingIds {
            let buildingWorkers = todayWorkers(for: buildingId, includeDSNY: includeDSNY)
            allWorkers.formUnion(buildingWorkers)
        }
        
        return allWorkers.sorted()
    }
    
    // MARK: - HF-33: Worker Helper Methods
    
    private func generateWorkerId(from name: String) -> String {
        // Generate consistent ID from worker name
        switch name.lowercased() {
        case let n where n.contains("greg"): return "1"
        case let n where n.contains("edwin"): return "2"
        case let n where n.contains("kevin"): return "4"
        case let n where n.contains("mercedes"): return "5"
        case let n where n.contains("luis"): return "6"
        case let n where n.contains("angel"): return "7"
        case let n where n.contains("shawn"): return "8"
        default: return String(abs(name.hashValue % 1000))
        }
    }
    
    private func inferWorkerRole(from name: String) -> String {
        switch name.lowercased() {
        case let n where n.contains("greg"): return "Maintenance"
        case let n where n.contains("edwin"): return "Cleaning"
        case let n where n.contains("kevin"): return "Cleaning"
        case let n where n.contains("mercedes"): return "Cleaning"
        case let n where n.contains("luis"): return "Maintenance"
        case let n where n.contains("angel"): return "DSNY"
        case let n where n.contains("shawn"): return "Management"
        default: return "General"
        }
    }
    
    private func inferWorkerShift(from name: String) -> String {
        switch name.lowercased() {
        case let n where n.contains("mercedes"): return "6:30 AM - 11:00 AM"
        case let n where n.contains("angel"): return "6:00 PM - 10:00 PM"
        case let n where n.contains("edwin"): return "7:00 AM - 3:00 PM"
        case let n where n.contains("greg"): return "9:00 AM - 3:00 PM"
        case let n where n.contains("shawn"): return "Flexible"
        default: return "9:00 AM - 5:00 PM"
        }
    }
    
    private func isWorkerOnSite(_ name: String) -> Bool {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())
        
        // Check if worker is likely on site based on their typical shift
        switch name.lowercased() {
        case let n where n.contains("mercedes"):
            return currentHour >= 6 && currentHour <= 11
        case let n where n.contains("angel"):
            return currentHour >= 18 && currentHour <= 22
        case let n where n.contains("edwin"):
            return currentHour >= 7 && currentHour <= 15
        case let n where n.contains("greg"):
            return currentHour >= 9 && currentHour <= 15
        default:
            return currentHour >= 9 && currentHour <= 17
        }
    }
    
    // MARK: - ⭐ PHASE-2: Enhanced Load Worker Context with Real-World Data Validation
    
    /// Load complete worker context with real-world data validation
    public func loadWorkerContext(workerId: String? = nil) async {
        let actualWorkerId = workerId ?? authManager.workerId
        
        guard !actualWorkerId.isEmpty else {
            print("❌ No worker ID provided and no authenticated user")
            await MainActor.run {
                self.error = WorkerContextError.noWorkerID
                self.isLoading = false
            }
            return
        }
        
        // Validate worker exists in real data
        guard await validateWorkerExists(actualWorkerId) else {
            print("❌ Worker ID \(actualWorkerId) not found in real-world data")
            await MainActor.run {
                self.error = WorkerContextError.workerNotFound(actualWorkerId)
                self.isLoading = false
            }
            return
        }
        
        print("🔄 Loading REAL worker context for ID: \(actualWorkerId)")
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            try await ensureMigrationRun()
            
            let worker = try await loadWorkerContext_Internal(actualWorkerId)
            
            // BEGIN PATCH(HF-07): Enhanced building loading with AssignmentManager coordination
            let buildings = try await loadWorkerBuildings_Enhanced(actualWorkerId)
            // END PATCH(HF-07)
            
            let todayTasks = try await loadWorkerTasksForToday_Internal(actualWorkerId)
            let upcomingTasks = try await loadUpcomingTasks_Internal(actualWorkerId)
            
            await MainActor.run {
                self.currentWorker = worker
                self.assignedBuildings = buildings
                self.todaysTasks = todayTasks
                self.upcomingTasks = upcomingTasks
                self.isLoading = false
            }
            
            print("✅ REAL worker context loaded for: \(worker.workerName)")
            print("📋 Buildings: \(buildings.count), Today's tasks: \(todayTasks.count), Upcoming: \(upcomingTasks.count)")
            
            // Log worker-specific metrics for validation
            await logWorkerMetrics(worker, buildings.count, todayTasks.count)
            
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
            
            print("❌ Failed to load worker context: \(error)")
        }
    }
    
    /// Load worker's operational routines for specified building (or all buildings)
    public func loadRoutinesForWorker(_ workerId: String, buildingId: String? = nil) async {
        guard let manager = sqliteManager else {
            print("❌ HF-24: No SQLite manager available")
            return
        }
        
        do {
            print("🔄 HF-24: Loading routines for worker \(workerId), building: \(buildingId ?? "all")")
            
            // Build query with optional building filter
            let buildingFilter = buildingId != nil ? "AND rs.building_id = ?" : ""
            let params = buildingId != nil ? [workerId, buildingId!] : [workerId]
            
            let routineResults = try await manager.query("""
                SELECT rs.*, b.name as building_name 
                FROM routine_schedules rs
                LEFT JOIN buildings b ON rs.building_id = b.id
                WHERE rs.worker_id = ? \(buildingFilter)
                ORDER BY rs.category, rs.name
            """, params)
            
            // Convert routine schedules to contextual tasks
            var routineTasks: [ContextualTask] = []
            
            for row in routineResults {
                guard let id = row["id"] as? String,
                      let name = row["name"] as? String,
                      let buildingId = row["building_id"] as? String,
                      let rrule = row["rrule"] as? String,
                      let category = row["category"] as? String else {
                    continue
                }
                
                let buildingName = row["building_name"] as? String ?? "Building \(buildingId)"
                let weatherDependent = (row["weather_dependent"] as? Int64) == 1
                
                let task = ContextualTask(
                    id: id,
                    name: name,
                    buildingId: buildingId,
                    buildingName: buildingName,
                    category: category,
                    startTime: extractTimeFromRRule(rrule),
                    endTime: calculateEndTime(rrule, duration: row["estimated_duration"] as? Int64),
                    recurrence: extractFrequencyFromRRule(rrule),
                    skillLevel: determineSkillLevel(category),
                    status: routineOverrides[id] ?? "pending",
                    urgencyLevel: determinePriority(category, rrule),
                    assignedWorkerName: getWorkerName()
                )
                
                routineTasks.append(task)
            }
            
            // Load DSNY schedules for worker's buildings
            let dsnyResults = try await manager.query("""
                SELECT ds.* FROM dsny_schedules ds
                WHERE EXISTS (
                    SELECT 1 FROM worker_building_assignments wba 
                    WHERE wba.worker_id = ? 
                    AND (',' || ds.building_ids || ',') LIKE ('%,' || wba.building_id || ',%')
                    AND wba.is_active = 1
                )
            """, [workerId])
            
            let dsnyTasks = generateDSNYTasks(from: dsnyResults)
            let dsnyDisplay = generateDSNYScheduleDisplay(from: dsnyResults)
            
            // 🔧 ADD-ON ②: Apply weather-based postponements
            let weatherAdjustedRoutines = await applyWeatherOverrides(routineTasks)
            
            await MainActor.run {
                self.dailyRoutines = weatherAdjustedRoutines + dsnyTasks
                self.dsnySchedule = dsnyDisplay
            }
            
            print("✅ HF-24: Loaded \(routineTasks.count) routines + \(dsnyTasks.count) DSNY tasks")
            if !routineOverrides.isEmpty {
                print("   🌤️ Weather overrides: \(routineOverrides.count) routines affected")
            }
            
        } catch {
            print("❌ HF-24: Failed to load routines: \(error)")
        }
    }

    // MARK: - 🔧 ADD-ON ②: WEATHER POSTPONEMENT SYSTEM

    /// Automatically postpone outdoor cleaning tasks during adverse weather
    private func applyWeatherOverrides(_ routines: [ContextualTask]) async -> [ContextualTask] {
        guard let currentWeather = WeatherManager.shared.currentWeather else {
            print("🌤️ ADD-ON ②: No weather data available, proceeding with all routines")
            return routines
        }
        
        var modifiedRoutines = routines
        var overrides: [String: String] = [:]
        
        // Weather conditions that affect outdoor work
        let isRainyWeather = currentWeather.condition == .rain || currentWeather.condition == .thunderstorm
        let isExtremeTemp = currentWeather.temperature < 20 || currentWeather.temperature > 95
        let isFoggyWeather = currentWeather.condition == .fog
        
        var postponementReason: String? = nil
        if isRainyWeather {
            postponementReason = "Rain/Thunderstorms (\(currentWeather.condition.rawValue))"
        } else if isExtremeTemp {
            postponementReason = "Extreme Temperature (\(currentWeather.formattedTemperature))"
        } else if isFoggyWeather {
            postponementReason = "Low Visibility (Fog)"
        }
        
        if let reason = postponementReason {
            print("🌤️ ADD-ON ②: Weather postponements active - \(reason)")
            
            for (index, routine) in modifiedRoutines.enumerated() {
                // Check if this is an outdoor cleaning task that should be postponed
                if routine.category == "Cleaning" && isOutdoorTask(routine.name) {
                    modifiedRoutines[index] = ContextualTask(
                        id: routine.id,
                        name: routine.name,
                        buildingId: routine.buildingId,
                        buildingName: routine.buildingName,
                        category: routine.category,
                        startTime: routine.startTime,
                        endTime: routine.endTime,
                        recurrence: routine.recurrence,
                        skillLevel: routine.skillLevel,
                        status: "postponed",
                        urgencyLevel: "low", // Reduce urgency for postponed tasks
                        assignedWorkerName: routine.assignedWorkerName
                    )
                    
                    overrides[routine.id] = reason
                    print("   ⏸ Postponed: \(routine.name) at \(routine.buildingName)")
                }
            }
        }
        
        // Update overrides dictionary
        await MainActor.run {
            self.routineOverrides = overrides
        }
        
        let postponedCount = overrides.count
        if postponedCount > 0 {
            print("✅ ADD-ON ②: Applied \(postponedCount) weather-based postponements")
            
            // Trigger AI weather alert if multiple tasks affected
            if postponedCount >= 2 {
                AIAssistantManager.shared.addScenario(.weatherAlert,
                                                    buildingName: "Multiple sites",
                                                    taskCount: postponedCount)
            }
        }
        
        return modifiedRoutines
    }

    /// Re-apply weather overrides when conditions change
    private func reapplyWeatherOverrides() async {
        guard !dailyRoutines.isEmpty else { return }
        
        let currentRoutines = dailyRoutines
        let updatedRoutines = await applyWeatherOverrides(currentRoutines)
        
        await MainActor.run {
            self.dailyRoutines = updatedRoutines
        }
    }

    /// Determine if a task is outdoor-based and weather-sensitive
    private func isOutdoorTask(_ taskName: String) -> Bool {
        let outdoorKeywords = [
            "sidewalk", "curb", "exterior", "facade", "roof", "drain",
            "trash area", "walkway", "entrance", "front", "outdoor",
            "street", "sidewalk sweep", "hose", "power wash"
        ]
        
        let lowercaseName = taskName.lowercased()
        return outdoorKeywords.contains { lowercaseName.contains($0) }
    }

    // MARK: - Helper Methods

    private func extractTimeFromRRule(_ rrule: String) -> String? {
        if let range = rrule.range(of: "BYHOUR=") {
            let remaining = String(rrule[range.upperBound...])
            let hourComponent = remaining.components(separatedBy: ";").first ?? remaining
            
            if let hour = Int(hourComponent) {
                return String(format: "%02d:00", hour)
            }
        }
        return "09:00" // Default start time
    }

    private func calculateEndTime(_ rrule: String, duration: Int64?) -> String? {
        guard let startTime = extractTimeFromRRule(rrule),
              let hour = Int(startTime.prefix(2)) else { return nil }
        
        let durationHours = Int(duration ?? 3600) / 3600 // Convert seconds to hours
        let endHour = min(hour + durationHours, 23)
        
        return String(format: "%02d:00", endHour)
    }

    private func extractFrequencyFromRRule(_ rrule: String) -> String {
        if rrule.contains("FREQ=DAILY") { return "Daily" }
        if rrule.contains("FREQ=WEEKLY") { return "Weekly" }
        if rrule.contains("FREQ=MONTHLY") { return "Monthly" }
        return "Daily"
    }

    private func determineSkillLevel(_ category: String) -> String {
        switch category.lowercased() {
        case "maintenance": return "Advanced"
        case "operations": return "Intermediate"
        default: return "Basic"
        }
    }

    private func determinePriority(_ category: String, _ rrule: String) -> String {
        if category == "Operations" { return "high" }
        if rrule.contains("FREQ=DAILY") { return "medium" }
        return "low"
    }

    private func generateDSNYTasks(from results: [[String: Any]]) -> [ContextualTask] {
        var tasks: [ContextualTask] = []
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        
        for row in results {
            guard let routeId = row["route_id"] as? String,
                  let collectionDays = row["collection_days"] as? String,
                  let buildingIds = row["building_ids"] as? String else { continue }
            
            let days = collectionDays.components(separatedBy: ",")
            let todayStr = ["", "SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"][weekday]
            
            if days.contains(todayStr) {
                let primaryBuildingId = buildingIds.components(separatedBy: ",").first ?? ""
                let buildingName = getBuildingName(primaryBuildingId)
                
                // DSNY Set-out task (evening before)
                tasks.append(ContextualTask(
                    id: "dsny_setout_\(routeId)_\(today.timeIntervalSince1970)",
                    name: "DSNY Set-out (\(routeId))",
                    buildingId: primaryBuildingId,
                    buildingName: buildingName,
                    category: "Operations",
                    startTime: "20:00",
                    endTime: "20:30",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "high",
                    assignedWorkerName: getWorkerName()
                ))
                
                // DSNY Bin Return task (morning after pickup)
                tasks.append(ContextualTask(
                    id: "dsny_return_\(routeId)_\(today.timeIntervalSince1970)",
                    name: "DSNY Bin Return (\(routeId))",
                    buildingId: primaryBuildingId,
                    buildingName: buildingName,
                    category: "Operations",
                    startTime: "10:00",
                    endTime: "10:15",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: getWorkerName()
                ))
            }
        }
        
        return tasks
    }

    private func generateDSNYScheduleDisplay(from results: [[String: Any]]) -> [(day: String, time: String, status: String)] {
        var schedule: [(day: String, time: String, status: String)] = []
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let todayStr = ["", "SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"][weekday]
        
        for row in results {
            guard let routeId = row["route_id"] as? String,
                  let collectionDays = row["collection_days"] as? String else { continue }
            
            let days = collectionDays.components(separatedBy: ",")
            
            for day in days {
                let dayName = ["MON": "Monday", "TUE": "Tuesday", "WED": "Wednesday",
                              "THU": "Thursday", "FRI": "Friday", "SAT": "Saturday", "SUN": "Sunday"][day] ?? day
                
                let isToday = day == todayStr
                let status = isToday ? "📍 Today" : "📅 Scheduled"
                
                schedule.append((
                    day: dayName,
                    time: "Set-out: 8:00 PM → Pickup: 6:00-12:00 PM",
                    status: status
                ))
            }
        }
        
        return schedule.sorted {
            let dayOrder = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
            let index1 = dayOrder.firstIndex(of: $0.day) ?? 999
            let index2 = dayOrder.firstIndex(of: $1.day) ?? 999
            return index1 < index2
        }
    }

    private func getBuildingName(_ buildingId: String) -> String {
        return assignedBuildings.first { $0.id == buildingId }?.name ?? "Building \(buildingId)"
    }
    
    /// Validate worker exists in real-world data
    private func validateWorkerExists(_ workerId: String) async -> Bool {
        guard let manager = sqliteManager else { return false }
        
        do {
            let results = try await manager.query("SELECT id FROM workers WHERE id = ? LIMIT 1", [workerId])
            let exists = !results.isEmpty
            
            // Additional check: ensure worker is not Jose Santos (ID 3)
            if workerId == "3" {
                print("🚫 Worker ID 3 (Jose Santos) is no longer active")
                return false
            }
            
            // Verify worker is in current active roster
            let activeWorkerIds = ["1", "2", "4", "5", "6", "7", "8"] // Current roster without Jose
            if !activeWorkerIds.contains(workerId) {
                print("🚫 Worker ID \(workerId) not in current active roster")
                return false
            }
            
            return exists
        } catch {
            print("⚠️ Worker validation error: \(error)")
            return false
        }
    }
    
    /// Log worker-specific metrics for real-world validation
    private func logWorkerMetrics(_ worker: InternalWorkerContext, _ buildingCount: Int, _ taskCount: Int) async {
        print("📊 Worker Metrics - \(worker.workerName):")
        print("   • Buildings assigned: \(buildingCount)")
        print("   • Tasks today: \(taskCount)")
        print("   • Worker role: \(worker.role)")
        
        // Validate against expected ranges for real workers
        if buildingCount == 0 {
            print("⚠️ WARNING: Worker \(worker.workerName) has no building assignments")
        }
        if taskCount == 0 {
            print("⚠️ WARNING: Worker \(worker.workerName) has no tasks for today")
        }
        
        // Special validation for Kevin's expanded duties
        if worker.workerId == "4" && buildingCount < 6 {
            print("⚠️ WARNING: Kevin Dutan should have 6+ buildings (expanded duties), found \(buildingCount)")
        }
        
        // Special validation for Mercedes' split shift
        if worker.workerId == "5" {
            print("⏰ Mercedes Inamagua: Split shift 6:30-10:30 AM")
        }
        
        // Log Phase-2 specific validations
        await validatePhase2WorkerRequirements(worker, buildingCount, taskCount)
    }
    
    /// Phase-2 specific worker validation
    private func validatePhase2WorkerRequirements(_ worker: InternalWorkerContext, _ buildingCount: Int, _ taskCount: Int) async {
        switch worker.workerId {
        case "1": // Greg Hutson - reduced hours
            print("🔧 Greg Hutson: Reduced hours 9:00-15:00")
            
        case "2": // Edwin Lema - early shift
            print("🧹 Edwin Lema: Early morning shift 6:00-15:00")
            
        case "4": // Kevin Dutan - expanded duties
            print("⚡ Kevin Dutan: EXPANDED DUTIES (took Jose's responsibilities)")
            if buildingCount >= 6 {
                print("✅ Kevin's building expansion verified: \(buildingCount) buildings")
            }
            
        case "5": // Mercedes Inamagua - split shift
            print("✨ Mercedes Inamagua: Split shift specialist 6:30-10:30 AM")
            
        case "6": // Luis Lopez - standard
            print("🔨 Luis Lopez: Standard day shift 7:00-16:00")
            
        case "7": // Angel Guirachocha - evening
            print("🗑️ Angel Guirachocha: Day + evening garbage duties")
            
        case "8": // Shawn Magloire - specialist
            print("🎨 Shawn Magloire: Rubin Museum specialist, flexible schedule")
            
        default:
            print("⚠️ Unknown worker ID: \(worker.workerId)")
        }
    }
    
    public func refreshContext() async {
        guard let workerId = getCurrentWorkerId() else { return }
        await loadWorkerContext(workerId: workerId)
    }
    
    // MARK: - ✅ PUBLIC ACCESSOR METHODS (Only basic types or verified public types)
    
    /// Get count of assigned buildings (Int - basic type)
    public func getAssignedBuildingsCount() -> Int {
        return assignedBuildings.count
    }
    
    /// Get count of today's tasks (Int - basic type)
    public func getTodaysTasksCount() -> Int {
        return todaysTasks.count
    }
    
    /// Get count of daily routines (Int - basic type)
    public func getDailyRoutinesCount() -> Int {
        return dailyRoutines.count
    }
    
    /// Get DSNY schedule data as basic types
    public func getDSNYScheduleData() -> [(day: String, time: String, status: String)] {
        return dsnySchedule
    }
    
    /// Get routine override count (Int - basic type)
    public func getRoutineOverrideCount() -> Int {
        return routineOverrides.count
    }
    
    /// Check if there are weather postponements (Bool - basic type)
    public func hasWeatherPostponements() -> Bool {
        return !routineOverrides.isEmpty
    }
    
    /// Get weather postponement reasons (basic types only)
    public func getWeatherPostponements() -> [String: String] {
        return routineOverrides
    }
    
    public func getTasksCount() -> Int {
        return todaysTasks.count
    }
    
    public func getPendingTasksCount() -> Int {
        return todaysTasks.filter { $0.status != "completed" }.count
    }
    
    public func getCompletedTasksCount() -> Int {
        return todaysTasks.filter { $0.status == "completed" }.count
    }
    
    public func getUrgentTaskCount() -> Int {
        return todaysTasks.filter { $0.isOverdue || $0.urgencyLevel == "high" }.count
    }
    
    public func getBuildingsCount() -> Int {
        return assignedBuildings.count
    }
    
    public func getWorkerName() -> String {
        return currentWorker?.workerName ?? ""
    }
    
    public func getWorkerId() -> String {
        return currentWorker?.workerId ?? ""
    }
    
    public func getWorkerEmail() -> String {
        return currentWorker?.email ?? ""
    }
    
    public func getWorkerRole() -> String {
        return currentWorker?.role ?? ""
    }
    
    public func hasWorkerData() -> Bool {
        return currentWorker != nil
    }
    
    public func getAssignedBuildingCount() -> Int {
        return assignedBuildings.count
    }
    
    // MARK: - HF-14: Task Count Methods for MapOverlay (Basic types only)

    /// Get total task count for a specific building (Int - basic type)
    public func getTaskCount(forBuilding buildingId: String) -> Int {
        return todaysTasks.filter { $0.buildingId == buildingId }.count
    }

    /// Get open task count for a specific building (Int - basic type)
    public func getOpenTaskCount(forBuilding buildingId: String) -> Int {
        return todaysTasks.filter { task in
            task.buildingId == buildingId && task.status != "completed"
        }.count
    }

    /// Get completed task count for a specific building (Int - basic type)
    public func getCompletedTaskCount(forBuilding buildingId: String) -> Int {
        return todaysTasks.filter { task in
            task.buildingId == buildingId && task.status == "completed"
        }.count
    }

    /// Get overdue task count for a specific building (Int - basic type)
    public func getOverdueTaskCount(forBuilding buildingId: String) -> Int {
        return todaysTasks.filter { task in
            task.buildingId == buildingId && task.isOverdue
        }.count
    }
    
    /// Get current worker ID (String - basic type)
    public func getCurrentWorkerId() -> String? {
        return currentWorker?.workerId
    }
    
    /// Get current worker name (String - basic type)
    public func getCurrentWorkerName() -> String? {
        return currentWorker?.workerName
    }
    
    // MARK: - ✅ INTERNAL DATABASE METHODS (Not exposed publicly)
    
    /// Internal method to load worker context (returns internal type)
    internal func loadWorkerContext_Internal(_ workerId: String) async throws -> InternalWorkerContext {
        guard let manager = sqliteManager else {
            throw DatabaseError.notInitialized
        }
        
        let results = try await manager.query("""
            SELECT w.id, w.name, w.email, w.role
            FROM workers w
            WHERE w.id = ?
            LIMIT 1
        """, [workerId])
        
        guard let row = results.first else {
            throw DatabaseError.invalidData("Worker not found")
        }
        
        let workerIdString: String
        if let idInt = row["id"] as? Int64 {
            workerIdString = String(idInt)
        } else if let idString = row["id"] as? String {
            workerIdString = idString
        } else {
            workerIdString = workerId
        }
        
        return InternalWorkerContext(
            workerId: workerIdString,
            workerName: row["name"] as? String ?? "",
            email: row["email"] as? String ?? "",
            role: row["role"] as? String ?? "worker",
            primaryBuildingId: nil
        )
    }
    
    // BEGIN PATCH(HF-07): Enhanced building loading with WorkerAssignmentManager coordination
    private func loadWorkerBuildings_Enhanced(_ workerId: String) async throws -> [FrancoSphere.NamedCoordinate] {
        print("🔄 HF-07: Enhanced building loading for worker \(workerId)")
        
        // Method 1: Try WorkerAssignmentManager first (immediate response)
        let assignmentManagerBuildings = assignmentManager.getAssignedBuildingIds(for: workerId)
        
        if !assignmentManagerBuildings.isEmpty {
            print("✅ HF-07: Got \(assignmentManagerBuildings.count) buildings from WorkerAssignmentManager")
            return convertBuildingIdsToCoordinates(assignmentManagerBuildings)
        }
        
        // Method 2: Try database query (fallback)
        print("🔄 HF-07: WorkerAssignmentManager empty, trying database...")
        let databaseBuildings = try await loadWorkerBuildings_Internal(workerId)
        
        if !databaseBuildings.isEmpty {
            print("✅ HF-07: Got \(databaseBuildings.count) buildings from database")
            return databaseBuildings
        }
        
        // Method 3: Try CSV fallback (last resort)
        print("🔄 HF-07: Database empty, using CSV fallback...")
        let csvBuildings = await loadBuildingsFromCSVFallback_Internal(workerId)
        
        if !csvBuildings.isEmpty {
            print("✅ HF-07: Got \(csvBuildings.count) buildings from CSV fallback")
            
            // For Kevin, trigger emergency assignment creation to populate database
            if workerId == "4" && csvBuildings.count >= 6 {
                print("🔧 HF-07: Triggering emergency assignment creation for Kevin")
                let success = await assignmentManager.createEmergencyAssignments(for: workerId)
                if success {
                    print("✅ HF-07: Emergency assignments created successfully")
                }
            }
        }
        
        return csvBuildings
    }
    
    /// Convert building IDs to NamedCoordinate objects (verified public type)
    private func convertBuildingIdsToCoordinates(_ buildingIds: [String]) -> [FrancoSphere.NamedCoordinate] {
        let allBuildings = FrancoSphere.NamedCoordinate.allBuildings
        return allBuildings.filter { building in
            buildingIds.contains(building.id)
        }.sorted { $0.name < $1.name }
    }
    // END PATCH(HF-07)
    
    private func loadWorkerBuildings_Internal(_ workerId: String) async throws -> [FrancoSphere.NamedCoordinate] {
        guard let manager = sqliteManager else {
            throw DatabaseError.notInitialized
        }
        
        // Load buildings from worker_building_assignments table (real CSV data)
        let results = try await manager.query("""
            SELECT DISTINCT b.id, b.name, b.latitude, b.longitude, b.imageAssetName
            FROM buildings b
            INNER JOIN worker_building_assignments wa ON CAST(b.id AS TEXT) = wa.building_id
            WHERE wa.worker_id = ? AND wa.is_active = 1
            ORDER BY b.name
        """, [workerId])
        
        var buildings: [FrancoSphere.NamedCoordinate] = []
        
        for row in results {
            guard let idValue = row["id"],
                  let name = row["name"] as? String,
                  let lat = row["latitude"] as? Double,
                  let lng = row["longitude"] as? Double else {
                continue
            }
            
            let buildingId: String
            if let idInt = idValue as? Int64 {
                buildingId = String(idInt)
            } else if let idString = idValue as? String {
                buildingId = idString
            } else {
                continue
            }
            
            let imageAssetName = row["imageAssetName"] as? String ?? "building_default"
            
            let building = FrancoSphere.NamedCoordinate(
                id: buildingId,
                name: name,
                latitude: lat,
                longitude: lng,
                imageAssetName: imageAssetName
            )
            
            buildings.append(building)
        }
        
        print("📋 Loaded \(buildings.count) buildings for worker \(workerId) from database")
        return buildings
    }
    
    /// Fallback to load buildings based on CSV assignments if database is empty
    internal func loadBuildingsFromCSVFallback_Internal(_ workerId: String) async -> [FrancoSphere.NamedCoordinate] {
        print("🔄 Loading buildings from CSV fallback for worker \(workerId)")
        
        // Real worker-building assignments based on current roster
        let workerBuildingMap: [String: [String]] = [
            "1": ["1", "4", "7", "10", "12"],           // Greg Hutson
            "2": ["2", "5", "8", "11"],                 // Edwin Lema
            "4": ["3", "6", "7", "9", "11", "16"],      // Kevin Dutan (expanded - took Jose's duties)
            "5": ["2", "6", "10", "13"],                // Mercedes Inamagua
            "6": ["4", "8", "13"],                      // Luis Lopez
            "7": ["9", "13", "15", "18"],               // Angel Guirachocha
            "8": ["14"]                                 // Shawn Magloire (Rubin Museum)
        ]
        
        let assignedBuildingIds = workerBuildingMap[workerId] ?? []
        let allBuildings = FrancoSphere.NamedCoordinate.allBuildings
        
        let buildings = allBuildings.filter { building in
            assignedBuildingIds.contains(building.id)
        }
        
        print("📋 CSV fallback loaded \(buildings.count) buildings for worker \(workerId)")
        return buildings
    }
    
    private func loadWorkerTasksForToday_Internal(_ workerId: String) async throws -> [ContextualTask] {
        guard let manager = sqliteManager else {
            throw DatabaseError.notInitialized
        }
        
        let today = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? today
        
        // Load tasks from database with real worker assignments
        let results = try await manager.query("""
            SELECT t.id, t.name, t.buildingId, t.category, t.urgencyLevel, 
                   t.status, t.startTime, t.endTime, t.description, 
                   b.name as buildingName
            FROM tasks t
            LEFT JOIN buildings b ON CAST(t.buildingId AS TEXT) = CAST(b.id AS TEXT)
            WHERE t.workerId = ? 
            AND t.scheduledDate >= ? 
            AND t.scheduledDate < ?
            ORDER BY t.startTime
        """, [workerId, startOfDay.iso8601String, endOfDay.iso8601String])
        
        var tasks: [ContextualTask] = []
        
        for row in results {
            guard let id = row["id"] as? String,
                  let name = row["name"] as? String else {
                continue
            }
            
            let buildingId = String(row["buildingId"] as? Int64 ?? 0)
            let buildingName = row["buildingName"] as? String ?? "Unknown Building"
            
            let task = ContextualTask(
                id: id,
                name: name,
                buildingId: buildingId,
                buildingName: buildingName,
                category: row["category"] as? String ?? "Maintenance",
                startTime: row["startTime"] as? String,
                endTime: row["endTime"] as? String,
                recurrence: "Daily", // Default
                skillLevel: "Basic", // Default
                status: row["status"] as? String ?? "pending",
                urgencyLevel: row["urgencyLevel"] as? String ?? "medium",
                assignedWorkerName: getWorkerName()
            )
            
            tasks.append(task)
        }
        
        print("📋 Loaded \(tasks.count) tasks for worker \(workerId) today")
        
        // If no tasks found, generate sample tasks based on worker role
        if tasks.isEmpty {
            tasks = await generateSampleTasksForWorker(workerId)
        }
        
        return tasks
    }
    
    /// Generate sample tasks if database is empty (for development/testing)
    private func generateSampleTasksForWorker(_ workerId: String) async -> [ContextualTask] {
        let workerName = getWorkerName()
        print("🔄 Generating sample tasks for \(workerName) (ID: \(workerId))")
        
        let sampleTasks: [String: [ContextualTask]] = [
            "1": [ // Greg Hutson
                ContextualTask(
                    id: "greg_sample_1",
                    name: "Sidewalk & Curb Clean",
                    buildingId: "1",
                    buildingName: "12 West 18th Street",
                    category: "Cleaning",
                    startTime: "09:00",
                    endTime: "10:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: workerName
                )
            ],
            "2": [ // Edwin Lema
                ContextualTask(
                    id: "edwin_sample_1",
                    name: "Morning Park Check",
                    buildingId: "16",
                    buildingName: "Stuyvesant Cove Park",
                    category: "Maintenance",
                    startTime: "06:00",
                    endTime: "07:00",
                    recurrence: "Daily",
                    skillLevel: "Intermediate",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: workerName
                )
            ],
            "4": [ // Kevin Dutan (expanded)
                ContextualTask(
                    id: "kevin_sample_1",
                    name: "Sidewalk + Curb Sweep / Trash Return",
                    buildingId: "10",
                    buildingName: "131 Perry Street",
                    category: "Cleaning",
                    startTime: "06:00",
                    endTime: "07:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: workerName
                ),
                ContextualTask(
                    id: "kevin_sample_2",
                    name: "Lobby + Packages Check",
                    buildingId: "10",
                    buildingName: "131 Perry Street",
                    category: "Cleaning",
                    startTime: "08:00",
                    endTime: "08:30",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: workerName
                )
            ],
            "5": [ // Mercedes Inamagua
                ContextualTask(
                    id: "mercedes_sample_1",
                    name: "Glass & Lobby Clean",
                    buildingId: "7",
                    buildingName: "112 West 18th Street",
                    category: "Cleaning",
                    startTime: "06:30",
                    endTime: "07:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: workerName
                )
            ]
        ]
        
        return sampleTasks[workerId] ?? []
    }
    
    private func loadUpcomingTasks_Internal(_ workerId: String) async throws -> [ContextualTask] {
        guard let manager = sqliteManager else {
            throw DatabaseError.notInitialized
        }
        
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        
        let results = try await manager.query("""
            SELECT t.id, t.name, t.buildingId, t.category, t.urgencyLevel, 
                   t.status, t.startTime, t.endTime, t.description, 
                   b.name as buildingName
            FROM tasks t
            LEFT JOIN buildings b ON CAST(t.buildingId AS TEXT) = CAST(b.id AS TEXT)
            WHERE t.workerId = ? 
            AND t.scheduledDate >= ? 
            AND t.scheduledDate <= ?
            ORDER BY t.scheduledDate, t.startTime
        """, [workerId, tomorrow.iso8601String, weekFromNow.iso8601String])
        
        var tasks: [ContextualTask] = []
        
        for row in results {
            guard let id = row["id"] as? String,
                  let name = row["name"] as? String else {
                continue
            }
            
            let buildingId = String(row["buildingId"] as? Int64 ?? 0)
            let buildingName = row["buildingName"] as? String ?? "Unknown Building"
            
            let task = ContextualTask(
                id: id,
                name: name,
                buildingId: buildingId,
                buildingName: buildingName,
                category: row["category"] as? String ?? "Maintenance",
                startTime: row["startTime"] as? String,
                endTime: row["endTime"] as? String,
                recurrence: "Daily", // Default
                skillLevel: "Basic", // Default
                status: row["status"] as? String ?? "pending",
                urgencyLevel: row["urgencyLevel"] as? String ?? "medium",
                assignedWorkerName: getWorkerName()
            )
            
            tasks.append(task)
        }
        
        print("📋 Loaded \(tasks.count) upcoming tasks for worker \(workerId)")
        return tasks
    }
    
    // MARK: - Migration Management
    
    private func ensureMigrationRun() async throws {
        guard !migrationRun else { return }
        
        // 🔧 FIX #3: Use instance method instead of static
        do {
            try await SchemaMigrationPatch.shared.applyPatch()
            print("✅ Phase-2 database migration completed")
        } catch {
            print("❌ Phase-2 database migration failed: \(error)")
            throw error
        }
        
        migrationRun = true
    }
}

// MARK: - ⭐ PHASE-2: Enhanced Error Types for Real-World Validation

public enum WorkerContextError: LocalizedError {
    case noWorkerID
    case workerNotFound(String)
    case noRealWorldData
    case joseNotAllowed
    case invalidWorkerRoster
    
    public var errorDescription: String? {
        switch self {
        case .noWorkerID:
            return "No worker ID available. Please log in."
        case .workerNotFound(let id):
            return "Worker ID \(id) not found in system. Contact administrator."
        case .noRealWorldData:
            return "Real-world data not loaded. Please refresh."
        case .joseNotAllowed:
            return "Jose Santos is no longer with the company."
        case .invalidWorkerRoster:
            return "Invalid worker roster. Expected 7 active workers."
        }
    }
}

// MARK: - ⭐ PHASE-2: Enhanced Worker Context Public Interface

extension WorkerContextEngine {
    
    /// Get current worker context summary for debugging (basic types only)
    public func getWorkerContextSummary() -> [String: Any] {
        var summary: [String: Any] = [:]
        
        if let worker = currentWorker {
            summary["workerId"] = worker.workerId
            summary["workerName"] = worker.workerName
            summary["role"] = worker.role
            summary["email"] = worker.email
        }
        
        summary["buildingCount"] = assignedBuildings.count
        summary["todayTaskCount"] = todaysTasks.count
        summary["upcomingTaskCount"] = upcomingTasks.count
        summary["completedTaskCount"] = getCompletedTasksCount()
        summary["urgentTaskCount"] = getUrgentTaskCount()
        summary["isLoading"] = isLoading
        summary["hasError"] = error != nil
        
        if let error = error {
            summary["errorDescription"] = error.localizedDescription
        }
        
        return summary
    }
    
    /// Validate current worker against Phase-2 requirements (returns basic types)
    public func validateCurrentWorker() -> (isValid: Bool, issues: [String]) {
        var issues: [String] = []
        
        guard let worker = currentWorker else {
            issues.append("No worker loaded")
            return (false, issues)
        }
        
        // Check if worker is Jose Santos (should not be allowed)
        if worker.workerId == "3" || worker.workerName.contains("Jose") {
            issues.append("Jose Santos is no longer active")
        }
        
        // Check if worker is in current active roster
        let activeWorkerIds = ["1", "2", "4", "5", "6", "7", "8"]
        if !activeWorkerIds.contains(worker.workerId) {
            issues.append("Worker not in current active roster")
        }
        
        // Check Kevin's expanded assignments
        if worker.workerId == "4" && assignedBuildings.count < 6 {
            issues.append("Kevin should have 6+ buildings (expanded duties)")
        }
        
        // Check Mercedes' schedule constraints
        if worker.workerId == "5" && !todaysTasks.isEmpty {
            // Should only have morning tasks (6:30-10:30 AM)
            let morningTasks = todaysTasks.filter { task in
                guard let startTime = task.startTime,
                      let hour = Int(startTime.split(separator: ":").first ?? "") else {
                    return true
                }
                return hour >= 6 && hour <= 10
            }
            
            if morningTasks.count != todaysTasks.count {
                issues.append("Mercedes should only have morning tasks (6:30-10:30 AM)")
            }
        }
        
        return (issues.isEmpty, issues)
    }
    
    /// Force refresh worker context with CSV import if needed
    public func forceRefreshWithCSVImport() async {
        print("🔄 Force refreshing worker context with CSV import if needed...")
        
        // Clear current data
        await MainActor.run {
            self.assignedBuildings = []
            self.todaysTasks = []
            self.upcomingTasks = []
        }
        
        // Trigger CSV import if needed
        do {
            let importer = CSVDataImporter.shared
            importer.sqliteManager = sqliteManager
            let (imported, errors) = try await importer.importRealWorldTasks()
            print("🔄 CSV import: \(imported) tasks, \(errors.count) errors")
        } catch {
            print("❌ CSV import failed: \(error)")
        }
        
        // Reload context
        await refreshContext()
    }
}
