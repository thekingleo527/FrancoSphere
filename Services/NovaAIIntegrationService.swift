//
//  NovaAIIntegrationService.swift
//  FrancoSphere v6.0
//
//  ✅ NOVA AI: Complete integration with existing services
//  ✅ REAL-TIME: Context synchronization with task data
//  ✅ INSIGHTS: AI-powered recommendations across dashboards
//

import Foundation
import Combine

@MainActor
public class NovaAIIntegrationService: ObservableObject {
    public static let shared = NovaAIIntegrationService()
    
    // MARK: - Dependencies
    private let novaCore = NovaCore.shared
    private let intelligenceService = IntelligenceService.shared
    private let taskService = TaskService.shared
    private let buildingService = BuildingService.shared
    
    // MARK: - Published State
    @Published public var isConnected = false
    @Published public var lastSyncTime: Date?
    @Published public var aiInsights: [CoreTypes.IntelligenceInsight] = []
    @Published public var contextSummary: String = "Initializing Nova AI..."
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupRealTimeIntegration()
    }
    
    // MARK: - Public Interface
    
    /// Initialize Nova AI with current portfolio context
    public func initializeAI() async {
        do {
            // Get current portfolio data
            let buildings = await buildingService.getAllBuildings()
            let tasks = await taskService.getAllTasks()
            
            // Initialize Nova AI context
            await novaCore.initializeContext(buildings: buildings, tasks: tasks)
            
            isConnected = true
            lastSyncTime = Date()
            contextSummary = "Nova AI connected - \(buildings.count) buildings, \(tasks.count) tasks"
            
            log_info("Nova AI initialized with \(buildings.count) buildings and \(tasks.count) tasks")
            
            // Generate initial insights
            await generateInsights()
            
        } catch {
            log_error("Failed to initialize Nova AI: \(error)")
            isConnected = false
        }
    }
    
    /// Generate AI insights for all buildings
    public func generateInsights() async {
        guard isConnected else {
            await initializeAI()
            return
        }
        
        do {
            let generatedInsights = await novaCore.generateInsights()
            
            // Convert Nova insights to CoreTypes format
            aiInsights = generatedInsights.map { novaInsight in
                CoreTypes.IntelligenceInsight(
                    id: UUID().uuidString,
                    title: novaInsight.title,
                    description: novaInsight.description,
                    priority: mapNovaPriority(novaInsight.priority),
                    category: mapNovaCategory(novaInsight.category),
                    source: .ai,
                    confidence: novaInsight.confidence,
                    buildingIds: novaInsight.buildingIds,
                    estimatedImpact: novaInsight.estimatedImpact
                )
            }
            
            lastSyncTime = Date()
            log_success("Generated \(aiInsights.count) AI insights")
            
        } catch {
            log_error("Failed to generate AI insights: \(error)")
        }
    }
    
    /// Sync real-time task completion data with Nova AI
    public func syncTaskCompletion(taskId: String, buildingId: String) async {
        guard isConnected else { return }
        
        await novaCore.updateTaskContext(taskId: taskId, buildingId: buildingId, completed: true)
        await generateInsights() // Regenerate insights with new context
    }
    
    /// Get building-specific AI recommendations
    public func getBuildingRecommendations(buildingId: String) async -> [CoreTypes.AISuggestion] {
        guard isConnected else { return [] }
        
        let novaRecommendations = await novaCore.getRecommendations(for: buildingId)
        
        return novaRecommendations.map { novaRec in
            CoreTypes.AISuggestion(
                id: UUID().uuidString,
                title: novaRec.title,
                description: novaRec.description,
                priority: mapNovaPriority(novaRec.priority),
                category: novaRec.category,
                estimatedImpact: novaRec.estimatedImpact,
                buildingId: buildingId
            )
        }
    }
    
    // MARK: - Private Helpers
    
    private func setupRealTimeIntegration() {
        // Listen for task completions
        NotificationCenter.default.publisher(for: .taskCompleted)
            .sink { [weak self] notification in
                guard let self = self,
                      let taskId = notification.userInfo?["taskId"] as? String,
                      let buildingId = notification.userInfo?["buildingId"] as? String else { return }
                
                Task {
                    await self.syncTaskCompletion(taskId: taskId, buildingId: buildingId)
                }
            }
            .store(in: &cancellables)
        
        // Auto-refresh insights every 30 minutes
        Timer.publish(every: 1800, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.generateInsights()
                }
            }
            .store(in: &cancellables)
    }
    
    private func mapNovaPriority(_ novaPriority: String) -> CoreTypes.AIPriority {
        switch novaPriority.lowercased() {
        case "critical": return .critical
        case "high": return .high
        case "medium": return .medium
        default: return .low
        }
    }
    
    private func mapNovaCategory(_ novaCategory: String) -> CoreTypes.InsightCategory {
        switch novaCategory.lowercased() {
        case "efficiency": return .efficiency
        case "maintenance": return .maintenance
        case "compliance": return .compliance
        case "cost": return .cost
        case "performance": return .performance
        default: return .risk
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let taskCompleted = Notification.Name("taskCompleted")
    static let buildingUpdated = Notification.Name("buildingUpdated")
    static let novaInsightsUpdated = Notification.Name("novaInsightsUpdated")
}
