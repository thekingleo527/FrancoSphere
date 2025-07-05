#!/bin/bash

echo "🔧 Fix FrancoSphereModels Redeclarations"
echo "========================================"
echo "Completely removing and rebuilding FrancoSphereModels.swift to eliminate duplicates"

cd "/Volumes/FastSSD/Xcode" || exit 1

# =============================================================================
# STEP 1: Remove existing file and create fresh version
# =============================================================================

echo ""
echo "🔧 Step 1: Removing existing FrancoSphereModels.swift and creating clean version..."

# Create backup of existing file
if [ -f "Models/FrancoSphereModels.swift" ]; then
    cp "Models/FrancoSphereModels.swift" "Models/FrancoSphereModels.swift.duplicate_backup.$(date +%s)"
    echo "✅ Created backup of existing models file"
    
    # Completely remove the existing file
    rm "Models/FrancoSphereModels.swift"
    echo "✅ Removed existing models file"
fi

# Create completely fresh FrancoSphereModels.swift with NO duplicates
cat > "Models/FrancoSphereModels.swift" << 'CLEAN_MODELS_EOF'
//
//  FrancoSphereModels.swift
//  FrancoSphere
//
//  ✅ CLEAN REBUILD - No duplicate declarations
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - FrancoSphere Namespace
public enum FrancoSphere {
    
    // MARK: - Geographic Models
    public struct NamedCoordinate: Identifiable, Codable, Equatable {
        public let id: String
        public let name: String
        public let latitude: Double
        public let longitude: Double
        public let address: String?
        public let imageAssetName: String?
        
        public var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        public init(id: String, name: String, latitude: Double, longitude: Double, address: String? = nil, imageAssetName: String? = nil) {
            self.id = id
            self.name = name
            self.latitude = latitude
            self.longitude = longitude
            self.address = address
            self.imageAssetName = imageAssetName
        }
        
        public init(id: String, name: String, coordinate: CLLocationCoordinate2D, address: String? = nil, imageAssetName: String? = nil) {
            self.id = id
            self.name = name
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
            self.address = address
            self.imageAssetName = imageAssetName
        }
        
        public static func == (lhs: NamedCoordinate, rhs: NamedCoordinate) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    // MARK: - Weather Models
    public enum WeatherCondition: String, Codable, CaseIterable {
        case clear = "Clear"
        case sunny = "Sunny"
        case cloudy = "Cloudy"
        case rain = "Rain"
        case rainy = "Rainy"
        case snow = "Snow"
        case snowy = "Snowy"
        case storm = "Storm"
        case stormy = "Stormy"
        case fog = "Fog"
        case foggy = "Foggy"
        case windy = "Windy"
        
        public var icon: String {
            switch self {
            case .clear, .sunny: return "sun.max.fill"
            case .cloudy: return "cloud.fill"
            case .rain, .rainy: return "cloud.rain.fill"
            case .snow, .snowy: return "cloud.snow.fill"
            case .storm, .stormy: return "cloud.bolt.fill"
            case .fog, .foggy: return "cloud.fog.fill"
            case .windy: return "wind"
            }
        }
    }
    
    public struct WeatherData: Codable {
        public let date: Date
        public let temperature: Double
        public let feelsLike: Double
        public let humidity: Int
        public let windSpeed: Double
        public let windDirection: Int
        public let precipitation: Double
        public let snow: Double
        public let visibility: Double
        public let pressure: Double
        public let condition: WeatherCondition
        public let icon: String
        
        public var timestamp: Date { date }
        
        public init(date: Date, temperature: Double, feelsLike: Double, humidity: Int, windSpeed: Double, windDirection: Int, precipitation: Double, snow: Double, visibility: Double, pressure: Double, condition: WeatherCondition, icon: String) {
            self.date = date
            self.temperature = temperature
            self.feelsLike = feelsLike
            self.humidity = humidity
            self.windSpeed = windSpeed
            self.windDirection = windDirection
            self.precipitation = precipitation
            self.snow = snow
            self.visibility = visibility
            self.pressure = pressure
            self.condition = condition
            self.icon = icon
        }
        
        public init(temperature: Double, condition: WeatherCondition, humidity: Double, windSpeed: Double, timestamp: Date) {
            self.init(date: timestamp, temperature: temperature, feelsLike: temperature, humidity: Int(humidity), windSpeed: windSpeed, windDirection: 0, precipitation: 0.0, snow: 0.0, visibility: 10.0, pressure: 1013.0, condition: condition, icon: condition.icon)
        }
    }
    
    public enum OutdoorWorkRisk: String, CaseIterable {
        case low = "Low Risk"
        case moderate = "Moderate Risk"
        case medium = "Medium Risk"
        case high = "High Risk"
        case extreme = "Extreme Risk"
        
        public var color: Color {
            switch self {
            case .low: return .green
            case .moderate, .medium: return .orange
            case .high: return .red
            case .extreme: return .purple
            }
        }
    }
    
    // MARK: - Task Models
    public enum TaskCategory: String, CaseIterable, Codable {
        case cleaning = "Cleaning"
        case maintenance = "Maintenance"
        case inspection = "Inspection"
        case repair = "Repair"
        case security = "Security"
        case landscaping = "Landscaping"
        case administrative = "Administrative"
        case emergency = "Emergency"
    }
    
    public enum TaskUrgency: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        case urgent = "Urgent"
    }
    
    public enum TaskRecurrence: String, CaseIterable, Codable {
        case none = "None"
        case oneTime = "One Time"
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }
    
    public enum VerificationStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case verified = "Verified"
        case approved = "Approved"
        case rejected = "Rejected"
        case failed = "Failed"
        case requiresReview = "Requires Review"
    }
    
    public struct MaintenanceTask: Identifiable, Codable {
        public let id: String
        public let title: String
        public let description: String
        public let category: TaskCategory
        public let urgency: TaskUrgency
        public let buildingId: String
        public let assignedTo: String?
        public let dueDate: Date?
        public let isCompleted: Bool
        public let completedDate: Date?
        public let completedBy: String?
        public let verificationStatus: VerificationStatus
        
        public var name: String { title }
        public var buildingID: String { buildingId }
        public var isComplete: Bool { isCompleted }
        
        public init(id: String, title: String, description: String, category: TaskCategory, urgency: TaskUrgency, buildingId: String, assignedTo: String? = nil, dueDate: Date? = nil, isCompleted: Bool = false, completedDate: Date? = nil, completedBy: String? = nil, verificationStatus: VerificationStatus = .pending) {
            self.id = id
            self.title = title
            self.description = description
            self.category = category
            self.urgency = urgency
            self.buildingId = buildingId
            self.assignedTo = assignedTo
            self.dueDate = dueDate
            self.isCompleted = isCompleted
            self.completedDate = completedDate
            self.completedBy = completedBy
            self.verificationStatus = verificationStatus
        }
    }
    
    // MARK: - Worker Models
    public enum WorkerSkill: String, CaseIterable, Codable {
        case basic = "Basic"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"
        case maintenance = "Maintenance"
        case electrical = "Electrical"
        case plumbing = "Plumbing"
        case hvac = "HVAC"
        case painting = "Painting"
        case carpentry = "Carpentry"
        case landscaping = "Landscaping"
        case security = "Security"
        case specialized = "Specialized"
    }
    
    public enum UserRole: String, Codable, CaseIterable {
        case admin
        case supervisor
        case worker
        case client
    }
    
    public struct WorkerProfile: Identifiable, Codable {
        public let id: String
        public let name: String
        public let email: String
        public let role: UserRole
        public var skills: [WorkerSkill]
        public var assignedBuildings: [String]
        public var isActive: Bool
        
        public init(id: String, name: String, email: String, role: UserRole, skills: [WorkerSkill] = [], assignedBuildings: [String] = [], isActive: Bool = true) {
            self.id = id
            self.name = name
            self.email = email
            self.role = role
            self.skills = skills
            self.assignedBuildings = assignedBuildings
            self.isActive = isActive
        }
    }
    
    public struct WorkerAssignment: Identifiable, Codable {
        public let id: String
        public let workerId: String
        public let buildingId: String
        public let taskId: String?
        public let assignedDate: Date
        public let isActive: Bool
        
        public init(id: String, workerId: String, buildingId: String, taskId: String? = nil, assignedDate: Date, isActive: Bool = true) {
            self.id = id
            self.workerId = workerId
            self.buildingId = buildingId
            self.taskId = taskId
            self.assignedDate = assignedDate
            self.isActive = isActive
        }
    }
    
    // MARK: - Inventory Models
    public enum InventoryCategory: String, CaseIterable, Codable {
        case cleaning = "Cleaning"
        case tools = "Tools"
        case safety = "Safety"
        case plumbing = "Plumbing"
        case electrical = "Electrical"
        case paint = "Paint"
        case hardware = "Hardware"
        case seasonal = "Seasonal"
        case maintenance = "Maintenance"
        case office = "Office"
        case other = "Other"
    }
    
    public enum RestockStatus: String, Codable, CaseIterable {
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
        public let unit: String
        public let minimumQuantity: Int
        public let buildingId: String
        public let location: String
        public let restockStatus: RestockStatus
        
        public init(id: String, name: String, category: InventoryCategory, quantity: Int, unit: String, minimumQuantity: Int, buildingId: String, location: String, restockStatus: RestockStatus) {
            self.id = id
            self.name = name
            self.category = category
            self.quantity = quantity
            self.unit = unit
            self.minimumQuantity = minimumQuantity
            self.buildingId = buildingId
            self.location = location
            self.restockStatus = restockStatus
        }
    }
    
    // MARK: - Task Context Models
    public struct ContextualTask: Identifiable, Codable {
        public let id: String
        public let maintenanceTask: MaintenanceTask
        public let buildingName: String?
        
        public var name: String { maintenanceTask.title }
        public var title: String { maintenanceTask.title }
        public var description: String { maintenanceTask.description }
        public var category: TaskCategory { maintenanceTask.category }
        public var urgency: TaskUrgency { maintenanceTask.urgency }
        public var buildingId: String { maintenanceTask.buildingId }
        public var isCompleted: Bool { maintenanceTask.isCompleted }
        
        public init(id: String, maintenanceTask: MaintenanceTask, buildingName: String? = nil) {
            self.id = id
            self.maintenanceTask = maintenanceTask
            self.buildingName = buildingName
        }
        
        public init(id: String, name: String, description: String, buildingId: String, workerId: String, isCompleted: Bool) {
            let task = MaintenanceTask(
                id: id,
                title: name,
                description: description,
                category: .maintenance,
                urgency: .medium,
                buildingId: buildingId,
                assignedTo: workerId,
                isCompleted: isCompleted
            )
            self.init(id: id, maintenanceTask: task)
        }
    }
    
    // MARK: - Worker Routine Models
    public struct WorkerRoutineSummary: Codable {
        public let totalRoutines: Int
        public let completedToday: Int
        public let averageCompletionTime: Double
        public let efficiencyScore: Double
        public let tasksOverdue: Int
        
        public init(totalRoutines: Int, completedToday: Int, averageCompletionTime: Double, efficiencyScore: Double = 0.0, tasksOverdue: Int = 0) {
            self.totalRoutines = totalRoutines
            self.completedToday = completedToday
            self.averageCompletionTime = averageCompletionTime
            self.efficiencyScore = efficiencyScore
            self.tasksOverdue = tasksOverdue
        }
    }
    
    public struct WorkerDailyRoute: Codable {
        public let workerId: String
        public let date: Date
        public let buildings: [NamedCoordinate]
        public let optimizedOrder: [String]
        public let totalEstimatedTime: TimeInterval
        public let totalDistance: Double
        public let stops: [RouteStop]
        
        public init(workerId: String, date: Date, buildings: [NamedCoordinate], optimizedOrder: [String], totalEstimatedTime: TimeInterval, totalDistance: Double, stops: [RouteStop] = []) {
            self.workerId = workerId
            self.date = date
            self.buildings = buildings
            self.optimizedOrder = optimizedOrder
            self.totalEstimatedTime = totalEstimatedTime
            self.totalDistance = totalDistance
            self.stops = stops
        }
    }
    
    public struct RouteOptimization: Identifiable, Codable {
        public let id: String
        public let suggestion: String
        public let timeSaving: TimeInterval
        public let distanceSaving: Double
        public let priority: Int
        
        public init(id: String, suggestion: String, timeSaving: TimeInterval, distanceSaving: Double, priority: Int) {
            self.id = id
            self.suggestion = suggestion
            self.timeSaving = timeSaving
            self.distanceSaving = distanceSaving
            self.priority = priority
        }
    }
    
    public struct ScheduleConflict: Identifiable, Codable {
        public let id: String
        public let description: String
        public let severity: TaskUrgency
        public let affectedTasks: [String]
        public let resolution: String?
        
        public init(id: String, description: String, severity: TaskUrgency, affectedTasks: [String], resolution: String? = nil) {
            self.id = id
            self.description = description
            self.severity = severity
            self.affectedTasks = affectedTasks
            self.resolution = resolution
        }
    }
    
    public struct RouteStop: Identifiable, Codable {
        public let id: String
        public let buildingId: String
        public let buildingName: String
        public let tasks: [ContextualTask]
        public let estimatedDuration: TimeInterval
        
        public init(id: String = UUID().uuidString, buildingId: String, buildingName: String, tasks: [ContextualTask], estimatedDuration: TimeInterval) {
            self.id = id
            self.buildingId = buildingId
            self.buildingName = buildingName
            self.tasks = tasks
            self.estimatedDuration = estimatedDuration
        }
    }
    
    // MARK: - Building Models
    public struct BuildingInsight: Identifiable, Codable {
        public let id: String
        public let title: String
        public let value: String
        public let trend: String
        public let category: String
        
        public init(id: String, title: String, value: String, trend: String, category: String) {
            self.id = id
            self.title = title
            self.value = value
            self.trend = trend
            self.category = category
        }
    }
    
    public enum BuildingTab: String, CaseIterable, Codable {
        case overview = "Overview"
        case tasks = "Tasks"
        case inventory = "Inventory"
        case insights = "Insights"
    }
    
    public enum BuildingStatus: String, CaseIterable, Codable {
        case active = "Active"
        case maintenance = "Maintenance"
        case inspection = "Inspection"
        case emergency = "Emergency"
    }
    
    // MARK: - Performance Models  
    public enum TrendDirection: String, Codable {
        case up = "up"
        case down = "down"
        case stable = "stable"
    }
    
    public struct TaskTrends: Codable {
        public let weeklyCompletion: [Double]
        public let categoryBreakdown: [String: Int]
        public let changePercentage: Double
        public let comparisonPeriod: String
        public let trend: TrendDirection
        
        public init(weeklyCompletion: [Double], categoryBreakdown: [String: Int], changePercentage: Double, comparisonPeriod: String, trend: TrendDirection) {
            self.weeklyCompletion = weeklyCompletion
            self.categoryBreakdown = categoryBreakdown
            self.changePercentage = changePercentage
            self.comparisonPeriod = comparisonPeriod
            self.trend = trend
        }
    }
    
    public struct PerformanceMetrics: Codable {
        public let efficiency: Double
        public let tasksCompleted: Int
        public let averageTime: Double
        public let qualityScore: Double
        public let lastUpdate: Date
        
        public init(efficiency: Double, tasksCompleted: Int, averageTime: Double, qualityScore: Double, lastUpdate: Date) {
            self.efficiency = efficiency
            self.tasksCompleted = tasksCompleted
            self.averageTime = averageTime
            self.qualityScore = qualityScore
            self.lastUpdate = lastUpdate
        }
    }
    
    public struct StreakData: Codable {
        public let currentStreak: Int
        public let longestStreak: Int
        public let lastUpdate: Date
        
        public init(currentStreak: Int, longestStreak: Int, lastUpdate: Date) {
            self.currentStreak = currentStreak
            self.longestStreak = longestStreak
            self.lastUpdate = lastUpdate
        }
    }
    
    public struct BuildingStatistics: Codable {
        public let completionRate: Double
        public let totalTasks: Int
        public let completedTasks: Int
        
        public init(completionRate: Double, totalTasks: Int, completedTasks: Int) {
            self.completionRate = completionRate
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
        }
    }
    
    // MARK: - Task Evidence and Progress
    public struct TaskEvidence: Codable {
        public let photos: [Data]
        public let timestamp: Date
        public let notes: String?
        
        public init(photos: [Data], timestamp: Date, notes: String? = nil) {
            self.photos = photos
            self.timestamp = timestamp
            self.notes = notes
        }
    }
    
    public struct TaskProgress: Codable {
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
    
    // MARK: - AI Models
    public enum AIScenario: String, Codable, CaseIterable {
        case routineIncomplete = "routineIncomplete"
        case pendingTasks = "pendingTasks"
        case missingPhoto = "missingPhoto"
        case clockOutReminder = "clockOutReminder"
        case weatherAlert = "weatherAlert"
        case buildingArrival = "buildingArrival"
        case taskCompletion = "taskCompletion"
        case inventoryLow = "inventoryLow"
    }
    
    public struct AISuggestion: Identifiable, Codable {
        public let id: String
        public let title: String
        public let description: String
        public let priority: Int
        public let scenario: AIScenario
        public let suggestedActions: [String]
        public let confidence: Double
        
        public init(id: String, title: String, description: String, priority: Int, scenario: AIScenario, suggestedActions: [String], confidence: Double) {
            self.id = id
            self.title = title
            self.description = description
            self.priority = priority
            self.scenario = scenario
            self.suggestedActions = suggestedActions
            self.confidence = confidence
        }
    }
    
    public struct AIScenarioData: Identifiable, Codable {
        public let id: String
        public let scenario: AIScenario
        public let message: String
        public let timestamp: Date
        public let confidence: Double
        public let priority: Int
        
        public init(id: String, scenario: AIScenario, message: String, timestamp: Date, confidence: Double, priority: Int) {
            self.id = id
            self.scenario = scenario
            self.message = message
            self.timestamp = timestamp
            self.confidence = confidence
            self.priority = priority
        }
    }
    
    // MARK: - Weather Impact
    public struct WeatherImpact: Codable {
        public let condition: WeatherCondition
        public let temperature: Double
        public let affectedTasks: [ContextualTask]
        public let recommendation: String
        
        public init(condition: WeatherCondition, temperature: Double, affectedTasks: [ContextualTask], recommendation: String) {
            self.condition = condition
            self.temperature = temperature
            self.affectedTasks = affectedTasks
            self.recommendation = recommendation
        }
    }
    
    // MARK: - System Models
    public enum DataHealthStatus: Codable, Equatable {
        case unknown
        case healthy
        case warning([String])
        case critical([String])
    }
    
    // MARK: - Additional Records
    public struct MaintenanceRecord: Identifiable, Codable {
        public let id: String
        public let taskId: String
        public let completedDate: Date
        public let notes: String
        
        public init(id: String, taskId: String, completedDate: Date, notes: String) {
            self.id = id
            self.taskId = taskId
            self.completedDate = completedDate
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
    
    // MARK: - Export Models (SINGLE DECLARATION ONLY)
    public struct ExportProgress {
        public let completed: Int
        public let total: Int
        public let percentage: Double
        
        public init(completed: Int, total: Int) {
            self.completed = completed
            self.total = total
            self.percentage = total > 0 ? Double(completed) / Double(total) * 100 : 0
        }
    }
    
    public enum ImportError: LocalizedError {
        case noSQLiteManager
        case invalidData(String)
        
        public var errorDescription: String? {
            switch self {
            case .noSQLiteManager:
                return "SQLiteManager not initialized"
            case .invalidData(let message):
                return "Invalid data: \(message)"
            }
        }
    }
}

// MARK: - Clean Type Aliases (SINGLE DECLARATION SECTION)
public typealias NamedCoordinate = FrancoSphere.NamedCoordinate
public typealias WeatherCondition = FrancoSphere.WeatherCondition
public typealias WeatherData = FrancoSphere.WeatherData
public typealias OutdoorWorkRisk = FrancoSphere.OutdoorWorkRisk
public typealias TaskCategory = FrancoSphere.TaskCategory
public typealias TaskUrgency = FrancoSphere.TaskUrgency
public typealias TaskRecurrence = FrancoSphere.TaskRecurrence
public typealias VerificationStatus = FrancoSphere.VerificationStatus
public typealias MaintenanceTask = FrancoSphere.MaintenanceTask
public typealias WorkerSkill = FrancoSphere.WorkerSkill
public typealias UserRole = FrancoSphere.UserRole
public typealias WorkerProfile = FrancoSphere.WorkerProfile
public typealias WorkerAssignment = FrancoSphere.WorkerAssignment
public typealias InventoryCategory = FrancoSphere.InventoryCategory
public typealias RestockStatus = FrancoSphere.RestockStatus
public typealias InventoryItem = FrancoSphere.InventoryItem
public typealias ContextualTask = FrancoSphere.ContextualTask
public typealias WorkerRoutineSummary = FrancoSphere.WorkerRoutineSummary
public typealias WorkerDailyRoute = FrancoSphere.WorkerDailyRoute
public typealias RouteOptimization = FrancoSphere.RouteOptimization
public typealias ScheduleConflict = FrancoSphere.ScheduleConflict
public typealias RouteStop = FrancoSphere.RouteStop
public typealias BuildingInsight = FrancoSphere.BuildingInsight
public typealias BuildingTab = FrancoSphere.BuildingTab
public typealias BuildingStatus = FrancoSphere.BuildingStatus
public typealias TaskTrends = FrancoSphere.TaskTrends
public typealias PerformanceMetrics = FrancoSphere.PerformanceMetrics
public typealias StreakData = FrancoSphere.StreakData
public typealias TrendDirection = FrancoSphere.TrendDirection
public typealias BuildingStatistics = FrancoSphere.BuildingStatistics
public typealias TaskEvidence = FrancoSphere.TaskEvidence
public typealias TaskProgress = FrancoSphere.TaskProgress
public typealias AIScenario = FrancoSphere.AIScenario
public typealias AISuggestion = FrancoSphere.AISuggestion
public typealias AIScenarioData = FrancoSphere.AIScenarioData
public typealias WeatherImpact = FrancoSphere.WeatherImpact
public typealias DataHealthStatus = FrancoSphere.DataHealthStatus
public typealias MaintenanceRecord = FrancoSphere.MaintenanceRecord
public typealias TaskCompletionRecord = FrancoSphere.TaskCompletionRecord
public typealias ExportProgress = FrancoSphere.ExportProgress
public typealias ImportError = FrancoSphere.ImportError

// Legacy compatibility
public typealias FSTaskItem = ContextualTask
public typealias DetailedWorker = WorkerProfile
CLEAN_MODELS_EOF

echo "✅ Created completely clean FrancoSphereModels.swift with NO duplicates"

# =============================================================================
# VERIFICATION
# =============================================================================

echo ""
echo "🔍 VERIFICATION: Checking for duplicate declarations..."

echo ""
echo "Checking line 24 (coordinate property):"
sed -n '24p' "Models/FrancoSphereModels.swift"

echo ""
echo "Searching for any TrendDirection declarations:"
grep -n "TrendDirection" "Models/FrancoSphereModels.swift" | head -5

echo ""
echo "Searching for any ExportProgress declarations:"
grep -n "ExportProgress" "Models/FrancoSphereModels.swift" | head -5

echo ""
echo "File structure verification:"
echo "Total lines: $(wc -l < Models/FrancoSphereModels.swift)"
echo "Namespace sections: $(grep -c "// MARK:" Models/FrancoSphereModels.swift)"

# =============================================================================
# BUILD TEST
# =============================================================================

echo ""
echo "🔨 Testing compilation..."
xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build -destination "platform=iOS Simulator,name=iPhone 15 Pro" 2>&1 | grep -E "(error|warning|FrancoSphereModels)" | head -20

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "🎯 REDECLARATION FIX COMPLETED!"
echo "==============================="
echo ""
echo "📋 What was fixed:"
echo "• ✅ Completely removed existing FrancoSphereModels.swift"
echo "• ✅ Created fresh file with single 'coordinate' property declaration"
echo "• ✅ Single TrendDirection enum declaration only"
echo "• ✅ Single ExportProgress struct declaration only"
echo "• ✅ Eliminated ALL duplicate type declarations"
echo "• ✅ Clean type alias section at end"
echo ""
echo "📂 Backup: Models/FrancoSphereModels.swift.duplicate_backup.[timestamp]"
echo ""
echo "🚀 Next: Check build output above - should have ZERO redeclaration errors!"

exit 0
