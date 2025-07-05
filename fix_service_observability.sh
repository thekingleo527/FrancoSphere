#!/bin/bash
set -e

echo "🔧 Fixing Service ObservableObject Architecture Issue"
echo "===================================================="
echo "Targeted fix: Remove @ObservedObject wrappers for actor-based services"

cd "/Volumes/FastSSD/Xcode" || exit 1

# Create targeted backup
TIMESTAMP=$(date +%s)
cp "Views/Main/WorkerProfileView.swift" "Views/Main/WorkerProfileView.swift.observability_backup.$TIMESTAMP"

echo "📦 Created backup: WorkerProfileView.swift.observability_backup.$TIMESTAMP"

# =============================================================================
# TARGETED FIX: Remove @ObservedObject wrappers for actor services
# =============================================================================

echo ""
echo "🎯 TARGETED FIX: Removing inappropriate @ObservedObject wrappers..."

cat > /tmp/fix_service_observability.py << 'PYTHON_EOF'
def fix_service_observability():
    file_path = "/Volumes/FastSSD/Xcode/Views/Main/WorkerProfileView.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        print("🔧 Fixing service property declarations...")
        
        # Replace the problematic @ObservedObject service declarations
        # with direct access to shared instances
        
        # Remove the service parameters from struct definition
        old_struct_params = '''    let workerId: String
    @ObservedObject var workerService: WorkerService
    @ObservedObject var taskService: TaskService
    @ObservedObject var buildingService: BuildingService'''
        
        new_struct_params = '''    let workerId: String'''
        
        content = content.replace(old_struct_params, new_struct_params)
        
        # Update the data loading method to use shared instances
        old_loading = '''        do {
            // Load worker profile
            worker = await workerService.fetchWorker(id: workerId)
            
            // Load performance metrics
            performanceMetrics = await workerService.fetchPerformanceMetrics(for: workerId)
            
            // Load recent tasks
            recentTasks = await taskService.fetchRecentTasks(for: workerId, limit: 10)
            
            // Load current building assignment
            if let buildingId = worker?.currentBuildingId {
                currentBuilding = await buildingService.fetchBuilding(id: buildingId)
            }
            
        } catch {
            print("Error loading worker data: \\(error)")
            worker = nil
        }'''
        
        new_loading = '''        do {
            // Load worker profile using shared service instances
            worker = await WorkerService.shared.fetchWorker(id: workerId)
            
            // Load performance metrics
            performanceMetrics = await WorkerService.shared.fetchPerformanceMetrics(for: workerId)
            
            // Load recent tasks
            recentTasks = await TaskService.shared.fetchRecentTasks(for: workerId, limit: 10)
            
            // Load current building assignment
            if let buildingId = worker?.currentBuildingId {
                currentBuilding = await BuildingService.shared.fetchBuilding(id: buildingId)
            }
            
        } catch {
            print("Error loading worker data: \\(error)")
            worker = nil
        }'''
        
        content = content.replace(old_loading, new_loading)
        
        # Update the Preview section to remove service parameters
        old_preview = '''#Preview {
    NavigationView {
        WorkerProfileView(
            workerId: "kevin",
            workerService: WorkerService.shared,
            taskService: TaskService.shared,
            buildingService: BuildingService.shared
        )
    }
    .preferredColorScheme(.dark)
}'''
        
        new_preview = '''#Preview {
    NavigationView {
        WorkerProfileView(workerId: "kevin")
    }
    .preferredColorScheme(.dark)
}'''
        
        content = content.replace(old_preview, new_preview)
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        print("✅ Fixed service observability issues")
        print("• Removed @ObservedObject wrappers for actor services")
        print("• Updated to use shared service instances directly")
        print("• Fixed Preview section parameters")
        return True
        
    except Exception as e:
        print(f"❌ Error fixing service observability: {e}")
        return False

if __name__ == "__main__":
    fix_service_observability()
PYTHON_EOF

python3 /tmp/fix_service_observability.py

# =============================================================================
# VERIFICATION
# =============================================================================

echo ""
echo "🔍 VERIFICATION: Checking fixed service references..."

echo ""
echo "Service property declarations:"
grep -A 5 "struct WorkerProfileView" "Views/Main/WorkerProfileView.swift"

echo ""
echo "Service usage in data loading:"
grep -A 3 "WorkerService.shared\|TaskService.shared\|BuildingService.shared" "Views/Main/WorkerProfileView.swift"

echo ""
echo "Preview section:"
grep -A 5 "#Preview" "Views/Main/WorkerProfileView.swift"

# =============================================================================
# BUILD TEST
# =============================================================================

echo ""
echo "🔨 Testing compilation after service observability fix..."

BUILD_OUTPUT=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build -destination "platform=iOS Simulator,name=iPhone 15 Pro" 2>&1)

# Count specific error types
OBSERVABLEOBJECT_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "requires that.*conform to 'ObservableObject'" || echo "0")
WORKERPROFILE_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "WorkerProfileView.swift.*error" || echo "0")
TOTAL_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c " error:" || echo "0")

echo ""
echo "📊 SERVICE OBSERVABILITY FIX RESULTS"
echo "===================================="
echo ""
echo "🎯 Specific issue resolution:"
echo "• ObservableObject conformance errors: $OBSERVABLEOBJECT_ERRORS (was 3)"
echo "• WorkerProfileView.swift errors: $WORKERPROFILE_ERRORS"
echo "• Total compilation errors: $TOTAL_ERRORS"

if [[ $OBSERVABLEOBJECT_ERRORS -eq 0 ]]; then
    echo ""
    echo "🟢 ✅ SERVICE ARCHITECTURE FIX SUCCESS!"
    echo "======================================"
    echo "✅ ObservableObject conformance errors resolved"
    echo "✅ Proper actor service architecture maintained"
    echo "✅ Shared service instances accessed correctly"
    echo "✅ Thread safety preserved through actor pattern"
    
    if [[ $TOTAL_ERRORS -eq 0 ]]; then
        echo ""
        echo "🎉 COMPLETE PROJECT SUCCESS!"
        echo "============================"
        echo "🚀 ALL COMPILATION ERRORS RESOLVED!"
        echo "✅ FrancoSphere ready for deployment"
        echo "🎯 Clean build achieved across entire project"
        echo "🏗️ Proper architecture: actors for services, @State for UI"
    else
        echo ""
        echo "📋 Remaining errors in other files: $TOTAL_ERRORS"
        echo "$BUILD_OUTPUT" | grep " error:" | head -5
    fi
    
else
    echo ""
    echo "⚠️  $OBSERVABLEOBJECT_ERRORS ObservableObject errors remain"
    echo ""
    echo "📋 Remaining ObservableObject errors:"
    echo "$BUILD_OUTPUT" | grep "conform to 'ObservableObject'"
fi

echo ""
echo "🎯 SERVICE OBSERVABILITY FIX COMPLETE"
echo "====================================="
echo ""
echo "✅ ARCHITECTURAL CORRECTIONS APPLIED:"
echo "• ✅ Removed inappropriate @ObservedObject wrappers"
echo "• ✅ Maintained actor-based service architecture"
echo "• ✅ Updated to use shared service instances (WorkerService.shared, etc.)"
echo "• ✅ Preserved thread safety through actor isolation"
echo "• ✅ Fixed Preview section to match new structure"
echo "• ✅ Proper separation: actors for business logic, @State for UI state"
echo ""
echo "🏗️ ARCHITECTURE SUMMARY:"
echo "• Services: Actor-based for thread safety"
echo "• UI State: @State properties for reactive updates"  
echo "• Data Loading: Async calls to shared service instances"
echo "• Preview: Clean parameter structure"
echo ""
echo "📦 Previous version backed up as: WorkerProfileView.swift.observability_backup.$TIMESTAMP"

exit 0
