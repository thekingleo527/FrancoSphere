// UPDATED: Using centralized TypeRegistry for all types
import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


// MARK: - Worker Skill Models

/// Use a namespace to avoid ambiguity with WorkerSkill
enum LocalModels {
    /// Represents a skill for a worker.
    struct WorkerSkill: Identifiable, Codable, Hashable, Equatable {
        let id: String
        let name: String
        let category: Category  // Using nested Category enum
        let level: Int          // Rating from 1 to 5
        let certifications: [String]
        let description: String
        
        init(id: String = UUID().uuidString,
             name: String,
             category: Category,
             level: Int = 1,
             certifications: [String] = [],
             description: String = "") {
            self.id = id
            self.name = name
            self.category = category
            self.level = level
            self.certifications = certifications
            self.description = description
        }
        
        // Add Equatable implementation
        static func == (lhs: WorkerSkill, rhs: WorkerSkill) -> Bool {
            return lhs.id == rhs.id &&
                   lhs.name == rhs.name &&
                   lhs.category == rhs.category &&
                   lhs.level == rhs.level
        }
        
        // Add Hashable implementation
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(name)
            hasher.combine(category)
            hasher.combine(level)
        }
        
        var isAdvanced: Bool {
            return level >= 4
        }
        
        var levelText: String {
            switch level {
            case 1: return "Beginner"
            case 2: return "Basic"
            case 3: return "Intermediate"
            case 4: return "Advanced"
            case 5: return "Expert"
            default: return "Unknown"
            }
        }
        
        /// Returns the task categories compatible with this skill.
        func compatibleTaskCategories() -> [TaskCategory] {
            switch category {
            case .maintenance:
                return [TaskCategory.maintenance, TaskCategory.repair]
            case .cleaning:
                return [TaskCategory.cleaning, TaskCategory.sanitation]
            case .repair:
                return [TaskCategory.repair, TaskCategory.maintenance]
            case .inspection:
                return [TaskCategory.inspection]
            case .sanitation:
                return [TaskCategory.sanitation, TaskCategory.cleaning]
            case .electrical:
                return [TaskCategory.maintenance, TaskCategory.repair]
            case .plumbing:
                return [TaskCategory.maintenance, TaskCategory.repair]
            case .hvac:
                return [TaskCategory.maintenance]
            case .security:
                return [TaskCategory.inspection]
            case .management:
                return [TaskCategory.inspection]
            case .technical, .manual, .administrative:  // Handle additional cases
                return []
            }
        }
        
        /// Returns the maximum task urgency level this worker can handle based on their skill level.
        func maxTaskUrgency() -> TaskUrgency {
            switch level {
            case 1: return TaskUrgency.low
            case 2: return TaskUrgency.medium
            case 3: return TaskUrgency.medium
            case 4: return TaskUrgency.high
            case 5: return TaskUrgency.urgent
            default: return TaskUrgency.low
            }
        }
        
        /// Determines if the worker can handle a specific task based on task category and urgency.
        func canHandle(taskCategory: TaskCategory, urgency: TaskUrgency) -> Bool {
            let validCategories = compatibleTaskCategories()
            let maxUrgency = maxTaskUrgency()
            return validCategories.contains(taskCategory) &&
                   getUrgencyValue(urgency) <= getUrgencyValue(maxUrgency)
        }
        
        private func getUrgencyValue(_ urgency: TaskUrgency) -> Int {
            switch urgency {
            case .low: return 1
            case .medium: return 2
            case .high: return 3
            case .urgent: return 4
            }
        }
        
        // Define Category enum within WorkerSkill
        enum Category: String, Codable, CaseIterable, Hashable {
            case technical = "Technical"
            case manual = "Manual"
            case administrative = "Administrative"
            case cleaning = "Cleaning"
            case repair = "Repair"
            case inspection = "Inspection"
            case sanitation = "Sanitation"
            case maintenance = "Maintenance"
            case electrical = "Electrical"
            case plumbing = "Plumbing"
            case hvac = "HVAC"
            case security = "Security"
            case management = "Management"
        }
    }
}

// Create top-level type alias for easier access
typealias WorkerSkillModel = LocalModels.WorkerSkill
typealias WorkerSkillCategory = LocalModels.WorkerSkill.Category

// MARK: - Worker Skills Manager

class WorkerSkillsManager {
    static let shared = WorkerSkillsManager()
    
    private init() {}
    
    /// Returns all skills for a given worker.
    func getSkills(for workerId: String) -> [WorkerSkillModel] {
        return sampleSkills(for: workerId)
    }
    
    /// Updates a worker's skill in the database.
    func updateSkill(_ skill: WorkerSkillModel, for workerId: String) -> Bool {
        print("Updating skill \(skill.name) for worker \(workerId)")
        return true
    }
    
    /// Adds a new skill for a worker in the database.
    func addSkill(_ skill: WorkerSkillModel, for workerId: String) -> Bool {
        print("Adding skill \(skill.name) for worker \(workerId)")
        return true
    }
    
    /// Removes a skill from a worker in the database.
    func removeSkill(_ skillId: String, for workerId: String) -> Bool {
        print("Removing skill \(skillId) for worker \(workerId)")
        return true
    }
    
    /// Creates sample skills for demonstration purposes.
    private func sampleSkills(for workerId: String) -> [WorkerSkillModel] {
        return [
            WorkerSkillModel(
                name: "General Maintenance",
                category: .maintenance,
                level: 4,
                certifications: ["Building Maintenance Certification"],
                description: "General building maintenance including minor repairs"
            ),
            WorkerSkillModel(
                name: "Cleaning",
                category: .cleaning,
                level: 3,
                certifications: [],
                description: "Standard cleaning procedures and handling of cleaning chemicals"
            ),
            WorkerSkillModel(
                name: "Basic Electrical",
                category: .electrical,
                level: 2,
                certifications: ["Basic Electrical Safety"],
                description: "Light fixture replacement, outlet repair, basic wiring"
            ),
            WorkerSkillModel(
                name: "Plumbing Repairs",
                category: .plumbing,
                level: 3,
                certifications: ["Plumbing Basics"],
                description: "Fixing leaks, unclogging drains, toilet repairs"
            ),
            WorkerSkillModel(
                name: "HVAC Maintenance",
                category: .hvac,
                level: 2,
                certifications: [],
                description: "Filter replacement, basic maintenance, troubleshooting"
            )
        ]
    }
    
    /// Returns skills grouped by their category.
    func getSkillsByCategory(for workerId: String) -> [WorkerSkillCategory: [WorkerSkillModel]] {
        let skills = getSkills(for: workerId)
        var skillsByCategory: [WorkerSkillCategory: [WorkerSkillModel]] = [:]
        for category in WorkerSkillCategory.allCases {
            skillsByCategory[category] = skills.filter { $0.category == category }
        }
        return skillsByCategory
    }
    
    /// Checks if a worker has the required skills for a specific task.
    func workerHasRequiredSkills(workerId: String, taskCategory: TaskCategory, urgency: TaskUrgency) -> Bool {
        let skills = getSkills(for: workerId)
        return skills.contains { $0.canHandle(taskCategory: taskCategory, urgency: urgency) }
    }
}

// Additional cases to make switch statements exhaustive
extension WorkerSkill {
    public static var allCases: [WorkerSkill] {
        return [.basic, .intermediate, .advanced, .expert, .specialized]
    }
}
