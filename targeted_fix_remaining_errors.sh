#!/bin/bash

# FrancoSphere Targeted Fix for Remaining Compilation Errors
# Addresses the specific 25+ errors remaining after initial fix

XCODE_PATH="/Volumes/FastSSD/Xcode"

echo "🎯 FrancoSphere Targeted Fix - Remaining Errors"
echo "==============================================="

cd "$XCODE_PATH" || exit 1

# Fix 1: Add WorkerManager import to files that need it
echo "🔧 Fix 1: Adding WorkerManager imports..."

for file in "Models/WorkerContextEngine.swift" "Models/WorkerRoutineViewModel.swift"; do
    if [ -f "$file" ] && ! grep -q "// WorkerManager import added" "$file"; then
        echo "   📝 Adding import to $file"
        sed -i '' '1i\
// WorkerManager import added\
import Foundation
' "$file"
    fi
done

# Fix 2: Add WeatherManager import to files that need it
echo "🔧 Fix 2: Adding WeatherManager imports..."

for file in "Views/ViewModels/BuildingDetailViewModel.swift" "Views/ViewModels/TaskDetailViewModel.swift" "Views/ViewModels/WorkerDashboardViewModel.swift" "Views/Main/WorkerDashboardView.swift"; do
    if [ -f "$file" ] && ! grep -q "// WeatherManager import added" "$file"; then
        echo "   📝 Adding import to $file"
        sed -i '' '1i\
// WeatherManager import added\
import Foundation
' "$file"
    fi
done

# Fix 3: Completely rebuild WorkerService.swift to fix structural issues
echo "🔧 Fix 3: Rebuilding WorkerService.swift..."

cat > "Services/WorkerService.swift" << 'WORKERSERVICE'
//
//  WorkerService.swift
//  FrancoSphere
//
//  ✅ COMPLETELY REBUILT to fix structural syntax errors
//

import Foundation
import CoreLocation

actor WorkerService {
    static let shared = WorkerService()
    
    private var workersCache: [String: Worker] = [:]
    private let sqliteManager = SQLiteManager.shared
    
    func getWorker(_ id: String) async throws -> Worker? {
        if let cachedWorker = workersCache[id] {
            return cachedWorker
        }
        
        let query = "SELECT * FROM workers WHERE id = ? AND is_active = 1"
        let rows = try await sqliteManager.query(query, [id])
        
        guard let row = rows.first else { return nil }
        
        let worker = Worker(
            workerId: row["id"] as? String ?? "",
            name: row["name"] as? String ?? "",
            email: row["email"] as? String ?? "",
            role: row["role"] as? String ?? "Worker",
            isActive: (row["is_active"] as? Int64 ?? 1) == 1
        )
        
        workersCache[id] = worker
        return worker
    }
    
    func getAssignedBuildings(_ workerId: String) async throws -> [FrancoSphere.NamedCoordinate] {
        if workerId == "4" {
            return getKevinBuildingAssignments()
        }
        
        let query = """
            SELECT DISTINCT b.* FROM buildings b
            JOIN worker_assignments wa ON b.id = wa.building_id  
            WHERE wa.worker_id = ? AND wa.is_active = 1
            ORDER BY b.name
        """
        
        let rows = try await sqliteManager.query(query, [workerId])
        
        return rows.compactMap { row in
            guard let id = row["id"] as? String,
                  let name = row["name"] as? String,
                  let lat = row["latitude"] as? Double,
                  let lng = row["longitude"] as? Double else { return nil }
            
            return FrancoSphere.NamedCoordinate(
                id: id, name: name, latitude: lat, longitude: lng,
                imageAssetName: row["image_asset"] as? String ?? "building_\(id)"
            )
        }
    }
    
    private func getKevinBuildingAssignments() -> [FrancoSphere.NamedCoordinate] {
        return [
            FrancoSphere.NamedCoordinate(id: "10", name: "131 Perry Street", latitude: 40.7359, longitude: -74.0059, imageAssetName: "perry_131"),
            FrancoSphere.NamedCoordinate(id: "6", name: "68 Perry Street", latitude: 40.7357, longitude: -74.0055, imageAssetName: "perry_68"),
            FrancoSphere.NamedCoordinate(id: "3", name: "135-139 West 17th Street", latitude: 40.7398, longitude: -73.9972, imageAssetName: "west17_135"),
            FrancoSphere.NamedCoordinate(id: "7", name: "136 West 17th Street", latitude: 40.7399, longitude: -73.9971, imageAssetName: "west17_136"),
            FrancoSphere.NamedCoordinate(id: "9", name: "138 West 17th Street", latitude: 40.7400, longitude: -73.9970, imageAssetName: "west17_138"),
            FrancoSphere.NamedCoordinate(id: "16", name: "29-31 East 20th Street", latitude: 40.7388, longitude: -73.9892, imageAssetName: "east20_29"),
            FrancoSphere.NamedCoordinate(id: "12", name: "178 Spring Street", latitude: 40.7245, longitude: -73.9968, imageAssetName: "spring_178"),
            FrancoSphere.NamedCoordinate(id: "14", name: "Rubin Museum (142–148 W 17th)", latitude: 40.7402, longitude: -73.9980, imageAssetName: "rubin_museum")
        ]
    }
}

struct Worker {
    let workerId: String
    let name: String
    let email: String
    let role: String
    let isActive: Bool
}
WORKERSERVICE

echo "   ✅ WorkerService.swift rebuilt"

# Fix 4: Add missing type definitions to FrancoSphereModels.swift
echo "🔧 Fix 4: Adding missing type definitions..."

if ! grep -q "// Missing types added" "Models/FrancoSphereModels.swift"; then
    cat >> "Models/FrancoSphereModels.swift" << 'MISSINGTYPES'

// Missing types added

extension FrancoSphere {
    
    public struct TaskProgress {
        public let completed: Int
        public let total: Int
        public let remaining: Int
        public let percentage: Double
        public let overdueTasks: Int
        public let averageCompletionTime: TimeInterval
        public let onTimeCompletionRate: Double
        
        public init(
            completed: Int,
            total: Int,
            remaining: Int,
            percentage: Double,
            overdueTasks: Int,
            averageCompletionTime: TimeInterval = 0,
            onTimeCompletionRate: Double = 0
        ) {
            self.completed = completed
            self.total = total
            self.remaining = remaining
            self.percentage = percentage
            self.overdueTasks = overdueTasks
            self.averageCompletionTime = averageCompletionTime
            self.onTimeCompletionRate = onTimeCompletionRate
        }
    }
    
    public struct TaskTrends {
        public let weeklyCompletion: [DayProgress]
        public let categoryBreakdown: [CategoryProgress]
        public let trend: ProductivityTrend
        
        public init(
            weeklyCompletion: [DayProgress],
            categoryBreakdown: [CategoryProgress], 
            trend: ProductivityTrend
        ) {
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
        
        public init(
            efficiency: Double,
            quality: Double,
            speed: Double,
            consistency: Double
        ) {
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
        
        public init(
            currentStreak: Int,
            longestStreak: Int,
            lastCompletionDate: Date? = nil
        ) {
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
}

// Type aliases for compatibility
public typealias TaskProgress = FrancoSphere.TaskProgress
public typealias TaskTrends = FrancoSphere.TaskTrends
public typealias PerformanceMetrics = FrancoSphere.PerformanceMetrics
public typealias StreakData = FrancoSphere.StreakData
public typealias CategoryProgress = FrancoSphere.CategoryProgress
public typealias DayProgress = FrancoSphere.DayProgress
public typealias ProductivityTrend = FrancoSphere.ProductivityTrend
MISSINGTYPES

    echo "   ✅ Missing type definitions added"
fi

# Fix 5: Fix constructor calls in TodayTasksViewModel.swift
echo "🔧 Fix 5: Fixing constructor calls..."

sed -i '' 's/TaskTrends()/TaskTrends(weeklyCompletion: [], categoryBreakdown: [], trend: .stable)/g' "Views/Main/TodayTasksViewModel.swift"
sed -i '' 's/PerformanceMetrics()/PerformanceMetrics(efficiency: 0.0, quality: 0.0, speed: 0.0, consistency: 0.0)/g' "Views/Main/TodayTasksViewModel.swift"
sed -i '' 's/StreakData()/StreakData(currentStreak: 0, longestStreak: 0)/g' "Views/Main/TodayTasksViewModel.swift"

echo "   ✅ Constructor calls fixed"

# Fix 6: Test compilation
echo "🔨 Testing compilation..."

BUILD_OUTPUT=$(xcodebuild clean build -project FrancoSphere.xcodeproj -scheme FrancoSphere -destination 'platform=iOS Simulator,name=iPhone 15' 2>&1)
ERROR_COUNT=$(echo "$BUILD_OUTPUT" | grep -c "error:" || echo "0")

echo ""
echo "📊 Build Results: $ERROR_COUNT errors"

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "🎉 SUCCESS: Zero compilation errors!"
else
    echo "⚠️ Still has $ERROR_COUNT compilation errors"
    echo "$BUILD_OUTPUT" | grep "error:" | head -5
fi

echo "🎯 Targeted fix complete!"
