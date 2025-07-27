//
//  WorkerContextEngine.swift
//  FrancoSphere v6.0 - FIXED VERSION
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ ALIGNED: With actual service methods and types
//  ✅ MAINTAINED: @MainActor class with ObservableObject pattern
//

import Foundation
import CoreLocation
import Combine

@MainActor
public final class WorkerContextEngine: ObservableObject {
    public static let shared = WorkerContextEngine()
    
    // MARK: - Published Properties for SwiftUI Binding
    @Published public var currentWorker: WorkerProfile?
    @Published public var assignedBuildings: [NamedCoordinate] = []
    @Published public var portfolioBuildings: [NamedCoordinate] = []
    @Published public var todaysTasks: [ContextualTask] = []
    @Published public var taskProgress: CoreTypes.TaskProgress?
    @Published public var clockInStatus: (isClockedIn: Bool, building: NamedCoordinate?) = (false, nil)
    @Published public var isLoading = false
    @Published public var lastError: Error?
    
    // MARK: - Dependencies
    private let operationalData = OperationalDataManager.shared
    private let workerService = WorkerService.shared
    private let buildingService = BuildingService.shared
    private let clockInManager = ClockInManager.shared
    
    private init() {}
    
    // MARK: - Context Loading
    public func loadContext(for workerId: CoreTypes.WorkerID) async throws {
        guard !isLoading else { return }
        isLoading = true
        lastError = nil
        
        do {
            // Get worker profile
            let allWorkers = try await workerService.getAllActiveWorkers()
            guard let worker = allWorkers.first(where: { $0.id == workerId }) else {
                throw WorkerContextError.workerNotFound(workerId)
            }
            self.currentWorker = worker
            
            // Load operational data (not async)
            let workerName = WorkerConstants.getWorkerName(id: workerId)
            let workerAssignments = operationalData.getRealWorldTasks(for: workerName)
            
            // Build assigned buildings list
            var assignedBuildingsList: [NamedCoordinate] = []
            let uniqueBuildingNames = Set(workerAssignments.map { $0.building })
            
            for buildingName in uniqueBuildingNames {
                if let buildingId = await operationalData.getRealBuildingId(from: buildingName) {
                    do {
                        // ✅ FIXED: Use correct parameter label 'buildingId:' not 'by:'
                        if let building = try await buildingService.getBuilding(buildingId: buildingId) {
                            assignedBuildingsList.append(building)
                        }
                    } catch {
                        print("⚠️ Could not load building \(buildingName): \(error)")
                    }
                }
            }
            
            self.assignedBuildings = assignedBuildingsList
            self.portfolioBuildings = try await buildingService.getAllBuildings()
            
            // Generate tasks with correct type
            self.todaysTasks = await generateContextualTasks(
                for: workerId,
                workerName: workerName,
                assignedBuildings: assignedBuildingsList,
                realWorldAssignments: workerAssignments
            )
            
            // Calculate progress
            let completedTasks = todaysTasks.filter { $0.isCompleted }.count
            self.taskProgress = CoreTypes.TaskProgress(
                totalTasks: todaysTasks.count,
                completedTasks: completedTasks
            )
            
            // ✅ FIXED: getClockInStatus requires await because ClockInManager is an actor
            let clockStatus = await clockInManager.getClockInStatus(for: workerId)
            if let session = clockStatus.session {
                let building = NamedCoordinate(
                    id: session.buildingId,
                    name: session.buildingName,
                    // ✅ FIXED: Handle missing address property gracefully
                    address: "", // ClockInSession doesn't have address
                    latitude: session.location?.latitude ?? 0,
                    longitude: session.location?.longitude ?? 0
                )
                self.clockInStatus = (clockStatus.isClockedIn, building)
            } else {
                self.clockInStatus = (clockStatus.isClockedIn, nil)
            }
            
        } catch {
            lastError = error
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Task Generation
    // ✅ FIXED: Use correct type OperationalDataTaskAssignment (standalone type, not nested)
    private func generateContextualTasks(
        for workerId: String,
        workerName: String,
        assignedBuildings: [NamedCoordinate],
        realWorldAssignments: [OperationalDataTaskAssignment]
    ) async -> [ContextualTask] {
        var tasks: [ContextualTask] = []
        
        for (index, operational) in realWorldAssignments.enumerated() {
            let building = assignedBuildings.first { building in
                building.name.lowercased().contains(operational.building.lowercased()) ||
                operational.building.lowercased().contains(building.name.lowercased())
            }
            
            // ✅ FIXED: Use correct ContextualTask initializer matching actual signature
            let task = ContextualTask(
                id: "op_task_\(workerId)_\(index)",
                title: operational.taskName,
                description: "Operational assignment: \(operational.taskName) at \(operational.building)",
                isCompleted: false,
                completedDate: nil,
                dueDate: Date().addingTimeInterval(3600),
                category: mapOperationalCategory(operational.category),
                urgency: mapOperationalUrgency(operational.skillLevel),
                building: building,
                worker: currentWorker,
                buildingId: building?.id,
                priority: mapOperationalUrgency(operational.skillLevel)
                // ✅ FIXED: Removed extra arguments (buildingName, assignedWorkerId, assignedWorkerName)
            )
            
            tasks.append(task)
        }
        
        return tasks.sorted { task1, task2 in
            let urgency1 = task1.urgency?.numericValue ?? 0
            let urgency2 = task2.urgency?.numericValue ?? 0
            return urgency1 > urgency2
        }
    }
    
    // MARK: - Access Methods
    public func getCurrentWorker() -> WorkerProfile? { return currentWorker }
    public func getCurrentBuilding() -> NamedCoordinate? { return clockInStatus.building }
    public func getAssignedBuildings() -> [NamedCoordinate] { return assignedBuildings }
    public func getPortfolioBuildings() -> [NamedCoordinate] { return portfolioBuildings }
    public func getTodaysTasks() -> [ContextualTask] { return todaysTasks }
    public func getTaskProgress() -> CoreTypes.TaskProgress? { return taskProgress }
    
    // MARK: - Helper Methods
    private func mapOperationalCategory(_ category: String) -> TaskCategory? {
        switch category.lowercased() {
        case "cleaning": return .cleaning
        case "maintenance": return .maintenance
        case "repair": return .repair
        case "inspection": return .inspection
        case "landscaping": return .landscaping
        case "security": return .security
        case "sanitation": return .sanitation
        case "emergency": return .emergency
        default: return .maintenance
        }
    }
    
    private func mapOperationalUrgency(_ skillLevel: String) -> TaskUrgency? {
        switch skillLevel.lowercased() {
        case "basic": return .low
        case "intermediate": return .medium
        case "advanced": return .high
        case "expert", "critical": return .critical
        default: return .medium
        }
    }
}

// MARK: - Error Types
public enum WorkerContextError: Error, LocalizedError {
    case workerNotFound(String)
    case dataLoadingFailed(Error)
    case invalidConfiguration
    
    public var errorDescription: String? {
        switch self {
        case .workerNotFound(let id): return "Worker with ID \(id) not found"
        case .dataLoadingFailed(let error): return "Failed to load context data: \(error.localizedDescription)"
        case .invalidConfiguration: return "Invalid worker context configuration"
        }
    }
}

// MARK: - TaskUrgency Extension
extension TaskUrgency {
    var numericValue: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        case .emergency: return 5
        case .urgent: return 4
        }
    }
}
