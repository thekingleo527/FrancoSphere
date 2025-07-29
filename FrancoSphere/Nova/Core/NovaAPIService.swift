//
//  NovaAPIService.swift
//  FrancoSphere v6.0
//
//  Nova API Service with domain knowledge about Kevin Dutan, Rubin Museum, and portfolio
//  Simplified to resolve compilation errors with multiple NovaTypes definitions
//

import Foundation
import SwiftUI

/// Nova API Service for processing prompts and generating responses
public actor NovaAPIService {
    public static let shared = NovaAPIService()
    
    // MARK: - Dependencies
    private let contextEngine = NovaContextEngine.shared
    private let intelligenceService = IntelligenceService.shared
    
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
    
    // MARK: - Context Management
    
    private func getOrCreateContext(for prompt: NovaPrompt) async -> NovaContext {
        // Use existing context if available
        if let context = prompt.context {
            return context
        }
        
        // Generate new context based on prompt content
        return await generateContextualResponse(for: prompt.text)
    }
    
    private func generateContextualResponse(for text: String) async -> NovaContext {
        // Analyze prompt for context clues
        let contextType = determineContextType(from: text)
        
        switch contextType {
        case .building:
            return await generateBuildingContext(from: text)
        case .worker:
            return await generateWorkerContext(from: text)
        case .portfolio:
            return await generatePortfolioContext(from: text)
        case .task:
            return await generateTaskContext(from: text)
        case .general:
            return await generateGeneralContext(from: text)
        }
    }
    
    // MARK: - Response Generation
    
    private func generateResponse(for prompt: NovaPrompt, context: NovaContext) async throws -> NovaResponse {
        let responseText = try await generateResponseText(for: prompt, context: context)
        let insights = try await generateInsights(for: prompt, context: context)
        let actions = try await generateActions(for: prompt, context: context)
        
        return NovaResponse(
            success: true,
            message: responseText,
            actions: actions,
            insights: insights
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
        return """
        Currently tracking \(TASK_COUNT) tasks across our portfolio. Tasks are prioritized by urgency and building requirements. Our system ensures efficient allocation based on worker expertise and building needs. Would you like to see pending tasks or completion statistics?
        """
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
        return """
        I'm Nova, your intelligent portfolio assistant. I can help you with:
        
        • Building information and management
        • Worker assignments and schedules
        • Task tracking and completion
        • Portfolio metrics and insights
        • Operational efficiency analysis
        
        What would you like to know about your portfolio operations?
        """
    }
    
    // MARK: - Insight Generation
    
    private func generateInsights(for prompt: NovaPrompt, context: NovaContext) async throws -> [NovaInsight] {
        // Return empty array until we resolve which NovaInsight type definition to use
        // The project has multiple conflicting NovaTypes.swift files
        return []
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
                actionType: .navigate
            ))
        }
        
        // Task-related actions
        if promptText.contains("task") {
            actions.append(NovaAction(
                title: "View Tasks",
                description: "Navigate to task management interface",
                actionType: .navigate
            ))
        }
        
        // Schedule-related actions
        if promptText.contains("schedule") || promptText.contains("assign") {
            actions.append(NovaAction(
                title: "Optimize Schedule",
                description: "Analyze current schedules for optimization opportunities",
                actionType: .schedule
            ))
        }
        
        // General help action
        actions.append(NovaAction(
            title: "Get Help",
            description: "Access Nova AI documentation and features",
            actionType: .review
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
    
    // MARK: - Context Generators (Enhanced with Domain Knowledge)
    
    private func generateBuildingContext(from text: String) async -> NovaContext {
        var insights = ["Building operations analysis", "Specialized requirements assessment"]
        
        // Add Rubin Museum specific insights if mentioned
        if text.lowercased().contains("rubin") {
            insights.append("Museum climate control requirements")
            insights.append("Security protocol compliance")
        }
        
        return NovaContext(
            data: "Building management context with portfolio overview - Building ID: 14 (Rubin Museum)",
            insights: insights,
            metadata: [
                "context_type": "building",
                "source": "portfolio_data",
                "specialization": "museum_operations",
                "buildingId": "14"
            ]
        )
    }
    
    private func generateWorkerContext(from text: String) async -> NovaContext {
        var insights = ["Worker specialization analysis", "Assignment optimization"]
        
        // Add Kevin-specific insights if mentioned
        if text.lowercased().contains("kevin") {
            insights.append("Museum specialist expertise")
            insights.append("Multi-building coverage analysis")
        }
        
        return NovaContext(
            data: "Worker management context - Worker ID: 4 (Kevin Dutan) - Museum Specialist",
            insights: insights,
            metadata: [
                "context_type": "worker",
                "source": "team_data",
                "specialization": "museum_operations",
                "workerId": "4",
                "workerName": "Kevin Dutan"
            ]
        )
    }
    
    private func generatePortfolioContext(from text: String) async -> NovaContext {
        return NovaContext(
            data: "Portfolio management context - \(BUILDING_COUNT) buildings, \(WORKER_COUNT) workers, \(TASK_COUNT) tasks",
            insights: [
                "Portfolio performance analysis",
                "Operational efficiency metrics",
                "Resource utilization patterns"
            ],
            metadata: [
                "context_type": "portfolio",
                "source": "aggregate_data",
                "buildingCount": String(BUILDING_COUNT),
                "workerCount": String(WORKER_COUNT),
                "taskCount": String(TASK_COUNT)
            ]
        )
    }
    
    private func generateTaskContext(from text: String) async -> NovaContext {
        return NovaContext(
            data: "Task management context - \(TASK_COUNT) total tasks across portfolio",
            insights: ["Task distribution analysis", "Priority optimization"],
            metadata: [
                "context_type": "task",
                "source": "task_data",
                "totalTasks": String(TASK_COUNT)
            ]
        )
    }
    
    private func generateGeneralContext(from text: String) async -> NovaContext {
        return NovaContext(
            data: "General assistance context - Query: \(text)",
            insights: ["System features overview", "Available assistance options"],
            metadata: [
                "context_type": "general",
                "source": "system_info",
                "originalQuery": text
            ]
        )
    }
}

// MARK: - Supporting Types

private enum ContextType {
    case building
    case worker
    case portfolio
    case task
    case general
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
}
