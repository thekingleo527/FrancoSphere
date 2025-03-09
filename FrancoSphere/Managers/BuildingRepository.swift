import Foundation
import SwiftUI

class BuildingRepository {
    static let shared = BuildingRepository()
    
    private init() {}
    
    lazy var buildings: [NamedCoordinate] = loadBuildings()
    
    private func loadBuildings() -> [NamedCoordinate] {
        return [
            // Existing buildings
            NamedCoordinate(
                id: "1",
                name: "12 West 18th Street",
                latitude: 40.7390,
                longitude: -73.9930,
                address: "12 W 18th St, New York, NY",
                imageAssetName: "12_West_18th_Street"
            ),
            NamedCoordinate(
                id: "2",
                name: "29-31 East 20th Street",
                latitude: 40.7380,
                longitude: -73.9880,
                address: "29-31 E 20th St, New York, NY",
                imageAssetName: "29_31_East_20th_Street"
            ),
            NamedCoordinate(
                id: "3",
                name: "36 Walker Street",
                latitude: 40.7190,
                longitude: -74.0050,
                address: "36 Walker St, New York, NY",
                imageAssetName: "36_Walker_Street"
            ),
            NamedCoordinate(
                id: "4",
                name: "41 Elizabeth Street",
                latitude: 40.7170,
                longitude: -73.9970,
                address: "41 Elizabeth St, New York, NY",
                imageAssetName: "41_Elizabeth_Street"
            ),
            NamedCoordinate(
                id: "5",
                name: "68 Perry Street",
                latitude: 40.7350,
                longitude: -74.0050,
                address: "68 Perry St, New York, NY",
                imageAssetName: "68_Perry_Street"
            ),
            NamedCoordinate(
                id: "6",
                name: "104 Franklin Street",
                latitude: 40.7180,
                longitude: -74.0060,
                address: "104 Franklin St, New York, NY",
                imageAssetName: "104_Franklin_Street"
            ),
            NamedCoordinate(
                id: "7",
                name: "112 West 18th Street",
                latitude: 40.7400,
                longitude: -73.9940,
                address: "112 W 18th St, New York, NY",
                imageAssetName: "112_West_18th_Street"
            ),
            NamedCoordinate(
                id: "8",
                name: "117 West 17th Street",
                latitude: 40.7395,
                longitude: -73.9950,
                address: "117 W 17th St, New York, NY",
                imageAssetName: "117_West_17th_Street"
            ),
            NamedCoordinate(
                id: "9",
                name: "123 1st Avenue",
                latitude: 40.7270,
                longitude: -73.9850,
                address: "123 1st Ave, New York, NY",
                imageAssetName: "123_1st_Avenue"
            ),
            NamedCoordinate(
                id: "10",
                name: "131 Perry Street",
                latitude: 40.7340,
                longitude: -74.0060,
                address: "131 Perry St, New York, NY",
                imageAssetName: "131_Perry_Street"
            ),
            NamedCoordinate(
                id: "11",
                name: "133 East 15th Street",
                latitude: 40.7345,
                longitude: -73.9875,
                address: "133 E 15th St, New York, NY",
                imageAssetName: "133_East_15th_Street"
            ),
            NamedCoordinate(
                id: "12",
                name: "135-139 West 17th Street",
                latitude: 40.7400,
                longitude: -73.9960,
                address: "135-139 W 17th St, New York, NY",
                // FIXED: Changed from W to West to match the actual asset name
                imageAssetName: "135West17thStreet"
            ),
            NamedCoordinate(
                id: "13",
                name: "136 West 17th Street",
                latitude: 40.7402,
                longitude: -73.9970,
                address: "136 W 17th St, New York, NY",
                imageAssetName: "136_West_17th_Street"
            ),
            NamedCoordinate(
                id: "14",
                name: "Rubin Museum (142-148 W 17th)",
                latitude: 40.7405,
                longitude: -73.9980,
                address: "142-148 W 17th St, New York, NY",
                // FIXED: Changed to match the actual asset name
                imageAssetName: "Rubin_Museum_142_148_West_17th_Street"
            ),
            NamedCoordinate(
                id: "15",
                name: "Stuyvesant Cove Park",
                latitude: 40.7318,
                longitude: -73.9740,
                address: "20 Waterside Plaza, New York, NY 10010",
                imageAssetName: "Stuyvesant_Cove_Park"
            ),
            // NEW: 138 West 17th Street
            NamedCoordinate(
                id: "16",
                name: "138 West 17th Street",
                latitude: 40.7399,   // Approximate, adjust as needed
                longitude: -73.9965,
                address: "138 W 17th St, New York, NY",
                imageAssetName: "138West17thStreet"
            )
        ]
    }
    
    /// Get building name for given ID
    func getBuildingName(forId id: String) -> String {
        return buildings.first(where: { $0.id == id })?.name ?? "Unknown Building"
    }
    
    /// Get first N buildings
    func getFirstNBuildings(_ count: Int) -> [NamedCoordinate] {
        return Array(buildings.prefix(count))
    }
    
    /// Get worker assignments for a building
    func getAssignedWorkers(for buildingId: String) -> [FrancoWorkerAssignment] {
        switch buildingId {
        case "1": // 12 West 18th Street
            return [
                FrancoWorkerAssignment(buildingId: "1", workerId: 1, workerName: "Greg Hutson", shift: "Day", specialRole: "Lead Maintenance"),
                FrancoWorkerAssignment(buildingId: "1", workerId: 7, workerName: "Angel Guirachocha", shift: "Day", specialRole: nil),
                FrancoWorkerAssignment(buildingId: "1", workerId: 8, workerName: "Shawn Magloire", shift: "Day", specialRole: nil)
            ]
        case "2": // 29-31 East 20th Street
            return [
                FrancoWorkerAssignment(buildingId: "2", workerId: 2, workerName: "Edwin Lema", shift: "Day", specialRole: "Lead Cleaning"),
                FrancoWorkerAssignment(buildingId: "2", workerId: 5, workerName: "Jose Santos", shift: "Day", specialRole: nil)
            ]
        case "3": // 36 Walker Street
            return [
                FrancoWorkerAssignment(buildingId: "3", workerId: 3, workerName: "Luis Lopez", shift: "Day", specialRole: "HVAC Specialist"),
                FrancoWorkerAssignment(buildingId: "3", workerId: 4, workerName: "Kevin Dutan", shift: "Day", specialRole: nil)
            ]
        case "4": // 41 Elizabeth Street
            return [
                FrancoWorkerAssignment(buildingId: "4", workerId: 1, workerName: "Edwin Lema", shift: "Day", specialRole: nil),
                FrancoWorkerAssignment(buildingId: "4", workerId: 6, workerName: "Luis Lopez", shift: "Day", specialRole: "Facilities Manager")
            ]
        case "5": // 68 Perry Street
            return [
                FrancoWorkerAssignment(buildingId: "5", workerId: 2, workerName: "Edwin Lema", shift: "Day", specialRole: nil),
                FrancoWorkerAssignment(buildingId: "5", workerId: 7, workerName: "Angel Guirachocha", shift: "Day", specialRole: "Cleaning Supervisor")
            ]
        case "6": // 104 Franklin Street
            return [
                FrancoWorkerAssignment(buildingId: "6", workerId: 3, workerName: "Angel Guirachocha", shift: "Day", specialRole: nil),
                FrancoWorkerAssignment(buildingId: "6", workerId: 5, workerName: "Mercedes Inamagua", shift: "Evening", specialRole: "Maintenance")
            ]
        case "7": // 112 West 18th Street
            return [
                FrancoWorkerAssignment(buildingId: "7", workerId: 1, workerName: "Jose Santos", shift: "Day", specialRole: nil),
                FrancoWorkerAssignment(buildingId: "7", workerId: 4, workerName: "Kevin Dutan", shift: "Day", specialRole: nil)
            ]
        case "8": // 117 West 17th Street
            return [
                FrancoWorkerAssignment(buildingId: "8", workerId: 2, workerName: "Edwin Lema", shift: "Day", specialRole: nil),
                FrancoWorkerAssignment(buildingId: "8", workerId: 6, workerName: "Mercedes Inamagua", shift: "Day", specialRole: nil)
            ]
        case "9": // 123 1st Avenue
            return [
                FrancoWorkerAssignment(buildingId: "9", workerId: 3, workerName: "Jose Santos", shift: "Day", specialRole: nil),
                FrancoWorkerAssignment(buildingId: "9", workerId: 7, workerName: "Angel Guirachocha", shift: "Day", specialRole: nil)
            ]
        case "10": // 131 Perry Street
            return [
                FrancoWorkerAssignment(buildingId: "10", workerId: 1, workerName: "Jose Santos", shift: "Day", specialRole: "HVAC"),
                FrancoWorkerAssignment(buildingId: "10", workerId: 5, workerName: "Edwin Lema", shift: "Evening", specialRole: "Maintenance")
            ]
        case "11": // 133 East 15th Street
            return [
                FrancoWorkerAssignment(buildingId: "11", workerId: 2, workerName: "Edwin Lema", shift: "Day", specialRole: nil),
                FrancoWorkerAssignment(buildingId: "11", workerId: 4, workerName: "Kevin Dutan", shift: "Day", specialRole: nil)
            ]
        case "12": // 135-139 West 17th Street
            return [
                FrancoWorkerAssignment(buildingId: "12", workerId: 1, workerName: "Mercedes Inamagua", shift: "Day", specialRole: "Lead Maintenance"),
                FrancoWorkerAssignment(buildingId: "12", workerId: 3, workerName: "Jose Santos", shift: "Day", specialRole: "Cleaning")
            ]
        case "13": // 136 West 17th Street
            return [
                FrancoWorkerAssignment(buildingId: "13", workerId: 6, workerName: "Jose Santos", shift: "Day", specialRole: nil),
                FrancoWorkerAssignment(buildingId: "13", workerId: 7, workerName: "Angel Guirachocha", shift: "Day", specialRole: nil)
            ]
        case "14": // Rubin Museum (142-148 W 17th)
            return [
                FrancoWorkerAssignment(buildingId: "14", workerId: 8, workerName: "Shawn Magloire", shift: "Day", specialRole: nil)
            ]
        case "15": // Stuyvesant Cove Park
            return [
                FrancoWorkerAssignment(buildingId: "15", workerId: 1, workerName: "Edwin Lema", shift: "On Call", specialRole: nil)
            ]
        case "16": // 138 West 17th Street
            return [
                // Adjust worker assignment as needed
                FrancoWorkerAssignment(buildingId: "16", workerId: 1, workerName: "Jose Santos", shift: "Day", specialRole: "Maintenance")
            ]
        default:
            // Default assignment for buildings without specific assignments
            return [
                FrancoWorkerAssignment(buildingId: buildingId, workerId: 1, workerName: "Jose Santos", shift: "On Call", specialRole: nil)
            ]
        }
    }
    
    /// Get routine tasks for a specific building
    func getRoutineTasks(for buildingId: String) -> [String] {
        // Based on Buildings_Database.csv "Routine Tasks" column
        switch buildingId {
        case "1": // 12 West 18th Street
            return ["HVAC Filter Replacement", "Lobby Cleaning", "Garbage Collection", "Security System Check"]
        case "2": // 29-31 East 20th Street
            return ["Hallway Sweeping", "Window Cleaning", "Elevator Maintenance", "Common Area Sanitizing"]
        case "3": // 36 Walker Street
            return ["HVAC Inspection", "Plumbing System Check", "Exterior Cleaning", "Pest Control"]
        case "4": // 41 Elizabeth Street
            return ["Roof Inspection", "Fire Safety Equipment Check", "Landscaping", "Utility Room Inspection"]
        case "5": // 68 Perry Street
            return ["Mailbox Area Cleaning", "Lighting Maintenance", "Front Door Maintenance", "Stairwell Cleaning"]
        default:
            return ["General Maintenance", "Cleaning", "Inspection"]
        }
    }
}

// MARK: - Worker Assignment Data Model
struct FrancoWorkerAssignment {
    let buildingId: String
    let workerId: Int64
    let workerName: String
    let shift: String?
    let specialRole: String?
    
    var description: String {
        var result = workerName
        if let shift = shift {
            result += " (\(shift))"
        }
        if let specialRole = specialRole {
            result += " - \(specialRole)"
        }
        return result
    }
}
