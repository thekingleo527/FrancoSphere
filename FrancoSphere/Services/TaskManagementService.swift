//
//  TaskManagementService.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/30/25.
//


import Foundation
import SwiftUI

/// Service for managing all task-related operations
class TaskManagementService {
    static let shared = TaskManagementService()
    
    private let database: SQLiteManager
    private let completionManager: TaskCompletionManager
    private let buildingStatusManager: BuildingStatusManager
    
    private init() {
        database = SQLiteManager.shared
        completionManager = TaskCompletionManager.shared
        buildingStatusManager = BuildingStatusManager.shared
        
        createTablesIfNeeded()
        importCSVDataIfNeeded()
    }
    
    // MARK: - Database Setup
    
    private func createTablesIfNeeded() {
        createMasterTasksTable()
        createTaskAssignmentsTable()
        // Task completion log table is created by TaskCompletionManager
    }
    
    private func createMasterTasksTable() {
        try? database.execute("""
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
    }
    
    private func createTaskAssignmentsTable() {
        try? database.execute("""
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
    }
    
    // MARK: - CSV Data Import
    
    private func importCSVDataIfNeeded() {
        // Check if data already exists
        let result = try? database.query("SELECT COUNT(*) as count FROM master_tasks")
        let count = result?.first?["count"] as? Int ?? 0
        
        if count == 0 {
            importMasterTasksCSV()
            importTaskAssignmentsCSV()
        }
    }
    
    private func importMasterTasksCSV() {
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
                recurrence: "OneTime",
                description: "Emergency repair needed for leaking pipe",
                urgency: "Urgent"
            ),
            
            // Weather-related tasks
            (
                id: "T1011",
                name: "Clear Ice from Entrance",
                category: "Maintenance",
                skillRequired: "Basic",
                recurrence: "OneTime",
                description: "Apply salt and clear ice from building entrance",
                urgency: "High"
            )
            
            // Add more tasks as needed
        ]
        
        // Insert tasks
        for task in tasks {
            try? database.execute("""
            INSERT INTO master_tasks (taskID, name, category, skillRequired, recurrence, description, urgency)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """, parameters: [
                task.id, task.name, task.category, task.skillRequired,
                task.recurrence, task.description, task.urgency
            ])
        }
    }
    
    private func importTaskAssignmentsCSV() {
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
                taskName: "Lobby Glass Cleaning",
                workerID: "8", // Shawn Magloire
                recurrence: "Daily",
                dayOfWeek: 0,
                category: "Cleaning",
                skillLevel: "Intermediate"
            ),
            (
                id: "A2002",
                buildingID: "14",
                taskName: "Elevator Inspection",
                workerID: "8", // Shawn Magloire
                recurrence: "Monthly",
                dayOfWeek: 1, // First Monday
                category: "Inspection",
                skillLevel: "Advanced"
            )
            
            // Add more assignments for each building
        ]
        
        // Insert assignments
        for assignment in assignments {
            try? database.execute("""
            INSERT INTO task_assignments (id, buildingID, taskName, workerID, recurrence, dayOfWeek, category, skillLevel)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, parameters: [
                assignment.id, assignment.buildingID, assignment.taskName, assignment.workerID,
                assignment.recurrence, assignment.dayOfWeek, assignment.category, assignment.skillLevel
            ])
        }
    }
    
    // MARK: - Task Generation and Scheduling
    
    /// Generates tasks for a worker for a specific date
    func generateTasks(forWorker workerID: String, date: Date) -> [MaintenanceTask] {
        var tasks: [MaintenanceTask] = []
        
        // Get the day of week for the given date
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) - 1 // 0 = Sunday, 1 = Monday, etc.
        
        // Get all task assignments for this worker that match the day
        let result = try? database.query("""
        SELECT ta.id, ta.buildingID, ta.taskName, ta.recurrence, ta.category, ta.skillLevel,
               mt.taskID, mt.description, mt.urgency
        FROM task_assignments ta
        JOIN master_tasks mt ON ta.taskName = mt.name
        WHERE ta.workerID = ? AND (ta.dayOfWeek = ? OR ta.dayOfWeek = 0)
        """, parameters: [workerID, weekday])
        
        guard let rows = result else { return [] }
        
        // Create a MaintenanceTask object for each assignment
        for row in rows {
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
            let (startTime, endTime) = getTaskTiming(for: category)
            
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
            let isComplete = isTaskAlreadyCompleted(taskID: task.id, date: date)
            
            // Add completion status
            var mutableTask = task
            mutableTask.isComplete = isComplete
            
            tasks.append(mutableTask)
        }
        
        return tasks
    }
    
    /// Gets all tasks for a specific building and date
    func getTasks(forBuilding buildingID: String, date: Date) -> [MaintenanceTask] {
        var tasks: [MaintenanceTask] = []
        
        // Get the day of week for the given date
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) - 1
        
        // Get all task assignments for this building that match the day
        let result = try? database.query("""
        SELECT ta.id, ta.workerID, ta.taskName, ta.recurrence, ta.category, ta.skillLevel,
               mt.taskID, mt.description, mt.urgency
        FROM task_assignments ta
        JOIN master_tasks mt ON ta.taskName = mt.name
        WHERE ta.buildingID = ? AND (ta.dayOfWeek = ? OR ta.dayOfWeek = 0)
        """, parameters: [buildingID, weekday])
        
        guard let rows = result else { return [] }
        
        // Same logic as generateTasks, but filtered by building instead of worker
        for row in rows {
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
            
            let (startTime, endTime) = getTaskTiming(for: category)
            
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
            
            let isComplete = isTaskAlreadyCompleted(taskID: task.id, date: date)
            
            var mutableTask = task
            mutableTask.isComplete = isComplete
            
            tasks.append(mutableTask)
        }
        
        return tasks
    }
    
    // MARK: - Task Status Management
    
    /// Toggles the completion status of a task
    func toggleTaskCompletion(taskID: String) {
        // Actual completion is handled by TaskCompletionManager
        // This just updates the in-memory model
        NotificationCenter.default.post(
            name: NSNotification.Name("TaskCompletionStatusChanged"),
            object: nil,
            userInfo: ["taskID": taskID]
        )
    }
    
    /// Checks if a task is already completed for a specific date
    func isTaskAlreadyCompleted(taskID: String, date: Date) -> Bool {
        // This would typically check the task_completion_log table
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let dateFormatter = ISO8601DateFormatter()
        let startString = dateFormatter.string(from: startOfDay)
        let endString = dateFormatter.string(from: endOfDay)
        
        let result = try? database.query("""
        SELECT COUNT(*) as count FROM task_completion_log
        WHERE taskID = ? AND timestamp >= ? AND timestamp < ? AND isVerified >= 0
        """, parameters: [taskID, startString, endString])
        
        let count = result?.first?["count"] as? Int ?? 0
        return count > 0
    }
    
    // MARK: - Helper Methods
    
    /// Gets appropriate start and end times for a task based on category
    private func getTaskTiming(for category: TaskCategory) -> (startTime: Date?, endTime: Date?) {
        let now = Date()
        let calendar = Calendar.current
        
        // Set different timing based on task category
        switch category {
        case .cleaning:
            // Morning tasks
            var startComponents = calendar.dateComponents([.year, .month, .day], from: now)
            startComponents.hour = 8
            startComponents.minute = 0
            
            var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
            endComponents.hour = 10
            endComponents.minute = 0
            
            return (calendar.date(from: startComponents), calendar.date(from: endComponents))
            
        case .maintenance:
            // Afternoon tasks
            var startComponents = calendar.dateComponents([.year, .month, .day], from: now)
            startComponents.hour = 13
            startComponents.minute = 0
            
            var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
            endComponents.hour = 16
            endComponents.minute = 0
            
            return (calendar.date(from: startComponents), calendar.date(from: endComponents))
            
        case .inspection:
            // Early morning tasks
            var startComponents = calendar.dateComponents([.year, .month, .day], from: now)
            startComponents.hour = 7
            startComponents.minute = 0
            
            var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
            endComponents.hour = 9
            endComponents.minute = 0
            
            return (calendar.date(from: startComponents), calendar.date(from: endComponents))
            
        case .repair:
            // Flexible timing, without specific start/end
            return (nil, nil)
            
        case .sanitation:
            // Evening tasks
            var startComponents = calendar.dateComponents([.year, .month, .day], from: now)
            startComponents.hour = 17
            startComponents.minute = 0
            
            var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
            endComponents.hour = 19
            endComponents.minute = 0
            
            return (calendar.date(from: startComponents), calendar.date(from: endComponents))
        }
    }
}

// MARK: - Integration with TaskSchedulerService

/*
 Note on TaskManagementService vs TaskSchedulerService:
 
 While there's some functional overlap between this TaskManagementService and the
 previously mentioned TaskSchedulerService, they serve different purposes:
 
 - TaskManagementService: Responsible for the overall task lifecycle management,
   including data import, persistence, and business logic around task creation and completion.
   
 - TaskSchedulerService: Focused specifically on the scheduling algorithm and generation
   of tasks based on recurrence patterns, day of week, and other scheduling factors.
   
 In a production implementation, you have two options:
 
 1. Merge these into a single service with clear internal organization
 2. Keep them separate but make TaskSchedulerService depend on TaskManagementService
    for data access and only handle the scheduling logic.
 
 For this implementation, we've created a comprehensive TaskManagementService that includes
 scheduling capabilities. To avoid conflicts, you should:
 
 - Either use only TaskManagementService and discard TaskSchedulerService
 - Or refactor TaskSchedulerService to only handle the scheduling algorithm and have it
   call TaskManagementService for persistence operations
 */

// MARK: - Minimal TaskSchedulerService Interface
// This shows how TaskSchedulerService would delegate to TaskManagementService

class TaskSchedulerService {
    static let shared = TaskSchedulerService()
    
    private let taskManagementService = TaskManagementService.shared
    
    func generateTasks(forWorker workerID: String, date: Date) -> [MaintenanceTask] {
        // Simply delegate to TaskManagementService
        return taskManagementService.generateTasks(forWorker: workerID, date: date)
    }
    
    func getAllAssignments(workerID: String, buildingID: String?) -> [MaintenanceTask] {
        // This would be a specialized query that might be more appropriate in the scheduler
        // For now, we'll simply return tasks for today
        if let buildingID = buildingID {
            return taskManagementService.getTasks(forBuilding: buildingID, date: Date())
                .filter { $0.assignedWorkers.contains(workerID) }
        } else {
            return taskManagementService.generateTasks(forWorker: workerID, date: Date())
        }
    }
    
    // Other scheduling-specific methods could be added here
}
