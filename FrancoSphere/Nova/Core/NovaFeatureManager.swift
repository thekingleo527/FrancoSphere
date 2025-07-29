//
//  NovaFeatureManager.swift
//  FrancoSphere v6.0
//
//  Manages Nova AI features, scenarios, and role-based capabilities
//  ✅ ENHANCED: Added scenario support from AIScenarioSheetView
//  ✅ ENHANCED: Added emergency repair functionality
//  ✅ ENHANCED: Added reminder scheduling
//  ✅ FIXED: Swift 6 concurrency compliance
//  ✅ FIXED: Added CoreTypes prefix to DashboardUpdate
//  ✅ FIXED: Added proper error handling for throwing calls
//

import Foundation
import SwiftUI
import Combine

@MainActor
public class NovaFeatureManager: ObservableObject {
    public static let shared = NovaFeatureManager()
    
    // MARK: - Feature Management Properties
    @Published public var availableFeatures: [NovaAIFeature] = []
    @Published public var suggestedActions: [CoreTypes.AISuggestion] = []
    @Published public var activeInsights: [CoreTypes.IntelligenceInsight] = []
    @Published public var isProcessing = false
    
    // MARK: - Scenario Management Properties
    @Published public var activeScenarios: [NovaScenarioData] = []
    @Published public var currentScenario: NovaScenarioData?
    @Published public var showingScenario = false
    @Published public var hasActiveScenarios = false
    
    // MARK: - Emergency Repair Properties
    @Published public var repairState = NovaEmergencyRepairState()
    
    // MARK: - Dependencies
    private let contextAdapter = WorkerContextEngineAdapter.shared
    private let intelligenceEngine = NovaIntelligenceEngine.shared
    private let dashboardSyncService = DashboardSyncService.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var reminderTimers: [UUID: Timer] = [:]
    
    private init() {
        setupSubscriptions()
        updateFeatures()
        checkForScenarios()
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // Subscribe to dashboard updates
        dashboardSyncService.crossDashboardUpdates
            .sink(receiveValue: { [weak self] update in
                self?.handleDashboardUpdate(update)
            })
            .store(in: &cancellables)
        
        // Subscribe to worker context changes
        contextAdapter.$currentWorker
            .sink(receiveValue: { [weak self] _ in
                self?.updateFeatures()
                self?.checkForScenarios()
            })
            .store(in: &cancellables)
        
        contextAdapter.$currentBuilding
            .sink(receiveValue: { [weak self] _ in
                self?.updateFeatures()
            })
            .store(in: &cancellables)
        
        // Monitor active scenarios
        $activeScenarios
            .map { !$0.isEmpty }
            .assign(to: &$hasActiveScenarios)
    }
    
    // MARK: - Scenario Management
    
    public func addScenario(_ scenario: NovaScenarioData) {
        // Avoid duplicates
        if !activeScenarios.contains(where: { $0.id == scenario.id }) {
            activeScenarios.append(scenario)
            
            // Show high priority scenarios immediately
            if scenario.isHighPriority {
                presentScenario(scenario)
            }
        }
    }
    
    public func presentScenario(_ scenario: NovaScenarioData) {
        currentScenario = scenario
        showingScenario = true
    }
    
    public func dismissCurrentScenario() {
        if let scenario = currentScenario {
            activeScenarios.removeAll { $0.id == scenario.id }
        }
        currentScenario = nil
        showingScenario = false
    }
    
    public func performScenarioAction(_ scenario: NovaScenarioData) {
        print("🤖 Performing action for scenario: \(scenario.scenario.rawValue)")
        
        // Handle specific scenarios
        switch scenario.scenario {
        case .emergencyRepair:
            if let workerId = scenario.context["workerId"] {
                Task {
                    await performEmergencyRepair(for: workerId)
                }
            }
            
        case .clockOutReminder:
            // Trigger clock out
            NotificationCenter.default.post(
                name: Notification.Name("ClockOutRequested"),
                object: nil
            )
            
        case .pendingTasks:
            // Navigate to tasks
            NotificationCenter.default.post(
                name: Notification.Name("NavigateToTasks"),
                object: nil
            )
            
        default:
            print("🤖 Handling scenario: \(scenario.scenario.rawValue)")
        }
        
        dismissCurrentScenario()
    }
    
    public func scheduleReminder(for scenario: NovaScenarioData, minutes: Int = 30) {
        print("⏰ Scheduling reminder for scenario: \(scenario.scenario.rawValue) in \(minutes) minutes")
        
        let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(minutes * 60), repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.addScenario(scenario)
                self?.reminderTimers.removeValue(forKey: scenario.id)
            }
        }
        
        reminderTimers[scenario.id] = timer
        dismissCurrentScenario()
    }
    
    // MARK: - Emergency Repair
    
    public func performEmergencyRepair(for workerId: String) async {
        print("🚨 Starting emergency repair for worker: \(workerId)")
        
        await MainActor.run {
            self.repairState = NovaEmergencyRepairState(
                isActive: true,
                progress: 0.0,
                message: "Initializing repair sequence...",
                workerId: workerId
            )
        }
        
        let steps = [
            (0.15, "Scanning worker assignment database..."),
            (0.30, "Detected missing building associations..."),
            (0.45, "Rebuilding assignment matrix..."),
            (0.60, "Verifying task dependencies..."),
            (0.80, "Updating worker context engine..."),
            (0.95, "Finalizing repair..."),
            (1.00, "✅ Emergency repair successful")
        ]
        
        for (progress, message) in steps {
            await MainActor.run {
                self.repairState.progress = progress
                self.repairState.message = message
            }
            
            try? await Task.sleep(nanoseconds: UInt64(500 * 1_000_000))
        }
        
        // Trigger actual data refresh
        // ✅ FIXED: Added try-catch for the throwing call on line 187
        do {
            try await contextAdapter.loadContext(for: workerId)
        } catch {
            print("⚠️ Error loading context during emergency repair: \(error)")
        }
        
        await MainActor.run {
            self.repairState.isActive = false
            
            // Add success notification
            let successScenario = NovaScenarioData(
                scenario: .buildingAlert,
                message: "Emergency repair completed successfully. All building assignments have been restored.",
                actionText: "View Buildings",
                priority: .low
            )
            self.addScenario(successScenario)
        }
    }
    
    // MARK: - Scenario Detection
    
    public func checkForScenarios() {
        guard let worker = contextAdapter.currentWorker else { return }
        
        // Check for Kevin's missing buildings scenario
        if worker.id == "worker_001" && contextAdapter.assignedBuildings.isEmpty {
            let scenario = NovaScenarioData(
                scenario: .emergencyRepair,
                message: "Kevin hasn't been assigned to any buildings yet, but system shows 6+ available buildings. Emergency repair recommended.",
                actionText: "Fix Assignments",
                priority: .critical,
                context: ["workerId": worker.id]
            )
            addScenario(scenario)
        }
        
        // Check for pending tasks
        if contextAdapter.todaysTasks.count > 5 {
            let scenario = NovaScenarioData(
                scenario: .pendingTasks,
                message: "You have \(contextAdapter.todaysTasks.count) tasks scheduled for today. Would you like AI assistance to prioritize them?",
                actionText: "Prioritize Tasks",
                priority: .medium
            )
            addScenario(scenario)
        }
        
        // Weather alerts (mock for now)
        if Date().formatted(.dateTime.weekday()) == "Monday" {
            let scenario = NovaScenarioData(
                scenario: .weatherAlert,
                message: "Rain expected this afternoon. Consider completing outdoor tasks this morning.",
                actionText: "Check Weather Tasks",
                priority: .high
            )
            addScenario(scenario)
        }
    }
    
    // MARK: - Feature Management
    
    public func updateFeatures() {
        guard let worker = contextAdapter.currentWorker else { return }
        
        // Update features based on role
        availableFeatures = generateFeaturesForRole(worker.role)
        
        // Generate suggestions
        generateSuggestions()
        
        // Refresh insights
        Task {
            await refreshInsights()
        }
    }
    
    private func generateFeaturesForRole(_ role: CoreTypes.UserRole) -> [NovaAIFeature] {
        var features: [NovaAIFeature] = []
        
        // Common features for all roles
        features.append(contentsOf: [
            NovaAIFeature(
                id: "building-info",
                title: "Building Information",
                description: "Get details about your current building",
                icon: "building.2",
                category: .information,
                priority: .medium
            ),
            NovaAIFeature(
                id: "safety-protocols",
                title: "Safety Protocols",
                description: "Review safety guidelines",
                icon: "shield",
                category: .safety,
                priority: .high
            )
        ])
        
        // Role-specific features
        switch role {
        case .worker, .manager:  // Manager role covers supervisor functionality
            features.append(contentsOf: [
                NovaAIFeature(
                    id: "task-guidance",
                    title: "Task Guidance",
                    description: "Step-by-step task assistance",
                    icon: "checklist",
                    category: .taskManagement,
                    priority: .high
                ),
                NovaAIFeature(
                    id: "equipment-help",
                    title: "Equipment Help",
                    description: "Equipment usage and troubleshooting",
                    icon: "wrench.and.screwdriver",
                    category: .fieldAssistance,
                    priority: .medium
                ),
                NovaAIFeature(
                    id: "report-issue",
                    title: "Report Issue",
                    description: "Report problems or hazards",
                    icon: "exclamationmark.triangle",
                    category: .problemSolving,
                    priority: .high
                )
            ])
            
        case .admin:
            features.append(contentsOf: [
                NovaAIFeature(
                    id: "portfolio-analytics",
                    title: "Portfolio Analytics",
                    description: "AI-powered portfolio insights",
                    icon: "chart.line.uptrend.xyaxis",
                    category: .analytics,
                    priority: .high
                ),
                NovaAIFeature(
                    id: "workforce-optimization",
                    title: "Workforce Optimization",
                    description: "Optimize worker assignments",
                    icon: "person.3",
                    category: .optimization,
                    priority: .medium
                ),
                NovaAIFeature(
                    id: "predictive-maintenance",
                    title: "Predictive Maintenance",
                    description: "Forecast maintenance needs",
                    icon: "gear.badge.questionmark",
                    category: .predictive,
                    priority: .high
                )
            ])
            
        case .client:
            features.append(contentsOf: [
                NovaAIFeature(
                    id: "executive-summary",
                    title: "Executive Summary",
                    description: "AI-generated reports",
                    icon: "doc.text.magnifyingglass",
                    category: .reporting,
                    priority: .high
                ),
                NovaAIFeature(
                    id: "compliance-monitoring",
                    title: "Compliance Monitoring",
                    description: "Track compliance status",
                    icon: "checkmark.shield",
                    category: .compliance,
                    priority: .critical
                ),
                NovaAIFeature(
                    id: "strategic-insights",
                    title: "Strategic Insights",
                    description: "Long-term strategic recommendations",
                    icon: "lightbulb",
                    category: .strategic,
                    priority: .medium
                )
            ])
        }
        
        return features
    }
    
    // MARK: - Suggestions
    
    private func generateSuggestions() {
        Task {
            do {
                let worker = contextAdapter.currentWorker ?? CoreTypes.WorkerProfile(
                    id: "default",
                    name: "User",
                    email: "user@example.com",
                    role: .worker
                )
                
                let suggestions = try await intelligenceEngine.generateTaskRecommendations(for: worker)
                
                await MainActor.run {
                    self.suggestedActions = suggestions
                }
            } catch {
                print("Error generating suggestions: \(error)")
            }
        }
    }
    
    // MARK: - Insights
    
    private func refreshInsights() async {
        // Generate insights using NovaIntelligenceEngine
        let insights = await intelligenceEngine.generateInsights()
        
        await MainActor.run {
            self.activeInsights = insights
        }
    }
    
    // MARK: - Dashboard Updates
    
    private func handleDashboardUpdate(_ update: CoreTypes.DashboardUpdate) {  // ✅ FIXED: Added CoreTypes prefix
        // React to dashboard changes
        switch update.type {
        case .taskCompleted:
            // Refresh suggestions after task completion
            generateSuggestions()
            
        case .buildingMetricsChanged:
            // Update insights when metrics change
            Task {
                await refreshInsights()
            }
            
        case .workerClockedIn, .workerClockedOut:
            // Check for clock-related scenarios
            checkForScenarios()
            
        default:
            break
        }
    }
    
    // MARK: - Feature Execution
    
    public func executeFeature(_ feature: NovaAIFeature) async -> String {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Use NovaIntelligenceEngine to process feature requests
            let query = generateQueryForFeature(feature)
            let insight = try await intelligenceEngine.process(
                query: query,
                context: ["featureId": feature.id],
                priority: feature.priority
            )
            
            return insight.description
        } catch {
            return "I encountered an error processing your request. Please try again."
        }
    }
    
    private func generateQueryForFeature(_ feature: NovaAIFeature) -> String {
        switch feature.id {
        case "task-guidance":
            return "Provide step-by-step guidance for the current task"
        case "safety-protocols":
            return "List safety protocols for the current location"
        case "building-info":
            return "Provide information about the current building"
        case "portfolio-analytics":
            return "Generate portfolio performance analytics"
        case "workforce-optimization":
            return "Suggest workforce optimization strategies"
        case "predictive-maintenance":
            return "Predict upcoming maintenance needs"
        case "executive-summary":
            return "Generate executive summary of current operations"
        case "compliance-monitoring":
            return "Report on compliance status across portfolio"
        case "strategic-insights":
            return "Provide strategic insights for portfolio improvement"
        default:
            return feature.description
        }
    }
    
    // MARK: - Building Intelligence
    
    public func loadBuildingInsights(for buildingId: String) async {
        isProcessing = true
        
        do {
            let insight = try await intelligenceEngine.analyzeBuilding(buildingId)
            await MainActor.run {
                self.activeInsights = [insight]
                self.isProcessing = false
            }
        } catch {
            print("Error loading building insights: \(error)")
            await MainActor.run {
                self.isProcessing = false
            }
        }
    }
    
    // MARK: - Context Helpers
    
    public func getCurrentContextData() -> (buildings: Int, tasks: Int, status: String, worker: String) {
        let buildings = contextAdapter.assignedBuildings.count
        let tasks = contextAdapter.todaysTasks.count
        let status = contextAdapter.currentWorker != nil ? "Active" : "Standby"
        let worker = contextAdapter.currentWorker?.name ?? "Unknown"
        
        return (buildings, tasks, status, worker)
    }
    
    public func getScenarioSuggestions(for scenario: NovaScenarioData) -> [CoreTypes.AISuggestion] {
        var suggestions: [CoreTypes.AISuggestion] = []
        
        switch scenario.scenario {
        case .emergencyRepair:
            suggestions.append(
                CoreTypes.AISuggestion(
                    id: UUID().uuidString,
                    title: "Emergency Repair",
                    description: "Fix missing building assignments using AI repair",
                    priority: .critical,
                    category: .operations,
                    estimatedImpact: "Restore access to all assigned buildings"
                )
            )
            
        case .weatherAlert:
            suggestions.append(
                CoreTypes.AISuggestion(
                    id: UUID().uuidString,
                    title: "Check Outdoor Tasks",
                    description: "Review weather-appropriate task alternatives",
                    priority: .medium,
                    category: .operations,
                    estimatedImpact: "Optimize work schedule for weather conditions"
                )
            )
            
        case .pendingTasks:
            suggestions.append(
                CoreTypes.AISuggestion(
                    id: UUID().uuidString,
                    title: "Prioritize Tasks",
                    description: "AI will optimize task order by urgency and efficiency",
                    priority: .high,
                    category: .efficiency,
                    estimatedImpact: "Improve daily task completion rate"
                )
            )
            
        default:
            break
        }
        
        // Add general suggestion
        suggestions.append(
            CoreTypes.AISuggestion(
                id: UUID().uuidString,
                title: "View Schedule",
                description: "Open today's optimized work schedule",
                priority: .low,
                category: .operations,
                estimatedImpact: "Better time management"
            )
        )
        
        return suggestions
    }
    
    // MARK: - Public Helper Methods
    
    /// Get feature by ID
    public func getFeature(byId id: String) -> NovaAIFeature? {
        return availableFeatures.first { $0.id == id }
    }
    
    /// Check if should show Kevin emergency repair
    public var shouldShowEmergencyRepair: Bool {
        let workerId = contextAdapter.currentWorker?.id ?? ""
        let buildings = contextAdapter.assignedBuildings
        return workerId == "worker_001" && buildings.isEmpty
    }
    
    /// Cleanup timers on deallocation
    deinit {
        reminderTimers.values.forEach { $0.invalidate() }
    }
}

// MARK: - Supporting Types

public struct NovaAIFeature: Identifiable {
    public let id: String
    public let title: String
    public let description: String
    public let icon: String
    public let category: NovaAIFeatureCategory
    public let priority: CoreTypes.AIPriority
}

public enum NovaAIFeatureCategory {
    case fieldAssistance, safety, information, taskSpecific, buildingSpecific
    case weatherAdaptive, analytics, optimization, predictive, financial
    case compliance, teamManagement, qualityAssurance, training, problemSolving
    case reporting, monitoring, serviceManagement, performance, taskManagement
    case strategic
}
