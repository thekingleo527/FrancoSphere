import Foundation
import CoreLocation

// MARK: - CoreTypes - Foundation Type System for FrancoSphere v6.0
// This file defines ALL fundamental types used across the multi-dashboard system

public struct CoreTypes {
    // MARK: - Identity Types
    public typealias WorkerID = String
    public typealias BuildingID = String
    public typealias TaskID = String
    public typealias AssignmentID = String
    public typealias RoleID = String
    
    // MARK: - User Model (Unified across all dashboards)
    public struct User: Codable, Hashable {
        public let workerId: WorkerID
        public let name: String
        public let email: String
        public let role: String
        
        // Dashboard routing computed properties
        public var isAdmin: Bool { role == "admin" }
        public var isWorker: Bool { role == "worker" }
        public var isClient: Bool { role == "client" }
        public var displayName: String { name }
        
        public init(workerId: WorkerID, name: String, email: String, role: String) {
            self.workerId = workerId
            self.name = name
            self.email = email
            self.role = role
        }
    }
    
    // MARK: - Building Types
    public enum BuildingType: String, Codable, CaseIterable {
        case residential = "Residential"     // Perry Street cluster
        case commercial = "Commercial"       // West 17th Street corridor
        case museum = "Museum"              // Rubin Museum (ID: 14)
        case mixedUse = "Mixed Use"         // Multi-purpose buildings
    }
    
    // MARK: - Task and Performance Types
    public enum TaskUrgency: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
    }
    
    public enum TaskCategory: String, Codable, CaseIterable {
        case cleaning = "Cleaning"
        case sanitation = "Sanitation"
        case maintenance = "Maintenance"
        case inspection = "Inspection"
        case operations = "Operations"
        case repair = "Repair"
        case security = "Security"
        case landscaping = "Landscaping"
    }
    
    public enum TaskRecurrence: String, Codable, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case biWeekly = "Bi-Weekly"
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case semiannual = "Semiannual"
        case annual = "Annual"
        case onDemand = "On-Demand"
    }
}

// MARK: - Task Progress Tracking
public struct TaskProgress: Codable, Hashable {
    public let workerId: CoreTypes.WorkerID
    public let totalTasks: Int
    public let completedTasks: Int
    public let overdueTasks: Int
    public let todayCompletedTasks: Int
    public let weeklyTarget: Int
    public let currentStreak: Int
    public let lastCompletionDate: Date?
    
    // Computed properties
    public var completionRate: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    public var isOnTrack: Bool {
        return overdueTasks == 0 && completionRate >= 0.8
    }
    
    public var progressPercentage: Int {
        return Int(completionRate * 100)
    }
    
    public init(workerId: CoreTypes.WorkerID, totalTasks: Int, completedTasks: Int, overdueTasks: Int, todayCompletedTasks: Int, weeklyTarget: Int, currentStreak: Int, lastCompletionDate: Date? = nil) {
        self.workerId = workerId
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.overdueTasks = overdueTasks
        self.todayCompletedTasks = todayCompletedTasks
        self.weeklyTarget = weeklyTarget
        self.currentStreak = currentStreak
        self.lastCompletionDate = lastCompletionDate
    }
}

// MARK: - Performance Metrics
public struct PerformanceMetrics: Codable, Hashable {
    public let workerId: CoreTypes.WorkerID
    public let period: TimePeriod
    public let efficiency: Double          // 0.0 - 1.0
    public let quality: Double            // 0.0 - 1.0
    public let punctuality: Double        // 0.0 - 1.0
    public let consistency: Double        // 0.0 - 1.0
    public let overallScore: Double       // 0.0 - 1.0
    public let tasksCompleted: Int
    public let averageCompletionTime: TimeInterval
    public let recentTrend: TrendDirection
    
    public enum TimePeriod: String, Codable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case quarterly = "quarterly"
    }
    
    public init(workerId: CoreTypes.WorkerID, period: TimePeriod, efficiency: Double, quality: Double, punctuality: Double, consistency: Double, overallScore: Double, tasksCompleted: Int, averageCompletionTime: TimeInterval, recentTrend: TrendDirection) {
        self.workerId = workerId
        self.period = period
        self.efficiency = efficiency
        self.quality = quality
        self.punctuality = punctuality
        self.consistency = consistency
        self.overallScore = overallScore
        self.tasksCompleted = tasksCompleted
        self.averageCompletionTime = averageCompletionTime
        self.recentTrend = recentTrend
    }
}

// MARK: - Trend Analysis
public enum TrendDirection: String, Codable, CaseIterable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"
    case unknown = "unknown"
    
    public var systemImage: String {
        switch self {
        case .improving: return "arrow.up.circle.fill"
        case .stable: return "minus.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
    
    public var color: String {
        switch self {
        case .improving: return "green"
        case .stable: return "blue"
        case .declining: return "red"
        case .unknown: return "gray"
        }
    }
}

// MARK: - Building Analytics
public struct BuildingStatistics: Codable, Hashable {
    public let buildingId: CoreTypes.BuildingID
    public let period: PerformanceMetrics.TimePeriod
    public let totalTasks: Int
    public let completedTasks: Int
    public let averageCompletionTime: TimeInterval
    public let workerEfficiency: Double
    public let maintenanceScore: Double
    public let complianceScore: Double
    public let issueCount: Int
    public let trend: TrendDirection
    
    public var completionRate: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    public init(buildingId: CoreTypes.BuildingID, period: PerformanceMetrics.TimePeriod, totalTasks: Int, completedTasks: Int, averageCompletionTime: TimeInterval, workerEfficiency: Double, maintenanceScore: Double, complianceScore: Double, issueCount: Int, trend: TrendDirection) {
        self.buildingId = buildingId
        self.period = period
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.averageCompletionTime = averageCompletionTime
        self.workerEfficiency = workerEfficiency
        self.maintenanceScore = maintenanceScore
        self.complianceScore = complianceScore
        self.issueCount = issueCount
        self.trend = trend
    }
}

// MARK: - Schedule Management
public struct ScheduleConflict: Codable, Hashable {
    public let id: String
    public let workerId: CoreTypes.WorkerID
    public let conflictType: ConflictType
    public let description: String
    public let affectedTasks: [CoreTypes.TaskID]
    public let severity: Severity
    public let suggestedResolution: String
    public let detectedAt: Date
    
    public enum ConflictType: String, Codable {
        case timeOverlap = "time_overlap"
        case locationConflict = "location_conflict"
        case skillMismatch = "skill_mismatch"
        case resourceUnavailable = "resource_unavailable"
    }
    
    public enum Severity: String, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
    }
    
    public init(id: String, workerId: CoreTypes.WorkerID, conflictType: ConflictType, description: String, affectedTasks: [CoreTypes.TaskID], severity: Severity, suggestedResolution: String, detectedAt: Date = Date()) {
        self.id = id
        self.workerId = workerId
        self.conflictType = conflictType
        self.description = description
        self.affectedTasks = affectedTasks
        self.severity = severity
        self.suggestedResolution = suggestedResolution
        self.detectedAt = detectedAt
    }
}

// MARK: - Building Insights
public struct BuildingInsight: Codable, Hashable {
    public let buildingId: CoreTypes.BuildingID
    public let type: InsightType
    public let title: String
    public let description: String
    public let impact: Impact
    public let actionRequired: Bool
    public let suggestedAction: String?
    public let generatedAt: Date
    
    public enum InsightType: String, Codable {
        case efficiency = "efficiency"
        case maintenance = "maintenance"
        case compliance = "compliance"
        case cost = "cost"
        case safety = "safety"
    }
    
    public enum Impact: String, Codable {
        case positive = "positive"
        case neutral = "neutral"
        case negative = "negative"
    }
    
    public init(buildingId: CoreTypes.BuildingID, type: InsightType, title: String, description: String, impact: Impact, actionRequired: Bool, suggestedAction: String? = nil, generatedAt: Date = Date()) {
        self.buildingId = buildingId
        self.type = type
        self.title = title
        self.description = description
        self.impact = impact
        self.actionRequired = actionRequired
        self.suggestedAction = suggestedAction
        self.generatedAt = generatedAt
    }
}

// MARK: - UI Support Types
public enum BuildingTab: String, Codable, CaseIterable {
    case overview = "overview"
    case tasks = "tasks"
    case workers = "workers"
    case maintenance = "maintenance"
    case analytics = "analytics"
    
    public var displayName: String {
        return rawValue.capitalized
    }
    
    public var systemImage: String {
        switch self {
        case .overview: return "building.2.fill"
        case .tasks: return "checklist"
        case .workers: return "person.2.fill"
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .analytics: return "chart.bar.fill"
        }
    }
}

// MARK: - Task Analytics
public struct TaskTrends: Codable, Hashable {
    public let period: PerformanceMetrics.TimePeriod
    public let completionTrend: TrendDirection
    public let efficiencyTrend: TrendDirection
    public let qualityTrend: TrendDirection
    public let weeklyAverage: Double
    public let monthlyProjection: Int
    public let peakPerformanceDay: String
    public let improvementAreas: [String]
    
    public init(period: PerformanceMetrics.TimePeriod, completionTrend: TrendDirection, efficiencyTrend: TrendDirection, qualityTrend: TrendDirection, weeklyAverage: Double, monthlyProjection: Int, peakPerformanceDay: String, improvementAreas: [String]) {
        self.period = period
        self.completionTrend = completionTrend
        self.efficiencyTrend = efficiencyTrend
        self.qualityTrend = qualityTrend
        self.weeklyAverage = weeklyAverage
        self.monthlyProjection = monthlyProjection
        self.peakPerformanceDay = peakPerformanceDay
        self.improvementAreas = improvementAreas
    }
}

// MARK: - Streak Tracking
public struct StreakData: Codable, Hashable {
    public let workerId: CoreTypes.WorkerID
    public let currentStreak: Int
    public let longestStreak: Int
    public let streakType: StreakType
    public let lastActivityDate: Date
    public let nextMilestone: Int
    public let streakStartDate: Date
    
    public enum StreakType: String, Codable {
        case taskCompletion = "task_completion"
        case punctuality = "punctuality"
        case qualityRating = "quality_rating"
        case consistency = "consistency"
    }
    
    public var isActive: Bool {
        Calendar.current.isDate(lastActivityDate, inSameDayAs: Date())
    }
    
    public var daysToMilestone: Int {
        return max(0, nextMilestone - currentStreak)
    }
    
    public init(workerId: CoreTypes.WorkerID, currentStreak: Int, longestStreak: Int, streakType: StreakType, lastActivityDate: Date, nextMilestone: Int, streakStartDate: Date) {
        self.workerId = workerId
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.streakType = streakType
        self.lastActivityDate = lastActivityDate
        self.nextMilestone = nextMilestone
        self.streakStartDate = streakStartDate
    }
}

// MARK: - AI Assistant Types (Temporary Stubs)
public struct AIScenarioData: Codable, Hashable {
    public let id: String
    public let title: String
    public let description: String
    public let priority: CoreTypes.TaskUrgency
    
    public init(id: String, title: String, description: String, priority: CoreTypes.TaskUrgency) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
    }
}

public struct AISuggestion: Codable, Hashable {
    public let id: String
    public let title: String
    public let description: String
    public let priority: CoreTypes.TaskUrgency
    public let category: SuggestionCategory
    
    public enum SuggestionCategory: String, Codable {
        case efficiency = "efficiency"
        case safety = "safety"
        case maintenance = "maintenance"
        case scheduling = "scheduling"
        case weatherAlert = "weatherAlert"
        case pendingTasks = "pendingTasks"
    }
    
    public init(id: String, title: String, description: String, priority: CoreTypes.TaskUrgency, category: SuggestionCategory) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.category = category
    }
}

public struct AIScenario: Codable, Hashable {
    public let id: String
    public let title: String
    public let description: String
    public let data: AIScenarioData
    public let suggestions: [AISuggestion]
    
    public init(id: String, title: String, description: String, data: AIScenarioData, suggestions: [AISuggestion]) {
        self.id = id
        self.title = title
        self.description = description
        self.data = data
        self.suggestions = suggestions
    }
}
