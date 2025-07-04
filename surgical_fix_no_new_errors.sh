#!/bin/bash

# FrancoSphere Surgical Fix - No New Errors
# Analyzes existing code and only fixes what's broken without creating new issues

XCODE_PATH="/Volumes/FastSSD/Xcode"

echo "🔧 FrancoSphere Surgical Fix - No New Errors"
echo "============================================"

cd "$XCODE_PATH" || exit 1

# Step 1: Analyze what types already exist in FrancoSphereModels.swift
echo "📊 Step 1: Analyzing existing types..."

EXISTING_TYPES=$(grep -n "public struct\|public enum\|public class" "Models/FrancoSphereModels.swift" | head -20)
echo "Existing types found:"
echo "$EXISTING_TYPES"

# Step 2: Remove duplicate type definitions that we accidentally added
echo "🧹 Step 2: Removing duplicate type definitions..."

# Create a backup first
cp "Models/FrancoSphereModels.swift" "Models/FrancoSphereModels.swift.backup"

# Remove everything after "// Missing types added" to eliminate duplicates
sed -i '' '/\/\/ Missing types added/,$d' "Models/FrancoSphereModels.swift"

echo "   ✅ Duplicate definitions removed"

# Step 3: Check if MaintenanceTask exists and is public
echo "🔍 Step 3: Checking MaintenanceTask definition..."

if grep -q "public struct MaintenanceTask" "Models/FrancoSphereModels.swift"; then
    echo "   ✅ MaintenanceTask exists and is public"
else
    echo "   ⚠️ MaintenanceTask missing or not public"
    # Make MaintenanceTask public if it exists but isn't public
    sed -i '' 's/struct MaintenanceTask/public struct MaintenanceTask/g' "Models/FrancoSphereModels.swift"
    echo "   ✅ MaintenanceTask made public"
fi

# Step 4: Check if TaskCategory, TaskUrgency, TaskRecurrence are public
echo "🔍 Step 4: Checking enum definitions..."

for enum_type in "TaskCategory" "TaskUrgency" "TaskRecurrence"; do
    if grep -q "public enum $enum_type" "Models/FrancoSphereModels.swift"; then
        echo "   ✅ $enum_type is public"
    else
        sed -i '' "s/enum $enum_type/public enum $enum_type/g" "Models/FrancoSphereModels.swift"
        echo "   🔧 $enum_type made public"
    fi
done

# Step 5: Add ONLY truly missing types (check first if they exist)
echo "🔧 Step 5: Adding only missing types..."

# Check for TaskProgress
if ! grep -q "struct TaskProgress" "Models/FrancoSphereModels.swift"; then
    echo "   📝 Adding TaskProgress..."
    cat >> "Models/FrancoSphereModels.swift" << 'TASKPROGRESS'

    // MARK: - Missing Core Types
    
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
TASKPROGRESS
fi

# Check for missing view model types only if they don't exist
if ! grep -q "struct TaskTrends" "Models/FrancoSphereModels.swift"; then
    echo "   📝 Adding TaskTrends and related types..."
    cat >> "Models/FrancoSphereModels.swift" << 'VIEWMODELTYPES'
    
    public struct TaskTrends {
        public let weeklyCompletion: [DayProgress]
        public let categoryBreakdown: [CategoryProgress]
        public let trend: ProductivityTrend
        
        public init(weeklyCompletion: [DayProgress], categoryBreakdown: [CategoryProgress], trend: ProductivityTrend) {
            self.weeklyCompletion = weeklyCompletion
            self.categoryBreakdown = categoryBreakdown
            self.trend = trend
        }
    }
    
    public struct PerformanceMetrics {
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
    
    public struct StreakData {
        public let currentStreak: Int
        public let longestStreak: Int
        public let lastCompletionDate: Date?
        
        public init(currentStreak: Int, longestStreak: Int, lastCompletionDate: Date? = nil) {
            self.currentStreak = currentStreak
            self.longestStreak = longestStreak
            self.lastCompletionDate = lastCompletionDate
        }
    }
    
    public struct CategoryProgress {
        public let category: String
        public let completed: Int
        public let total: Int
        public let percentage: Double
        
        public init(category: String, completed: Int, total: Int, percentage: Double) {
            self.category = category
            self.completed = completed
            self.total = total
            self.percentage = percentage
        }
    }
    
    public struct DayProgress {
        public let date: Date
        public let completed: Int
        public let total: Int
        public let percentage: Double
        
        public init(date: Date, completed: Int, total: Int, percentage: Double) {
            self.date = date
            self.completed = completed
            self.total = total
            self.percentage = percentage
        }
    }
    
    public enum ProductivityTrend: String, CaseIterable, Codable {
        case stable = "stable"
        case improving = "improving"
        case declining = "declining"
    }

} // End FrancoSphere extension

// MARK: - Global Type Aliases (No Conflicts)
public typealias TSTaskProgress = FrancoSphere.TaskProgress
public typealias TSTaskTrends = FrancoSphere.TaskTrends  
public typealias TSPerformanceMetrics = FrancoSphere.PerformanceMetrics
public typealias TSStreakData = FrancoSphere.StreakData
public typealias TSCategoryProgress = FrancoSphere.CategoryProgress
public typealias TSDayProgress = FrancoSphere.DayProgress
public typealias TSProductivityTrend = FrancoSphere.ProductivityTrend
VIEWMODELTYPES
fi

# Step 6: Fix constructor calls using TS prefixes to avoid conflicts
echo "🔧 Step 6: Fixing constructor calls..."

if [ -f "Views/Main/TodayTasksViewModel.swift" ]; then
    sed -i '' 's/TaskTrends()/TSTaskTrends(weeklyCompletion: [], categoryBreakdown: [], trend: .stable)/g' "Views/Main/TodayTasksViewModel.swift"
    sed -i '' 's/PerformanceMetrics()/TSPerformanceMetrics(efficiency: 0.0, quality: 0.0, speed: 0.0, consistency: 0.0)/g' "Views/Main/TodayTasksViewModel.swift"
    sed -i '' 's/StreakData()/TSStreakData(currentStreak: 0, longestStreak: 0)/g' "Views/Main/TodayTasksViewModel.swift"
    echo "   ✅ Constructor calls fixed with TS prefixes"
fi

# Step 7: Test compilation
echo "🔨 Step 7: Testing compilation..."

BUILD_OUTPUT=$(xcodebuild clean build -project FrancoSphere.xcodeproj -scheme FrancoSphere -destination 'platform=iOS Simulator,name=iPhone 15' 2>&1)
ERROR_COUNT=$(echo "$BUILD_OUTPUT" | grep -c "error:" || echo "0")

echo ""
echo "📊 Build Results: $ERROR_COUNT errors"

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "🎉 SUCCESS: Zero compilation errors!"
else
    echo "⚠️ Still has $ERROR_COUNT errors"
    echo "Top 5 remaining errors:"
    echo "$BUILD_OUTPUT" | grep "error:" | head -5
fi

echo "🔧 Surgical fix complete!"
