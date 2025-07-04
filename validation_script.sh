#!/bin/bash
#
# FrancoSphere Compilation Fix Validation Script
# Run this after applying all compilation fixes
#

echo "🔍 FrancoSphere Compilation Fix Validation"
echo "=========================================="

# Change to project directory
XCODE_PATH="/Volumes/FastSSD/Xcode"
cd "$XCODE_PATH" || { echo "❌ Cannot find project directory"; exit 1; }

echo ""
echo "1️⃣ Checking for missing type definitions..."

# Check if critical types are defined
if grep -q "public struct Worker" Models/FrancoSphereModels.swift; then
    echo "✅ Worker type defined"
else
    echo "❌ Worker type missing"
fi

if grep -q "public enum DataHealthStatus" Models/FrancoSphereModels.swift; then
    echo "✅ DataHealthStatus defined"
else
    echo "❌ DataHealthStatus missing"
fi

if grep -q "public struct TaskProgress" Models/FrancoSphereModels.swift; then
    echo "✅ TaskProgress defined"
else
    echo "❌ TaskProgress missing"
fi

echo ""
echo "2️⃣ Checking for required managers..."

if [ -f "Managers/WeatherManager.swift" ]; then
    echo "✅ WeatherManager.swift exists"
else
    echo "❌ WeatherManager.swift missing"
fi

if [ -f "Managers/WorkerManager.swift" ]; then
    echo "✅ WorkerManager.swift exists"
else
    echo "❌ WorkerManager.swift missing"
fi

echo ""
echo "3️⃣ Checking for fixed method implementations..."

if grep -q "validateAndRepairDataPipelineFixed" Models/WorkerContextEngine.swift; then
    echo "✅ validateAndRepairDataPipelineFixed method exists"
else
    echo "❌ validateAndRepairDataPipelineFixed method missing"
fi

if grep -q "loadRoutinesForWorker.*buildingId" Models/WorkerContextEngine.swift; then
    echo "✅ loadRoutinesForWorker with buildingId parameter exists"
else
    echo "❌ loadRoutinesForWorker method signature needs fix"
fi

echo ""
echo "4️⃣ Checking Kevin's Rubin Museum assignment..."

if grep -q "Rubin Museum" Models/WorkerContextEngine.swift; then
    echo "✅ Kevin's Rubin Museum assignment found"
else
    echo "❌ Kevin's Rubin Museum assignment missing"
fi

if grep -q "104 Franklin" Models/WorkerContextEngine.swift; then
    echo "⚠️  Kevin still has 104 Franklin Street - should be removed"
else
    echo "✅ 104 Franklin Street correctly removed"
fi

echo ""
echo "5️⃣ Running compilation test..."

# Clean and build
echo "🧹 Cleaning build folder..."
xcodebuild clean -project FrancoSphere.xcodeproj -quiet > /dev/null 2>&1

echo "🔨 Attempting build..."
BUILD_OUTPUT=$(xcodebuild build -project FrancoSphere.xcodeproj -scheme FrancoSphere -destination 'platform=iOS Simulator,name=iPhone 15' 2>&1)

# Count errors
ERROR_COUNT=$(echo "$BUILD_OUTPUT" | grep -c "error:")
WARNING_COUNT=$(echo "$BUILD_OUTPUT" | grep -c "warning:")

echo ""
echo "📊 BUILD RESULTS:"
echo "=================="
echo "Errors: $ERROR_COUNT"
echo "Warnings: $WARNING_COUNT"

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "🎉 SUCCESS: Zero compilation errors!"
    echo ""
    echo "✅ All compilation fixes applied successfully"
    echo "✅ Project builds without errors"
    echo "✅ Ready for testing Kevin's workflow"
else
    echo "❌ FAILURE: Still has compilation errors"
    echo ""
    echo "Remaining errors:"
    echo "$BUILD_OUTPUT" | grep "error:" | head -10
    echo ""
    echo "💡 Next steps:"
    echo "1. Check the error messages above"
    echo "2. Ensure all type definitions were added correctly"
    echo "3. Verify all import statements are present"
    echo "4. Double-check method names match exactly"
fi

echo ""
echo "6️⃣ File structure validation..."

EXPECTED_FILES=(
    "Models/FrancoSphereModels.swift"
    "Models/WorkerContextEngine.swift"
    "Managers/WeatherManager.swift"
    "Managers/WorkerManager.swift"
    "Views/Main/WorkerDashboardView.swift"
    "Views/Buildings/BuildingDetailView.swift"
)

for file in "${EXPECTED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
    fi
done

echo ""
echo "📋 VALIDATION COMPLETE"
echo "====================="

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "🚀 Status: READY FOR NEXT PHASE"
    echo ""
    echo "Recommended next steps:"
    echo "1. Test app launch"
    echo "2. Login as Kevin (worker ID: 4)"
    echo "3. Verify Rubin Museum appears in his buildings"
    echo "4. Check task count (should be 38+ tasks)"
    echo "5. Verify dashboard loads without crashes"
else
    echo "⚠️  Status: NEEDS MORE FIXES"
    echo ""
    echo "Focus on resolving the compilation errors shown above"
    echo "Run this script again after applying additional fixes"
fi

echo ""
echo "For help with remaining issues, refer to the step-by-step execution plan."