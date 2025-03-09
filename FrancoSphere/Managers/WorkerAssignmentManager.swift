import Foundation
import SQLite

class WorkerAssignmentManager {
    // MARK: - Worker Management
    
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
    
    private func getAssignedWorkerIds(for buildingId: String) -> [String] {
        // Building to worker assignments based on updated, correct data
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
        default:
            return []
        }
    }
    
    private func getWorkerById(_ workerId: String) -> FrancoSphere.WorkerProfile? {
        // Real worker data based on provided emails and updated names
        switch workerId {
        case "1":
            return FrancoSphere.WorkerProfile(
                id: "1",
                name: "Greg Hutson",
                email: "g.hutson1989@gmail.com",
                role: .worker,
                skills: [.maintenance, .repair, .electrical],
                assignedBuildings: ["1", "4", "7", "10", "12"]
            )
        case "2":
            return FrancoSphere.WorkerProfile(
                id: "2",
                name: "Edwin Lema",
                email: "edwinlema911@gmail.com",
                role: .worker,
                skills: [.cleaning, .sanitation, .inspection],
                assignedBuildings: ["2", "5", "8", "11"]
            )
        case "3":
            return FrancoSphere.WorkerProfile(
                id: "3",
                name: "Jose Santos",
                email: "josesantos14891989@gmail.com",
                role: .worker,
                skills: [.maintenance, .repair, .plumbing],
                assignedBuildings: ["3", "6", "9", "12"]
            )
        case "4":
            return FrancoSphere.WorkerProfile(
                id: "4",
                name: "Kevin Dutan",
                email: "dutankevin1@gmail.com",
                role: .worker,
                skills: [.hvac, .electrical, .technical],
                assignedBuildings: ["3", "7", "11"]
            )
        case "5":
            return FrancoSphere.WorkerProfile(
                id: "5",
                name: "Mercedes Inamagua",
                email: "Jneola@gmail.com",
                role: .worker,
                skills: [.cleaning, .sanitation],
                assignedBuildings: ["2", "6", "10"]
            )
        case "6":
            return FrancoSphere.WorkerProfile(
                id: "6",
                name: "Luis Lopez",
                email: "luislopez030@yahoo.com",
                role: .worker,
                skills: [.maintenance, .manual, .inspection],
                assignedBuildings: ["4", "8", "13"]
            )
        case "7":
            return FrancoSphere.WorkerProfile(
                id: "7",
                name: "Angel Guirachocha",
                email: "lio.angel71@gmail.com",
                role: .worker,
                skills: [.cleaning, .sanitation, .manual],
                assignedBuildings: ["1", "5", "9", "13"]
            )
        case "8":
            return FrancoSphere.WorkerProfile(
                id: "8",
                name: "Shawn Magloire",
                email: "shawn@francomanagementgroup.com",
                role: .worker,
                skills: [.management, .inspection, .maintenance, .hvac, .electrical, .plumbing],
                assignedBuildings: ["1", "14"]
            )
        default:
            return nil
        }
    }
    
    // Get workers with a specific skill (for task assignment)
    func getSkilledWorkers(category: FrancoSphere.TaskCategory, urgency: FrancoSphere.TaskUrgency) -> [String] {
        var skilledWorkers: [String] = []
        
        // Map task categories to worker skills
        let requiredSkills: [FrancoSphere.WorkerSkill] = mapCategoryToSkills(category)
        
        // Get all workers
        let allWorkers = getAllWorkers()
        
        // Filter workers by skills
        for worker in allWorkers {
            for skill in requiredSkills {
                if worker.skills.contains(skill) {
                    skilledWorkers.append(worker.id)
                    break
                }
            }
        }
        
        return skilledWorkers
    }
    
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
    
    private func getAllWorkers() -> [FrancoSphere.WorkerProfile] {
        // Return all real workers
        return [
            getWorkerById("1"), // Greg Hutson
            getWorkerById("2"), // Edwin Lema
            getWorkerById("3"), // Jose Santos
            getWorkerById("4"), // Kevin Dutan
            getWorkerById("5"), // Mercedes Inamagua
            getWorkerById("6"), // Luis Lopez
            getWorkerById("7"), // Angel Guirachocha
            getWorkerById("8")  // Shawn Magloire
        ].compactMap { $0 }
    }
    
    // Get worker skills from local storage
    func getWorkerSkills(workerId: String) -> [System.WorkerSkill] {
        // Return skills for each real worker
        switch workerId {
        case "1": // Greg Hutson
            return [
                System.WorkerSkill(
                    id: "1-1",
                    name: "General Maintenance",
                    category: .maintenance,
                    level: 4,
                    certifications: ["Building Maintenance Certification"],
                    description: "General building maintenance and repairs"
                ),
                System.WorkerSkill(
                    id: "1-2",
                    name: "Electrical Systems",
                    category: .electrical,
                    level: 3,
                    certifications: ["Basic Electrical Safety"],
                    description: "Basic electrical repairs and troubleshooting"
                ),
                System.WorkerSkill(
                    id: "1-3",
                    name: "Repair Work",
                    category: .repair,
                    level: 4,
                    certifications: [],
                    description: "Various repair skills for building systems"
                )
            ]
        case "2": // Edwin Lema
            return [
                System.WorkerSkill(
                    id: "2-1",
                    name: "Commercial Cleaning",
                    category: .cleaning,
                    level: 5,
                    certifications: ["Commercial Cleaning Standards"],
                    description: "Professional cleaning for commercial spaces"
                ),
                System.WorkerSkill(
                    id: "2-2",
                    name: "Sanitation",
                    category: .sanitation,
                    level: 4,
                    certifications: ["Health & Safety"],
                    description: "Sanitation procedures for public areas"
                ),
                System.WorkerSkill(
                    id: "2-3",
                    name: "Inspection",
                    category: .inspection,
                    level: 3,
                    certifications: [],
                    description: "Property inspections and reporting"
                )
            ]
        case "3": // Jose Santos
            return [
                System.WorkerSkill(
                    id: "3-1",
                    name: "Plumbing Systems",
                    category: .plumbing,
                    level: 4,
                    certifications: ["Plumbing Basics"],
                    description: "Plumbing maintenance and repairs"
                ),
                System.WorkerSkill(
                    id: "3-2",
                    name: "Building Maintenance",
                    category: .maintenance,
                    level: 3,
                    certifications: [],
                    description: "General maintenance tasks"
                ),
                System.WorkerSkill(
                    id: "3-3",
                    name: "Repair Services",
                    category: .repair,
                    level: 4,
                    certifications: [],
                    description: "Building repair work"
                )
            ]
        case "4": // Kevin Dutan
            return [
                System.WorkerSkill(
                    id: "4-1",
                    name: "HVAC Systems",
                    category: .hvac,
                    level: 5,
                    certifications: ["HVAC Technician"],
                    description: "Complete HVAC maintenance and repair"
                ),
                System.WorkerSkill(
                    id: "4-2",
                    name: "Electrical Work",
                    category: .electrical,
                    level: 4,
                    certifications: ["Electrical Safety"],
                    description: "Electrical system maintenance"
                ),
                System.WorkerSkill(
                    id: "4-3",
                    name: "Technical Support",
                    category: .technical,
                    level: 3,
                    certifications: [],
                    description: "Technical systems support"
                )
            ]
        case "5": // Mercedes Inamagua
            return [
                System.WorkerSkill(
                    id: "5-1",
                    name: "Cleaning Services",
                    category: .cleaning,
                    level: 5,
                    certifications: [],
                    description: "Professional cleaning for properties"
                ),
                System.WorkerSkill(
                    id: "5-2",
                    name: "Sanitation Work",
                    category: .sanitation,
                    level: 4,
                    certifications: ["Sanitation Standards"],
                    description: "Sanitation procedures"
                )
            ]
        case "6": // Luis Lopez
            return [
                System.WorkerSkill(
                    id: "6-1",
                    name: "Building Maintenance",
                    category: .maintenance,
                    level: 4,
                    certifications: [],
                    description: "Overall building maintenance"
                ),
                System.WorkerSkill(
                    id: "6-2",
                    name: "Manual Tasks",
                    category: .manual,
                    level: 5,
                    certifications: ["Heavy Lifting"],
                    description: "Physical maintenance tasks"
                ),
                System.WorkerSkill(
                    id: "6-3",
                    name: "Building Inspection",
                    category: .inspection,
                    level: 3,
                    certifications: [],
                    description: "Property inspection"
                )
            ]
        case "7": // Angel Guirachocha
            return [
                System.WorkerSkill(
                    id: "7-1",
                    name: "Commercial Cleaning",
                    category: .cleaning,
                    level: 5,
                    certifications: [],
                    description: "Professional cleaning services"
                ),
                System.WorkerSkill(
                    id: "7-2",
                    name: "Sanitation",
                    category: .sanitation,
                    level: 4,
                    certifications: [],
                    description: "Building sanitation procedures"
                ),
                System.WorkerSkill(
                    id: "7-3",
                    name: "Manual Work",
                    category: .manual,
                    level: 4,
                    certifications: [],
                    description: "Manual maintenance tasks"
                )
            ]
        case "8": // Shawn Magloire
            return [
                System.WorkerSkill(
                    id: "8-1",
                    name: "Building Management",
                    category: .management,
                    level: 5,
                    certifications: ["Property Management"],
                    description: "Overall property management"
                ),
                System.WorkerSkill(
                    id: "8-2",
                    name: "Maintenance Supervision",
                    category: .maintenance,
                    level: 4,
                    certifications: [],
                    description: "Supervise maintenance operations"
                ),
                System.WorkerSkill(
                    id: "8-3",
                    name: "HVAC Systems",
                    category: .hvac,
                    level: 4,
                    certifications: [],
                    description: "HVAC system knowledge"
                ),
                System.WorkerSkill(
                    id: "8-4",
                    name: "Electrical Systems",
                    category: .electrical,
                    level: 3,
                    certifications: [],
                    description: "Electrical system knowledge"
                ),
                System.WorkerSkill(
                    id: "8-5",
                    name: "Plumbing Systems",
                    category: .plumbing,
                    level: 3,
                    certifications: [],
                    description: "Plumbing system knowledge"
                ),
                System.WorkerSkill(
                    id: "8-6",
                    name: "Building Inspection",
                    category: .inspection,
                    level: 5,
                    certifications: [],
                    description: "Detailed building inspections"
                )
            ]
        default:
            return []
        }
    }
}

// Simple namespace to avoid ambiguity until FrancoSphereModels is updated
enum System {
    struct WorkerSkill {
        let id: String
        let name: String
        let category: FrancoSphere.WorkerSkill
        let level: Int
        let certifications: [String]
        let description: String
    }
}
