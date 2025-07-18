//
//  AdditionalTypes.swift
//  FrancoSphere
//
//  Additional types for conformance
//

import Foundation
import SwiftUI

public struct PerformanceMetrics: Codable, Hashable {
    public let workerId: String
    public let efficiency: Double
    public let tasksCompleted: Int
    public let averageTime: Double
    public let qualityScore: Double
    public let lastUpdate: Date
    public init(workerId: String, efficiency: Double, tasksCompleted: Int, averageTime: Double, qualityScore: Double, lastUpdate: Date=Date()) {
        self.workerId=workerId;self.efficiency=efficiency;self.tasksCompleted=tasksCompleted
        self.averageTime=averageTime;self.qualityScore=qualityScore;self.lastUpdate=lastUpdate
    }
}

public struct BuildingStatistics: Codable, Hashable {
    public let buildingId: String
    public let completionRate: Double
    public let taskCount: Int
    public let workerCount: Int
    public let efficiencyTrend: FrancoSphere.TrendDirection
    public let lastUpdate: Date
    public init(buildingId:String,completionRate:Double,taskCount:Int,workerCount:Int,efficiencyTrend:FrancoSphere.TrendDirection,lastUpdate:Date=Date()){
        self.buildingId=buildingId;self.completionRate=completionRate;self.taskCount=taskCount
        self.workerCount=workerCount;self.efficiencyTrend=efficiencyTrend;self.lastUpdate=lastUpdate
    }
}

public struct TaskTrends: Codable, Hashable {
    public let weeklyCompletion: [Double]
    public let categoryBreakdown: [String:Int]
    public let changePercentage: Double
    public let comparisonPeriod: String
    public let trend: FrancoSphere.TrendDirection

    public var upwardTrend: FrancoSphere.TrendDirection { .up }
    public var downwardTrend: FrancoSphere.TrendDirection { .down }
    public var stableTrend: FrancoSphere.TrendDirection { .stable }

    public init(weeklyCompletion:[Double],categoryBreakdown:[String:Int],changePercentage:Double,comparisonPeriod:String,trend:FrancoSphere.TrendDirection){
        self.weeklyCompletion=weeklyCompletion;self.categoryBreakdown=categoryBreakdown
        self.changePercentage=changePercentage;self.comparisonPeriod=comparisonPeriod;self.trend=trend
    }
}

public struct InsightFilter: Hashable, Equatable {
    public let type: FrancoSphere.InsightType?
    public let priority: FrancoSphere.InsightPriority?
    public let buildingId: String?
    public init(type:FrancoSphere.InsightType?=nil,priority:FrancoSphere.InsightPriority?=nil,buildingId:String?=nil){
        self.type=type;self.priority=priority;self.buildingId=buildingId
    }
}

public struct StreakData: Codable, Hashable {
    public let workerId: String
    public let currentStreak: Int
    public let longestStreak: Int
    public let streakType: StreakType
    public let lastActivityDate: Date
    public let nextMilestone: Int
    public let streakStartDate: Date

    public enum StreakType: String, Codable {
        case taskCompletion="task_completion",punctuality="punctuality",qualityRating="quality_rating",consistency="consistency"
    }
    public init(workerId:String,currentStreak:Int,longestStreak:Int,streakType:StreakType,lastActivityDate:Date,nextMilestone:Int,streakStartDate:Date){
        self.workerId=workerId;self.currentStreak=currentStreak;self.longestStreak=longestStreak
        self.streakType=streakType;self.lastActivityDate=lastActivityDate;self.nextMilestone=nextMilestone;self.streakStartDate=streakStartDate
    }
}
