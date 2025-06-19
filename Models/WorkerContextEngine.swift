//
//  WorkerContextEngine.swift
//  FrancoSphere
//
//  🔧 PHASE-2 ENHANCED - Dynamic Worker-Specific Data Loading
//  ✅ PATCH P2-04-V2: Real CSV task assignments integration
//  ✅ Enhanced worker validation with real-world data
//  ✅ Jose Santos removal support, Kevin expansion tracking
//  ✅ Dynamic worker-specific context loading with auth integration
//  ✅ HF-07: Enhanced coordination with WorkerAssignmentManager
//

import Foundation
import Combine
import CoreLocation

// MARK: - Supporting Types (internal - used only within WorkerContextEngine)

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

@MainActor
public class WorkerContextEngine: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = WorkerContextEngine()
    
    // MARK: - Published Properties
    @Published public var isLoading = false
    @Published public var error: Error?
    
    // MARK: - Internal Properties (accessed via public methods)
    @Published internal var currentWorker: InternalWorkerContext?
    @Published internal var assignedBuildings: [FrancoSphere.NamedCoordinate] = []
    @Published internal var todaysTasks: [ContextualTask] = []
    @Published internal var upcomingTasks: [ContextualTask] = []
    
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
    }
    
    // MARK: - Setup
    
    private func setupSQLiteManager() {
        sqliteManager = SQLiteManager.shared
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
            
            let worker = try await loadWorkerContext_Fixed(actualWorkerId)
            
            // BEGIN PATCH(HF-07): Enhanced building loading with AssignmentManager coordination
            let buildings = try await loadWorkerBuildings_Enhanced(actualWorkerId)
            // END PATCH(HF-07)
            
            let todayTasks = try await loadWorkerTasksForToday_Fixed(actualWorkerId)
            let upcomingTasks = try await loadUpcomingTasks_Fixed(actualWorkerId)
            
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
        guard let workerId = currentWorker?.workerId else { return }
        await loadWorkerContext(workerId: workerId)
    }
    
    // MARK: - ⭐ PHASE-2: Enhanced Public Accessor Methods
    
    public func getAssignedBuildings() -> [FrancoSphere.NamedCoordinate] {
        return assignedBuildings
    }
    
    public func getAllBuildings() -> [FrancoSphere.NamedCoordinate] {
        return FrancoSphere.NamedCoordinate.allBuildings
    }
    
    internal func getTodaysTasks() -> [ContextualTask] {
        return todaysTasks
    }
    
    internal func getUpcomingTasks() -> [ContextualTask] {
        return upcomingTasks
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
    
    public func hasWorkerData() -> Bool {
        return currentWorker != nil
    }
    
    public func getAssignedBuildingCount() -> Int {
        return assignedBuildings.count
    }
    
    // MARK: - ⭐ PHASE-2: Enhanced Database Query Methods
    
    private func loadWorkerContext_Fixed(_ workerId: String) async throws -> InternalWorkerContext {
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
        let databaseBuildings = try await loadWorkerBuildings_Fixed(workerId)
        
        if !databaseBuildings.isEmpty {
            print("✅ HF-07: Got \(databaseBuildings.count) buildings from database")
            return databaseBuildings
        }
        
        // Method 3: Try CSV fallback (last resort)
        print("🔄 HF-07: Database empty, using CSV fallback...")
        let csvBuildings = await loadBuildingsFromCSVFallback(workerId)
        
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
    
    /// Convert building IDs to NamedCoordinate objects
    private func convertBuildingIdsToCoordinates(_ buildingIds: [String]) -> [FrancoSphere.NamedCoordinate] {
        let allBuildings = FrancoSphere.NamedCoordinate.allBuildings
        return allBuildings.filter { building in
            buildingIds.contains(building.id)
        }.sorted { $0.name < $1.name }
    }
    // END PATCH(HF-07)
    
    private func loadWorkerBuildings_Fixed(_ workerId: String) async throws -> [FrancoSphere.NamedCoordinate] {
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
    internal func loadBuildingsFromCSVFallback(_ workerId: String) async -> [FrancoSphere.NamedCoordinate] {
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
    
    private func loadWorkerTasksForToday_Fixed(_ workerId: String) async throws -> [ContextualTask] {
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
    
    private func loadUpcomingTasks_Fixed(_ workerId: String) async throws -> [ContextualTask] {
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
        
        // Use the enhanced Phase-2 schema migration
        do {
            try await SchemaMigrationPatch.applyPatch()
            print("✅ Phase-2 database migration completed")
        } catch {
            print("❌ Phase-2 database migration failed: \(error)")
            throw error
        }
        
        migrationRun = true
    }
}

// MARK: - ⭐ PHASE-2: Enhanced Error Types for Real-World Validation

enum WorkerContextError: LocalizedError {
    case noWorkerID
    case workerNotFound(String)
    case noRealWorldData
    case joseNotAllowed
    case invalidWorkerRoster
    
    var errorDescription: String? {
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
    
    /// Get current worker context summary for debugging
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
    
    /// Validate current worker against Phase-2 requirements
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
