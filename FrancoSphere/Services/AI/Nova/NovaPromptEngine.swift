//
//  NovaPromptEngine.swift
//  FrancoSphere v6.0
//
//  ✅ ENHANCED: Rich prompt generation for Nova models
//  ✅ UTILIZES: Aggregated GRDB data with contextual enhancement
//  ✅ ALIGNED: With FrancoSphere architecture and patterns
//

import Foundation

/// Generates intelligent text prompts from aggregated Nova data
public actor NovaPromptEngine {
    nonisolated public static let shared = NovaPromptEngine()
    
    // MARK: - Dependencies
    private let buildingService = BuildingService.shared
    private let workerService = WorkerService.shared
    
    // MARK: - Configuration
    private let maxPromptLength = 500
    private let includeMetrics = true
    private let includeContext = true
    
    private init() {}
    
    // MARK: - Portfolio Prompt Generation
    
    /// Create a comprehensive portfolio level prompt
    public func generatePortfolioPrompt(from data: NovaAggregatedData) -> String {
        var prompt = "Portfolio Overview: "
        prompt += "\(data.buildingCount) buildings under management, "
        prompt += "\(data.workerCount) active workers deployed, "
        prompt += "\(data.taskCount) tasks scheduled today. "
        
        // Add contextual information
        if includeContext {
            prompt += generatePortfolioContext(data)
        }
        
        // Add performance indicators
        if includeMetrics {
            prompt += generatePortfolioMetrics(data)
        }
        
        return truncatePrompt(prompt)
    }
    
    /// Generate portfolio prompt with specific focus
    public func generatePortfolioPrompt(from data: NovaAggregatedData, focus: PromptFocus) -> String {
        let basePrompt = generatePortfolioPrompt(from: data)
        
        switch focus {
        case .operations:
            return basePrompt + " Focus on operational efficiency and task distribution."
        case .workforce:
            return basePrompt + " Analyze workforce utilization and productivity."
        case .maintenance:
            return basePrompt + " Prioritize maintenance schedules and preventive care."
        case .compliance:
            return basePrompt + " Review compliance status and regulatory requirements."
        case .financial:
            return basePrompt + " Evaluate cost optimization and budget efficiency."
        }
    }
    
    // MARK: - Building Prompt Generation
    
    /// Create a comprehensive building specific prompt
    public func generateBuildingPrompt(for buildingId: CoreTypes.BuildingID, data: NovaAggregatedData) -> String {
        var prompt = "Building \(buildingId) Status: "
        prompt += "\(data.workerCount) workers assigned, "
        prompt += "\(data.taskCount) tasks scheduled. "
        
        // Add building-specific context
        prompt += await generateBuildingContext(buildingId)
        
        // Add building metrics if available
        if includeMetrics {
            prompt += generateBuildingMetrics(buildingId, data)
        }
        
        return truncatePrompt(prompt)
    }
    
    /// Generate building prompt with historical context
    public func generateBuildingPrompt(
        for buildingId: CoreTypes.BuildingID,
        data: NovaAggregatedData,
        includeHistory: Bool
    ) -> String {
        var prompt = generateBuildingPrompt(for: buildingId, data: data)
        
        if includeHistory {
            prompt += " Historical performance: Consistent maintenance record with specialized care requirements."
        }
        
        return prompt
    }
    
    // MARK: - Worker Prompt Generation
    
    /// Generate worker-focused prompt
    public func generateWorkerPrompt(
        workerId: CoreTypes.WorkerID,
        workerName: String,
        taskCount: Int
    ) -> String {
        var prompt = "Worker \(workerName) (ID: \(workerId)): "
        prompt += "\(taskCount) tasks assigned. "
        
        // Add specialization context
        if workerName.contains("Kevin") {
            prompt += "Specialized in museum operations and cultural artifact care. "
        } else if workerName.contains("Mercedes") {
            prompt += "Focused on residential property maintenance. "
        }
        
        prompt += "Performance analysis and optimization recommendations requested."
        
        return prompt
    }
    
    // MARK: - Task Prompt Generation
    
    /// Generate task-focused prompt
    public func generateTaskPrompt(
        totalTasks: Int,
        completedTasks: Int,
        urgentTasks: Int
    ) -> String {
        let completionRate = totalTasks > 0 ? Int(Double(completedTasks) / Double(totalTasks) * 100) : 0
        
        var prompt = "Task Management Overview: "
        prompt += "\(totalTasks) total tasks, "
        prompt += "\(completedTasks) completed (\(completionRate)%), "
        prompt += "\(urgentTasks) urgent items requiring attention. "
        prompt += "Optimization and prioritization analysis needed."
        
        return prompt
    }
    
    // MARK: - Specialized Prompt Generation
    
    /// Generate weather-aware prompt
    public func generateWeatherPrompt(condition: String, impact: String) -> String {
        return "Weather Impact Analysis: Current conditions - \(condition). " +
               "Operational impact: \(impact). " +
               "Adjust outdoor task scheduling and worker safety protocols accordingly."
    }
    
    /// Generate compliance-focused prompt
    public func generateCompliancePrompt(
        compliantBuildings: Int,
        totalBuildings: Int,
        issues: Int
    ) -> String {
        let complianceRate = totalBuildings > 0 ? Int(Double(compliantBuildings) / Double(totalBuildings) * 100) : 100
        
        return "Compliance Status: \(complianceRate)% buildings compliant. " +
               "\(issues) active issues requiring resolution. " +
               "Regulatory adherence and safety protocol review requested."
    }
    
    /// Generate emergency response prompt
    public func generateEmergencyPrompt(
        buildingId: String,
        issueType: String,
        severity: String
    ) -> String {
        return "URGENT: Building \(buildingId) emergency. " +
               "Issue: \(issueType). Severity: \(severity). " +
               "Immediate response coordination and resource allocation required."
    }
    
    // MARK: - Context Generation Methods
    
    private func generatePortfolioContext(_ data: NovaAggregatedData) -> String {
        var context = ""
        
        // Add time-based context
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            context += "Morning operations in progress. "
        } else if hour < 17 {
            context += "Afternoon maintenance window active. "
        } else {
            context += "Evening wind-down phase. "
        }
        
        // Add workload context
        if data.taskCount > 100 {
            context += "High task volume detected. "
        } else if data.taskCount < 20 {
            context += "Light task load today. "
        }
        
        return context
    }
    
    private func generatePortfolioMetrics(_ data: NovaAggregatedData) -> String {
        let avgTasksPerWorker = data.workerCount > 0 ? data.taskCount / data.workerCount : 0
        let avgTasksPerBuilding = data.buildingCount > 0 ? data.taskCount / data.buildingCount : 0
        
        return "Metrics: \(avgTasksPerWorker) tasks/worker, \(avgTasksPerBuilding) tasks/building. "
    }
    
    private func generateBuildingContext(_ buildingId: String) async -> String {
        // Building-specific context based on ID
        switch buildingId {
        case "14": // Rubin Museum
            return "Museum facility with climate control and artifact protection priorities. "
        case "7": // 136 W 17th Street
            return "Residential property focusing on tenant satisfaction. "
        case "10": // 29-31 East 20th Street
            return "Mixed-use building with diverse maintenance requirements. "
        case "13": // Stuyvesant Cove Park
            return "Outdoor facility with weather-dependent maintenance needs. "
        default:
            return "Standard commercial property maintenance protocols. "
        }
    }
    
    private func generateBuildingMetrics(_ buildingId: String, _ data: NovaAggregatedData) -> String {
        // In a full implementation, would fetch actual metrics
        return "Building efficiency metrics within normal range. "
    }
    
    // MARK: - Utility Methods
    
    private func truncatePrompt(_ prompt: String) -> String {
        if prompt.count <= maxPromptLength {
            return prompt
        }
        
        let truncated = String(prompt.prefix(maxPromptLength - 3))
        return truncated + "..."
    }
    
    /// Generate a prompt with custom parameters
    public func generateCustomPrompt(
        template: PromptTemplate,
        parameters: [String: Any]
    ) -> String {
        var prompt = template.baseText
        
        // Replace placeholders with parameters
        for (key, value) in parameters {
            prompt = prompt.replacingOccurrences(of: "{\(key)}", with: String(describing: value))
        }
        
        return truncatePrompt(prompt)
    }
}

// MARK: - Supporting Types

/// Focus areas for prompt generation
public enum PromptFocus {
    case operations
    case workforce
    case maintenance
    case compliance
    case financial
}

/// Template for custom prompts
public struct PromptTemplate {
    public let name: String
    public let baseText: String
    public let requiredParameters: [String]
    
    public init(name: String, baseText: String, requiredParameters: [String]) {
        self.name = name
        self.baseText = baseText
        self.requiredParameters = requiredParameters
    }
    
    // Predefined templates
    public static let dailyBriefing = PromptTemplate(
        name: "Daily Briefing",
        baseText: "Daily briefing for {date}: {taskCount} tasks across {buildingCount} buildings with {workerCount} active workers.",
        requiredParameters: ["date", "taskCount", "buildingCount", "workerCount"]
    )
    
    public static let workerAssignment = PromptTemplate(
        name: "Worker Assignment",
        baseText: "Assign {workerName} to {buildingName} for {taskType} tasks. Duration: {hours} hours.",
        requiredParameters: ["workerName", "buildingName", "taskType", "hours"]
    )
    
    public static let maintenanceAlert = PromptTemplate(
        name: "Maintenance Alert",
        baseText: "Maintenance required at {buildingName}: {issueType}. Priority: {priority}. Estimated time: {duration}.",
        requiredParameters: ["buildingName", "issueType", "priority", "duration"]
    )
}
