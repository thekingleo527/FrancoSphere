// WorkerAssignmentManager.swift
// FrancoSphere
//
// Manager for worker assignments and skill matching

import Foundation
import SwiftUI

// MARK: - WorkerAssignmentManager
// Main manager for worker assignments

final class WorkerAssignmentManager: ObservableObject {
    // MARK: - Singleton
    static let shared = WorkerAssignmentManager()
    
    // Private init to ensure singleton
    private init() {}
    
    // MARK: - Worker Management
    
    /// Get workers assigned to a specific building
    func getWorkersForBuilding(buildingId: String) -> [FrancoSphere.WorkerProfile] {
        var workers: [FrancoSphere.WorkerProfile] = []
        
        // Get worker IDs assigned to this building
        let buildingWorkers = getAssignedWorkerIds(for: buildingId)
        
        for workerId in buildingWorkers {
            if let worker = getWorkerById(workerId) {
                workers.append(worker)
            }
        }
        
        return workers
    }
    
    /// Get worker IDs assigned to a building
    private func getAssignedWorkerIds(for buildingId: String) -> [String] {
        // Building to worker assignments based on updated data
        switch buildingId {
        case "1":  // 12 West 18th Street
            return ["1", "7", "8"]  // Greg Hutson, Angel Guirachocha, Shawn Magloire
        case "2":  // 29-31 East 20th Street
            return ["2", "5"]       // Edwin Lema, Mercedes Inamagua
        case "3":  // 36 Walker Street
            return ["3", "4"]       // Jose Santos, Kevin Dutan
        case "4":  // 41 Elizabeth Street
            return ["1", "6"]       // Greg Hutson, Luis Lopez
        case "5":  // 68 Perry Street
            return ["2", "7"]       // Edwin Lema, Angel Guirachocha
        case "6":  // 104 Franklin Street
            return ["3", "5"]       // Jose Santos, Mercedes Inamagua
        case "7":  // 112 West 18th Street
            return ["1", "4"]       // Greg Hutson, Kevin Dutan
        case "8":  // 117 West 17th Street
            return ["2", "6"]       // Edwin Lema, Luis Lopez
        case "9":  // 123 1st Avenue
            return ["3", "7"]       // Jose Santos, Angel Guirachocha
        case "10": // 131 Perry Street
            return ["1", "5"]       // Greg Hutson, Mercedes Inamagua
        case "11": // 133 East 15th Street
            return ["2", "4"]       // Edwin Lema, Kevin Dutan
        case "12": // 135-139 West 17th Street
            return ["1", "3"]       // Greg Hutson, Jose Santos
        case "13": // 136 West 17th Street
            return ["6", "7"]       // Luis Lopez, Angel Guirachocha
        case "14": // Rubin Museum (142-148 W 17th)
            return ["8"]            // Shawn Magloire
        case "15": // Stuyvesant Cove Park
            return ["7"]            // Angel Guirachocha
        case "16": // 138 West 17th Street
            return ["4"]            // Kevin Dutan
        default:
            return []
        }
    }
    
    /// Get worker by ID
    private func getWorkerById(_ workerId: String) -> FrancoSphere.WorkerProfile? {
        // Real worker data based on provided emails
        switch workerId {
        case "1":
            return FrancoSphere.WorkerProfile(
                id: "1",
                name: "Greg Hutson",
                email: "g.hutson1989@gmail.com",
                role: .worker,
                skills: [.maintenance, .repair, .electrical],
                assignedBuildings: ["1", "4", "7", "10", "12"],
                skillLevel: .advanced
            )
        case "2":
            return FrancoSphere.WorkerProfile(
                id: "2",
                name: "Edwin Lema",
                email: "edwinlema911@gmail.com",
                role: .worker,
                skills: [.cleaning, .sanitation, .inspection],
                assignedBuildings: ["2", "5", "8", "11"],
                skillLevel: .intermediate
            )
        case "3":
            return FrancoSphere.WorkerProfile(
                id: "3",
                name: "Jose Santos",
                email: "josesantos14891989@gmail.com",
                role: .worker,
                skills: [.maintenance, .repair, .plumbing],
                assignedBuildings: ["3", "6", "9", "12"],
                skillLevel: .intermediate
            )
        case "4":
            return FrancoSphere.WorkerProfile(
                id: "4",
                name: "Kevin Dutan",
                email: "dutankevin1@gmail.com",
                role: .worker,
                skills: [.hvac, .electrical, .technical],
                assignedBuildings: ["3", "7", "11", "16"],
                skillLevel: .advanced
            )
        case "5":
            return FrancoSphere.WorkerProfile(
                id: "5",
                name: "Mercedes Inamagua",
                email: "Jneola@gmail.com",
                role: .worker,
                skills: [.cleaning, .sanitation],
                assignedBuildings: ["2", "6", "10"],
                skillLevel: .intermediate
            )
        case "6":
            return FrancoSphere.WorkerProfile(
                id: "6",
                name: "Luis Lopez",
                email: "luislopez030@yahoo.com",
                role: .worker,
                skills: [.maintenance, .manual, .inspection],
                assignedBuildings: ["4", "8", "13"],
                skillLevel: .intermediate
            )
        case "7":
            return FrancoSphere.WorkerProfile(
                id: "7",
                name: "Angel Guirachocha",
                email: "lio.angel71@gmail.com",
                role: .worker,
                skills: [.cleaning, .sanitation, .manual],
                assignedBuildings: ["1", "5", "9", "13", "15"],
                skillLevel: .intermediate
            )
        case "8":
            return FrancoSphere.WorkerProfile(
                id: "8",
                name: "Shawn Magloire",
                email: "shawn@francomanagementgroup.com",
                role: .admin,
                skills: [.management, .inspection, .maintenance, .hvac, .electrical, .plumbing],
                assignedBuildings: ["1", "14"],
                skillLevel: .expert
            )
        default:
            return nil
        }
    }
    
    /// Get all workers
    func getAllWorkers() -> [FrancoSphere.WorkerProfile] {
        return (1...8).compactMap { getWorkerById(String($0)) }
    }
    
    /// Get workers with specific skills for task assignment
    func getSkilledWorkers(category: FrancoSphere.TaskCategory, urgency: FrancoSphere.TaskUrgency) -> [String] {
        var skilledWorkers: [String] = []
        
        // Map task categories to worker skills
        let requiredSkills = mapCategoryToSkills(category)
        
        // Get all workers
        let allWorkers = getAllWorkers()
        
        // Filter workers by skills and urgency level
        for worker in allWorkers {
            // Check if worker has required skills
            let hasRequiredSkill = worker.skills.contains { skill in
                requiredSkills.contains(skill)
            }
            
            // Check if worker's skill level matches urgency
            let meetsUrgencyRequirement = isQualifiedForUrgency(
                skillLevel: worker.skillLevel,
                urgency: urgency
            )
            
            if hasRequiredSkill && meetsUrgencyRequirement {
                skilledWorkers.append(worker.id)
            }
        }
        
        return skilledWorkers
    }
    
    /// Map task categories to required worker skills
    private func mapCategoryToSkills(_ category: FrancoSphere.TaskCategory) -> [FrancoSphere.WorkerSkill] {
        switch category {
        case .maintenance:
            return [.maintenance, .hvac, .plumbing, .electrical]
        case .cleaning:
            return [.cleaning, .sanitation]
        case .repair:
            return [.repair, .electrical, .plumbing, .maintenance]
        case .inspection:
            return [.inspection, .security, .management]
        case .sanitation:
            return [.sanitation, .cleaning]
        }
    }
    
    /// Check if worker's skill level qualifies for task urgency
    private func isQualifiedForUrgency(skillLevel: FrancoSphere.SkillLevel, urgency: FrancoSphere.TaskUrgency) -> Bool {
        switch urgency {
        case .low:
            return true // Any skill level can handle low urgency
        case .medium:
            return skillLevel != .basic
        case .high:
            return skillLevel == .advanced || skillLevel == .expert
        case .urgent:
            return skillLevel == .expert
        }
    }
    
    /// Get worker skills - returns generic WorkerSkill enum values
    func getWorkerSkills(workerId: String) -> [FrancoSphere.WorkerSkill] {
        guard let worker = getWorkerById(workerId) else { return [] }
        return worker.skills
    }
    
    /// Check if worker has required skills for a task
    func workerHasRequiredSkills(workerId: String, taskCategory: FrancoSphere.TaskCategory, urgency: FrancoSphere.TaskUrgency) -> Bool {
        guard let worker = getWorkerById(workerId) else { return false }
        
        let requiredSkills = mapCategoryToSkills(taskCategory)
        let hasSkill = worker.skills.contains { skill in
            requiredSkills.contains(skill)
        }
        
        let meetsUrgency = isQualifiedForUrgency(
            skillLevel: worker.skillLevel,
            urgency: urgency
        )
        
        return hasSkill && meetsUrgency
    }
    
    /// Get workers for a specific building with optional skill filter
    func getWorkersForBuilding(buildingId: String, withSkill skill: FrancoSphere.WorkerSkill? = nil) -> [FrancoSphere.WorkerProfile] {
        let workers = getWorkersForBuilding(buildingId: buildingId)
        
        guard let requiredSkill = skill else { return workers }
        
        return workers.filter { $0.skills.contains(requiredSkill) }
    }
    
    /// Get worker by email
    func getWorkerByEmail(_ email: String) -> FrancoSphere.WorkerProfile? {
        return getAllWorkers().first { $0.email.lowercased() == email.lowercased() }
    }
    
    /// Get worker's assigned building names
    func getAssignedBuildingNames(for workerId: String) -> [String] {
        guard let worker = getWorkerById(workerId) else { return [] }
        
        return worker.assignedBuildings.compactMap { buildingId in
            FrancoSphere.NamedCoordinate.getBuilding(byId: buildingId)?.name
        }
    }
}
