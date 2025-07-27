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
        let workerName = getWorkerName(id: workerId)
        
        // FIX: Use the public getAllTasks() method instead of accessing private realWorldTasks
        let operationalData = await OperationalDataManager.shared
        let allTasks = await operationalData.getAllTasks()
        
        // Filter tasks for this worker
        let workerTasks = allTasks.filter { task in
            task.worker?.name == workerName
        }
        
        print("📊 Fallback: Found \(workerTasks.count) tasks for \(workerName) from operational data")
        return workerTasks
    }
    
    // MARK: - OperationalDataManager Conversion
    
    private func generateTasksFromOperationalData() async -> [ContextualTask] {
        // FIX: Use the public getAllTasks() method
        let operationalData = await OperationalDataManager.shared
        let tasks = await operationalData.getAllTasks()
        
        return tasks.sorted { task1, task2 in
            let urgency1 = task1.urgency?.numericValue ?? 0
            let urgency2 = task2.urgency?.numericValue ?? 0
            return urgency1 > urgency2
        }
    }
    
    // MARK: - Helper method for creating fallback task
    func createFallbackTask(
        title: String,
        buildingName: String,
        workerId: String,
        category: CoreTypes.TaskCategory
    ) async -> ContextualTask? {
        // Get building coordinate from building service
        let buildingService = BuildingService.shared
        var building: NamedCoordinate?
        
        do {
            let allBuildings = try await buildingService.getAllBuildings()
            building = allBuildings.first { b in
                b.name.lowercased().contains(buildingName.lowercased()) ||
                buildingName.lowercased().contains(b.name.lowercased())
            }
        } catch {
            print("⚠️ Could not find building for \(buildingName): \(error)")
        }
        
        // Get worker profile
        let workerService = WorkerService.shared
        var worker: WorkerProfile?
        
        do {
            worker = try await workerService.getWorkerProfile(for: workerId)
        } catch {
            print("⚠️ Could not find worker profile for \(workerId): \(error)")
        }
        
        // FIX: Use proper TaskUrgency value
        let urgency: CoreTypes.TaskUrgency = .medium // Changed from .normal
        
        // Calculate dates
        let dueDate = Calendar.current.date(byAdding: .hour, value: 4, to: Date())
        
        // FIX: Create ContextualTask with correct parameters
        return ContextualTask(
            id: UUID().uuidString,
            title: title,
            description: "Operational task: \(title) at \(buildingName)",
            isCompleted: false,
            completedDate: nil,
            dueDate: dueDate,
            category: category,
            urgency: urgency,
            building: building, // FIX: Pass NamedCoordinate, not String
            worker: worker,
            buildingId: building?.id
            // REMOVED: scheduledDate - not in ContextualTask constructor
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
    
    // FIX: Remove duplicate WorkerConstants and use inline method
    private func getWorkerName(id: String) -> String {
        let workerNames: [String: String] = [
            "1": "Greg Hutson",
            "2": "Edwin Lema",
            "4": "Kevin Dutan",
            "5": "Mercedes Inamagua",
            "6": "Luis Lopez",
            "7": "Angel Guirachocha",
            "8": "Shawn Magloire"
        ]
        
        return workerNames[id] ?? "Unknown Worker"
    }
}

// MARK: - TaskUrgency Extension for numeric value
extension CoreTypes.TaskUrgency {
    var numericValue: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .urgent: return 4
        case .critical: return 5
        case .emergency: return 6
        }
    }
}
