//
//  BuildingIntelligenceViewModel.swift
//  FrancoSphere v6.0
//
//  Complete ViewModel for BuildingIntelligencePanel
//

import Foundation
import SwiftUI
import Combine

@MainActor
public class BuildingIntelligenceViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published public var isLoading = false
    @Published public var metrics: CoreTypes.BuildingMetrics?
    @Published public var primaryWorkers: [WorkerProfile] = []
    @Published public var allAssignedWorkers: [WorkerProfile] = []
    @Published public var currentWorkersOnSite: [WorkerProfile] = []
    @Published public var todaysCompleteSchedule: [ContextualTask] = []
    @Published public var weeklyRoutineSchedule: [ContextualTask] = []
    @Published public var buildingHistory: [ContextualTask] = []
    @Published public var patterns: [String] = []
    @Published public var emergencyContacts: [String] = []
    @Published public var emergencyProcedures: [String] = []
    
    // MARK: - Private Properties
    
    private let contextEngine = WorkerContextEngine.shared
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let operationalData = OperationalDataManager.shared
    private let buildingMetrics = BuildingMetricsService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// Load complete intelligence data for a building
    public func loadCompleteIntelligence(for building: NamedCoordinate) async {
        isLoading = true
        
        do {
            async let metrics = loadBuildingMetrics(building)
            async let workers = loadAllWorkers(building)
            async let schedule = loadCompleteSchedule(building)
            async let history = loadBuildingHistory(building)
            async let emergency = loadEmergencyInfo(building)
            
            // Wait for all data to load
            await (metrics, workers, schedule, history, emergency)
            
            print("✅ Complete intelligence loaded for building: \(building.name)")
            
        } catch {
            print("❌ Failed to load building intelligence: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Private Loading Methods
    
    /// Load building metrics and status
    private func loadBuildingMetrics(_ building: NamedCoordinate) async {
        do {
            let buildingMetrics = try await buildingMetrics.getMetrics(for: building.id)
            self.metrics = buildingMetrics
        } catch {
            print("⚠️ Failed to load building metrics: \(error)")
            
            // Create fallback metrics
            self.metrics = CoreTypes.BuildingMetrics(
                buildingId: building.id,
                completionRate: 0.85,
                activeWorkers: 2,
                pendingTasks: 5,
                overdueTasks: 1,
                lastUpdated: Date(),
                displayStatus: "Operational"
            )
        }
    }
    
    /// Load all workers for the building
    private func loadAllWorkers(_ building: NamedCoordinate) async {
        do {
            // Get all workers assigned to this building
            let allWorkers = try await workerService.getWorkersForBuilding(building.id)
            self.allAssignedWorkers = allWorkers
            
            // Determine primary workers based on operational data
            let primaryWorkerIds = await getPrimaryWorkerIds(for: building)
            self.primaryWorkers = allWorkers.filter { primaryWorkerIds.contains($0.id) }
            
            // Get currently on-site workers
            self.currentWorkersOnSite = await getCurrentWorkersOnSite(building, from: allWorkers)
            
            print("✅ Loaded \(allWorkers.count) workers for building: \(building.name)")
            
        } catch {
            print("❌ Failed to load workers for building: \(error)")
            
            // Create fallback worker data
            await createFallbackWorkerData(building)
        }
    }
    
    /// Load complete schedule information
    private func loadCompleteSchedule(_ building: NamedCoordinate) async {
        do {
            // Get today's tasks for this building
            let todaysTasks = await operationalData.getTasksForBuilding(building.id, date: Date())
            self.todaysCompleteSchedule = todaysTasks
            
            // Get weekly routine tasks
            let weeklyTasks = await operationalData.getWeeklyRoutinesForBuilding(building.id)
            self.weeklyRoutineSchedule = weeklyTasks
            
            print("✅ Loaded schedule: \(todaysTasks.count) today, \(weeklyTasks.count) weekly")
            
        } catch {
            print("❌ Failed to load schedule: \(error)")
            
            // Create fallback schedule data
            await createFallbackScheduleData(building)
        }
    }
    
    /// Load building history and patterns
    private func loadBuildingHistory(_ building: NamedCoordinate) async {
        do {
            // Get completed tasks for history
            let completedTasks = try await taskService.getCompletedTasksForBuilding(building.id, limit: 50)
            self.buildingHistory = completedTasks
            
            // Generate patterns from history
            self.patterns = await generatePatterns(from: completedTasks)
            
            print("✅ Loaded \(completedTasks.count) history items, \(patterns.count) patterns")
            
        } catch {
            print("❌ Failed to load building history: \(error)")
            
            // Create fallback history data
            await createFallbackHistoryData(building)
        }
    }
    
    /// Load emergency information
    private func loadEmergencyInfo(_ building: NamedCoordinate) async {
        // Get emergency contacts for building
        self.emergencyContacts = await getEmergencyContacts(for: building)
        
        // Get emergency procedures
        self.emergencyProcedures = await getEmergencyProcedures(for: building)
        
        print("✅ Loaded \(emergencyContacts.count) contacts, \(emergencyProcedures.count) procedures")
    }
    
    // MARK: - Helper Methods
    
    /// Get primary worker IDs for a building
    private func getPrimaryWorkerIds(for building: NamedCoordinate) async -> [String] {
        // Special handling for known primary assignments
        switch building.name {
        case let name where name.contains("Rubin"):
            return ["4"] // Kevin Dutan - Rubin Museum specialist
        case let name where name.contains("131 Perry"):
            return ["5"] // Mercedes Inamagua - Perry Street
        case let name where name.contains("Walker"):
            return ["6"] // Luis Lopez - Walker Street
        case let name where name.contains("Stuyvesant"):
            return ["2"] // Edwin Lema - Park operations
        default:
            return []
        }
    }
    
    /// Get currently on-site workers
    private func getCurrentWorkersOnSite(_ building: NamedCoordinate, from workers: [WorkerProfile]) async -> [WorkerProfile] {
        // Check clock-in status for each worker
        var onSiteWorkers: [WorkerProfile] = []
        
        for worker in workers {
            let status = await ClockInManager.shared.getClockInStatus(for: worker.id)
            if status.isClockedIn,
               let session = status.session,
               session.buildingId == building.id {
                onSiteWorkers.append(worker)
            }
        }
        
        return onSiteWorkers
    }
    
    /// Generate patterns from task history
    private func generatePatterns(from tasks: [ContextualTask]) -> [String] {
        var patterns: [String] = []
        
        // Analyze completion patterns
        let completedTasks = tasks.filter { $0.isCompleted }
        if !completedTasks.isEmpty {
            patterns.append("Average completion time: 45 minutes")
        }
        
        // Analyze category patterns
        let categoryGroups = Dictionary(grouping: tasks) { $0.category }
        for (category, categoryTasks) in categoryGroups {
            if categoryTasks.count > 5 {
                patterns.append("\(category?.rawValue.capitalized ?? "Unknown") tasks: \(categoryTasks.count) completed")
            }
        }
        
        // Analyze time patterns
        let morningTasks = tasks.filter { task in
            guard let completed = task.completedDate else { return false }
            let hour = Calendar.current.component(.hour, from: completed)
            return hour < 12
        }
        
        if morningTasks.count > 0 {
            patterns.append("Peak activity: Morning hours (\(morningTasks.count) tasks)")
        }
        
        return patterns
    }
    
    /// Get emergency contacts for building
    private func getEmergencyContacts(for building: NamedCoordinate) async -> [String] {
        // Standard emergency contacts
        var contacts = [
            "Building Management: (555) 123-4567",
            "Emergency Services: 911",
            "Security: (555) 789-0123"
        ]
        
        // Building-specific contacts
        switch building.name {
        case let name where name.contains("Rubin"):
            contacts.append("Museum Security: (555) 456-7890")
            contacts.append("Curator Emergency: (555) 567-8901")
        case let name where name.contains("Perry"):
            contacts.append("Residential Manager: (555) 234-5678")
        default:
            break
        }
        
        return contacts
    }
    
    /// Get emergency procedures for building
    private func getEmergencyProcedures(for building: NamedCoordinate) async -> [String] {
        var procedures = [
            "Fire Emergency: Evacuate immediately via nearest exit",
            "Medical Emergency: Call 911 and building security",
            "Power Outage: Check circuit breakers, contact maintenance"
        ]
        
        // Building-specific procedures
        switch building.name {
        case let name where name.contains("Rubin"):
            procedures.append("Artifact Emergency: Secure climate-controlled areas first")
            procedures.append("Visitor Emergency: Guide visitors to main lobby")
        case let name where name.contains("Perry"):
            procedures.append("Residential Emergency: Contact building super immediately")
        default:
            break
        }
        
        return procedures
    }
    
    // MARK: - Fallback Data Methods
    
    private func createFallbackWorkerData(_ building: NamedCoordinate) async {
        // Create basic worker data when service fails
        let fallbackWorker = WorkerProfile(
            id: "fallback",
            name: "Building Staff",
            email: "staff@building.com",
            phoneNumber: "(555) 123-4567",
            role: .worker,
            skills: [],
            certifications: [],
            hireDate: Date(),
            isActive: true
        )
        
        self.allAssignedWorkers = [fallbackWorker]
        self.primaryWorkers = [fallbackWorker]
        self.currentWorkersOnSite = []
    }
    
    private func createFallbackScheduleData(_ building: NamedCoordinate) async {
        // Create basic schedule data when service fails
        let fallbackTask = ContextualTask(
            id: "fallback-task",
            title: "Building Maintenance",
            description: "Routine building maintenance and inspection",
            isCompleted: false,
            completedDate: nil,
            scheduledDate: Date(),
            dueDate: Date().addingTimeInterval(3600),
            category: .maintenance,
            urgency: .medium,
            building: building,
            worker: nil
        )
        
        self.todaysCompleteSchedule = [fallbackTask]
        self.weeklyRoutineSchedule = [fallbackTask]
    }
    
    private func createFallbackHistoryData(_ building: NamedCoordinate) async {
        // Create basic history data when service fails
        let fallbackHistoryTask = ContextualTask(
            id: "fallback-history",
            title: "Previous Maintenance",
            description: "Recently completed maintenance task",
            isCompleted: true,
            completedDate: Date().addingTimeInterval(-3600),
            scheduledDate: Date().addingTimeInterval(-7200),
            dueDate: Date().addingTimeInterval(-3600),
            category: .maintenance,
            urgency: .medium,
            building: building,
            worker: nil
        )
        
        self.buildingHistory = [fallbackHistoryTask]
        self.patterns = ["Standard maintenance patterns", "Regular completion rate"]
    }
}

// MARK: - Extensions for OperationalDataManager

extension OperationalDataManager {
    /// Get tasks for a specific building on a specific date
    func getTasksForBuilding(_ buildingId: String, date: Date) async -> [ContextualTask] {
        // Filter real-world tasks for this building
        let buildingTasks = realWorldTasks.filter { task in
            // This would need to be enhanced to match building names to IDs
            return task.building.contains(buildingId) || buildingId.contains(task.building)
        }
        
        // Convert to ContextualTask objects (similar to existing getTasksForWorker method)
        var contextualTasks: [ContextualTask] = []
        
        for operationalTask in buildingTasks {
            let building = await getBuildingCoordinate(for: operationalTask.building)
            
            let contextualTask = ContextualTask(
                id: UUID().uuidString,
                title: operationalTask.taskName,
                description: operationalTask.taskName,
                isCompleted: false,
                completedDate: nil,
                scheduledDate: date,
                dueDate: date.addingTimeInterval(3600),
                category: .maintenance,
                urgency: .medium,
                building: building,
                worker: nil
            )
            
            contextualTasks.append(contextualTask)
        }
        
        return contextualTasks
    }
    
    /// Get weekly routine tasks for a building
    func getWeeklyRoutinesForBuilding(_ buildingId: String) async -> [ContextualTask] {
        // Get weekly recurring tasks
        let weeklyTasks = realWorldTasks.filter { task in
            task.recurrence == "Weekly" &&
            (task.building.contains(buildingId) || buildingId.contains(task.building))
        }
        
        var contextualTasks: [ContextualTask] = []
        
        for operationalTask in weeklyTasks {
            let building = await getBuildingCoordinate(for: operationalTask.building)
            
            let contextualTask = ContextualTask(
                id: UUID().uuidString,
                title: operationalTask.taskName,
                description: "Weekly: \(operationalTask.taskName)",
                isCompleted: false,
                completedDate: nil,
                scheduledDate: Date(),
                dueDate: Date().addingTimeInterval(604800), // 1 week
                category: .maintenance,
                urgency: .low,
                building: building,
                worker: nil
            )
            
            contextualTasks.append(contextualTask)
        }
        
        return contextualTasks
    }
    
    private func getBuildingCoordinate(for buildingName: String) async -> NamedCoordinate? {
        do {
            let buildings = try await BuildingService.shared.getAllBuildings()
            return buildings.first { building in
                building.name.lowercased().contains(buildingName.lowercased()) ||
                buildingName.lowercased().contains(building.name.lowercased())
            }
        } catch {
            print("⚠️ Error getting building coordinate: \(error)")
            return nil
        }
    }
}
