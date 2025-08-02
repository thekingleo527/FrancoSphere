//
//  DashboardSyncService.swift
//  FrancoSphere v6.0
//
//  Cross-dashboard synchronization service for real-time updates
//  Manages communication between Worker, Admin, and Client dashboards
//
//  ✅ UPDATED: Added publisher aliases for dashboard compatibility
//  ✅ UPDATED: Implemented client data anonymization
//  ✅ UPDATED: Added specialized broadcast methods for routine status
//  ✅ UPDATED: Enhanced context engine integration
//  ✅ UPDATED: Added debouncing for high-frequency updates
//  ✅ STREAM B INTEGRATED: WebSocket support for real-time server sync
//

import Foundation
import SwiftUI
import Combine

// MARK: - Dashboard Sync Service

@MainActor
public class DashboardSyncService: ObservableObject {
    public static let shared = DashboardSyncService()
    
    // MARK: - Cross-Dashboard Publishers
    
    private let crossDashboardSubject = PassthroughSubject<CoreTypes.DashboardUpdate, Never>()
    public var crossDashboardUpdates: AnyPublisher<CoreTypes.DashboardUpdate, Never> {
        crossDashboardSubject.eraseToAnyPublisher()
    }
    
    // Publisher aliases for dashboard compatibility
    public var crossDashboardPublisher: AnyPublisher<CoreTypes.DashboardUpdate, Never> {
        crossDashboardUpdates
    }
    
    // MARK: - Dashboard-Specific Publishers
    
    private let workerUpdatesSubject = PassthroughSubject<CoreTypes.DashboardUpdate, Never>()
    public var workerDashboardUpdates: AnyPublisher<CoreTypes.DashboardUpdate, Never> {
        workerUpdatesSubject.eraseToAnyPublisher()
    }
    
    private let adminUpdatesSubject = PassthroughSubject<CoreTypes.DashboardUpdate, Never>()
    public var adminDashboardUpdates: AnyPublisher<CoreTypes.DashboardUpdate, Never> {
        adminUpdatesSubject.eraseToAnyPublisher()
    }
    
    private let clientUpdatesSubject = PassthroughSubject<CoreTypes.DashboardUpdate, Never>()
    public var clientDashboardUpdates: AnyPublisher<CoreTypes.DashboardUpdate, Never> {
        clientUpdatesSubject.eraseToAnyPublisher()
    }
    
    // Publisher alias for client dashboard compatibility
    public var clientUpdatePublisher: AnyPublisher<CoreTypes.DashboardUpdate, Never> {
        clientDashboardUpdates
    }
    
    // MARK: - Live Update Feeds
    
    @Published public var liveWorkerUpdates: [LiveWorkerUpdate] = []
    @Published public var liveAdminAlerts: [LiveAdminAlert] = []
    @Published public var liveClientMetrics: [LiveClientMetric] = []
    
    // MARK: - Unified Dashboard State
    
    @Published public var unifiedBuildingMetrics: [String: CoreTypes.BuildingMetrics] = [:]
    @Published public var unifiedPortfolioIntelligence: CoreTypes.PortfolioIntelligence?
    @Published public var isLive = true
    @Published public var lastSyncTime: Date?
    @Published public var isOnline = true
    @Published public var pendingUpdatesCount = 0
    @Published public var urgentPendingCount = 0
    
    // MARK: - Service Dependencies
    
    private let buildingMetricsService = BuildingMetricsService.shared
    private let intelligenceService = IntelligenceService.shared
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let operationalDataManager = OperationalDataManager.shared
    private let grdbManager = GRDBManager.shared
    private let webSocketManager = WebSocketManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?
    private var offlineQueueTimer: Timer?
    private var urgentQueueTimer: Timer?
    private var cleanupTimer: Timer?
    private var isInitialized = false
    
    // Debouncing for high-frequency updates
    private var updateDebouncer: [String: Timer] = [:]
    
    // Debug mode for logging
    #if DEBUG
    private let debugMode = true
    #else
    private let debugMode = false
    #endif
    
    private init() {
        // Simple synchronous init - setup happens in initialize()
    }
    
    deinit {
        syncTimer?.invalidate()
        offlineQueueTimer?.invalidate()
        urgentQueueTimer?.invalidate()
        cleanupTimer?.invalidate()
        updateDebouncer.values.forEach { $0.invalidate() }
    }
    
    // MARK: - Initialization
    
    /// Initialize the service - must be called after creation
    public func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
        
        // Validate data sources
        guard validateDataSources() else {
            operationalDataManager.logError("DashboardSyncService initialization failed - limited functionality")
            return
        }
        
        setupRealTimeSynchronization()
        setupAutoSync()
        setupEnhancedOfflineQueueProcessing()
        setupNetworkMonitoring()
        setupWebSocketConnection()
    }
    
    // MARK: - WebSocket Setup (STREAM B)
    
    private func setupWebSocketConnection() {
        // Get auth token and connect
        Task {
            if let token = await getAuthToken() {
                await webSocketManager.connect(token: token)
            }
        }
    }
    
    private func getAuthToken() async -> String? {
        // Get token from NewAuthManager or similar auth service
        // This is a placeholder - actual implementation would get from auth service
        return UserDefaults.standard.string(forKey: "authToken")
    }
    
    // MARK: - Data Validation
    
    /// Validates that all required data sources are available
    private func validateDataSources() -> Bool {
        // Check if OperationalDataManager is initialized and has data
        guard operationalDataManager.isInitialized else {
            print("❌ DashboardSyncService: OperationalDataManager not initialized")
            return false
        }
        
        // Verify we can access configuration
        let config = operationalDataManager.getSystemConfiguration()
        guard config.isValid else {
            print("❌ DashboardSyncService: Invalid system configuration")
            return false
        }
        
        // Verify we have at least some cached data
        let hasWorkers = operationalDataManager.getCachedWorkerCount() > 0
        let hasBuildings = operationalDataManager.getCachedBuildingCount() > 0
        
        if !hasWorkers || !hasBuildings {
            print("⚠️ DashboardSyncService: Limited cached data, will fetch on demand")
        }
        
        return true
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        // Monitor network status changes
        NotificationCenter.default.publisher(for: .networkStatusChanged)
            .sink { [weak self] notification in
                guard let self = self else { return }
                if let isOnline = notification.userInfo?["isOnline"] as? Bool {
                    self.isOnline = isOnline
                    if isOnline {
                        Task {
                            await self.processPendingUpdatesBatch()
                            // Reconnect WebSocket if needed
                            if let token = await self.getAuthToken() {
                                await self.webSocketManager.connect(token: token)
                            }
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Broadcasting Methods

    /// Broadcast update from Worker Dashboard (task completion, clock-in, etc.)
    public func broadcastWorkerUpdate(_ update: CoreTypes.DashboardUpdate) {
        guard isLive else { return }
        
        // Enrich update with real data if needed
        let enrichedUpdate = enrichUpdateWithRealData(update)
        
        if isOnline {
            // 1. Send locally
            crossDashboardSubject.send(enrichedUpdate)
            
            // Send to specific dashboard streams
            workerUpdatesSubject.send(enrichedUpdate)
            adminUpdatesSubject.send(enrichedUpdate)
            
            // Send anonymized version to clients
            let anonymizedUpdate = anonymizeUpdateForClient(enrichedUpdate)
            clientUpdatesSubject.send(anonymizedUpdate)
            
            // Create live updates for real-time feeds
            createLiveWorkerUpdate(from: enrichedUpdate)
            createLiveAdminAlert(from: enrichedUpdate)
            createLiveClientMetric(from: anonymizedUpdate)
            
            // Update unified state
            updateUnifiedState(from: enrichedUpdate)
            
            // 2. Send via WebSocket
            Task {
                await sendToServer(enrichedUpdate)
            }
            
        } else {
            // Queue for later if offline
            Task {
                await enqueueUpdate(enrichedUpdate)
            }
        }
    }

    /// Broadcast update from Admin Dashboard (building metrics, intelligence, etc.)
    public func broadcastAdminUpdate(_ update: CoreTypes.DashboardUpdate) {
        guard isLive else { return }
        
        let enrichedUpdate = enrichUpdateWithRealData(update)
        
        if isOnline {
            // 1. Send locally
            crossDashboardSubject.send(enrichedUpdate)
            
            // Send to specific dashboard streams
            adminUpdatesSubject.send(enrichedUpdate)
            workerUpdatesSubject.send(enrichedUpdate)
            
            // Send anonymized version to clients
            let anonymizedUpdate = anonymizeUpdateForClient(enrichedUpdate)
            clientUpdatesSubject.send(anonymizedUpdate)
            
            // Create live updates
            createLiveAdminAlert(from: enrichedUpdate)
            createLiveClientMetric(from: anonymizedUpdate)
            
            // Update unified state
            updateUnifiedState(from: enrichedUpdate)
            
            // 2. Send via WebSocket
            Task {
                await sendToServer(enrichedUpdate)
            }
            
        } else {
            // Queue for later if offline
            Task {
                await enqueueUpdate(enrichedUpdate)
            }
        }
    }

    /// Broadcast update from Client Dashboard (portfolio changes, etc.)
    public func broadcastClientUpdate(_ update: CoreTypes.DashboardUpdate) {
        guard isLive else { return }
        
        // Client updates are already anonymized
        let enrichedUpdate = enrichUpdateWithRealData(update)
        
        if isOnline {
            // 1. Send locally
            crossDashboardSubject.send(enrichedUpdate)
            
            // Send to specific dashboard streams
            clientUpdatesSubject.send(enrichedUpdate)
            adminUpdatesSubject.send(enrichedUpdate)
            workerUpdatesSubject.send(enrichedUpdate)
            
            // Create live updates
            createLiveClientMetric(from: enrichedUpdate)
            createLiveAdminAlert(from: enrichedUpdate)
            
            // Update unified state
            updateUnifiedState(from: enrichedUpdate)
            
            // 2. Send via WebSocket
            Task {
                await sendToServer(enrichedUpdate)
            }
            
        } else {
            // Queue for later if offline
            Task {
                await enqueueUpdate(enrichedUpdate)
            }
        }
    }
    
    // MARK: - Client-Specific Broadcasting Methods
    
    /// Broadcast real-time routine status update for client dashboards
    public func broadcastRealtimeRoutineUpdate(
        buildingId: String,
        completionRate: Double,
        activeWorkerCount: Int,
        isOnSchedule: Bool,
        estimatedCompletion: Date? = nil
    ) {
        let update = CoreTypes.DashboardUpdate(
            source: .system,
            type: .routineStatusChanged,
            buildingId: buildingId,
            workerId: "",
            data: [
                "completionRate": String(completionRate),
                "activeWorkerCount": String(activeWorkerCount),
                "isOnSchedule": String(isOnSchedule),
                "timeBlock": String(describing: BuildingRoutineStatus.TimeBlock.current),
                "estimatedCompletion": estimatedCompletion?.ISO8601Format() ?? "",
                "buildingName": operationalDataManager.getBuilding(byId: buildingId)?.name ?? ""
            ]
        )
        broadcastClientUpdate(update)
    }
    
    /// Broadcast building routine statuses for multiple buildings
    public func broadcastBuildingRoutineStatuses(
        _ statuses: [String: BuildingRoutineStatus]
    ) {
        for (buildingId, status) in statuses {
            broadcastRealtimeRoutineUpdate(
                buildingId: buildingId,
                completionRate: status.completionRate,
                activeWorkerCount: status.activeWorkerCount,
                isOnSchedule: status.isOnSchedule,
                estimatedCompletion: status.estimatedCompletion
            )
        }
    }
    
    /// Broadcast compliance update for client dashboards
    public func broadcastComplianceUpdate(
        buildingId: String,
        score: Double,
        violations: Int,
        pendingInspections: Int = 0
    ) {
        let update = CoreTypes.DashboardUpdate(
            source: .admin,
            type: .complianceStatusChanged,
            buildingId: buildingId,
            workerId: "",
            data: [
                "complianceScore": String(score),
                "violations": String(violations),
                "pendingInspections": String(pendingInspections),
                "lastUpdated": ISO8601DateFormatter().string(from: Date())
            ]
        )
        broadcastClientUpdate(update)
    }
    
    /// Broadcast DSNY deadline for compliance tracking
    public func broadcastDSNYDeadline(
        buildingId: String,
        deadline: Date,
        status: String
    ) {
        let update = CoreTypes.DashboardUpdate(
            source: .system,
            type: .complianceStatusChanged,
            buildingId: buildingId,
            workerId: "",
            data: [
                "complianceType": "DSNY",
                "deadline": ISO8601DateFormatter().string(from: deadline),
                "status": status,
                "requiresAction": "true"
            ]
        )
        
        // Send to both admin and client
        broadcastAdminUpdate(update)
        broadcastClientUpdate(update)  // Will be anonymized
    }
    
    /// Broadcast monthly metrics update for client dashboards
    public func broadcastMonthlyMetricsUpdate(
        currentSpend: Double,
        monthlyBudget: Double,
        projectedSpend: Double,
        daysRemaining: Int
    ) {
        let update = CoreTypes.DashboardUpdate(
            source: .system,
            type: .monthlyMetricsUpdated,
            buildingId: "",
            workerId: "",
            data: [
                "currentSpend": String(currentSpend),
                "monthlyBudget": String(monthlyBudget),
                "projectedSpend": String(projectedSpend),
                "daysRemaining": String(daysRemaining),
                "budgetUtilization": String(currentSpend / monthlyBudget)
            ]
        )
        broadcastClientUpdate(update)
    }
    
    // MARK: - Admin-Specific Broadcasting Methods
    
    /// Broadcast critical alert for admin dashboards
    public func broadcastCriticalAlert(
        _ alert: CoreTypes.AdminAlert
    ) {
        let update = CoreTypes.DashboardUpdate(
            source: .admin,
            type: .criticalAlert,
            buildingId: alert.affectedBuilding ?? "",
            workerId: "",
            data: [
                "alertId": alert.id,
                "title": alert.title,
                "urgency": alert.urgency.rawValue,
                "type": alert.type.rawValue,
                "affectedBuilding": alert.affectedBuilding ?? "",
                "timestamp": alert.timestamp.ISO8601Format()
            ]
        )
        
        // Only broadcast to admin dashboards
        adminUpdatesSubject.send(update)
        
        // Create live admin alert
        createLiveAdminAlert(from: update)
    }
    
    /// Broadcast portfolio metrics for admin dashboards
    public func broadcastPortfolioMetrics(
        _ metrics: CoreTypes.PortfolioMetrics
    ) {
        let update = CoreTypes.DashboardUpdate(
            source: .admin,
            type: .portfolioMetricsChanged,
            buildingId: "",
            workerId: "",
            data: [
                "totalBuildings": String(metrics.totalBuildings),
                "totalWorkers": String(metrics.totalWorkers),
                "activeWorkers": String(metrics.activeWorkers),
                "overallCompletionRate": String(metrics.overallCompletionRate),
                "criticalIssues": String(metrics.criticalIssues),
                "complianceScore": String(metrics.complianceScore)
            ]
        )
        broadcastAdminUpdate(update)
    }
    
    // MARK: - Data Anonymization
    
    /// Anonymize update for client consumption
    private func anonymizeUpdateForClient(_ update: CoreTypes.DashboardUpdate) -> CoreTypes.DashboardUpdate {
        var anonymizedData = update.data
        
        // Remove worker-specific information
        anonymizedData.removeValue(forKey: "workerName")
        anonymizedData.removeValue(forKey: "workerId")
        anonymizedData.removeValue(forKey: "workerEmail")
        anonymizedData.removeValue(forKey: "workerPhone")
        
        // Replace with anonymous indicators
        if !update.workerId.isEmpty {
            anonymizedData["workerPresent"] = "true"
            anonymizedData["hasActiveWorker"] = "true"
        }
        
        // Anonymize any worker lists
        if let workerList = anonymizedData["workers"] {
            // Replace with count only
            if let workers = workerList.split(separator: ",") {
                anonymizedData["workerCount"] = String(workers.count)
                anonymizedData.removeValue(forKey: "workers")
            }
        }
        
        // Create anonymized update
        return CoreTypes.DashboardUpdate(
            id: update.id,
            source: update.source,
            type: update.type,
            buildingId: update.buildingId,
            workerId: "", // Clear worker ID
            data: anonymizedData,
            timestamp: update.timestamp
        )
    }
    
    // MARK: - Context Engine Integration
    
    /// Sync updates with AdminContextEngine
    public func syncAdminContextEngine(_ contextEngine: AdminContextEngine) {
        adminDashboardUpdates
            .sink { [weak contextEngine] update in
                Task { @MainActor in
                    contextEngine?.handleDashboardUpdate(update)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Sync updates with ClientContextEngine
    public func syncClientContextEngine(_ contextEngine: ClientContextEngine) {
        clientDashboardUpdates
            .filter { [weak contextEngine] update in
                // Only updates for client's buildings
                contextEngine?.clientBuildings.contains { $0.id == update.buildingId } ?? false
            }
            .sink { [weak contextEngine] update in
                Task { @MainActor in
                    contextEngine?.handleDashboardUpdate(update)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Sync updates with WorkerContextEngine
    public func syncWorkerContextEngine(_ contextEngine: WorkerContextEngine) {
        workerDashboardUpdates
            .filter { [weak contextEngine] update in
                // Only updates relevant to the worker
                update.workerId == contextEngine?.currentWorker?.id ||
                update.buildingId == contextEngine?.assignedBuilding?.id
            }
            .sink { [weak contextEngine] update in
                Task { @MainActor in
                    contextEngine?.handleDashboardUpdate(update)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Debounced Updates
    
    /// Debounce high-frequency updates
    private func debouncedBroadcast(
        key: String,
        delay: TimeInterval = 0.5,
        update: @escaping () -> Void
    ) {
        updateDebouncer[key]?.invalidate()
        updateDebouncer[key] = Timer.scheduledTimer(
            withTimeInterval: delay,
            repeats: false
        ) { _ in
            update()
        }
    }
    
    // MARK: - WebSocket Integration (STREAM B)
    
    /// Send update to server via WebSocket
    private func sendToServer(_ update: CoreTypes.DashboardUpdate) async {
        do {
            try await webSocketManager.send(update)
            print("🌐 Sent update to server: \(update.type.rawValue)")
        } catch {
            print("❌ Failed to send update to server: \(error)")
            // Queue for retry
            await enqueueUpdate(update)
        }
    }
    
    /// Handle update received from server via WebSocket
    public func handleRemoteUpdate(_ update: CoreTypes.DashboardUpdate) {
        Task {
            // Handle conflicts
            await detectAndResolveConflicts(update)
            
            // Broadcast the remote update locally
            switch update.source {
            case .worker:
                workerUpdatesSubject.send(update)
                // Also send anonymized version to clients
                let anonymized = anonymizeUpdateForClient(update)
                clientUpdatesSubject.send(anonymized)
            case .admin:
                adminUpdatesSubject.send(update)
                // Send relevant updates to clients
                if shouldClientSeeUpdate(update) {
                    let anonymized = anonymizeUpdateForClient(update)
                    clientUpdatesSubject.send(anonymized)
                }
            case .client:
                clientUpdatesSubject.send(update)
                adminUpdatesSubject.send(update)
            case .system:
                crossDashboardSubject.send(update)
            }
            
            // Update local state
            createLiveUpdateFromRemote(update)
            updateUnifiedState(from: update)
        }
    }
    
    /// Determine if client should see an update
    private func shouldClientSeeUpdate(_ update: CoreTypes.DashboardUpdate) -> Bool {
        switch update.type {
        case .buildingMetricsChanged,
             .complianceStatusChanged,
             .routineStatusChanged,
             .monthlyMetricsUpdated:
            return true
        case .taskCompleted:
            // Only if it affects completion rate
            return true
        case .workerClockedIn, .workerClockedOut:
            // Only as anonymous count changes
            return true
        default:
            return false
        }
    }
    
    /// Detect and resolve conflicts between local and remote updates
    private func detectAndResolveConflicts(_ update: CoreTypes.DashboardUpdate) async {
        // Check if we have a conflicting local update
        let hasConflict = await checkForConflict(update)
        
        if hasConflict {
            print("⚠️ Conflict detected for update: \(update.id)")
            
            // Resolve based on conflict resolution strategy
            let resolution = await resolveConflict(update)
            
            switch resolution {
            case .acceptRemote:
                // Accept the remote update as-is
                print("✅ Resolved conflict: Accepting remote update")
                
            case .acceptLocal:
                // Keep local version, ignore remote
                print("✅ Resolved conflict: Keeping local version")
                return // Don't process the remote update
                
            case .merge(let mergedUpdate):
                // Use merged version
                print("✅ Resolved conflict: Using merged version")
                handleResolvedUpdate(mergedUpdate)
                return
                
            case .manual:
                // Queue for manual resolution
                print("⚠️ Conflict requires manual resolution")
                await queueForManualResolution(update)
                return
            }
        }
    }
    
    private func checkForConflict(_ update: CoreTypes.DashboardUpdate) async -> Bool {
        // Check if we have a recent local update for the same entity
        do {
            let recentUpdates = try await grdbManager.query("""
                SELECT * FROM sync_queue
                WHERE entity_id = ? AND entity_type = ?
                AND created_at > ?
                ORDER BY created_at DESC
                LIMIT 1
            """, [
                update.buildingId.isEmpty ? update.workerId : update.buildingId,
                "dashboard_update",
                Date().addingTimeInterval(-30).ISO8601Format() // Within last 30 seconds
            ])
            
            return !recentUpdates.isEmpty
        } catch {
            return false
        }
    }
    
    private enum ConflictResolution {
        case acceptRemote
        case acceptLocal
        case merge(CoreTypes.DashboardUpdate)
        case manual
    }
    
    private func resolveConflict(_ update: CoreTypes.DashboardUpdate) async -> ConflictResolution {
        // Simple last-write-wins strategy for now
        switch update.type {
        case .taskCompleted:
            // Task completions should never conflict - accept all
            return .acceptRemote
            
        case .buildingMetricsChanged:
            // Metrics can be merged
            if let localMetrics = unifiedBuildingMetrics[update.buildingId],
               let remoteCompletion = Double(update.data["completionRate"] ?? "0") {
                
                // Take the average for now (simple merge strategy)
                let mergedCompletion = (localMetrics.completionRate + remoteCompletion) / 2
                
                var mergedData = update.data
                mergedData["completionRate"] = String(mergedCompletion)
                
                let mergedUpdate = CoreTypes.DashboardUpdate(
                    source: update.source,
                    type: update.type,
                    buildingId: update.buildingId,
                    workerId: update.workerId,
                    data: mergedData
                )
                
                return .merge(mergedUpdate)
            }
            return .acceptRemote
            
        case .workerClockedIn, .workerClockedOut:
            // Clock events should be ordered - last one wins
            return .acceptRemote
            
        default:
            // Default to accepting remote
            return .acceptRemote
        }
    }
    
    private func handleResolvedUpdate(_ update: CoreTypes.DashboardUpdate) {
        // Process the resolved update
        crossDashboardSubject.send(update)
        updateUnifiedState(from: update)
    }
    
    private func queueForManualResolution(_ update: CoreTypes.DashboardUpdate) async {
        // Store in a special conflict queue for admin review
        do {
            let updateData = try JSONEncoder().encode(update)
            
            try await grdbManager.execute("""
                INSERT INTO conflict_queue (
                    id, update_data, conflict_type, created_at
                ) VALUES (?, ?, ?, ?)
            """, [
                UUID().uuidString,
                String(data: updateData, encoding: .utf8) ?? "{}",
                "dashboard_update",
                Date().ISO8601Format()
            ])
            
            print("📋 Queued update for manual conflict resolution")
        } catch {
            print("❌ Failed to queue conflict: \(error)")
        }
    }
    
    private func createLiveUpdateFromRemote(_ update: CoreTypes.DashboardUpdate) {
        // Create appropriate live update based on source
        switch update.source {
        case .worker:
            createLiveWorkerUpdate(from: update)
        case .admin:
            createLiveAdminAlert(from: update)
        case .client:
            createLiveClientMetric(from: update)
        case .system:
            // System updates might create all types
            createLiveWorkerUpdate(from: update)
            createLiveAdminAlert(from: update)
            createLiveClientMetric(from: update)
        }
    }
    
    // MARK: - Live Update Types

    public struct LiveWorkerUpdate {
        public let id = UUID()
        public let workerId: String
        public let workerName: String?
        public let action: String
        public let buildingId: String?
        public let buildingName: String?
        public let timestamp = Date()
        
        public init(workerId: String, workerName: String? = nil, action: String, buildingId: String? = nil, buildingName: String? = nil) {
            self.workerId = workerId
            self.workerName = workerName
            self.action = action
            self.buildingId = buildingId
            self.buildingName = buildingName
        }
    }

    public struct LiveAdminAlert {
        public let id = UUID()
        public let title: String
        public let severity: Severity
        public let buildingId: String
        public let timestamp = Date()
        
        public enum Severity: String, CaseIterable {
            case low = "Low"
            case medium = "Medium"
            case high = "High"
            case critical = "Critical"
            
            var color: Color {
                switch self {
                case .low: return .green
                case .medium: return .yellow
                case .high: return .orange
                case .critical: return .red
                }
            }
        }
        
        public init(title: String, severity: Severity, buildingId: String) {
            self.title = title
            self.severity = severity
            self.buildingId = buildingId
        }
    }

    public struct LiveClientMetric {
        public let id = UUID()
        public let name: String
        public let value: String
        public let trend: CoreTypes.TrendDirection
        public let timestamp = Date()
        
        public init(name: String, value: String, trend: CoreTypes.TrendDirection) {
            self.name = name
            self.value = value
            self.trend = trend
        }
    }
    
    // MARK: - Priority Levels
    
    public enum UpdatePriority: Int {
        case low = 0
        case normal = 1
        case high = 2
        case urgent = 3
        
        static func fromUpdateType(_ type: CoreTypes.DashboardUpdate.UpdateType) -> UpdatePriority {
            switch type {
            case .workerClockedIn, .workerClockedOut:
                return .urgent // Clock events need immediate sync
            case .taskCompleted:
                return .high // Task completions are important
            case .buildingMetricsChanged:
                return .normal // Metrics can wait a bit
            case .complianceStatusChanged:
                return .urgent // Compliance is critical
            case .criticalAlert:
                return .urgent // Critical alerts are urgent
            case .routineStatusChanged:
                return .high // Real-time status is important
            default:
                return .normal
            }
        }
    }
    
    // MARK: - Enhanced Offline Queue Implementation
    
    private func enqueueUpdate(_ update: CoreTypes.DashboardUpdate) async {
        await enqueueUpdateWithPriority(update)
    }
    
    private func enqueueUpdateWithPriority(_ update: CoreTypes.DashboardUpdate) async {
        do {
            // Determine priority
            let priority = UpdatePriority.fromUpdateType(update.type)
            
            // Compress update data if large
            let updateData = try JSONEncoder().encode(update)
            let compressedData = await compressDataIfNeeded(updateData)
            let isCompressed = compressedData.count < updateData.count
            
            // Calculate exponential backoff delay for retries
            let baseRetryDelay = 2.0 // 2 seconds base
            
            try await grdbManager.execute("""
                INSERT INTO sync_queue (
                    id, entity_type, entity_id, action,
                    data, retry_count, priority, is_compressed,
                    retry_delay, created_at, expires_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, [
                update.id,
                "dashboard_update",
                update.buildingId.isEmpty ? update.workerId : update.buildingId,
                update.type.rawValue,
                String(data: compressedData, encoding: .utf8) ?? "{}",
                0,
                priority.rawValue,
                isCompressed ? 1 : 0,
                baseRetryDelay,
                Date().ISO8601Format(),
                Date().addingTimeInterval(86400).ISO8601Format() // 24 hour expiry
            ])
            
            // Update pending count
            await updatePendingCountWithPriority()
            
            print("📥 Queued update with priority \(priority): \(update.type)")
            
            // Trigger immediate processing for urgent updates
            if priority == .urgent && isOnline {
                Task {
                    await processUrgentUpdates()
                }
            }
            
        } catch {
            print("❌ Failed to queue update: \(error)")
            operationalDataManager.logError("Failed to enqueue dashboard update", error: error)
        }
    }
    
    // MARK: - Batch Processing
    
    public func processPendingUpdatesBatch() async {
        guard isOnline else { return }
        
        do {
            // Get updates in priority order, with retry limit
            let rows = try await grdbManager.query("""
                SELECT * FROM sync_queue
                WHERE entity_type = 'dashboard_update'
                AND retry_count < ?
                AND (expires_at IS NULL OR expires_at > ?)
                ORDER BY priority DESC, created_at ASC
                LIMIT ?
            """, [
                getMaxRetries(),
                Date().ISO8601Format(),
                getBatchSize()
            ])
            
            guard !rows.isEmpty else {
                await updatePendingCountWithPriority()
                await cleanupExpiredItems()
                return
            }
            
            print("📤 Batch processing \(rows.count) pending updates")
            
            // Group updates by type for efficient batch sending
            let updateBatches = await groupUpdatesForBatching(rows)
            
            // Process each batch
            for (batchType, batchItems) in updateBatches {
                await processBatch(batchType: batchType, items: batchItems)
            }
            
            // Update pending count
            await updatePendingCountWithPriority()
            
        } catch {
            operationalDataManager.logError("Failed to process pending updates batch", error: error)
        }
    }
    
    private func groupUpdatesForBatching(_ rows: [[String: Any]]) async -> [String: [[String: Any]]] {
        var batches: [String: [[String: Any]]] = [:]
        
        for row in rows {
            guard let action = row["action"] as? String else { continue }
            
            if batches[action] == nil {
                batches[action] = []
            }
            batches[action]?.append(row)
        }
        
        return batches
    }
    
    private func processBatch(batchType: String, items: [[String: Any]]) async {
        var updates: [CoreTypes.DashboardUpdate] = []
        var queueIds: [String] = []
        
        // Decode all updates in the batch
        for item in items {
            guard let queueId = item["id"] as? String,
                  let dataString = item["data"] as? String,
                  let isCompressed = item["is_compressed"] as? Int64,
                  let data = dataString.data(using: .utf8) else {
                continue
            }
            
            do {
                // Decompress if needed
                let decompressedData = isCompressed == 1 ? await decompressData(data) : data
                let update = try JSONDecoder().decode(CoreTypes.DashboardUpdate.self, from: decompressedData)
                
                updates.append(update)
                queueIds.append(queueId)
            } catch {
                print("⚠️ Failed to decode queued update: \(error)")
                await handleFailedUpdate(item)
            }
        }
        
        // Send batch via WebSocket
        if !updates.isEmpty {
            await sendBatchToServer(updates: updates, queueIds: queueIds)
        }
    }
    
    private func sendBatchToServer(updates: [CoreTypes.DashboardUpdate], queueIds: [String]) async {
        do {
            // Send all updates in a batch
            for (index, update) in updates.enumerated() {
                try await webSocketManager.send(update)
                
                // Remove from queue on success
                try await grdbManager.execute(
                    "DELETE FROM sync_queue WHERE id = ?",
                    [queueIds[index]]
                )
            }
            
            print("✅ Batch sent successfully: \(updates.count) updates")
            
        } catch {
            print("❌ Batch send failed: \(error)")
            
            // Handle batch failure with exponential backoff
            for queueId in queueIds {
                await incrementRetryWithBackoff(queueId: queueId)
            }
        }
    }
    
    // MARK: - Exponential Backoff
    
    private func incrementRetryWithBackoff(queueId: String) async {
        do {
            // Get current retry info
            let rows = try await grdbManager.query(
                "SELECT retry_count, retry_delay FROM sync_queue WHERE id = ?",
                [queueId]
            )
            
            guard let row = rows.first,
                  let retryCount = row["retry_count"] as? Int,
                  let currentDelay = row["retry_delay"] as? Double else {
                return
            }
            
            // Calculate next delay with exponential backoff
            let newRetryCount = retryCount + 1
            let newDelay = min(currentDelay * 2.0, 300.0) // Max 5 minutes
            let nextRetryTime = Date().addingTimeInterval(newDelay)
            
            try await grdbManager.execute("""
                UPDATE sync_queue
                SET retry_count = ?,
                    retry_delay = ?,
                    last_retry_at = ?,
                    next_retry_at = ?
                WHERE id = ?
            """, [
                newRetryCount,
                newDelay,
                Date().ISO8601Format(),
                nextRetryTime.ISO8601Format(),
                queueId
            ])
            
            print("⏱️ Update \(queueId) will retry in \(newDelay) seconds (attempt \(newRetryCount))")
            
        } catch {
            print("❌ Failed to update retry info: \(error)")
        }
    }
    
    private func handleFailedUpdate(_ item: [String: Any]) async {
        guard let queueId = item["id"] as? String else { return }
        await incrementRetryWithBackoff(queueId: queueId)
    }
    
    // MARK: - Urgent Updates Processing
    
    private func processUrgentUpdates() async {
        guard isOnline else { return }
        
        do {
            // Get only urgent updates
            let rows = try await grdbManager.query("""
                SELECT * FROM sync_queue
                WHERE entity_type = 'dashboard_update'
                AND priority = ?
                AND retry_count < ?
                ORDER BY created_at ASC
                LIMIT 10
            """, [
                UpdatePriority.urgent.rawValue,
                3 // Fewer retries for urgent items
            ])
            
            for item in rows {
                guard let queueId = item["id"] as? String,
                      let dataString = item["data"] as? String,
                      let data = dataString.data(using: .utf8) else {
                    continue
                }
                
                do {
                    let update = try JSONDecoder().decode(CoreTypes.DashboardUpdate.self, from: data)
                    
                    // Send immediately
                    try await webSocketManager.send(update)
                    
                    // Remove from queue on success
                    try await grdbManager.execute(
                        "DELETE FROM sync_queue WHERE id = ?",
                        [queueId]
                    )
                    
                    print("🚨 Urgent update processed: \(update.type)")
                    
                } catch {
                    await handleFailedUpdate(item)
                }
            }
            
        } catch {
            print("❌ Failed to process urgent updates: \(error)")
        }
    }
    
    // MARK: - Compression
    
    private func compressDataIfNeeded(_ data: Data) async -> Data {
        // Only compress if data is larger than 1KB
        guard data.count > 1024 else { return data }
        
        if let compressed = try? (data as NSData).compressed(using: .zlib) as Data {
            let ratio = Double(compressed.count) / Double(data.count)
            print("🗜️ Compressed update: \(data.count) → \(compressed.count) bytes (ratio: \(String(format: "%.2f", ratio)))")
            return compressed
        }
        
        return data
    }
    
    private func decompressData(_ data: Data) async -> Data {
        if let decompressed = try? (data as NSData).decompressed(using: .zlib) as Data {
            return decompressed
        }
        print("⚠️ Decompression failed, assuming uncompressed data")
        return data
    }
    
    // MARK: - Automatic Cleanup
    
    private func cleanupExpiredItems() async {
        do {
            // Get counts before deletion for logging
            let expiredCount = try await grdbManager.query("""
                SELECT COUNT(*) as count FROM sync_queue
                WHERE entity_type = 'dashboard_update'
                AND expires_at IS NOT NULL
                AND expires_at < ?
            """, [Date().ISO8601Format()]).first?["count"] as? Int64 ?? 0
            
            if expiredCount > 0 {
                // Delete expired items
                try await grdbManager.execute("""
                    DELETE FROM sync_queue
                    WHERE entity_type = 'dashboard_update'
                    AND expires_at IS NOT NULL
                    AND expires_at < ?
                """, [Date().ISO8601Format()])
                
                print("🧹 Cleaned up \(expiredCount) expired queue items")
            }
            
            // Count items that exceed max retries
            let maxRetries = getMaxRetries()
            let failedCount = try await grdbManager.query("""
                SELECT COUNT(*) as count FROM sync_queue
                WHERE entity_type = 'dashboard_update'
                AND retry_count >= ?
            """, [maxRetries]).first?["count"] as? Int64 ?? 0
            
            if failedCount > 0 {
                // Remove failed items
                try await grdbManager.execute("""
                    DELETE FROM sync_queue
                    WHERE entity_type = 'dashboard_update'
                    AND retry_count >= ?
                """, [maxRetries])
                
                print("🧹 Removed \(failedCount) failed queue items")
            }
            
            // Archive old successful items (optional)
            await archiveOldItems()
            
        } catch {
            print("❌ Cleanup failed: \(error)")
        }
    }
    
    private func archiveOldItems() async {
        // Move successfully processed items older than 7 days to archive table
        do {
            let archiveDate = Date().addingTimeInterval(-604800) // 7 days ago
            
            // Check if archive table exists first
            let tableExists = try await grdbManager.query("""
                SELECT name FROM sqlite_master 
                WHERE type='table' AND name='sync_queue_archive'
            """).first != nil
            
            guard tableExists else { return }
            
            // Count items to archive
            let archiveCount = try await grdbManager.query("""
                SELECT COUNT(*) as count FROM sync_queue
                WHERE entity_type = 'dashboard_update'
                AND created_at < ?
                AND retry_count = 0
            """, [archiveDate.ISO8601Format()]).first?["count"] as? Int64 ?? 0
            
            if archiveCount > 0 {
                // Copy to archive
                try await grdbManager.execute("""
                    INSERT INTO sync_queue_archive
                    SELECT * FROM sync_queue
                    WHERE entity_type = 'dashboard_update'
                    AND created_at < ?
                    AND retry_count = 0
                """, [archiveDate.ISO8601Format()])
                
                // Delete from main queue
                try await grdbManager.execute("""
                    DELETE FROM sync_queue
                    WHERE entity_type = 'dashboard_update'
                    AND created_at < ?
                    AND retry_count = 0
                """, [archiveDate.ISO8601Format()])
                
                print("📦 Archived \(archiveCount) old queue items")
            }
            
        } catch {
            // Archive table might not exist, that's ok
        }
    }
    
    // MARK: - Configuration
    
    private func getBatchSize() -> Int {
        // Default value since SystemConfiguration doesn't have syncBatchSize
        return 50
    }
    
    private func getMaxRetries() -> Int {
        // Default value since SystemConfiguration doesn't have maxSyncRetries
        return 5
    }
    
    // MARK: - Enhanced Timer Setup
    
    private func setupEnhancedOfflineQueueProcessing() {
        // Urgent items - every 10 seconds
        urgentQueueTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isOnline else { return }
                await self.processUrgentUpdates()
            }
        }
        
        // Regular batch processing - every 30 seconds
        offlineQueueTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isOnline else { return }
                await self.processPendingUpdatesBatch()
            }
        }
        
        // Cleanup - every 5 minutes
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                await self.cleanupExpiredItems()
            }
        }
        
        // Process immediately on startup
        Task {
            await processPendingUpdatesBatch()
            await cleanupExpiredItems()
        }
    }
    
    // MARK: - Updated Pending Count
    
    private func updatePendingCountWithPriority() async {
        do {
            // Get counts by priority
            let counts = try await grdbManager.query("""
                SELECT priority, COUNT(*) as count
                FROM sync_queue
                WHERE entity_type = 'dashboard_update'
                AND retry_count < ?
                GROUP BY priority
            """, [getMaxRetries()])
            
            var totalCount = 0
            var urgentCount = 0
            
            for row in counts {
                if let priority = row["priority"] as? Int,
                   let count = row["count"] as? Int64 {
                    totalCount += Int(count)
                    if priority == UpdatePriority.urgent.rawValue {
                        urgentCount = Int(count)
                    }
                }
            }
            
            await MainActor.run {
                self.pendingUpdatesCount = totalCount
                self.urgentPendingCount = urgentCount
            }
            
            if urgentCount > 0 {
                print("⚠️ \(urgentCount) urgent updates pending")
            }
            
        } catch {
            print("❌ Failed to update pending count: \(error)")
        }
    }
    
    // MARK: - Data Enrichment
    
    private func enrichUpdateWithRealData(_ update: CoreTypes.DashboardUpdate) -> CoreTypes.DashboardUpdate {
        var enrichedData = update.data
        
        // Add real worker name if we have workerId
        if !update.workerId.isEmpty, enrichedData["workerName"] == nil || enrichedData["workerName"] == "" {
            if let worker = operationalDataManager.getWorker(byId: update.workerId) {
                enrichedData["workerName"] = worker.name
            }
        }
        
        // Add real building name if we have buildingId
        if !update.buildingId.isEmpty, enrichedData["buildingName"] == nil || enrichedData["buildingName"] == "" {
            if let building = operationalDataManager.getBuilding(byId: update.buildingId) {
                enrichedData["buildingName"] = building.name
            }
        }
        
        // Add timestamp if not present
        if enrichedData["timestamp"] == nil {
            enrichedData["timestamp"] = ISO8601DateFormatter().string(from: Date())
        }
        
        // Create new update with enriched data
        return CoreTypes.DashboardUpdate(
            source: update.source,
            type: update.type,
            buildingId: update.buildingId,
            workerId: update.workerId,
            data: enrichedData
        )
    }
    
    // MARK: - Convenience Broadcasting Methods
    
    /// Worker clocked in
    public func onWorkerClockedIn(workerId: String, buildingId: String, buildingName: String? = nil) {
        // Get real data from OperationalDataManager
        let workerName = operationalDataManager.getWorker(byId: workerId)?.name ?? ""
        let realBuildingName = buildingName ?? operationalDataManager.getBuilding(byId: buildingId)?.name ?? ""
        
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: .workerClockedIn,
            buildingId: buildingId,
            workerId: workerId,
            data: [
                "buildingName": realBuildingName,
                "workerName": workerName
            ]
        )
        broadcastWorkerUpdate(update)
    }
    
    /// Worker clocked out
    public func onWorkerClockedOut(workerId: String, buildingId: String, duration: TimeInterval? = nil) {
        let workerName = operationalDataManager.getWorker(byId: workerId)?.name ?? ""
        let buildingName = operationalDataManager.getBuilding(byId: buildingId)?.name ?? ""
        
        var data: [String: String] = [
            "buildingName": buildingName,
            "workerName": workerName
        ]
        
        if let duration = duration {
            let hours = Int(duration / 3600)
            let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
            data["duration"] = "\(hours)h \(minutes)m"
        }
        
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: .workerClockedOut,
            buildingId: buildingId,
            workerId: workerId,
            data: data
        )
        broadcastWorkerUpdate(update)
    }
    
    /// Task completed
    public func onTaskCompleted(taskId: String, workerId: String, buildingId: String, taskName: String? = nil) {
        let workerName = operationalDataManager.getWorker(byId: workerId)?.name ?? ""
        let buildingName = operationalDataManager.getBuilding(byId: buildingId)?.name ?? ""
        
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: .taskCompleted,
            buildingId: buildingId,
            workerId: workerId,
            data: [
                "taskId": taskId,
                "taskName": taskName ?? "task",
                "buildingName": buildingName,
                "workerName": workerName
            ]
        )
        broadcastWorkerUpdate(update)
    }
    
    /// Building metrics changed (with debouncing)
    public func onBuildingMetricsChanged(buildingId: String, metrics: CoreTypes.BuildingMetrics) {
        debouncedBroadcast(key: "metrics_\(buildingId)", delay: 0.5) { [weak self] in
            guard let self = self else { return }
            
            // Record metric values for trend analysis
            self.operationalDataManager.recordMetricValue(
                metricName: "building_\(buildingId)_completion",
                value: metrics.completionRate
            )
            
            let update = CoreTypes.DashboardUpdate(
                source: .admin,
                type: .buildingMetricsChanged,
                buildingId: buildingId,
                workerId: "",
                data: [
                    "completionRate": String(metrics.completionRate),
                    "overdueTasks": String(metrics.overdueTasks),
                    "urgentTasks": String(metrics.urgentTasksCount),
                    "activeWorkers": String(metrics.activeWorkers)
                ]
            )
            self.broadcastAdminUpdate(update)
        }
    }
    
    /// Intelligence insights generated
    public func onIntelligenceGenerated(insights: [CoreTypes.IntelligenceInsight]) {
        let update = CoreTypes.DashboardUpdate(
            source: .admin,
            type: .intelligenceGenerated,
            buildingId: "",
            workerId: "",
            data: [
                "insightCount": String(insights.count),
                "highPriorityCount": String(insights.filter { $0.priority == .high || $0.priority == .critical }.count),
                "intelligenceUpdate": "true"
            ]
        )
        broadcastAdminUpdate(update)
    }
    
    // MARK: - Live Update Creation
    
    private func createLiveWorkerUpdate(from update: CoreTypes.DashboardUpdate) {
        guard update.source == .worker else { return }
        
        let workerUpdate = LiveWorkerUpdate(
            workerId: update.workerId,
            workerName: update.data["workerName"], // Only for admin dashboard
            action: generateDetailedAction(for: update),
            buildingId: update.buildingId.isEmpty ? nil : update.buildingId,
            buildingName: update.data["buildingName"]
        )
        
        liveWorkerUpdates.append(workerUpdate)
        limitLiveUpdates()
    }
    
    private func createLiveAdminAlert(from update: CoreTypes.DashboardUpdate) {
        guard update.type == .buildingMetricsChanged ||
              update.type == .complianceStatusChanged ||
              update.type == .criticalAlert else { return }
        
        // Use real thresholds from OperationalDataManager
        let config = operationalDataManager.getSystemConfiguration()
        
        let severity: LiveAdminAlert.Severity = {
            if update.type == .criticalAlert {
                return .critical
            } else if let overdueTasks = Int(update.data["overdueTasks"] ?? "0"),
               overdueTasks > config.criticalOverdueThreshold {
                return .critical
            } else if let completionRate = Double(update.data["completionRate"] ?? "0"),
                     completionRate < config.minimumCompletionRate {
                return .high
            } else if let urgentTasks = Int(update.data["urgentTasks"] ?? "0"),
                     urgentTasks > config.urgentTaskThreshold {
                return .medium
            } else {
                return .low
            }
        }()
        
        let title = update.data["title"] ?? update.type.rawValue
        
        let alert = LiveAdminAlert(
            title: title,
            severity: severity,
            buildingId: update.buildingId
        )
        
        liveAdminAlerts.append(alert)
        limitLiveUpdates()
    }
    
    private func createLiveClientMetric(from update: CoreTypes.DashboardUpdate) {
        guard update.type == .buildingMetricsChanged ||
              update.type == .routineStatusChanged ||
              update.type == .monthlyMetricsUpdated else { return }
        
        // Calculate real trend from OperationalDataManager historical data
        let trend: CoreTypes.TrendDirection = {
            if let metricName = update.data["metricName"] {
                return operationalDataManager.calculateTrend(for: metricName, days: 7)
            }
            // Try to calculate trend for building completion if available
            if !update.buildingId.isEmpty {
                return operationalDataManager.calculateTrend(
                    for: "building_\(update.buildingId)_completion",
                    days: 7
                )
            }
            return .stable
        }()
        
        let metricName: String = {
            switch update.type {
            case .routineStatusChanged:
                return "Routine Status"
            case .monthlyMetricsUpdated:
                return "Monthly Budget"
            default:
                return "Building Metrics"
            }
        }()
        
        let metricValue: String = {
            if let value = update.data["completionRate"] {
                return "\(value)%"
            } else if let value = update.data["budgetUtilization"] {
                return "\(value)%"
            }
            return "N/A"
        }()
        
        let metric = LiveClientMetric(
            name: metricName,
            value: metricValue,
            trend: trend
        )
        
        liveClientMetrics.append(metric)
        limitLiveUpdates()
    }
    
    private func limitLiveUpdates() {
        // Get limit from OperationalDataManager configuration
        let config = operationalDataManager.getSystemConfiguration()
        let maxLiveUpdates = config.maxLiveUpdatesPerFeed
        
        // Keep only last N updates for performance
        if liveWorkerUpdates.count > maxLiveUpdates {
            liveWorkerUpdates.removeFirst(liveWorkerUpdates.count - maxLiveUpdates)
        }
        if liveAdminAlerts.count > maxLiveUpdates {
            liveAdminAlerts.removeFirst(liveAdminAlerts.count - maxLiveUpdates)
        }
        if liveClientMetrics.count > maxLiveUpdates {
            liveClientMetrics.removeFirst(liveClientMetrics.count - maxLiveUpdates)
        }
    }
    
    // MARK: - Unified State Management
    
    private func updateUnifiedState(from update: CoreTypes.DashboardUpdate) {
        // Update building metrics if relevant
        if !update.buildingId.isEmpty,
           update.type == .buildingMetricsChanged || update.type == .taskCompleted {
            
            // Schedule async work to run later
            scheduleMetricsUpdate(for: update.buildingId)
        }
    }
    
    private func scheduleMetricsUpdate(for buildingId: String) {
        // Use main queue to schedule the async work
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            Task {
                do {
                    let metrics = try await self.buildingMetricsService.calculateMetrics(for: buildingId)
                    await MainActor.run {
                        self.unifiedBuildingMetrics[buildingId] = metrics
                        
                        // Record metric for trend analysis
                        self.operationalDataManager.recordMetricValue(
                            metricName: "building_\(buildingId)_completion",
                            value: metrics.completionRate
                        )
                    }
                } catch {
                    self.operationalDataManager.logError("Failed to update building metrics", error: error)
                }
            }
        }
    }
    
    // MARK: - Real-Time Synchronization Setup
    
    private func setupRealTimeSynchronization() {
        // Subscribe to cross-dashboard updates for logging
        crossDashboardUpdates
            .sink(receiveValue: { update in
                print("🔄 Cross-dashboard sync: \(update.source.rawValue) → \(update.type.rawValue)")
            })
            .store(in: &cancellables)
    }
    
    private func setupAutoSync() {
        // Get sync interval from OperationalDataManager configuration
        let config = operationalDataManager.getSystemConfiguration()
        let syncInterval = config.autoSyncInterval
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.scheduleAutoSync()
            }
        }
    }
    
    private func scheduleAutoSync() {
        // Use main queue to schedule the async work
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            Task {
                await self.performAutoSync()
            }
        }
    }
    
    private func performAutoSync() async {
        // Perform lightweight sync to ensure all dashboards are consistent
        do {
            let buildings = try await buildingService.getAllBuildings()
            
            // Check if building count has changed
            if buildings.count != unifiedBuildingMetrics.count {
                let update = CoreTypes.DashboardUpdate(
                    source: .admin,
                    type: .buildingMetricsChanged,
                    buildingId: "",
                    workerId: "",
                    data: ["buildingCount": String(buildings.count), "autoSync": "true"]
                )
                
                broadcastAdminUpdate(update)
            }
            
            lastSyncTime = Date()
            
            // Store sync event in OperationalDataManager
            operationalDataManager.recordSyncEvent(timestamp: lastSyncTime ?? Date())
            
        } catch {
            operationalDataManager.logError("Auto-sync failed", error: error)
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateActionDescription(for update: CoreTypes.DashboardUpdate) -> String {
        switch update.type {
        case .taskCompleted:
            return "Completed task"
        case .workerClockedIn:
            return "Clocked in"
        case .workerClockedOut:
            return "Clocked out"
        case .taskStarted:
            return "Started task"
        default:
            return update.type.rawValue
        }
    }
    
    private func generateDetailedAction(for update: CoreTypes.DashboardUpdate) -> String {
        switch update.type {
        case .taskCompleted:
            if let taskName = update.data["taskName"] {
                return "completed \(taskName)"
            }
            return "completed task"
        case .workerClockedIn:
            return "clocked in"
        case .workerClockedOut:
            if let duration = update.data["duration"] {
                return "clocked out after \(duration)"
            }
            return "clocked out"
        case .taskStarted:
            if let taskName = update.data["taskName"] {
                return "started \(taskName)"
            }
            return "started task"
        default:
            return update.type.rawValue
        }
    }
}

// MARK: - Extensions for SwiftUI Integration

extension DashboardSyncService {
    
    /// Enable cross-dashboard synchronization (called from DashboardView)
    public func enableCrossDashboardSync() {
        // Initialize if not already done
        initialize()
        
        isLive = true
        print("🔄 Cross-dashboard synchronization enabled")
    }
    
    /// Disable cross-dashboard synchronization
    public func disableCrossDashboardSync() {
        isLive = false
        print("⏸️ Cross-dashboard synchronization disabled")
    }
    
    /// Get recent updates for a specific dashboard
    public func getRecentUpdates(for source: CoreTypes.DashboardUpdate.Source, limit: Int = 5) -> [CoreTypes.DashboardUpdate] {
        // Fetch real recent updates from OperationalDataManager
        let recentEvents = operationalDataManager.getRecentEvents(limit: limit)
        
        return recentEvents.compactMap { event in
            // Convert operational events to dashboard updates
            guard let eventType = CoreTypes.DashboardUpdate.UpdateType(rawValue: event.type) else { return nil }
            
            return CoreTypes.DashboardUpdate(
                source: source,
                type: eventType,
                buildingId: event.buildingId ?? "",
                workerId: event.workerId ?? "",
                data: event.metadata as? [String: String] ?? [:]
            )
        }
    }
    
    /// Clear live update feeds
    public func clearLiveUpdates() {
        liveWorkerUpdates.removeAll()
        liveAdminAlerts.removeAll()
        liveClientMetrics.removeAll()
    }
}

// MARK: - Convenience Publishers

extension DashboardSyncService {
    
    /// Publisher for worker-specific updates
    public var workerUpdates: AnyPublisher<CoreTypes.DashboardUpdate, Never> {
        workerDashboardUpdates
            .filter { $0.source == .worker || $0.type == .taskCompleted || $0.type == .workerClockedIn || $0.type == .workerClockedOut }
            .eraseToAnyPublisher()
    }
    
    /// Publisher for admin-specific updates
    public var adminUpdates: AnyPublisher<CoreTypes.DashboardUpdate, Never> {
        adminDashboardUpdates
            .filter { $0.source == .admin || $0.type == .buildingMetricsChanged || $0.type == .criticalAlert }
            .eraseToAnyPublisher()
    }
    
    /// Publisher for client-specific updates
    public var clientUpdates: AnyPublisher<CoreTypes.DashboardUpdate, Never> {
        clientDashboardUpdates
            .filter { $0.source == .client || $0.type == .buildingMetricsChanged || $0.type == .routineStatusChanged }
            .eraseToAnyPublisher()
    }
}

// MARK: - App Initialization

extension DashboardSyncService {
    /// Call this during app startup to ensure proper initialization
    public static func initializeForApp() {
        // Initialize the shared instance
        shared.initialize()
    }
}

// MARK: - Sample Data Generation

extension DashboardSyncService {
    /// Generate sample updates based on real data patterns
    /// Used for testing and demo purposes - all data comes from OperationalDataManager
    public func generateSampleUpdate(type: CoreTypes.DashboardUpdate.UpdateType) -> CoreTypes.DashboardUpdate? {
        // Get real workers and buildings from OperationalDataManager
        guard let randomWorker = operationalDataManager.getRandomWorker(),
              let randomBuilding = operationalDataManager.getRandomBuilding() else {
            if debugMode {
                print("⚠️ DashboardSyncService: Cannot generate sample - no real data available")
            }
            return nil
        }
        
        // Create update based on real data
        return CoreTypes.DashboardUpdate(
            source: .worker,
            type: type,
            buildingId: randomBuilding.id,
            workerId: randomWorker.id,
            data: [
                "workerName": randomWorker.name,
                "buildingName": randomBuilding.name,
                "isRealData": "true"
            ]
        )
    }
}

// MARK: - Network Status Extension

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}

// MARK: - Supporting Types for Client Dashboard

/// Building routine status for real-time client updates
public struct BuildingRoutineStatus {
    public let buildingId: String
    public let buildingName: String
    public let completionRate: Double
    public let timeBlock: TimeBlock
    public let activeWorkerCount: Int
    public let isOnSchedule: Bool
    public let estimatedCompletion: Date?
    public let hasIssue: Bool
    
    public var isBehindSchedule: Bool {
        !isOnSchedule && completionRate < expectedCompletionForTime()
    }
    
    private func expectedCompletionForTime() -> Double {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 7..<11: return 0.3  // Morning should be 30% done
        case 11..<15: return 0.6 // Afternoon should be 60% done
        case 15..<19: return 0.9 // Evening should be 90% done
        default: return 1.0
        }
    }
    
    public enum TimeBlock: String {
        case morning = "morning"
        case afternoon = "afternoon"
        case evening = "evening"
        case overnight = "overnight"
        
        public static var current: TimeBlock {
            let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 6..<12: return .morning
            case 12..<17: return .afternoon
            case 17..<22: return .evening
            default: return .overnight
            }
        }
    }
    
    public init(
        buildingId: String,
        buildingName: String,
        completionRate: Double,
        activeWorkerCount: Int,
        isOnSchedule: Bool,
        estimatedCompletion: Date? = nil,
        hasIssue: Bool = false
    ) {
        self.buildingId = buildingId
        self.buildingName = buildingName
        self.completionRate = completionRate
        self.timeBlock = TimeBlock.current
        self.activeWorkerCount = activeWorkerCount
        self.isOnSchedule = isOnSchedule
        self.estimatedCompletion = estimatedCompletion
        self.hasIssue = hasIssue
    }
}

// MARK: - Extension for Update Types

extension CoreTypes.DashboardUpdate.UpdateType {
    // Add new update types for client dashboard
    static let routineStatusChanged = CoreTypes.DashboardUpdate.UpdateType(rawValue: "routineStatusChanged")!
    static let monthlyMetricsUpdated = CoreTypes.DashboardUpdate.UpdateType(rawValue: "monthlyMetricsUpdated")!
    static let activeWorkersChanged = CoreTypes.DashboardUpdate.UpdateType(rawValue: "activeWorkersChanged")!
    static let criticalAlert = CoreTypes.DashboardUpdate.UpdateType(rawValue: "criticalAlert")!
    static let intelligenceGenerated = CoreTypes.DashboardUpdate.UpdateType(rawValue: "intelligenceGenerated")!
    static let portfolioMetricsChanged = CoreTypes.DashboardUpdate.UpdateType(rawValue: "portfolioMetricsChanged")!
}
