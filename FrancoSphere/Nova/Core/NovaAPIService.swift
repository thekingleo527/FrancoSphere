//
//  NovaAPIService.swift
//  CyntientOps v6.0
//
//  Nova API Service with domain knowledge about Kevin Dutan, Rubin Museum, and portfolio
//  ✅ UPDATED: Removed NovaContextEngine dependency
//  ✅ ENHANCED: Direct context generation without external dependencies
//  ✅ INTEGRATED: Works with NovaFeatureManager for comprehensive AI support
//  ✅ FIXED: All compilation errors resolved
//

import Foundation
import SwiftUI

/// Nova API Service for processing prompts and generating responses
public actor NovaAPIService {
    public static let shared = NovaAPIService()
    
    // MARK: - Dependencies
    private let intelligenceService = IntelligenceService.shared
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    
    // MARK: - Configuration
    private let processingTimeout: TimeInterval = 30.0
    private let maxRetries = 3
    
    // MARK: - Portfolio Constants (Domain Knowledge)
    private let BUILDING_COUNT = 18
    private let WORKER_COUNT = 8
    private let TASK_COUNT = 150
    
    // MARK: - Processing State
    private var isProcessing = false
    private var processingQueue: [NovaPrompt] = []
    
    private init() {}
    
    // MARK: - Public API
    
    /// Process a Nova prompt and generate intelligent response
    public func processPrompt(_ prompt: NovaPrompt) async throws -> NovaResponse {
        guard !isProcessing else {
            throw NovaAPIError.processingInProgress
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            print("🧠 Processing Nova prompt: \(prompt.text)")
            
            // Get context for the prompt
            let context = await getOrCreateContext(for: prompt)
            
            // Generate response based on prompt type and context
            let response = try await generateResponse(for: prompt, context: context)
            
            print("✅ Nova response generated successfully")
            return response
            
        } catch {
            print("❌ Nova processing failed: \(error)")
            throw error
        }
    }
    
    /// Check if Nova is currently processing
    public func isCurrentlyProcessing() -> Bool {
        return isProcessing
    }
    
    /// Get processing queue status
    public func getQueueStatus() -> Int {
        return processingQueue.count
    }
    
    // MARK: - Context Management (Enhanced without NovaContextEngine)
    
    private func getOrCreateContext(for prompt: NovaPrompt) async -> NovaContext {
        // Use existing context if available
        if let context = prompt.context {
            return context
        }
        
        // Generate new context based on prompt content and current data
        return await generateEnhancedContext(for: prompt.text)
    }
    
    private func generateEnhancedContext(for text: String) async -> NovaContext {
        // Analyze prompt for context clues
        let contextType = determineContextType(from: text)
        
        // Gather real-time data
        var contextData: [String: String] = [:]
        var insights: [String] = []
        
        do {
            // Get current worker context if available
            if let currentWorker = await WorkerContextEngineAdapter.shared.currentWorker {
                contextData["workerId"] = currentWorker.id
                contextData["workerName"] = currentWorker.name
                contextData["workerRole"] = currentWorker.role.rawValue
                insights.append("Worker context: \(currentWorker.name)")
            }
            
            // Get building context if mentioned
            if text.lowercased().contains("building") || text.lowercased().contains("rubin") {
                let buildings = try await buildingService.getAllBuildings()
                contextData["totalBuildings"] = "\(buildings.count)"
                
                if let rubin = buildings.first(where: { $0.name.contains("Rubin") }) {
                    contextData["rubinBuildingId"] = rubin.id
                    insights.append("Rubin Museum context available")
                }
            }
            
            // Get task context if relevant
            if text.lowercased().contains("task") {
                let tasks = try await taskService.getAllTasks()
                contextData["totalTasks"] = "\(tasks.count)"
                
                let urgentTasks = tasks.filter {
                    guard let urgency = $0.urgency else { return false }
                    return urgency == .urgent || urgency == .critical
                }
                if !urgentTasks.isEmpty {
                    contextData["urgentTaskCount"] = "\(urgentTasks.count)"
                    insights.append("\(urgentTasks.count) urgent tasks detected")
                }
            }
            
        } catch {
            print("⚠️ Error gathering context data: \(error)")
        }
        
        // Build comprehensive context
        // FIX 1: Pass dictionary directly to data parameter
        return NovaContext(
            data: contextData,  // Already a [String: String]
            insights: insights,
            metadata: [
                "contextType": contextType.rawValue,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ],
            userRole: await WorkerContextEngineAdapter.shared.currentWorker?.role,
            buildingContext: contextData["rubinBuildingId"],
            taskContext: contextType == .task ? text : nil
        )
    }
    
    private func buildContextDescription(type: ContextType, contextData: [String: String]) async -> String {
        var description = "Context type: \(type). "
        
        if let workerName = contextData["workerName"] {
            description += "Worker: \(workerName). "
        }
        
        if let buildings = contextData["totalBuildings"] {
            description += "Portfolio: \(buildings) buildings. "
        }
        
        if let tasks = contextData["totalTasks"] {
            description += "Tasks: \(tasks) total. "
        }
        
        if let urgent = contextData["urgentTaskCount"] {
            description += "Urgent: \(urgent) tasks. "
        }
        
        return description
    }
    
    // MARK: - Response Generation
    
    private func generateResponse(for prompt: NovaPrompt, context: NovaContext) async throws -> NovaResponse {
        let responseText = try await generateResponseText(for: prompt, context: context)
        let insights = try await generateInsights(for: prompt, context: context)
        let actions = try await generateActions(for: prompt, context: context)
        
        return NovaResponse(
            success: true,
            message: responseText,
            insights: insights,
            actions: actions,
            context: context,
            metadata: ["processedAt": ISO8601DateFormatter().string(from: Date())]
        )
    }
    
    private func generateResponseText(for prompt: NovaPrompt, context: NovaContext) async throws -> String {
        let promptText = prompt.text.lowercased()
        
        // Building-related queries
        if promptText.contains("building") || promptText.contains("rubin") || promptText.contains("museum") {
            return await generateBuildingResponse(prompt: promptText, context: context)
        }
        
        // Worker-related queries
        if promptText.contains("worker") || promptText.contains("kevin") || promptText.contains("schedule") {
            return await generateWorkerResponse(prompt: promptText, context: context)
        }
        
        // Task-related queries
        if promptText.contains("task") || promptText.contains("complete") || promptText.contains("todo") {
            return await generateTaskResponse(prompt: promptText, context: context)
        }
        
        // Portfolio-related queries
        if promptText.contains("portfolio") || promptText.contains("overview") || promptText.contains("metrics") {
            return await generatePortfolioResponse(prompt: promptText, context: context)
        }
        
        // General conversational response
        return await generateGeneralResponse(prompt: promptText, context: context)
    }
    
    // MARK: - Specific Response Generators (PRESERVED FROM ORIGINAL)
    
    private func generateBuildingResponse(prompt: String, context: NovaContext) async -> String {
        if prompt.contains("rubin") {
            return """
            The Rubin Museum is one of our key properties with specialized requirements. Kevin Dutan is the primary specialist for this building, handling approximately \(TASK_COUNT) tasks across the museum's unique operational needs. The building requires careful attention to climate control and security protocols for the art collection.
            """
        }
        
        return """
        We manage \(BUILDING_COUNT) buildings in our portfolio. Each building has specific operational requirements and assigned specialist workers. Would you like information about a specific building or general portfolio metrics?
        """
    }
    
    private func generateWorkerResponse(prompt: String, context: NovaContext) async -> String {
        if prompt.contains("kevin") {
            return """
            Kevin Dutan is our museum and property specialist, primarily responsible for the Rubin Museum and several other key buildings. He manages complex tasks requiring specialized knowledge of museum operations, climate control, and security protocols. His expertise is essential for maintaining our art-related properties.
            """
        }
        
        return """
        Our team includes \(WORKER_COUNT) active workers, each with specialized skills and building assignments. Workers are assigned based on their expertise and the specific needs of each property. Would you like information about a specific worker or team assignments?
        """
    }
    
    private func generateTaskResponse(prompt: String, context: NovaContext) async -> String {
        // Enhanced with real-time data if available
        var response = "Currently tracking \(TASK_COUNT) tasks across our portfolio. "
        
        if let urgentCount = context.metadata["urgentTaskCount"] {
            response += "⚠️ \(urgentCount) tasks require urgent attention. "
        }
        
        response += "Tasks are prioritized by urgency and building requirements. Our system ensures efficient allocation based on worker expertise and building needs. Would you like to see pending tasks or completion statistics?"
        
        return response
    }
    
    private func generatePortfolioResponse(prompt: String, context: NovaContext) async -> String {
        return """
        Portfolio Overview:
        • Buildings: \(BUILDING_COUNT) properties under management
        • Active Workers: \(WORKER_COUNT) specialized team members
        • Current Tasks: \(TASK_COUNT) active assignments
        
        Our portfolio spans diverse property types from residential to specialized facilities like the Rubin Museum. Each property receives tailored management based on its unique operational requirements.
        """
    }
    
    private func generateGeneralResponse(prompt: String, context: NovaContext) async -> String {
        var response = "I'm Nova, your intelligent portfolio assistant. "
        
        // Add personalized greeting if we have worker context
        if let workerName = context.metadata["workerName"] {
            response = "Hello \(workerName)! " + response
        }
        
        response += """
        I can help you with:
        
        • Building information and management
        • Worker assignments and schedules
        • Task tracking and completion
        • Portfolio metrics and insights
        • Operational efficiency analysis
        
        What would you like to know about your portfolio operations?
        """
        
        return response
    }
    
    // MARK: - Insight Generation
    
    private func generateInsights(for prompt: NovaPrompt, context: NovaContext) async throws -> [NovaInsight] {
        var insights: [NovaInsight] = []
        
        // Generate insights based on context and prompt
        do {
            // Try to get real insights from IntelligenceService
            if let buildingId = context.buildingContext {
                let buildingInsights = try await intelligenceService.generateBuildingInsights(for: buildingId)
                insights.append(contentsOf: buildingInsights)
            } else {
                // Get portfolio insights
                let portfolioInsights = try await intelligenceService.generatePortfolioInsights()
                insights.append(contentsOf: portfolioInsights.prefix(3)) // Top 3 insights
            }
        } catch {
            // FIX 2 & 3: Use correct IntelligenceInsight initializer
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Portfolio Analysis",
                description: "AI-powered insights available for deeper analysis",
                type: .operations,  // Valid InsightCategory case
                priority: .medium,
                actionRequired: false
            ))
        }
        
        return insights
    }
    
    // MARK: - Action Generation
    
    private func generateActions(for prompt: NovaPrompt, context: NovaContext) async throws -> [NovaAction] {
        var actions: [NovaAction] = []
        
        let promptText = prompt.text.lowercased()
        
        // Building-related actions
        if promptText.contains("building") {
            actions.append(NovaAction(
                title: "View Building Details",
                description: "Access complete building information and metrics",
                actionType: .navigate,
                priority: .medium
            ))
            
            if context.buildingContext != nil {
                actions.append(NovaAction(
                    title: "Building Analytics",
                    description: "View detailed analytics for this building",
                    actionType: .analysis,
                    priority: .high
                ))
            }
        }
        
        // Task-related actions
        if promptText.contains("task") {
            actions.append(NovaAction(
                title: "View Tasks",
                description: "Navigate to task management interface",
                actionType: .navigate,
                priority: .medium
            ))
            
            if let urgentCount = context.metadata["urgentTaskCount"], Int(urgentCount) ?? 0 > 0 {
                actions.append(NovaAction(
                    title: "Review Urgent Tasks",
                    description: "\(urgentCount) tasks need immediate attention",
                    actionType: .review,
                    priority: .critical
                ))
            }
        }
        
        // Schedule-related actions
        if promptText.contains("schedule") || promptText.contains("assign") {
            actions.append(NovaAction(
                title: "Optimize Schedule",
                description: "Analyze current schedules for optimization opportunities",
                actionType: .schedule,
                priority: .medium
            ))
        }
        
        // Worker-specific actions
        if context.userRole == .worker || context.userRole == .manager {
            actions.append(NovaAction(
                title: "My Tasks",
                description: "View your assigned tasks",
                actionType: .navigate,
                priority: .high,
                parameters: ["workerId": context.data["workerId"] ?? ""]
            ))
        }
        
        // Always include help action
        actions.append(NovaAction(
            title: "Get Help",
            description: "Access Nova AI documentation and features",
            actionType: .review,
            priority: .low
        ))
        
        return actions
    }
    
    // MARK: - Context Type Determination
    
    private func determineContextType(from text: String) -> ContextType {
        let lowerText = text.lowercased()
        
        if lowerText.contains("building") || lowerText.contains("rubin") || lowerText.contains("museum") {
            return .building
        }
        
        if lowerText.contains("worker") || lowerText.contains("kevin") || lowerText.contains("team") {
            return .worker
        }
        
        if lowerText.contains("portfolio") || lowerText.contains("overview") || lowerText.contains("metrics") {
            return .portfolio
        }
        
        if lowerText.contains("task") || lowerText.contains("complete") || lowerText.contains("todo") {
            return .task
        }
        
        return .general
    }
}

// MARK: - Supporting Types

private enum ContextType: String {
    case building = "building"
    case worker = "worker"
    case portfolio = "portfolio"
    case task = "task"
    case general = "general"
}

// MARK: - Error Types

public enum NovaAPIError: Error, LocalizedError {
    case processingInProgress
    case contextGenerationFailed
    case responseGenerationFailed
    case timeout
    case invalidPrompt
    
    public var errorDescription: String? {
        switch self {
        case .processingInProgress:
            return "Nova is currently processing another request"
        case .contextGenerationFailed:
            return "Failed to generate context for prompt"
        case .responseGenerationFailed:
            return "Failed to generate response"
        case .timeout:
            return "Request timed out"
        case .invalidPrompt:
            return "Invalid prompt provided"
        }
    }
}

// MARK: - Future API Integration
extension NovaAPIService {
    
    /// Placeholder for future OpenAI/Claude API integration
    private func callExternalAPI(prompt: String) async throws -> String {
        // Future implementation:
        // 1. Format prompt for API
        // 2. Make API call
        // 3. Parse response
        // 4. Return formatted result
        
        return "API response placeholder"
    }
    
    /// Prepare for streaming responses
    public func streamResponse(for prompt: NovaPrompt) async throws -> AsyncStream<String> {
        return AsyncStream { continuation in
            Task {
                // Future: Stream responses from API
                continuation.yield("Streaming response coming soon...")
                continuation.finish()
            }
        }
    }
    
    /// Generate response using NovaFeatureManager's enhanced capabilities
    public func processWithFeatureManager(_ query: String) async -> NovaResponse {
        // This allows NovaFeatureManager to use the API service
        let prompt = NovaPrompt(
            text: query,
            priority: .medium,
            metadata: ["source": "feature_manager"]
        )
        
        do {
            return try await processPrompt(prompt)
        } catch {
            return NovaResponse(
                success: false,
                message: "Unable to process request: \(error.localizedDescription)",
                metadata: ["error": "true"]
            )
        }
    }
}
