import Foundation
import SwiftUI


//  OperationalDataManager+DatabaseIntegration.swift
//  FrancoSphere v6.0
//
//  🚨 CRITICAL FIX: Connect OperationalDataManager real data to database
//  ✅ FIXED: Progress 0/0 issue by ensuring real tasks reach TaskService
//  ✅ ADDED: importRoutinesAndDSNY() method that was missing
//  ✅ ENHANCED: Kevin's Rubin Museum PRIMARY assignment
//

import Foundation
import GRDB

extension OperationalDataManager {
    
    // MARK: - Database Integration (CRITICAL FIX)
    
    /// Import all real-world tasks into the database
    /// This fixes the Progress 0/0 issue by ensuring TaskService has real data
    func importRoutinesAndDSNY() async throws -> (imported: Int, errors: [Error]) {
        print("🔄 Importing \(realWorldTasks.count) real-world tasks to database...")
        
        var importedCount = 0
        var errors: [Error] = []
        let manager = GRDBManager.shared
        
        // Clear existing routine tasks to avoid duplicates
        try await manager.execute("DELETE FROM routine_tasks")
        print("🗑️ Cleared existing routine tasks")
        
        // Import each real-world task
        for task in realWorldTasks {
            do {
                try await importSingleTask(task, using: manager)
                importedCount += 1
            } catch {
                errors.append(error)
                print("❌ Failed to import task: \(task.taskName) - \(error)")
            }
        }
        
        print("✅ Imported \(importedCount) tasks, \(errors.count) errors")
        return (imported: importedCount, errors: errors)
    }
    
    /// Import a single task with proper worker and building resolution
    private func importSingleTask(_ task: ContextualTask, using manager: GRDBManager) async throws {
        // Get worker ID from name
        guard let workerId = await getWorkerIdFromName(task.assignedWorker) else {
            throw ImportError.workerNotFound(task.assignedWorker)
        }
        
        // Get building ID from name
        guard let buildingId = await getBuildingIdFromName(task.building) else {
            throw ImportError.buildingNotFound(task.building)
        }
        
        // Create contextual task
        let contextualTask = createContextualTask(from: task, workerId: workerId, buildingId: buildingId)
        
        // Insert into database
        try await insertContextualTask(contextualTask, using: manager)
        
        print("✅ Imported: \(task.taskName) for \(task.assignedWorker) at \(task.building)")
    }
    
    /// Convert ContextualTask to ContextualTask
    private func createContextualTask(
        from realTask: ContextualTask, 
        workerId: String, 
        buildingId: String
    ) -> ContextualTask {
        
        let now = Date()
        let calendar = Calendar.current
        
        // Calculate next occurrence based on recurrence
        let nextDue = calculateNextDueDate(from: realTask, baseDate: now)
        
        return ContextualTask(
            id: UUID().uuidString,
            title: realTask.taskName,
            description: generateTaskDescription(from: realTask),
            buildingId: buildingId,
            buildingName: realTask.building,
            category: mapTaskCategory(realTask.category),
            urgency: mapTaskUrgency(realTask),
            skillLevel: mapWorkerSkill(realTask.skillLevel),
            estimatedDuration: TimeInterval(realTask.estimatedDuration ?? 3600),
            isCompleted: false,
            completedAt: nil,
            completedBy: nil,
            notes: generateTaskNotes(from: realTask),
            dueDate: nextDue,
            scheduledDate: nextDue,
            recurrencePattern: realTask.recurrence,
            priority: mapTaskPriority(from: realTask),
            assignedWorkerId: workerId,
            createdAt: now,
            updatedAt: now
        )
    }
    
    /// Insert ContextualTask into database
    private func insertContextualTask(_ task: ContextualTask, using manager: GRDBManager) async throws {
        try await manager.execute("""
            INSERT INTO routine_tasks (
                id, title, taskDescription, buildingId, category, urgency, 
                skillLevel, estimatedDuration, isCompleted, dueDate, 
                scheduledDate, recurrence, priority, workerId, createdAt, updatedAt
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, [
            task.id,
            task.title ?? "Untitled Task",
            task.description ?? "",
            task.buildingId ?? "",
            task.category?.rawValue ?? "maintenance",
            task.urgency?.rawValue ?? "medium",
            task.skillLevel?.rawValue ?? "intermediate",
            task.estimatedDuration,
            task.isCompleted ? 1 : 0,
            task.dueDate?.iso8601String ?? Date().iso8601String,
            task.scheduledDate?.iso8601String ?? Date().iso8601String,
            task.recurrencePattern ?? "once",
            task.priority?.rawValue ?? "medium",
            task.assignedWorkerId ?? "",
            task.createdAt?.iso8601String ?? Date().iso8601String,
            task.updatedAt?.iso8601String ?? Date().iso8601String
        ])
    }
    
    // MARK: - Helper Methods
    
    /// Get worker ID from worker name
    private func getWorkerIdFromName(_ workerName: String) async -> String? {
        let workerMapping: [String: String] = [
            "Greg Hutson": "1",
            "Edwin Lema": "2", 
            "Kevin Dutan": "4",
            "Mercedes Inamagua": "5",
            "Luis Lopez": "6",
            "Angel Guirachocha": "7",
            "Shawn Magloire": "8"
        ]
        
        return workerMapping[workerName]
    }
    
    /// Get building ID from building name
    private func getBuildingIdFromName(_ buildingName: String) async -> String? {
        // Kevin's buildings mapping (especially Rubin Museum)
        let buildingMapping: [String: String] = [
            "Rubin Museum": "rubin-museum",
            "117 West 17th Street": "117-west-17th",
            "123 1st Avenue": "123-1st-ave",
            "131 Perry Street": "131-perry",
            "133 East 15th Street": "133-east-15th",
            "135 West 17th Street": "135-west-17th",
            "136 West 17th Street": "136-west-17th",
            "138 West 17th Street": "138-west-17th",
            "Stuyvesant Cove Park": "stuyvesant-cove",
            "12 West 18th Street": "12-west-18th",
            "29-31 East 20th Street": "29-31-east-20th",
            "36 Walker Street": "36-walker",
            "41 Elizabeth Street": "41-elizabeth",
            "68 Perry Street": "68-perry",
            "104 Franklin Street": "104-franklin",
            "112 West 18th Street": "112-west-18th"
        ]
        
        return buildingMapping[buildingName]
    }
    
    /// Calculate next due date based on recurrence pattern
    private func calculateNextDueDate(from task: ContextualTask, baseDate: Date) -> Date {
        let calendar = Calendar.current
        
        switch task.recurrence.lowercased() {
        case "daily":
            return calendar.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate
        case "weekly":
            return calendar.date(byAdding: .weekOfYear, value: 1, to: baseDate) ?? baseDate
        case "monthly":
            return calendar.date(byAdding: .month, value: 1, to: baseDate) ?? baseDate
        case "as_needed":
            return calendar.date(byAdding: .day, value: 7, to: baseDate) ?? baseDate
        default:
            return baseDate
        }
    }
    
    /// Generate detailed task description
    private func generateTaskDescription(from task: ContextualTask) -> String {
        var description = task.taskName
        
        if let startHour = task.startHour, let endHour = task.endHour {
            description += "\n⏰ Scheduled: \(startHour):00 - \(endHour):00"
        }
        
        if let days = task.daysOfWeek, !days.isEmpty {
            description += "\n📅 Days: \(days)"
        }
        
        description += "\n🏢 Location: \(task.building)"
        description += "\n👷 Skill Level: \(task.skillLevel)"
        description += "\n📂 Category: \(task.category)"
        
        return description
    }
    
    /// Generate task notes with operational context
    private func generateTaskNotes(from task: ContextualTask) -> String {
        var notes = "Imported from operational data"
        
        if task.building.contains("Rubin") {
            notes += "\n🏛️ Cultural site - special handling required"
        }
        
        if task.category.contains("DSNY") {
            notes += "\n🗑️ DSNY coordination required"
        }
        
        if task.recurrence == "emergency" {
            notes += "\n🚨 Emergency response task"
        }
        
        return notes
    }
    
    // MARK: - Enum Mapping Methods
    
    private func mapTaskCategory(_ category: String) -> TaskCategory {
        switch category.lowercased() {
        case "cleaning", "sanitation":
            return .cleaning
        case "maintenance", "repair":
            return .maintenance
        case "inspection":
            return .inspection
        case "dsny", "garbage", "recycling":
            return .waste_management
        case "security":
            return .security
        default:
            return .maintenance
        }
    }
    
    private func mapTaskUrgency(_ task: ContextualTask) -> TaskUrgency {
        if task.taskName.lowercased().contains("emergency") {
            return .critical
        } else if task.taskName.lowercased().contains("urgent") {
            return .urgent
        } else if task.recurrence == "daily" {
            return .high
        }
        return .medium
    }
    
    private func mapWorkerSkill(_ skillLevel: String) -> WorkerSkill {
        switch skillLevel.lowercased() {
        case "basic", "entry":
            return .beginner
        case "intermediate", "standard":
            return .intermediate
        case "advanced", "expert":
            return .advanced
        case "specialist":
            return .expert
        default:
            return .intermediate
        }
    }
    
    private func mapTaskPriority(from task: ContextualTask) -> TaskPriority {
        if task.building.contains("Rubin") {
            return .high // Cultural site gets high priority
        } else if task.recurrence == "daily" {
            return .high
        } else if task.category.contains("emergency") {
            return .critical
        }
        return .medium
    }
}

// MARK: - Import Error Types

enum ImportError: LocalizedError {
    case workerNotFound(String)
    case buildingNotFound(String)
    case taskMappingFailed(String)
    case databaseInsertFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .workerNotFound(let name):
            return "Worker not found: \(name)"
        case .buildingNotFound(let name):
            return "Building not found: \(name)"
        case .taskMappingFailed(let task):
            return "Failed to map task: \(task)"
        case .databaseInsertFailed(let detail):
            return "Database insert failed: \(detail)"
        }
    }
}
