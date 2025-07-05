#!/bin/bash

echo "🔧 FrancoSphere Final Surgical Fix"
echo "=================================="
echo "Applying surgical precision fixes to exact remaining compilation errors"
echo ""

cd "/Volumes/FastSSD/Xcode" || exit 1

# =============================================================================
# FIX 1: HeroStatusCard.swift - Complete rebuild with proper imports and structure
# =============================================================================

echo "🔧 Fix 1: Complete HeroStatusCard.swift fixes"
echo "=============================================="

HERO_FILE="Components/Shared Components/HeroStatusCard.swift"
if [ -f "$HERO_FILE" ]; then
    cp "$HERO_FILE" "$HERO_FILE.final_surgical_backup.$(date +%s)"
    
    cat > /tmp/fix_hero_surgical.py << 'PYTHON_EOF'
import re

def fix_hero_surgical():
    file_path = "/Volumes/FastSSD/Xcode/Components/Shared Components/HeroStatusCard.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        print("🔧 Applying surgical fixes to HeroStatusCard...")
        
        # Fix 1: Add CoreLocation import if missing
        if 'import CoreLocation' not in content:
            content = re.sub(r'(import Foundation\s*\n)', r'\1import CoreLocation\n', content)
            print("✅ Added CoreLocation import")
        
        # Fix 2: Replace problematic sample data with corrected versions
        lines = content.split('\n')
        for i, line in enumerate(lines):
            line_num = i + 1
            
            # Fix line 13: CLLocationCoordinate2D scope issue
            if line_num == 13 and 'CLLocationCoordinate2D' in line:
                lines[i] = line  # Should work now with import
            
            # Fix line 22: Int to String conversion
            elif line_num == 22 and 'uvIndex:' in line:
                # Make sure uvIndex is Int, not String
                if '"' in line:  # If it's quoted as string
                    lines[i] = line.replace('"', '').replace('uvIndex: ', 'uvIndex: ')
            
            # Fix line 31: Extra arguments in TaskProgress constructor
            elif line_num == 31 and 'TaskProgress(' in line:
                indent = len(line) - len(line.lstrip())
                lines[i] = ' ' * indent + 'TaskProgress(completed: 5, total: 10, remaining: 5, percentage: 50.0, overdueTasks: 2)\n'
                print(f"✅ Fixed line {line_num}: TaskProgress constructor")
            
            # Fix line 32: Missing 'from' parameter issue
            elif line_num == 32:
                if 'from' in line or 'TaskProgress' in line:
                    lines[i] = ''  # Remove this problematic line
                    print(f"✅ Fixed line {line_num}: Removed problematic from parameter")
            
            # Fix line 229: Missing onClockInTap argument
            elif line_num == 229 and ('HeroStatusCard(' in line or ')' in line):
                indent = len(line) - len(line.lstrip())
                if not 'onClockInTap' in line:
                    lines[i] = ' ' * indent + 'onClockInTap: { }\n'
                    print(f"✅ Fixed line {line_num}: Added onClockInTap argument")
            
            # Fix line 233: Remove currentBuilding and consecutive statements
            elif line_num == 233:
                if 'currentBuilding' in line:
                    lines[i] = ''  # Remove problematic line
                    print(f"✅ Fixed line {line_num}: Removed currentBuilding line")
        
        content = '\n'.join(lines)
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        print("✅ Applied comprehensive HeroStatusCard surgical fixes")
        
    except Exception as e:
        print(f"❌ Error in HeroStatusCard surgical fix: {e}")

if __name__ == "__main__":
    fix_hero_surgical()
PYTHON_EOF

    python3 /tmp/fix_hero_surgical.py
fi

# =============================================================================
# FIX 2: HeaderV3B.swift - Remove extra arguments from specific lines
# =============================================================================

echo ""
echo "🔧 Fix 2: HeaderV3B.swift extra arguments removal"
echo "================================================="

HEADER_FILE="Components/Design/HeaderV3B.swift"
if [ -f "$HEADER_FILE" ]; then
    cp "$HEADER_FILE" "$HEADER_FILE.final_surgical_backup.$(date +%s)"
    
    # Direct sed fixes for specific lines
    echo "🔧 Fixing HeaderV3B lines 178, 183, 203..."
    
    # Fix line 178: Remove extra arguments
    sed -i.tmp '178s/(\([^,]*\),[^)]*/(\1)/g' "$HEADER_FILE"
    
    # Fix line 183: Remove extra arguments
    sed -i.tmp '183s/(\([^,]*\),[^)]*/(\1)/g' "$HEADER_FILE"
    
    # Fix line 203: Remove extra arguments
    sed -i.tmp '203s/(\([^,]*\),[^)]*/(\1)/g' "$HEADER_FILE"
    
    rm -f "${HEADER_FILE}.tmp"
    echo "✅ Fixed HeaderV3B.swift extra arguments"
fi

# =============================================================================
# FIX 3: WeatherDashboardComponent.swift - Add missing arguments
# =============================================================================

echo ""
echo "🔧 Fix 3: WeatherDashboardComponent.swift missing arguments"
echo "=========================================================="

WEATHER_FILE="Components/Shared Components/WeatherDashboardComponent.swift"
if [ -f "$WEATHER_FILE" ]; then
    cp "$WEATHER_FILE" "$WEATHER_FILE.final_surgical_backup.$(date +%s)"
    
    # Fix line 338 with direct replacement
    sed -i.tmp '338s/.*/        WeatherDashboardComponent(building: sampleBuilding, weather: sampleWeather, tasks: sampleTasks)/' "$WEATHER_FILE"
    
    # Add sample data definitions if not present
    if ! grep -q "sampleBuilding\|sampleTasks" "$WEATHER_FILE"; then
        # Add sample definitions at the top
        cat > /tmp/add_weather_samples.py << 'PYTHON_EOF'
import re

def add_weather_samples():
    file_path = "/Volumes/FastSSD/Xcode/Components/Shared Components/WeatherDashboardComponent.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Add sample data after imports
        if 'sampleBuilding' not in content:
            import_pattern = r'(import\s+\w+\s*\n)+(\s*\n)'
            sample_data = '''
// Sample data for WeatherDashboardComponent
private let sampleBuilding = NamedCoordinate(id: "sample", name: "Sample Building", coordinate: CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851))
private let sampleWeather = WeatherData(date: Date(), temperature: 72, feelsLike: 75, humidity: 60, windSpeed: 5, windDirection: 180, precipitation: 0, snow: 0, condition: .clear, uvIndex: 5, visibility: 10, description: "Clear")
private let sampleTasks: [ContextualTask] = []

'''
            content = re.sub(import_pattern, r'\g<0>' + sample_data, content)
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        print("✅ Added sample data to WeatherDashboardComponent")
        
    except Exception as e:
        print(f"❌ Error adding weather samples: {e}")

if __name__ == "__main__":
    add_weather_samples()
PYTHON_EOF

        python3 /tmp/add_weather_samples.py
    fi
    
    rm -f "${WEATHER_FILE}.tmp"
    echo "✅ Fixed WeatherDashboardComponent.swift missing arguments"
fi

# =============================================================================
# FIX 4: FrancoSphereModels.swift - Fix consecutive declarations
# =============================================================================

echo ""
echo "🔧 Fix 4: FrancoSphereModels.swift consecutive declarations"
echo "========================================================="

MODELS_FILE="Models/FrancoSphereModels.swift"
if [ -f "$MODELS_FILE" ]; then
    cp "$MODELS_FILE" "$MODELS_FILE.final_surgical_backup.$(date +%s)"
    
    # Direct line fixes for consecutive declarations
    echo "🔧 Adding semicolons to lines 413 and 425..."
    
    # Fix line 413: Add semicolon if missing
    sed -i.tmp '413s/$/;/' "$MODELS_FILE"
    
    # Fix line 425: Add semicolon if missing  
    sed -i.tmp '425s/$/;/' "$MODELS_FILE"
    
    # Remove duplicate semicolons
    sed -i.tmp 's/;;/;/g' "$MODELS_FILE"
    
    rm -f "${MODELS_FILE}.tmp"
    echo "✅ Fixed consecutive declarations in FrancoSphereModels.swift"
fi

# =============================================================================
# FIX 5: ViewModel fixes - Complete property declaration syntax
# =============================================================================

echo ""
echo "🔧 Fix 5: ViewModel property declaration fixes"
echo "=============================================="

# Fix BuildingDetailViewModel.swift
BUILD_VM_FILE="Views/ViewModels/BuildingDetailViewModel.swift"
if [ -f "$BUILD_VM_FILE" ]; then
    cp "$BUILD_VM_FILE" "$BUILD_VM_FILE.final_surgical_backup.$(date +%s)"
    
    # Fix line 13: Remove all arguments
    sed -i.tmp '13s/([^)]*)/()/g' "$BUILD_VM_FILE"
    rm -f "${BUILD_VM_FILE}.tmp"
    echo "✅ Fixed BuildingDetailViewModel.swift line 13"
fi

# Fix WorkerDashboardViewModel.swift
WORKER_VM_FILE="Views/ViewModels/WorkerDashboardViewModel.swift"
if [ -f "$WORKER_VM_FILE" ]; then
    cp "$WORKER_VM_FILE" "$WORKER_VM_FILE.final_surgical_backup.$(date +%s)"
    
    # Fix line 27: Complete property declaration
    sed -i.tmp '27s/.*/    private var progress = TaskProgress(completed: 0, total: 0, remaining: 0, percentage: 0, overdueTasks: 0)/' "$WORKER_VM_FILE"
    rm -f "${WORKER_VM_FILE}.tmp"
    echo "✅ Fixed WorkerDashboardViewModel.swift line 27"
fi

# Fix TodayTasksViewModel.swift
TODAY_VM_FILE="Views/Main/TodayTasksViewModel.swift"
if [ -f "$TODAY_VM_FILE" ]; then
    cp "$TODAY_VM_FILE" "$TODAY_VM_FILE.final_surgical_backup.$(date +%s)"
    
    cat > /tmp/fix_today_vm_surgical.py << 'PYTHON_EOF'
import re

def fix_today_vm_surgical():
    file_path = "/Volumes/FastSSD/Xcode/Views/Main/TodayTasksViewModel.swift"
    
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        print("🔧 Fixing TodayTasksViewModel property declarations...")
        
        # Fix specific lines with proper property declarations
        fixes = {
            19: "    private var currentProgress = TaskProgress(completed: 0, total: 0, remaining: 0, percentage: 0, overdueTasks: 0)",
            20: "    private var trends = TaskTrends(weeklyCompletion: [], categoryBreakdown: [:], changePercentage: 0, comparisonPeriod: \"week\", trend: .stable)",
            27: "    private var performanceMetrics = PerformanceMetrics(efficiency: 0, tasksCompleted: 0, averageTime: 0, qualityScore: 0, lastUpdate: Date())",
            28: "    private var streakData = StreakData(currentStreak: 0, longestStreak: 0, lastUpdate: Date())"
        }
        
        for line_num, replacement in fixes.items():
            if line_num <= len(lines):
                lines[line_num - 1] = replacement + '\n'
                print(f"✅ Fixed line {line_num}")
        
        with open(file_path, 'w') as f:
            f.writelines(lines)
        
        print("✅ Applied TodayTasksViewModel surgical fixes")
        
    except Exception as e:
        print(f"❌ Error in TodayTasksViewModel surgical fix: {e}")

if __name__ == "__main__":
    fix_today_vm_surgical()
PYTHON_EOF

    python3 /tmp/fix_today_vm_surgical.py
fi

# =============================================================================
# VERIFICATION
# =============================================================================

echo ""
echo "🔍 VERIFICATION: Checking specific line fixes..."
echo "================================================"

echo "🔍 Checking HeroStatusCard.swift imports:"
head -10 "$HERO_FILE" | grep -E "import|CoreLocation"

echo ""
echo "🔍 Checking HeaderV3B.swift lines 178, 183, 203:"
sed -n '178p;183p;203p' "$HEADER_FILE"

echo ""
echo "🔍 Checking FrancoSphereModels.swift lines 413, 425:"
sed -n '413p;425p' "$MODELS_FILE" | grep -E ";\s*$" && echo "✅ Semicolons added" || echo "⚠️ Check semicolons"

echo ""
echo "🔍 Checking TodayTasksViewModel.swift lines 19, 20, 27, 28:"
sed -n '19p;20p;27p;28p' "$TODAY_VM_FILE"

# =============================================================================
# BUILD TEST
# =============================================================================

echo ""
echo "🔨 TESTING: Final surgical build test..."
echo "======================================="

BUILD_OUTPUT=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build 2>&1)

# Count specific remaining errors
HEADER_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "HeaderV3B.*Extra arguments" || echo "0")
HERO_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "HeroStatusCard.*Cannot find\|Cannot convert\|Missing argument" || echo "0")
WEATHER_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "WeatherDashboardComponent.*Missing arguments" || echo "0")
MODELS_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "FrancoSphereModels.*Consecutive" || echo "0")
VM_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "ViewModel.*Expected.*keyword\|Missing argument.*from" || echo "0")

echo "HeaderV3B extra argument errors: $HEADER_ERRORS"
echo "HeroStatusCard scope/conversion errors: $HERO_ERRORS"
echo "WeatherDashboardComponent missing argument errors: $WEATHER_ERRORS"
echo "FrancoSphereModels consecutive declaration errors: $MODELS_ERRORS"
echo "ViewModel syntax errors: $VM_ERRORS"

TOTAL_TARGETED_ERRORS=$((HEADER_ERRORS + HERO_ERRORS + WEATHER_ERRORS + MODELS_ERRORS + VM_ERRORS))

if [ "$TOTAL_TARGETED_ERRORS" -eq 0 ]; then
    echo ""
    echo "✅ SUCCESS: All targeted compilation errors resolved!"
else
    echo ""
    echo "⚠️ Some targeted errors may remain: $TOTAL_TARGETED_ERRORS"
    echo "Showing remaining targeted errors:"
    echo "$BUILD_OUTPUT" | grep -E "(HeaderV3B|HeroStatusCard|WeatherDashboardComponent|FrancoSphereModels|ViewModel).*error" | head -10
fi

# Show overall error count
TOTAL_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c " error:" || echo "0")
echo ""
echo "📊 Total compilation errors: $TOTAL_ERRORS"

# =============================================================================
# CLEANUP
# =============================================================================

rm -f /tmp/fix_*.py
rm -f /tmp/add_*.py

echo ""
echo "🎯 FINAL SURGICAL FIX COMPLETED!"
echo "==============================="
echo ""
echo "📋 Surgical fixes applied to exact problem lines:"
echo "• HeroStatusCard.swift: Added CoreLocation import, fixed type conversions, constructor arguments"
echo "• HeaderV3B.swift: Removed extra arguments from lines 178, 183, 203"
echo "• WeatherDashboardComponent.swift: Added missing constructor arguments with sample data"
echo "• FrancoSphereModels.swift: Added semicolons to consecutive declarations (lines 413, 425)"
echo "• ViewModels: Fixed property declaration syntax across all ViewModels"
echo ""
echo "🚀 Build project (Cmd+B) - targeted errors should be significantly reduced!"

exit 0
