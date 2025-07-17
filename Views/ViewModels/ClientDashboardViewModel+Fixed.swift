//
//  ClientDashboardViewModel+Fixed.swift
//  FrancoSphere v6.0 - FIXED: Uses intelligence with OperationalDataManager fallback
//

import Foundation

extension ClientDashboardViewModel {
    
    /// FIXED: Load portfolio intelligence with operational fallback
    func loadPortfolioIntelligenceFixed() async {
        await MainActor.run {
            isLoadingInsights = true
        }
        
        do {
            // Use FIXED intelligence service with operational fallback
            let insights = try await intelligenceService.generatePortfolioInsightsWithFallback()
            let portfolioIntel = try await generateFixedPortfolioIntelligence()
            
            await MainActor.run {
                self.intelligenceInsights = insights
                self.portfolioIntelligence = portfolioIntel
                self.isLoadingInsights = false
            }
            
            print("✅ FIXED portfolio intelligence loaded: \(insights.count) insights")
            broadcastCrossDashboardUpdate(.insightsUpdated(count: insights.count))
            
        } catch {
            await MainActor.run {
                self.isLoadingInsights = false
            }
            print("⚠️ Fixed intelligence loading failed, using fallback: \(error)")
            
            // Fallback: Generate basic insights from operational data
            await generateFallbackInsights()
        }
    }
    
    private func generateFixedPortfolioIntelligence() async throws -> CoreTypes.PortfolioIntelligence {
        let buildingService = BuildingService.shared
        let workerService = WorkerService.shared
        let taskService = TaskService.shared
        
        // Get data with fallbacks
        let buildings = try await buildingService.getAllBuildings()
        let workers = try await workerService.getAllActiveWorkers()
        
        var tasks: [ContextualTask] = []
        do {
            tasks = try await taskService.getAllTasksWithOperationalFallback()
        } catch {
            print("⚠️ Task loading failed: \(error)")
        }
        
        // Calculate metrics
        let completedTasks = tasks.filter { $0.isCompleted }.count
        let completionRate = tasks.count > 0 ? Double(completedTasks) / Double(tasks.count) : 0.0
        let urgentTasks = tasks.filter { $0.urgency == .critical || $0.urgency == .urgent }.count
        let overdueTasks = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return !task.isCompleted && dueDate < Date()
        }.count
        
        return CoreTypes.PortfolioIntelligence(
            totalBuildings: buildings.count,
            activeWorkers: workers.count,
            completionRate: completionRate,
            efficiency: max(0.0, completionRate - (Double(overdueTasks) * 0.1)),
            urgentTasks: urgentTasks,
            overdueTasks: overdueTasks,
            lastUpdated: Date()
        )
    }
    
    private func generateFallbackInsights() async {
        let operationalData = OperationalDataManager.shared
        let realTasks = await operationalData.realWorldTasks
        
        var fallbackInsights: [CoreTypes.IntelligenceInsight] = []
        
        // Basic operational insight
        fallbackInsights.append(CoreTypes.IntelligenceInsight(
            title: "Portfolio Operating from Operational Data",
            description: "System is using \(realTasks.count) operational tasks across the portfolio. Database integration in progress.",
            type: .performance,
            priority: .medium,
            actionRequired: false,
            affectedBuildings: []
        ))
        
        // Worker distribution insight
        let workerDistribution = await operationalData.getWorkerTaskDistribution()
        let busyWorkers = workerDistribution.filter { $1 > 10 }
        
        if !busyWorkers.isEmpty {
            let workerList = busyWorkers.map { "\($0.key) (\($0.value) tasks)" }.joined(separator: ", ")
            fallbackInsights.append(CoreTypes.IntelligenceInsight(
                title: "High Activity Workers",
                description: "Workers with significant task loads: \(workerList)",
                type: .efficiency,
                priority: .low,
                actionRequired: false,
                affectedBuildings: []
            ))
        }
        
        await MainActor.run {
            self.intelligenceInsights = fallbackInsights
            self.isLoadingInsights = false
        }
        
        print("✅ Fallback insights generated: \(fallbackInsights.count)")
    }
}
