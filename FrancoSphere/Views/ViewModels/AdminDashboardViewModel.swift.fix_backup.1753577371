//
//  AdminDashboardViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ CORRECTED: DashboardSyncService integration
//  ✅ ALIGNED: With actual project API structure
//  ✅ ENHANCED: Cross-dashboard integration ready
//  ✅ VIEWMODEL ONLY: No View definitions in this file
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AdminDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties for Admin UI
    @Published var buildings: [NamedCoordinate] = []
    @Published var activeWorkers: [WorkerProfile] = []
    @Published var ongoingTasks: [ContextualTask] = []
    @Published var buildingMetrics: [String: CoreTypes.BuildingMetrics] = [:]
    @Published var portfolioInsights: [CoreTypes.IntelligenceInsight] = []
    
    // MARK: - Building Intelligence Panel
    @Published var selectedBuildingInsights: [CoreTypes.IntelligenceInsight] = []
    @Published var selectedBuildingId: String?
    @Published var isLoadingIntelligence = false
    
    // MARK: - Loading States
    @Published var isLoading = false
    @Published var isLoadingInsights = false
    @Published var errorMessage: String?
    @Published var lastUpdateTime: Date?
    
    // MARK: - Cross-Dashboard Integration (Using proper DashboardSyncService)
    @Published var dashboardSyncStatus: CoreTypes.DashboardSyncStatus = .synced
    @Published var crossDashboardUpdates: [DashboardUpdate] = []
    
    // MARK: - Services (Using .shared pattern consistently)
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let buildingMetricsService = BuildingMetricsService.shared
    private let intelligenceService = IntelligenceService.shared
    private let dashboardSyncService = DashboardSyncService.shared
    
    // MARK: - Real-time Subscriptions
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    // MARK: - Initialization
    
    init() {
        setupAutoRefresh()
        setupCrossDashboardSync()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Core Data Loading Methods
    
    /// Load all dashboard data
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let buildingsLoad = buildingService.getAllBuildings()
            async let workersLoad = workerService.getAllActiveWorkers()
            async let tasksLoad = taskService.getAllTasks()
            
            let (buildings, workers, tasks) = try await (buildingsLoad, workersLoad, tasksLoad)
            
            self.buildings = buildings
            self.activeWorkers = workers.filter { $0.isActive }
            self.ongoingTasks = tasks.filter { !$0.isCompleted }
            
            // Load building metrics
            await loadBuildingMetrics()
            
            // Load portfolio insights
            await loadPortfolioInsights()
            
            self.lastUpdateTime = Date()
            print("✅ Admin dashboard loaded: \(buildings.count) buildings, \(workers.count) workers, \(tasks.count) tasks")
            
        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ Failed to load admin dashboard: \(error)")
        }
        
        isLoading = false
    }
    
    /// Refresh dashboard data (for pull-to-refresh)
    func refreshDashboardData() async {
        await loadDashboardData()
    }
    
    /// Loads building metrics for all buildings
    private func loadBuildingMetrics() async {
        var metrics: [String: CoreTypes.BuildingMetrics] = [:]
        
        for building in buildings {
            do {
                let buildingMetrics = try await buildingMetricsService.calculateMetrics(for: building.id)
                metrics[building.id] = buildingMetrics
            } catch {
                print("⚠️ Failed to load metrics for building \(building.id): \(error)")
            }
        }
        
        self.buildingMetrics = metrics
        
        // ✅ FIXED: Use proper DashboardSyncService API
        broadcastAdminUpdate(.buildingMetricsChanged, data: [
            "buildingIds": Array(metrics.keys).joined(separator: ","),
            "totalBuildings": String(metrics.count)
        ])
    }
    
    /// Loads portfolio-wide intelligence insights
    func loadPortfolioInsights() async {
        isLoadingInsights = true
        
        do {
            let insights = try await intelligenceService.generatePortfolioInsights()
            self.portfolioInsights = insights
            self.isLoadingInsights = false
            
            print("✅ Portfolio insights loaded: \(insights.count) insights")
            
            // ✅ FIXED: Use proper DashboardSyncService API
            broadcastAdminUpdate(.intelligenceGenerated, data: [
                "insightCount": String(insights.count),
                "criticalInsights": String(insights.filter { $0.priority == .critical }.count)
            ])
            
        } catch {
            self.portfolioInsights = []
            self.isLoadingInsights = false
            print("⚠️ Failed to load portfolio insights: \(error)")
        }
    }
    
    // MARK: - Building Intelligence Methods
    
    /// Fetches detailed intelligence for a specific building
    func fetchBuildingIntelligence(for buildingId: String) async {
        guard !buildingId.isEmpty else {
            print("⚠️ Invalid building ID provided")
            return
        }
        
        isLoadingIntelligence = true
        selectedBuildingInsights = []
        selectedBuildingId = buildingId
        
        do {
            let insights = try await intelligenceService.generateBuildingInsights(for: buildingId)
            
            self.selectedBuildingInsights = insights
            self.isLoadingIntelligence = false
            
            print("✅ Intelligence loaded for building \(buildingId): \(insights.count) insights")
            
            // ✅ FIXED: Use proper DashboardSyncService API
            broadcastAdminUpdate(.intelligenceGenerated, buildingId: buildingId, data: [
                "buildingInsights": String(insights.count),
                "buildingId": buildingId
            ])
            
        } catch {
            self.selectedBuildingInsights = []
            self.isLoadingIntelligence = false
            self.errorMessage = error.localizedDescription
            print("❌ Failed to load building intelligence: \(error)")
        }
    }
    
    /// Clear building intelligence data
    func clearBuildingIntelligence() {
        selectedBuildingInsights = []
        selectedBuildingId = nil
        isLoadingIntelligence = false
    }
    
    /// Refresh metrics for a specific building
    func refreshBuildingMetrics(for buildingId: String) async {
        do {
            let metrics = try await buildingMetricsService.calculateMetrics(for: buildingId)
            buildingMetrics[buildingId] = metrics
            
            print("✅ Refreshed metrics for building \(buildingId)")
            
            // ✅ FIXED: Use proper DashboardSyncService API
            broadcastAdminUpdate(.buildingMetricsChanged, buildingId: buildingId, data: [
                "buildingId": buildingId,
                "completionRate": String(metrics.completionRate),
                "overdueTasks": String(metrics.overdueTasks)
            ])
            
        } catch {
            print("❌ Failed to refresh building metrics: \(error)")
        }
    }
    
    // MARK: - Admin-specific Methods (Fixed function declarations)
    
    /// ✅ FIXED: Added parentheses around parameter
    func loadAdminMetrics(building: String) async {
        await refreshBuildingMetrics(for: building)
    }
    
    /// ✅ FIXED: Added parentheses around parameter
    func updateStatus(status: String) async {
        dashboardSyncStatus = CoreTypes.DashboardSyncStatus(rawValue: status) ?? .synced
        
        broadcastAdminUpdate(.performanceChanged, data: [
            "adminStatus": status,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ])
    }
    
    // MARK: - Helper Methods
    
    /// Get building metrics for a specific building
    func getBuildingMetrics(for buildingId: String) -> CoreTypes.BuildingMetrics? {
        return buildingMetrics[buildingId]
    }
    
    /// Get intelligence insights for a specific building
    func getIntelligenceInsights(for buildingId: String) -> [CoreTypes.IntelligenceInsight] {
        return portfolioInsights.filter { insight in
            insight.affectedBuildings.contains(buildingId)
        }
    }
    
    /// Calculate portfolio summary metrics (using AdminPortfolioSummary type)
    func getAdminPortfolioSummary() -> AdminPortfolioSummary {
        let totalBuildings = buildings.count
        let totalWorkers = activeWorkers.count
        let totalTasks = ongoingTasks.count
        let completedTasks = ongoingTasks.filter { $0.isCompleted }.count
        
        let averageCompletion = buildingMetrics.values.isEmpty ? 0 :
            buildingMetrics.values.reduce(0) { $0 + $1.completionRate } / Double(buildingMetrics.count)
        
        let criticalInsights = portfolioInsights.filter { $0.priority == .critical }.count
        let actionableInsights = portfolioInsights.filter { $0.actionRequired }.count
        
        return AdminPortfolioSummary(
            totalBuildings: totalBuildings,
            totalWorkers: totalWorkers,
            totalTasks: totalTasks,
            completedTasks: completedTasks,
            averageCompletion: averageCompletion,
            criticalInsights: criticalInsights,
            actionableInsights: actionableInsights,
            efficiencyStatus: calculateEfficiencyStatus(averageCompletion)
        )
    }
    
    /// Calculate efficiency status based on completion rate
    private func calculateEfficiencyStatus(_ completion: Double) -> EfficiencyStatus {
        switch completion {
        case 0.9...: return .excellent
        case 0.7..<0.9: return .good
        default: return .needsImprovement
        }
    }
    
    // MARK: - Cross-Dashboard Integration
    
    /// Setup cross-dashboard synchronization
    private func setupCrossDashboardSync() {
        // Subscribe to cross-dashboard updates
        dashboardSyncService.crossDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleCrossDashboardUpdate(update)
            }
            .store(in: &cancellables)
        
        // Subscribe to worker dashboard updates
        dashboardSyncService.workerDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleWorkerDashboardUpdate(update)
            }
            .store(in: &cancellables)
        
        // Subscribe to client dashboard updates
        dashboardSyncService.clientDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleClientDashboardUpdate(update)
            }
            .store(in: &cancellables)
        
        print("🔗 Admin dashboard cross-dashboard sync configured")
    }
    
    /// ✅ FIXED: Use proper DashboardSyncService API for broadcasting
    private func broadcastAdminUpdate(_ type: UpdateType, buildingId: String? = nil, data: [String: Any] = [:]) {
        let update = DashboardUpdate(
            source: .admin,
            type: type,
            buildingId: buildingId,
            workerId: nil,
            data: data
        )
        
        crossDashboardUpdates.append(update)
        
        // Keep only recent updates (last 50)
        if crossDashboardUpdates.count > 50 {
            crossDashboardUpdates = Array(crossDashboardUpdates.suffix(50))
        }
        
        dashboardSyncService.broadcastAdminUpdate(update)
        print("📡 Admin update broadcast: \(type.displayName)")
    }
    
    /// Setup auto-refresh timer
    private func setupAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task {
                await self.refreshDashboardData()
            }
        }
    }
    
    /// ✅ FIXED: Handle cross-dashboard updates with proper type and enum cases
    private func handleCrossDashboardUpdate(_ update: DashboardUpdate) {
        crossDashboardUpdates.append(update)
        
        // Keep only recent updates
        if crossDashboardUpdates.count > 50 {
            crossDashboardUpdates = Array(crossDashboardUpdates.suffix(50))
        }
        
        // Handle specific update types using correct enum cases
        switch update.type {
        case .taskCompleted:
            if let buildingId = update.buildingId {
                Task {
                    await refreshBuildingMetrics(for: buildingId)
                }
            }
        case .workerClockedIn:
            if let buildingId = update.buildingId {
                Task {
                    await refreshBuildingMetrics(for: buildingId)
                }
            }
        case .complianceChanged:
            // Refresh all affected buildings
            Task {
                await loadBuildingMetrics()
            }
        case .portfolioUpdated:
            Task {
                await loadPortfolioInsights()
            }
        default:
            break
        }
    }
    
    /// Handle worker dashboard updates
    private func handleWorkerDashboardUpdate(_ update: DashboardUpdate) {
        switch update.type {
        case .taskCompleted, .taskStarted:
            if let buildingId = update.buildingId {
                Task {
                    await refreshBuildingMetrics(for: buildingId)
                }
            }
        case .workerClockedIn, .workerClockedOut:
            // Update worker status tracking
            Task {
                await loadDashboardData()
            }
        default:
            break
        }
    }
    
    /// Handle client dashboard updates
    private func handleClientDashboardUpdate(_ update: DashboardUpdate) {
        switch update.type {
        case .portfolioUpdated:
            Task {
                await loadPortfolioInsights()
            }
        case .complianceChanged:
            Task {
                await loadBuildingMetrics()
            }
        default:
            break
        }
    }
}

// MARK: - Supporting Types (Admin-specific, no conflicts)

/// Admin-specific portfolio summary to avoid type conflicts
struct AdminPortfolioSummary {
    let totalBuildings: Int
    let totalWorkers: Int
    let totalTasks: Int
    let completedTasks: Int
    let averageCompletion: Double
    let criticalInsights: Int
    let actionableInsights: Int
    let efficiencyStatus: EfficiencyStatus
    
    var completionPercentage: String {
        return "\(Int(averageCompletion * 100))%"
    }
    
    var efficiencyDescription: String {
        switch efficiencyStatus {
        case .excellent: return "Excellent Performance"
        case .good: return "Good Performance"
        case .needsImprovement: return "Needs Improvement"
        }
    }
}

enum EfficiencyStatus {
    case excellent
    case good
    case needsImprovement
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .needsImprovement: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .excellent: return "checkmark.circle.fill"
        case .good: return "hand.thumbsup.fill"
        case .needsImprovement: return "exclamationmark.triangle.fill"
        }
    }
}
