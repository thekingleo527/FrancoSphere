#!/bin/bash
set -e

echo "🩺 FrancoSphere Surgical Build-Doctor v3.0"
echo "=========================================="
echo "Ultra-precise refactor bot targeting exact compilation errors"

cd "/Volumes/FastSSD/Xcode" || exit 1

TIMESTAMP=$(date +%s)

# =============================================================================
# 🔧 BACKUP ALL TARGET FILES
# =============================================================================

echo ""
echo "🔧 Creating timestamped backups..."

TARGET_FILES=(
    "Components/Design/ModelColorsExtensions.swift"
    "Components/Shared Components/AIScenarioSheetView.swift"
    "Components/Shared Components/HeroStatusCard.swift"
    "Components/Shared Components/AIAvatarOverlayView.swift"
    "Managers/AIAssistantManager.swift"
    "Models/FrancoSphereModels.swift"
    "Services/BuildingService.swift"
    "Views/ViewModels/WorkerDashboardViewModel.swift"
    "Views/Main/WorkerProfileView.swift"
)

for FILE in "${TARGET_FILES[@]}"; do
    if [ -f "$FILE" ]; then
        cp "$FILE" "$FILE.backup.$TIMESTAMP"
        echo "✅ Backed up $FILE"
    fi
done

# =============================================================================
# 🔧 FIX 1: Create AIModels.swift for missing AI types
# =============================================================================

echo ""
echo "🔧 Creating Models/AIModels.swift for AI types..."

cat > "Models/AIModels.swift" << 'AI_MODELS_EOF'
//
//  AIModels.swift
//  FrancoSphere
//
//  AI Assistant type definitions
//

import Foundation

// MARK: - AI Scenario Types
public struct AIScenario: Identifiable, Codable {
    public let id: String
    public let type: String
    public let title: String
    public let description: String
    public let timestamp: Date
    
    public init(id: String = UUID().uuidString, type: String = "general", title: String = "AI Scenario", description: String = "AI-generated scenario", timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.timestamp = timestamp
    }
}

public struct AISuggestion: Identifiable, Codable {
    public let id: String
    public let text: String
    public let actionType: String
    public let confidence: Double
    
    public init(id: String = UUID().uuidString, text: String, actionType: String = "general", confidence: Double = 0.8) {
        self.id = id
        self.text = text
        self.actionType = actionType
        self.confidence = confidence
    }
}

public struct AIScenarioData: Identifiable, Codable {
    public let id: String
    public let context: String
    public let workerId: String?
    public let buildingId: String?
    public let taskId: String?
    public let timestamp: Date
    
    public init(id: String = UUID().uuidString, context: String, workerId: String? = nil, buildingId: String? = nil, taskId: String? = nil, timestamp: Date = Date()) {
        self.id = id
        self.context = context
        self.workerId = workerId
        self.buildingId = buildingId
        self.taskId = taskId
        self.timestamp = timestamp
    }
}
AI_MODELS_EOF

echo "✅ Created AIModels.swift"

# =============================================================================
# 🔧 FIX 2: Completely rebuild FrancoSphereModels.swift
# =============================================================================

echo ""
echo "🔧 Completely rebuilding FrancoSphereModels.swift..."

cat > /tmp/rebuild_models.py << 'PYTHON_EOF'
def rebuild_francosphere_models():
    file_path = "/Volumes/FastSSD/Xcode/Models/FrancoSphereModels.swift"
    
    content = '''//
//  FrancoSphereModels.swift
//  FrancoSphere
//
//  Complete working model definitions - REBUILT
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - FrancoSphere Namespace
public enum FrancoSphere {
    
    // MARK: - Core Geographic Types
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
    }
    
    // MARK: - Weather Types
    public enum WeatherCondition: String, Codable, CaseIterable {
        case sunny = "sunny"
        case clear = "clear"
        case cloudy = "cloudy"
        case rainy = "rainy"
        case rain = "rain"
        case snowy = "snowy"
        case snow = "snow"
        case foggy = "foggy"
        case fog = "fog"
        case stormy = "stormy"
        case storm = "storm"
        case windy = "windy"
    }
    
    public struct WeatherData: Codable, Hashable {
        public let condition: WeatherCondition
        public let temperature: Double
        public let humidity: Double
        public let windSpeed: Double
        public let description: String
        
        public init(condition: WeatherCondition, temperature: Double, humidity: Double, windSpeed: Double, description: String) {
            self.condition = condition
            self.temperature = temperature
            self.humidity = humidity
            self.windSpeed = windSpeed
            self.description = description
        }
    }
    
    public enum OutdoorWorkRisk: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case extreme = "extreme"
    }
    
    // MARK: - Task Types
    public enum TaskCategory: String, Codable, CaseIterable {
        case cleaning = "Cleaning"
        case maintenance = "Maintenance"
        case repair = "Repair"
        case inspection = "Inspection"
        case sanitation = "Sanitation"
    }
    
    public enum TaskUrgency: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        case urgent = "Urgent"
    }
    
    public enum TaskRecurrence: String, Codable, CaseIterable {
        case none = "None"
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }
    
    public enum VerificationStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case approved = "Approved"
        case verified = "Verified"
        case rejected = "Rejected"
        case failed = "Failed"
        case requiresReview = "Requires Review"
    }
    
    public struct MaintenanceTask: Identifiable, Codable {
        public let id: String
        public let buildingId: String
        public let title: String
        public let description: String
        public let category: TaskCategory
        public let urgency: TaskUrgency
        public let dueDate: Date
        public let estimatedDuration: TimeInterval
        public let recurrence: TaskRecurrence
        public let requiredSkills: [String]
        public let verificationStatus: VerificationStatus
        public let assignedWorkerId: String?
        public let completedDate: Date?
        public let notes: String?
        
        public init(id: String = UUID().uuidString, buildingId: String, title: String, description: String, category: TaskCategory, urgency: TaskUrgency, dueDate: Date, estimatedDuration: TimeInterval = 3600, recurrence: TaskRecurrence = .none, requiredSkills: [String] = [], verificationStatus: VerificationStatus = .pending, assignedWorkerId: String? = nil, completedDate: Date? = nil, notes: String? = nil) {
            self.id = id
            self.buildingId = buildingId
            self.title = title
            self.description = description
            self.category = category
            self.urgency = urgency
            self.dueDate = dueDate
            self.estimatedDuration = estimatedDuration
            self.recurrence = recurrence
            self.requiredSkills = requiredSkills
            self.verificationStatus = verificationStatus
            self.assignedWorkerId = assignedWorkerId
            self.completedDate = completedDate
            self.notes = notes
        }
    }
    
    public struct ContextualTask: Identifiable, Codable {
        public let id: String
        public let name: String
        public let description: String
        public let buildingId: String
        public let workerId: String
        public let isCompleted: Bool
        public let dueDate: Date?
        
        public init(id: String = UUID().uuidString, name: String, description: String, buildingId: String, workerId: String, isCompleted: Bool = false, dueDate: Date? = nil) {
            self.id = id
            self.name = name
            self.description = description
            self.buildingId = buildingId
            self.workerId = workerId
            self.isCompleted = isCompleted
            self.dueDate = dueDate
        }
    }
    
    // MARK: - Worker Types
    public enum UserRole: String, Codable, CaseIterable {
        case admin = "Admin"
        case supervisor = "Supervisor"
        case worker = "Worker"
        case client = "Client"
    }
    
    public enum WorkerSkill: String, Codable, CaseIterable {
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
        case cleaning = "Cleaning"
    }
    
    public struct WorkerProfile: Identifiable, Codable {
        public let id: String
        public let name: String
        public let email: String
        public let phone: String?
        public let role: UserRole
        public let skills: [WorkerSkill]
        public let hourlyRate: Double?
        public let isActive: Bool
        public let profileImagePath: String?
        public let address: String?
        public let emergencyContact: String?
        public let notes: String?
        
        public init(id: String, name: String, email: String, phone: String?, role: UserRole, skills: [WorkerSkill], hourlyRate: Double?, isActive: Bool, profileImagePath: String?, address: String?, emergencyContact: String?, notes: String?) {
            self.id = id
            self.name = name
            self.email = email
            self.phone = phone
            self.role = role
            self.skills = skills
            self.hourlyRate = hourlyRate
            self.isActive = isActive
            self.profileImagePath = profileImagePath
            self.address = address
            self.emergencyContact = emergencyContact
            self.notes = notes
        }
    }
    
    public struct WorkerAssignment: Identifiable, Codable {
        public let id: String
        public let workerId: String
        public let buildingId: String
        public let assignedDate: Date
        public let isActive: Bool
        
        public init(id: String = UUID().uuidString, workerId: String, buildingId: String, assignedDate: Date, isActive: Bool = true) {
            self.id = id
            self.workerId = workerId
            self.buildingId = buildingId
            self.assignedDate = assignedDate
            self.isActive = isActive
        }
    }
    
    // MARK: - Inventory Types
    public enum InventoryCategory: String, Codable, CaseIterable {
        case cleaning = "Cleaning"
        case tools = "Tools"
        case hardware = "Hardware"
        case electrical = "Electrical"
        case plumbing = "Plumbing"
        case safety = "Safety"
        case office = "Office"
        case supplies = "Supplies"
        case maintenance = "Maintenance"
        case paint = "Paint"
        case seasonal = "Seasonal"
        case other = "Other"
    }
    
    public enum RestockStatus: String, Codable, CaseIterable {
        case inStock = "In Stock"
        case lowStock = "Low Stock"
        case outOfStock = "Out of Stock"
        case onOrder = "On Order"
        case ordered = "Ordered"
        case inTransit = "In Transit"
        case delivered = "Delivered"
        case cancelled = "Cancelled"
    }
    
    public struct InventoryItem: Identifiable, Codable {
        public let id: String
        public let name: String
        public let description: String?
        public let category: InventoryCategory
        public let quantity: Int
        public let minimumQuantity: Int
        public let unit: String
        public let costPerUnit: Double?
        public let supplier: String?
        public let restockStatus: RestockStatus
        public let lastRestocked: Date?
        
        public init(id: String = UUID().uuidString, name: String, description: String?, category: InventoryCategory, quantity: Int, minimumQuantity: Int, unit: String, costPerUnit: Double?, supplier: String?, restockStatus: RestockStatus, lastRestocked: Date?) {
            self.id = id
            self.name = name
            self.description = description
            self.category = category
            self.quantity = quantity
            self.minimumQuantity = minimumQuantity
            self.unit = unit
            self.costPerUnit = costPerUnit
            self.supplier = supplier
            self.restockStatus = restockStatus
            self.lastRestocked = lastRestocked
        }
    }
    
    // MARK: - Progress and Analytics Types
    public enum TrendDirection: String, Codable, CaseIterable {
        case up = "up"
        case down = "down"
        case stable = "stable"
    }
    
    public struct TaskProgress: Codable, Hashable {
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
    
    public struct TaskTrends: Codable {
        public let direction: TrendDirection
        public let percentage: Double
        public let period: String
        
        public init(direction: TrendDirection, percentage: Double, period: String) {
            self.direction = direction
            self.percentage = percentage
            self.period = period
        }
    }
    
    public struct PerformanceMetrics: Codable {
        public let completionRate: Double
        public let averageTime: TimeInterval
        public let qualityScore: Double
        
        public init(completionRate: Double, averageTime: TimeInterval, qualityScore: Double) {
            self.completionRate = completionRate
            self.averageTime = averageTime
            self.qualityScore = qualityScore
        }
    }
    
    public struct StreakData: Codable {
        public let currentStreak: Int
        public let bestStreak: Int
        public let lastCompletionDate: Date?
        
        public init(currentStreak: Int, bestStreak: Int, lastCompletionDate: Date?) {
            self.currentStreak = currentStreak
            self.bestStreak = bestStreak
            self.lastCompletionDate = lastCompletionDate
        }
    }
    
    public struct BuildingStatistics: Codable {
        public let buildingId: String
        public let totalTasks: Int
        public let completedTasks: Int
        public let completionRate: Double
        public let averageTaskTime: TimeInterval
        public let lastUpdated: Date
        
        public init(buildingId: String, totalTasks: Int, completedTasks: Int, completionRate: Double, averageTaskTime: TimeInterval, lastUpdated: Date) {
            self.buildingId = buildingId
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
            self.completionRate = completionRate
            self.averageTaskTime = averageTaskTime
            self.lastUpdated = lastUpdated
        }
    }
    
    // MARK: - Building Types
    public enum BuildingStatus: String, Codable, CaseIterable {
        case active = "Active"
        case inactive = "Inactive"
        case maintenance = "Maintenance"
        case closed = "Closed"
    }
    
    public enum BuildingTab: String, Codable, CaseIterable {
        case overview = "Overview"
        case tasks = "Tasks"
        case workers = "Workers"
        case maintenance = "Maintenance"
    }
    
    public struct BuildingInsight: Identifiable, Codable {
        public let id: String
        public let buildingId: String
        public let title: String
        public let description: String
        public let priority: TaskUrgency
        public let actionRequired: Bool
        
        public init(id: String = UUID().uuidString, buildingId: String, title: String, description: String, priority: TaskUrgency, actionRequired: Bool) {
            self.id = id
            self.buildingId = buildingId
            self.title = title
            self.description = description
            self.priority = priority
            self.actionRequired = actionRequired
        }
    }
    
    // MARK: - Maintenance Types
    public struct MaintenanceRecord: Identifiable, Codable {
        public let id: String
        public let buildingId: String
        public let workerId: String
        public let taskId: String
        public let description: String
        public let completedDate: Date
        public let notes: String?
        
        public init(id: String = UUID().uuidString, buildingId: String, workerId: String, taskId: String, description: String, completedDate: Date, notes: String?) {
            self.id = id
            self.buildingId = buildingId
            self.workerId = workerId
            self.taskId = taskId
            self.description = description
            self.completedDate = completedDate
            self.notes = notes
        }
    }
    
    public struct TaskCompletionRecord: Identifiable, Codable {
        public let id: String
        public let taskId: String
        public let workerId: String
        public let completedAt: Date
        public let notes: String?
        
        public init(id: String = UUID().uuidString, taskId: String, workerId: String, completedAt: Date, notes: String?) {
            self.id = id
            self.taskId = taskId
            self.workerId = workerId
            self.completedAt = completedAt
            self.notes = notes
        }
    }
    
    public struct TaskEvidence: Identifiable, Codable, Hashable, Equatable {
        public let id: String
        public let taskId: String
        public let photoURL: String?
        public let notes: String
        public let latitude: Double?
        public let longitude: Double?
        public let timestamp: Date
        
        public var location: CLLocationCoordinate2D? {
            guard let lat = latitude, let lng = longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        
        public init(id: String = UUID().uuidString, taskId: String, photoURL: String?, notes: String, location: CLLocationCoordinate2D?, timestamp: Date) {
            self.id = id
            self.taskId = taskId
            self.photoURL = photoURL
            self.notes = notes
            self.latitude = location?.latitude
            self.longitude = location?.longitude
            self.timestamp = timestamp
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(taskId)
            hasher.combine(timestamp)
        }
        
        public static func == (lhs: TaskEvidence, rhs: TaskEvidence) -> Bool {
            return lhs.id == rhs.id && lhs.taskId == rhs.taskId
        }
    }
    
    // MARK: - Worker Routine Types
    public struct WorkerDailyRoute: Identifiable, Codable {
        public let id: String
        public let workerId: String
        public let date: Date
        public let stops: [RouteStop]
        public let estimatedDuration: TimeInterval
        
        public init(id: String = UUID().uuidString, workerId: String, date: Date, stops: [RouteStop], estimatedDuration: TimeInterval) {
            self.id = id
            self.workerId = workerId
            self.date = date
            self.stops = stops
            self.estimatedDuration = estimatedDuration
        }
    }
    
    public struct RouteStop: Identifiable, Codable {
        public let id: String
        public let buildingId: String
        public let location: String
        public let estimatedArrival: Date
        public let estimatedDeparture: Date
        public let tasks: [String]
        
        public init(id: String = UUID().uuidString, buildingId: String, location: String, estimatedArrival: Date, estimatedDeparture: Date, tasks: [String]) {
            self.id = id
            self.buildingId = buildingId
            self.location = location
            self.estimatedArrival = estimatedArrival
            self.estimatedDeparture = estimatedDeparture
            self.tasks = tasks
        }
    }
    
    public struct RouteOptimization: Codable {
        public let totalDistance: Double
        public let totalTime: TimeInterval
        public let optimizationScore: Double
        
        public init(totalDistance: Double, totalTime: TimeInterval, optimizationScore: Double) {
            self.totalDistance = totalDistance
            self.totalTime = totalTime
            self.optimizationScore = optimizationScore
        }
    }
    
    public struct ScheduleConflict: Identifiable, Codable {
        public let id: String
        public let workerId: String
        public let conflictType: String
        public let description: String
        public let suggestedResolution: String?
        
        public init(id: String = UUID().uuidString, workerId: String, conflictType: String, description: String, suggestedResolution: String?) {
            self.id = id
            self.workerId = workerId
            self.conflictType = conflictType
            self.description = description
            self.suggestedResolution = suggestedResolution
        }
    }
    
    public struct WorkerRoutineSummary: Identifiable, Codable {
        public let id: String
        public let workerId: String
        public let date: Date
        public let totalTasks: Int
        public let completedTasks: Int
        public let routeEfficiency: Double
        
        public init(id: String = UUID().uuidString, workerId: String, date: Date, totalTasks: Int, completedTasks: Int, routeEfficiency: Double) {
            self.id = id
            self.workerId = workerId
            self.date = date
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
            self.routeEfficiency = routeEfficiency
        }
    }
    
    // MARK: - Weather Impact Types
    public struct WeatherImpact: Codable {
        public let severity: OutdoorWorkRisk
        public let affectedTasks: [String]
        public let recommendations: [String]
        
        public init(severity: OutdoorWorkRisk, affectedTasks: [String], recommendations: [String]) {
            self.severity = severity
            self.affectedTasks = affectedTasks
            self.recommendations = recommendations
        }
    }
    
    // MARK: - Data Health Types
    public enum DataHealthStatus: Codable {
        case healthy
        case warning(String)
        case error(String)
        case unknown
        
        public static let unknown = DataHealthStatus.unknown
    }
    
    // MARK: - Export/Import Types
    public struct ExportProgress: Codable {
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
                return "Invalid data: \\(message)"
            }
        }
    }
}

// MARK: - Type Aliases (Single Source)
public typealias NamedCoordinate = FrancoSphere.NamedCoordinate
public typealias WeatherCondition = FrancoSphere.WeatherCondition
public typealias WeatherData = FrancoSphere.WeatherData
public typealias OutdoorWorkRisk = FrancoSphere.OutdoorWorkRisk
public typealias TaskCategory = FrancoSphere.TaskCategory
public typealias TaskUrgency = FrancoSphere.TaskUrgency
public typealias TaskRecurrence = FrancoSphere.TaskRecurrence
public typealias VerificationStatus = FrancoSphere.VerificationStatus
public typealias MaintenanceTask = FrancoSphere.MaintenanceTask
public typealias ContextualTask = FrancoSphere.ContextualTask
public typealias UserRole = FrancoSphere.UserRole
public typealias WorkerSkill = FrancoSphere.WorkerSkill
public typealias WorkerProfile = FrancoSphere.WorkerProfile
public typealias WorkerAssignment = FrancoSphere.WorkerAssignment
public typealias InventoryCategory = FrancoSphere.InventoryCategory
public typealias RestockStatus = FrancoSphere.RestockStatus
public typealias InventoryItem = FrancoSphere.InventoryItem
public typealias TrendDirection = FrancoSphere.TrendDirection
public typealias TaskProgress = FrancoSphere.TaskProgress
public typealias TaskTrends = FrancoSphere.TaskTrends
public typealias PerformanceMetrics = FrancoSphere.PerformanceMetrics
public typealias StreakData = FrancoSphere.StreakData
public typealias BuildingStatistics = FrancoSphere.BuildingStatistics
public typealias BuildingStatus = FrancoSphere.BuildingStatus
public typealias BuildingTab = FrancoSphere.BuildingTab
public typealias BuildingInsight = FrancoSphere.BuildingInsight
public typealias MaintenanceRecord = FrancoSphere.MaintenanceRecord
public typealias TaskCompletionRecord = FrancoSphere.TaskCompletionRecord
public typealias TaskEvidence = FrancoSphere.TaskEvidence
public typealias WorkerDailyRoute = FrancoSphere.WorkerDailyRoute
public typealias RouteStop = FrancoSphere.RouteStop
public typealias RouteOptimization = FrancoSphere.RouteOptimization
public typealias ScheduleConflict = FrancoSphere.ScheduleConflict
public typealias WorkerRoutineSummary = FrancoSphere.WorkerRoutineSummary
public typealias WeatherImpact = FrancoSphere.WeatherImpact
public typealias DataHealthStatus = FrancoSphere.DataHealthStatus
public typealias ExportProgress = FrancoSphere.ExportProgress
public typealias ImportError = FrancoSphere.ImportError
'''
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("✅ Completely rebuilt FrancoSphereModels.swift")

if __name__ == "__main__":
    rebuild_francosphere_models()
PYTHON_EOF

python3 /tmp/rebuild_models.py

# =============================================================================
# 🔧 FIX 3: Add AIModels imports to AI-related files
# =============================================================================

echo ""
echo "🔧 Adding AIModels imports to AI-related files..."

AI_FILES=(
    "Components/Shared Components/AIScenarioSheetView.swift"
    "Components/Shared Components/AIAvatarOverlayView.swift"
    "Managers/AIAssistantManager.swift"
)

for FILE in "${AI_FILES[@]}"; do
    if [ -f "$FILE" ]; then
        if ! grep -q "import.*AIModels" "$FILE" 2>/dev/null; then
            sed -i '' '/import Foundation/a\
import AIModels
' "$FILE"
            echo "✅ Added AIModels import to $FILE"
        fi
    fi
done

# =============================================================================
# 🔧 FIX 4: Fix specific syntax issues
# =============================================================================

echo ""
echo "🔧 Fixing specific syntax issues..."

# Fix ModelColorsExtensions.swift line 49 - remove orphaned default
if [ -f "Components/Design/ModelColorsExtensions.swift" ]; then
    sed -i '' '49s/.*default.*/        \/\/ Fixed: removed orphaned default/' "Components/Design/ModelColorsExtensions.swift"
    echo "✅ Fixed orphaned default in ModelColorsExtensions.swift"
fi

# Fix HeroStatusCard.swift line 193 - Color.clear ambiguity
if [ -f "Components/Shared Components/HeroStatusCard.swift" ]; then
    sed -i '' 's/\.clear/Color.clear/g' "Components/Shared Components/HeroStatusCard.swift"
    echo "✅ Fixed Color.clear ambiguity in HeroStatusCard.swift"
fi

# =============================================================================
# 🔧 FIX 5: Fix BuildingService.swift actor isolation and constructor
# =============================================================================

echo ""
echo "🔧 Fixing BuildingService.swift..."

cat > /tmp/fix_building_service.py << 'PYTHON_EOF'
import re

def fix_building_service():
    file_path = "/Volumes/FastSSD/Xcode/Services/BuildingService.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Fix actor isolation by using 'self' instead of BuildingService.shared
        content = re.sub(r'BuildingService\.shared', 'self', content)
        
        # Fix NamedCoordinate constructor calls - replace coordinate: with latitude:, longitude:
        def fix_constructor(match):
            coord_match = re.search(r'CLLocationCoordinate2D\s*\(\s*latitude:\s*([\d.-]+)\s*,\s*longitude:\s*([\d.-]+)\s*\)', match.group(0))
            if coord_match:
                lat = coord_match.group(1)
                lng = coord_match.group(2)
                result = match.group(0).replace(f'coordinate: CLLocationCoordinate2D(latitude: {lat}, longitude: {lng})', f'latitude: {lat}, longitude: {lng}')
                return result
            return match.group(0)
        
        pattern = r'NamedCoordinate\([^)]*coordinate:\s*CLLocationCoordinate2D[^)]*\)[^)]*\)'
        content = re.sub(pattern, fix_constructor, content)
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        print("✅ Fixed BuildingService.swift")
        return True
        
    except Exception as e:
        print(f"❌ Error fixing BuildingService: {e}")
        return False

if __name__ == "__main__":
    fix_building_service()
PYTHON_EOF

python3 /tmp/fix_building_service.py

# =============================================================================
# 🔧 FIX 6: Fix ambiguous type references
# =============================================================================

echo ""
echo "🔧 Fixing ambiguous type references..."

# Fix WorkerDashboardViewModel.swift
if [ -f "Views/ViewModels/WorkerDashboardViewModel.swift" ]; then
    sed -i '' 's/DataHealthStatus/FrancoSphere.DataHealthStatus/g' "Views/ViewModels/WorkerDashboardViewModel.swift"
    echo "✅ Fixed DataHealthStatus references in WorkerDashboardViewModel.swift"
fi

# Fix WorkerProfileView.swift
if [ -f "Views/Main/WorkerProfileView.swift" ]; then
    sed -i '' 's/TrendDirection/FrancoSphere.TrendDirection/g' "Views/Main/WorkerProfileView.swift"
    echo "✅ Fixed TrendDirection references in WorkerProfileView.swift"
fi

# =============================================================================
# 🔧 BUILD TEST
# =============================================================================

echo ""
echo "🔨 Running final build test..."

BUILD_OUTPUT=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build -destination "platform=iOS Simulator,name=iPhone 15 Pro" 2>&1)

ERROR_COUNT=$(echo "$BUILD_OUTPUT" | grep -c " error:" || echo "0")

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo ""
    echo "🟢 ✅ BUILD CLEAN"
    echo "================="
    echo "🎉 FrancoSphere compiled successfully with 0 errors!"
    echo "🧹 Cleaning up old backups..."
    find . -name "*.backup.*" -mtime +7 -delete 2>/dev/null || true
    echo "✅ All fixes applied successfully"
else
    echo ""
    echo "🔴 ❌ BUILD FAILED"
    echo "=================="
    echo "❌ $ERROR_COUNT compilation errors remain"
    echo ""
    echo "📋 First 20 remaining errors:"
    echo "$BUILD_OUTPUT" | grep " error:" | head -20
    exit 1
fi

echo ""
echo "🩺 Surgical Build-Doctor v3.0 - COMPLETE"
echo "========================================"
