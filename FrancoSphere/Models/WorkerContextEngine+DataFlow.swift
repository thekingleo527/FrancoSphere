//
//  WorkerContextEngine+DataFlow.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/16/25.
//

//  WorkerContextEngine+DataFlow.swift
//  FrancoSphere v6.0
//
//  ✅ FIXES: Connects WorkerContextEngine to OperationalDataManager
//  ✅ ADDS: Real data flow from operational tasks
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
            // Get worker name from constants
            let workerName = WorkerConstants.getWorkerName(id: workerId)
            
            // Load worker profile
            let profile = try await workerService.getWorkerProfile(for: workerId)
            self.currentWorker = profile
            
            // Get REAL tasks from OperationalDataManager
            let operationalData = await OperationalDataManager.shared
            let workerTasks = await operationalData.realWorldTasks.filter {
                $0.assignedWorker == workerName
            }
            
            print("📊 Found \(workerTasks.count) operational tasks for \(workerName)")
            
            // Extract unique buildings from tasks
            var uniqueBuildingNames = Set<String>()
            for task in workerTasks {
                uniqueBuildingNames.insert(task.building)
            }
            
            // Convert building names to NamedCoordinate objects
            var buildings: [NamedCoordinate] = []
            for buildingName in uniqueBuildingNames {
                if let buildingId = await operationalData.getRealBuildingId(from: buildingName) {
                    do {
                        let building = try await buildingService.getBuilding(buildingId: buildingId)
                        buildings.append(building)
                    } catch {
                        print("⚠️ Could not load building \(buildingName): \(error)")
                    }
                }
            }
            
            self.assignedBuildings = buildings
            print("✅ Loaded \(buildings.count) assigned buildings")
            
            // Load all portfolio buildings for coverage
            self.portfolioBuildings = try await buildingService.getAllBuildings()
            
            // Convert operational tasks to contextual tasks
            var contextualTasks: [ContextualTask] = []
            for (index, opTask) in workerTasks.enumerated() {
                let building = buildings.first { $0.name.contains(opTask.building) }
                
                let task = ContextualTask(
                    id: "task_\(workerId)_\(index)",
                    title: opTask.taskName,
                    description: "Recurring: \(opTask.recurrence)",
                    buildingId: building?.id,
                    buildingName: opTask.building,
                    category: mapToTaskCategory(opTask.category),
                    urgency: mapToUrgency(opTask.skillLevel),
                    skillLevel: mapToSkillLevel(opTask.skillLevel),
                    estimatedDuration: 3600, // 1 hour default
                    isCompleted: false,
                    completedAt: nil,
                    completedBy: nil,
                    notes: nil
                )
                contextualTasks.append(task)
            }
            
            self.todaysTasks = contextualTasks
            print("✅ Created \(contextualTasks.count) contextual tasks")
            
            // Update task progress
            let completedCount = contextualTasks.filter { $0.isCompleted }.count
            self.taskProgress = TaskProgress(
                completedTasks: completedCount,
                totalTasks: contextualTasks.count,
                progressPercentage: contextualTasks.isEmpty ? 0 : Double(completedCount) / Double(contextualTasks.count) * 100
            )
            
            // Clock-in status
            let status = await ClockInManager.shared.getClockInStatus(for: workerId)
            if let session = status.session {
                let building = buildings.first { $0.id == session.buildingId } ?? NamedCoordinate(
                    id: session.buildingId,
                    name: session.buildingName,
                    latitude: session.location?.latitude ?? 0,
                    longitude: session.location?.longitude ?? 0
                )
                self.clockInStatus = (true, building)
            } else {
                self.clockInStatus = (false, nil)
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
    
    private func mapToTaskCategory(_ category: String) -> TaskCategory {
        switch category.lowercased() {
        case "maintenance": return .maintenance
        case "cleaning": return .cleaning
        case "security": return .security
        case "inventory": return .inventory
        case "emergency": return .emergency
        default: return .other
        }
    }
    
    private func mapToUrgency(_ skillLevel: String) -> TaskUrgency? {
        switch skillLevel.lowercased() {
        case "specialized", "advanced": return .high
        case "intermediate": return .normal
        case "basic": return .low
        default: return .normal
        }
    }
    
    private func mapToSkillLevel(_ level: String) -> SkillLevel {
        switch level.lowercased() {
        case "specialized", "advanced": return .advanced
        case "intermediate": return .intermediate
        case "basic": return .basic
        default: return .basic
        }
    }
}

// MARK: - Update Main loadContext to use operational data

extension WorkerContextEngine {
    /// Override existing loadContext to use operational data
    public func loadContext(for workerId: CoreTypes.WorkerID) async throws {
        // Use the new operational data method
        try await loadContextWithOperationalData(for: workerId)
    }
}
