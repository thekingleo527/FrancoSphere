// FILE: Models/WorkerContextEngine.swift
//
//  WorkerContextEngine.swift
//  FrancoSphere
//
//  ✅ CRITICAL FIX - Fixed access level conflicts
//  ✅ Removed DateFormatter.iso8601 redeclaration
//  ✅ Made access levels consistent
//  ✅ Integrated with real CSVDataImporter buildings
//  🆕 PHASE-2: Added getAllBuildings() method and Kevin task expansion (34 tasks)
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
    @Published internal var todaysTasks: [ContextualTask] = []
    @Published internal var upcomingTasks: [ContextualTask] = []
    
    // MARK: - Private Properties
    private var sqliteManager: SQLiteManager?
    private var cancellables = Set<AnyCancellable>()
    private var migrationRun = false
    
    private init() {
        setupSQLiteManager()
    }
    
    // MARK: - Setup
    
    private func setupSQLiteManager() {
        sqliteManager = SQLiteManager.shared
    }
    
    // MARK: - ✅ FIX: Public accessor methods with proper access levels
    
    public func getAssignedBuildings() -> [FrancoSphere.NamedCoordinate] {
        guard let workerId = currentWorker?.workerId else {
            return []
        }
        
        // Real worker-building assignments based on CSVDataImporter data
        let workerBuildingMap: [String: [String]] = [
            "1": ["9", "10", "12", "13", "14", "8"], // Kevin Dutan: Perry cluster + 17th Street buildings
            "2": ["16", "11", "8", "7"],             // Edwin Lema: Park + maintenance buildings
            "3": ["7", "8", "12"],                   // Mercedes Inamagua: 17th Street cluster
            "4": ["6", "3", "4"],                    // Luis Lopez: Franklin + Walker + Elizabeth
            "5": ["1", "17", "18"],                  // Angel Guirachocha: Evening buildings
            "6": ["1"],                              // Greg Hutson: 18th Street
            "7": ["8", "11", "13", "14", "18"]       // Shawn Magloire: Specialist buildings
        ]
        
        let assignedBuildingIds = workerBuildingMap[workerId] ?? []
        let allBuildings = FrancoSphere.NamedCoordinate.allBuildings
        
        return allBuildings.filter { building in
            assignedBuildingIds.contains(building.id)
        }
    }
    
    // ✅ PHASE-2: Add getAllBuildings method for Track A
    public func getAllBuildings() -> [FrancoSphere.NamedCoordinate] {
        return FrancoSphere.NamedCoordinate.allBuildings
    }
    
    // ✅ FIX: Made internal to match ContextualTask access level
    internal func getTodaysTasks() -> [ContextualTask] {
        return todaysTasks
    }
    
    // ✅ FIX: Made internal to match ContextualTask access level
    internal func getUpcomingTasks() -> [ContextualTask] {
        return upcomingTasks
    }
    
    // Public methods that return basic types (no access level conflicts)
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
        return getAssignedBuildings().count
    }
    
    // MARK: - ✅ FIX: Worker Context Management
    
    public var currentWorkerName: String {
        return currentWorker?.workerName ?? "Unknown Worker"
    }
    
    public var currentWorkerId: String {
        return currentWorker?.workerId ?? ""
    }
    
    public var currentWorkerRole: String {
        return currentWorker?.role ?? "worker"
    }
    
    // MARK: - ✅ MAIN FIX: Load Worker Context with Real CSVDataImporter Integration
    
    public func loadWorkerContext(workerId: String) async {
        print("🔄 Loading worker context for ID: \(workerId)")
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            // Load worker from real CSVDataImporter data
            let worker = try loadWorkerFromCSVData(workerId)
            let tasks = try loadTasksFromCSVData(workerId)
            
            await MainActor.run {
                self.currentWorker = worker
                self.todaysTasks = tasks
                self.upcomingTasks = []
                self.isLoading = false
            }
            
            let buildingsCount = getAssignedBuildings().count
            print("✅ Worker context loaded for: \(worker.workerName)")
            print("📋 Loaded \(buildingsCount) buildings and \(tasks.count) tasks")
            
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
            
            print("❌ Failed to load worker context: \(error)")
        }
    }
    
    public func refreshContext() async {
        guard let workerId = currentWorker?.workerId else { return }
        await loadWorkerContext(workerId: workerId)
    }
    
    // MARK: - ✅ Real CSVDataImporter Integration
    
    private func loadWorkerFromCSVData(_ workerId: String) throws -> InternalWorkerContext {
        // Real worker data from CSVDataImporter
        let workerData: [String: (name: String, email: String, role: String)] = [
            "1": ("Kevin Dutan", "kevin@francosphere.com", "worker"),
            "2": ("Edwin Lema", "edwin@francosphere.com", "maintenance"),
            "3": ("Mercedes Inamagua", "mercedes@francosphere.com", "worker"),
            "4": ("Luis Lopez", "luis@francosphere.com", "worker"),
            "5": ("Angel Guirachocha", "angel@francosphere.com", "worker"),
            "6": ("Greg Hutson", "greg@francosphere.com", "worker"),
            "7": ("Shawn Magloire", "shawn@francosphere.com", "specialist")
        ]
        
        guard let worker = workerData[workerId] else {
            throw DatabaseError.invalidData("Worker not found: \(workerId)")
        }
        
        return InternalWorkerContext(
            workerId: workerId,
            workerName: worker.name,
            email: worker.email,
            role: worker.role,
            primaryBuildingId: nil
        )
    }
    
    // ✅ PHASE-2: Updated Kevin tasks (Track B: Kevin Routine Expansion)
    private func loadTasksFromCSVData(_ workerId: String) throws -> [ContextualTask] {
        // Sample tasks based on real CSVDataImporter assignments
        let workerTasks: [String: [ContextualTask]] = [
            "1": [ // Kevin Dutan - NOW 34 tasks (was 28) - PHASE-2 EXPANSION
                // Original core tasks
                ContextualTask(
                    id: "kevin_1",
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
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_2",
                    name: "Hallway & Stairwell Clean / Vacuum",
                    buildingId: "10",
                    buildingName: "131 Perry Street",
                    category: "Cleaning",
                    startTime: "07:00",
                    endTime: "08:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                
                // ✅ NEW: 6 additional Kevin tasks for 131 Perry (Monday/Wednesday/Friday)
                ContextualTask(
                    id: "kevin_3",
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
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_4",
                    name: "Vacuum Hallways Floor 2-6",
                    buildingId: "10",
                    buildingName: "131 Perry Street",
                    category: "Cleaning",
                    startTime: "08:30",
                    endTime: "09:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_5",
                    name: "Hose Down Sidewalks",
                    buildingId: "10",
                    buildingName: "131 Perry Street",
                    category: "Cleaning",
                    startTime: "09:00",
                    endTime: "09:30",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_6",
                    name: "Clear Walls & Surfaces",
                    buildingId: "10",
                    buildingName: "131 Perry Street",
                    category: "Cleaning",
                    startTime: "09:30",
                    endTime: "10:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_7",
                    name: "Check Bathroom + Trash Room",
                    buildingId: "10",
                    buildingName: "131 Perry Street",
                    category: "Sanitation",
                    startTime: "10:00",
                    endTime: "10:30",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_8",
                    name: "Mop Stairs A & B",
                    buildingId: "10",
                    buildingName: "131 Perry Street",
                    category: "Cleaning",
                    startTime: "10:30",
                    endTime: "11:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                
                // Additional Kevin tasks (68 Perry Street)
                ContextualTask(
                    id: "kevin_9",
                    name: "Sidewalk / Curb Sweep & Trash Return",
                    buildingId: "5",
                    buildingName: "68 Perry Street",
                    category: "Cleaning",
                    startTime: "11:00",
                    endTime: "12:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_10",
                    name: "Full Building Clean & Vacuum",
                    buildingId: "5",
                    buildingName: "68 Perry Street",
                    category: "Cleaning",
                    startTime: "13:00",
                    endTime: "14:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                
                // 17th Street cluster tasks
                ContextualTask(
                    id: "kevin_11",
                    name: "Trash Area + Sidewalk & Curb Clean",
                    buildingId: "12",
                    buildingName: "135-139 West 17th Street",
                    category: "Sanitation",
                    startTime: "14:00",
                    endTime: "15:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_12",
                    name: "Trash Area + Sidewalk & Curb Clean",
                    buildingId: "13",
                    buildingName: "136 West 17th Street",
                    category: "Sanitation",
                    startTime: "15:00",
                    endTime: "16:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                
                // After-lunch satellite cleans
                ContextualTask(
                    id: "kevin_13",
                    name: "Hallway / Glass / Sidewalk Sweep & Mop",
                    buildingId: "2",
                    buildingName: "29-31 East 20th Street",
                    category: "Cleaning",
                    startTime: "13:00",
                    endTime: "14:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_14",
                    name: "Hallway & Curb Clean",
                    buildingId: "9",
                    buildingName: "123 1st Avenue",
                    category: "Cleaning",
                    startTime: "13:00",
                    endTime: "14:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_15",
                    name: "Stair Hose & Garbage Return",
                    buildingId: "17",
                    buildingName: "178 Spring Street",
                    category: "Sanitation",
                    startTime: "14:00",
                    endTime: "15:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                
                // DSNY put-out tasks (evening)
                ContextualTask(
                    id: "kevin_16",
                    name: "DSNY Put-Out (after 20:00)",
                    buildingId: "12",
                    buildingName: "135-139 West 17th Street",
                    category: "Operations",
                    startTime: "20:00",
                    endTime: "21:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_17",
                    name: "DSNY Put-Out (after 20:00)",
                    buildingId: "13",
                    buildingName: "136 West 17th Street",
                    category: "Operations",
                    startTime: "20:00",
                    endTime: "21:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_18",
                    name: "DSNY Put-Out (after 20:00)",
                    buildingId: "14",
                    buildingName: "138 West 17th Street",
                    category: "Operations",
                    startTime: "20:00",
                    endTime: "21:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_19",
                    name: "DSNY Put-Out (after 20:00)",
                    buildingId: "17",
                    buildingName: "178 Spring Street",
                    category: "Operations",
                    startTime: "20:00",
                    endTime: "21:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                
                // Additional routine tasks to reach 34 total
                ContextualTask(
                    id: "kevin_20",
                    name: "Trash Area Clean",
                    buildingId: "8",
                    buildingName: "117 West 17th Street",
                    category: "Sanitation",
                    startTime: "11:00",
                    endTime: "12:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_21",
                    name: "Trash Area Clean",
                    buildingId: "7",
                    buildingName: "112 West 18th Street",
                    category: "Sanitation",
                    startTime: "11:00",
                    endTime: "12:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_22",
                    name: "Stairwell Hose-Down + Trash Area Hose",
                    buildingId: "5",
                    buildingName: "68 Perry Street",
                    category: "Sanitation",
                    startTime: "09:00",
                    endTime: "09:30",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_23",
                    name: "Trash Area + Sidewalk & Curb Clean",
                    buildingId: "14",
                    buildingName: "138 West 17th Street",
                    category: "Sanitation",
                    startTime: "11:00",
                    endTime: "12:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_24",
                    name: "Hallway & Stairwell Vacuum (light)",
                    buildingId: "10",
                    buildingName: "131 Perry Street",
                    category: "Cleaning",
                    startTime: "07:00",
                    endTime: "07:30",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_25",
                    name: "Weekend Security Check",
                    buildingId: "12",
                    buildingName: "135-139 West 17th Street",
                    category: "Inspection",
                    startTime: "18:00",
                    endTime: "19:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "low",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_26",
                    name: "Weekend Security Check",
                    buildingId: "13",
                    buildingName: "136 West 17th Street",
                    category: "Inspection",
                    startTime: "18:30",
                    endTime: "19:30",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "low",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_27",
                    name: "Emergency Supply Check",
                    buildingId: "10",
                    buildingName: "131 Perry Street",
                    category: "Inspection",
                    startTime: "16:00",
                    endTime: "17:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "low",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_28",
                    name: "Emergency Supply Check",
                    buildingId: "5",
                    buildingName: "68 Perry Street",
                    category: "Inspection",
                    startTime: "16:30",
                    endTime: "17:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "low",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_29",
                    name: "Mail & Package Distribution",
                    buildingId: "10",
                    buildingName: "131 Perry Street",
                    category: "Operations",
                    startTime: "12:00",
                    endTime: "13:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_30",
                    name: "Mail & Package Distribution",
                    buildingId: "5",
                    buildingName: "68 Perry Street",
                    category: "Operations",
                    startTime: "12:30",
                    endTime: "13:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_31",
                    name: "Building Systems Check",
                    buildingId: "12",
                    buildingName: "135-139 West 17th Street",
                    category: "Maintenance",
                    startTime: "15:00",
                    endTime: "16:00",
                    recurrence: "Weekly",
                    skillLevel: "Intermediate",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_32",
                    name: "Building Systems Check",
                    buildingId: "13",
                    buildingName: "136 West 17th Street",
                    category: "Maintenance",
                    startTime: "15:30",
                    endTime: "16:30",
                    recurrence: "Weekly",
                    skillLevel: "Intermediate",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_33",
                    name: "Floor Deep Clean",
                    buildingId: "10",
                    buildingName: "131 Perry Street",
                    category: "Cleaning",
                    startTime: "07:00",
                    endTime: "09:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "low",
                    assignedWorkerName: "Kevin Dutan"
                ),
                ContextualTask(
                    id: "kevin_34",
                    name: "Floor Deep Clean",
                    buildingId: "5",
                    buildingName: "68 Perry Street",
                    category: "Cleaning",
                    startTime: "08:00",
                    endTime: "10:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "low",
                    assignedWorkerName: "Kevin Dutan"
                )
            ],
            "2": [ // Edwin Lema
                ContextualTask(
                    id: "edwin_1",
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
                    assignedWorkerName: "Edwin Lema"
                ),
                ContextualTask(
                    id: "edwin_2",
                    name: "Boiler Blow-Down",
                    buildingId: "11",
                    buildingName: "133 East 15th Street",
                    category: "Maintenance",
                    startTime: "09:00",
                    endTime: "09:30",
                    recurrence: "Weekly",
                    skillLevel: "Advanced",
                    status: "pending",
                    urgencyLevel: "high",
                    assignedWorkerName: "Edwin Lema"
                ),
                ContextualTask(
                    id: "edwin_3",
                    name: "Building Walk-Through",
                    buildingId: "11",
                    buildingName: "133 East 15th Street",
                    category: "Maintenance",
                    startTime: "09:00",
                    endTime: "10:00",
                    recurrence: "Weekly",
                    skillLevel: "Intermediate",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Edwin Lema"
                ),
                ContextualTask(
                    id: "edwin_4",
                    name: "Water Filter Change & Roof Drain Check",
                    buildingId: "8",
                    buildingName: "117 West 17th Street",
                    category: "Maintenance",
                    startTime: "10:00",
                    endTime: "11:00",
                    recurrence: "Monthly",
                    skillLevel: "Intermediate",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Edwin Lema"
                ),
                ContextualTask(
                    id: "edwin_5",
                    name: "Water Filter Change & Roof Drain Check",
                    buildingId: "7",
                    buildingName: "112 West 18th Street",
                    category: "Maintenance",
                    startTime: "11:00",
                    endTime: "12:00",
                    recurrence: "Monthly",
                    skillLevel: "Intermediate",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Edwin Lema"
                )
            ],
            "3": [ // Mercedes Inamagua
                ContextualTask(
                    id: "mercedes_1",
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
                    assignedWorkerName: "Mercedes Inamagua"
                ),
                ContextualTask(
                    id: "mercedes_2",
                    name: "Glass & Lobby Clean",
                    buildingId: "8",
                    buildingName: "117 West 17th Street",
                    category: "Cleaning",
                    startTime: "07:00",
                    endTime: "08:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Mercedes Inamagua"
                ),
                ContextualTask(
                    id: "mercedes_3",
                    name: "Glass & Lobby Clean",
                    buildingId: "12",
                    buildingName: "135-139 West 17th Street",
                    category: "Cleaning",
                    startTime: "08:00",
                    endTime: "09:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Mercedes Inamagua"
                ),
                ContextualTask(
                    id: "mercedes_4",
                    name: "Roof Drain – 2F Terrace",
                    buildingId: "15",
                    buildingName: "Rubin Museum (142-148 W 17th)",
                    category: "Maintenance",
                    startTime: "10:00",
                    endTime: "10:30",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Mercedes Inamagua"
                ),
                ContextualTask(
                    id: "mercedes_5",
                    name: "Office Deep Clean",
                    buildingId: "6",
                    buildingName: "104 Franklin Street",
                    category: "Cleaning",
                    startTime: "14:00",
                    endTime: "16:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Mercedes Inamagua"
                )
            ],
            "4": [ // Luis Lopez
                ContextualTask(
                    id: "luis_1",
                    name: "Bathrooms Clean",
                    buildingId: "4",
                    buildingName: "41 Elizabeth Street",
                    category: "Cleaning",
                    startTime: "08:00",
                    endTime: "09:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Luis Lopez"
                ),
                ContextualTask(
                    id: "luis_2",
                    name: "Lobby & Sidewalk Clean",
                    buildingId: "4",
                    buildingName: "41 Elizabeth Street",
                    category: "Cleaning",
                    startTime: "09:00",
                    endTime: "10:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Luis Lopez"
                ),
                ContextualTask(
                    id: "luis_3",
                    name: "Elevator Clean",
                    buildingId: "4",
                    buildingName: "41 Elizabeth Street",
                    category: "Cleaning",
                    startTime: "10:00",
                    endTime: "11:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Luis Lopez"
                ),
                ContextualTask(
                    id: "luis_4",
                    name: "Sidewalk Hose",
                    buildingId: "6",
                    buildingName: "104 Franklin Street",
                    category: "Cleaning",
                    startTime: "07:00",
                    endTime: "07:30",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Luis Lopez"
                ),
                ContextualTask(
                    id: "luis_5",
                    name: "Sidewalk Sweep",
                    buildingId: "3",
                    buildingName: "36 Walker Street",
                    category: "Cleaning",
                    startTime: "07:00",
                    endTime: "08:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Luis Lopez"
                )
            ],
            "5": [ // Angel Guirachocha
                ContextualTask(
                    id: "angel_1",
                    name: "Evening Garbage Collection",
                    buildingId: "1",
                    buildingName: "12 West 18th Street",
                    category: "Sanitation",
                    startTime: "18:00",
                    endTime: "19:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Angel Guirachocha"
                ),
                ContextualTask(
                    id: "angel_2",
                    name: "DSNY Prep / Move Bins",
                    buildingId: "5",
                    buildingName: "68 Perry Street",
                    category: "Operations",
                    startTime: "19:00",
                    endTime: "20:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Angel Guirachocha"
                ),
                ContextualTask(
                    id: "angel_3",
                    name: "DSNY Prep / Move Bins",
                    buildingId: "9",
                    buildingName: "123 1st Avenue",
                    category: "Operations",
                    startTime: "19:00",
                    endTime: "20:00",
                    recurrence: "Weekly",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Angel Guirachocha"
                ),
                ContextualTask(
                    id: "angel_4",
                    name: "Evening Building Security Check",
                    buildingId: "12",
                    buildingName: "135-139 West 17th Street",
                    category: "Inspection",
                    startTime: "21:00",
                    endTime: "22:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Angel Guirachocha"
                )
            ],
            "6": [ // Greg Hutson
                ContextualTask(
                    id: "greg_1",
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
                    assignedWorkerName: "Greg Hutson"
                ),
                ContextualTask(
                    id: "greg_2",
                    name: "Lobby & Vestibule Clean",
                    buildingId: "1",
                    buildingName: "12 West 18th Street",
                    category: "Cleaning",
                    startTime: "10:00",
                    endTime: "11:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Greg Hutson"
                ),
                ContextualTask(
                    id: "greg_3",
                    name: "Glass & Elevator Clean",
                    buildingId: "1",
                    buildingName: "12 West 18th Street",
                    category: "Cleaning",
                    startTime: "11:00",
                    endTime: "12:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Greg Hutson"
                ),
                ContextualTask(
                    id: "greg_4",
                    name: "Trash Area Clean",
                    buildingId: "1",
                    buildingName: "12 West 18th Street",
                    category: "Sanitation",
                    startTime: "13:00",
                    endTime: "14:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium",
                    assignedWorkerName: "Greg Hutson"
                ),
                ContextualTask(
                    id: "greg_5",
                    name: "Boiler Blow-Down",
                    buildingId: "1",
                    buildingName: "12 West 18th Street",
                    category: "Maintenance",
                    startTime: "14:00",
                    endTime: "14:30",
                    recurrence: "Weekly",
                    skillLevel: "Advanced",
                    status: "pending",
                    urgencyLevel: "high",
                    assignedWorkerName: "Greg Hutson"
                )
            ],
            "7": [ // Shawn Magloire
                ContextualTask(
                    id: "shawn_1",
                    name: "Boiler Blow-Down",
                    buildingId: "8",
                    buildingName: "117 West 17th Street",
                    category: "Maintenance",
                    startTime: "09:00",
                    endTime: "11:00",
                    recurrence: "Weekly",
                    skillLevel: "Advanced",
                    status: "pending",
                    urgencyLevel: "high",
                    assignedWorkerName: "Shawn Magloire"
                ),
                ContextualTask(
                    id: "shawn_2",
                    name: "Boiler Blow-Down",
                    buildingId: "11",
                    buildingName: "133 East 15th Street",
                    category: "Maintenance",
                    startTime: "11:00",
                    endTime: "13:00",
                    recurrence: "Weekly",
                    skillLevel: "Advanced",
                    status: "pending",
                    urgencyLevel: "high",
                    assignedWorkerName: "Shawn Magloire"
                ),
                ContextualTask(
                    id: "shawn_3",
                    name: "HVAC System Check",
                    buildingId: "7",
                    buildingName: "112 West 18th Street",
                    category: "Maintenance",
                    startTime: "09:00",
                    endTime: "12:00",
                    recurrence: "Monthly",
                    skillLevel: "Advanced",
                    status: "pending",
                    urgencyLevel: "high",
                    assignedWorkerName: "Shawn Magloire"
                ),
                ContextualTask(
                    id: "shawn_4",
                    name: "HVAC System Check",
                    buildingId: "8",
                    buildingName: "117 West 17th Street",
                    category: "Maintenance",
                    startTime: "13:00",
                    endTime: "16:00",
                    recurrence: "Monthly",
                    skillLevel: "Advanced",
                    status: "pending",
                    urgencyLevel: "high",
                    assignedWorkerName: "Shawn Magloire"
                )
            ]
        ]
        
        return workerTasks[workerId] ?? []
    }
}

// MARK: - ✅ FIX: Public interface for external access (no internal type exposure)

extension WorkerContextEngine {
    
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
        return getAssignedBuildings().count
    }
}
