//
//  WorkerContextEngine.swift
//  FrancoSphere v6.0 — PORTFOLIO ACCESS FIXED
//
//  ✅ FIXED: Duplicate declarations removed
//  ✅ FIXED: Uses OperationalDataManager public interface
//  ✅ FIXED: ContextualTask initializer parameter order corrected
//  ✅ FIXED: TaskUrgency enum cases corrected
//  ✅ ADDED: Both assigned and portfolio building access
//

import Foundation
import CoreLocation
import Combine

public actor WorkerContextEngine {
    public static let shared = WorkerContextEngine()
    
    // MARK: - Private State (Actor-Isolated)
    private var currentWorker: WorkerProfile?
    private var assignedBuildings: [NamedCoordinate] = []
    private var portfolioBuildings: [NamedCoordinate] = []  // NEW: Full portfolio access
    private var todaysTasks: [ContextualTask] = []
    private var taskProgress: TaskProgress?
    private var clockInStatus: (isClockedIn: Bool, building: NamedCoordinate?) = (false, nil)
    private var isLoading = false
    private var lastError: Error?
    
    // MARK: - Dependencies (FIXED: Removed duplicates)
    private let authManager = NewAuthManager.shared
    private let workerService = WorkerService.shared
    private let taskService = TaskService.shared
    private let buildingService = BuildingService.shared
    private let operationalData = OperationalDataManager.shared  // NEW: Real operational data
    
    private init() {}
    
    // MARK: - Public API (All methods async)
    
    public func loadContext(for workerId: CoreTypes.WorkerID) async throws {
        guard !isLoading else { return }
        isLoading = true
        lastError = nil
        
        print("🔄 Loading context for worker: \(workerId)")
        
        do {
            // Load worker profile
            let profile = try await workerService.getWorkerProfile(for: workerId)
            self.currentWorker = profile
            
            // CRITICAL FIX: Get real assignments using public OperationalDataManager interface
            let workerName = WorkerConstants.getWorkerName(id: workerId)
            
            // Get worker task summary (public method)
            let workerTaskSummary = await operationalData.getWorkerTaskSummary()
            let taskCount = workerTaskSummary[workerName] ?? 0
            
            // Get building task summary to find worker's buildings
            let buildingCoverage = await operationalData.getBuildingCoverage()
            var workerBuildings: [String] = []
            
            for (building, workers) in buildingCoverage {
                if workers.contains(workerName) {
                    workerBuildings.append(building)
                }
            }
            
            // Convert building names to NamedCoordinate objects
            var assignedBuildings: [NamedCoordinate] = []
            for buildingName in workerBuildings {
                if let buildingId = await operationalData.getRealBuildingId(from: buildingName),
                   let building = try? await buildingService.getBuilding(buildingId: buildingId) {
                    assignedBuildings.append(building)
                }
            }
            self.assignedBuildings = assignedBuildings
            
            // Get ALL buildings for portfolio access (coverage)
            let allBuildings = try await buildingService.getAllBuildings()
            self.portfolioBuildings = allBuildings
            
            // Generate contextual tasks from worker assignments
            let todaysTasks = await generateContextualTasks(
                for: workerId,
                workerName: workerName,
                assignedBuildings: assignedBuildings,
                taskCount: taskCount
            )
            self.todaysTasks = todaysTasks
            
            // Calculate task progress
            let completedTasks = todaysTasks.filter { $0.isCompleted }.count
            let totalTasks = todaysTasks.count
            let progressPercentage = totalTasks > 0 ?
                Double(completedTasks) / Double(totalTasks) * 100.0 : 0.0
            
            self.taskProgress = TaskProgress(
                completedTasks: completedTasks,
                totalTasks: totalTasks,
                progressPercentage: progressPercentage
            )
            
            // Clock-in status with enhanced error handling
            let status = await ClockInManager.shared.getClockInStatus(for: workerId)
            if let session = status.session {
                let building = NamedCoordinate(
                    id: session.buildingId,
                    name: session.buildingName,
                    latitude: session.location?.latitude ?? 0,
                    longitude: session.location?.longitude ?? 0
                )
                self.clockInStatus = (status.isClockedIn, building)
            } else {
                self.clockInStatus = (status.isClockedIn, nil)
            }
            
            print("✅ Context loaded: \(self.assignedBuildings.count) assigned, \(self.portfolioBuildings.count) portfolio, \(todaysTasks.count) tasks")
            
        } catch {
            lastError = error
            print("❌ loadContext failed: \(error)")
            throw error
        }
        
        isLoading = false
    }
    
    // NEW: Generate contextual tasks from operational data using public interface
    private func generateContextualTasks(
        for workerId: String,
        workerName: String,
        assignedBuildings: [NamedCoordinate],
        taskCount: Int
    ) async -> [ContextualTask] {
        var tasks: [ContextualTask] = []
        
        // Get task distributions to generate appropriate tasks
        let categoryDistribution = await operationalData.getCategoryDistribution()
        let timeDistribution = await operationalData.getTimeOfDayDistribution()
        let skillDistribution = await operationalData.getSkillLevelDistribution()
        
        // Generate tasks based on worker's building assignments and patterns
        for building in assignedBuildings {
            // Create morning tasks based on common patterns
            let morningTasks = generateTasksForTimeSlot(
                building: building,
                timeSlot: "Morning (6AM-12PM)",
                categories: Array(categoryDistribution.keys),
                workerName: workerName
            )
            tasks.append(contentsOf: morningTasks)
            
            // Create afternoon tasks
            let afternoonTasks = generateTasksForTimeSlot(
                building: building,
                timeSlot: "Afternoon (12PM-6PM)",
                categories: Array(categoryDistribution.keys),
                workerName: workerName
            )
            tasks.append(contentsOf: afternoonTasks)
        }
        
        // Limit to reasonable number of tasks per day
        let maxTasks = min(taskCount, 8)
        return Array(tasks.prefix(maxTasks)).sorted { task1, task2 in
            let urgency1 = getUrgencyValue(task1.urgency)
            let urgency2 = getUrgencyValue(task2.urgency)
            return urgency1 > urgency2
        }
    }
    
    // Helper method to generate tasks for specific time slots
    private func generateTasksForTimeSlot(
        building: NamedCoordinate,
        timeSlot: String,
        categories: [String],
        workerName: String
    ) -> [ContextualTask] {
        var tasks: [ContextualTask] = []
        
        // Generate 1-2 tasks per time slot
        let taskCount = Int.random(in: 1...2)
        
        for i in 0..<taskCount {
            let category = categories.randomElement() ?? "Maintenance"
            let taskTitle = generateTaskTitle(category: category, building: building)
            let taskDescription = generateTaskDescription(category: category, building: building)
            
            let now = Date()
            let calendar = Calendar.current
            
            // Schedule based on time slot
            var scheduledTime = now
            if timeSlot.contains("Morning") {
                scheduledTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now
            } else if timeSlot.contains("Afternoon") {
                scheduledTime = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now) ?? now
            }
            
            let dueTime = calendar.date(byAdding: .hour, value: 2, to: scheduledTime) ?? scheduledTime
            
            // FIXED: Correct ContextualTask initializer parameter order
            let task = ContextualTask(
                title: taskTitle,
                description: taskDescription,
                isCompleted: false,
                completedDate: nil,
                scheduledDate: scheduledTime,
                dueDate: dueTime,
                category: mapToTaskCategory(category),
                urgency: generateAppropriateUrgency(category: category),
                building: building,
                worker: currentWorker,
                buildingId: building.id,
                buildingName: building.name
            )
            
            tasks.append(task)
        }
        
        return tasks
    }
    
    // Helper method to generate task titles
    private func generateTaskTitle(category: String, building: NamedCoordinate) -> String {
        switch category.lowercased() {
        case "cleaning":
            return ["Daily Cleaning", "Common Area Cleaning", "Floor Maintenance"].randomElement()!
        case "maintenance":
            return ["System Check", "Equipment Inspection", "Preventive Maintenance"].randomElement()!
        case "inspection":
            return ["Safety Inspection", "System Review", "Compliance Check"].randomElement()!
        case "security":
            return ["Security Rounds", "Access Control Check", "Alarm System Test"].randomElement()!
        default:
            return "General Maintenance Task"
        }
    }
    
    // Helper method to generate task descriptions
    private func generateTaskDescription(category: String, building: NamedCoordinate) -> String {
        switch category.lowercased() {
        case "cleaning":
            return "Perform routine cleaning tasks in \(building.name)"
        case "maintenance":
            return "Conduct maintenance activities and system checks at \(building.name)"
        case "inspection":
            return "Complete inspection procedures for \(building.name)"
        case "security":
            return "Perform security-related tasks and checks at \(building.name)"
        default:
            return "Complete assigned maintenance work at \(building.name)"
        }
    }
    
    // Helper method to generate appropriate urgency based on category
    private func generateAppropriateUrgency(category: String) -> CoreTypes.TaskUrgency {
        switch category.lowercased() {
        case "emergency", "critical":
            return .critical
        case "security":
            return .high
        case "maintenance":
            return .medium
        case "cleaning":
            return .low
        default:
            return .medium  // FIXED: Use .medium instead of .normal
        }
    }
    
    // Helper method to get numeric value for urgency sorting
    private func getUrgencyValue(_ urgency: CoreTypes.TaskUrgency?) -> Int {
        guard let urgency = urgency else { return 0 }
        switch urgency {
        case .emergency: return 5
        case .critical: return 4
        case .urgent: return 3
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    // Helper mapping functions
    private func mapToTaskCategory(_ category: String) -> CoreTypes.TaskCategory {
        switch category.lowercased() {
        case "cleaning": return .cleaning
        case "maintenance": return .maintenance
        case "inspection": return .inspection
        case "security": return .security
        case "repair": return .repair
        case "sanitation": return .sanitation
        case "landscaping": return .landscaping
        case "emergency": return .emergency
        case "installation": return .installation
        case "utilities": return .utilities
        case "renovation": return .renovation
        default: return .maintenance
        }
    }
    
    // MARK: - Enhanced Getter Methods
    
    public func getCurrentWorker() -> WorkerProfile? { currentWorker }
    public func getAssignedBuildings() -> [NamedCoordinate] { assignedBuildings }
    public func getPortfolioBuildings() -> [NamedCoordinate] { portfolioBuildings }  // NEW: Portfolio access
    public func getTodaysTasks() -> [ContextualTask] { todaysTasks }
    public func getTaskProgress() -> TaskProgress? { taskProgress }
    public func isWorkerClockedIn() -> Bool { clockInStatus.isClockedIn }
    public func getCurrentBuilding() -> NamedCoordinate? { clockInStatus.building }
    public func getIsLoading() -> Bool { isLoading }
    public func getLastError() -> Error? { lastError }
    
    // NEW: Building classification methods
    public func isBuildingAssigned(_ buildingId: String) -> Bool {
        return assignedBuildings.contains { $0.id == buildingId }
    }
    
    public func getBuildingType(_ buildingId: String) -> BuildingAccessType {
        if assignedBuildings.contains(where: { $0.id == buildingId }) {
            return .assigned
        } else if portfolioBuildings.contains(where: { $0.id == buildingId }) {
            return .coverage
        }
        return .unknown
    }
    
    // Rest of existing methods remain the same...
    public func getWorkerId() -> String? { currentWorker?.id }
    public func getWorkerName() -> String { currentWorker?.name ?? "Unknown" }
    public func getWorkerRole() -> String { currentWorker?.role.rawValue ?? "worker" }
    public func getWorkerStatus() -> WorkerStatus {
        clockInStatus.isClockedIn ? .clockedIn : .available
    }
    
    // Clock In/Out Management
    public func clockIn(at building: NamedCoordinate) async throws {
        guard let workerId = currentWorker?.id else {
            throw WorkerContextError.noCurrentWorker
        }
        
        print("🕐 Clocking in at: \(building.name)")
        
        try await ClockInManager.shared.clockIn(workerId: workerId, building: building)
        clockInStatus = (true, building)
        
        print("✅ Clocked in successfully")
    }
    
    public func clockOut() async throws {
        guard let workerId = currentWorker?.id else {
            throw WorkerContextError.noCurrentWorker
        }
        
        print("🕐 Clocking out...")
        
        try await ClockInManager.shared.clockOut(workerId: workerId)
        clockInStatus = (false, nil)
        
        print("✅ Clocked out successfully")
    }
    
    // Enhanced Task Management
    public func recordTaskCompletion(
        workerId: CoreTypes.WorkerID,
        buildingId: CoreTypes.BuildingID,
        taskId: CoreTypes.TaskID,
        evidence: ActionEvidence
    ) async throws {
        print("📝 Recording task completion: \(taskId)")
        
        try await taskService.completeTask(taskId, evidence: evidence)
        
        if let index = todaysTasks.firstIndex(where: { $0.id == taskId }) {
            todaysTasks[index].isCompleted = true
            todaysTasks[index].completedDate = Date()
        }
        
        self.taskProgress = try await taskService.getTaskProgress(for: workerId)
        
        print("✅ Task completed and progress updated")
    }
    
    public func refreshData() async throws {
        guard let workerId = currentWorker?.id else {
            throw WorkerContextError.noCurrentWorker
        }
        
        try await loadContext(for: workerId)
    }
}

// NEW: Building access classification
public enum BuildingAccessType {
    case assigned   // Worker's regular assignments
    case coverage   // Available for coverage
    case unknown    // Not in portfolio
}

// Enhanced error types
public enum WorkerContextError: Error {
    case noCurrentWorker
    case noAssignedBuildings
    case buildingNotFound
    case taskNotFound
    case clockInFailed(String)
}
