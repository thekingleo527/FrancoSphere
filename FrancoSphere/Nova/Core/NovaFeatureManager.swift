//
//  NovaFeatureManager.swift
//  FrancoSphere v6.0
//
//  REFACTORED: Final version aligned with the production architecture.
//  ✅ FIXED: All remaining compilation errors and ambiguities resolved.
//  ✅ LEAN: All duplicated logic removed. Now acts as a true ViewModel/Coordinator.
//  ✅ DELEGATED: Correctly calls singleton services (NovaIntelligenceEngine, WorkerService, etc.) for all data and AI processing.
//  ✅ CAPABILITY-AWARE: Implements the WorkerCapabilities system for adaptive UI.
//

import Foundation
import SwiftUI
import Combine

@MainActor
public class NovaFeatureManager: ObservableObject {
    public static let shared = NovaFeatureManager()
    
    // MARK: - Published UI State
    @Published public var availableFeatures: [NovaAIFeature] = []
    @Published public var suggestedActions: [CoreTypes.AISuggestion] = []
    @Published public var activeInsights: [CoreTypes.IntelligenceInsight] = []
    @Published public var isProcessing = false
    @Published public var errorMessage: String?
    
    // MARK: - Context & Scenario Management
    @Published public var currentContext: NovaContext? // Uses the canonical NovaContext from NovaTypes.swift
    @Published public var timeOfDay: TimeOfDay = .morning
    @Published public var activeScenarios: [CoreTypes.AIScenario] = []
    @Published public var currentScenario: CoreTypes.AIScenario?
    @Published public var showingScenario = false
    @Published public var hasActiveScenarios = false
    
    // MARK: - Emergency Repair State
    @Published public var repairState = NovaEmergencyRepairState()
    
    // MARK: - Dependencies
    private let contextAdapter = WorkerContextEngineAdapter.shared
    private let intelligenceEngine = NovaIntelligenceEngine.shared
    private let dashboardSyncService = DashboardSyncService.shared
    private let workerService = WorkerService.shared
    private let intelligenceService = IntelligenceService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupSubscriptions()
        updateTimeOfDay()
        
        // Initial data load on startup
        Task {
            await updateContext()
            await updateFeatures()
            await checkForScenarios()
        }
    }
    
    // MARK: - Setup & Subscriptions
    
    private func setupSubscriptions() {
        // Subscribe to dashboard updates for real-time reactivity
        dashboardSyncService.crossDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleDashboardUpdate(update)
            }
            .store(in: &cancellables)
        
        // Subscribe to worker context changes
        contextAdapter.$currentWorker
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.updateContext()
                    await self?.updateFeatures()
                    await self?.checkForScenarios()
                }
            }
            .store(in: &cancellables)
        
        // Monitor active scenarios to update UI badges
        $activeScenarios
            .map { !$0.isEmpty }
            .assign(to: &$hasActiveScenarios)
        
        // Update time of day periodically
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimeOfDay()
            }
            .store(in: &cancellables)
    }
    
    private func handleDashboardUpdate(_ update: CoreTypes.DashboardUpdate) {
        Task {
            switch update.type {
            case .taskCompleted, .taskStarted, .workerClockedIn, .workerClockedOut:
                await updateContext()
                await checkForScenarios()
            case .buildingMetricsChanged:
                await refreshInsights()
            default:
                break
            }
        }
    }
    
    // MARK: - Context Management
    
    private func updateContext() async {
        guard let worker = contextAdapter.currentWorker else {
            currentContext = nil
            return
        }
        
        updateTimeOfDay()
        
        let urgentTasks = getUrgentTasks()
        let activeTask = getCurrentActiveTask()
        
        // Use the canonical NovaContext initializer from NovaTypes.swift
        currentContext = NovaContext(
            data: [
                "userRole": worker.role.rawValue,
                "workerId": worker.id,
                "workerName": worker.name,
                "currentBuilding": contextAdapter.currentBuilding?.id ?? "",
                "buildingName": contextAdapter.currentBuilding?.name ?? "",
                "assignedBuildingsCount": String(contextAdapter.assignedBuildings.count),
                "todaysTasksCount": String(contextAdapter.todaysTasks.count),
                "completedTasksCount": String(contextAdapter.todaysTasks.filter { $0.isCompleted }.count),
                "urgentTasksCount": String(urgentTasks.count),
                "timeOfDay": timeOfDay.rawValue
            ],
            insights: activeInsights.map { $0.description },
            metadata: ["version": "2.0"],
            userRole: worker.role,
            buildingContext: contextAdapter.currentBuilding?.id,
            taskContext: activeTask?.id
        )
    }
    
    private func updateTimeOfDay() {
        let hour = Calendar.current.component(.hour, from: Date())
        timeOfDay = switch hour {
        case 6..<12: .morning
        case 12..<17: .afternoon
        case 17..<20: .evening
        default: .night
        }
    }
    
    // MARK: - Feature Management (Capability-Aware)
    
    public func updateFeatures() async {
        guard let worker = contextAdapter.currentWorker else {
            availableFeatures = []
            return
        }
        
        do {
            // Use the real WorkerService to fetch capabilities
            let capabilities = try await workerService.getWorkerCapabilityRecord(worker.id)
            availableFeatures = generateFeaturesForRole(worker.role, capabilities: capabilities)
        } catch {
            // Fallback to default capabilities if the service fails
            print("⚠️ Could not fetch worker capabilities, using defaults. Error: \(error)")
            let defaultCapabilities = WorkerCapabilityRecord.default(for: worker.id)
            availableFeatures = generateFeaturesForRole(worker.role, capabilities: defaultCapabilities)
        }
        
        await generateSuggestions()
        await refreshInsights()
    }
    
    private func generateFeaturesForRole(_ role: CoreTypes.UserRole, capabilities: WorkerCapabilityRecord) -> [NovaAIFeature] {
        var features: [NovaAIFeature] = []
        
        features.append(NovaAIFeature(id: "building-info", title: "Building Information", description: "Get details about your current building", icon: "building.2", category: .information, priority: .medium))
        features.append(NovaAIFeature(id: "safety-protocols", title: "Safety Protocols", description: "Review safety guidelines", icon: "shield", category: .safety, priority: .high))

        if role == .worker || role == .manager {
            features.append(NovaAIFeature(id: "task-guidance", title: "Task Guidance", description: "Step-by-step task assistance", icon: "checklist", category: .taskManagement, priority: .high))
            
            if capabilities.canUploadPhotos {
                features.append(NovaAIFeature(id: "photo-assistant", title: "Photo Assistant", description: "Tips for quality evidence photos", icon: "camera.on.rectangle", category: .fieldAssistance, priority: .medium))
            }
            if capabilities.canAddEmergencyTasks {
                features.append(NovaAIFeature(id: "report-issue", title: "Report Issue", description: "Report problems or hazards", icon: "exclamationmark.triangle", category: .problemSolving, priority: .high))
            }
        }
        
        return features
    }
    
    // MARK: - Query & Feature Delegation
    
    public func processUserQuery(_ query: String) async -> String {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Correctly pass the optional dictionary
            let insight = try await intelligenceEngine.process(query: query, context: currentContext?.data)
            return insight.description
        } catch {
            return "I'm having trouble processing that request. Please try again."
        }
    }

    public func executeFeature(_ feature: NovaAIFeature) async -> String {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let query = feature.description
            let insight = try await intelligenceEngine.process(query: query, context: ["featureId": feature.id], priority: feature.priority)
            return insight.description
        } catch {
            return "I encountered an error processing your request. Please try again."
        }
    }
    
    // MARK: - Suggestions & Insights
    
    private func generateSuggestions() async {
        guard let worker = contextAdapter.currentWorker else { return }
        do {
            let recommendations = try await intelligenceEngine.generateTaskRecommendations(for: worker)
            self.suggestedActions = recommendations
        } catch {
            print("Error generating suggestions: \(error)")
        }
    }
    
    private func refreshInsights() async {
        do {
            let insights = try await intelligenceService.generatePortfolioInsights()
            self.activeInsights = insights
        } catch {
            print("Error refreshing insights: \(error)")
        }
    }

    // MARK: - Scenario Management
    
    public func checkForScenarios() async {
        guard let worker = contextAdapter.currentWorker else { return }
        
        // Kevin's missing buildings scenario (Worker ID "4")
        if worker.id == "4" && contextAdapter.assignedBuildings.isEmpty {
            let scenario = CoreTypes.AIScenario(type: .emergencyRepair, title: "Assignment Error", description: "Critical: No buildings assigned to Kevin Dutan.", timestamp: Date())
            addScenario(scenario)
        }
    }
    
    public func addScenario(_ scenario: CoreTypes.AIScenario) {
        if !activeScenarios.contains(where: { $0.id == scenario.id }) {
            activeScenarios.append(scenario)
            if scenario.priority == .critical {
                presentScenario(scenario)
            }
        }
    }
    
    public func presentScenario(_ scenario: CoreTypes.AIScenario) {
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
    
    public func performScenarioAction(_ scenario: CoreTypes.AIScenario) {
        switch scenario.type {
        case .emergencyRepair:
            // The worker context is already known, no need to pass it from the scenario
            if let workerId = contextAdapter.currentWorker?.id {
                Task { await performEmergencyRepair(for: workerId) }
            }
        default:
            print("🤖 Handling scenario: \(scenario.type.rawValue)")
        }
        dismissCurrentScenario()
    }
    
    // MARK: - Emergency Repair
    
    public func performEmergencyRepair(for workerId: String) async {
        self.repairState = NovaEmergencyRepairState(isActive: true, progress: 0.0, message: "Initializing repair sequence...", workerId: workerId)
        
        do {
            try await Task.sleep(nanoseconds: 500_000_000)
            repairState.message = "Rebuilding assignment matrix..."
            repairState.progress = 0.5
            
            // DELEGATE the actual data refresh to the context engine
            try await contextAdapter.loadContext(for: workerId)
            
            repairState.message = "✅ Emergency repair successful."
            repairState.progress = 1.0
            try await Task.sleep(nanoseconds: 1_000_000_000)
        } catch {
            repairState.message = "❌ Repair failed: \(error.localizedDescription)"
        }
        
        self.repairState.isActive = false
    }

    // MARK: - Helper Methods
    
    private func getCurrentActiveTask() -> CoreTypes.ContextualTask? {
        return contextAdapter.todaysTasks.first { !$0.isCompleted }
    }
    
    private func getUrgentTasks() -> [CoreTypes.ContextualTask] {
        return contextAdapter.todaysTasks.filter { task in
            guard let urgency = task.urgency else { return false }
            return urgency == .urgent || urgency == .critical || urgency == .emergency
        }
    }
    
    private func getUrgentTaskCount() -> Int {
        return getUrgentTasks().count
    }
    
    private func calculateCurrentCompletionRate() -> Int {
        let tasks = contextAdapter.todaysTasks
        guard !tasks.isEmpty else { return 100 }
        let completed = tasks.filter { $0.isCompleted }.count
        return Int((Double(completed) / Double(tasks.count)) * 100)
    }
}

// MARK: - Supporting Local Types

public struct NovaAIFeature: Identifiable {
    public let id: String
    public let title: String
    public let description: String
    public let icon: String
    public let category: NovaAIFeatureCategory
    public let priority: CoreTypes.AIPriority
}

public enum NovaAIFeatureCategory {
    case fieldAssistance, safety, information, taskManagement, problemSolving
    case analytics, optimization, predictive, compliance, reporting, strategic
}

public enum TimeOfDay: String {
    case morning, afternoon, evening, night
}
