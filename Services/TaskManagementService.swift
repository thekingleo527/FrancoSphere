//
//  TaskManagementService.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/30/25.
//

import Foundation
import SwiftUI

/// Service for managing all task-related operations
actor TaskManagementService {
    static let shared = TaskManagementService()
    
    private var database: SQLiteManager?
    
    private init() {
        Task {
            await initializeDatabase()
        }
    }
    
    // MARK: - Database Setup
    
    private func initializeDatabase() async {
        do {
            database = try await SQLiteManager.start()
            await createTablesIfNeeded()
            await importCSVDataIfNeeded()
        } catch {
            print("Failed to initialize database: \(error)")
        }
    }
    
    private func createTablesIfNeeded() async {
        await createMasterTasksTable()
        await createTaskAssignmentsTable()
        await createTaskCompletionLogTable()
    }
    
    private func createMasterTasksTable() async {
        guard let database = database else { return }
        
        do {
            try await database.execute("""
            CREATE TABLE IF NOT EXISTS master_tasks (
                taskID TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                category TEXT NOT NULL,
                skillRequired TEXT NOT NULL,
                recurrence TEXT NOT NULL,
                description TEXT,
                urgency TEXT NOT NULL
            )
            """)
        } catch {
            print("Error creating master_tasks table: \(error)")
        }
    }
    
    private func createTaskAssignmentsTable() async {
        guard let database = database else { return }
        
        do {
            try await database.execute("""
            CREATE TABLE IF NOT EXISTS task_assignments (
                id TEXT PRIMARY KEY,
                buildingID TEXT NOT NULL,
                taskName TEXT NOT NULL,
                workerID TEXT NOT NULL,
                recurrence TEXT NOT NULL,
                dayOfWeek INTEGER,
                category TEXT NOT NULL,
                skillLevel TEXT NOT NULL
            )
            """)
        } catch {
            print("Error creating task_assignments table: \(error)")
        }
    }
    
    private func createTaskCompletionLogTable() async {
        guard let database = database else { return }
        
        do {
            try await database.execute("""
            CREATE TABLE IF NOT EXISTS task_completion_log (
                id TEXT PRIMARY KEY,
                taskID TEXT NOT NULL,
                workerID TEXT NOT NULL,
                buildingID TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                isVerified INTEGER DEFAULT 0,
                notes TEXT,
                photoPath TEXT
            )
            """)
        } catch {
            print("Error creating task_completion_log table: \(error)")
        }
    }
    
    // MARK: - CSV Data Import
    
    private func importCSVDataIfNeeded() async {
        guard let database = database else { return }
        
        do {
            // Check if data already exists
            let result = try await database.query("SELECT COUNT(*) as count FROM master_tasks")
            let count = result.first?["count"] as? Int64 ?? 0
            
            if count == 0 {
                await importMasterTasksCSV()
                await importTaskAssignmentsCSV()
            }
        } catch {
            print("Error checking existing data: \(error)")
        }
    }
    
    private func importMasterTasksCSV() async {
        guard let database = database else { return }
        
        // Replace the sample tasks with full task data from CSV
        let tasks = [
            // Cleaning tasks
            (
                id: "T1001",
                name: "Lobby Floor Cleaning",
                category: "Cleaning",
                skillRequired: "Basic",
                recurrence: "Daily",
                description: "Deep clean the lobby floor and entrance mats",
                urgency: "Medium"
            ),
            (
                id: "T1002",
                name: "Stairwell Cleaning",
                category: "Cleaning",
                skillRequired: "Basic",
                recurrence: "Weekly",
                description: "Sweep and mop all stairwells, front and back",
                urgency: "Medium"
            ),
            (
                id: "T1003",
                name: "Elevator Cleaning",
                category: "Cleaning",
                skillRequired: "Basic",
                recurrence: "Daily",
                description: "Clean elevator floor, walls, and control panel",
                urgency: "Low"
            ),
            
            // Sanitation tasks
            (
                id: "T1004",
                name: "Trash Room Cleaning",
                category: "Sanitation",
                skillRequired: "Basic",
                recurrence: "Daily",
                description: "Clean and sanitize trash room, replace bin liners",
                urgency: "High"
            ),
            (
                id: "T1005",
                name: "Garbage Collection",
                category: "Sanitation",
                skillRequired: "Basic",
                recurrence: "Daily",
                description: "Collect garbage from all floors and bring to main disposal",
                urgency: "High"
            ),
            
            // Maintenance tasks
            (
                id: "T1006",
                name: "Boiler Blowdown",
                category: "Maintenance",
                skillRequired: "Advanced",
                recurrence: "Weekly",
                description: "Perform routine boiler blowdown procedure",
                urgency: "High"
            ),
            
            // Inspection tasks
            (
                id: "T1007",
                name: "Water Tank Inspection",
                category: "Inspection",
                skillRequired: "Intermediate",
                recurrence: "Weekly",
                description: "Check water tank levels and condition",
                urgency: "Medium"
            ),
            (
                id: "T1008",
                name: "Roof Drain Inspection",
                category: "Inspection",
                skillRequired: "Basic",
                recurrence: "Monthly",
                description: "Inspect and clear all roof drains",
                urgency: "Medium"
            ),
            (
                id: "T1009",
                name: "Utility Room Walkthrough",
                category: "Inspection",
                skillRequired: "Basic",
                recurrence: "Weekly",
                description: "Perform visual inspection of all utility rooms",
                urgency: "Low"
            ),
            
            // Emergency tasks
            (
                id: "T1010",
                name: "Fix Leaking Pipe",
                category: "Repair",
                skillRequired: "Advanced",
                recurrence: "One Time",
                description: "Emergency repair needed for leaking pipe",
                urgency: "Urgent"
            ),
            
            // Weather-related tasks
            (
                id: "T1011",
                name: "Clear Ice from Entrance",
                category: "Maintenance",
                skillRequired: "Basic",
                recurrence: "One Time",
                description: "Apply salt and clear ice from building entrance",
                urgency: "High"
            )
        ]
        
        // Insert tasks
        for task in tasks {
            do {
                try await database.execute("""
                INSERT OR IGNORE INTO master_tasks (taskID, name, category, skillRequired, recurrence, description, urgency)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """, [
                    task.id, task.name, task.category, task.skillRequired,
                    task.recurrence, task.description, task.urgency
                ])
            } catch {
                print("Error inserting task \(task.name): \(error)")
            }
        }
    }
    
    private func importTaskAssignmentsCSV() async {
        guard let database = database else { return }
        
        // Replace sample assignments with our building-worker-task assignments
        let assignments = [
            // 12 West 18th Street (ID: 1)
            (
                id: "A1001",
                buildingID: "1",
                taskName: "Lobby Floor Cleaning",
                workerID: "1", // Greg Hutson
                recurrence: "Daily",
                dayOfWeek: 0, // 0 means every day
                category: "Cleaning",
                skillLevel: "Basic"
            ),
            (
                id: "A1002",
                buildingID: "1",
                taskName: "Stairwell Cleaning",
                workerID: "1", // Greg Hutson
                recurrence: "Weekly",
                dayOfWeek: 1, // Monday
                category: "Cleaning",
                skillLevel: "Basic"
            ),
            (
                id: "A1003",
                buildingID: "1",
                taskName: "Elevator Cleaning",
                workerID: "7", // Angel Guirachocha
                recurrence: "Daily",
                dayOfWeek: 0,
                category: "Cleaning",
                skillLevel: "Basic"
            ),
            
            // Rubin Museum (ID: 14)
            (
                id: "A2001",
                buildingID: "14",
                taskName: "Lobby Floor Cleaning",
                workerID: "8", // Shawn Magloire
                recurrence: "Daily",
                dayOfWeek: 0,
                category: "Cleaning",
                skillLevel: "Intermediate"
            ),
            (
                id: "A2002",
                buildingID: "14",
                taskName: "Water Tank Inspection",
                workerID: "8", // Shawn Magloire
                recurrence: "Weekly",
                dayOfWeek: 1, // Monday
                category: "Inspection",
                skillLevel: "Intermediate"
            )
        ]
        
        // Insert assignments
        for assignment in assignments {
            do {
                try await database.execute("""
                INSERT OR IGNORE INTO task_assignments (id, buildingID, taskName, workerID, recurrence, dayOfWeek, category, skillLevel)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, [
                    assignment.id, assignment.buildingID, assignment.taskName, assignment.workerID,
                    assignment.recurrence, assignment.dayOfWeek, assignment.category, assignment.skillLevel
                ])
            } catch {
                print("Error inserting assignment \(assignment.id): \(error)")
            }
        }
    }
    
    // MARK: - Task Generation and Scheduling
    
    /// Generates tasks for a worker for a specific date
    func generateTasks(forWorker workerID: String, date: Date) async -> [MaintenanceTask] {
        guard let database = database else { return [] }
        
        var tasks: [MaintenanceTask] = []
        
        // Get the day of week for the given date
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) - 1 // 0 = Sunday, 1 = Monday, etc.
        
        do {
            // Get all task assignments for this worker that match the day
            let result = try await database.query("""
            SELECT ta.id, ta.buildingID, ta.taskName, ta.recurrence, ta.category, ta.skillLevel,
                   mt.taskID, mt.description, mt.urgency
            FROM task_assignments ta
            JOIN master_tasks mt ON ta.taskName = mt.name
            WHERE ta.workerID = ? AND (ta.dayOfWeek = ? OR ta.dayOfWeek = 0)
            """, [workerID, weekday])
            
            // Create a MaintenanceTask object for each assignment
            for row in result {
                guard let assignmentID = row["id"] as? String,
                      let buildingID = row["buildingID"] as? String,
                      let taskName = row["taskName"] as? String,
                      let recurrenceStr = row["recurrence"] as? String,
                      let categoryStr = row["category"] as? String,
                      let taskID = row["taskID"] as? String,
                      let description = row["description"] as? String,
                      let urgencyStr = row["urgency"] as? String else {
                    continue
                }
                
                // Convert string values to enums
                guard let recurrence = TaskRecurrence(rawValue: recurrenceStr),
                      let category = TaskCategory(rawValue: categoryStr),
                      let urgency = TaskUrgency(rawValue: urgencyStr) else {
                    continue
                }
                
                // Create a task with appropriate timing based on recurrence
                let (startTime, endTime) = getTaskTiming(for: category, date: date)
                
                let task = MaintenanceTask(
                    id: "\(taskID)_\(date.formatted(date: .numeric, time: .omitted))_\(assignmentID)",
                    name: taskName,
                    buildingID: buildingID,
                    description: description,
                    dueDate: date,
                    startTime: startTime,
                    endTime: endTime,
                    category: category,
                    urgency: urgency,
                    recurrence: recurrence,
                    assignedWorkers: [workerID]
                )
                
                // Check if the task is already completed for today
                let isComplete = await isTaskAlreadyCompleted(taskID: task.id, date: date)
                
                // Add completion status
                var mutableTask = task
                mutableTask.isComplete = isComplete
                
                tasks.append(mutableTask)
            }
        } catch {
            print("Error generating tasks for worker \(workerID): \(error)")
        }
        
        return tasks
    }
    
    /// Gets all tasks for a specific building and date
    func getTasks(forBuilding buildingID: String, date: Date) async -> [MaintenanceTask] {
        guard let database = database else { return [] }
        
        var tasks: [MaintenanceTask] = []
        
        // Get the day of week for the given date
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) - 1
        
        do {
            // Get all task assignments for this building that match the day
            let result = try await database.query("""
            SELECT ta.id, ta.workerID, ta.taskName, ta.recurrence, ta.category, ta.skillLevel,
                   mt.taskID, mt.description, mt.urgency
            FROM task_assignments ta
            JOIN master_tasks mt ON ta.taskName = mt.name
            WHERE ta.buildingID = ? AND (ta.dayOfWeek = ? OR ta.dayOfWeek = 0)
            """, [buildingID, weekday])
            
            // Same logic as generateTasks, but filtered by building instead of worker
            for row in result {
                guard let assignmentID = row["id"] as? String,
                      let workerID = row["workerID"] as? String,
                      let taskName = row["taskName"] as? String,
                      let recurrenceStr = row["recurrence"] as? String,
                      let categoryStr = row["category"] as? String,
                      let taskID = row["taskID"] as? String,
                      let description = row["description"] as? String,
                      let urgencyStr = row["urgency"] as? String else {
                    continue
                }
                
                guard let recurrence = TaskRecurrence(rawValue: recurrenceStr),
                      let category = TaskCategory(rawValue: categoryStr),
                      let urgency = TaskUrgency(rawValue: urgencyStr) else {
                    continue
                }
                
                let (startTime, endTime) = getTaskTiming(for: category, date: date)
                
                let task = MaintenanceTask(
                    id: "\(taskID)_\(date.formatted(date: .numeric, time: .omitted))_\(assignmentID)",
                    name: taskName,
                    buildingID: buildingID,
                    description: description,
                    dueDate: date,
                    startTime: startTime,
                    endTime: endTime,
                    category: category,
                    urgency: urgency,
                    recurrence: recurrence,
                    assignedWorkers: [workerID]
                )
                
                let isComplete = await isTaskAlreadyCompleted(taskID: task.id, date: date)
                
                var mutableTask = task
                mutableTask.isComplete = isComplete
                
                tasks.append(mutableTask)
            }
        } catch {
            print("Error getting tasks for building \(buildingID): \(error)")
        }
        
        return tasks
    }
    
    // MARK: - Task Status Management
    
    /// Toggles the completion status of a task
    func toggleTaskCompletion(taskID: String, workerID: String, buildingID: String) async {
        guard let database = database else { return }
        
        // Check if task is already completed
        let isCompleted = await isTaskAlreadyCompleted(taskID: taskID, date: Date())
        
        if !isCompleted {
            // Mark task as completed
            do {
                let completionID = UUID().uuidString
                let timestamp = ISO8601DateFormatter().string(from: Date())
                
                try await database.execute("""
                INSERT INTO task_completion_log (id, taskID, workerID, buildingID, timestamp, isVerified)
                VALUES (?, ?, ?, ?, ?, 0)
                """, [completionID, taskID, workerID, buildingID, timestamp])
                
                print("Task \(taskID) marked as completed")
            } catch {
                print("Error completing task: \(error)")
            }
        }
        
        // Notify UI of status change
        await MainActor.run {
            NotificationCenter.default.post(
                name: NSNotification.Name("TaskCompletionStatusChanged"),
                object: nil,
                userInfo: ["taskID": taskID]
            )
        }
    }
    
    /// Checks if a task is already completed for a specific date
    func isTaskAlreadyCompleted(taskID: String, date: Date) async -> Bool {
        guard let database = database else { return false }
        
        // This would typically check the task_completion_log table
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let dateFormatter = ISO8601DateFormatter()
        let startString = dateFormatter.string(from: startOfDay)
        let endString = dateFormatter.string(from: endOfDay)
        
        do {
            let result = try await database.query("""
            SELECT COUNT(*) as count FROM task_completion_log
            WHERE taskID = ? AND timestamp >= ? AND timestamp < ? AND isVerified >= 0
            """, [taskID, startString, endString])
            
            let count = result.first?["count"] as? Int64 ?? 0
            return count > 0
        } catch {
            print("Error checking task completion: \(error)")
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    /// Gets appropriate start and end times for a task based on category
    private func getTaskTiming(for category: TaskCategory, date: Date) -> (startTime: Date?, endTime: Date?) {
        let calendar = Calendar.current
        
        // Set different timing based on task category
        switch category {
        case .cleaning:
            // Morning tasks
            var startComponents = calendar.dateComponents([.year, .month, .day], from: date)
            startComponents.hour = 8
            startComponents.minute = 0
            
            var endComponents = calendar.dateComponents([.year, .month, .day], from: date)
            endComponents.hour = 10
            endComponents.minute = 0
            
            return (calendar.date(from: startComponents), calendar.date(from: endComponents))
            
        case .maintenance:
            // Afternoon tasks
            var startComponents = calendar.dateComponents([.year, .month, .day], from: date)
            startComponents.hour = 13
            startComponents.minute = 0
            
            var endComponents = calendar.dateComponents([.year, .month, .day], from: date)
            endComponents.hour = 16
            endComponents.minute = 0
            
            return (calendar.date(from: startComponents), calendar.date(from: endComponents))
            
        case .inspection:
            // Early morning tasks
            var startComponents = calendar.dateComponents([.year, .month, .day], from: date)
            startComponents.hour = 7
            startComponents.minute = 0
            
            var endComponents = calendar.dateComponents([.year, .month, .day], from: date)
            endComponents.hour = 9
            endComponents.minute = 0
            
            return (calendar.date(from: startComponents), calendar.date(from: endComponents))
            
        case .repair:
            // Flexible timing, without specific start/end
            return (nil, nil)
            
        case .sanitation:
            // Evening tasks
            var startComponents = calendar.dateComponents([.year, .month, .day], from: date)
            startComponents.hour = 17
            startComponents.minute = 0
            
            var endComponents = calendar.dateComponents([.year, .month, .day], from: date)
            endComponents.hour = 19
            endComponents.minute = 0
            
            return (calendar.date(from: startComponents), calendar.date(from: endComponents))
        }
    }
}

// MARK: - Non-Actor TaskSchedulerService for Legacy Compatibility

class TaskSchedulerService {
    static let shared = TaskSchedulerService()
    
    private let taskManagementService = TaskManagementService.shared
    
    func generateTasks(forWorker workerID: String, date: Date) -> [MaintenanceTask] {
        // Create a synchronous wrapper for the async call
        var result: [MaintenanceTask] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            result = await taskManagementService.generateTasks(forWorker: workerID, date: date)
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    func getAllAssignments(workerID: String, buildingID: String?) -> [MaintenanceTask] {
        // This would be a specialized query that might be more appropriate in the scheduler
        // For now, we'll simply return tasks for today
        if let buildingID = buildingID {
            var result: [MaintenanceTask] = []
            let semaphore = DispatchSemaphore(value: 0)
            
            Task {
                let tasks = await taskManagementService.getTasks(forBuilding: buildingID, date: Date())
                result = tasks.filter { $0.assignedWorkers.contains(workerID) }
                semaphore.signal()
            }
            
            semaphore.wait()
            return result
        } else {
            return generateTasks(forWorker: workerID, date: Date())
        }
    }
    
    func toggleTaskCompletion(taskID: String, workerID: String, buildingID: String) {
        Task {
            await taskManagementService.toggleTaskCompletion(taskID: taskID, workerID: workerID, buildingID: buildingID)
        }
    }
}
