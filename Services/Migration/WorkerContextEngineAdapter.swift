//
//  WorkerContextEngineAdapter.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/17/25.
//


//
//  WorkerContextEngineAdapter.swift
//  FrancoSphere v6.0
//
//  🚨 CRITICAL FIX: Added portfolio building access for coverage scenarios
//  ✅ FIXED: Workers can now access ALL buildings, not just assigned ones
//  ✅ ADDED: Building type classification (assigned vs coverage)
//  ✅ ENHANCED: Primary building detection for each worker
//

import SwiftUI
import Combine

@MainActor
public class WorkerContextEngineAdapter: ObservableObject {
    public static let shared = WorkerContextEngineAdapter()
    
    // MARK: - Published Properties
    
    @Published public var currentWorker: WorkerProfile?
    @Published public var assignedBuildings: [NamedCoordinate] = []
    @Published public var portfolioBuildings: [NamedCoordinate] = []  // NEW: Full portfolio access
    @Published public var todaysTasks: [ContextualTask] = []
    @Published public var taskProgress: TaskProgress?
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var isClockedIn = false
    @Published public var currentBuilding: NamedCoordinate?
    
    // MARK: - Private Properties
    
    private let contextEngine = WorkerContextEngine.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupPeriodicUpdates()
    }
    
    // MARK: - Public API (Enhanced with Portfolio Access)
    
    /// Load worker context with portfolio access
    public func loadContext(for workerId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await contextEngine.loadContext(for: workerId)
            await refreshPublishedState()
            print("✅ Worker context loaded with portfolio access")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to load worker context: \(error)")
        }
        
        isLoading = false
    }
    
    /// Get all buildings (assigned + portfolio) for coverage access
    public func getAllAccessibleBuildings() async -> [NamedCoordinate] {
        let assigned = await contextEngine.getAssignedBuildings()
        let portfolio = await contextEngine.getPortfolioBuildings()
        
        // Combine and deduplicate
        let allBuildings = Array(Set(assigned + portfolio))
        return allBuildings.sorted { $0.name < $1.name }
    }
    
    /// Determine building access type for UI display
    public func getBuildingAccessType(_ building: NamedCoordinate) async -> BuildingAccessType {
        let buildingType = await contextEngine.getBuildingType(building.id)
        
        // Enhanced classification
        if isPrimaryBuilding(building) {
            return .primary
        } else if buildingType == .assigned {
            return .assigned
        } else {
            return .coverage
        }
    }
    
    /// Check if building is the worker's primary building
    public func isPrimaryBuilding(_ building: NamedCoordinate) -> Bool {
        guard let worker = currentWorker else { return false }
        
        let primaryId = determinePrimaryBuildingId(for: worker.id)
        return building.id == primaryId
    }
    
    /// Get primary building for current worker
    public func getPrimaryBuilding() async -> NamedCoordinate? {
        guard let worker = currentWorker else { return nil }
        
        let primaryId = determinePrimaryBuildingId(for: worker.id)
        let allBuildings = assignedBuildings + portfolioBuildings
        
        return allBuildings.first { $0.id == primaryId }
    }
    
    /// Get buildings by access type for UI organization
    public func getBuildingsByType() async -> (primary: NamedCoordinate?, assigned: [NamedCoordinate], coverage: [NamedCoordinate]) {
        let allBuildings = await getAllAccessibleBuildings()
        
        var primary: NamedCoordinate?
        var assigned: [NamedCoordinate] = []
        var coverage: [NamedCoordinate] = []
        
        for building in allBuildings {
            let accessType = await getBuildingAccessType(building)
            
            switch accessType {
            case .primary:
                primary = building
                assigned.append(building)  // Primary is also assigned
            case .assigned:
                assigned.append(building)
            case .coverage:
                coverage.append(building)
            case .unknown:
                coverage.append(building)  // Default to coverage
            }
        }
        
        return (primary: primary, assigned: assigned, coverage: coverage)
    }
    
    // MARK: - Worker-Specific Primary Building Logic
    
    /// Determine primary building ID for specific workers
    private func determinePrimaryBuildingId(for workerId: String) -> String? {
        switch workerId {
        case "4":  // Kevin Dutan - Rubin Museum specialist
            return "rubin-museum"
        case "2":  // Edwin Lema - Park operations
            return "stuyvesant-cove"
        case "5":  // Mercedes Inamagua - Perry Street focus
            return "131-perry"
        case "6":  // Luis Lopez - Elizabeth Street area
            return "41-elizabeth"
        case "1":  // Greg Hutson - 12 West 18th
            return "12-west-18th"
        case "7":  // Angel Guirachocha - Evening operations
            return "12-west-18th"
        case "8":  // Shawn Magloire - Management overview
            return nil  // No specific primary building
        default:
            return nil
        }
    }
    
    // MARK: - Clock-In Methods (Enhanced for Portfolio Access)
    
    /// Clock in at any building (assigned or portfolio)
    public func clockIn(at building: NamedCoordinate) async throws {
        try await contextEngine.clockIn(at: building)
        await refreshPublishedState()
    }
    
    /// Clock out from current building
    public func clockOut() async throws {
        try await contextEngine.clockOut()
        await refreshPublishedState()
    }
    
    // MARK: - Task Management
    
    /// Complete a task and refresh state
    public func completeTask(_ task: ContextualTask) async throws {
        guard let workerId = currentWorker?.id else {
            throw WorkerContextError.noCurrentWorker
        }
        
        let evidence = ActionEvidence(
            description: "Task completed via worker dashboard",
            photoURLs: [],
            timestamp: Date()
        )
        
        try await contextEngine.recordTaskCompletion(
            workerId: workerId,
            buildingId: task.buildingId ?? "unknown",
            taskId: task.id,
            evidence: evidence
        )
        
        await refreshPublishedState()
    }
    
    // MARK: - State Management
    
    /// Refresh all published state from actor
    private func refreshPublishedState() async {
        self.currentWorker = await contextEngine.getCurrentWorker()
        self.assignedBuildings = await contextEngine.getAssignedBuildings()
        self.portfolioBuildings = await contextEngine.getPortfolioBuildings()  // NEW
        self.todaysTasks = await contextEngine.getTodaysTasks()
        self.taskProgress = await contextEngine.getTaskProgress()
        self.isClockedIn = await contextEngine.isWorkerClockedIn()
        self.currentBuilding = await contextEngine.getCurrentBuilding()
    }
    
    /// Refresh context if needed
    private func refreshContextIfNeeded() async {
        guard let workerId = currentWorker?.id else { return }
        
        do {
            try await contextEngine.refreshData()
            await refreshPublishedState()
        } catch {
            print("❌ Failed to refresh context: \(error)")
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupPeriodicUpdates() {
        // Refresh every 30 seconds
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.refreshContextIfNeeded()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Enhanced Building Access Types

public enum BuildingAccessType {
    case primary    // Worker's main/primary building
    case assigned   // Regular assigned building
    case coverage   // Portfolio access for coverage
    case unknown    // Not classified
    
    var displayName: String {
        switch self {
        case .primary: return "Primary"
        case .assigned: return "Assigned"
        case .coverage: return "Coverage"
        case .unknown: return "Unknown"
        }
    }
    
    var color: Color {
        switch self {
        case .primary: return .green
        case .assigned: return .blue
        case .coverage: return .orange
        case .unknown: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .primary: return "star.fill"
        case .assigned: return "building.2.fill"
        case .coverage: return "shield.fill"
        case .unknown: return "questionmark"
        }
    }
}

// MARK: - Convenience Methods

extension WorkerContextEngineAdapter {
    
    /// Get formatted worker role description
    public func getEnhancedWorkerRole() -> String {
        guard let worker = currentWorker else { return "Building Operations" }
        
        switch worker.id {
        case "4": return "Museum & Property Specialist"
        case "2": return "Park Operations & Maintenance"
        case "5": return "West Village Buildings"
        case "6": return "Downtown Maintenance"
        case "1": return "Building Systems Specialist"
        case "7": return "Evening Operations"
        case "8": return "Portfolio Management"
        default: return worker.role.rawValue.capitalized
        }
    }
    
    /// Get worker's building assignment summary
    public func getAssignmentSummary() -> String {
        let assignedCount = assignedBuildings.count
        let portfolioCount = portfolioBuildings.count
        
        if assignedCount == 0 {
            return "Portfolio access (\(portfolioCount) buildings)"
        } else if portfolioCount > assignedCount {
            return "\(assignedCount) assigned + \(portfolioCount - assignedCount) coverage"
        } else {
            return "\(assignedCount) buildings assigned"
        }
    }
}