//
//  FrancoSphereModels.swift
//  FrancoSphere v6.0 - CLEANED
//

import Foundation
import SwiftUI
import CoreLocation

public struct FrancoSphere {
    public struct NamedCoordinate: Identifiable, Codable, Hashable {
        public let id: String; public let name: String
        public let coordinate: CLLocationCoordinate2D
        public let address: String?; public let imageAssetName: String?
        public init(id:String,name:String,coordinate:CLLocationCoordinate2D,address:String?=nil,imageAssetName:String?=nil){
            self.id=id;self.name=name;self.coordinate=coordinate
            self.address=address;self.imageAssetName=imageAssetName
        }
    }
    public enum WeatherCondition: String, Codable, CaseIterable { case clear,sunny,cloudy,rainy,snowy,stormy,foggy,windy }
    public struct WeatherData: Identifiable, Codable {
        public let id:String; public let date:Date
        public let temperature:Double; public let feelsLike:Double
        public let humidity:Int; public let windSpeed:Double
        public let windDirection:Int; public let precipitation:Double
        public let snow:Double; public let condition:WeatherCondition
        public let uvIndex:Int; public let visibility:Double
        public let description:String
        public init(id:String,date:Date,temperature:Double,feelsLike:Double,humidity:Int,windSpeed:Double,windDirection:Int,precipitation:Double,snow:Double,condition:WeatherCondition,uvIndex:Int,visibility:Double,description:String){
            self.id=id;self.date=date;self.temperature=temperature;self.feelsLike=feelsLike
            self.humidity=humidity;self.windSpeed=windSpeed;self.windDirection=windDirection
            self.precipitation=precipitation;self.snow=snow;self.condition=condition
            self.uvIndex=uvIndex;self.visibility=visibility;self.description=description
        }
    }
    public enum OutdoorWorkRisk: String, Codable, CaseIterable { case low,medium,high,extreme }
    public enum TaskCategory: String, Codable, CaseIterable { case maintenance,cleaning,inspection,repair,security,landscaping }
    public enum TaskUrgency: String, Codable, CaseIterable {
        case low,medium,high,critical,emergency,urgent
        public var color: Color {
            switch self { case .low: return .green; case .medium: return .yellow
                case .high: return .orange; case .critical: return .red
                case .emergency: return .red; case .urgent: return .red }
        }
    }
    public enum TaskRecurrence: String, Codable, CaseIterable { case none,daily,weekly,monthly,yearly }
    public enum VerificationStatus: String, Codable, CaseIterable { case pending,verified,rejected,needsReview }
    public struct MaintenanceTask: Identifiable, Codable, Hashable {
        public let id:String, title:String, description:String
        public let category:TaskCategory, urgency:TaskUrgency, buildingId:String
        public let assignedWorkerId:String?; public var isCompleted:Bool
        public let dueDate:Date?, estimatedDuration:TimeInterval
        public let recurrence:TaskRecurrence; public let notes:String?
        public init(id:String=UUID().uuidString,title:String,description:String,category:TaskCategory,urgency:TaskUrgency,buildingId:String,assignedWorkerId:String?=nil,isCompleted:Bool=false,dueDate:Date?=nil,estimatedDuration:TimeInterval=3600,recurrence:TaskRecurrence=.none,notes:String?=nil){
            self.id=id;self.title=title;self.description=description
            self.category=category;self.urgency=urgency;self.buildingId=buildingId
            self.assignedWorkerId=assignedWorkerId;self.isCompleted=isCompleted
            self.dueDate=dueDate;self.estimatedDuration=estimatedDuration
            self.recurrence=recurrence;self.notes=notes
        }
    }
    public struct Worker: Identifiable, Codable, Hashable {
        public let id:String,name:String,email:String,role:String,buildings:[String]
        public init(id:String,name:String,email:String,role:String,buildings:[String]){
            self.id=id;self.name=name;self.email=email
            self.role=role;self.buildings=buildings
        }
    }
    public struct ActionEvidence: Codable {
        public let timestamp:Date,location:CLLocationCoordinate2D?,photoPath:String?,notes:String?
        public init(timestamp:Date=Date(),location:CLLocationCoordinate2D?=nil,photoPath:String?=nil,notes:String?=nil){
            self.timestamp=timestamp;self.location=location
            self.photoPath=photoPath;self.notes=notes
        }
    }
    public struct WorkerPerformanceMetrics: Codable {
        public let efficiency:Double,tasksCompleted:Int,averageCompletionTime:TimeInterval
        public init(efficiency:Double,tasksCompleted:Int,averageCompletionTime:TimeInterval){
            self.efficiency=efficiency;self.tasksCompleted=tasksCompleted;self.averageCompletionTime=averageCompletionTime
        }
    }
    public enum TrendDirection: String, Codable, CaseIterable {
        case up,down,stable
        public var color: Color {
            switch self { case .up: return .green; case .down: return .red; case .stable: return .blue }
        }
        public var icon: String {
            switch self { case .up: return "arrow.up.right"; case .down: return "arrow.down.right"; case .stable: return "arrow.right" }
        }
    }
    public enum ServiceError: Error { case noSQLiteManager, invalidData(String) }
}

# Global aliases
cat >> Models/FrancoSphereModels.swift << 'ALIASES'
// Aliases for backward compatibility
public typealias NamedCoordinate          = FrancoSphere.NamedCoordinate
public typealias WeatherCondition         = FrancoSphere.WeatherCondition
public typealias WeatherData              = FrancoSphere.WeatherData
public typealias OutdoorWorkRisk          = FrancoSphere.OutdoorWorkRisk
public typealias TaskCategory             = FrancoSphere.TaskCategory
public typealias TaskUrgency              = FrancoSphere.TaskUrgency
public typealias TaskRecurrence           = FrancoSphere.TaskRecurrence
public typealias VerificationStatus       = FrancoSphere.VerificationStatus
public typealias MaintenanceTask          = FrancoSphere.MaintenanceTask
public typealias Worker                    = FrancoSphere.Worker
public typealias ActionEvidence           = FrancoSphere.ActionEvidence
public typealias WorkerPerformanceMetrics = FrancoSphere.WorkerPerformanceMetrics
public typealias TrendDirection           = FrancoSphere.TrendDirection
ALIASES

# 7️⃣ BuildingAnalytics.swift
echo "7️⃣ Writing BuildingAnalytics.swift…"
cat > Models/BuildingAnalytics.swift << 'BA'
//
//  BuildingAnalytics.swift
//  FrancoSphere
//

import Foundation

public struct BuildingAnalytics: Codable {
    public let buildingId: String
    public let totalTasks: Int
    public let completedTasks: Int
    public let overdueTasks: Int
    public let completionRate: Double
    public let uniqueWorkers: Int
    public let averageCompletionTime: TimeInterval
    public let efficiency: Double
    public let lastUpdated: Date

    public init(buildingId:String,totalTasks:Int,completedTasks:Int,overdueTasks:Int,completionRate:Double,uniqueWorkers:Int,averageCompletionTime:TimeInterval,efficiency:Double,lastUpdated:Date=Date()){
        self.buildingId=buildingId;self.totalTasks=totalTasks;self.completedTasks=completedTasks
        self.overdueTasks=overdueTasks;self.completionRate=completionRate;self.uniqueWorkers=uniqueWorkers
        self.averageCompletionTime=averageCompletionTime;self.efficiency=efficiency;self.lastUpdated=lastUpdated
    }
}

extension BuildingService {
    func getBuildingAnalytics(_ buildingId: String) async throws -> BuildingAnalytics {
        let tasks      = try await TaskService.shared.getTasksForBuilding(buildingId)
        let completed  = tasks.filter { $0.isCompleted }
        let overdue    = tasks.filter { !$0.isCompleted && ($0.dueDate ?? Date.distantFuture) < Date() }
        let workers    = try await WorkerService.shared.getActiveWorkersForBuilding(buildingId)
        let rate       = tasks.isEmpty ? 0.0 : Double(completed.count)/Double(tasks.count)
        let avgTime    = completed.isEmpty ? 0.0 : completed.reduce(0.0){$0+$1.estimatedDuration}/Double(completed.count)
        return BuildingAnalytics(
            buildingId: buildingId,
            totalTasks: tasks.count,
            completedTasks: completed.count,
            overdueTasks: overdue.count,
            completionRate: rate,
            uniqueWorkers: workers.count,
            averageCompletionTime: avgTime,
            efficiency: rate
        )
    }
}
BA

echo "✅ All surgical compilation fixes applied!"
echo "🔨 Now run: xcodebuild clean build"
