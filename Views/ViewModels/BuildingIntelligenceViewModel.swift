//
//  BuildingIntelligenceViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Method names aligned with BuildingIntelligencePanel usage
//  ✅ FIXED: Uses correct WorkerService.getAllActiveWorkers() method
//  ✅ FIXED: Uses public OperationalDataManager methods instead of private realWorldTasks
//  ✅ ALIGNED: With existing service patterns and data types
//  ✅ USES: Real operational data from OperationalDataManager
//  ✅ FOLLOWS: Current MVVM architecture patterns
//

import SwiftUI
import Combine

@MainActor
class BuildingIntelligenceViewModel: ObservableObject {
    // MARK: - Published Properties (matching BuildingIntelligencePanel usage)
    @Published var metrics: CoreTypes.BuildingMetrics?
    @Published var primaryWorkers: [WorkerProfile] = []
    @Published var allAssignedWorkers: [WorkerProfile] = []
    @Published var currentWorkersOnSite: [WorkerProfile] = []
    @Published var todaysCompleteSchedule: [ContextualTask] = []
    @Published var weeklyRoutineSchedule: [ContextualTask] = []
    @Published var buildingHistory: [ContextualTask] = []
    @Published var patterns: [String] = []
    @Published var emergencyContacts: [String] = []
    @Published var emergencyProcedures: [String] = []
    
    // MARK: - Loading States
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Services
    private let buildingService = BuildingService.shared
    private let workerService = WorkerService.shared
    private let taskService = TaskService.shared
    private let buildingMetricsService = BuildingMetricsService.shared
    private let operationalData = OperationalDataManager.shared
    
    // MARK: - Main Data Loading Method (matching BuildingIntelligencePanel usage)
    
    func loadCompleteIntelligence(for building: NamedCoordinate) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load all intelligence data concurrently
            async let metricsTask = loadBuildingMetrics(for: building.id)
            async let workersTask = loadAllWorkers(for: building.id, buildingName: building.name)
            async let scheduleTask = loadCompleteSchedule(for: building.id, buildingName: building.name)
            async let historyTask = loadBuildingHistory(for: building.id)
            async let emergencyTask = loadEmergencyInfo(for: building.id, buildingName: building.name)
            
            // Wait for all tasks to complete
            await (metricsTask, workersTask, scheduleTask, historyTask, emergencyTask)
            
            print("✅ Building intelligence loaded for \(building.name)")
            
        } catch {
            self.errorMessage = "Failed to load building intelligence: \(error.localizedDescription)"
            print("❌ Failed to load building intelligence: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Individual Data Loading Methods
    
    private func loadBuildingMetrics(for buildingId: String) async {
        do {
            let buildingMetrics = try await buildingMetricsService.calculateMetrics(for: buildingId)
            self.metrics = buildingMetrics
        } catch {
            print("❌ Failed to load building metrics: \(error)")
        }
    }
    
    private func loadAllWorkers(for buildingId: String, buildingName: String) async {
        do {
            // Get all active workers
            let allWorkers = try await workerService.getAllActiveWorkers()
            
            // Get building coverage from operational data
            let buildingCoverage = operationalData.getBuildingCoverage()
            
            // Get workers assigned to this building
            let assignedWorkerNames = buildingCoverage[buildingName] ?? []
            
            // Filter workers who are assigned to this building
            let buildingWorkers = allWorkers.filter { worker in
                assignedWorkerNames.contains(worker.name)
            }
            
            self.allAssignedWorkers = buildingWorkers
            
            // Determine primary workers (those with most tasks)
            let workerTaskCounts = operationalData.getWorkerTaskSummary()
            let primaryWorkers = buildingWorkers.filter { worker in
                let taskCount = workerTaskCounts[worker.name] ?? 0
                return taskCount >= 5 // Workers with 5+ tasks are considered primary
            }
            
            self.primaryWorkers = primaryWorkers
            
            // Simulate current workers on site (for demo purposes)
            self.currentWorkersOnSite = buildingWorkers.filter { worker in
                // Simulate some workers being on site
                return worker.isActive && Int.random(in: 1...10) > 7
            }
            
        } catch {
            print("❌ Failed to load workers: \(error)")
        }
    }
    
    private func loadCompleteSchedule(for buildingId: String, buildingName: String) async {
        do {
            // Get all tasks for this building
            let allTasks = try await taskService.getAllTasks()
            let buildingTasks = allTasks.filter { task in
                task.buildingName == buildingName || task.buildingId == buildingId
            }
            
            // Separate by completion status
            let pendingTasks = buildingTasks.filter { !$0.isCompleted }
            let completedTasks = buildingTasks.filter { $0.isCompleted }
            
            self.todaysCompleteSchedule = pendingTasks
            self.buildingHistory = Array(completedTasks.suffix(20).reversed()) // Last 20 completed tasks
            
            // Generate weekly routine info from operational data
            let legacyTasks = await operationalData.getLegacyTaskAssignments()
            let routineTasks = legacyTasks.filter { $0.building == buildingName }
            
            self.weeklyRoutineSchedule = routineTasks.map { routine in
                ContextualTask(
                    id: UUID().uuidString,
                    title: routine.taskName,
                    description: "Routine: \(routine.category)",
                    isCompleted: false,
                    scheduledDate: Date(),
                    category: mapTaskCategory(routine.category),
                    urgency: .medium,
                    buildingId: buildingId,
                    buildingName: buildingName
                )
            }
            
        } catch {
            print("❌ Failed to load schedule: \(error)")
        }
    }
    
    private func loadBuildingHistory(for buildingId: String) async {
        // History is already loaded in loadCompleteSchedule
        // Generate patterns from historical data
        let completedTaskTypes = buildingHistory.compactMap { $0.category?.rawValue }
        let uniqueTypes = Set(completedTaskTypes)
        
        self.patterns = uniqueTypes.map { type in
            let count = completedTaskTypes.filter { $0 == type }.count
            return "\(type.capitalized): \(count) completed tasks"
        }
    }
    
    private func loadEmergencyInfo(for buildingId: String, buildingName: String) async {
        // Generate emergency contacts based on building type
        if buildingName.contains("Museum") {
            self.emergencyContacts = [
                "Museum Security: (555) 123-4567",
                "Building Manager: (555) 987-6543",
                "HVAC Emergency: (555) 456-7890",
                "Fire Safety: (555) 111-2222"
            ]
            
            self.emergencyProcedures = [
                "Fire Emergency: Evacuate via nearest exit, protect artifacts",
                "Medical Emergency: Call 911, notify security",
                "Power Outage: Activate backup power for climate control",
                "Security Breach: Lock down exhibits, call security"
            ]
        } else {
            self.emergencyContacts = [
                "Building Security: (555) 123-4567",
                "Property Manager: (555) 987-6543",
                "Maintenance: (555) 456-7890",
                "Emergency Services: 911"
            ]
            
            self.emergencyProcedures = [
                "Fire Emergency: Evacuate immediately via nearest exit",
                "Medical Emergency: Call 911 and building security",
                "Power Outage: Use emergency lighting, contact facilities",
                "Elevator Emergency: Use emergency phone, call maintenance"
            ]
        }
    }
    
    // MARK: - Helper Methods
    
    private func getBuildingName(for buildingId: String) async -> String {
        do {
            let building = try await buildingService.getBuilding(buildingId: buildingId)
            return building?.name ?? "Unknown Building"
        } catch {
            return "Unknown Building"
        }
    }
    
    private func mapTaskCategory(_ category: String) -> CoreTypes.TaskCategory {
        switch category.lowercased() {
        case "cleaning": return .cleaning
        case "maintenance": return .maintenance
        case "repair": return .repair
        case "inspection": return .inspection
        case "installation": return .installation
        case "utilities": return .utilities
        case "emergency": return .emergency
        case "renovation": return .renovation
        case "landscaping": return .landscaping
        case "security": return .security
        case "sanitation": return .sanitation
        default: return .maintenance
        }
    }
    
    // MARK: - Public Methods for Data Access
    
    func refreshData(for building: NamedCoordinate) async {
        await loadCompleteIntelligence(for: building)
    }
    
    func refreshMetrics(for buildingId: String) async {
        await loadBuildingMetrics(for: buildingId)
    }
    
    func getWorkersOnSite() -> [WorkerProfile] {
        return currentWorkersOnSite
    }
    
    func getPrimaryWorkers() -> [WorkerProfile] {
        return primaryWorkers
    }
    
    func getAllAssignedWorkers() -> [WorkerProfile] {
        return allAssignedWorkers
    }
    
    func getTodaysSchedule() -> [ContextualTask] {
        return todaysCompleteSchedule
    }
    
    func getWeeklyRoutines() -> [ContextualTask] {
        return weeklyRoutineSchedule
    }
    
    func getBuildingHistory() -> [ContextualTask] {
        return buildingHistory
    }
    
    func getEmergencyContacts() -> [String] {
        return emergencyContacts
    }
    
    func getEmergencyProcedures() -> [String] {
        return emergencyProcedures
    }
}
