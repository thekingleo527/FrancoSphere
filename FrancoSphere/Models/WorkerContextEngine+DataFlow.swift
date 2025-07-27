//
//  WorkerContextEngine+DataFlow.swift
//  FrancoSphere v6.0
//
//  ✅ FIXES: Connects WorkerContextEngine to OperationalDataManager
//  ✅ ADDS: Real data flow from operational tasks
//  ✅ FIXED: All compilation errors resolved
//

import Foundation

extension WorkerContextEngine {
    
    /// Load context with REAL operational data
    public func loadContextWithOperationalData(for workerId: CoreTypes.WorkerID) async throws {
        guard !isLoading else { return }
        isLoading = true
        lastError = nil
        
        print("🔄 Loading context with operational data for worker: \(workerId)")
        
        do {
            // Get worker name from constants - avoid ambiguity by using static method directly
            let workerName = WorkerConstants.nameMapping[workerId] ?? "Unknown Worker"
            
            // Load worker profile - these services are private, so we need to use public methods
            let allWorkers = try await WorkerService.shared.getAllActiveWorkers()
            guard let profile = allWorkers.first(where: { $0.id == workerId }) else {
                throw WorkerContextError.workerNotFound(workerId)
            }
            self.currentWorker = profile
            
            // Get REAL tasks from OperationalDataManager
            let operationalData = OperationalDataManager.shared
            let allTasks = await operationalData.getRealWorldTasks(for: workerName)
            
            print("📊 Found \(allTasks.count) operational tasks for \(workerName)")
            
            // Extract unique buildings from tasks
            var uniqueBuildingNames = Set<String>()
            for task in allTasks {
                uniqueBuildingNames.insert(task.building)
            }
            
            // Convert building names to NamedCoordinate objects
            var buildings: [NamedCoordinate] = []
            for buildingName in uniqueBuildingNames {
                if let buildingId = await operationalData.getRealBuildingId(from: buildingName) {
                    do {
                        let building = try await BuildingService.shared.getBuilding(buildingId: buildingId)
                        buildings.append(building)
                    } catch {
                        print("⚠️ Could not load building \(buildingName): \(error)")
                    }
                }
            }
            
            self.assignedBuildings = buildings
            print("✅ Loaded \(buildings.count) assigned buildings")
            
            // Load all portfolio buildings for coverage
            self.portfolioBuildings = try await BuildingService.shared.getAllBuildings()
            
            // Convert operational tasks to contextual tasks
            var contextualTasks: [ContextualTask] = []
            for (index, opTask) in allTasks.enumerated() {
                let building = buildings.first { $0.name.contains(opTask.building) }
                
                // Use the correct ContextualTask initializer from FrancoSphereModels
                let task = ContextualTask(
                    id: "task_\(workerId)_\(index)",
                    title: opTask.taskName,
                    description: "Recurring: \(opTask.recurrence)",
                    isCompleted: false,
                    completedDate: nil,
                    dueDate: Date().addingTimeInterval(3600), // 1 hour from now
                    category: mapToTaskCategory(opTask.category),
                    urgency: mapToUrgency(opTask.skillLevel),
                    building: nil,  // We have the building object but can set it
                    worker: nil,     // We have the worker profile but can set it
                    buildingId: building?.id,
                    priority: mapToUrgency(opTask.skillLevel),  // Use same as urgency
                    buildingName: opTask.building,
                    assignedWorkerId: workerId,
                    assignedWorkerName: workerName,
                    estimatedDuration: 3600  // 1 hour default
                )
                contextualTasks.append(task)
            }
            
            self.todaysTasks = contextualTasks
            print("✅ Created \(contextualTasks.count) contextual tasks")
            
            // Update task progress
            let completedCount = contextualTasks.filter { $0.isCompleted }.count
            self.taskProgress = CoreTypes.TaskProgress(
                totalTasks: contextualTasks.count,
                completedTasks: completedCount
            )
            
            // Clock-in status
            let status = await ClockInManager.shared.getCurrentSession(for: workerId)
            if let session = status.session {
                let building = buildings.first { $0.id == session.buildingId } ?? NamedCoordinate(
                    id: session.buildingId ?? "unknown",
                    name: session.buildingName ?? "Unknown Building",
                    address: session.address ?? "",
                    latitude: session.location?.latitude ?? 0,
                    longitude: session.location?.longitude ?? 0
                )
                self.clockInStatus = (status.isClockedIn, building)
            } else {
                self.clockInStatus = (status.isClockedIn, nil)
            }
            
            print("✅ Context loaded successfully with operational data")
            
        } catch {
            lastError = error
            print("❌ loadContextWithOperationalData failed: \(error)")
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    private func mapToTaskCategory(_ category: String) -> CoreTypes.TaskCategory {
        switch category.lowercased() {
        case "maintenance": return .maintenance
        case "cleaning": return .cleaning
        case "security": return .security
        case "inspection": return .inspection
        case "emergency": return .emergency
        // Map inventory and other to existing categories
        case "inventory": return .inspection  // Closest match
        default: return .maintenance  // Default fallback
        }
    }
    
    private func mapToUrgency(_ skillLevel: String) -> CoreTypes.TaskUrgency? {
        switch skillLevel.lowercased() {
        case "specialized", "advanced": return .high
        case "intermediate": return .medium
        case "basic": return .low
        default: return .medium
        }
    }
    
    private func mapToSkillLevel(_ level: String) -> CoreTypes.SkillLevel {
        switch level.lowercased() {
        case "specialized", "advanced": return .advanced
        case "intermediate": return .intermediate
        default: return .intermediate  // Default to intermediate
        }
    }
}

// MARK: - Main loadContext Override

extension WorkerContextEngine {
    /// Override to use operational data method
    /// This replaces the duplicate loadContext method that was causing conflicts
    public func loadContextWithOperational(for workerId: CoreTypes.WorkerID) async throws {
        try await loadContextWithOperationalData(for: workerId)
    }
}
