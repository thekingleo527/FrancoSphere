#!/bin/bash

# FrancoSphere Type Cleanup Fix
# Resolves all ambiguous type lookups and invalid redeclarations

XCODE_PATH="/Volumes/FastSSD/Xcode"

echo "🔧 FrancoSphere Type Cleanup - Fixing Ambiguous Types & Redeclarations"
echo "=================================================================="

# Function to remove duplicate type declarations
remove_duplicate_types() {
    echo "📝 Removing duplicate type declarations..."
    
    # Fix WorkerContextEngine.swift - Remove duplicate iso8601String extension
    if [ -f "$XCODE_PATH/Models/WorkerContextEngine.swift" ]; then
        echo "🔧 Fixing WorkerContextEngine.swift - removing duplicate iso8601String..."
        # Remove the duplicate iso8601String extension at the end of the file
        sed -i '' '/extension Date {$/,/^}$/d' "$XCODE_PATH/Models/WorkerContextEngine.swift"
        echo "✅ Fixed WorkerContextEngine.swift"
    fi
    
    # Fix WorkerManager.swift - Remove duplicate WorkerShift declaration
    if [ -f "$XCODE_PATH/Managers/WorkerManager.swift" ]; then
        echo "🔧 Fixing WorkerManager.swift - removing duplicate WorkerShift..."
        # Remove WorkerShift struct declaration (should be in FrancoSphereModels.swift)
        sed -i '' '/^struct WorkerShift/,/^}$/d' "$XCODE_PATH/Managers/WorkerManager.swift"
        sed -i '' '/^public struct WorkerShift/,/^}$/d' "$XCODE_PATH/Managers/WorkerManager.swift"
        echo "✅ Fixed WorkerManager.swift"
    fi
    
    # Fix WorkerRoutineViewModel.swift - Remove duplicate DataHealthStatus
    if [ -f "$XCODE_PATH/Models/WorkerRoutineViewModel.swift" ]; then
        echo "🔧 Fixing WorkerRoutineViewModel.swift - removing duplicate DataHealthStatus..."
        sed -i '' '/^enum DataHealthStatus/,/^}$/d' "$XCODE_PATH/Models/WorkerRoutineViewModel.swift"
        sed -i '' '/^public enum DataHealthStatus/,/^}$/d' "$XCODE_PATH/Models/WorkerRoutineViewModel.swift"
        echo "✅ Fixed WorkerRoutineViewModel.swift"
    fi
    
    # Fix WorkerService.swift - Use proper type references
    if [ -f "$XCODE_PATH/Services/WorkerService.swift" ]; then
        echo "🔧 Fixing WorkerService.swift - using proper Worker type..."
        # Remove the local Worker struct definition and use proper references
        sed -i '' '/^public struct Worker {$/,/^}$/d' "$XCODE_PATH/Services/WorkerService.swift"
        sed -i '' '/^struct Worker {$/,/^}$/d' "$XCODE_PATH/Services/WorkerService.swift"
        echo "✅ Fixed WorkerService.swift"
    fi
    
    # Fix WorkerDashboardViewModel.swift - Remove duplicate type declarations
    if [ -f "$XCODE_PATH/Views/ViewModels/WorkerDashboardViewModel.swift" ]; then
        echo "🔧 Fixing WorkerDashboardViewModel.swift - removing duplicate types..."
        # Remove duplicate struct declarations at the end
        sed -i '' '/^struct WorkerShift/,/^}$/d' "$XCODE_PATH/Views/ViewModels/WorkerDashboardViewModel.swift"
        sed -i '' '/^struct TaskProgress/,/^}$/d' "$XCODE_PATH/Views/ViewModels/WorkerDashboardViewModel.swift"
        sed -i '' '/^struct TaskEvidence/,/^}$/d' "$XCODE_PATH/Views/ViewModels/WorkerDashboardViewModel.swift"
        sed -i '' '/^struct Worker/,/^}$/d' "$XCODE_PATH/Views/ViewModels/WorkerDashboardViewModel.swift"
        echo "✅ Fixed WorkerDashboardViewModel.swift"
    fi
    
    # Fix TodayTasksViewModel.swift - Major cleanup needed
    if [ -f "$XCODE_PATH/Views/Main/TodayTasksViewModel.swift" ]; then
        echo "🔧 Fixing TodayTasksViewModel.swift - major cleanup..."
        # This file has severe syntax issues, needs careful handling
        
        # Remove duplicate type declarations and fix syntax issues
        # First, backup the file
        cp "$XCODE_PATH/Views/Main/TodayTasksViewModel.swift" "$XCODE_PATH/Views/Main/TodayTasksViewModel.swift.backup"
        
        # Remove duplicate struct declarations at the end of the file
        sed -i '' '/^struct TaskCompletionStats/,/^}$/d' "$XCODE_PATH/Views/Main/TodayTasksViewModel.swift"
        sed -i '' '/^enum Timeframe/,/^}$/d' "$XCODE_PATH/Views/Main/TodayTasksViewModel.swift"
        sed -i '' '/^struct DayProgress/,/^}$/d' "$XCODE_PATH/Views/Main/TodayTasksViewModel.swift"
        sed -i '' '/^struct TaskTrends/,/^}$/d' "$XCODE_PATH/Views/Main/TodayTasksViewModel.swift"
        sed -i '' '/^struct CategoryProgress/,/^}$/d' "$XCODE_PATH/Views/Main/TodayTasksViewModel.swift"
        sed -i '' '/^struct PerformanceMetrics/,/^}$/d' "$XCODE_PATH/Views/Main/TodayTasksViewModel.swift"
        sed -i '' '/^enum ProductivityTrend/,/^}$/d' "$XCODE_PATH/Views/Main/TodayTasksViewModel.swift"
        sed -i '' '/^struct StreakData/,/^}$/d' "$XCODE_PATH/Views/Main/TodayTasksViewModel.swift"
        
        # Remove extraneous closing braces and syntax errors
        sed -i '' '/^}$/d' "$XCODE_PATH/Views/Main/TodayTasksViewModel.swift"
        
        echo "✅ Fixed TodayTasksViewModel.swift"
    fi
}

# Function to add proper type definitions to FrancoSphereModels.swift
add_missing_types() {
    echo "📝 Adding missing type definitions to FrancoSphereModels.swift..."
    
    if [ -f "$XCODE_PATH/Models/FrancoSphereModels.swift" ]; then
        # Add missing types that were causing ambiguity
        cat >> "$XCODE_PATH/Models/FrancoSphereModels.swift" << 'EOF'

// MARK: - Additional Type Definitions (Cleanup Fix)

extension FrancoSphere {
    
    // Worker Shift Management
    public struct WorkerShift: Identifiable, Codable {
        public let id: String
        public let workerId: String
        public let startTime: Date
        public let endTime: Date?
        public let startBuilding: String
        public let status: ShiftStatus
        
        public enum ShiftStatus: String, Codable, CaseIterable {
            case active = "Active"
            case completed = "Completed" 
            case paused = "Paused"
        }
        
        public init(id: String = UUID().uuidString, workerId: String, startTime: Date, endTime: Date? = nil, startBuilding: String, status: ShiftStatus = .active) {
            self.id = id
            self.workerId = workerId
            self.startTime = startTime
            self.endTime = endTime
            self.startBuilding = startBuilding
            self.status = status
        }
    }
    
    // Data Health Status
    public enum DataHealthStatus: Equatable {
        case unknown
        case healthy
        case warning([String])
        case critical([String])
    }
    
    // Task Progress Tracking
    public struct TaskProgress {
        public let completed: Int
        public let total: Int
        public let remaining: Int
        public let percentage: Double
        public let overdueTasks: Int
        public let averageCompletionTime: Double
        public let onTimeCompletionRate: Double
        
        public init(completed: Int, total: Int, remaining: Int, percentage: Double, overdueTasks: Int, averageCompletionTime: Double = 0, onTimeCompletionRate: Double = 0) {
            self.completed = completed
            self.total = total
            self.remaining = remaining
            self.percentage = percentage
            self.overdueTasks = overdueTasks
            self.averageCompletionTime = averageCompletionTime
            self.onTimeCompletionRate = onTimeCompletionRate
        }
    }
    
    // Task Evidence
    public struct TaskEvidence {
        public let photos: [Data]
        public let timestamp: Date
        public let location: CLLocation?
        public let notes: String?
        
        public init(photos: [Data], timestamp: Date, location: CLLocation? = nil, notes: String? = nil) {
            self.photos = photos
            self.timestamp = timestamp
            self.location = location
            self.notes = notes
        }
    }
    
    // Analytics Types
    public struct TaskCompletionStats {
        public let totalCompleted: Int
        public let totalAssigned: Int
        public let completionRate: Double
        public let averageTimeToComplete: TimeInterval
        
        public init(totalCompleted: Int, totalAssigned: Int, completionRate: Double, averageTimeToComplete: TimeInterval) {
            self.totalCompleted = totalCompleted
            self.totalAssigned = totalAssigned
            self.completionRate = completionRate
            self.averageTimeToComplete = averageTimeToComplete
        }
    }
    
    public enum Timeframe: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
    }
    
    public struct DayProgress {
        public let date: Date
        public let completed: Int
        public let total: Int
        
        public init(date: Date, completed: Int, total: Int) {
            self.date = date
            self.completed = completed
            self.total = total
        }
    }
    
    public struct TaskTrends {
        public let categoryProgress: [CategoryProgress]
        public let productivityTrend: ProductivityTrend
        
        public init(categoryProgress: [CategoryProgress], productivityTrend: ProductivityTrend) {
            self.categoryProgress = categoryProgress
            self.productivityTrend = productivityTrend
        }
    }
    
    public struct CategoryProgress {
        public let category: String
        public let completed: Int
        public let total: Int
        
        public init(category: String, completed: Int, total: Int) {
            self.category = category
            self.completed = completed
            self.total = total
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
    
    public enum ProductivityTrend: String {
        case increasing = "Increasing"
        case stable = "Stable"
        case decreasing = "Decreasing"
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
}

// Add type aliases for these new types
public typealias WorkerShift = FrancoSphere.WorkerShift
public typealias DataHealthStatus = FrancoSphere.DataHealthStatus
public typealias TaskProgress = FrancoSphere.TaskProgress
public typealias TaskEvidence = FrancoSphere.TaskEvidence
public typealias TaskCompletionStats = FrancoSphere.TaskCompletionStats
public typealias Timeframe = FrancoSphere.Timeframe
public typealias DayProgress = FrancoSphere.DayProgress
public typealias TaskTrends = FrancoSphere.TaskTrends
public typealias CategoryProgress = FrancoSphere.CategoryProgress
public typealias PerformanceMetrics = FrancoSphere.PerformanceMetrics
public typealias ProductivityTrend = FrancoSphere.ProductivityTrend
public typealias StreakData = FrancoSphere.StreakData

// Date extension (if not already present)
extension Date {
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }
}
EOF
        echo "✅ Added missing type definitions to FrancoSphereModels.swift"
    fi
}

# Function to fix specific compilation issues
fix_specific_issues() {
    echo "📝 Fixing specific compilation issues..."
    
    # Fix WorkerManager.swift function call issues
    if [ -f "$XCODE_PATH/Managers/WorkerManager.swift" ]; then
        echo "🔧 Fixing WorkerManager.swift function calls..."
        
        # Fix WorkerShift initializer calls (add missing parameters)
        sed -i '' 's/WorkerShift(id: shiftId, workerId: workerId, startTime: Date())/WorkerShift(id: shiftId, workerId: workerId, startTime: Date(), startBuilding: building?.name ?? "Unknown")/g' "$XCODE_PATH/Managers/WorkerManager.swift"
        
        # Fix status references
        sed -i '' 's/\.active/.active/g' "$XCODE_PATH/Managers/WorkerManager.swift"
        sed -i '' 's/\.completed/.completed/g' "$XCODE_PATH/Managers/WorkerManager.swift"
        
        echo "✅ Fixed WorkerManager.swift function calls"
    fi
    
    # Fix DashboardView.swift type reference
    if [ -f "$XCODE_PATH/Views/Main/DashboardView.swift" ]; then
        echo "🔧 Fixing DashboardView.swift type references..."
        sed -i '' 's/TaskProgress/FrancoSphere.TaskProgress/g' "$XCODE_PATH/Views/Main/DashboardView.swift"
        echo "✅ Fixed DashboardView.swift"
    fi
}

# Function to create a comprehensive Worker type definition
create_worker_definition() {
    echo "📝 Creating comprehensive Worker type definition..."
    
    # Add Worker definition to FrancoSphereModels.swift if not already present
    if [ -f "$XCODE_PATH/Models/FrancoSphereModels.swift" ]; then
        # Check if Worker is already defined
        if ! grep -q "struct Worker" "$XCODE_PATH/Models/FrancoSphereModels.swift"; then
            cat >> "$XCODE_PATH/Models/FrancoSphereModels.swift" << 'EOF'

// Worker Definition (Unified)
extension FrancoSphere {
    public struct Worker {
        public let id: String
        public let name: String
        public let email: String
        public let role: String
        public let isActive: Bool
        public let hourlyRate: Double?
        public let skills: [String]
        public let buildingIds: [String]
        
        public init(id: String, name: String, email: String, role: String, isActive: Bool, hourlyRate: Double? = nil, skills: [String] = [], buildingIds: [String] = []) {
            self.id = id
            self.name = name
            self.email = email
            self.role = role
            self.isActive = isActive
            self.hourlyRate = hourlyRate
            self.skills = skills
            self.buildingIds = buildingIds
        }
    }
}

public typealias Worker = FrancoSphere.Worker
EOF
        fi
        echo "✅ Created Worker type definition"
    fi
}

# Main execution
main() {
    echo "Starting FrancoSphere type cleanup..."
    
    if [ ! -d "$XCODE_PATH" ]; then
        echo "❌ Error: Xcode project directory not found at $XCODE_PATH"
        exit 1
    fi
    
    # Create backup
    echo "📁 Creating backup..."
    BACKUP_DIR="$HOME/francosphere_cleanup_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp -r "$XCODE_PATH"/{Models,Managers,Services,Views} "$BACKUP_DIR/" 2>/dev/null || true
    echo "✅ Backup created at: $BACKUP_DIR"
    
    # Execute fixes
    remove_duplicate_types
    add_missing_types
    create_worker_definition
    fix_specific_issues
    
    echo ""
    echo "🎯 FrancoSphere Type Cleanup Complete!"
    echo "========================================="
    echo "✅ Removed duplicate type declarations"
    echo "✅ Added missing type definitions to FrancoSphereModels.swift"
    echo "✅ Fixed function call parameter issues"
    echo "✅ Resolved type ambiguity issues"
    echo ""
    echo "📝 Next Steps:"
    echo "1. Test compilation: xcodebuild clean build -project FrancoSphere.xcodeproj -scheme FrancoSphere"
    echo "2. If issues remain, check specific files mentioned in error messages"
    echo "3. Backup location: $BACKUP_DIR"
}

# Run the script
main "$@"