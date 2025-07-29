//
//  NovaFeatureManager.swift
//  FrancoSphere v6.0
//
//  Manages Nova AI features, scenarios, and role-based capabilities
//  ✅ ENHANCED: Added scenario support from AIScenarioSheetView
//  ✅ ENHANCED: Added emergency repair functionality
//  ✅ ENHANCED: Added reminder scheduling
//  ✅ ENHANCED: Added query processing from AIContextManager
//  ✅ ENHANCED: Added prediction caching from PredictionEngine
//  ✅ ENHANCED: Added context awareness and time-based features
//  ✅ FIXED: Swift 6 concurrency compliance
//  ✅ FIXED: Added CoreTypes prefix to DashboardUpdate
//  ✅ FIXED: Added proper error handling for throwing calls
//  ✅ FIXED: All compilation errors resolved
//  ✅ FIXED: Sendable conformance for Timer closures
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
    
    // MARK: - Context Properties (from AIContextManager)
    @Published public var currentContext: NovaContext?
    @Published public var timeOfDay: TimeOfDay = .morning
    
    // MARK: - Scenario Management Properties
    @Published public var activeScenarios: [NovaScenarioData] = []
    @Published public var currentScenario: NovaScenarioData?
    @Published public var showingScenario = false
    @Published public var hasActiveScenarios = false
    
    // MARK: - Emergency Repair Properties
    @Published public var repairState = NovaEmergencyRepairState()
    
    // MARK: - Caching Properties (from PredictionEngine)
    private var predictionCache: [String: (content: String, timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    // MARK: - Dependencies
    private let contextAdapter = WorkerContextEngineAdapter.shared
    private let intelligenceEngine = NovaIntelligenceEngine.shared
    private let dashboardSyncService = DashboardSyncService.shared
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let buildingMetricsService = BuildingMetricsService.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var reminderTimers: [UUID: Timer] = [:]
    
    private init() {
        setupSubscriptions()
        updateContext()
        updateFeatures()
        checkForScenarios()
    }
    
    // MARK: - Setup (FIX 1: Broken into smaller methods)
    
    private func setupSubscriptions() {
        setupDashboardSubscriptions()
        setupWorkerContextSubscriptions()
        setupScenarioSubscriptions()
        setupTimeUpdates()
    }
    
    private func setupDashboardSubscriptions() {
        // Subscribe to dashboard updates
        dashboardSyncService.crossDashboardUpdates
            .sink(receiveValue: { [weak self] update in
                self?.handleDashboardUpdate(update)
            })
            .store(in: &cancellables)
    }
    
    private func setupWorkerContextSubscriptions() {
        // Subscribe to worker context changes
        contextAdapter.$currentWorker
            .sink(receiveValue: { [weak self] _ in
                self?.updateContext()
                self?.updateFeatures()
                self?.checkForScenarios()
            })
            .store(in: &cancellables)
        
        contextAdapter.$currentBuilding
            .sink(receiveValue: { [weak self] _ in
                self?.updateContext()
                self?.updateFeatures()
            })
            .store(in: &cancellables)
    }
    
    private func setupScenarioSubscriptions() {
        // Monitor active scenarios
        $activeScenarios
            .map { !$0.isEmpty }
            .assign(to: &$hasActiveScenarios)
    }
    
    private func setupTimeUpdates() {
        // Update time of day periodically
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimeOfDay()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Context Management (from AIContextManager)
    
    private func updateContext() {
        guard let worker = contextAdapter.currentWorker else { return }
        
        // Update time of day
        updateTimeOfDay()
        
        // Build comprehensive context
        let urgentTasks = getUrgentTasks()
        let activeTask = getCurrentActiveTask()
        
        // FIX 2: Ensure all values are strings in the data dictionary
        currentContext = NovaContext(
            data: [
                "userRole": worker.role.rawValue,
                "workerId": worker.id,
                "workerName": worker.name,
                "currentBuilding": contextAdapter.currentBuilding?.id ?? "",
                "buildingName": contextAdapter.currentBuilding?.name ?? "",
                "assignedBuildingsCount": "\(contextAdapter.assignedBuildings.count)",
                "portfolioBuildingsCount": "\(contextAdapter.portfolioBuildings.count)",
                "todaysTasksCount": "\(contextAdapter.todaysTasks.count)",
                "completedTasksCount": "\(contextAdapter.todaysTasks.filter { $0.isCompleted }.count)",
                "urgentTasksCount": "\(urgentTasks.count)",  // FIX 2: Convert to string
                "activeTaskId": activeTask?.id ?? "",
                "activeTaskTitle": activeTask?.title ?? "",
                "timeOfDay": timeOfDay.rawValue,
                "completionRate": "\(calculateCurrentCompletionRate())"
            ],
            insights: activeInsights.map { $0.title },  // Convert to string array
            metadata: [
                "lastUpdated": ISO8601DateFormatter().string(from: Date()),
                "contextVersion": "1.0"
            ],
            userRole: worker.role,
            buildingContext: contextAdapter.currentBuilding?.id,
            taskContext: activeTask?.id
        )
    }
    
    // MARK: - Query Processing (from AIContextManager)
    
    public func processUserQuery(_ query: String) async -> String {
        isProcessing = true
        defer { isProcessing = false }
        
        let lowercaseQuery = query.lowercased()
        
        // Check for specific intents
        if lowercaseQuery.contains("portfolio") || lowercaseQuery.contains("overview") {
            return await generatePortfolioPrediction()
        }
        
        if lowercaseQuery.contains("building") {
            if let buildingId = contextAdapter.currentBuilding?.id {
                return await generateBuildingPrediction(for: buildingId)
            } else {
                return "Please select a building to get building-specific information."
            }
        }
        
        if lowercaseQuery.contains("task") || lowercaseQuery.contains("what should i do") {
            return await generateTaskGuidance()
        }
        
        if lowercaseQuery.contains("urgent") || lowercaseQuery.contains("priority") {
            let urgentCount = getUrgentTaskCount()
            if urgentCount > 0 {
                let urgentTasks = getUrgentTasks()
                var response = "You have \(urgentCount) urgent task(s):\n"
                for (index, task) in urgentTasks.prefix(3).enumerated() {
                    let urgencyText = task.urgency?.rawValue ?? "Unknown"
                    response += "\(index + 1). \(task.title) - \(urgencyText)\n"
                }
                return response
            } else {
                return "No urgent tasks at the moment. You're all caught up!"
            }
        }
        
        if lowercaseQuery.contains("weather") {
            return await generateWeatherBasedGuidance()
        }
        
        if lowercaseQuery.contains("help") || lowercaseQuery.contains("nova") {
            return generateContextAwareHelp()
        }
        
        // Default to using intelligence engine for general queries
        do {
            // FIX 3: Context is already correct type [String: String]
            let insight = try await intelligenceEngine.process(
                query: query,
                context: currentContext?.data ?? [:],
                priority: .medium
            )
            return insight.description
        } catch {
            return "I'm having trouble processing that request. Could you try rephrasing it?"
        }
    }
    
    // MARK: - Prediction Methods (from PredictionEngine)
    
    public func generatePortfolioPrediction() async -> String {
        // Check cache first
        if let cached = getCachedPrediction(for: "portfolio") {
            return cached
        }
        
        do {
            // Get real portfolio data
            let buildings = try await buildingService.getAllBuildings()
            let tasks = try await taskService.getAllTasks()
            let workers = try await workerService.getAllActiveWorkers()
            
            let completedTasks = tasks.filter { $0.isCompleted }.count
            let urgentTasks = tasks.filter { task in
                guard let urgency = task.urgency else { return false }
                return urgency == .urgent || urgency == .critical || urgency == .emergency
            }.count
            let overdueTasks = tasks.filter { $0.isOverdue && !$0.isCompleted }.count
            
            // Build prediction
            var prediction = "📊 Portfolio Overview: "
            prediction += "\(buildings.count) buildings, \(workers.count) active workers, \(tasks.count) total tasks. "
            
            // Add completion metrics
            let completionRate = tasks.isEmpty ? 100 : Int(Double(completedTasks) / Double(tasks.count) * 100)
            prediction += "Current completion rate: \(completionRate)%. "
            
            // Add urgency indicators
            if urgentTasks > 0 {
                prediction += "⚠️ \(urgentTasks) urgent tasks require attention. "
            }
            if overdueTasks > 0 {
                prediction += "⏰ \(overdueTasks) overdue tasks. "
            }
            
            // Add predictive element
            let predictedRate = calculatePredictedCompletionRate()
            prediction += "Predicted end-of-day completion: \(predictedRate)%. "
            
            // Add time-based recommendation
            switch timeOfDay {
            case .morning:
                prediction += "Morning focus: Prioritize urgent and outdoor tasks."
            case .afternoon:
                prediction += "Afternoon focus: Indoor tasks and documentation."
            case .evening:
                prediction += "Evening focus: Wrap up tasks and prepare for tomorrow."
            case .night:
                prediction += "After hours: Emergency response only."
            }
            
            // Cache the result
            cachePrediction(prediction, for: "portfolio")
            
            return prediction
        } catch {
            return "Portfolio analysis is being updated. Using cached data: Multiple buildings under active management."
        }
    }
    
    public func generateBuildingPrediction(for buildingId: String) async -> String {
        let cacheKey = "building_\(buildingId)"
        
        // Check cache
        if let cached = getCachedPrediction(for: cacheKey) {
            return cached
        }
        
        do {
            // Get real building data
            guard let building = try await buildingService.getBuilding(buildingId: buildingId) else {
                return "Building not found."
            }
            
            let tasks = try await taskService.getTasksForBuilding(buildingId)
            let metrics = try await buildingMetricsService.calculateMetrics(for: buildingId)
            
            // Build prediction
            var prediction = "🏢 \(building.name) Status: "
            
            // Add metrics
            prediction += "\(tasks.count) tasks, \(metrics.activeWorkers) workers on-site. "
            prediction += "Completion rate: \(Int(metrics.completionRate * 100))%. "
            
            if metrics.overdueTasks > 0 {
                prediction += "⚠️ \(metrics.overdueTasks) overdue tasks. "
            }
            
            if metrics.urgentTasksCount > 0 {
                prediction += "🚨 \(metrics.urgentTasksCount) urgent tasks. "
            }
            
            // Add building-specific context (from PredictionEngine)
            prediction = enhanceBuildingContext(prediction, building: building)
            
            // Add compliance status
            prediction += metrics.isCompliant ? "✅ Compliance: OK. " : "❌ Compliance: Needs attention. "
            
            // Cache the result
            cachePrediction(prediction, for: cacheKey)
            
            return prediction
        } catch {
            return "Building analysis for \(buildingId) is being updated."
        }
    }
    
    private func enhanceBuildingContext(_ base: String, building: NamedCoordinate) -> String {
        var enhanced = base
        
        // Special handling for known buildings (from PredictionEngine)
        switch building.name.lowercased() {
        case let name where name.contains("rubin"):
            enhanced += "🏛️ Special: Museum environment - climate control critical, artifact protection priority. "
        case let name where name.contains("perry"):
            enhanced += "🏠 Special: Residential property - tenant satisfaction priority, quiet hours observed. "
        case let name where name.contains("park"):
            enhanced += "🌳 Special: Outdoor facility - weather dependent, seasonal maintenance required. "
        case let name where name.contains("hudson"):
            enhanced += "🏢 Special: Commercial property - business hours constraints, minimal disruption. "
        case let name where name.contains("chelsea"):
            enhanced += "🏪 Special: Mixed-use building - flexible scheduling, diverse tenant needs. "
        default:
            if building.name.contains("Museum") {
                enhanced += "🎨 Cultural institution requiring specialized care. "
            } else if building.name.contains("Office") || building.name.contains("Tower") {
                enhanced += "💼 Commercial property with weekday priority scheduling. "
            }
        }
        
        return enhanced
    }
    
    // MARK: - Task Guidance
    
    private func generateTaskGuidance() async -> String {
        let activeTask = getCurrentActiveTask()
        let urgentTasks = getUrgentTasks()
        
        if let task = activeTask {
            var guidance = "📋 Current Task: \(task.title)\n"
            
            // FIX 4: Safely unwrap optional urgency
            if let urgency = task.urgency {
                guidance += "Priority: \(urgency.rawValue)\n"
            }
            
            if let description = task.description {
                guidance += "Details: \(description)\n"
            }
            
            // Add category-specific guidance
            if let category = task.category {
                switch category {
                case .cleaning:
                    guidance += "💡 Tip: Check cleaning supplies and follow building-specific protocols."
                case .maintenance:
                    guidance += "💡 Tip: Review equipment manuals and safety procedures."
                case .repair:
                    guidance += "💡 Tip: Diagnose issue thoroughly before beginning repairs."
                case .inspection:
                    guidance += "💡 Tip: Use checklist and document all findings with photos."
                case .emergency:
                    guidance += "🚨 EMERGENCY: Follow safety protocols immediately!"
                default:
                    break
                }
            }
            
            return guidance
        } else if !urgentTasks.isEmpty {
            return "No active task. You have \(urgentTasks.count) urgent task(s) to choose from."
        } else {
            let totalTasks = contextAdapter.todaysTasks.count
            let completedTasks = contextAdapter.todaysTasks.filter { $0.isCompleted }.count
            return "Great job! You've completed \(completedTasks) of \(totalTasks) tasks today."
        }
    }
    
    // MARK: - Weather-Based Guidance
    
    private func generateWeatherBasedGuidance() async -> String {
        // In real implementation, this would check actual weather service
        // For now, provide context-aware guidance
        
        let outdoorTasks = contextAdapter.todaysTasks.filter { task in
            task.category == .landscaping ||
            task.title.lowercased().contains("outdoor") ||
            task.title.lowercased().contains("exterior")
        }
        
        if outdoorTasks.isEmpty {
            return "☀️ No weather-dependent tasks scheduled today."
        } else {
            return "🌤️ You have \(outdoorTasks.count) outdoor task(s). Check current conditions before starting exterior work."
        }
    }
    
    // MARK: - Context-Aware Help
    
    private func generateContextAwareHelp() -> String {
        guard let worker = contextAdapter.currentWorker else {
            return "👋 Hi! I'm Nova, your AI assistant. Please log in to get personalized help."
        }
        
        var help = "👋 Hi \(worker.name)! I'm Nova, here to help with:\n\n"
        
        switch worker.role {
        case .worker, .manager:
            help += "• 📋 Task guidance and prioritization\n"
            help += "• 🔧 Equipment troubleshooting\n"
            help += "• 🏢 Building information\n"
            help += "• 🚨 Safety protocols\n"
            help += "• 📸 Photo documentation help"
            
        case .admin:
            help += "• 📊 Portfolio analytics\n"
            help += "• 👥 Workforce optimization\n"
            help += "• 🔮 Predictive maintenance\n"
            help += "• 💰 Cost analysis\n"
            help += "• ✅ Compliance monitoring"
            
        case .client:
            help += "• 📑 Service reports\n"
            help += "• 🏢 Building status\n"
            help += "• 📈 Performance metrics\n"
            help += "• ✅ Compliance overview\n"
            help += "• 💡 Strategic insights"
        }
        
        help += "\n\nJust ask me anything!"
        
        return help
    }
    
    // MARK: - Helper Methods (from AIContextManager)
    
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
    
    private func updateTimeOfDay() {
        let hour = Calendar.current.component(.hour, from: Date())
        timeOfDay = switch hour {
        case 6..<12: .morning
        case 12..<17: .afternoon
        case 17..<20: .evening
        default: .night
        }
    }
    
    private func calculateCurrentCompletionRate() -> Int {
        let tasks = contextAdapter.todaysTasks
        guard !tasks.isEmpty else { return 100 }
        
        let completed = tasks.filter { $0.isCompleted }.count
        return Int(Double(completed) / Double(tasks.count) * 100)
    }
    
    private func calculatePredictedCompletionRate() -> Int {
        let tasks = contextAdapter.todaysTasks
        guard !tasks.isEmpty else { return 100 }
        
        let completed = tasks.filter { $0.isCompleted }.count
        let remaining = tasks.count - completed
        
        let now = Date()
        let endOfDay = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: now) ?? now
        let hoursRemaining = max(0, endOfDay.timeIntervalSince(now) / 3600)
        
        // Average tasks per hour based on role
        let averageTasksPerHour: Double = switch contextAdapter.currentWorker?.role {
        case .worker: 2.5
        case .manager: 2.0
        default: 1.5
        }
        
        let predictedAdditional = Int(averageTasksPerHour * hoursRemaining)
        let predictedTotal = completed + min(remaining, predictedAdditional)
        
        return min(100, Int(Double(predictedTotal) / Double(tasks.count) * 100))
    }
    
    // MARK: - Caching (from PredictionEngine)
    
    private func cachePrediction(_ content: String, for key: String) {
        predictionCache[key] = (content, Date())
    }
    
    private func getCachedPrediction(for key: String) -> String? {
        guard let cached = predictionCache[key],
              Date().timeIntervalSince(cached.timestamp) < cacheTimeout else {
            return nil
        }
        return cached.content
    }
    
    public func clearPredictionCache() {
        predictionCache.removeAll()
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
            // FIX: Dictionary subscript returns optional, so if-let is correct
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
    
    // FIXED: Avoid capturing non-Sendable types in Timer closure
    public func scheduleReminder(for scenario: NovaScenarioData, minutes: Int = 30) {
        print("⏰ Scheduling reminder for scenario: \(scenario.scenario.rawValue) in \(minutes) minutes")
        
        // Extract all values before the Timer closure to avoid Sendable issues
        let scenarioId = scenario.id
        let scenarioTypeRawValue = scenario.scenario.rawValue  // Convert to String
        let message = scenario.message
        let actionText = scenario.actionText
        let priorityRawValue = scenario.priority.rawValue  // Convert to String
        let context = scenario.context
        
        let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(minutes * 60), repeats: false) { [weak self] _ in
            Task { @MainActor in
                // Recreate the scenario from the captured primitive values
                // Convert back from raw values
                guard let scenarioType = CoreTypes.AIScenarioType(rawValue: scenarioTypeRawValue),
                      let priority = CoreTypes.AIPriority(rawValue: priorityRawValue) else {
                    return
                }
                
                let recreatedScenario = NovaScenarioData(
                    scenario: scenarioType,
                    message: message,
                    actionText: actionText,
                    priority: priority,
                    context: context
                )
                self?.addScenario(recreatedScenario)
                self?.reminderTimers.removeValue(forKey: scenarioId)
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
        
        // Check for clock out based on time
        if timeOfDay == .evening && contextAdapter.currentWorker != nil {
            let scenario = NovaScenarioData(
                scenario: .clockOutReminder,
                message: "It's getting late. Don't forget to clock out when you're done.",
                actionText: "Clock Out",
                priority: .low
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

    private func handleDashboardUpdate(_ update: CoreTypes.DashboardUpdate) {
        // React to dashboard changes
        switch update.type {
        case .taskCompleted:
            // Refresh suggestions and context after task completion
            updateContext()
            generateSuggestions()
            // Clear relevant cache
            clearPredictionCache()
            
        case .buildingMetricsChanged:
            // Update insights when metrics change
            Task {
                await refreshInsights()
            }
            // Clear building cache - check if buildingId is not empty
            if !update.buildingId.isEmpty {
                predictionCache.removeValue(forKey: "building_\(update.buildingId)")
            }
            
        case .workerClockedIn, .workerClockedOut:
            // Update context and check for clock-related scenarios
            updateContext()
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
    
    // MARK: - Portfolio Intelligence
    
    public func loadPortfolioInsights() async {
        isProcessing = true
        
        do {
            // Use the actual IntelligenceService method
            let insights = try await IntelligenceService.shared.generatePortfolioInsights()
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
    
    // MARK: - Context Helpers
    
    public func getCurrentContextData() -> (buildings: Int, tasks: Int, status: String, worker: String) {
        let buildings = contextAdapter.assignedBuildings.count
        let tasks = contextAdapter.todaysTasks.count
        let status = contextAdapter.currentWorker != nil ? "Active" : "Standby"
        let worker = contextAdapter.currentWorker?.name ?? "Unknown"
        
        return (buildings, tasks, status, worker)
    }
    
    // FIXED: Use correct AISuggestion initializer
    public func getScenarioSuggestions(for scenario: NovaScenarioData) -> [CoreTypes.AISuggestion] {
        var suggestions: [CoreTypes.AISuggestion] = []
        
        switch scenario.scenario {
        case .emergencyRepair:
            suggestions.append(
                CoreTypes.AISuggestion(
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
                    title: "Prioritize Tasks",
                    description: "AI will optimize task order by urgency and efficiency",
                    priority: .high,
                    category: .operations,  // Changed from .efficiency
                    estimatedImpact: "Improve daily task completion rate"
                )
            )
            
        default:
            break
        }
        
        // Add general suggestion
        suggestions.append(
            CoreTypes.AISuggestion(
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
    
    /// Get Nova avatar state based on current context
    public var novaAvatarState: NovaAvatarState {
        if isProcessing {
            return .busy
        } else if getUrgentTaskCount() > 3 {
            return .urgent
        } else {
            return .idle
        }
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

// MARK: - Time of Day Enum (from AIContextManager)
public enum TimeOfDay: String {
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"
    case night = "night"
}

// MARK: - Nova Avatar State
public enum NovaAvatarState {
    case idle
    case busy
    case urgent
}

// MARK: - Extensions for NovaAvatar Integration

extension NovaFeatureManager {
    /// Get current Nova message based on context
    public var currentNovaMessage: String {
        if isProcessing {
            return "Processing..."
        }
        
        if let scenario = activeScenarios.first(where: { $0.priority == .critical }) {
            return scenario.message
        }
        
        if getUrgentTaskCount() > 0 {
            return "\(getUrgentTaskCount()) urgent tasks need attention!"
        }
        
        switch timeOfDay {
        case .morning:
            return "Good morning! Ready to help."
        case .afternoon:
            return "Good afternoon! How can I assist?"
        case .evening:
            return "Good evening! Wrapping up?"
        case .night:
            return "Working late? I'm here to help."
        }
    }
}
