
public struct BuildingMetrics {
    public let completionRate: Double
    public let pendingTasks: Int
    public let overdueTasks: Int
    public let activeWorkers: Int
    public let isCompliant: Bool
    public let overallScore: Int
    
    public init(completionRate: Double, pendingTasks: Int, overdueTasks: Int, activeWorkers: Int, isCompliant: Bool, overallScore: Int) {
        self.completionRate = completionRate
        self.pendingTasks = pendingTasks
        self.overdueTasks = overdueTasks
        self.activeWorkers = activeWorkers
        self.isCompliant = isCompliant
        self.overallScore = overallScore
    }
    
    public static func calculate(from analytics: BuildingAnalytics) -> BuildingMetrics {
        return BuildingMetrics(
            completionRate: analytics.completionRate,
            pendingTasks: analytics.totalTasks - analytics.completedTasks,
            overdueTasks: analytics.overdueTasks,
            activeWorkers: analytics.uniqueWorkers,
            isCompliant: analytics.overdueTasks == 0,
            overallScore: Int(analytics.completionRate * 100)
        )
    }
}
