//
//  TaskService+OperationalFallback.swift
//  FrancoSphere v6.0 - FIXED: OperationalDataManager Fallback
//
//  ✅ FALLBACK: When database is empty, use OperationalDataManager
//  ✅ REAL DATA: Converts operational tasks to ContextualTask objects
//

import Foundation

extension TaskService {
    
    /// FIXED: Get all tasks with OperationalDataManager fallback
    func getAllTasksWithOperationalFallback() async throws -> [ContextualTask] {
        // Try database first
        do {
            let dbTasks = try await getAllTasks()
            if !dbTasks.isEmpty {
                print("✅ Using database tasks: \(dbTasks.count)")
                return dbTasks
            }
        } catch {
            print("⚠️ Database query failed, falling back to operational data: \(error)")
        }
        
        // Fallback: Generate from OperationalDataManager
        print("📊 Fallback: Generating tasks from OperationalDataManager")
        return await generateTasksFromOperationalData()
    }
    
    /// FIXED: Get worker tasks with OperationalDataManager fallback
    func getTasksWithOperationalFallback(for workerId: String, date: Date) async throws -> [ContextualTask] {
        // Try database first
        do {
            let dbTasks = try await getTasks(for: workerId, date: date)
            if !dbTasks.isEmpty {
                print("✅ Using database tasks for worker \(workerId): \(dbTasks.count)")
                return dbTasks
            }
        } catch {
            print("⚠️ Database worker tasks failed, falling back to operational data: \(error)")
        }
        
        // Fallback: Generate from OperationalDataManager
        let workerName = WorkerConstants.getWorkerName(id: workerId)
        let operationalData = OperationalDataManager.shared
        let workerTasks = await operationalData.realWorldTasks.filter { 
            $0.assignedWorker == workerName 
        }
        
        print("📊 Fallback: Generating \(workerTasks.count) tasks for \(workerName) from operational data")
        return await convertOperationalTasks(workerTasks, workerId: workerId)
    }
    
    // MARK: - OperationalDataManager Conversion
    
    private func generateTasksFromOperationalData() async -> [ContextualTask] {
        let operationalData = OperationalDataManager.shared
        var tasks: [ContextualTask] = []
        
        for (index, opTask) in await operationalData.realWorldTasks.enumerated() {
            if let contextualTask = await convertOperationalTask(opTask, index: index) {
                tasks.append(contextualTask)
            }
        }
        
        return tasks.sorted { task1, task2 in
            let urgency1 = task1.urgency?.numericValue ?? 0
            let urgency2 = task2.urgency?.numericValue ?? 0
            return urgency1 > urgency2
        }
    }
    
    private func convertOperationalTasks(_ opTasks: [OperationalDataTaskAssignment], workerId: String) async -> [ContextualTask] {
        var tasks: [ContextualTask] = []
        
        for (index, opTask) in opTasks.enumerated() {
            if let contextualTask = await convertOperationalTask(opTask, index: index, workerId: workerId) {
                tasks.append(contextualTask)
            }
        }
        
        return tasks
    }
    
    private func convertOperationalTask(_ opTask: OperationalDataTaskAssignment, index: Int, workerId: String? = nil) async -> ContextualTask? {
        // Get building ID from building service
        let buildingService = BuildingService.shared
        var buildingId: String?
        
        do {
            let allBuildings = try await buildingService.getAllBuildings()
            let building = allBuildings.first { building in
                building.name.lowercased().contains(opTask.building.lowercased()) ||
                opTask.building.lowercased().contains(building.name.lowercased())
            }
            buildingId = building?.id
        } catch {
            print("⚠️ Could not get building for \(opTask.building): \(error)")
        }
        
        // Map category
        let category: CoreTypes.TaskCategory
        switch opTask.category.lowercased() {
        case "cleaning": category = .cleaning
        case "maintenance": category = .maintenance
        case "inspection": category = .inspection
        case "security": category = .security
        case "sanitation": category = .cleaning
        default: category = .maintenance
        }
        
        // Map urgency
        let urgency: CoreTypes.TaskUrgency
        switch opTask.skillLevel.lowercased() {
        case "advanced", "critical": urgency = .critical
        case "intermediate": urgency = .urgent
        default: urgency = .normal
        }
        
        // Calculate dates
        let scheduledDate = calculateScheduledDate(for: opTask.recurrence)
        let dueDate = Calendar.current.date(byAdding: .hour, value: 4, to: scheduledDate)
        
        // Create unique ID
        let taskId = workerId != nil ? 
            "op_\(workerId!)_\(index)" : 
            "op_global_\(index)_\(opTask.building.hash)"
        
        return ContextualTask(
            id: taskId,
            title: opTask.taskName,
            description: "Operational task: \(opTask.taskName) at \(opTask.building)",
            buildingId: buildingId,
            buildingName: opTask.building,
            category: category,
            urgency: urgency,
            isCompleted: false,
            scheduledDate: scheduledDate,
            dueDate: dueDate
        )
    }
    
    private func calculateScheduledDate(for recurrence: String) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch recurrence.lowercased() {
        case "daily":
            return calendar.startOfDay(for: now)
        case "weekly":
            return calendar.date(byAdding: .day, value: 1, to: now) ?? now
        case "monthly":
            return calendar.date(byAdding: .day, value: 7, to: now) ?? now
        default:
            return now
        }
    }
}

// MARK: - WorkerConstants (if not in other file)

public struct WorkerConstants {
    public static let workerNames: [String: String] = [
        "1": "Greg Hutson",
        "2": "Edwin Lema", 
        "4": "Kevin Dutan",
        "5": "Mercedes Inamagua",
        "6": "Luis Lopez",
        "7": "Angel Guirachocha",
        "8": "Shawn Magloire"
    ]
    
    public static func getWorkerName(id: String) -> String {
        return workerNames[id] ?? "Unknown Worker"
    }
}
