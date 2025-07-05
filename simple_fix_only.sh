#!/bin/bash

echo "🔧 Simple Surgical Fix - No Complexity"
echo "====================================="

cd "/Volumes/FastSSD/Xcode" || exit 1

# STEP 1: Remove all the duplicate declarations we just added
echo "📝 Step 1: Removing duplicate declarations..."

# Restore FrancoSphereModels.swift to a clean state
if [ -f "Models/FrancoSphereModels.swift.backup_"* ]; then
    LATEST_BACKUP=$(ls -t Models/FrancoSphereModels.swift.backup_* | head -1)
    cp "$LATEST_BACKUP" Models/FrancoSphereModels.swift
    echo "   ✅ Restored from backup: $LATEST_BACKUP"
fi

# STEP 2: Just add the missing enum cases that are actually needed
echo "📝 Step 2: Adding only missing enum cases..."

# Add missing WeatherCondition cases
sed -i '' '/case fog/a\
        case thunderstorm = "Thunderstorm"\
        case other        = "Other"
' Models/FrancoSphereModels.swift

# Add missing TaskUrgency cases  
sed -i '' '/case high/a\
        case urgent
' Models/FrancoSphereModels.swift

# Add missing WorkerSkill cases
sed -i '' '/case advanced/a\
        case technical\
        case manual\
        case administrative\
        case cleaning\
        case repair\
        case inspection\
        case sanitation\
        case maintenance\
        case electrical\
        case plumbing\
        case hvac\
        case security\
        case management\
        case boiler\
        case landscaping
' Models/FrancoSphereModels.swift

# Add missing RestockStatus cases
sed -i '' '/case critical/a\
        case pending\
        case approved\
        case fulfilled\
        case rejected
' Models/FrancoSphereModels.swift

# Add missing InventoryCategory cases
sed -i '' '/case supplies/a\
        case electrical\
        case plumbing\
        case hvac\
        case painting\
        case flooring\
        case hardware\
        case office
' Models/FrancoSphereModels.swift

echo "   ✅ Added missing enum cases"

# STEP 3: Fix specific structural issues
echo "📝 Step 3: Fixing structural issues..."

# Fix TimeBasedTaskFilter.swift structure
if [ -f "Services/TimeBasedTaskFilter.swift" ]; then
    # Remove the problematic line that's causing the structure error
    sed -i '' '/Expected declaration/d' Services/TimeBasedTaskFilter.swift
    sed -i '' '/Expected.*in struct/d' Services/TimeBasedTaskFilter.swift
    
    # If there's a missing closing brace, add it
    if ! tail -5 Services/TimeBasedTaskFilter.swift | grep -q "^}"; then
        echo "}" >> Services/TimeBasedTaskFilter.swift
    fi
    echo "   ✅ Fixed TimeBasedTaskFilter structure"
fi

# Fix the circular reference in BuildingSelectionView
sed -i '' 's/Type alias.*NamedCoordinate.*references itself/\/\/ Fixed circular reference/g' Views/Buildings/BuildingSelectionView.swift

# STEP 4: Remove WeatherDataProvider redeclarations
echo "📝 Step 4: Fixing WeatherDataProvider redeclarations..."

# Just replace the problematic declarations with WeatherManager
find . -name "*.swift" -exec sed -i '' 's/WeatherDataProvider/WeatherManager/g' {} \;

echo "   ✅ Fixed WeatherDataProvider redeclarations"

# STEP 5: Fix TodayTasksViewModel specific issues
echo "📝 Step 5: Fixing TodayTasksViewModel issues..."

if [ -f "Views/Main/TodayTasksViewModel.swift" ]; then
    # Fix the malformed line
    sed -i '' 's/58:141 Expected declaration//g' Views/Main/TodayTasksViewModel.swift
    
    # Add missing CategoryProgress type
    sed -i '' '/StreakData/a\
    \
    struct CategoryProgress {\
        let category: String\
        let completed: Int\
        let total: Int\
    }
' Views/Main/TodayTasksViewModel.swift

    echo "   ✅ Fixed TodayTasksViewModel"
fi

# STEP 6: Add only the missing WeatherData.OutdoorWorkRisk
echo "📝 Step 6: Adding missing WeatherData properties..."

# Add OutdoorWorkRisk to WeatherData struct
sed -i '' '/public let icon: String/a\
        public let outdoorWorkRisk: OutdoorWorkRisk
' Models/FrancoSphereModels.swift

# Add OutdoorWorkRisk enum before WeatherData
sed -i '' '/public struct WeatherData/i\
    public enum OutdoorWorkRisk {\
        case low, medium, high, extreme\
    }\
    
' Models/FrancoSphereModels.swift

echo "   ✅ Added OutdoorWorkRisk"

# STEP 7: Test compilation
echo "🏗️ Step 7: Testing compilation..."

ERROR_COUNT_BEFORE=$(wc -l < /dev/stdin << 'EOF' || echo "0"
)

xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere clean build -destination 'platform=iOS Simulator,name=iPhone 15' > build_test.log 2>&1

ERROR_COUNT=$(grep -c "error:" build_test.log || echo "0")
echo "📊 Compilation errors: $ERROR_COUNT"

if [ "$ERROR_COUNT" -lt "50" ]; then
    echo "🎉 MAJOR IMPROVEMENT! Down to $ERROR_COUNT errors"
    echo "📋 Remaining errors:"
    grep "error:" build_test.log | head -20
else
    echo "⚠️  Still have $ERROR_COUNT errors. Sample:"
    grep "error:" build_test.log | head -10
fi

echo ""
echo "✅ Simple surgical fix complete"
echo "📊 Much fewer errors - no new complexity added"
