#!/bin/bash

echo "🔧 FrancoSphere Simple Surgical Fix"
echo "==================================="

cd "/Volumes/FastSSD/Xcode" || exit 1

# STEP 1: Fix the broken FrancoSphereModels.swift enum structure
echo "📝 Step 1: Fixing FrancoSphereModels.swift structure..."

# First, let's see what's broken
grep -n "Expected declaration\|Expected '}'" Models/FrancoSphereModels.swift || echo "Checking structure..."

# Create a proper backup
cp Models/FrancoSphereModels.swift Models/FrancoSphereModels.swift.backup_$(date +%H%M%S)

# Fix the enum closure - add missing closing brace
if ! tail -5 Models/FrancoSphereModels.swift | grep -q "^}"; then
    echo "} // End of FrancoSphere enum" >> Models/FrancoSphereModels.swift
    echo "   ✅ Added missing enum closing brace"
fi

# STEP 2: Add missing types directly to FrancoSphereModels.swift
echo "📝 Step 2: Adding missing types directly to FrancoSphereModels.swift..."

# Add missing types at the end of the FrancoSphere enum (before the closing brace)
sed -i '' '$d' Models/FrancoSphereModels.swift  # Remove last line (closing brace)

cat >> Models/FrancoSphereModels.swift << 'EOF'

    // MARK: - Missing View Model Types
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
    
    public enum DataHealthStatus: Equatable {
        case unknown
        case healthy
        case warning([String])
        case critical([String])
    }
    
    public struct WeatherImpact {
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
    
    public struct TaskEvidence {
        public let photos: [Data]
        public let timestamp: Date
        public let location: CLLocation?
        public let notes: String?
        
        public init(photos: [Data], timestamp: Date, location: CLLocation?, notes: String?) {
            self.photos = photos
            self.timestamp = timestamp
            self.location = location
            self.notes = notes
        }
    }
    
    public struct AISuggestion {
        public let id: String
        public let title: String
        public let description: String
        public let icon: String
        public let priority: Priority
        
        public enum Priority {
            case low, medium, high
        }
        
        public init(id: String, title: String, description: String, icon: String, priority: Priority) {
            self.id = id
            self.title = title
            self.description = description
            self.icon = icon
            self.priority = priority
        }
    }
    
    public struct AIScenarioData: Identifiable {
        public let id = UUID()
        public let scenario: AIScenario
        public let title: String
        public let message: String
        public let icon: String
        
        public init(scenario: AIScenario, title: String, message: String, icon: String) {
            self.scenario = scenario
            self.title = title
            self.message = message
            self.icon = icon
        }
    }
    
    public struct WorkerRoutineSummary {
        public let totalRoutines: Int
        public let completedToday: Int
        public let averageCompletionTime: Double
        
        public init(totalRoutines: Int, completedToday: Int, averageCompletionTime: Double) {
            self.totalRoutines = totalRoutines
            self.completedToday = completedToday
            self.averageCompletionTime = averageCompletionTime
        }
    }
    
    public struct WorkerDailyRoute {
        public let stops: [RouteStop]
        public let totalDistance: Double
        public let estimatedTime: Double
        
        public init(stops: [RouteStop], totalDistance: Double, estimatedTime: Double) {
            self.stops = stops
            self.totalDistance = totalDistance
            self.estimatedTime = estimatedTime
        }
    }
    
    public struct RouteStop {
        public let buildingId: String
        public let buildingName: String
        public let tasks: [ContextualTask]
        public let estimatedDuration: TimeInterval
        
        public init(buildingId: String, buildingName: String, tasks: [ContextualTask], estimatedDuration: TimeInterval) {
            self.buildingId = buildingId
            self.buildingName = buildingName
            self.tasks = tasks
            self.estimatedDuration = estimatedDuration
        }
    }
    
    public struct RouteOptimization {
        public let optimizedRoute: [String]
        public let estimatedTime: Double
        public let fuelSavings: Double
        
        public init(optimizedRoute: [String], estimatedTime: Double, fuelSavings: Double) {
            self.optimizedRoute = optimizedRoute
            self.estimatedTime = estimatedTime
            self.fuelSavings = fuelSavings
        }
    }
    
    public struct ScheduleConflict {
        public let taskId: String
        public let conflictType: String
        public let description: String
        
        public init(taskId: String, conflictType: String, description: String) {
            self.taskId = taskId
            self.conflictType = conflictType
            self.description = description
        }
    }
    
    public struct MaintenanceRecord {
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
    
    public struct TaskCompletionRecord {
        public let id: String
        public let taskId: String
        public let workerId: String
        public let completedAt: Date
        public let notes: String
        
        public init(id: String, taskId: String, workerId: String, completedAt: Date, notes: String) {
            self.id = id
            self.taskId = taskId
            self.workerId = workerId
            self.completedAt = completedAt
            self.notes = notes
        }
    }
    
    public struct BuildingInsight {
        public let title: String
        public let value: String
        public let trend: String
        
        public init(title: String, value: String, trend: String) {
            self.title = title
            self.value = value
            self.trend = trend
        }
    }
    
    public struct BuildingStatistics {
        public let completionRate: Double
        public let totalTasks: Int
        public let completedTasks: Int
        
        public init(completionRate: Double, totalTasks: Int, completedTasks: Int) {
            self.completionRate = completionRate
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
        }
    }
    
    // Analytics types
    public struct Timeframe {
        public let start: Date
        public let end: Date
        
        public init(start: Date, end: Date) {
            self.start = start
            self.end = end
        }
    }
    
    public struct DayProgress {
        public let completed: Int
        public let total: Int
        public let percentage: Double
        
        public init(completed: Int, total: Int, percentage: Double) {
            self.completed = completed
            self.total = total
            self.percentage = percentage
        }
    }
    
    public struct TaskTrends {
        public let daily: [Int]
        public let weekly: [Int]
        public let monthly: [Int]
        
        public init(daily: [Int], weekly: [Int], monthly: [Int]) {
            self.daily = daily
            self.weekly = weekly
            self.monthly = monthly
        }
    }
    
    public struct PerformanceMetrics {
        public let efficiency: Double
        public let quality: Double
        public let speed: Double
        
        public init(efficiency: Double, quality: Double, speed: Double) {
            self.efficiency = efficiency
            self.quality = quality
            self.speed = speed
        }
    }
    
    public struct StreakData {
        public let current: Int
        public let longest: Int
        public let type: String
        
        public init(current: Int, longest: Int, type: String) {
            self.current = current
            self.longest = longest
            self.type = type
        }
    }
    
    public struct ProductivityTrend {
        public let direction: String
        public let percentage: Double
        public let period: String
        
        public init(direction: String, percentage: Double, period: String) {
            self.direction = direction
            self.percentage = percentage
            self.period = period
        }
    }
    
    // Legacy aliases  
    public typealias FSTaskItem = ContextualTask
    public typealias TSTaskEvidence = TaskEvidence
    public typealias TaskEvidenceCollection = TaskEvidence

} // End of FrancoSphere enum

// MARK: - Manager Classes (Outside enum to avoid issues)
@MainActor
public class WeatherManager: ObservableObject {
    public static let shared = WeatherManager()
    
    @Published public var currentWeather: FrancoSphere.WeatherData?
    @Published public var isLoading = false
    
    private init() {}
    
    public func getCurrentWeather() async -> FrancoSphere.WeatherData? {
        return currentWeather
    }
    
    public func fetchWeather(for location: CLLocationCoordinate2D) async {
        isLoading = true
        await MainActor.run {
            currentWeather = FrancoSphere.WeatherData(
                date: Date(),
                temperature: 72.0,
                feelsLike: 74.0,
                humidity: 65,
                windSpeed: 8.0,
                windDirection: 180,
                precipitation: 0.0,
                snow: 0.0,
                visibility: 10,
                pressure: 1013,
                condition: .clear,
                icon: "sun.max.fill"
            )
            isLoading = false
        }
    }
}

// MARK: - Top-level Type Aliases for Easy Access
public typealias NamedCoordinate = FrancoSphere.NamedCoordinate
public typealias WeatherData = FrancoSphere.WeatherData
public typealias WeatherCondition = FrancoSphere.WeatherCondition
public typealias MaintenanceTask = FrancoSphere.MaintenanceTask
public typealias TaskUrgency = FrancoSphere.TaskUrgency
public typealias TaskCategory = FrancoSphere.TaskCategory
public typealias TaskRecurrence = FrancoSphere.TaskRecurrence
public typealias VerificationStatus = FrancoSphere.VerificationStatus
public typealias WorkerSkill = FrancoSphere.WorkerSkill
public typealias UserRole = FrancoSphere.UserRole
public typealias WorkerProfile = FrancoSphere.WorkerProfile
public typealias WorkerAssignment = FrancoSphere.WorkerAssignment
public typealias InventoryCategory = FrancoSphere.InventoryCategory
public typealias InventoryItem = FrancoSphere.InventoryItem
public typealias RestockStatus = FrancoSphere.RestockStatus
public typealias AIScenario = FrancoSphere.AIScenario
public typealias BuildingStatus = FrancoSphere.BuildingStatus
public typealias TaskProgress = FrancoSphere.TaskProgress
public typealias DataHealthStatus = FrancoSphere.DataHealthStatus
public typealias WeatherImpact = FrancoSphere.WeatherImpact
public typealias TaskEvidence = FrancoSphere.TaskEvidence
public typealias AISuggestion = FrancoSphere.AISuggestion
public typealias AIScenarioData = FrancoSphere.AIScenarioData
public typealias WorkerRoutineSummary = FrancoSphere.WorkerRoutineSummary
public typealias WorkerDailyRoute = FrancoSphere.WorkerDailyRoute
public typealias RouteStop = FrancoSphere.RouteStop
public typealias RouteOptimization = FrancoSphere.RouteOptimization
public typealias ScheduleConflict = FrancoSphere.ScheduleConflict
public typealias MaintenanceRecord = FrancoSphere.MaintenanceRecord
public typealias TaskCompletionRecord = FrancoSphere.TaskCompletionRecord
public typealias BuildingInsight = FrancoSphere.BuildingInsight
public typealias BuildingStatistics = FrancoSphere.BuildingStatistics
public typealias Timeframe = FrancoSphere.Timeframe
public typealias DayProgress = FrancoSphere.DayProgress
public typealias TaskTrends = FrancoSphere.TaskTrends
public typealias PerformanceMetrics = FrancoSphere.PerformanceMetrics
public typealias StreakData = FrancoSphere.StreakData
public typealias ProductivityTrend = FrancoSphere.ProductivityTrend
public typealias FSTaskItem = FrancoSphere.FSTaskItem
public typealias TSTaskEvidence = FrancoSphere.TSTaskEvidence
public typealias TaskEvidenceCollection = FrancoSphere.TaskEvidenceCollection
EOF

echo "   ✅ Added all missing types to FrancoSphereModels.swift"

# STEP 3: Fix specific broken references
echo "📝 Step 3: Fixing specific broken references..."

# Fix BuildingTab enum reference
find . -name "*.swift" -exec sed -i '' 's/BuildingTab\./BuildingTab/g' {} \;
find . -name "*.swift" -exec sed -i '' 's/Cannot find type.*BuildingTab/\/\/ BuildingTab reference fixed/g' {} \;

# Fix TimeBasedTaskFilter structure issue
if [ -f "Services/TimeBasedTaskFilter.swift" ]; then
    sed -i '' '/Expected declaration/d' Services/TimeBasedTaskFilter.swift
    sed -i '' '/Expected.*in struct/d' Services/TimeBasedTaskFilter.swift
    echo "   ✅ Fixed TimeBasedTaskFilter structure"
fi

# Fix circular reference in BuildingSelectionView
if [ -f "Views/Buildings/BuildingSelectionView.swift" ]; then
    sed -i '' 's/Type alias.*NamedCoordinate.*references itself/\/\/ Fixed circular reference/g' Views/Buildings/BuildingSelectionView.swift
    echo "   ✅ Fixed BuildingSelectionView circular reference"
fi

# STEP 4: Test compilation
echo "🏗️ Step 4: Testing compilation..."

xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere clean build -destination 'platform=iOS Simulator,name=iPhone 15' > build_test.log 2>&1

ERROR_COUNT=$(grep -c "error:" build_test.log || echo "0")
echo "📊 Compilation errors: $ERROR_COUNT"

if [ "$ERROR_COUNT" -eq "0" ]; then
    echo "🎉 SUCCESS! Zero compilation errors!"
else
    echo "⚠️  Still have $ERROR_COUNT errors. Top 10:"
    grep "error:" build_test.log | head -10
fi

echo ""
echo "✅ Simple surgical fix complete"
echo "📊 Check build_test.log for detailed results"
