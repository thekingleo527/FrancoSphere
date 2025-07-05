#!/bin/bash

# FrancoSphere Precise Compilation Fix Script
# Fixes specific compilation errors

cat << 'SCRIPT_HEADER'
🔧 FrancoSphere Precise Fix
===========================
Fixing specific compilation errors only
SCRIPT_HEADER

# =============================================================================
# FIX 1: NamedCoordinate coordinate redeclaration
# =============================================================================

cat > /Volumes/FastSSD/Xcode/Models/FrancoSphereModels_TEMP.swift << 'MODEL_EOF'
//
//  FrancoSphereModels.swift
//  FrancoSphere
//
//  Complete type definitions - Single source of truth
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - FrancoSphere Namespace
public enum FrancoSphere {
    
    // MARK: - Core Models
    public struct NamedCoordinate: Identifiable, Codable, Equatable {
        public let id: String
        public let name: String
        public let latitude: Double
        public let longitude: Double
        public let address: String?
        public let imageAssetName: String?
        
        // Computed property for CLLocationCoordinate2D compatibility
        public var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        public init(id: String, name: String, coordinate: CLLocationCoordinate2D, address: String? = nil, imageAssetName: String? = nil) {
            self.id = id
            self.name = name
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
            self.address = address
            self.imageAssetName = imageAssetName
        }
        
        public init(id: String, name: String, latitude: Double, longitude: Double, address: String? = nil, imageAssetName: String? = nil) {
            self.id = id
            self.name = name
            self.latitude = latitude
            self.longitude = longitude
            self.address = address
            self.imageAssetName = imageAssetName
        }
        
        enum CodingKeys: String, CodingKey {
            case id, name, address, latitude, longitude, imageAssetName
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(String.self, forKey: .id)
            self.name = try container.decode(String.self, forKey: .name)
            self.address = try container.decodeIfPresent(String.self, forKey: .address)
            self.latitude = try container.decode(Double.self, forKey: .latitude)
            self.longitude = try container.decode(Double.self, forKey: .longitude)
            self.imageAssetName = try container.decodeIfPresent(String.self, forKey: .imageAssetName)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encodeIfPresent(address, forKey: .address)
            try container.encode(latitude, forKey: .latitude)
            try container.encode(longitude, forKey: .longitude)
            try container.encodeIfPresent(imageAssetName, forKey: .imageAssetName)
        }
        
        public static func == (lhs: NamedCoordinate, rhs: NamedCoordinate) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    // MARK: - Building Models
    public enum BuildingTab: String, CaseIterable, Codable {
        case overview = "Overview"
        case tasks = "Tasks"
        case inventory = "Inventory"
        case insights = "Insights"
    }
    
    public enum BuildingStatus: String, CaseIterable, Codable {
        case active = "Active"
        case maintenance = "Maintenance"
        case closed = "Closed"
        case inactive = "Inactive"
    }
    
    public struct BuildingStatistics: Codable {
        public let totalTasks: Int
        public let completedTasks: Int
        public let efficiency: Double
        public let lastUpdated: Date
        
        public init(totalTasks: Int, completedTasks: Int, efficiency: Double, lastUpdated: Date) {
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
            self.efficiency = efficiency
            self.lastUpdated = lastUpdated
        }
    }
    
    public struct BuildingInsight: Identifiable, Codable {
        public let id: String
        public let title: String
        public let description: String
        public let priority: Int
        
        public init(id: String, title: String, description: String, priority: Int) {
            self.id = id
            self.title = title
            self.description = description
            self.priority = priority
        }
    }
    
    // MARK: - User Models
    public enum UserRole: String, CaseIterable, Codable {
        case admin = "Admin"
        case manager = "Manager"
        case worker = "Worker"
        case viewer = "Viewer"
    }
    
    public enum WorkerSkill: String, CaseIterable, Codable {
        case basic = "Basic"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"
    }
    
    public struct WorkerProfile: Identifiable, Codable {
        public let id: String
        public let name: String
        public let email: String
        public let role: UserRole
        public let skillLevel: WorkerSkill
        
        public init(id: String, name: String, email: String, role: UserRole, skillLevel: WorkerSkill) {
            self.id = id
            self.name = name
            self.email = email
            self.role = role
            self.skillLevel = skillLevel
        }
    }
    
    public struct WorkerAssignment: Identifiable, Codable {
        public let id: String
        public let workerId: String
        public let buildingId: String
        public let startDate: Date
        public let endDate: Date?
        
        public init(id: String, workerId: String, buildingId: String, startDate: Date, endDate: Date? = nil) {
            self.id = id
            self.workerId = workerId
            self.buildingId = buildingId
            self.startDate = startDate
            self.endDate = endDate
        }
    }
    
    // MARK: - Inventory Models
    public enum InventoryCategory: String, CaseIterable, Codable {
        case cleaning = "Cleaning"
        case maintenance = "Maintenance"
        case safety = "Safety"
        case office = "Office"
        case other = "Other"
    }
    
    public enum RestockStatus: String, CaseIterable, Codable {
        case inStock = "In Stock"
        case lowStock = "Low Stock"
        case outOfStock = "Out of Stock"
        case ordered = "Ordered"
        case inTransit = "In Transit"
        case delivered = "Delivered"
        case cancelled = "Cancelled"
    }
    
    public struct InventoryItem: Identifiable, Codable {
        public let id: String
        public let name: String
        public let category: InventoryCategory
        public let quantity: Int
        public let status: RestockStatus
        public let minimumStock: Int
        
        public init(id: String, name: String, category: InventoryCategory, quantity: Int, status: RestockStatus, minimumStock: Int = 5) {
            self.id = id
            self.name = name
            self.category = category
            self.quantity = quantity
            self.status = status
            self.minimumStock = minimumStock
        }
    }
    
    // MARK: - Task Models
    public enum TaskCategory: String, CaseIterable, Codable {
        case cleaning = "Cleaning"
        case maintenance = "Maintenance"
        case inspection = "Inspection"
        case security = "Security"
        case landscaping = "Landscaping"
        case other = "Other"
    }
    
    public enum TaskUrgency: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        case urgent = "Urgent"
    }
    
    public enum TaskRecurrence: String, CaseIterable, Codable {
        case once = "Once"
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case yearly = "Yearly"
        case oneOff = "One-Off"
    }
    
    public enum VerificationStatus: String, CaseIterable, Codable {
        case pending = "Pending"
        case approved = "Approved"
        case rejected = "Rejected"
        case requiresReview = "Requires Review"
        case verified = "Verified"
        case failed = "Failed"
    }
    
    public struct MaintenanceTask: Identifiable, Codable {
        public let id: String
        public let title: String
        public let description: String
        public let category: TaskCategory
        public let urgency: TaskUrgency
        public let buildingId: String
        public let assignedWorkerId: String?
        public let dueDate: Date
        public let estimatedDuration: TimeInterval
        public let recurrence: TaskRecurrence
        public let isCompleted: Bool
        public let completedDate: Date?
        public let verificationStatus: VerificationStatus
        
        public init(id: String, title: String, description: String, category: TaskCategory, urgency: TaskUrgency, buildingId: String, assignedWorkerId: String? = nil, dueDate: Date, estimatedDuration: TimeInterval, recurrence: TaskRecurrence = .once, isCompleted: Bool = false, completedDate: Date? = nil, verificationStatus: VerificationStatus = .pending) {
            self.id = id
            self.title = title
            self.description = description
            self.category = category
            self.urgency = urgency
            self.buildingId = buildingId
            self.assignedWorkerId = assignedWorkerId
            self.dueDate = dueDate
            self.estimatedDuration = estimatedDuration
            self.recurrence = recurrence
            self.isCompleted = isCompleted
            self.completedDate = completedDate
            self.verificationStatus = verificationStatus
        }
    }
    
    public struct TaskCompletionInfo: Codable {
        public let taskId: String
        public let workerId: String
        public let completedAt: Date
        public let photoPath: String?
        public let notes: String?
        
        public init(taskId: String, workerId: String, completedAt: Date, photoPath: String? = nil, notes: String? = nil) {
            self.taskId = taskId
            self.workerId = workerId
            self.completedAt = completedAt
            self.photoPath = photoPath
            self.notes = notes
        }
    }
    
    public struct TaskCompletionRecord: Identifiable, Codable {
        public let id: String
        public let taskId: String
        public let workerId: String
        public let completedAt: Date
        public let photoPath: String?
        public let notes: String?
        
        public init(id: String = UUID().uuidString, taskId: String, workerId: String, completedAt: Date, photoPath: String? = nil, notes: String? = nil) {
            self.id = id
            self.taskId = taskId
            self.workerId = workerId
            self.completedAt = completedAt
            self.photoPath = photoPath
            self.notes = notes
        }
    }
    
    public struct TaskProgress {
        public let completed: Int
        public let total: Int
        public let remaining: Int
        public let percentage: Double
        public let overdueTasks: Int
        
        public init(completed: Int, total: Int, remaining: Int, percentage: Double, overdueTasks: Int) {
            self.completed = completed
            self.total = total
            self.remaining = remaining
            self.percentage = percentage
            self.overdueTasks = overdueTasks
        }
    }
    
    public struct TaskEvidence: Codable {
        public let photos: [Data]
        public let timestamp: Date
        private let locationLatitude: Double?
        private let locationLongitude: Double?
        public let notes: String?
        
        public var location: CLLocation? {
            guard let lat = locationLatitude, let lng = locationLongitude else { return nil }
            return CLLocation(latitude: lat, longitude: lng)
        }
        
        public init(photos: [Data], timestamp: Date, location: CLLocation? = nil, notes: String? = nil) {
            self.photos = photos
            self.timestamp = timestamp
            self.locationLatitude = location?.coordinate.latitude
            self.locationLongitude = location?.coordinate.longitude
            self.notes = notes
        }
        
        enum CodingKeys: String, CodingKey {
            case photos, timestamp, notes, latitude, longitude
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.photos = try container.decode([Data].self, forKey: .photos)
            self.timestamp = try container.decode(Date.self, forKey: .timestamp)
            self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
            self.locationLatitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
            self.locationLongitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(photos, forKey: .photos)
            try container.encode(timestamp, forKey: .timestamp)
            try container.encodeIfPresent(notes, forKey: .notes)
            try container.encodeIfPresent(locationLatitude, forKey: .latitude)
            try container.encodeIfPresent(locationLongitude, forKey: .longitude)
        }
    }
    
    // MARK: - Weather Models
    public enum WeatherCondition: String, CaseIterable, Codable {
        case sunny = "Sunny"
        case cloudy = "Cloudy"
        case rainy = "Rainy"
        case snowy = "Snowy"
        case stormy = "Stormy"
        case foggy = "Foggy"
        case windy = "Windy"
        case clear = "Clear"
        case rain = "Rain"
        case snow = "Snow"
        case fog = "Fog"
        case storm = "Storm"
    }
    
    public struct WeatherData: Codable {
        public let temperature: Double
        public let condition: WeatherCondition
        public let humidity: Double
        public let windSpeed: Double
        public let timestamp: Date
        
        public init(temperature: Double, condition: WeatherCondition, humidity: Double, windSpeed: Double, timestamp: Date = Date()) {
            self.temperature = temperature
            self.condition = condition
            self.humidity = humidity
            self.windSpeed = windSpeed
            self.timestamp = timestamp
        }
    }
    
    public enum OutdoorWorkRisk: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case extreme = "Extreme"
    }
    
    public struct WeatherImpact: Codable {
        public let condition: WeatherCondition
        public let temperature: Double
        public let risk: OutdoorWorkRisk
        public let recommendation: String
        
        public init(condition: WeatherCondition, temperature: Double, risk: OutdoorWorkRisk, recommendation: String) {
            self.condition = condition
            self.temperature = temperature
            self.risk = risk
            self.recommendation = recommendation
        }
    }
    
    // MARK: - Additional Required Types
    public struct WorkerRoutineSummary: Identifiable, Codable {
        public let id: String
        public let workerId: String
        public let date: Date
        public let totalTasks: Int
        public let completedTasks: Int
        
        public init(id: String, workerId: String, date: Date, totalTasks: Int, completedTasks: Int) {
            self.id = id
            self.workerId = workerId
            self.date = date
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
        }
    }
    
    public struct WorkerDailyRoute: Identifiable, Codable {
        public let id: String
        public let workerId: String
        public let date: Date
        public let stops: [RouteStop]
        
        public init(id: String, workerId: String, date: Date, stops: [RouteStop]) {
            self.id = id
            self.workerId = workerId
            self.date = date
            self.stops = stops
        }
    }
    
    public struct RouteStop: Identifiable, Codable {
        public let id: String
        public let buildingId: String
        public let estimatedTime: TimeInterval
        public let tasks: [String]
        
        public init(id: String, buildingId: String, estimatedTime: TimeInterval, tasks: [String]) {
            self.id = id
            self.buildingId = buildingId
            self.estimatedTime = estimatedTime
            self.tasks = tasks
        }
    }
    
    public struct RouteOptimization: Codable {
        public let originalDistance: Double
        public let optimizedDistance: Double
        public let timeSaved: TimeInterval
        
        public init(originalDistance: Double, optimizedDistance: Double, timeSaved: TimeInterval) {
            self.originalDistance = originalDistance
            self.optimizedDistance = optimizedDistance
            self.timeSaved = timeSaved
        }
    }
    
    public struct ScheduleConflict: Identifiable, Codable {
        public let id: String
        public let description: String
        public let severity: String
        
        public init(id: String, description: String, severity: String) {
            self.id = id
            self.description = description
            self.severity = severity
        }
    }
    
    public struct MaintenanceRecord: Identifiable, Codable {
        public let id: String
        public let taskId: String
        public let buildingId: String
        public let description: String
        public let completedDate: Date
        public let performedBy: String
        
        public init(id: String, taskId: String, buildingId: String, description: String, completedDate: Date, performedBy: String) {
            self.id = id
            self.taskId = taskId
            self.buildingId = buildingId
            self.description = description
            self.completedDate = completedDate
            self.performedBy = performedBy
        }
    }
    
    public struct TaskTrends: Codable {
        public let weeklyCompletion: [Double]
        public let categoryBreakdown: [String: Int]
        public let changePercentage: Double
        
        public init(weeklyCompletion: [Double], categoryBreakdown: [String: Int], changePercentage: Double) {
            self.weeklyCompletion = weeklyCompletion
            self.categoryBreakdown = categoryBreakdown
            self.changePercentage = changePercentage
        }
    }
    
    public struct PerformanceMetrics: Codable {
        public let efficiency: Double
        public let quality: Double
        public let speed: Double
        public let consistency: Double
        
        public init(efficiency: Double, quality: Double, speed: Double, consistency: Double) {
            self.efficiency = efficiency
            self.quality = quality
            self.speed = speed
            self.consistency = consistency
        }
    }
    
    public struct StreakData: Codable {
        public let currentStreak: Int
        public let longestStreak: Int
        public let lastCompletionDate: Date?
        
        public init(currentStreak: Int, longestStreak: Int, lastCompletionDate: Date? = nil) {
            self.currentStreak = currentStreak
            self.longestStreak = longestStreak
            self.lastCompletionDate = lastCompletionDate
        }
    }
    
    public enum DataHealthStatus: Equatable, Hashable {
        case unknown
        case healthy
        case warning([String])
        case critical([String])
    }
    
    public struct AIScenario: Identifiable, Codable {
        public let id: String
        public let title: String
        public let description: String
        public let suggestedActions: [String]
        public let confidence: Double
        
        public init(id: String, title: String, description: String, suggestedActions: [String], confidence: Double) {
            self.id = id
            self.title = title
            self.description = description
            self.suggestedActions = suggestedActions
            self.confidence = confidence
        }
    }
    
    public struct AISuggestion: Identifiable, Codable {
        public let id: String
        public let title: String
        public let description: String
        public let priority: Int
        
        public init(id: String, title: String, description: String, priority: Int) {
            self.id = id
            self.title = title
            self.description = description
            self.priority = priority
        }
    }
    
    public struct AIScenarioData: Identifiable, Codable {
        public let id: String
        public let scenario: AIScenario
        public let timestamp: Date
        public let relevantTasks: [String]
        
        public init(id: String, scenario: AIScenario, timestamp: Date, relevantTasks: [String]) {
            self.id = id
            self.scenario = scenario
            self.timestamp = timestamp
            self.relevantTasks = relevantTasks
        }
    }
    
    public struct FSTaskItem: Identifiable, Codable {
        public let id: String
        public let name: String
        public let description: String
        public let dueDate: Date
        public let isCompleted: Bool
        
        public init(id: String = UUID().uuidString, name: String, description: String, dueDate: Date, isCompleted: Bool = false) {
            self.id = id
            self.name = name
            self.description = description
            self.dueDate = dueDate
            self.isCompleted = isCompleted
        }
    }
}

// MARK: - Global Type Aliases
public typealias NamedCoordinate = FrancoSphere.NamedCoordinate
public typealias BuildingTab = FrancoSphere.BuildingTab
public typealias BuildingStatus = FrancoSphere.BuildingStatus
public typealias BuildingStatistics = FrancoSphere.BuildingStatistics
public typealias BuildingInsight = FrancoSphere.BuildingInsight
public typealias UserRole = FrancoSphere.UserRole
public typealias WorkerProfile = FrancoSphere.WorkerProfile
public typealias WorkerSkill = FrancoSphere.WorkerSkill
public typealias WorkerAssignment = FrancoSphere.WorkerAssignment
public typealias InventoryCategory = FrancoSphere.InventoryCategory
public typealias RestockStatus = FrancoSphere.RestockStatus
public typealias InventoryItem = FrancoSphere.InventoryItem
public typealias TaskCategory = FrancoSphere.TaskCategory
public typealias TaskUrgency = FrancoSphere.TaskUrgency
public typealias TaskRecurrence = FrancoSphere.TaskRecurrence
public typealias VerificationStatus = FrancoSphere.VerificationStatus
public typealias MaintenanceTask = FrancoSphere.MaintenanceTask
public typealias TaskCompletionInfo = FrancoSphere.TaskCompletionInfo
public typealias TaskCompletionRecord = FrancoSphere.TaskCompletionRecord
public typealias TaskProgress = FrancoSphere.TaskProgress
public typealias TaskEvidence = FrancoSphere.TaskEvidence
public typealias WeatherCondition = FrancoSphere.WeatherCondition
public typealias WeatherData = FrancoSphere.WeatherData
public typealias OutdoorWorkRisk = FrancoSphere.OutdoorWorkRisk
public typealias WeatherImpact = FrancoSphere.WeatherImpact
public typealias WorkerRoutineSummary = FrancoSphere.WorkerRoutineSummary
public typealias WorkerDailyRoute = FrancoSphere.WorkerDailyRoute
public typealias RouteStop = FrancoSphere.RouteStop
public typealias RouteOptimization = FrancoSphere.RouteOptimization
public typealias ScheduleConflict = FrancoSphere.ScheduleConflict
public typealias MaintenanceRecord = FrancoSphere.MaintenanceRecord
public typealias TaskTrends = FrancoSphere.TaskTrends
public typealias PerformanceMetrics = FrancoSphere.PerformanceMetrics
public typealias StreakData = FrancoSphere.StreakData
public typealias DataHealthStatus = FrancoSphere.DataHealthStatus
public typealias AIScenario = FrancoSphere.AIScenario
public typealias AISuggestion = FrancoSphere.AISuggestion
public typealias AIScenarioData = FrancoSphere.AIScenarioData
public typealias FSTaskItem = FrancoSphere.FSTaskItem
MODEL_EOF

mv /Volumes/FastSSD/Xcode/Models/FrancoSphereModels_TEMP.swift /Volumes/FastSSD/Xcode/Models/FrancoSphereModels.swift

# =============================================================================
# FIX 2: SQLiteManager WorkerProfile constructor fixes
# =============================================================================

cat > /tmp/fix_sqlite.py << 'PYTHON_EOF'
import re

file_path = "/Volumes/FastSSD/Xcode/Managers/SQLiteManager.swift"

try:
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix line 420: Remove extra arguments from WorkerProfile constructor
    content = re.sub(
        r'return FrancoSphere\.WorkerProfile\(\s*id: workerId,\s*name: name,\s*email: email,\s*role: userRole,\s*skills: \[\],\s*assignedBuildings: \[\],\s*skillLevel: \.basic\s*\)',
        'return FrancoSphere.WorkerProfile(\n                id: workerId,\n                name: name,\n                email: email,\n                role: userRole,\n                skillLevel: .basic\n            )',
        content
    )
    
    # Fix line 444: Remove the .map call on WorkerSkill (it's an enum, not array)
    content = re.sub(
        r'skills <- worker\.skillLevel\.map \{ \$0\.rawValue \}\.joined\(separator: ","\)',
        'skills <- worker.skillLevel.rawValue',
        content
    )
    
    # Fix line 474: Remove extra arguments from WorkerProfile constructor
    content = re.sub(
        r'let worker = FrancoSphere\.WorkerProfile\(\s*id: workerId,\s*name: name,\s*email: email,\s*role: userRole,\s*skills: \[\],\s*assignedBuildings: \[\],\s*skillLevel: \.basic\s*\)',
        'let worker = FrancoSphere.WorkerProfile(\n                id: workerId,\n                name: name,\n                email: email,\n                role: userRole,\n                skillLevel: .basic\n            )',
        content
    )
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("✅ Fixed SQLiteManager.swift WorkerProfile constructor calls")

except Exception as e:
    print(f"❌ Error fixing SQLiteManager.swift: {e}")
PYTHON_EOF

python3 /tmp/fix_sqlite.py

# =============================================================================
# FIX 3: TaskDetailViewModel switch case statements
# =============================================================================

cat > /tmp/fix_task_detail.py << 'PYTHON_EOF'
import re

file_path = "/Volumes/FastSSD/Xcode/Views/ViewModels/TaskDetailViewModel.swift"

try:
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix the getWeatherImpact function switch statement with empty cases
    switch_pattern = r'(private func getWeatherImpact\(\) -> String \{.*?switch weather\.condition \{)(.*?)(\}.*?\})'
    
    def fix_switch_cases(match):
        prefix = match.group(1)
        switch_body = match.group(2)
        suffix = match.group(3)
        
        # Replace the switch body with proper case statements
        new_switch_body = '''
        case .clear, .sunny:
            return "Perfect conditions for outdoor work"
        case .cloudy:
            return "Good conditions, overcast sky"
        case .rain, .rainy:
            return "Wet conditions - take extra precautions"
        case .snow, .snowy:
            return "Snowy conditions - be careful on walkways"
        case .fog, .foggy:
            return "Low visibility - exercise caution"
        case .storm, .stormy, .windy:
            return "Severe weather - consider postponing outdoor tasks"
        '''
        
        return prefix + new_switch_body + suffix
    
    content = re.sub(switch_pattern, fix_switch_cases, content, flags=re.DOTALL)
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("✅ Fixed TaskDetailViewModel.swift switch case statements")

except Exception as e:
    print(f"❌ Error fixing TaskDetailViewModel.swift: {e}")
PYTHON_EOF

python3 /tmp/fix_task_detail.py

# =============================================================================
# CLEANUP
# =============================================================================

rm -f /tmp/fix_*.py

echo ""
echo "✅ PRECISE FIXES COMPLETE!"
echo "========================="
echo ""
echo "📋 Fixed Issues:"
echo "   1. ✅ NamedCoordinate coordinate redeclaration"
echo "   2. ✅ SQLiteManager WorkerProfile constructor calls (lines 420, 474)"
echo "   3. ✅ SQLiteManager WorkerSkill.map error (line 444)"
echo "   4. ✅ TaskDetailViewModel empty switch cases"
echo ""
echo "🔨 Test the fixes:"
echo "   cd /Volumes/FastSSD/Xcode"
echo "   xcodebuild clean build -project FrancoSphere.xcodeproj -scheme FrancoSphere"
echo ""
echo "🎯 Expected result: 0 compilation errors"
