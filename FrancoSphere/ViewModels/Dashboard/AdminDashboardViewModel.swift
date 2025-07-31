//
//  AdminDashboardViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All DashboardUpdate references now use CoreTypes prefix
//  ✅ ALIGNED: With DashboardSyncService using CoreTypes.DashboardUpdate
//  ✅ PHOTO EVIDENCE: Full integration with PhotoEvidenceService
//  ✅ READY: Full cross-dashboard integration with photo support
//  ✅ FIXED: Removed duplicate extension causing syntax error
//  ✅ FIXED: Removed duplicate isOverdue property (already in CoreTypes)
//  ✅ STREAM A MODIFIED: Added Spanish localization support
//  ✅ STREAM A MODIFIED: Added worker capabilities checking
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

@MainActor
class AdminDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties for Admin UI
    @Published var buildings: [CoreTypes.NamedCoordinate] = []
    @Published var workers: [CoreTypes.WorkerProfile] = []
    @Published var activeWorkers: [CoreTypes.WorkerProfile] = []
    @Published var tasks: [CoreTypes.ContextualTask] = []
    @Published var ongoingTasks: [CoreTypes.ContextualTask] = []
    @Published var buildingMetrics: [String: CoreTypes.BuildingMetrics] = [:]
    @Published var portfolioInsights: [CoreTypes.IntelligenceInsight] = []
    
    // MARK: - Photo Evidence Properties
    @Published var recentCompletedTasks: [CoreTypes.ContextualTask] = []
    @Published var completedTasks: [CoreTypes.ContextualTask] = []
    @Published var todaysPhotoCount: Int = 0
    @Published var isLoadingPhotos = false
    @Published var photoComplianceStats: PhotoComplianceStats?
    
    // MARK: - Building Intelligence Panel
    @Published var selectedBuildingInsights: [CoreTypes.IntelligenceInsight] = []
    @Published var selectedBuildingId: String?
    @Published var isLoadingIntelligence = false
    
    // MARK: - Loading States
    @Published var isLoading = false
    @Published var isLoadingInsights = false
    @Published var error: Error?
    @Published var errorMessage: String?
    @Published var lastUpdateTime: Date?
    
    // MARK: - Cross-Dashboard Integration
    @Published var dashboardSyncStatus: CoreTypes.DashboardSyncStatus = .synced
    @Published var crossDashboardUpdates: [CoreTypes.DashboardUpdate] = []
    
    // MARK: - Worker Capabilities (Stream A Addition)
    @Published var workerCapabilities: [String: WorkerCapabilities] = [:]
    
    // MARK: - Services
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let buildingMetricsService = BuildingMetricsService.shared
    private let intelligenceService = IntelligenceService.shared
    private let dashboardSyncService = DashboardSyncService.shared
    private let photoEvidenceService = PhotoEvidenceService.shared
    private let grdbManager = GRDBManager.shared
    
    // MARK: - Real-time Subscriptions
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    // MARK: - Nested Types
    
    // ✅ STREAM A ADDITION: Worker capabilities structure for UI adaptation
    struct WorkerCapabilities {
        let canUploadPhotos: Bool
        let canAddNotes: Bool
        let canViewMap: Bool
        let canAddEmergencyTasks: Bool
        let requiresPhotoForSanitation: Bool
        let simplifiedInterface: Bool
    }
    
    // MARK: - Initialization
    
    init() {
        setupAutoRefresh()
        setupCrossDashboardSync()
        subscribeToPhotoUpdates()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Core Data Loading Methods
    
    /// Load all dashboard data
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        error = nil
        
        do {
            // Load core data in parallel
            async let buildingsLoad = buildingService.getAllBuildings()
            async let workersLoad = workerService.getAllActiveWorkers()
            async let tasksLoad = taskService.getAllTasks()
            
            let (buildings, workers, tasks) = try await (buildingsLoad, workersLoad, tasksLoad)
            
            self.buildings = buildings
            self.workers = workers
            self.activeWorkers = workers.filter { $0.isActive }
            self.tasks = tasks
            self.ongoingTasks = tasks.filter { !$0.isCompleted }
            
            // ✅ STREAM A ADDITION: Load worker capabilities
            await loadWorkerCapabilities(for: workers)
            
            // Load building metrics
            await loadBuildingMetrics()
            
            // Load portfolio insights
            await loadPortfolioInsights()
            
            // Load completed tasks and photo data
            await loadCompletedTasks()
            await countTodaysPhotos()
            await loadPhotoComplianceStats()
            
            self.lastUpdateTime = Date()
            
            // ✅ STREAM A MODIFICATION: Localized success message
            let successMessage = NSLocalizedString("Admin dashboard loaded successfully", comment: "Dashboard load success")
            print("✅ \(successMessage): \(buildings.count) buildings, \(workers.count) workers, \(tasks.count) tasks")
            
        } catch {
            self.error = error
            // ✅ STREAM A MODIFICATION: More robust and localizable error handling
            let baseError = NSLocalizedString("Failed to load administrator data", comment: "Admin dashboard loading error")
            self.errorMessage = "\(baseError). \(NSLocalizedString("Please check your network connection.", comment: "Network error advice"))"
            print("❌ Failed to load admin dashboard: \(error)")
        }
        
        isLoading = false
    }
    
    /// Refresh dashboard data (for pull-to-refresh)
    func refreshDashboardData() async {
        await loadDashboardData()
    }
    
    // MARK: - Worker Capabilities Methods (Stream A Addition)
    
    /// Load worker capabilities for all workers
    private func loadWorkerCapabilities(for workers: [CoreTypes.WorkerProfile]) async {
        for worker in workers {
            do {
                let rows = try await grdbManager.query("""
                    SELECT * FROM worker_capabilities WHERE worker_id = ?
                """, [worker.id])
                
                if let row = rows.first {
                    workerCapabilities[worker.id] = WorkerCapabilities(
                        canUploadPhotos: (row["can_upload_photos"] as? Int64 ?? 1) == 1,
                        canAddNotes: (row["can_add_notes"] as? Int64 ?? 1) == 1,
                        canViewMap: (row["can_view_map"] as? Int64 ?? 1) == 1,
                        canAddEmergencyTasks: (row["can_add_emergency_tasks"] as? Int64 ?? 0) == 1,
                        requiresPhotoForSanitation: (row["requires_photo_for_sanitation"] as? Int64 ?? 1) == 1,
                        simplifiedInterface: (row["simplified_interface"] as? Int64 ?? 0) == 1
                    )
                }
            } catch {
                print("⚠️ Failed to load capabilities for worker \(worker.id): \(error)")
            }
        }
    }
    
    /// Check if a worker can perform a specific action
    func canWorkerPerformAction(_ workerId: String, action: WorkerAction) -> Bool {
        guard let capabilities = workerCapabilities[workerId] else { return true }
        
        switch action {
        case .uploadPhoto:
            return capabilities.canUploadPhotos
        case .addNotes:
            return capabilities.canAddNotes
        case .viewMap:
            return capabilities.canViewMap
        case .addEmergencyTask:
            return capabilities.canAddEmergencyTasks
        }
    }
    
    // MARK: - Photo Evidence Methods
    
    /// Load completed tasks with potential photo evidence
    func loadCompletedTasks() async {
        do {
            // Get today's completed tasks
            let todayStart = Calendar.current.startOfDay(for: Date())
            
            let allTasks = try await taskService.getAllTasks()
            
            // Filter for completed tasks
            let completed = allTasks.filter { task in
                task.status == .completed &&
                task.completedAt != nil
            }
            
            // Sort by completion time (most recent first)
            let sorted = completed.sorted { task1, task2 in
                (task1.completedAt ?? Date.distantPast) > (task2.completedAt ?? Date.distantPast)
            }
            
            // Update published properties
            completedTasks = sorted
            
            // Get recent tasks (last 10 or today's, whichever is more)
            let todaysTasks = sorted.filter { task in
                guard let completedAt = task.completedAt else { return false }
                return completedAt >= todayStart
            }
            
            if todaysTasks.count >= 10 {
                recentCompletedTasks = Array(todaysTasks.prefix(10))
            } else {
                recentCompletedTasks = Array(sorted.prefix(10))
            }
            
        } catch {
            // ✅ STREAM A MODIFICATION: Localized error message
            let errorMessage = NSLocalizedString("Failed to load completed tasks", comment: "Completed tasks loading error")
            print("❌ \(errorMessage): \(error)")
            completedTasks = []
            recentCompletedTasks = []
        }
    }
    
    /// Count photos captured today
    func countTodaysPhotos() async {
        do {
            let todayStart = Calendar.current.startOfDay(for: Date())
            
            // Query photo evidence table for today's photos
            let rows = try await grdbManager.query("""
                SELECT COUNT(*) as count 
                FROM photo_evidence 
                WHERE created_at >= ?
            """, [todayStart.ISO8601Format()])
            
            if let row = rows.first,
               let count = row["count"] as? Int64 {
                todaysPhotoCount = Int(count)
            } else {
                todaysPhotoCount = 0
            }
            
        } catch {
            // ✅ STREAM A MODIFICATION: Localized error message
            let errorMessage = NSLocalizedString("Failed to count today's photos", comment: "Photo count error")
            print("❌ \(errorMessage): \(error)")
            todaysPhotoCount = 0
        }
    }
    
    /// Load photo compliance statistics
    func loadPhotoComplianceStats() async {
        photoComplianceStats = await getPhotoComplianceStats()
    }
    
    /// Get tasks with photo evidence for a specific building
    func getTasksWithPhotos(for buildingId: String) async -> [CoreTypes.ContextualTask] {
        do {
            let allTasks = try await taskService.getTasksForBuilding(buildingId)
            
            // Filter for completed tasks with photos
            let tasksWithPhotos = allTasks.filter { task in
                task.status == .completed && (task.requiresPhoto ?? false)
            }
            
            // Check which actually have photos
            var verifiedTasks: [CoreTypes.ContextualTask] = []
            
            for task in tasksWithPhotos {
                let photos = try await photoEvidenceService.loadPhotoEvidence(for: task.id)
                if !photos.isEmpty {
                    verifiedTasks.append(task)
                }
            }
            
            return verifiedTasks
            
        } catch {
            // ✅ STREAM A MODIFICATION: Localized error message
            let errorMessage = NSLocalizedString("Failed to get tasks with photos", comment: "Tasks with photos error")
            print("❌ \(errorMessage): \(error)")
            return []
        }
    }
    
    /// Check if a task has photo evidence
    func hasPhotoEvidence(taskId: String) async -> Bool {
        do {
            let photos = try await photoEvidenceService.loadPhotoEvidence(for: taskId)
            return !photos.isEmpty
        } catch {
            return false
        }
    }
    
    /// Get photo count for a building
    func getPhotoCount(for buildingId: String) async -> Int {
        do {
            let rows = try await grdbManager.query("""
                SELECT COUNT(*) as count 
                FROM photo_evidence pe
                JOIN task_completions tc ON pe.completion_id = tc.id
                WHERE tc.building_id = ?
            """, [buildingId])
            
            if let row = rows.first,
               let count = row["count"] as? Int64 {
                return Int(count)
            }
            
        } catch {
            // ✅ STREAM A MODIFICATION: Localized error message
            let errorMessage = NSLocalizedString("Failed to get photo count", comment: "Photo count error")
            print("❌ \(errorMessage): \(error)")
        }
        
        return 0
    }
    
    /// Get completion statistics with photo compliance
    func getPhotoComplianceStats() async -> PhotoComplianceStats {
        do {
            // Get tasks that require photos
            let requiredPhotoTasks = try await grdbManager.query("""
                SELECT COUNT(*) as count 
                FROM routine_tasks 
                WHERE requires_photo = 1 
                AND status = 'completed'
            """, [])
            
            let requiredCount = (requiredPhotoTasks.first?["count"] as? Int64).map(Int.init) ?? 0
            
            // Get tasks with actual photos
            let tasksWithPhotos = try await grdbManager.query("""
                SELECT COUNT(DISTINCT tc.task_id) as count 
                FROM task_completions tc
                JOIN photo_evidence pe ON tc.id = pe.completion_id
                JOIN routine_tasks rt ON tc.task_id = rt.id
                WHERE rt.requires_photo = 1
            """, [])
            
            let withPhotosCount = (tasksWithPhotos.first?["count"] as? Int64).map(Int.init) ?? 0
            
            let complianceRate = requiredCount > 0 ? Double(withPhotosCount) / Double(requiredCount) : 1.0
            
            return PhotoComplianceStats(
                tasksRequiringPhotos: requiredCount,
                tasksWithPhotos: withPhotosCount,
                complianceRate: complianceRate,
                missingPhotos: requiredCount - withPhotosCount
            )
            
        } catch {
            // ✅ STREAM A MODIFICATION: Localized error message
            let errorMessage = NSLocalizedString("Failed to get photo compliance stats", comment: "Photo compliance error")
            print("❌ \(errorMessage): \(error)")
            return PhotoComplianceStats(
                tasksRequiringPhotos: 0,
                tasksWithPhotos: 0,
                complianceRate: 0,
                missingPhotos: 0
            )
        }
    }
    
    // MARK: - Photo Update Subscriptions
    
    private func subscribeToPhotoUpdates() {
        // Subscribe to photo upload progress
        photoEvidenceService.$uploadProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                // Update UI if needed based on upload progress
                if progress > 0 && progress < 1 {
                    // ✅ STREAM A MODIFICATION: Localized progress message
                    let progressMessage = NSLocalizedString("Photo upload progress", comment: "Photo upload progress message")
                    print("📸 \(progressMessage): \(Int(progress * 100))%")
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to pending uploads count
        photoEvidenceService.$pendingUploads
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                // ✅ STREAM A MODIFICATION: Localized pending message
                let pendingMessage = NSLocalizedString("Pending photo uploads", comment: "Pending uploads message")
                print("📸 \(pendingMessage): \(count)")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Building Metrics Methods
    
    /// Loads building metrics for all buildings
    private func loadBuildingMetrics() async {
        var metrics: [String: CoreTypes.BuildingMetrics] = [:]
        
        for building in buildings {
            do {
                let buildingMetrics = try await buildingMetricsService.calculateMetrics(for: building.id)
                metrics[building.id] = buildingMetrics
            } catch {
                // ✅ STREAM A MODIFICATION: Localized error message
                let errorMessage = NSLocalizedString("Failed to load metrics for building", comment: "Building metrics error")
                print("⚠️ \(errorMessage) \(building.id): \(error)")
            }
        }
        
        self.buildingMetrics = metrics
        
        // Create and broadcast update
        let update = CoreTypes.DashboardUpdate(
            source: .admin,
            type: .buildingMetricsChanged,
            buildingId: "",
            workerId: "",
            data: [
                "buildingIds": Array(metrics.keys).joined(separator: ","),
                "totalBuildings": String(metrics.count)
            ]
        )
        broadcastAdminUpdate(update)
    }
    
    // MARK: - Portfolio Insights Methods
    
    /// Loads portfolio-wide intelligence insights
    func loadPortfolioInsights() async {
        isLoadingInsights = true
        
        do {
            let insights = try await intelligenceService.generatePortfolioInsights()
            self.portfolioInsights = insights
            self.isLoadingInsights = false
            
            // ✅ STREAM A MODIFICATION: Localized success message
            let successMessage = NSLocalizedString("Portfolio insights loaded", comment: "Portfolio insights success")
            print("✅ \(successMessage): \(insights.count) insights")
            
            // Create and broadcast update
            let update = CoreTypes.DashboardUpdate(
                source: .admin,
                type: .buildingMetricsChanged,
                buildingId: "",
                workerId: "",
                data: [
                    "insightCount": String(insights.count),
                    "criticalInsights": String(insights.filter { $0.priority == .critical }.count),
                    "intelligenceGenerated": "true"
                ]
            )
            broadcastAdminUpdate(update)
            
        } catch {
            self.portfolioInsights = []
            self.isLoadingInsights = false
            // ✅ STREAM A MODIFICATION: Localized error message
            let errorMessage = NSLocalizedString("Failed to load portfolio insights", comment: "Portfolio insights error")
            print("⚠️ \(errorMessage): \(error)")
        }
    }
    
    // MARK: - Building Intelligence Methods
    
    /// Fetches detailed intelligence for a specific building
    func fetchBuildingIntelligence(for buildingId: String) async {
        guard !buildingId.isEmpty else {
            // ✅ STREAM A MODIFICATION: Localized warning message
            let warningMessage = NSLocalizedString("Invalid building ID provided", comment: "Invalid building ID warning")
            print("⚠️ \(warningMessage)")
            return
        }
        
        isLoadingIntelligence = true
        selectedBuildingInsights = []
        selectedBuildingId = buildingId
        
        do {
            let insights = try await intelligenceService.generateBuildingInsights(for: buildingId)
            
            self.selectedBuildingInsights = insights
            self.isLoadingIntelligence = false
            
            // ✅ STREAM A MODIFICATION: Localized success message
            let successMessage = NSLocalizedString("Intelligence loaded for building", comment: "Building intelligence success")
            print("✅ \(successMessage) \(buildingId): \(insights.count) insights")
            
            // Create and broadcast update
            let update = CoreTypes.DashboardUpdate(
                source: .admin,
                type: .buildingMetricsChanged,
                buildingId: buildingId,
                workerId: "",
                data: [
                    "buildingInsights": String(insights.count),
                    "buildingId": buildingId,
                    "intelligenceGenerated": "true"
                ]
            )
            broadcastAdminUpdate(update)
            
        } catch {
            self.selectedBuildingInsights = []
            self.isLoadingIntelligence = false
            // ✅ STREAM A MODIFICATION: Localized error message
            let errorMessage = NSLocalizedString("Failed to load building intelligence", comment: "Building intelligence error")
            self.errorMessage = "\(errorMessage): \(error.localizedDescription)"
            print("❌ \(errorMessage): \(error)")
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
            
            // ✅ STREAM A MODIFICATION: Localized success message
            let successMessage = NSLocalizedString("Refreshed metrics for building", comment: "Building metrics refresh success")
            print("✅ \(successMessage) \(buildingId)")
            
            // Create and broadcast update
            let update = CoreTypes.DashboardUpdate(
                source: .admin,
                type: .buildingMetricsChanged,
                buildingId: buildingId,
                workerId: "",
                data: [
                    "buildingId": buildingId,
                    "completionRate": String(metrics.completionRate),
                    "overdueTasks": String(metrics.overdueTasks)
                ]
            )
            broadcastAdminUpdate(update)
            
        } catch {
            // ✅ STREAM A MODIFICATION: Localized error message
            let errorMessage = NSLocalizedString("Failed to refresh building metrics", comment: "Building metrics refresh error")
            print("❌ \(errorMessage): \(error)")
        }
    }
    
    // MARK: - Admin-specific Methods
    
    func loadAdminMetrics(building: String) async {
        await refreshBuildingMetrics(for: building)
    }
    
    func updateStatus(status: String) async {
        dashboardSyncStatus = CoreTypes.DashboardSyncStatus(rawValue: status) ?? .synced
        
        // Create and broadcast update
        let update = CoreTypes.DashboardUpdate(
            source: .admin,
            type: .buildingMetricsChanged,
            buildingId: "",
            workerId: "",
            data: [
                "adminStatus": status,
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "performanceUpdate": "true"
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
    
    /// Calculate portfolio summary metrics with photo data
    func getAdminPortfolioSummary() -> AdminPortfolioSummary {
        let completedToday = completedTasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return Calendar.current.isDateInToday(completedAt)
        }.count
        
        let totalTasksToday = tasks.filter { task in
            Calendar.current.isDateInToday(task.scheduledDate ?? Date())
        }.count
        
        let efficiency = totalTasksToday > 0
            ? Double(completedToday) / Double(totalTasksToday)
            : 0.0
        
        let efficiencyStatus: AdminPortfolioSummary.EfficiencyStatus = {
            switch efficiency {
            case 0.9...1.0: return .excellent
            case 0.7..<0.9: return .good
            case 0.5..<0.7: return .needsImprovement
            default: return .critical
            }
        }()
        
        let averageCompletion = buildingMetrics.values.isEmpty ? 0 :
            buildingMetrics.values.reduce(0) { $0 + $1.completionRate } / Double(buildingMetrics.count)
        
        return AdminPortfolioSummary(
            totalBuildings: buildings.count,
            totalWorkers: workers.count,
            activeWorkers: activeWorkers.count,
            totalTasks: totalTasksToday,
            completedTasks: completedToday,
            pendingTasks: totalTasksToday - completedToday,
            criticalInsights: portfolioInsights.filter { $0.priority == .critical }.count,
            completionRate: efficiency,
            averageTaskTime: 25.0, // This would be calculated from actual data
            overdueTasks: tasks.filter { $0.isOverdue }.count,
            complianceScore: photoComplianceStats?.complianceRate ?? 0.92,
            completionPercentage: "\(Int(efficiency * 100))%",
            efficiencyDescription: efficiencyStatus.description,
            efficiencyStatus: efficiencyStatus,
            todaysPhotoCount: todaysPhotoCount
        )
    }
    
    // MARK: - Cross-Dashboard Integration
    
    /// Setup cross-dashboard synchronization
    private func setupCrossDashboardSync() {
        // Subscribe to cross-dashboard updates
        dashboardSyncService.crossDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                guard let self = self else { return }
                Task {
                    await self.handleCrossDashboardUpdate(update)
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to worker dashboard updates
        dashboardSyncService.workerDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                guard let self = self else { return }
                Task {
                    await self.handleWorkerDashboardUpdate(update)
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to client dashboard updates
        dashboardSyncService.clientDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                guard let self = self else { return }
                Task {
                    await self.handleClientDashboardUpdate(update)
                }
            }
            .store(in: &cancellables)
        
        // ✅ STREAM A MODIFICATION: Localized setup message
        let setupMessage = NSLocalizedString("Admin dashboard cross-dashboard sync configured", comment: "Dashboard sync setup message")
        print("🔗 \(setupMessage)")
    }
    
    /// Broadcast admin update using DashboardUpdate directly
    private func broadcastAdminUpdate(_ update: CoreTypes.DashboardUpdate) {
        crossDashboardUpdates.append(update)
        
        // Keep only recent updates (last 50)
        if crossDashboardUpdates.count > 50 {
            crossDashboardUpdates = Array(crossDashboardUpdates.suffix(50))
        }
        
        dashboardSyncService.broadcastAdminUpdate(update)
        
        // ✅ STREAM A MODIFICATION: Localized broadcast message
        let broadcastMessage = NSLocalizedString("Admin update broadcast", comment: "Update broadcast message")
        print("📡 \(broadcastMessage): \(update.type)")
    }
    
    /// Setup auto-refresh timer
    private func setupAutoRefresh() {
        let timer = Timer(timeInterval: 30.0, repeats: true) { _ in
            Task { [weak self] in
                await self?.refreshDashboardData()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.refreshTimer = timer
    }
    
    /// Handle cross-dashboard updates with proper type and enum cases
    private func handleCrossDashboardUpdate(_ update: CoreTypes.DashboardUpdate) async {
        crossDashboardUpdates.append(update)
        
        // Keep only recent updates
        if crossDashboardUpdates.count > 50 {
            crossDashboardUpdates = Array(crossDashboardUpdates.suffix(50))
        }
        
        // Handle specific update types using correct enum cases
        switch update.type {
        case .taskCompleted:
            if !update.buildingId.isEmpty {
                await refreshBuildingMetrics(for: update.buildingId)
            }
            // Check if task had photo
            if let photoId = update.data["photoId"], !photoId.isEmpty {
                await countTodaysPhotos()
                await loadCompletedTasks()
            }
            
        case .workerClockedIn:
            if !update.buildingId.isEmpty {
                await refreshBuildingMetrics(for: update.buildingId)
            }
            await loadDashboardData()
            
        case .workerClockedOut:
            await loadDashboardData()
            
        case .complianceStatusChanged:
            await loadBuildingMetrics()
            await loadPhotoComplianceStats()
            
        case .buildingMetricsChanged:
            // Check if this is a portfolio update based on data flags
            if update.data["portfolioUpdate"] == "true" {
                await loadPortfolioInsights()
            }
            
        default:
            break
        }
    }
    
    /// Handle worker dashboard updates
    private func handleWorkerDashboardUpdate(_ update: CoreTypes.DashboardUpdate) async {
        switch update.type {
        case .taskCompleted, .taskStarted:
            if !update.buildingId.isEmpty {
                await refreshBuildingMetrics(for: update.buildingId)
            }
            // Reload tasks to get updated status
            await loadCompletedTasks()
            
        case .workerClockedIn, .workerClockedOut:
            // Update worker status tracking
            await loadDashboardData()
            
        default:
            break
        }
    }
    
    /// Handle client dashboard updates
    private func handleClientDashboardUpdate(_ update: CoreTypes.DashboardUpdate) async {
        switch update.type {
        case .buildingMetricsChanged:
            // Check if this is a portfolio update based on data flags
            if update.data["portfolioUpdate"] == "true" {
                await loadPortfolioInsights()
            }
            
        case .complianceStatusChanged:
            await loadBuildingMetrics()
            await loadPhotoComplianceStats()
            
        default:
            break
        }
    }
}

// MARK: - Supporting Types

struct PhotoComplianceStats {
    let tasksRequiringPhotos: Int
    let tasksWithPhotos: Int
    let complianceRate: Double
    let missingPhotos: Int
    
    var isCompliant: Bool {
        complianceRate >= 0.95 // 95% compliance threshold
    }
    
    var compliancePercentage: String {
        "\(Int(complianceRate * 100))%"
    }
}

struct AdminPortfolioSummary {
    let totalBuildings: Int
    let totalWorkers: Int
    let activeWorkers: Int
    let totalTasks: Int
    let completedTasks: Int
    let pendingTasks: Int
    let criticalInsights: Int
    let completionRate: Double
    let averageTaskTime: Double
    let overdueTasks: Int
    let complianceScore: Double
    let completionPercentage: String
    let efficiencyDescription: String
    let efficiencyStatus: EfficiencyStatus
    let todaysPhotoCount: Int
    
    struct EfficiencyStatus {
        let icon: String
        let color: Color
        let description: String
        
        static let excellent = EfficiencyStatus(
            icon: "checkmark.circle.fill",
            color: .green,
            description: NSLocalizedString("Excellent performance", comment: "Excellent efficiency status")
        )
        
        static let good = EfficiencyStatus(
            icon: "hand.thumbsup.fill",
            color: .blue,
            description: NSLocalizedString("Good performance", comment: "Good efficiency status")
        )
        
        static let needsImprovement = EfficiencyStatus(
            icon: "exclamationmark.triangle.fill",
            color: .orange,
            description: NSLocalizedString("Needs improvement", comment: "Needs improvement efficiency status")
        )
        
        static let critical = EfficiencyStatus(
            icon: "xmark.circle.fill",
            color: .red,
            description: NSLocalizedString("Critical attention needed", comment: "Critical efficiency status")
        )
    }
}

// MARK: - Worker Action Enum (Stream A Addition)

enum WorkerAction {
    case uploadPhoto
    case addNotes
    case viewMap
    case addEmergencyTask
}
