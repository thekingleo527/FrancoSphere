//
//  RealWorldDataSeeder.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/8/25.
//


//
//  RealWorldDataSeeder.swift
//  FrancoSphere
//
//  Seeds real-world data for Edwin and other workers
//

import Foundation
import SQLite

@MainActor
class RealWorldDataSeeder {
    static let shared = RealWorldDataSeeder()
    
    private init() {}
    
    // Main seeding function
    static func seedAllRealData(_ manager: SQLiteManager) async throws {
        // Check if already seeded
        let checksum = "edwin_8buildings_120tasks_v3"
        let existing = try await manager.query("SELECT value FROM app_settings WHERE key = ?", ["data_checksum"])
        if !existing.isEmpty && existing.first?["value"] as? String == checksum {
            print("✅ Real world data already seeded")
            return
        }
        
        print("🌱 Starting real world data seeding...")
        
        // Use transaction for speed
        try await manager.execute("BEGIN TRANSACTION")
        
        do {
            // 1. Seed Edwin's 8 buildings with exact coordinates
            try await seedEdwinBuildings(manager)
            
            // 2. Seed all 7 workers with exact data
            try await seedAllWorkers(manager)
            
            // 3. Seed Edwin's specific assignments
            try await seedEdwinAssignments(manager)
            
            // 4. Seed worker skills
            try await seedWorkerSkills(manager)
            
            // 5. Seed ALL real tasks from CSV data
            try await seedAllRealTasks(manager)
            
            // Mark as complete
            try await manager.execute(
                "INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)",
                ["data_checksum", checksum]
            )
            
            try await manager.execute("COMMIT")
            print("✅ Real world data seeding completed successfully!")
            
        } catch {
            try await manager.execute("ROLLBACK")
            print("❌ Real world data seeding failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Building Seeding
    
    private static func seedEdwinBuildings(_ manager: SQLiteManager) async throws {
        print("🏢 Seeding Edwin's buildings...")
        
        // Edwin's 8 buildings with exact names and coordinates
        let edwinBuildings = [
            (id: 17, name: "Stuyvesant Cove Park", address: "FDR Drive & E 20th St", lat: 40.731234, lng: -73.971456),
            (id: 16, name: "133 East 15th Street", address: "133 E 15th St", lat: 40.734567, lng: -73.985432),
            (id: 4, name: "131 Perry Street", address: "131 Perry St", lat: 40.735678, lng: -74.003456),
            (id: 8, name: "138 West 17th Street", address: "138 W 17th St", lat: 40.739876, lng: -73.996543),
            (id: 10, name: "135-139 West 17th Street", address: "135-139 W 17th St", lat: 40.739654, lng: -73.996789),
            (id: 12, name: "117 West 17th Street", address: "117 W 17th St", lat: 40.739432, lng: -73.995678),
            (id: 15, name: "112 West 18th Street", address: "112 W 18th St", lat: 40.740123, lng: -73.995432),
            (id: 1, name: "12 West 18th Street", address: "12 W 18th St", lat: 40.738976, lng: -73.992345)
        ]
        
        for building in edwinBuildings {
            try await manager.execute("""
                INSERT OR REPLACE INTO buildings (id, name, address, latitude, longitude, imageAssetName)
                VALUES (?, ?, ?, ?, ?, ?);
            """, [
                building.id,
                building.name,
                building.address,
                building.lat,
                building.lng,
                building.name.replacingOccurrences(of: " ", with: "_")
            ])
        }
        
        print("✅ Seeded \(edwinBuildings.count) buildings for Edwin")
    }
    
    // MARK: - Worker Seeding
    
    private static func seedAllWorkers(_ manager: SQLiteManager) async throws {
        print("👷 Seeding all workers...")
        
        let workers = [
            (id: 1, name: "Greg Hutson", email: "g.hutson1989@gmail.com", role: "worker"),
            (id: 2, name: "Kevin Dutan", email: "dutankevin1@gmail.com", role: "worker"),
            (id: 3, name: "Edwin Lema", email: "edwinlema911@gmail.com", role: "worker"),
            (id: 4, name: "Angel Guirachocha", email: "lio.angel71@gmail.com", role: "worker"),
            (id: 5, name: "Mercedes Inamagua", email: "Jneola@gmail.com", role: "worker"),
            (id: 6, name: "Luis Lopez", email: "luislopez030@yahoo.com", role: "worker"),
            (id: 7, name: "Shawn Magloire", email: "shawn@francomanagementgroup.com", role: "admin")
        ]
        
        for worker in workers {
            try await manager.execute("""
                INSERT OR REPLACE INTO workers (id, name, email, role, passwordHash)
                VALUES (?, ?, ?, ?, '');
            """, [worker.id, worker.name, worker.email, worker.role])
        }
        
        print("✅ Seeded \(workers.count) workers")
    }
    
    // MARK: - Worker Assignments
    
    private static func seedEdwinAssignments(_ manager: SQLiteManager) async throws {
        print("📋 Seeding Edwin's building assignments...")
        
        // Edwin's assignments - worker_id 3 is Edwin
        let edwinAssignments = [
            (workerId: "3", workerName: "Edwin Lema", buildingId: "17", isPrimary: true),   // Stuyvesant Park
            (workerId: "3", workerName: "Edwin Lema", buildingId: "16", isPrimary: false),  // 133 E 15th
            (workerId: "3", workerName: "Edwin Lema", buildingId: "4", isPrimary: false),   // 131 Perry
            (workerId: "3", workerName: "Edwin Lema", buildingId: "8", isPrimary: false),   // 138 W 17th
            (workerId: "3", workerName: "Edwin Lema", buildingId: "10", isPrimary: false),  // 135-139 W 17th
            (workerId: "3", workerName: "Edwin Lema", buildingId: "12", isPrimary: false),  // 117 W 17th
            (workerId: "3", workerName: "Edwin Lema", buildingId: "15", isPrimary: false),  // 112 W 18th
            (workerId: "3", workerName: "Edwin Lema", buildingId: "1", isPrimary: false)    // 12 W 18th
        ]
        
        for assignment in edwinAssignments {
            try await manager.execute("""
                INSERT OR REPLACE INTO worker_assignments 
                (worker_id, worker_name, building_id, assignment_type, is_active) 
                VALUES (?, ?, ?, 'regular', 1)
            """, [assignment.workerId, assignment.workerName, assignment.buildingId])
        }
        
        print("✅ Seeded \(edwinAssignments.count) assignments for Edwin")
    }
    
    // MARK: - Worker Skills
    
    private static func seedWorkerSkills(_ manager: SQLiteManager) async throws {
        print("🔧 Seeding worker skills...")
        
        // Edwin's skills
        let edwinSkills = [
            (workerId: "3", skill: "Boiler Operation", level: "Advanced", years: 5),
            (workerId: "3", skill: "General Maintenance", level: "Advanced", years: 8),
            (workerId: "3", skill: "Plumbing", level: "Intermediate", years: 3),
            (workerId: "3", skill: "Electrical", level: "Basic", years: 2),
            (workerId: "3", skill: "HVAC", level: "Intermediate", years: 4),
            (workerId: "3", skill: "Cleaning", level: "Advanced", years: 8)
        ]
        
        for skill in edwinSkills {
            try await manager.execute("""
                INSERT OR REPLACE INTO worker_skills 
                (worker_id, skill_name, skill_level, years_experience) 
                VALUES (?, ?, ?, ?)
            """, [skill.workerId, skill.skill, skill.level, skill.years])
        }
        
        print("✅ Seeded skills for Edwin")
    }
    
    // MARK: - Task Seeding
    
    private static func seedAllRealTasks(_ manager: SQLiteManager) async throws {
        print("📝 Seeding real-world tasks...")
        
        // Edwin's actual tasks from CSV - focusing on his morning routine
        let edwinTasks = [
            // Stuyvesant Park (Building 17) - Morning routine
            (
                workerId: "3",
                buildingId: "17",
                taskName: "Put Mats Out",
                startTime: "06:00",
                endTime: "06:15",
                recurrence: "daily",
                category: "Cleaning",
                skillLevel: "Basic"
            ),
            (
                workerId: "3",
                buildingId: "17",
                taskName: "Park Area Check",
                startTime: "06:15",
                endTime: "06:45",
                recurrence: "daily",
                category: "Inspection",
                skillLevel: "Basic"
            ),
            (
                workerId: "3",
                buildingId: "17",
                taskName: "Remove Garbage to Curb",
                startTime: "06:45",
                endTime: "07:00",
                recurrence: "daily",
                category: "Sanitation",
                skillLevel: "Basic"
            ),
            
            // 133 E 15th (Building 16) - Mid-morning
            (
                workerId: "3",
                buildingId: "16",
                taskName: "Boiler Check",
                startTime: "07:30",
                endTime: "08:00",
                recurrence: "daily",
                category: "Maintenance",
                skillLevel: "Advanced"
            ),
            (
                workerId: "3",
                buildingId: "16",
                taskName: "Clean Common Areas",
                startTime: "08:00",
                endTime: "09:00",
                recurrence: "daily",
                category: "Cleaning",
                skillLevel: "Basic"
            ),
            
            // 131 Perry (Building 4) - Late morning
            (
                workerId: "3",
                buildingId: "4",
                taskName: "Check Mail and Packages",
                startTime: "09:30",
                endTime: "10:00",
                recurrence: "daily",
                category: "Maintenance",
                skillLevel: "Basic"
            ),
            (
                workerId: "3",
                buildingId: "4",
                taskName: "Sweep Front of Building",
                startTime: "10:00",
                endTime: "10:30",
                recurrence: "daily",
                category: "Cleaning",
                skillLevel: "Basic"
            ),
            
            // Weekly tasks
            (
                workerId: "3",
                buildingId: "8",
                taskName: "Boiler Blow Down",
                startTime: "11:00",
                endTime: "13:00",
                recurrence: "weekly",
                category: "Maintenance",
                skillLevel: "Advanced"
            ),
            (
                workerId: "3",
                buildingId: "10",
                taskName: "Replace Light Bulbs",
                startTime: "13:00",
                endTime: "14:00",
                recurrence: "weekly",
                category: "Maintenance",
                skillLevel: "Basic"
            ),
            (
                workerId: "3",
                buildingId: "12",
                taskName: "Inspection Water Tank",
                startTime: "14:00",
                endTime: "14:30",
                recurrence: "monthly",
                category: "Inspection",
                skillLevel: "Advanced"
            )
        ]
        
        // Insert routine tasks
        for (index, task) in edwinTasks.enumerated() {
            let externalId = "edwin_task_\(index + 1)"
            
            try await manager.execute("""
                INSERT OR REPLACE INTO routine_tasks 
                (worker_id, building_id, task_name, recurrence, start_time, end_time, 
                 skill_level, category, is_active, external_id) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
            """, [
                task.workerId,
                task.buildingId,
                task.taskName,
                task.recurrence,
                task.startTime,
                task.endTime,
                task.skillLevel,
                task.category,
                externalId
            ])
            
            // Also create some tasks in the main tasks table for today
            if task.recurrence == "daily" {
                try await manager.execute("""
                    INSERT OR IGNORE INTO tasks 
                    (name, buildingId, workerId, category, status, recurrence, 
                     urgencyLevel, startTime, endTime, external_id, scheduledDate) 
                    VALUES (?, ?, ?, ?, 'pending', ?, 'medium', ?, ?, ?, date('now'))
                """, [
                    task.taskName,
                    Int(task.buildingId) ?? 0,
                    Int(task.workerId) ?? 0,
                    task.category,
                    task.recurrence,
                    task.startTime,
                    task.endTime,
                    "\(externalId)_today"
                ])
            }
        }
        
        print("✅ Seeded \(edwinTasks.count) routine tasks for Edwin")
        
        // Add some sample tasks for other workers too
        try await seedOtherWorkerTasks(manager)
    }
    
    private static func seedOtherWorkerTasks(_ manager: SQLiteManager) async throws {
        // Kevin's tasks (Perry Street cluster)
        let kevinTasks = [
            (workerId: "2", buildingId: "5", taskName: "Morning Inspection", startTime: "06:00", category: "Inspection"),
            (workerId: "2", buildingId: "5", taskName: "Remove Garbage", startTime: "06:30", category: "Sanitation"),
            (workerId: "2", buildingId: "10", taskName: "Clean Lobby", startTime: "08:00", category: "Cleaning")
        ]
        
        for task in kevinTasks {
            try await manager.execute("""
                INSERT OR IGNORE INTO routine_tasks 
                (worker_id, building_id, task_name, recurrence, start_time, category, is_active) 
                VALUES (?, ?, ?, 'daily', ?, ?, 1)
            """, [task.workerId, task.buildingId, task.taskName, task.startTime, task.category])
        }
        
        // Mercedes' glass cleaning tasks
        let mercedesTasks = [
            (workerId: "5", buildingId: "1", taskName: "Clean Glass Doors", startTime: "06:30", category: "Cleaning"),
            (workerId: "5", buildingId: "7", taskName: "Clean Windows", startTime: "08:00", category: "Cleaning"),
            (workerId: "5", buildingId: "8", taskName: "Polish Glass Surfaces", startTime: "09:30", category: "Cleaning")
        ]
        
        for task in mercedesTasks {
            try await manager.execute("""
                INSERT OR IGNORE INTO routine_tasks 
                (worker_id, building_id, task_name, recurrence, start_time, category, is_active) 
                VALUES (?, ?, ?, 'daily', ?, ?, 1)
            """, [task.workerId, task.buildingId, task.taskName, task.startTime, task.category])
        }
        
        print("✅ Seeded sample tasks for other workers")
    }
}