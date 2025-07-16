//
//  BuildingIntelligenceDTO.swift
//  FrancoSphere
//
//  ✅ V6.0: Phase 1.1 - Comprehensive DTO System
//  ✅ FIXED: Aligned with actual DTO structures and method signatures
//  ✅ CORRECTED: All method calls and property references
//

import Foundation

public struct BuildingIntelligenceDTO: Codable, Hashable, Identifiable {
    public var id: CoreTypes.BuildingID { buildingId }
    
    let buildingId: CoreTypes.BuildingID
    let operationalMetrics: OperationalMetricsDTO
    let complianceData: ComplianceDataDTO
    let workerMetrics: [WorkerMetricsDTO] // An array to hold metrics for all assigned workers
    let buildingSpecificData: BuildingSpecificDataDTO
    let dataQuality: DataQuality
    let timestamp: Date
    
    // A convenience computed property to get the overall building score
    var overallScore: Int {
        return operationalMetrics.score
    }
    
    public init(
        buildingId: CoreTypes.BuildingID,
        operationalMetrics: OperationalMetricsDTO,
        complianceData: ComplianceDataDTO,
        workerMetrics: [WorkerMetricsDTO],
        buildingSpecificData: BuildingSpecificDataDTO,
        dataQuality: DataQuality,
        timestamp: Date = Date()
    ) {
        self.buildingId = buildingId
        self.operationalMetrics = operationalMetrics
        self.complianceData = complianceData
        self.workerMetrics = workerMetrics
        self.buildingSpecificData = buildingSpecificData
        self.dataQuality = dataQuality
        self.timestamp = timestamp
    }
}

// MARK: - Supporting DTOs (Enhanced from existing structures)

public struct OperationalMetricsDTO: Codable, Hashable {
    let score: Int
    let routineAdherence: Double
    let maintenanceEfficiency: Double
    let averageTaskDuration: TimeInterval
    let taskCompletionRate: Double
    let urgentTasksCount: Int
    let overdueTasksCount: Int
    
    public init(
        score: Int,
        routineAdherence: Double,
        maintenanceEfficiency: Double,
        averageTaskDuration: TimeInterval,
        taskCompletionRate: Double = 0.0,
        urgentTasksCount: Int = 0,
        overdueTasksCount: Int = 0
    ) {
        self.score = score
        self.routineAdherence = routineAdherence
        self.maintenanceEfficiency = maintenanceEfficiency
        self.averageTaskDuration = averageTaskDuration
        self.taskCompletionRate = taskCompletionRate
        self.urgentTasksCount = urgentTasksCount
        self.overdueTasksCount = overdueTasksCount
    }
}

public struct BuildingSpecificDataDTO: Codable, Hashable {
    let buildingType: String // e.g., "Commercial", "Residential", "Cultural"
    let yearBuilt: Int
    let squareFootage: Int
    let address: String?
    let totalFloors: Int?
    let hasElevator: Bool
    
    public init(
        buildingType: String,
        yearBuilt: Int,
        squareFootage: Int,
        address: String? = nil,
        totalFloors: Int? = nil,
        hasElevator: Bool = false
    ) {
        self.buildingType = buildingType
        self.yearBuilt = yearBuilt
        self.squareFootage = squareFootage
        self.address = address
        self.totalFloors = totalFloors
        self.hasElevator = hasElevator
    }
}

public struct DataQuality: Codable, Hashable {
    let score: Double
    let isDataStale: Bool
    let missingReports: Int
    let lastDataRefresh: Date
    let dataCompleteness: Double
    
    public init(
        score: Double,
        isDataStale: Bool,
        missingReports: Int,
        lastDataRefresh: Date = Date(),
        dataCompleteness: Double = 1.0
    ) {
        self.score = score
        self.isDataStale = isDataStale
        self.missingReports = missingReports
        self.lastDataRefresh = lastDataRefresh
        self.dataCompleteness = dataCompleteness
    }
}

// MARK: - Extension for Integration with CoreTypes

extension BuildingIntelligenceDTO {
    
    /// Convert to CoreTypes.BuildingMetrics for compatibility
    func toBuildingMetrics() -> CoreTypes.BuildingMetrics {
        return CoreTypes.BuildingMetrics(
            buildingId: buildingId,
            completionRate: operationalMetrics.taskCompletionRate,
            pendingTasks: operationalMetrics.urgentTasksCount,
            overdueTasks: operationalMetrics.overdueTasksCount,
            activeWorkers: workerMetrics.count,
            urgentTasksCount: operationalMetrics.urgentTasksCount,
            overallScore: operationalMetrics.score,
            isCompliant: complianceData.complianceStatus == .compliant,
            hasWorkerOnSite: workerMetrics.contains { $0.lastActiveDate > Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date() },
            maintenanceEfficiency: operationalMetrics.maintenanceEfficiency,
            weeklyCompletionTrend: operationalMetrics.taskCompletionRate
        )
    }
    
    /// Generate CoreTypes.IntelligenceInsight from building data
    func generateIntelligenceInsights() -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        // Performance insights
        if operationalMetrics.taskCompletionRate > 0.9 {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "High Performance Building",
                description: "Excellent task completion rate of \(Int(operationalMetrics.taskCompletionRate * 100))%",
                type: .performance,
                priority: .low,
                actionRequired: false,
                affectedBuildings: [buildingId]
            ))
        }
        
        // Maintenance insights
        if operationalMetrics.overdueTasksCount > 3 {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Overdue Maintenance Tasks",
                description: "\(operationalMetrics.overdueTasksCount) maintenance tasks are overdue",
                type: .maintenance,
                priority: operationalMetrics.overdueTasksCount > 10 ? .critical : .high,
                actionRequired: true,
                affectedBuildings: [buildingId]
            ))
        }
        
        // Compliance insights - using actual ComplianceStatus enum from ComplianceDataDTO
        if complianceData.complianceStatus != .compliant {
            let priorityLevel: CoreTypes.InsightPriority = {
                switch complianceData.complianceStatus {
                case .atRisk: return .critical
                case .needsReview: return .medium
                case .compliant: return .low
                }
            }()
            
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Compliance Issues Detected",
                description: "Building has \(complianceData.outstandingViolations) compliance issues requiring attention",
                type: .compliance,
                priority: priorityLevel,
                actionRequired: true,
                affectedBuildings: [buildingId]
            ))
        }
        
        // Data quality insights
        if dataQuality.isDataStale {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Stale Data Detected",
                description: "Building data hasn't been updated recently, insights may be inaccurate",
                type: .efficiency,
                priority: .medium,
                actionRequired: true,
                affectedBuildings: [buildingId]
            ))
        }
        
        // Worker performance insights
        let highPerformers = workerMetrics.filter { $0.isHighPerformer }
        if highPerformers.count == workerMetrics.count && !workerMetrics.isEmpty {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Exceptional Worker Performance",
                description: "All \(workerMetrics.count) assigned workers are high performers",
                type: .performance,
                priority: .low,
                actionRequired: false,
                affectedBuildings: [buildingId]
            ))
        }
        
        return insights.sorted { $0.priority.priorityValue > $1.priority.priorityValue }
    }
}

// MARK: - Factory Methods

extension BuildingIntelligenceDTO {
    
    /// Create a sample DTO for testing using StubFactory patterns
    static func sample(buildingId: CoreTypes.BuildingID) -> BuildingIntelligenceDTO {
        return BuildingIntelligenceDTO(
            buildingId: buildingId,
            operationalMetrics: OperationalMetricsDTO(
                score: 85,
                routineAdherence: 0.92,
                maintenanceEfficiency: 0.88,
                averageTaskDuration: 3600,
                taskCompletionRate: 0.85,
                urgentTasksCount: 2,
                overdueTasksCount: 1
            ),
            complianceData: StubFactory.makeComplianceData(for: buildingId),
            workerMetrics: [StubFactory.makeWorkerMetrics(for: buildingId, workerId: "1")],
            buildingSpecificData: StubFactory.makeBuildingSpecificData(for: buildingId),
            dataQuality: StubFactory.makeDataQuality()
        )
    }
    
    /// Create enhanced sample with multiple workers
    static func enhancedSample(buildingId: CoreTypes.BuildingID, workerIds: [CoreTypes.WorkerID]) -> BuildingIntelligenceDTO {
        let workerMetrics = workerIds.map { StubFactory.makeWorkerMetrics(for: buildingId, workerId: $0) }
        
        return BuildingIntelligenceDTO(
            buildingId: buildingId,
            operationalMetrics: StubFactory.makeOperationalMetrics(),
            complianceData: StubFactory.makeComplianceData(for: buildingId),
            workerMetrics: workerMetrics,
            buildingSpecificData: StubFactory.makeBuildingSpecificData(for: buildingId),
            dataQuality: StubFactory.makeDataQuality()
        )
    }
}
