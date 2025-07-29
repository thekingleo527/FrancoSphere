//
//  NovaAIContextManager.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: DashboardUpdate properly namespaced as CoreTypes.DashboardUpdate
//  ✅ UPDATED: Aligned with CoreTypes v6.0
//  ✅ FIXED: Using correct IntelligenceService methods
//  ✅ ENHANCED: Better role-based AI routing
//  ✅ INTEGRATED: With IntelligenceService and BuildingMetricsService
//

import Foundation
import SwiftUI
import Combine

// MARK: - Nova AI Context System

@MainActor
public class NovaAIContextManager: ObservableObject {
    public static let shared = NovaAIContextManager()
    
    @Published public var currentContext: AIContext?
    @Published public var availableFeatures: [AIFeature] = []
    @Published public var suggestedActions: [CoreTypes.AISuggestion] = []
    @Published public var activeInsights: [CoreTypes.IntelligenceInsight] = []
    @Published public var isProcessing = false
    
    // Dependencies
    private let contextAdapter = WorkerContextEngineAdapter.shared
    private let intelligenceService = IntelligenceService.shared
    private let buildingMetricsService = BuildingMetricsService.shared
    private let dashboardSyncService = DashboardSyncService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupSubscriptions()
        updateContext()
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // Subscribe to dashboard updates
        dashboardSyncService.crossDashboardUpdates
            .sink { [weak self] update in
                self?.handleDashboardUpdate(update)
            }
            .store(in: &cancellables)
        
        // Subscribe to worker context changes
        contextAdapter.$currentWorker
            .sink { [weak self] _ in
                self?.updateContext()
            }
            .store(in: &cancellables)
        
        contextAdapter.$currentBuilding
            .sink { [weak self] _ in
                self?.updateContext()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Context Management
    
    public func updateContext() {
        guard let worker = contextAdapter.currentWorker else { return }
        
        currentContext = AIContext(
            userRole: worker.role,
            currentBuilding: contextAdapter.currentBuilding,
            activeTask: getCurrentActiveTask(),
            assignedBuildings: contextAdapter.assignedBuildings,
            portfolioBuildings: contextAdapter.portfolioBuildings,
            urgentTasks: getUrgentTasks(),
            timeOfDay: getTimeOfDay(),
            weatherConditions: getCurrentWeather()
        )
        
        updateAvailableFeatures()
        generateSuggestions()
        Task {
            await refreshIntelligenceInsights()
        }
    }
    
    // MARK: - Role-Based Feature Sets
    
    private func updateAvailableFeatures() {
        guard let context = currentContext else { return }
        
        switch context.userRole {
        case .worker:
            availableFeatures = getWorkerFeatures(context: context)
        case .admin:
            availableFeatures = getAdminFeatures(context: context)
        case .manager:
            availableFeatures = getManagerFeatures(context: context)
        case .client:
            availableFeatures = getClientFeatures(context: context)
        }
    }
    
    // MARK: - Worker AI Features
    
    private func getWorkerFeatures(context: AIContext) -> [AIFeature] {
        var features: [AIFeature] = []
        
        // Core field assistance
        features.append(contentsOf: [
            AIFeature(
                id: "troubleshooting",
                title: "Equipment Troubleshooting",
                description: "Get step-by-step repair guidance",
                icon: "wrench.adjustable",
                category: .fieldAssistance,
                priority: context.activeTask != nil ? .high : .medium
            ),
            AIFeature(
                id: "safety-protocols",
                title: "Safety Protocols",
                description: "Emergency procedures and safety guidelines",
                icon: "shield.checkered",
                category: .safety,
                priority: .high
            ),
            AIFeature(
                id: "building-info",
                title: "Building Information",
                description: "Systems, layouts, and contact information",
                icon: "building.2",
                category: .information,
                priority: context.currentBuilding != nil ? .high : .low
            )
        ])
        
        // Task-specific features
        if let task = context.activeTask {
            features.append(
                AIFeature(
                    id: "task-guidance",
                    title: "Current Task Assistance",
                    description: "Help with: \(task.title)",
                    icon: "list.clipboard",
                    category: .taskSpecific,
                    priority: .critical
                )
            )
            
            // Category-specific assistance
            if let category = task.category {
                features.append(getTaskCategoryFeature(category: category))
            }
        }
        
        // Building-specific features
        if let building = context.currentBuilding {
            features.append(contentsOf: [
                AIFeature(
                    id: "building-systems",
                    title: "\(building.name) Systems",
                    description: "HVAC, electrical, and security info",
                    icon: "gear.2",
                    category: .buildingSpecific,
                    priority: .high
                ),
                AIFeature(
                    id: "maintenance-history",
                    title: "Maintenance History",
                    description: "Past work and known issues",
                    icon: "clock.arrow.circlepath",
                    category: .buildingSpecific,
                    priority: .medium
                )
            ])
        }
        
        // Weather-dependent features
        if context.weatherConditions?.requiresIndoorWork == true {
            features.append(
                AIFeature(
                    id: "indoor-tasks",
                    title: "Indoor Task Suggestions",
                    description: "Weather-appropriate alternatives",
                    icon: "cloud.rain",
                    category: .weatherAdaptive,
                    priority: .medium
                )
            )
        }
        
        // Sort features by priority
        return features.sorted(by: { $0.priority.numericValue > $1.priority.numericValue })
    }
    
    // MARK: - Admin AI Features
    
    private func getAdminFeatures(context: AIContext) -> [AIFeature] {
        [
            AIFeature(
                id: "portfolio-analytics",
                title: "Portfolio Analytics",
                description: "Performance metrics and trends",
                icon: "chart.line.uptrend.xyaxis",
                category: .analytics,
                priority: .high
            ),
            AIFeature(
                id: "resource-optimization",
                title: "Resource Optimization",
                description: "Worker allocation and scheduling",
                icon: "person.3.sequence",
                category: .optimization,
                priority: .high
            ),
            AIFeature(
                id: "predictive-maintenance",
                title: "Predictive Maintenance",
                description: "Anticipate equipment failures",
                icon: "waveform.path.ecg",
                category: .predictive,
                priority: .medium
            ),
            AIFeature(
                id: "cost-analysis",
                title: "Cost Analysis",
                description: "Budget tracking and projections",
                icon: "dollarsign.circle",
                category: .financial,
                priority: .medium
            ),
            AIFeature(
                id: "compliance-monitoring",
                title: "Compliance Monitoring",
                description: "Regulatory requirements and deadlines",
                icon: "checkmark.shield",
                category: .compliance,
                priority: .high
            ),
            AIFeature(
                id: "strategic-planning",
                title: "Strategic Planning",
                description: "Long-term portfolio optimization",
                icon: "chart.xyaxis.line",
                category: .strategic,
                priority: .medium
            )
        ]
    }
    
    // MARK: - Manager AI Features (Previously Supervisor)
    
    private func getManagerFeatures(context: AIContext) -> [AIFeature] {
        [
            AIFeature(
                id: "team-coordination",
                title: "Team Coordination",
                description: "Worker assignments and communication",
                icon: "person.3",
                category: .teamManagement,
                priority: .high
            ),
            AIFeature(
                id: "quality-control",
                title: "Quality Control",
                description: "Task verification and standards",
                icon: "checkmark.seal",
                category: .qualityAssurance,
                priority: .high
            ),
            AIFeature(
                id: "training-guidance",
                title: "Training Guidance",
                description: "Skill development and certification",
                icon: "graduationcap",
                category: .training,
                priority: .medium
            ),
            AIFeature(
                id: "issue-escalation",
                title: "Issue Escalation",
                description: "Problem resolution pathways",
                icon: "exclamationmark.triangle",
                category: .problemSolving,
                priority: .high
            ),
            AIFeature(
                id: "performance-tracking",
                title: "Performance Tracking",
                description: "Worker productivity and efficiency",
                icon: "speedometer",
                category: .performance,
                priority: .medium
            ),
            AIFeature(
                id: "schedule-optimization",
                title: "Schedule Optimization",
                description: "Shift planning and task allocation",
                icon: "calendar",
                category: .optimization,
                priority: .medium
            )
        ]
    }
    
    // MARK: - Client AI Features
    
    private func getClientFeatures(context: AIContext) -> [AIFeature] {
        [
            AIFeature(
                id: "service-reports",
                title: "Service Reports",
                description: "Detailed maintenance summaries",
                icon: "doc.text",
                category: .reporting,
                priority: .high
            ),
            AIFeature(
                id: "building-status",
                title: "Building Status",
                description: "Real-time system monitoring",
                icon: "building.columns",
                category: .monitoring,
                priority: .high
            ),
            AIFeature(
                id: "service-requests",
                title: "Service Requests",
                description: "Submit and track maintenance requests",
                icon: "plus.message",
                category: .serviceManagement,
                priority: .medium
            ),
            AIFeature(
                id: "performance-dashboard",
                title: "Performance Dashboard",
                description: "Key metrics and satisfaction scores",
                icon: "speedometer",
                category: .performance,
                priority: .medium
            ),
            AIFeature(
                id: "compliance-overview",
                title: "Compliance Overview",
                description: "Regulatory status and certifications",
                icon: "checkmark.shield",
                category: .compliance,
                priority: .high
            ),
            AIFeature(
                id: "cost-transparency",
                title: "Cost Transparency",
                description: "Maintenance costs and budget tracking",
                icon: "dollarsign.circle",
                category: .financial,
                priority: .medium
            )
        ]
    }
    
    // MARK: - AI Suggestions Generation
    
    private func generateSuggestions() {
        guard let context = currentContext else { return }
        
        switch context.userRole {
        case .worker:
            self.suggestedActions = generateWorkerSuggestions(context: context)
        case .admin:
            self.suggestedActions = generateAdminSuggestions(context: context)
        case .manager:
            self.suggestedActions = generateManagerSuggestions(context: context)
        case .client:
            self.suggestedActions = generateClientSuggestions(context: context)
        }
    }
    
    private func generateWorkerSuggestions(context: AIContext) -> [CoreTypes.AISuggestion] {
        var suggestions: [CoreTypes.AISuggestion] = []
        
        // Urgent task suggestions
        if !context.urgentTasks.isEmpty {
            suggestions.append(
                CoreTypes.AISuggestion(
                    title: "Urgent Tasks",
                    description: "You have \(context.urgentTasks.count) urgent task(s) pending",
                    priority: .high,
                    category: .operations,
                    actionRequired: true,
                    estimatedImpact: "High"
                )
            )
        }
        
        // Weather-based suggestions
        if let weather = context.weatherConditions, weather.requiresIndoorWork {
            suggestions.append(
                CoreTypes.AISuggestion(
                    title: "Weather Alert",
                    description: "Consider rescheduling outdoor work due to \(weather.description)",
                    priority: .medium,
                    category: .safety,
                    actionRequired: true,
                    estimatedImpact: "Medium"
                )
            )
        }
        
        // Building-specific suggestions
        if let building = context.currentBuilding {
            suggestions.append(
                CoreTypes.AISuggestion(
                    title: "Building Checklist",
                    description: "Review \(building.name) systems and recent alerts",
                    priority: .medium,
                    category: .operations,
                    estimatedImpact: "Low"
                )
            )
        }
        
        // Time-based suggestions
        switch context.timeOfDay {
        case .morning:
            suggestions.append(
                CoreTypes.AISuggestion(
                    title: "Morning Setup",
                    description: "Review today's tasks and safety equipment",
                    priority: .low,
                    category: .operations,
                    estimatedImpact: "Low"
                )
            )
        case .evening:
            suggestions.append(
                CoreTypes.AISuggestion(
                    title: "End of Day",
                    description: "Complete task documentation and secure equipment",
                    priority: .medium,
                    category: .operations,
                    estimatedImpact: "Medium"
                )
            )
        default:
            break
        }
        
        return suggestions
    }
    
    private func generateAdminSuggestions(context: AIContext) -> [CoreTypes.AISuggestion] {
        var suggestions: [CoreTypes.AISuggestion] = []
        
        suggestions.append(contentsOf: [
            CoreTypes.AISuggestion(
                title: "Performance Review",
                description: "Analyze portfolio efficiency and worker productivity",
                priority: .medium,
                category: .efficiency,
                estimatedImpact: "High"
            ),
            CoreTypes.AISuggestion(
                title: "Budget Optimization",
                description: "Identify cost-saving opportunities across buildings",
                priority: .medium,
                category: .cost,
                estimatedImpact: "High"
            ),
            CoreTypes.AISuggestion(
                title: "Compliance Check",
                description: "Review upcoming compliance deadlines",
                priority: .high,
                category: .compliance,
                actionRequired: true,
                estimatedImpact: "Critical"
            )
        ])
        
        // Add portfolio-specific suggestions
        if context.portfolioBuildings.count > 10 {
            suggestions.append(
                CoreTypes.AISuggestion(
                    title: "Portfolio Analysis",
                    description: "Large portfolio detected - consider automated scheduling",
                    priority: .high,
                    category: .efficiency,
                    estimatedImpact: "High"
                )
            )
        }
        
        return suggestions
    }
    
    private func generateManagerSuggestions(context: AIContext) -> [CoreTypes.AISuggestion] {
        var suggestions: [CoreTypes.AISuggestion] = []
        
        suggestions.append(
            CoreTypes.AISuggestion(
                title: "Team Check-in",
                description: "Review worker status and task progress",
                priority: .medium,
                category: .operations,
                estimatedImpact: "Medium"
            )
        )
        
        // Add task-based suggestions
        if context.urgentTasks.count > 3 {
            suggestions.append(
                CoreTypes.AISuggestion(
                    title: "Resource Allocation",
                    description: "Multiple urgent tasks - consider reassigning workers",
                    priority: .high,
                    category: .operations,
                    actionRequired: true,
                    estimatedImpact: "High"
                )
            )
        }
        
        // Quality control reminders
        suggestions.append(
            CoreTypes.AISuggestion(
                title: "Quality Assurance",
                description: "Review completed tasks for quality standards",
                priority: .medium,
                category: .quality,
                estimatedImpact: "Medium"
            )
        )
        
        return suggestions
    }
    
    private func generateClientSuggestions(context: AIContext) -> [CoreTypes.AISuggestion] {
        [
            CoreTypes.AISuggestion(
                title: "Service Summary",
                description: "Review this week's maintenance activities",
                priority: .low,
                category: .compliance,
                estimatedImpact: "Low"
            ),
            CoreTypes.AISuggestion(
                title: "Performance Metrics",
                description: "View building efficiency and cost analysis",
                priority: .medium,
                category: .efficiency,
                estimatedImpact: "Medium"
            )
        ]
    }
    
    // MARK: - Intelligence Integration
    
    private func refreshIntelligenceInsights() async {
        isProcessing = true
        
        do {
            // Get insights based on current context
            let insights: [CoreTypes.IntelligenceInsight]
            
            if let buildingId = currentContext?.currentBuilding?.id {
                // Get building-specific insights
                insights = try await intelligenceService.generateBuildingInsights(for: buildingId)
            } else {
                // Get portfolio insights
                insights = try await intelligenceService.generatePortfolioInsights()
            }
            
            await MainActor.run {
                self.activeInsights = insights
                self.isProcessing = false
            }
            
            // Check for critical insights
            let criticalInsights = insights.filter { $0.priority == .critical }
            if !criticalInsights.isEmpty {
                await MainActor.run {
                    self.handleCriticalInsights(criticalInsights)
                }
            }
            
        } catch {
            print("Error refreshing intelligence insights: \(error)")
            await MainActor.run {
                self.isProcessing = false
            }
        }
    }
    
    private func handleCriticalInsights(_ insights: [CoreTypes.IntelligenceInsight]) {
        // Create high-priority suggestions from critical insights
        let criticalSuggestions = insights.map { insight in
            CoreTypes.AISuggestion(
                title: "Critical: \(insight.title)",
                description: insight.description,
                priority: .critical,
                category: insight.type,
                actionRequired: true,
                estimatedImpact: "Critical"
            )
        }
        
        // Prepend critical suggestions
        suggestedActions = criticalSuggestions + suggestedActions
    }
    
    // MARK: - Task Category Features
    
    private func getTaskCategoryFeature(category: CoreTypes.TaskCategory) -> AIFeature {
        switch category {
        case .cleaning:
            return AIFeature(
                id: "cleaning-guide",
                title: "Cleaning Procedures",
                description: "Best practices and material guidance",
                icon: "sparkles",
                category: .taskSpecific,
                priority: .medium
            )
        case .maintenance:
            return AIFeature(
                id: "maintenance-guide",
                title: "Maintenance Procedures",
                description: "Equipment manuals and schedules",
                icon: "wrench.and.screwdriver",
                category: .taskSpecific,
                priority: .medium
            )
        case .repair:
            return AIFeature(
                id: "repair-diagnostics",
                title: "Repair Diagnostics",
                description: "Troubleshooting and part identification",
                icon: "hammer",
                category: .taskSpecific,
                priority: .high
            )
        case .inspection:
            return AIFeature(
                id: "inspection-checklist",
                title: "Inspection Checklist",
                description: "Compliance points and documentation",
                icon: "magnifyingglass",
                category: .taskSpecific,
                priority: .medium
            )
        case .emergency:
            return AIFeature(
                id: "emergency-response",
                title: "Emergency Response",
                description: "Immediate action protocols",
                icon: "exclamationmark.triangle.fill",
                category: .taskSpecific,
                priority: .critical
            )
        default:
            return AIFeature(
                id: "general-assistance",
                title: "Task Assistance",
                description: "General guidance and support",
                icon: "questionmark.circle",
                category: .taskSpecific,
                priority: .low
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentActiveTask() -> CoreTypes.ContextualTask? {
        return contextAdapter.todaysTasks.first { !$0.isCompleted }
    }
    
    private func getUrgentTasks() -> [CoreTypes.ContextualTask] {
        return contextAdapter.todaysTasks.filter {
            $0.urgency == .urgent || $0.urgency == .critical || $0.urgency == .emergency
        }
    }
    
    private func getTimeOfDay() -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<20: return .evening
        default: return .night
        }
    }
    
    private func getCurrentWeather() -> WeatherConditions? {
        // This would integrate with weather service
        // For now, return nil or mock data
        return nil
    }
    
    // MARK: - Dashboard Update Handling
    
    private func handleDashboardUpdate(_ update: CoreTypes.DashboardUpdate) {
        // React to real-time dashboard updates
        switch update.type {
        case .taskCompleted, .taskStarted:
            updateContext()
        case .buildingMetricsChanged:
            if update.buildingId == currentContext?.currentBuilding?.id {
                Task {
                    await refreshIntelligenceInsights()
                }
            }
        case .workerClockedIn, .workerClockedOut:
            if update.workerId == contextAdapter.currentWorker?.id {
                updateContext()
            }
        default:
            break
        }
    }
    
    // MARK: - Public API
    
    public func processUserQuery(_ query: String) async -> String {
        isProcessing = true
        
        // This would integrate with Nova AI service
        // For now, return a context-aware response
        let response = await generateContextAwareResponse(for: query)
        
        await MainActor.run {
            self.isProcessing = false
        }
        
        return response
    }
    
    private func generateContextAwareResponse(for query: String) async -> String {
        guard let context = currentContext else {
            return "I need more context to help you. Please ensure you're logged in."
        }
        
        // Basic context-aware responses
        let lowercaseQuery = query.lowercased()
        
        if lowercaseQuery.contains("task") || lowercaseQuery.contains("what should i do") {
            if let task = context.activeTask {
                return "Your current task is: \(task.title). \(task.description ?? "")"
            } else {
                return "You have no active tasks at the moment. Check your task list for upcoming work."
            }
        }
        
        if lowercaseQuery.contains("building") || lowercaseQuery.contains("where") {
            if let building = context.currentBuilding {
                return "You're currently at \(building.name). I can help with building-specific information."
            } else {
                return "Please select a building to get location-specific assistance."
            }
        }
        
        if lowercaseQuery.contains("urgent") || lowercaseQuery.contains("priority") {
            let urgentCount = context.urgentTasks.count
            if urgentCount > 0 {
                return "You have \(urgentCount) urgent task(s). Would you like me to list them?"
            } else {
                return "No urgent tasks at the moment. You're all caught up!"
            }
        }
        
        // Default response
        return "I'm Nova, your AI assistant. I can help with tasks, building information, safety protocols, and more. What would you like to know?"
    }
    
    // MARK: - Building-Specific Intelligence
    
    public func loadBuildingInsights(for buildingId: String) async {
        isProcessing = true
        
        do {
            let insights = try await intelligenceService.generateBuildingInsights(for: buildingId)
            await MainActor.run {
                self.activeInsights = insights
                self.isProcessing = false
            }
        } catch {
            print("Error loading building insights: \(error)")
            await MainActor.run {
                self.isProcessing = false
            }
        }
    }
    
    // MARK: - Portfolio Intelligence
    
    public func loadPortfolioInsights() async {
        isProcessing = true
        
        do {
            let insights = try await intelligenceService.generatePortfolioInsights()
            await MainActor.run {
                self.activeInsights = insights
                self.isProcessing = false
            }
        } catch {
            print("Error loading portfolio insights: \(error)")
            await MainActor.run {
                self.isProcessing = false
            }
        }
    }
}

// MARK: - Supporting Types (Local to AI Context)

public struct AIContext {
    let userRole: CoreTypes.UserRole
    let currentBuilding: CoreTypes.NamedCoordinate?
    let activeTask: CoreTypes.ContextualTask?
    let assignedBuildings: [CoreTypes.NamedCoordinate]
    let portfolioBuildings: [CoreTypes.NamedCoordinate]
    let urgentTasks: [CoreTypes.ContextualTask]
    let timeOfDay: TimeOfDay
    let weatherConditions: WeatherConditions?
}

public struct AIFeature: Identifiable {
    public let id: String
    public let title: String
    public let description: String
    public let icon: String
    public let category: AIFeatureCategory
    public let priority: CoreTypes.AIPriority
}

public enum AIFeatureCategory {
    case fieldAssistance, safety, information, taskSpecific, buildingSpecific
    case weatherAdaptive, analytics, optimization, predictive, financial
    case compliance, teamManagement, qualityAssurance, training, problemSolving
    case reporting, monitoring, serviceManagement, performance, taskManagement
    case strategic
}

public enum TimeOfDay {
    case morning, afternoon, evening, night
}

public struct WeatherConditions {
    let description: String
    let requiresIndoorWork: Bool
    let temperature: Double
    let precipitation: Bool
}

// MARK: - Extensions

extension CoreTypes.AIPriority {
    var numericValue: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
}

// MARK: - SwiftUI Integration

extension NovaAIContextManager {
    /// Get feature by ID
    public func getFeature(byId id: String) -> AIFeature? {
        return availableFeatures.first { $0.id == id }
    }
    
    /// Execute feature action
    public func executeFeature(_ feature: AIFeature) async {
        // This would trigger the appropriate AI action
        // For now, just log it
        print("Executing AI feature: \(feature.title)")
        
        // Generate contextual response based on feature
        let response = await processFeatureRequest(feature)
        print("AI Response: \(response)")
    }
    
    private func processFeatureRequest(_ feature: AIFeature) async -> String {
        switch feature.id {
        case "troubleshooting":
            return "I'll help you troubleshoot the equipment. What specific issue are you experiencing?"
        case "safety-protocols":
            return "Here are the safety protocols for your current location. Always prioritize safety first."
        case "building-info":
            return "I can provide building-specific information. What would you like to know?"
        case "task-guidance":
            return "Let me guide you through your current task step by step."
        case "portfolio-analytics":
            await loadPortfolioInsights()
            return "Loading portfolio analytics and insights..."
        case "building-systems":
            if let buildingId = currentContext?.currentBuilding?.id {
                await loadBuildingInsights(for: buildingId)
                return "Loading building system information..."
            }
            return "Please select a building first."
        default:
            return "How can I assist you with \(feature.title)?"
        }
    }
}

// MARK: - Usage Examples

/*
🎯 CONTEXTUAL AI EXAMPLES:

👷 WORKER (Kevin at Rubin Museum with HVAC task):
"Nova, the HVAC system in the east wing is making noise"
→ AI provides: Rubin Museum HVAC troubleshooting guide, safety protocols for museum environment, contact for specialized HVAC vendor

👔 ADMIN (Franco reviewing portfolio):
"Nova, show me this week's efficiency metrics"
→ AI provides: Portfolio analytics, cost per building, worker productivity scores, maintenance budget analysis

👨‍💼 MANAGER (Shawn coordinating team):
"Nova, where should I assign the new maintenance request?"
→ AI provides: Worker availability, skill matching, location optimization, workload balancing

🏢 CLIENT (building owner):
"Nova, what's the status of my building maintenance?"
→ AI provides: Service completion rates, recent activities, upcoming scheduled maintenance, compliance status

🌧️ WEATHER-AWARE:
Worker: "Nova, it's raining - what should I prioritize?"
→ AI provides: Indoor task list, weather-safe alternatives, schedule adjustments

🚨 EMERGENCY-AWARE:
Worker: "Nova, I found a water leak in the basement"
→ AI provides: Emergency shutdown procedures, vendor contacts, escalation protocols, safety guidelines

🎯 ROLE-SPECIFIC FEATURES:
- Workers get hands-on assistance and safety guidance
- Admins get strategic insights and portfolio optimization
- Managers get team coordination and quality control
- Clients get transparency and performance metrics
*/
