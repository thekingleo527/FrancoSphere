//
//  AdminDashboardViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ CORRECTED: DashboardSyncService integration with proper types
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
        
        // Create and broadcast update
        let update = DashboardUpdate(
            source: .admin,
            type: .buildingMetricsChanged,
            buildingId: nil,
            workerId: nil,
            data: [
                "buildingIds": Array(metrics.keys).joined(separator: ","),
                "totalBuildings": metrics.count
            ]
        )
        broadcastAdminUpdate(update)
    }
    
    /// Loads portfolio-wide intelligence insights
    func loadPortfolioInsights() async {
        isLoadingInsights = true
        
        do {
            let insights = try await intelligenceService.generatePortfolioInsights()
            self.portfolioInsights = insights
            self.isLoadingInsights = false
            
            print("✅ Portfolio insights loaded: \(insights.count) insights")
            
            // Create and broadcast update
            let update = DashboardUpdate(
                source: .admin,
                type: .intelligenceGenerated,
                buildingId: nil,
                workerId: nil,
                data: [
                    "insightCount": insights.count,
                    "criticalInsights": insights.filter { $0.priority == .critical }.count
                ]
            )
            broadcastAdminUpdate(update)
            
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
            
            // Create and broadcast update
            let update = DashboardUpdate(
                source: .admin,
                type: .intelligenceGenerated,
                buildingId: buildingId,
                workerId: nil,
                data: [
                    "buildingInsights": insights.count,
                    "buildingId": buildingId
                ]
            )
            broadcastAdminUpdate(update)
            
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
            
            // Create and broadcast update
            let update = DashboardUpdate(
                source: .admin,
                type: .buildingMetricsChanged,
                buildingId: buildingId,
                workerId: nil,
                data: [
                    "buildingId": buildingId,
                    "completionRate": metrics.completionRate,
                    "overdueTasks": metrics.overdueTasks
                ]
            )
            broadcastAdminUpdate(update)
            
        } catch {
            print("❌ Failed to refresh building metrics: \(error)")
        }
    }
    
    // MARK: - Admin-specific Methods
    
    func loadAdminMetrics(building: String) async {
        await refreshBuildingMetrics(for: building)
    }
    
    func updateStatus(status: String) async {
        dashboardSyncStatus = CoreTypes.DashboardSyncStatus(rawValue: status) ?? .synced
        
        // Create and broadcast update
        let update = DashboardUpdate(
            source: .admin,
            type: .performanceChanged,
            buildingId: nil,
            workerId: nil,
            data: [
                "adminStatus": status,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )
        broadcastAdminUpdate(update)
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
    
    /// Calculate portfolio summary metrics
    func getAdminPortfolioSummary() -> AdminDashboardViewModel.PortfolioSummary {
        let totalBuildings = buildings.count
        let totalWorkers = activeWorkers.count
        let totalTasks = ongoingTasks.count
        let completedTasks = ongoingTasks.filter { $0.isCompleted }.count
        
        let averageCompletion = buildingMetrics.values.isEmpty ? 0 :
            buildingMetrics.values.reduce(0) { $0 + $1.completionRate } / Double(buildingMetrics.count)
        
        let criticalInsights = portfolioInsights.filter { $0.priority == .critical }.count
        let actionableInsights = portfolioInsights.filter { $0.actionRequired }.count
        
        return PortfolioSummary(
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
    private func calculateEfficiencyStatus(_ completion: Double) -> AdminDashboardViewModel.Status {
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
                guard let self = self else { return }
                _Concurrency.Task {
                    await self.handleCrossDashboardUpdate(update)
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to worker dashboard updates
        dashboardSyncService.workerDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                guard let self = self else { return }
                _Concurrency.Task {
                    await self.handleWorkerDashboardUpdate(update)
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to client dashboard updates
        dashboardSyncService.clientDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                guard let self = self else { return }
                _Concurrency.Task {
                    await self.handleClientDashboardUpdate(update)
                }
            }
            .store(in: &cancellables)
        
        print("🔗 Admin dashboard cross-dashboard sync configured")
    }
    
    /// Broadcast admin update using DashboardUpdate directly
    private func broadcastAdminUpdate(_ update: DashboardUpdate) {
        crossDashboardUpdates.append(update)
        
        // Keep only recent updates (last 50)
        if crossDashboardUpdates.count > 50 {
            crossDashboardUpdates = Array(crossDashboardUpdates.suffix(50))
        }
        
        dashboardSyncService.broadcastAdminUpdate(update)
        print("📡 Admin update broadcast: \(update.type)")
    }
    
    /// Setup auto-refresh timer
    private func setupAutoRefresh() {
        let timer = Timer(timeInterval: 30.0, repeats: true) { _ in
            _Concurrency.Task { [weak self] in
                await self?.refreshDashboardData()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.refreshTimer = timer
    }
    
    /// Handle cross-dashboard updates with proper type and enum cases
    private func handleCrossDashboardUpdate(_ update: DashboardUpdate) async {
        crossDashboardUpdates.append(update)
        
        // Keep only recent updates
        if crossDashboardUpdates.count > 50 {
            crossDashboardUpdates = Array(crossDashboardUpdates.suffix(50))
        }
        
        // Handle specific update types using correct enum cases
        switch update.type {
        case .taskCompleted:
            if let buildingId = update.buildingId {
                await refreshBuildingMetrics(for: buildingId)
            }
        case .workerClockedIn:
            if let buildingId = update.buildingId {
                await refreshBuildingMetrics(for: buildingId)
            }
        case .complianceChanged:
            // Refresh all affected buildings
            await loadBuildingMetrics()
        case .portfolioUpdated:
            await loadPortfolioInsights()
        default:
            break
        }
    }
    
    /// Handle worker dashboard updates
    private func handleWorkerDashboardUpdate(_ update: DashboardUpdate) async {
        switch update.type {
        case .taskCompleted, .taskStarted:
            if let buildingId = update.buildingId {
                await refreshBuildingMetrics(for: buildingId)
            }
        case .workerClockedIn, .workerClockedOut:
            // Update worker status tracking
            await loadDashboardData()
        default:
            break
        }
    }
    
    /// Handle client dashboard updates
    private func handleClientDashboardUpdate(_ update: DashboardUpdate) async {
        switch update.type {
        case .portfolioUpdated:
            await loadPortfolioInsights()
        case .complianceChanged:
            await loadBuildingMetrics()
        default:
            break
        }
    }
}

// MARK: - Nested Types (To avoid global conflicts)

extension AdminDashboardViewModel {
    
    /// Portfolio summary nested in AdminDashboardViewModel to avoid conflicts
    struct PortfolioSummary {
        let totalBuildings: Int
        let totalWorkers: Int
        let totalTasks: Int
        let completedTasks: Int
        let averageCompletion: Double
        let criticalInsights: Int
        let actionableInsights: Int
        let efficiencyStatus: Status
        
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
    
    /// Status nested in AdminDashboardViewModel to avoid conflicts
    enum Status {
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
}
