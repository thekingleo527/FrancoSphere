import Foundation
import SQLite

// MARK: - TaskTemplate model
struct FrancoTaskTemplate: Identifiable {
    let id: String
    let name: String
    let description: String
    let category: FrancoSphere.TaskCategory
    let urgency: FrancoSphere.TaskUrgency
    let recurrence: FrancoSphere.TaskRecurrence
    let estimatedDuration: TimeInterval // in seconds
    let skillLevel: String
    
    func createTask(buildingID: String, dueDate: Date) -> FrancoSphere.MaintenanceTask {
        // Calculate start/end times if necessary
        var startTime: Date? = nil
        var endTime: Date? = nil
        
        if estimatedDuration > 0 {
            // Set a default start time (10 AM)
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: dueDate)
            components.hour = 10
            components.minute = 0
            startTime = calendar.date(from: components)
            
            // Calculate end time based on duration
            if let start = startTime {
                endTime = start.addingTimeInterval(estimatedDuration)
            }
        }
        
        return FrancoSphere.MaintenanceTask(
            id: UUID().uuidString,
            name: name,
            buildingID: buildingID,
            description: description,
            dueDate: dueDate,
            startTime: startTime,
            endTime: endTime,
            category: category,
            urgency: urgency,
            recurrence: recurrence,
            isComplete: false,
            assignedWorkers: []
        )
    }
    
    // Standard task templates that can be used across the app
    static var allTaskTemplates: [FrancoTaskTemplate] = [
        FrancoTaskTemplate(
            id: "template-1",
            name: "HVAC Filter Replacement",
            description: "Replace all air filters in the HVAC system throughout the building.",
            category: FrancoSphere.TaskCategory.maintenance,
            urgency: FrancoSphere.TaskUrgency.medium,
            recurrence: FrancoSphere.TaskRecurrence.monthly,
            estimatedDuration: 3600, // 1 hour
            skillLevel: "Intermediate"
        ),
        FrancoTaskTemplate(
            id: "template-2",
            name: "Lobby Floor Cleaning",
            description: "Deep clean the lobby floor and entrance mats.",
            category: FrancoSphere.TaskCategory.cleaning,
            urgency: FrancoSphere.TaskUrgency.low,
            recurrence: FrancoSphere.TaskRecurrence.daily,
            estimatedDuration: 1800, // 30 minutes
            skillLevel: "Basic"
        ),
        FrancoTaskTemplate(
            id: "template-3",
            name: "Fire Alarm Testing",
            description: "Test all fire alarm systems to ensure proper functioning.",
            category: FrancoSphere.TaskCategory.inspection,
            urgency: FrancoSphere.TaskUrgency.high,
            recurrence: FrancoSphere.TaskRecurrence.monthly,
            estimatedDuration: 7200, // 2 hours
            skillLevel: "Advanced"
        ),
        FrancoTaskTemplate(
            id: "template-4",
            name: "Plumbing Leak Repair",
            description: "Repair reported plumbing leak in specified location.",
            category: FrancoSphere.TaskCategory.repair,
            urgency: FrancoSphere.TaskUrgency.high,
            recurrence: FrancoSphere.TaskRecurrence.oneTime,
            estimatedDuration: 3600, // 1 hour
            skillLevel: "Intermediate"
        ),
        FrancoTaskTemplate(
            id: "template-5",
            name: "Garbage Room Sanitation",
            description: "Clean and sanitize garbage collection areas.",
            category: FrancoSphere.TaskCategory.sanitation,
            urgency: FrancoSphere.TaskUrgency.medium,
            recurrence: FrancoSphere.TaskRecurrence.weekly,
            estimatedDuration: 2700, // 45 minutes
            skillLevel: "Basic"
        )
    ]
}

class TaskManager {
    static let shared = TaskManager()
    
    private init() {
        createRequiredTables()
        initializeRealTasks()
    }
    
    // MARK: - Database Setup
    
    private func createRequiredTables() {
        do {
            try createTasksTable()
            try createTaskAssignmentsTable()
            try createMaintenanceHistoryTable()
        } catch {
            print("Error creating tables: \(error)")
        }
    }
    
    private func createTasksTable() throws {
        guard let db = SQLiteManager.shared.db else {
            throw NSError(domain: "TaskManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database connection not available"])
        }
        
        try db.execute("""
        CREATE TABLE IF NOT EXISTS tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            buildingId TEXT,
            isCompleted INTEGER DEFAULT 0,
            scheduledDate TEXT,
            recurrence TEXT DEFAULT 'One Time',
            urgencyLevel TEXT DEFAULT 'Medium',
            category TEXT DEFAULT 'Maintenance',
            startTime TEXT,
            endTime TEXT,
            requiredSkillLevel TEXT DEFAULT 'Basic'
        )
        """)
    }
    
    private func createTaskAssignmentsTable() throws {
        guard let db = SQLiteManager.shared.db else {
            throw NSError(domain: "TaskManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database connection not available"])
        }
        
        try db.execute("""
        CREATE TABLE IF NOT EXISTS task_assignments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            taskId INTEGER NOT NULL,
            workerId TEXT NOT NULL,
            UNIQUE(taskId, workerId)
        )
        """)
    }
    
    private func createMaintenanceHistoryTable() throws {
        guard let db = SQLiteManager.shared.db else {
            throw NSError(domain: "TaskManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database connection not available"])
        }
        
        try db.execute("""
        CREATE TABLE IF NOT EXISTS maintenance_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            buildingId TEXT NOT NULL,
            taskId TEXT,
            taskName TEXT NOT NULL,
            notes TEXT,
            completionDate TEXT NOT NULL,
            completedBy TEXT NOT NULL,
            workerId TEXT
        )
        """)
    }
    
    // Initialize real tasks in the database
    private func initializeRealTasks() {
        // Check if we already have tasks in the database
        do {
            guard let db = SQLiteManager.shared.db else { return }
            
            let count = try db.scalar("SELECT COUNT(*) FROM tasks") as! Int64
            
            // Only add sample tasks if the database is empty
            if count == 0 {
                loadTasksFromCSVData()
            }
        } catch {
            print("Error checking task count: \(error)")
        }
    }
    
    // Load real task data from mapped CSV data
    private func loadTasksFromCSVData() {
        // This method uses the mapping document to load real tasks into the database
        
        // Create tasks based on the "Updated_Task_Matrix.csv" data
        let realTaskAssignments: [(buildingName: String, taskName: String, workerName: String, category: String, skillLevel: String, recurrence: String)] = [
            // Building 1: 12 West 18th Street
            ("12 West 18th Street", "HVAC Filter Replacement", "Edwin Lema", "Maintenance", "Intermediate", "Monthly"),
            ("12 West 18th Street", "Lobby Floor Cleaning", "Jose Rodriguez", "Cleaning", "Basic", "Weekly"),
            
            // Building 2: 29-31 East 20th Street
            ("29-31 East 20th Street", "Common Area Cleaning", "Edwin Lema", "Cleaning", "Basic", "Daily"),
            ("29-31 East 20th Street", "Garbage Room Sanitation", "Greg", "Sanitation", "Intermediate", "Weekly"),
            
            // Building 3: 36 Walker Street
            ("36 Walker Street", "HVAC System Inspection", "Jose Rodriguez", "Inspection", "Advanced", "Monthly"),
            ("36 Walker Street", "Bathroom Plumbing Repair", "Greg", "Repair", "Intermediate", "One Time"),
            
            // Building 4: 41 Elizabeth Street
            ("41 Elizabeth Street", "Electrical Panel Inspection", "Greg", "Inspection", "Advanced", "Monthly"),
            ("41 Elizabeth Street", "Hallway Maintenance", "Jose Rodriguez", "Maintenance", "Basic", "Monthly"),
            
            // Building 5: 68 Perry Street
            ("68 Perry Street", "Lobby Cleaning", "Edwin Lema", "Cleaning", "Basic", "Daily"),
            ("68 Perry Street", "Window Cleaning", "Angel", "Cleaning", "Intermediate", "Monthly"),
            
            // Building 6: 104 Franklin Street
            ("104 Franklin Street", "Emergency Plumbing Repair", "Greg", "Repair", "Advanced", "One Time"),
            
            // Building 7: 112 West 18th Street
            ("112 West 18th Street", "Fire Alarm Testing", "Angel", "Inspection", "Advanced", "Monthly"),
            
            // Building 8: 117 West 17th Street
            ("117 West 17th Street", "Hallway Deep Cleaning", "Edwin Lema", "Cleaning", "Intermediate", "Monthly"),
            
            // Building 9: 123 1st Avenue
            ("123 1st Avenue", "Roof Inspection", "Jose Rodriguez", "Inspection", "Advanced", "Monthly"),
            
            // Building 10: 131 Perry Street
            ("131 Perry Street", "Elevator Maintenance", "Greg", "Maintenance", "Advanced", "Monthly"),
            
            // Building 11: 133 East 15th Street
            ("133 East 15th Street", "Garbage Room Cleaning", "Jose Rodriguez", "Sanitation", "Basic", "Weekly"),
            
            // Building 12: 135_139 West 17th Street
            ("135_139 West 17th Street", "HVAC System Check", "Edwin Lema", "Maintenance", "Intermediate", "Monthly"),
            
            // Building 13: 136 West 17th Street
            ("136 West 17th Street", "Stairwell Cleaning", "Angel", "Cleaning", "Basic", "Weekly"),
            
            // Building 14: 138 West 17th Street
            ("138 West 17th Street", "Building Security Check", "Greg", "Inspection", "Intermediate", "Weekly"),
            
            // Building 15: Rubin Museum
            ("Rubin Museum (142_148 W 17th)", "Exhibit Area Cleaning", "Angel", "Cleaning", "Intermediate", "Daily"),
            
            // Building 16: Stuyvesant Cove Park
            ("Stuyvesant Cove Park", "Gardening and Maintenance", "Angel", "Maintenance", "Intermediate", "Weekly")
        ]
        
        // Task templates from FrancoSphere_Master_Task_Table.csv to get descriptions and urgency levels
        // This is a simplified representation of your master task table
        let taskTemplates: [String: (description: String, urgency: String)] = [
            "HVAC Filter Replacement": ("Replace all air filters in the HVAC system", "Medium"),
            "Lobby Floor Cleaning": ("Deep clean the lobby floor and entrance mats", "Low"),
            "Common Area Cleaning": ("Clean all common areas including hallways and entrances", "Medium"),
            "Garbage Room Sanitation": ("Clean and sanitize garbage collection area", "Medium"),
            "HVAC System Inspection": ("Full inspection of HVAC system", "Medium"),
            "Bathroom Plumbing Repair": ("Fix leaking pipes and ensure proper drainage", "High"),
            "Electrical Panel Inspection": ("Safety inspection of all electrical panels", "High"),
            "Hallway Maintenance": ("General maintenance of hallways including paint touch-ups", "Low"),
            "Lobby Cleaning": ("Full cleaning of lobby area", "Low"),
            "Window Cleaning": ("Clean all windows in common areas", "Low"),
            "Emergency Plumbing Repair": ("Fix water leak in designated area", "Urgent"),
            "Fire Alarm Testing": ("Test all fire alarms in the building", "High"),
            "Hallway Deep Cleaning": ("Deep clean all hallway carpets and surfaces", "Medium"),
            "Roof Inspection": ("Inspect roof for potential leaks", "Medium"),
            "Elevator Maintenance": ("Regular maintenance check of elevator system", "High"),
            "Garbage Room Cleaning": ("Clean and sanitize garbage collection area", "Medium"),
            "HVAC System Check": ("Regular maintenance of HVAC system", "Medium"),
            "Stairwell Cleaning": ("Clean all stairwells", "Low"),
            "Building Security Check": ("Complete security inspection of all entrances", "High"),
            "Exhibit Area Cleaning": ("Clean and maintain museum exhibit areas", "Medium"),
            "Gardening and Maintenance": ("Maintain garden areas and pathways", "Medium")
        ]
        
        // Create tasks with appropriate due dates (spread across next 30 days)
        for (index, taskData) in realTaskAssignments.enumerated() {
            // Create a task with a due date within the next 30 days
            let dueOffset = index % 30 // Spread tasks over 30 days
            
            createTaskFromCSVData(
                buildingName: taskData.buildingName,
                taskName: taskData.taskName,
                workerName: taskData.workerName,
                category: taskData.category,
                skillLevel: taskData.skillLevel,
                recurrence: taskData.recurrence,
                description: taskTemplates[taskData.taskName]?.description ?? "Perform required task",
                urgency: taskTemplates[taskData.taskName]?.urgency ?? "Medium",
                dueOffset: dueOffset
            )
        }
        
        print("Successfully loaded \(realTaskAssignments.count) tasks from CSV data")
    }
    
    // Create a task from CSV data
    private func createTaskFromCSVData(
        buildingName: String,
        taskName: String,
        workerName: String,
        category: String,
        skillLevel: String,
        recurrence: String,
        description: String,
        urgency: String,
        dueOffset: Int
    ) {
        // Map CSV data to model objects
        guard let buildingID = FrancoSphere.NamedCoordinate.getBuildingId(byName: buildingName),
              let workerID = FrancoSphere.WorkerProfile.getWorkerId(byName: workerName),
              let taskCategory = FrancoSphere.TaskCategory(rawValue: category),
              let taskRecurrence = FrancoSphere.TaskRecurrence(rawValue: recurrence),
              let taskUrgency = FrancoSphere.TaskUrgency(rawValue: urgency) else {
            print("Error mapping CSV data for task: \(taskName)")
            return
        }
        
        // Calculate due date
        let dueDate = Calendar.current.date(byAdding: .day, value: dueOffset, to: Date()) ?? Date()
        
        // Calculate times (random time during work hours)
        let hour = Int.random(in: 8...16)
        let minute = [0, 15, 30, 45][Int.random(in: 0...3)]
        let startDate = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: dueDate) ?? dueDate
        let endDate = Calendar.current.date(byAdding: .hour, value: Int.random(in: 1...3), to: startDate) ?? dueDate
        
        do {
            guard let db = SQLiteManager.shared.db else { return }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dueDateStr = dateFormatter.string(from: dueDate)
            
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let startTimeStr = dateFormatter.string(from: startDate)
            let endTimeStr = dateFormatter.string(from: endDate)
            
            // Insert task
            let insertQuery = """
            INSERT INTO tasks (
                name, description, buildingId, scheduledDate, isCompleted,
                recurrence, urgencyLevel, category, startTime, endTime, requiredSkillLevel
            ) VALUES (?, ?, ?, ?, 0, ?, ?, ?, ?, ?, ?)
            """
            
            try db.run(insertQuery, taskName, description, buildingID, dueDateStr,
                       recurrence, urgency, category, startTimeStr, endTimeStr, skillLevel)
            
            // Get task ID
            let taskId = db.lastInsertRowid
            
            // Create worker assignment
            let assignmentQuery = "INSERT INTO task_assignments (taskId, workerId) VALUES (?, ?)"
            try db.run(assignmentQuery, taskId, workerID)
            
            print("Added task from CSV: \(taskName) for building \(buildingName) assigned to \(workerName)")
        } catch {
            print("Error adding task from CSV \(taskName): \(error)")
        }
    }
    
    // MARK: - Task Operations
    
    /// Fetch tasks for a worker on a specific date
    func fetchTasks(forWorker workerId: String, date: Date) -> [FrancoSphere.MaintenanceTask] {
        var tasks: [FrancoSphere.MaintenanceTask] = []
        
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: date)
            
            guard let db = SQLiteManager.shared.db else {
                print("Database connection not available")
                return []
            }
            
            let query = """
            SELECT t.id, t.name, t.description, t.buildingId, t.scheduledDate, t.isCompleted,
                   t.recurrence, t.urgencyLevel, t.category, t.startTime, t.endTime
            FROM tasks t
            LEFT JOIN task_assignments ta ON t.id = ta.taskId
            WHERE ta.workerId = ? AND t.scheduledDate LIKE ?
            GROUP BY t.id
            """
            
            let rows = try db.prepare(query, workerId, "\(dateString)%")
            
            for row in rows {
                let id = row[0] as! Int64
                let name = row[1] as! String
                let description = row[2] as? String ?? ""
                let buildingId = row[3] as! String
                let dateStr = row[4] as? String ?? dateString
                let isCompleted = (row[5] as? Int64 ?? 0) == 1
                
                let recurrenceStr = row[6] as? String ?? "One Time"
                let urgencyStr = row[7] as? String ?? "Medium"
                let categoryStr = row[8] as? String ?? "Maintenance"
                let startTimeStr = row[9] as? String
                let endTimeStr = row[10] as? String
                
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dueDate = dateFormatter.date(from: dateStr) ?? Date()
                
                var startTime: Date? = nil
                var endTime: Date? = nil
                if let startStr = startTimeStr {
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    startTime = dateFormatter.date(from: startStr)
                }
                if let endStr = endTimeStr {
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    endTime = dateFormatter.date(from: endStr)
                }
                
                let recurrence = FrancoSphere.TaskRecurrence(rawValue: recurrenceStr) ?? .oneTime
                let urgency = FrancoSphere.TaskUrgency(rawValue: urgencyStr) ?? .medium
                let category = FrancoSphere.TaskCategory(rawValue: categoryStr) ?? .maintenance
                
                let assignedWorkers = fetchAssignedWorkers(taskId: id)
                
                let task = FrancoSphere.MaintenanceTask(
                    id: "\(id)",
                    name: name,
                    buildingID: buildingId,
                    description: description,
                    dueDate: dueDate,
                    startTime: startTime,
                    endTime: endTime,
                    category: category,
                    urgency: urgency,
                    recurrence: recurrence,
                    isComplete: isCompleted,
                    assignedWorkers: assignedWorkers
                )
                tasks.append(task)
            }
            
        } catch {
            print("Error fetching tasks: \(error)")
        }
        
        return tasks
    }
    
    /// Fetch assigned workers for a task
    private func fetchAssignedWorkers(taskId: Int64) -> [String] {
        var workers: [String] = []
        do {
            guard let db = SQLiteManager.shared.db else { return [] }
            let query = "SELECT workerId FROM task_assignments WHERE taskId = ?"
            
            let rows = try db.prepare(query, taskId)
            for row in rows {
                if let workerId = row[0] as? String {
                    workers.append(workerId)
                }
            }
        } catch {
            print("Error fetching assigned workers: \(error)")
        }
        return workers
    }
    
    /// Fetch tasks for a building
    func fetchTasks(forBuilding buildingId: String, includePastTasks: Bool = false) -> [FrancoSphere.MaintenanceTask] {
        var tasks: [FrancoSphere.MaintenanceTask] = []
        
        do {
            guard let db = SQLiteManager.shared.db else {
                print("Database connection not available")
                return []
            }
            
            let dateFilter = includePastTasks ? "" : "AND (t.isCompleted = 0 OR t.scheduledDate >= date('now'))"
            
            let query = """
            SELECT t.id, t.name, t.description, t.buildingId, t.scheduledDate, t.isCompleted,
                   t.recurrence, t.urgencyLevel, t.category, t.startTime, t.endTime
            FROM tasks t
            WHERE t.buildingId = ? \(dateFilter)
            ORDER BY t.scheduledDate ASC
            """
            
            let rows = try db.prepare(query, buildingId)
            for row in rows {
                let id = row[0] as! Int64
                let name = row[1] as! String
                let description = row[2] as? String ?? ""
                let buildingId = row[3] as! String
                let dateStr = row[4] as? String ?? ""
                let isCompleted = (row[5] as? Int64 ?? 0) == 1
                
                let recurrenceStr = row[6] as? String ?? "One Time"
                let urgencyStr = row[7] as? String ?? "Medium"
                let categoryStr = row[8] as? String ?? "Maintenance"
                let startTimeStr = row[9] as? String
                let endTimeStr = row[10] as? String
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dueDate = dateFormatter.date(from: dateStr) ?? Date()
                
                var startTime: Date? = nil
                var endTime: Date? = nil
                if let startStr = startTimeStr {
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    startTime = dateFormatter.date(from: startStr)
                }
                if let endStr = endTimeStr {
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    endTime = dateFormatter.date(from: endStr)
                }
                
                let recurrence = FrancoSphere.TaskRecurrence(rawValue: recurrenceStr) ?? .oneTime
                let urgency = FrancoSphere.TaskUrgency(rawValue: urgencyStr) ?? .medium
                let category = FrancoSphere.TaskCategory(rawValue: categoryStr) ?? .maintenance
                
                let assignedWorkers = fetchAssignedWorkers(taskId: id)
                
                let task = FrancoSphere.MaintenanceTask(
                    id: "\(id)",
                    name: name,
                    buildingID: buildingId,
                    description: description,
                    dueDate: dueDate,
                    startTime: startTime,
                    endTime: endTime,
                    category: category,
                    urgency: urgency,
                    recurrence: recurrence,
                    isComplete: isCompleted,
                    assignedWorkers: assignedWorkers
                )
                tasks.append(task)
            }
            
        } catch {
            print("Error fetching tasks for building: \(error)")
        }
        
        return tasks
    }
    
    /// Create a new task
    func createTask(_ task: FrancoSphere.MaintenanceTask) -> Bool {
        do {
            guard let db = SQLiteManager.shared.db else {
                print("Database connection not available")
                return false
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dueDateStr = dateFormatter.string(from: task.dueDate)
            
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let startTimeStr = task.startTime != nil ? dateFormatter.string(from: task.startTime!) : nil
            let endTimeStr = task.endTime != nil ? dateFormatter.string(from: task.endTime!) : nil
            
            let isCompleted = task.isComplete ? 1 : 0
            
            let insertQuery = """
            INSERT INTO tasks (
                name, description, buildingId, scheduledDate, isCompleted,
                recurrence, urgencyLevel, category, startTime, endTime
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            
            try db.run(insertQuery, task.name, task.description, task.buildingID, dueDateStr, isCompleted,
                       task.recurrence.rawValue, task.urgency.rawValue, task.category.rawValue,
                       startTimeStr, endTimeStr)
            
            let taskId = db.lastInsertRowid
            
            if !task.assignedWorkers.isEmpty {
                try createTaskAssignments(taskId: taskId, workerIds: task.assignedWorkers)
            }
            
            if task.recurrence != .oneTime {
                scheduleNextOccurrence(task: task)
            }
            
            print("Successfully created task: \(task.name)")
            return true
            
        } catch {
            print("Error creating task: \(error)")
            return false
        }
    }
    
    /// Create task assignments for workers
    func createTaskAssignments(taskId: Int64, workerIds: [String]) throws {
        guard let db = SQLiteManager.shared.db else {
            throw NSError(domain: "TaskManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database connection not available"])
        }
        
        try db.execute("BEGIN TRANSACTION")
        
        do {
            try db.run("DELETE FROM task_assignments WHERE taskId = ?", taskId)
            
            for workerId in workerIds {
                try db.run("INSERT INTO task_assignments (taskId, workerId) VALUES (?, ?)", taskId, workerId)
            }
            
            try db.execute("COMMIT")
        } catch {
            try db.execute("ROLLBACK")
            throw error
        }
    }
    
    /// Toggle task completion status
    func toggleTaskCompletion(taskID: String, completedBy: String = "System") {
        guard let taskIdInt = Int64(taskID) else {
            print("Invalid task ID format")
            return
        }
        
        do {
            guard let db = SQLiteManager.shared.db else {
                print("Database connection not available")
                return
            }
            
            // Get current completion status
            let rows = try db.prepare("SELECT isCompleted FROM tasks WHERE id = ?", taskIdInt)
            
            if let row = rows.next() {
                let currentStatus = row[0] as! Int64
                let newStatus = currentStatus == 0 ? 1 : 0
                
                // Update task status
                try db.run("UPDATE tasks SET isCompleted = ? WHERE id = ?", newStatus, taskIdInt)
                
                // If task is being marked as complete, add to history and handle recurring tasks
                if newStatus == 1 {
                    // Get task details for maintenance history
                    let taskRows = try db.prepare("SELECT name, buildingId FROM tasks WHERE id = ?", taskIdInt)
                    
                    if let taskRow = taskRows.next() {
                        let taskName = taskRow[0] as! String
                        let buildingId = taskRow[1] as! String
                        
                        // Get worker who completed the task
                        let workerQuery = "SELECT workerId FROM task_assignments WHERE taskId = ? LIMIT 1"
                        let workerRows = try db.prepare(workerQuery, taskIdInt)
                        let workerId = workerRows.next().flatMap { $0[0] as? String } ?? ""
                        
                        // Add to maintenance history
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        let completionDate = dateFormatter.string(from: Date())
                        
                        let historyQuery = """
                        INSERT INTO maintenance_history (
                            buildingId, taskId, taskName, notes, completionDate, completedBy, workerId
                        ) VALUES (?, ?, ?, ?, ?, ?, ?)
                        """
                        
                        try db.run(historyQuery, buildingId, "\(taskIdInt)", taskName, "Task marked as completed",
                                   completionDate, completedBy, workerId)
                    }
                    
                    // Handle recurring tasks
                    scheduleNextOccurrenceForTask(taskId: taskIdInt)
                }
                
                print("Successfully toggled completion status for task \(taskID) to \(newStatus)")
            } else {
                print("Task not found with ID: \(taskID)")
            }
        } catch {
            print("Error toggling task completion: \(error)")
        }
    }
    
    /// Schedule next occurrence for a completed recurring task
    private func scheduleNextOccurrenceForTask(taskId: Int64) {
        do {
            guard let db = SQLiteManager.shared.db else { return }
            
            let query = """
            SELECT name, description, buildingId, recurrence, urgencyLevel, category
            FROM tasks
            WHERE id = ? AND recurrence != ?
            """
            
            let rows = try db.prepare(query, taskId, "One Time")
            
            if let row = rows.next() {
                let name = row[0] as! String
                let description = row[1] as? String ?? ""
                let buildingId = row[2] as! String
                let recurrenceStr = row[3] as! String
                let urgencyStr = row[4] as! String
                let categoryStr = row[5] as! String
                
                guard let recurrence = FrancoSphere.TaskRecurrence(rawValue: recurrenceStr) else { return }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                var nextDate = Date()
                switch recurrence {
                case .daily:
                    nextDate = Calendar.current.date(byAdding: .day, value: 1, to: nextDate)!
                case .weekly:
                    nextDate = Calendar.current.date(byAdding: .day, value: 7, to: nextDate)!
                case .monthly:
                    nextDate = Calendar.current.date(byAdding: .month, value: 1, to: nextDate)!
                case .oneTime:
                    return
                case .biweekly:
                    nextDate = Calendar.current.date(byAdding: .day, value: 14, to: nextDate)!
                case .quarterly:
                    nextDate = Calendar.current.date(byAdding: .month, value: 3, to: nextDate)!
                case .semiannual:
                    nextDate = Calendar.current.date(byAdding: .month, value: 6, to: nextDate)!
                case .annual:
                    nextDate = Calendar.current.date(byAdding: .year, value: 1, to: nextDate)!
                }
                
                let nextDateStr = dateFormatter.string(from: nextDate)
                
                let insertQuery = """
                INSERT INTO tasks (
                    name, description, buildingId, scheduledDate, isCompleted,
                    recurrence, urgencyLevel, category
                )
                VALUES (?, ?, ?, ?, 0, ?, ?, ?)
                """
                
                try db.run(insertQuery, name, description, buildingId, nextDateStr,
                           recurrenceStr, urgencyStr, categoryStr)
                
                let newTaskId = db.lastInsertRowid
                
                // Copy worker assignments from the original task
                let assignmentsQuery = """
                INSERT INTO task_assignments (taskId, workerId)
                SELECT ?, workerId FROM task_assignments
                WHERE taskId = ?
                """
                
                try db.run(assignmentsQuery, newTaskId, taskId)
                
                print("Scheduled next occurrence for task \(name) on \(nextDateStr)")
            }
        } catch {
            print("Error scheduling next occurrence: \(error)")
        }
    }
    
    /// Schedule next occurrence for a recurring task based on a MaintenanceTask object
    private func scheduleNextOccurrence(task: FrancoSphere.MaintenanceTask) {
        guard task.recurrence != .oneTime,
              let nextTask = task.createNextOccurrence() else {
            return
        }
        
        _ = createTask(nextTask)
    }
    
    /// Add weather-based tasks to the database
    func createWeatherBasedTasks(for buildingID: String, tasks: [FrancoSphere.MaintenanceTask]) {
        for task in tasks {
            _ = createTask(task)
        }
        print("Successfully created \(tasks.count) weather-based tasks for building \(buildingID)")
    }
    
    /// Fetch maintenance history for a building
    func fetchMaintenanceHistory(forBuilding buildingId: String, limit: Int = 20) -> [FrancoSphere.MaintenanceRecord] {
        var records: [FrancoSphere.MaintenanceRecord] = []
        
        do {
            guard let db = SQLiteManager.shared.db else {
                print("Database connection not available")
                return []
            }
            
            let query = """
            SELECT id, taskId, taskName, notes, completionDate, completedBy, workerId
            FROM maintenance_history
            WHERE buildingId = ? 
            ORDER BY completionDate DESC
            LIMIT ?
            """
            
            let rows = try db.prepare(query, buildingId, limit)
            
            for row in rows {
                let id = row[0] as! Int64
                let taskId = row[1] as? String ?? ""
                let taskName = row[2] as! String
                let notes = row[3] as? String ?? ""
                let dateStr = row[4] as! String
                let completedBy = row[5] as! String
                let workerId = row[6] as? String ?? ""
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let completionDate = dateFormatter.date(from: dateStr) ?? Date()
                
                let record = FrancoSphere.MaintenanceRecord(
                    id: "\(id)",
                    taskId: taskId,
                    buildingID: buildingId,
                    workerId: workerId,
                    completionDate: completionDate,
                    notes: notes,
                    taskName: taskName,
                    completedBy: completedBy
                )
                
                records.append(record)
            }
            
        } catch {
            print("Error fetching maintenance history: \(error)")
        }
        
        return records
    }
    
    /// Get upcoming tasks for the next few days for a worker
    func getUpcomingTasks(forWorker workerId: String, days: Int = 7) -> [FrancoSphere.MaintenanceTask] {
        var allTasks: [FrancoSphere.MaintenanceTask] = []
        for day in 0..<days {
            let date = Calendar.current.date(byAdding: .day, value: day, to: Date())!
            let tasks = fetchTasks(forWorker: workerId, date: date)
            allTasks.append(contentsOf: tasks)
        }
        return allTasks.sorted { $0.dueDate < $1.dueDate }
    }
    
    /// Get tasks by category for a worker
    func getTasksByCategory(forWorker workerId: String) -> [FrancoSphere.TaskCategory: [FrancoSphere.MaintenanceTask]] {
        let allTasks = getUpcomingTasks(forWorker: workerId)
        var tasksByCategory: [FrancoSphere.TaskCategory: [FrancoSphere.MaintenanceTask]] = [:]
        
        // Initialize with empty arrays for all categories
        for category in FrancoSphere.TaskCategory.allCases {
            tasksByCategory[category] = []
        }
        
        // Add tasks to their respective category arrays
        for task in allTasks {
            tasksByCategory[task.category, default: []].append(task)
        }
        
        return tasksByCategory
    }
    
    /// Get past due tasks for a worker
    func getPastDueTasks(forWorker workerId: String) -> [FrancoSphere.MaintenanceTask] {
        let today = Calendar.current.startOfDay(for: Date())
        let tasks = fetchTasks(forWorker: workerId, date: Date())
        return tasks.filter { !$0.isComplete && $0.dueDate < today }
    }
    
    /// Get all task templates for creating new tasks
    func getAllTaskTemplates() -> [FrancoTaskTemplate] {
        return FrancoTaskTemplate.allTaskTemplates
    }
    
    /// Create a task from a template
    func createTaskFromTemplate(template: FrancoTaskTemplate, buildingId: String, dueDate: Date, workerIds: [String]) -> Bool {
        let task = template.createTask(buildingID: buildingId, dueDate: dueDate)
        var taskWithWorkers = task
        taskWithWorkers.assignedWorkers = workerIds
        return createTask(taskWithWorkers)
    }
    
    /// Fetch all tasks for a specific date range
    func fetchTasks(fromDate: Date, toDate: Date) -> [FrancoSphere.MaintenanceTask] {
        var tasks: [FrancoSphere.MaintenanceTask] = []
        
        do {
            guard let db = SQLiteManager.shared.db else {
                print("Database connection not available")
                return []
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let fromDateStr = dateFormatter.string(from: fromDate)
            let toDateStr = dateFormatter.string(from: toDate)
            
            let query = """
            SELECT t.id, t.name, t.description, t.buildingId, t.scheduledDate, t.isCompleted,
                   t.recurrence, t.urgencyLevel, t.category, t.startTime, t.endTime
            FROM tasks t
            WHERE t.scheduledDate >= ? AND t.scheduledDate <= ?
            ORDER BY t.scheduledDate ASC
            """
            
            let rows = try db.prepare(query, fromDateStr, toDateStr)
            
            for row in rows {
                let id = row[0] as! Int64
                let name = row[1] as! String
                let description = row[2] as? String ?? ""
                let buildingId = row[3] as! String
                let dateStr = row[4] as? String ?? ""
                let isCompleted = (row[5] as? Int64 ?? 0) == 1
                
                let recurrenceStr = row[6] as? String ?? "One Time"
                let urgencyStr = row[7] as? String ?? "Medium"
                let categoryStr = row[8] as? String ?? "Maintenance"
                let startTimeStr = row[9] as? String
                let endTimeStr = row[10] as? String
                
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dueDate = dateFormatter.date(from: dateStr) ?? Date()
                
                var startTime: Date? = nil
                var endTime: Date? = nil
                if let startStr = startTimeStr {
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    startTime = dateFormatter.date(from: startStr)
                }
                if let endStr = endTimeStr {
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    endTime = dateFormatter.date(from: endStr)
                }
                
                let recurrence = FrancoSphere.TaskRecurrence(rawValue: recurrenceStr) ?? .oneTime
                let urgency = FrancoSphere.TaskUrgency(rawValue: urgencyStr) ?? .medium
                let category = FrancoSphere.TaskCategory(rawValue: categoryStr) ?? .maintenance
                
                let assignedWorkers = fetchAssignedWorkers(taskId: id)
                
                let task = FrancoSphere.MaintenanceTask(
                    id: "\(id)",
                    name: name,
                    buildingID: buildingId,
                    description: description,
                    dueDate: dueDate,
                    startTime: startTime,
                    endTime: endTime,
                    category: category,
                    urgency: urgency,
                    recurrence: recurrence,
                    isComplete: isCompleted,
                    assignedWorkers: assignedWorkers
                )
                tasks.append(task)
            }
            
        } catch {
            print("Error fetching tasks for date range: \(error)")
        }
        
        return tasks
    }
    
    func retrieveTasks(forBuilding buildingId: String, includePastTasks: Bool = false) -> [FrancoSphere.MaintenanceTask] {
        // This is the same implementation as the original fetchTasks method
        var tasks: [FrancoSphere.MaintenanceTask] = []
        
        do {
            guard let db = SQLiteManager.shared.db else {
                print("Database connection not available")
                return []
            }
            
            let dateFilter = includePastTasks ? "" : "AND (t.isCompleted = 0 OR t.scheduledDate >= date('now'))"
            
            let query = """
            SELECT t.id, t.name, t.description, t.buildingId, t.scheduledDate, t.isCompleted,
                   t.recurrence, t.urgencyLevel, t.category, t.startTime, t.endTime
            FROM tasks t
            WHERE t.buildingId = ? \(dateFilter)
            ORDER BY t.scheduledDate ASC
            """
            
            let rows = try db.prepare(query, buildingId)
            for row in rows {
                let id = row[0] as! Int64
                let name = row[1] as! String
                let description = row[2] as? String ?? ""
                let buildingId = row[3] as! String
                let dateStr = row[4] as? String ?? ""
                let isCompleted = (row[5] as? Int64 ?? 0) == 1
                
                let recurrenceStr = row[6] as? String ?? "One Time"
                let urgencyStr = row[7] as? String ?? "Medium"
                let categoryStr = row[8] as? String ?? "Maintenance"
                let startTimeStr = row[9] as? String
                let endTimeStr = row[10] as? String
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dueDate = dateFormatter.date(from: dateStr) ?? Date()
                
                var startTime: Date? = nil
                var endTime: Date? = nil
                if let startStr = startTimeStr {
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    startTime = dateFormatter.date(from: startStr)
                }
                if let endStr = endTimeStr {
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    endTime = dateFormatter.date(from: endStr)
                }
                
                let recurrence = FrancoSphere.TaskRecurrence(rawValue: recurrenceStr) ?? .oneTime
                let urgency = FrancoSphere.TaskUrgency(rawValue: urgencyStr) ?? .medium
                let category = FrancoSphere.TaskCategory(rawValue: categoryStr) ?? .maintenance
                
                let assignedWorkers = fetchAssignedWorkers(taskId: id)
                
                let task = FrancoSphere.MaintenanceTask(
                    id: "\(id)",
                    name: name,
                    buildingID: buildingId,
                    description: description,
                    dueDate: dueDate,
                    startTime: startTime,
                    endTime: endTime,
                    category: category,
                    urgency: urgency,
                    recurrence: recurrence,
                    isComplete: isCompleted,
                    assignedWorkers: assignedWorkers
                )
                tasks.append(task)
            }
            
        } catch {
            print("Error fetching tasks for building: \(error)")
        }
        
        return tasks
    }
    
    // Update the two methods that are causing the ambiguity errors:
    
    /// Get tasks for a specific building and category
    func getTasks(forBuilding buildingId: String, category: FrancoSphere.TaskCategory? = nil) -> [FrancoSphere.MaintenanceTask] {
        // Changed fetchTasks to retrieveTasks
        let allTasks = retrieveTasks(forBuilding: buildingId, includePastTasks: false)
        
        // If no category filter is provided, return all tasks
        guard let category = category else {
            return allTasks
        }
        
        // Filter tasks by category
        return allTasks.filter { $0.category == category }
    }
    
    /// Get maintenance statistics for a building
    func getMaintenanceStats(forBuilding buildingId: String, period: Int = 30) -> (completed: Int, pending: Int, overdue: Int) {
        // Changed fetchTasks to retrieveTasks
        let allTasks = retrieveTasks(forBuilding: buildingId, includePastTasks: true)
        
        // Calculate date threshold for period
        let periodStart = Calendar.current.date(byAdding: .day, value: -period, to: Date())!
        
        // Filter tasks within the period
        let tasksInPeriod = allTasks.filter { $0.dueDate >= periodStart }
        
        // Count statistics
        let completed = tasksInPeriod.filter { $0.isComplete }.count
        let pending = tasksInPeriod.filter { !$0.isComplete && !$0.isPastDue }.count
        let overdue = tasksInPeriod.filter { !$0.isComplete && $0.isPastDue }.count
        
        return (completed, pending, overdue)
    }}
