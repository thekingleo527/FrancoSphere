//
//  WorkerContextEngine.swift
//  FrancoSphere v6.0 - FIXED VERSION
//
//  ✅ CHANGED: From actor to @MainActor class with ObservableObject
//  ✅ FIXED: All multiple await syntax errors
//  ✅ ADDED: @Published properties for SwiftUI binding
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
            
            // Load operational data
            let workerName = WorkerConstants.getWorkerName(id: workerId)
            let workerAssignments = await operationalData.getRealWorldTasks(for: workerName)
            
            // Build assigned buildings list
            var assignedBuildingsList: [NamedCoordinate] = []
            let uniqueBuildingNames = Set(workerAssignments.map { $0.building })
            
            for buildingName in uniqueBuildingNames {
                if let buildingId = await operationalData.getRealBuildingId(from: buildingName) {
                    do {
                        let building = try await buildingService.getBuilding(buildingId: buildingId)
                        assignedBuildingsList.append(building)
                    } catch {
                        print("⚠️ Could not load building \(buildingName): \(error)")
                    }
                }
            }
            
            self.assignedBuildings = assignedBuildingsList
            self.portfolioBuildings = try await buildingService.getAllBuildings()
            
            // Generate tasks
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
            
            // Get clock-in status
            let clockStatus = await clockInManager.getCurrentSession(for: workerId)
            if let session = clockStatus.session {
                let building = NamedCoordinate(
                    id: session.buildingId ?? "unknown",
                    name: session.buildingName ?? "Unknown Building",
                    address: session.address ?? "",
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
    private func generateContextualTasks(
        for workerId: String,
        workerName: String,
        assignedBuildings: [NamedCoordinate],
        realWorldAssignments: [LegacyTaskAssignment]
    ) async -> [ContextualTask] {
        var tasks: [ContextualTask] = []
        
        for (index, operational) in realWorldAssignments.enumerated() {
            let building = assignedBuildings.first { building in
                building.name.lowercased().contains(operational.building.lowercased()) ||
                operational.building.lowercased().contains(building.name.lowercased())
            }
            
            let task = ContextualTask(
                id: "op_task_\(workerId)_\(index)",
                title: operational.taskName,
                description: "Operational assignment: \(operational.taskName) at \(operational.building)",
                isCompleted: false,
                scheduledDate: Date(),
                dueDate: Date().addingTimeInterval(3600),
                category: mapOperationalCategory(operational.category),
                urgency: mapOperationalUrgency(operational.skillLevel),
                buildingId: building?.id,
                buildingName: operational.building
            )
            
            tasks.append(task)
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
    private func mapOperationalCategory(_ category: String) -> TaskCategory {
        switch category.lowercased() {
        case "cleaning": return .cleaning
        case "maintenance": return .maintenance
        case "repair": return .repair
        case "inspection": return .inspection
        case "landscaping": return .landscaping
        case "security": return .security
        default: return .maintenance
        }
    }
    
    private func mapOperationalUrgency(_ skillLevel: String) -> TaskUrgency {
        switch skillLevel.lowercased() {
        case "basic": return .low
        case "intermediate": return .medium
        case "advanced": return .high
        case "expert": return .critical
        default: return .medium
        }
    }
}

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
