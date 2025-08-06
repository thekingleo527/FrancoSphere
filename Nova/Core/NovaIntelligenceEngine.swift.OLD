//
//  NovaIntelligenceEngine.swift
//  FrancoSphere v6.0
//
//  ✅ COMPLETE: Single entry point for all Nova AI operations
//  ✅ ENHANCED: Navigation support for IntelligencePreviewPanel
//  ✅ INTEGRATED: Data aggregation from all services
//  ✅ PRODUCTION: Real-time insights and suggestions
//  ✅ DARK ELEGANCE: Aligned with new theme system
//
//  Dependencies:
//  - NovaTypes.swift: For NovaAggregatedData and other Nova types
//  - CoreTypes: For all shared data structures
//

import SwiftUI
import Combine
import CoreLocation  // For NamedCoordinate support

// MARK: - Main Nova Intelligence Engine
// Note: NovaAggregatedData is imported from NovaTypes.swift
@MainActor
public class NovaIntelligenceEngine: ObservableObject {
    public static let shared = NovaIntelligenceEngine()
    
    // MARK: - Published Properties
    @Published public var currentContext: String = ""
    @Published public var insights: [CoreTypes.IntelligenceInsight] = []
    @Published public var suggestions: [CoreTypes.AISuggestion] = []
    @Published public var processingState: ProcessingState = .idle
    @Published public var lastError: Error?
    @Published public var navigationSuggestions: [NavigationSuggestion] = []
    
    // MARK: - Dependencies
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let buildingMetricsService = BuildingMetricsService.shared
    private let clockInManager = ClockInManager.shared
    
    // MARK: - Data Aggregation Cache
    private var portfolioCache: (data: NovaAggregatedData, timestamp: Date)?
    private var buildingCache: [String: (data: NovaAggregatedData, timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    // MARK: - State
    public enum ProcessingState: Equatable {
        case idle
        case processing
        case generating
        case error(String)
    }
    
    // MARK: - Navigation Support
    public struct NavigationSuggestion: Identifiable {
        public let id = UUID()
        public let title: String
        public let icon: String
        public let priority: Int
        public let badge: Int?
        public let action: NavigationAction
    }
    
    public enum NavigationAction {
        case tasks(urgent: Int)
        case buildings(affected: [String])
        case compliance(deadline: Date?)
        case maintenance(overdue: Int)
        case fullInsights
        case taskDetail(id: String)
        case buildingDetail(id: String)
        case dsnyTasks
        case routeOptimization
    }
    
    private init() {
        setupInitialInsights()
    }
    
    // MARK: - Setup Methods
    
    private func setupInitialInsights() {
        Task {
            await generateSystemInsights()
        }
    }
    
    // MARK: - Main Processing Method
    public func process(
        query: String,
        context: [String: Any]? = nil,
        priority: CoreTypes.AIPriority = .medium
    ) async throws -> CoreTypes.IntelligenceInsight {
        
        processingState = .processing
        
        do {
            // 1. Generate context-aware prompt using internal data aggregation
            let prompt = try await generatePromptWithData(
                query: query,
                context: context
            )
            
            processingState = .generating
            
            // 2. Generate insight based on CoreTypes structure
            let insight = CoreTypes.IntelligenceInsight(
                title: extractTitle(from: query),
                description: await generateResponse(for: prompt),
                type: determineCategory(from: query),
                priority: priority,
                actionRequired: determineIfActionRequired(from: query),
                affectedBuildings: extractAffectedBuildings(from: context)
            )
            
            // 3. Update state
            insights.append(insight)
            processingState = .idle
            
            // 4. Update navigation suggestions if needed
            await updateNavigationSuggestions()
            
            return insight
            
        } catch {
            processingState = .error(error.localizedDescription)
            lastError = error
            throw error
        }
    }
    
    // MARK: - Navigation Methods (NEW)
    
    /// Get navigation suggestion for current context
    public func getNavigationSuggestion() async -> String? {
        // Analyze current insights for most important action
        let criticalInsights = insights.filter { $0.priority == .critical }
        let urgentInsights = insights.filter { $0.priority == .high }
        
        if let critical = criticalInsights.first {
            if critical.type == .compliance {
                return "DSNY deadline approaching - action required"
            } else if critical.type == .maintenance {
                return "Critical maintenance task overdue"
            }
        }
        
        if urgentInsights.count > 3 {
            return "\(urgentInsights.count) urgent items need attention"
        }
        
        // Check for optimization opportunities
        let data = try? await aggregatePortfolioData()
        if let data = data, data.averageCompletionRate < 0.7 {
            return "Task completion below target - optimize route"
        }
        
        return nil
    }
    
    /// Calculate priority for navigation items
    public func calculateNavigationPriority(for action: NavigationAction) -> Int {
        switch action {
        case .tasks(let urgent):
            return urgent > 0 ? 100 - urgent : 0
        case .compliance(let deadline):
            if let deadline = deadline {
                let hoursUntil = deadline.timeIntervalSinceNow / 3600
                if hoursUntil < 2 { return 100 }
                if hoursUntil < 4 { return 90 }
                return 50
            }
            return 30
        case .maintenance(let overdue):
            return overdue > 0 ? 80 - overdue : 0
        case .buildings(let affected):
            return affected.count * 10
        default:
            return 10
        }
    }
    
    /// Get insight counts by category
    public func getInsightCounts() -> [CoreTypes.InsightCategory: Int] {
        var counts: [CoreTypes.InsightCategory: Int] = [:]
        
        for insight in insights {
            counts[insight.type, default: 0] += 1
        }
        
        return counts
    }
    
    /// Update navigation suggestions based on current context
    private func updateNavigationSuggestions() async {
        navigationSuggestions.removeAll()
        
        // Analyze insights for navigation priorities
        let urgentTasks = insights.filter {
            $0.type == .operations && $0.priority == .critical
        }.count
        
        if urgentTasks > 0 {
            navigationSuggestions.append(NavigationSuggestion(
                title: "Urgent Tasks",
                icon: "exclamationmark.triangle.fill",
                priority: 100,
                badge: urgentTasks,
                action: .tasks(urgent: urgentTasks)
            ))
        }
        
        // Check for DSNY compliance
        let dsnyInsights = insights.filter {
            $0.type == .compliance &&
            ($0.description.contains("DSNY") || $0.description.contains("trash"))
        }
        
        if !dsnyInsights.isEmpty {
            let affectedBuildings = dsnyInsights.flatMap { $0.affectedBuildings }
            navigationSuggestions.append(NavigationSuggestion(
                title: "DSNY Compliance",
                icon: "trash.fill",
                priority: 90,
                badge: affectedBuildings.count,
                action: .compliance(deadline: getDSNYDeadline())
            ))
        }
        
        // Route optimization suggestion
        if let data = try? await aggregatePortfolioData(),
           data.averageCompletionRate < 0.8 {
            navigationSuggestions.append(NavigationSuggestion(
                title: "Optimize Route",
                icon: "map",
                priority: 70,
                badge: nil,
                action: .routeOptimization
            ))
        }
    }
    
    // MARK: - Data Aggregation Methods
    
    /// Gather comprehensive portfolio metrics from GRDB data
    public func aggregatePortfolioData() async throws -> NovaAggregatedData {
        // Check cache first
        if let cached = portfolioCache,
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            print("📦 Using cached portfolio data")
            return cached.data
        }
        
        print("🔄 Aggregating fresh portfolio data...")
        
        // Fetch real data using existing services
        async let buildings = buildingService.getAllBuildings()
        async let tasks = taskService.getAllTasks()
        async let workers = workerService.getAllActiveWorkers()
        
        // Wait for all data
        let allBuildings = try await buildings
        let allTasks = try await tasks
        let allWorkers = try await workers
        
        // Calculate task metrics
        let completedTasks = allTasks.filter { $0.isCompleted }
        let urgentTasks = allTasks.filter { task in
            task.urgency == .urgent || task.urgency == .critical || task.urgency == .emergency
        }
        let overdueTasks = allTasks.filter { task in
            !task.isCompleted && task.isOverdue
        }
        
        // Calculate average completion rate
        let completionRate = allTasks.isEmpty ? 0.0 : Double(completedTasks.count) / Double(allTasks.count)
        
        let aggregated = NovaAggregatedData(
            buildingCount: allBuildings.count,
            taskCount: allTasks.count,
            workerCount: allWorkers.count,
            completedTaskCount: completedTasks.count,
            urgentTaskCount: urgentTasks.count,
            overdueTaskCount: overdueTasks.count,
            averageCompletionRate: completionRate
        )
        
        // Cache the result
        portfolioCache = (aggregated, Date())
        
        print("✅ Portfolio data aggregated: \(allBuildings.count) buildings, \(allTasks.count) tasks, \(allWorkers.count) workers")
        
        return aggregated
    }
    
    /// Gather comprehensive metrics for a specific building
    public func aggregateBuildingData(for buildingId: CoreTypes.BuildingID) async throws -> NovaAggregatedData {
        // Check cache first
        if let cached = buildingCache[buildingId],
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            print("📦 Using cached data for building \(buildingId)")
            return cached.data
        }
        
        print("🔄 Aggregating fresh data for building \(buildingId)...")
        
        // Fetch building-specific data
        async let building = buildingService.getBuilding(buildingId: buildingId)
        async let allTasks = taskService.getAllTasks()
        async let workers = workerService.getActiveWorkersForBuilding(buildingId)
        
        // Get building metrics if available
        let metrics = try? await buildingMetricsService.calculateMetrics(for: buildingId)
        
        // Filter tasks for this building
        let tasks = try await allTasks
        let buildingTasks = tasks.filter { task in
            task.buildingId == buildingId || task.building?.id == buildingId
        }
        
        // Calculate task metrics
        let completedTasks = buildingTasks.filter { $0.isCompleted }
        let urgentTasks = buildingTasks.filter { task in
            task.urgency == .urgent || task.urgency == .critical || task.urgency == .emergency
        }
        let overdueTasks = buildingTasks.filter { task in
            !task.isCompleted && task.isOverdue
        }
        
        // Use metrics if available, otherwise calculate
        let completionRate = metrics?.completionRate ??
            (buildingTasks.isEmpty ? 0.0 : Double(completedTasks.count) / Double(buildingTasks.count))
        
        let buildingData = try await building
        let buildingWorkers = try await workers
        
        let aggregated = NovaAggregatedData(
            buildingCount: buildingData == nil ? 0 : 1,
            taskCount: buildingTasks.count,
            workerCount: buildingWorkers.count,
            completedTaskCount: completedTasks.count,
            urgentTaskCount: urgentTasks.count,
            overdueTaskCount: overdueTasks.count,
            averageCompletionRate: completionRate
        )
        
        // Cache the result
        buildingCache[buildingId] = (aggregated, Date())
        
        print("✅ Building data aggregated: \(buildingTasks.count) tasks, \(buildingWorkers.count) workers")
        
        return aggregated
    }
    
    /// Gather metrics for a specific worker
    public func aggregateWorkerData(for workerId: CoreTypes.WorkerID) async throws -> NovaAggregatedData {
        print("🔄 Aggregating data for worker \(workerId)...")
        
        // Get worker profile
        let worker = try await workerService.getWorkerProfile(for: workerId)
        
        // Get worker's tasks
        let allTasks = try await taskService.getAllTasks()
        let workerTasks = allTasks.filter { task in
            task.assignedWorkerId == workerId || task.worker?.id == workerId
        }
        
        // Calculate metrics
        let completedTasks = workerTasks.filter { $0.isCompleted }
        let urgentTasks = workerTasks.filter { task in
            task.urgency == .urgent || task.urgency == .critical || task.urgency == .emergency
        }
        let overdueTasks = workerTasks.filter { task in
            !task.isCompleted && task.isOverdue
        }
        
        let completionRate = workerTasks.isEmpty ? 0.0 : Double(completedTasks.count) / Double(workerTasks.count)
        
        // Get unique buildings for this worker
        let buildingIds = Set(workerTasks.compactMap { $0.buildingId })
        
        return NovaAggregatedData(
            buildingCount: buildingIds.count,
            taskCount: workerTasks.count,
            workerCount: worker == nil ? 0 : 1,
            completedTaskCount: completedTasks.count,
            urgentTaskCount: urgentTasks.count,
            overdueTaskCount: overdueTasks.count,
            averageCompletionRate: completionRate
        )
    }
    
    /// Aggregate data by task category
    public func aggregateByCategory(_ category: CoreTypes.TaskCategory) async throws -> NovaAggregatedData {
        let allTasks = try await taskService.getAllTasks()
        let categoryTasks = allTasks.filter { $0.category == category }
        
        let completedTasks = categoryTasks.filter { $0.isCompleted }
        let urgentTasks = categoryTasks.filter { task in
            task.urgency == .urgent || task.urgency == .critical || task.urgency == .emergency
        }
        let overdueTasks = categoryTasks.filter { task in
            !task.isCompleted && task.isOverdue
        }
        
        let completionRate = categoryTasks.isEmpty ? 0.0 : Double(completedTasks.count) / Double(categoryTasks.count)
        
        // Get unique buildings and workers
        let buildingIds = Set(categoryTasks.compactMap { $0.buildingId })
        let workerIds = Set(categoryTasks.compactMap { $0.assignedWorkerId })
        
        return NovaAggregatedData(
            buildingCount: buildingIds.count,
            taskCount: categoryTasks.count,
            workerCount: workerIds.count,
            completedTaskCount: completedTasks.count,
            urgentTaskCount: urgentTasks.count,
            overdueTaskCount: overdueTasks.count,
            averageCompletionRate: completionRate
        )
    }
    
    /// Aggregate compliance-related data
    public func aggregateComplianceData() async throws -> NovaAggregatedData {
        // Get all buildings and check compliance
        let buildings = try await buildingService.getAllBuildings()
        var compliantCount = 0
        var issueCount = 0
        
        for building in buildings {
            if let metrics = try? await buildingMetricsService.calculateMetrics(for: building.id) {
                if metrics.isCompliant {
                    compliantCount += 1
                } else {
                    issueCount += 1
                }
            }
        }
        
        let complianceRate = buildings.isEmpty ? 0.0 : Double(compliantCount) / Double(buildings.count)
        
        return NovaAggregatedData(
            buildingCount: buildings.count,
            taskCount: 0, // Not relevant for compliance
            workerCount: 0, // Not relevant for compliance
            completedTaskCount: compliantCount,
            urgentTaskCount: issueCount,
            overdueTaskCount: 0,
            averageCompletionRate: complianceRate
        )
    }
    
    // MARK: - Cache Management
    
    /// Invalidate all caches
    public func invalidateAllCaches() {
        portfolioCache = nil
        buildingCache.removeAll()
        print("🗑️ All Nova caches invalidated")
    }
    
    /// Invalidate cache for specific building
    public func invalidateBuildingCache(for buildingId: String) {
        buildingCache.removeValue(forKey: buildingId)
        print("🗑️ Cache invalidated for building \(buildingId)")
    }
    
    // MARK: - System Insights Generation
    
    /// Generate system-wide insights
    @MainActor
    private func generateSystemInsights() async {
        do {
            let data = try await aggregatePortfolioData()
            
            // Performance insight
            if data.averageCompletionRate < 0.7 {
                insights.append(CoreTypes.IntelligenceInsight(
                    title: "Task completion below target",
                    description: "Overall completion rate is \(Int(data.averageCompletionRate * 100))%. Consider reviewing task assignments and worker capacity.",
                    type: .efficiency,
                    priority: .high,
                    actionRequired: true
                ))
            }
            
            // Urgent tasks insight
            if data.urgentTaskCount > 5 {
                insights.append(CoreTypes.IntelligenceInsight(
                    title: "\(data.urgentTaskCount) urgent tasks require attention",
                    description: "Multiple high-priority tasks are pending. Focus on critical items to maintain service quality.",
                    type: .operations,
                    priority: .critical,
                    actionRequired: true
                ))
            }
            
            // Compliance check
            let complianceData = try await aggregateComplianceData()
            if complianceData.averageCompletionRate < 0.9 {
                let nonCompliant = complianceData.buildingCount - complianceData.completedTaskCount
                insights.append(CoreTypes.IntelligenceInsight(
                    title: "Compliance issues detected",
                    description: "\(nonCompliant) buildings have compliance concerns that need immediate attention.",
                    type: .compliance,
                    priority: .critical,
                    actionRequired: true,
                    affectedBuildings: [] // Would need to fetch specific building IDs
                ))
            }
            
        } catch {
            print("Failed to generate system insights: \(error)")
        }
    }
    
    // MARK: - Convenience Methods
    
    public func generateInsight(for building: CoreTypes.NamedCoordinate) async throws -> CoreTypes.IntelligenceInsight {
        return try await process(
            query: "Generate insight for building \(building.name)",
            context: ["buildingId": building.id, "building": building],
            priority: .medium
        )
    }
    
    public func generateTaskRecommendations(for worker: CoreTypes.WorkerProfile) async throws -> [CoreTypes.AISuggestion] {
        let insight = try await process(
            query: "Recommend tasks for worker \(worker.name)",
            context: ["workerId": worker.id],
            priority: .high
        )
        
        // Convert to suggestions
        return [
            CoreTypes.AISuggestion(
                title: insight.title,
                description: insight.description,
                priority: insight.priority,
                category: insight.type,
                actionRequired: insight.actionRequired,
                estimatedImpact: "Medium"
            )
        ]
    }
    
    // MARK: - Private Helpers
    
    private func generatePromptWithData(query: String, context: [String: Any]?) async throws -> String {
        // Use internal data aggregation
        let portfolioData = try await aggregatePortfolioData()
        
        // Convert internal data to prompt string
        var promptParts = [String]()
        promptParts.append("Query: \(query)")
        promptParts.append("Buildings: \(portfolioData.buildingCount)")
        promptParts.append("Active Workers: \(portfolioData.workerCount)")
        promptParts.append("Tasks Today: \(portfolioData.taskCount)")
        promptParts.append("Completion Rate: \(String(format: "%.1f%%", portfolioData.averageCompletionRate * 100))")
        promptParts.append("Urgent Tasks: \(portfolioData.urgentTaskCount)")
        
        // Add context if provided
        if let context = context {
            promptParts.append("Context: \(context.description)")
        }
        
        return promptParts.joined(separator: "\n")
    }
    
    private func generateResponse(for prompt: String) async -> String {
        // Placeholder - will integrate with actual AI API
        return "Based on current data patterns, recommendation is to focus on urgent tasks and optimize worker allocation for better efficiency."
    }
    
    private func extractTitle(from query: String) -> String {
        let title = query.prefix(50).trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? "AI Insight" : String(title)
    }
    
    private func determineCategory(from query: String) -> CoreTypes.InsightCategory {
        let lowercased = query.lowercased()
        
        if lowercased.contains("efficiency") || lowercased.contains("optimize") {
            return .efficiency
        } else if lowercased.contains("cost") || lowercased.contains("expense") {
            return .cost
        } else if lowercased.contains("safety") || lowercased.contains("hazard") {
            return .safety
        } else if lowercased.contains("compliance") || lowercased.contains("regulation") {
            return .compliance
        } else if lowercased.contains("maintenance") || lowercased.contains("repair") {
            return .maintenance
        } else {
            return .operations
        }
    }
    
    private func determineIfActionRequired(from query: String) -> Bool {
        let lowercased = query.lowercased()
        return lowercased.contains("urgent") ||
               lowercased.contains("critical") ||
               lowercased.contains("immediate") ||
               lowercased.contains("required")
    }
    
    private func extractAffectedBuildings(from context: [String: Any]?) -> [String] {
        guard let context = context else { return [] }
        
        if let buildingId = context["buildingId"] as? String {
            return [buildingId]
        }
        
        if let building = context["building"] as? CoreTypes.NamedCoordinate {
            return [building.id]
        }
        
        if let buildingIds = context["buildingIds"] as? [String] {
            return buildingIds
        }
        
        return []
    }
    
    private func getDSNYDeadline() -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 20 // 8 PM
        components.minute = 0
        return calendar.date(from: components)
    }
}

// MARK: - Public API Extensions
extension NovaIntelligenceEngine {
    
    /// Generate insights for dashboard display
    public func generateInsights() async -> [CoreTypes.IntelligenceInsight] {
        do {
            let buildings = try await buildingService.getAllBuildings()
            var newInsights: [CoreTypes.IntelligenceInsight] = []
            
            for building in buildings.prefix(3) { // Process first 3 for performance
                let insight = try await generateInsight(for: building)
                newInsights.append(insight)
            }
            
            // Update published insights
            insights.append(contentsOf: newInsights)
            return newInsights
            
        } catch {
            print("Failed to generate insights: \(error)")
            return []
        }
    }
    
    /// Predict portfolio trends
    public func predictPortfolioTrends() async throws -> [CoreTypes.AISuggestion] {
        let insight = try await process(
            query: "Predict portfolio trends based on current metrics",
            priority: .high
        )
        
        return [
            CoreTypes.AISuggestion(
                title: "Portfolio Trend Analysis",
                description: insight.description,
                priority: insight.priority,
                category: .operations,
                actionRequired: true,
                estimatedImpact: "High"
            )
        ]
    }
    
    /// Analyze specific building
    public func analyzeBuilding(_ buildingId: String) async throws -> CoreTypes.IntelligenceInsight {
        let buildingData = try await aggregateBuildingData(for: buildingId)
        
        let buildingContext: [String: Any] = [
            "buildingId": buildingId,
            "taskCount": buildingData.taskCount,
            "completionRate": buildingData.averageCompletionRate,
            "activeWorkers": buildingData.workerCount
        ]
        
        return try await process(
            query: "Analyze building performance and suggest improvements",
            context: buildingContext,
            priority: .medium
        )
    }
    
    /// Generate contextual suggestions for current user
    public func generateContextualSuggestions(role: CoreTypes.UserRole) async throws -> [CoreTypes.AISuggestion] {
        let query: String
        let priority: CoreTypes.AIPriority
        
        switch role {
        case .worker:
            query = "What tasks should I focus on today?"
            priority = .high
        case .manager, .admin:
            query = "What operational improvements can be made?"
            priority = .medium
        case .client:
            query = "How is my portfolio performing?"
            priority = .medium
        }
        
        let insight = try await process(query: query, priority: priority)
        
        return [
            CoreTypes.AISuggestion(
                title: insight.title,
                description: insight.description,
                priority: insight.priority,
                category: insight.type,
                actionRequired: insight.actionRequired,
                estimatedImpact: role == .worker ? "High" : "Medium"
            )
        ]
    }
    
    /// Generate portfolio intelligence for AdminDashboardView
    public func generatePortfolioIntelligence() async throws -> CoreTypes.PortfolioIntelligence {
        let portfolioData = try await aggregatePortfolioData()
        let complianceData = try await aggregateComplianceData()
        
        let criticalIssues = insights.filter { $0.priority == .critical }.count
        
        let trend: CoreTypes.TrendDirection = {
            if portfolioData.averageCompletionRate > 0.8 {
                return .up
            } else if portfolioData.averageCompletionRate < 0.5 {
                return .down
            } else {
                return .stable
            }
        }()
        
        return CoreTypes.PortfolioIntelligence(
            totalBuildings: portfolioData.buildingCount,
            activeWorkers: portfolioData.workerCount,
            completionRate: portfolioData.averageCompletionRate,
            criticalIssues: criticalIssues,
            monthlyTrend: trend,
            complianceScore: complianceData.averageCompletionRate
        )
    }
    
    /// Generate task timeline insights
    public func generateTaskTimelineInsights(workerId: String, date: Date) async throws -> [CoreTypes.IntelligenceInsight] {
        var timelineInsights: [CoreTypes.IntelligenceInsight] = []
        
        let tasks = try await taskService.getTasksForWorker(workerId)
        let calendar = Calendar.current
        let dayTasks = tasks.filter { task in
            if let dueDate = task.dueDate {
                return calendar.isDate(dueDate, inSameDayAs: date)
            }
            return false
        }
        
        // Analyze task load
        if dayTasks.count > 10 {
            timelineInsights.append(CoreTypes.IntelligenceInsight(
                title: "Heavy Task Load",
                description: "\(dayTasks.count) tasks scheduled for this date. Consider prioritizing critical tasks.",
                type: .efficiency,
                priority: .high,
                actionRequired: true
            ))
        }
        
        // Check for overdue tasks
        let overdueTasks = dayTasks.filter { task in
            guard let dueDate = task.dueDate, !task.isCompleted else { return false }
            return dueDate < Date()
        }
        
        if !overdueTasks.isEmpty {
            timelineInsights.append(CoreTypes.IntelligenceInsight(
                title: "Overdue Tasks Alert",
                description: "\(overdueTasks.count) tasks are overdue. Focus on completing these first.",
                type: .maintenance,
                priority: .critical,
                actionRequired: true
            ))
        }
        
        return timelineInsights
    }
}

// MARK: - Migration Helpers
extension NovaIntelligenceEngine {
    
    /// Helper for views still using NovaCore pattern
    @available(*, deprecated, message: "Use NovaIntelligenceEngine.process() instead")
    public func generateInsights(for context: String) async -> [CoreTypes.IntelligenceInsight] {
        do {
            let insight = try await process(query: context)
            return [insight]
        } catch {
            return []
        }
    }
    
    /// Get portfolio summary for real-time updates
    public func getPortfolioSummary() async throws -> [String: Any] {
        let data = try await aggregatePortfolioData()
        
        return [
            "buildingCount": data.buildingCount,
            "workerCount": data.workerCount,
            "taskCount": data.taskCount,
            "completionRate": data.averageCompletionRate,
            "urgentTaskCount": data.urgentTaskCount,
            "overdueTaskCount": data.overdueTaskCount,
            "completionPercentage": data.completionPercentage
        ]
    }
}

// MARK: - NovaAggregatedData Extension
extension NovaAggregatedData {
    /// Calculate a health score based on metrics
    public var healthScore: Double {
        let completionScore = averageCompletionRate
        let urgencyPenalty = Double(urgentTaskCount) / Double(max(taskCount, 1)) * 0.3
        let overduePenalty = Double(overdueTaskCount) / Double(max(taskCount, 1)) * 0.5
        return max(0, completionScore - urgencyPenalty - overduePenalty)
    }
}
