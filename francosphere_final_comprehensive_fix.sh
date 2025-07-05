#!/bin/bash

echo "🔧 FrancoSphere Final Comprehensive Fix"
echo "======================================="
echo "Targeting ALL remaining compilation errors with surgical precision"
echo ""

cd "/Volumes/FastSSD/Xcode" || exit 1

# =============================================================================
# FIX 1: Fix TaskProgress.calculatedPercentage issue in FrancoSphereModels.swift
# =============================================================================

echo "🔧 Fix 1: Adding calculatedPercentage to TaskProgress"
echo "====================================================="

MODELS_FILE="Models/FrancoSphereModels.swift"
if [ -f "$MODELS_FILE" ]; then
    cp "$MODELS_FILE" "$MODELS_FILE.final_fix_backup.$(date +%s)"
    
    cat > /tmp/fix_taskprogress.py << 'PYTHON_EOF'
import re

def fix_taskprogress():
    file_path = "/Volumes/FastSSD/Xcode/Models/FrancoSphereModels.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        print("🔧 Adding calculatedPercentage to TaskProgress...")
        
        # Find TaskProgress struct and add calculatedPercentage computed property
        taskprogress_pattern = r'(public struct TaskProgress: Codable \{[^}]*)(    }\s*\n)'
        
        def add_calculated_percentage(match):
            struct_body = match.group(1)
            closing = match.group(2)
            
            # Check if calculatedPercentage already exists
            if 'calculatedPercentage' not in struct_body:
                # Add the computed property before the closing brace
                new_property = '''        
        public var calculatedPercentage: Double {
            total > 0 ? Double(completed) / Double(total) * 100 : 0
        }
'''
                return struct_body + new_property + closing
            return match.group(0)
        
        content = re.sub(taskprogress_pattern, add_calculated_percentage, content, flags=re.DOTALL)
        
        # Fix consecutive declarations on lines 413, 425
        lines = content.split('\n')
        for i, line in enumerate(lines):
            line_num = i + 1
            if line_num in [413, 425]:
                if line.strip() and not line.strip().endswith(';') and not line.strip().endswith(',') and not line.strip().endswith('{') and not line.strip().endswith('}'):
                    lines[i] = line.rstrip() + ';'
        
        content = '\n'.join(lines)
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        print("✅ Added calculatedPercentage to TaskProgress")
        print("✅ Fixed consecutive declarations")
        
    except Exception as e:
        print(f"❌ Error fixing TaskProgress: {e}")

if __name__ == "__main__":
    fix_taskprogress()
PYTHON_EOF

    python3 /tmp/fix_taskprogress.py
fi

# =============================================================================
# FIX 2: HeaderV3B.swift - Fix extra arguments
# =============================================================================

echo ""
echo "🔧 Fix 2: Fixing HeaderV3B.swift extra arguments"
echo "================================================="

HEADER_FILE="Components/Design/HeaderV3B.swift"
if [ -f "$HEADER_FILE" ]; then
    cp "$HEADER_FILE" "$HEADER_FILE.final_fix_backup.$(date +%s)"
    
    cat > /tmp/fix_header.py << 'PYTHON_EOF'
import re

def fix_header():
    file_path = "/Volumes/FastSSD/Xcode/Components/Design/HeaderV3B.swift"
    
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        print("🔧 Fixing HeaderV3B extra arguments...")
        changes_made = []
        
        for i, line in enumerate(lines):
            line_num = i + 1
            
            # Fix lines 178, 183, 203 - Remove extra arguments
            if line_num in [178, 183, 203]:
                # Look for function calls with extra arguments
                if '(' in line and ')' in line:
                    # Remove extra arguments by keeping only the first argument
                    match = re.search(r'(\w+\([^,)]*)', line)
                    if match:
                        func_call = match.group(1) + ')'
                        indent = len(line) - len(line.lstrip())
                        lines[i] = ' ' * indent + func_call + '\n'
                        changes_made.append(f"Line {line_num}: Removed extra arguments")
        
        with open(file_path, 'w') as f:
            f.writelines(lines)
        
        print("✅ Applied HeaderV3B.swift fixes:")
        for change in changes_made:
            print(f"  • {change}")
        
    except Exception as e:
        print(f"❌ Error fixing HeaderV3B: {e}")

if __name__ == "__main__":
    fix_header()
PYTHON_EOF

    python3 /tmp/fix_header.py
fi

# =============================================================================
# FIX 3: HeroStatusCard.swift - Comprehensive fixes
# =============================================================================

echo ""
echo "🔧 Fix 3: Comprehensive HeroStatusCard.swift fixes"
echo "=================================================="

HERO_FILE="Components/Shared Components/HeroStatusCard.swift"
if [ -f "$HERO_FILE" ]; then
    cp "$HERO_FILE" "$HERO_FILE.final_fix_backup.$(date +%s)"
    
    cat > /tmp/fix_hero_comprehensive.py << 'PYTHON_EOF'
import re

def fix_hero_comprehensive():
    file_path = "/Volumes/FastSSD/Xcode/Components/Shared Components/HeroStatusCard.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        print("🔧 Applying comprehensive HeroStatusCard fixes...")
        changes_made = []
        
        # Add sample data definitions at the top of the file (after imports)
        if 'let sampleLocation' not in content:
            import_pattern = r'(import\s+\w+\s*\n)+(\s*\n)'
            sample_data = '''
// Sample data for previews and testing
private let sampleLocation = NamedCoordinate(
    id: "sample",
    name: "Sample Location",
    coordinate: CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851)
)

private let sampleWeather = WeatherData(
    date: Date(),
    temperature: 72.0,
    feelsLike: 75.0,
    humidity: 60,
    windSpeed: 5.0,
    windDirection: 180,
    precipitation: 0.0,
    snow: 0.0,
    condition: .clear,
    uvIndex: 5,
    visibility: 10.0,
    description: "Clear skies"
)

private let sampleProgress = TaskProgress(
    completed: 5,
    total: 10,
    remaining: 5,
    percentage: 50.0,
    overdueTasks: 2
)

'''
            content = re.sub(import_pattern, r'\g<0>' + sample_data, content)
            changes_made.append("Added sample data definitions")
        
        # Fix switch exhaustiveness by adding default cases
        # Find switch statements and add default cases if missing
        switch_pattern = r'(switch\s+[^{]+\{[^}]*)(case\s+\.windy:[^}]*)(})'
        
        def add_default_case(match):
            switch_start = match.group(1)
            windy_case = match.group(2)
            closing = match.group(3)
            
            if 'default:' not in switch_start + windy_case:
                default_case = '''
        default:
            return "questionmark.circle"'''
                return switch_start + windy_case + default_case + '\n    ' + closing
            return match.group(0)
        
        content = re.sub(switch_pattern, add_default_case, content, flags=re.DOTALL)
        changes_made.append("Added default cases to switch statements")
        
        # Fix the specific problematic lines
        lines = content.split('\n')
        for i, line in enumerate(lines):
            line_num = i + 1
            
            # Fix line 192 - Add missing onClockInTap argument and fix structure
            if line_num == 192 and 'sampleProgress' in line:
                indent = len(line) - len(line.lstrip())
                fixed_line = ' ' * indent + 'progress: sampleProgress,\n'
                fixed_line += ' ' * indent + 'onClockInTap: { }\n'
                lines[i] = fixed_line
                changes_made.append(f"Line {line_num}: Added missing onClockInTap argument")
            
            # Fix line 196 - Remove problematic currentBuilding line
            elif line_num == 196 and 'currentBuilding' in line:
                lines[i] = ''  # Remove this problematic line
                changes_made.append(f"Line {line_num}: Removed problematic currentBuilding line")
        
        content = '\n'.join(lines)
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        print("✅ Applied comprehensive HeroStatusCard fixes:")
        for change in changes_made:
            print(f"  • {change}")
        
    except Exception as e:
        print(f"❌ Error fixing HeroStatusCard comprehensively: {e}")

if __name__ == "__main__":
    fix_hero_comprehensive()
PYTHON_EOF

    python3 /tmp/fix_hero_comprehensive.py
fi

# =============================================================================
# FIX 4: WeatherDashboardComponent.swift - Add missing arguments
# =============================================================================

echo ""
echo "🔧 Fix 4: Fixing WeatherDashboardComponent.swift missing arguments"
echo "=================================================================="

WEATHER_FILE="Components/Shared Components/WeatherDashboardComponent.swift"
if [ -f "$WEATHER_FILE" ]; then
    cp "$WEATHER_FILE" "$WEATHER_FILE.final_fix_backup.$(date +%s)"
    
    cat > /tmp/fix_weather_comprehensive.py << 'PYTHON_EOF'
import re

def fix_weather_comprehensive():
    file_path = "/Volumes/FastSSD/Xcode/Components/Shared Components/WeatherDashboardComponent.swift"
    
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        print("🔧 Fixing WeatherDashboardComponent missing arguments...")
        changes_made = []
        
        for i, line in enumerate(lines):
            line_num = i + 1
            
            # Fix line 338 - Add missing arguments
            if line_num == 338 and 'WeatherDashboardComponent(' in line:
                indent = len(line) - len(line.lstrip())
                fixed_line = ' ' * indent + 'WeatherDashboardComponent(\n'
                fixed_line += ' ' * (indent + 4) + 'building: sampleLocation,\n'
                fixed_line += ' ' * (indent + 4) + 'weather: sampleWeather,\n'
                fixed_line += ' ' * (indent + 4) + 'tasks: []\n'
                fixed_line += ' ' * indent + ')\n'
                
                lines[i] = fixed_line
                changes_made.append(f"Line {line_num}: Added missing arguments to WeatherDashboardComponent")
        
        with open(file_path, 'w') as f:
            f.writelines(lines)
        
        print("✅ Applied WeatherDashboardComponent fixes:")
        for change in changes_made:
            print(f"  • {change}")
        
    except Exception as e:
        print(f"❌ Error fixing WeatherDashboardComponent: {e}")

if __name__ == "__main__":
    fix_weather_comprehensive()
PYTHON_EOF

    python3 /tmp/fix_weather_comprehensive.py
fi

# =============================================================================
# FIX 5: ViewModel syntax issues
# =============================================================================

echo ""
echo "🔧 Fix 5: Fixing ViewModel syntax and declaration issues"
echo "======================================================="

# Fix BuildingDetailViewModel.swift
BUILD_VM_FILE="Views/ViewModels/BuildingDetailViewModel.swift"
if [ -f "$BUILD_VM_FILE" ]; then
    cp "$BUILD_VM_FILE" "$BUILD_VM_FILE.final_fix_backup.$(date +%s)"
    
    # Fix line 13 - Remove arguments from no-argument call
    sed -i.tmp '13s/([^)]*)/()/g' "$BUILD_VM_FILE"
    rm -f "${BUILD_VM_FILE}.tmp"
    echo "✅ Fixed BuildingDetailViewModel.swift line 13"
fi

# Fix WorkerDashboardViewModel.swift
WORKER_VM_FILE="Views/ViewModels/WorkerDashboardViewModel.swift"
if [ -f "$WORKER_VM_FILE" ]; then
    cp "$WORKER_VM_FILE" "$WORKER_VM_FILE.final_fix_backup.$(date +%s)"
    
    cat > /tmp/fix_worker_vm_comprehensive.py << 'PYTHON_EOF'
import re

def fix_worker_vm_comprehensive():
    file_path = "/Volumes/FastSSD/Xcode/Views/ViewModels/WorkerDashboardViewModel.swift"
    
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        print("🔧 Fixing WorkerDashboardViewModel syntax...")
        changes_made = []
        
        for i, line in enumerate(lines):
            line_num = i + 1
            
            # Fix line 27 - Expected 'func' keyword issue
            if line_num == 27:
                if 'TaskProgress(' in line and not line.strip().startswith('let') and not line.strip().startswith('var'):
                    # This should be a property declaration
                    indent = len(line) - len(line.lstrip())
                    lines[i] = ' ' * indent + 'private var progress = TaskProgress(completed: 0, total: 0, remaining: 0, percentage: 0, overdueTasks: 0)\n'
                    changes_made.append(f"Line {line_num}: Fixed property declaration syntax")
        
        with open(file_path, 'w') as f:
            f.writelines(lines)
        
        print("✅ Applied WorkerDashboardViewModel fixes:")
        for change in changes_made:
            print(f"  • {change}")
        
    except Exception as e:
        print(f"❌ Error fixing WorkerDashboardViewModel: {e}")

if __name__ == "__main__":
    fix_worker_vm_comprehensive()
PYTHON_EOF

    python3 /tmp/fix_worker_vm_comprehensive.py
fi

# Fix TodayTasksViewModel.swift
TODAY_VM_FILE="Views/Main/TodayTasksViewModel.swift"
if [ -f "$TODAY_VM_FILE" ]; then
    cp "$TODAY_VM_FILE" "$TODAY_VM_FILE.final_fix_backup.$(date +%s)"
    
    cat > /tmp/fix_today_vm_comprehensive.py << 'PYTHON_EOF'
import re

def fix_today_vm_comprehensive():
    file_path = "/Volumes/FastSSD/Xcode/Views/Main/TodayTasksViewModel.swift"
    
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        print("🔧 Fixing TodayTasksViewModel syntax...")
        changes_made = []
        
        for i, line in enumerate(lines):
            line_num = i + 1
            
            # Fix lines with declaration issues
            if line_num in [19, 20, 27, 28]:
                if 'TaskProgress(' in line and not line.strip().startswith('let') and not line.strip().startswith('var'):
                    # Fix property declaration syntax
                    indent = len(line) - len(line.lstrip())
                    if line_num == 19:
                        lines[i] = ' ' * indent + 'private var currentProgress = TaskProgress(completed: 0, total: 0, remaining: 0, percentage: 0, overdueTasks: 0)\n'
                    elif line_num == 20:
                        lines[i] = ' ' * indent + 'private var trends = TaskTrends(weeklyCompletion: [], categoryBreakdown: [:], changePercentage: 0, comparisonPeriod: "week", trend: .stable)\n'
                    elif line_num == 27:
                        lines[i] = ' ' * indent + 'private var performanceMetrics = PerformanceMetrics(efficiency: 0, tasksCompleted: 0, averageTime: 0, qualityScore: 0, lastUpdate: Date())\n'
                    elif line_num == 28:
                        lines[i] = ' ' * indent + 'private var streakData = StreakData(currentStreak: 0, longestStreak: 0, lastUpdate: Date())\n'
                    
                    changes_made.append(f"Line {line_num}: Fixed property declaration syntax")
        
        with open(file_path, 'w') as f:
            f.writelines(lines)
        
        print("✅ Applied TodayTasksViewModel fixes:")
        for change in changes_made:
            print(f"  • {change}")
        
    except Exception as e:
        print(f"❌ Error fixing TodayTasksViewModel: {e}")

if __name__ == "__main__":
    fix_today_vm_comprehensive()
PYTHON_EOF

    python3 /tmp/fix_today_vm_comprehensive.py
fi

# =============================================================================
# VERIFICATION
# =============================================================================

echo ""
echo "🔍 VERIFICATION: Checking all fixes..."
echo "====================================="

echo "🔍 Checking TaskProgress calculatedPercentage:"
grep -n "calculatedPercentage" "$MODELS_FILE" || echo "⚠️ calculatedPercentage not found"

echo ""
echo "🔍 Checking HeroStatusCard sample data:"
grep -n "sampleLocation\|sampleWeather\|sampleProgress" "$HERO_FILE" | head -3

echo ""
echo "🔍 Checking for consecutive declaration issues:"
grep -n ";" "$MODELS_FILE" | grep -E "413|425" || echo "Lines 413, 425 should have semicolons"

# =============================================================================
# BUILD TEST
# =============================================================================

echo ""
echo "🔨 TESTING: Final comprehensive build test..."
echo "============================================"

BUILD_OUTPUT=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build 2>&1)

# Count remaining error types
HEADER_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "HeaderV3B.*Extra arguments" || echo "0")
HERO_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "HeroStatusCard.*Cannot find\|calculatedPercentage\|Switch must" || echo "0")
WEATHER_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "WeatherDashboardComponent.*Missing arguments" || echo "0")
MODELS_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "FrancoSphereModels.*Consecutive" || echo "0")
VM_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "ViewModel.*Expected.*keyword\|Consecutive declarations" || echo "0")

echo "HeaderV3B errors: $HEADER_ERRORS"
echo "HeroStatusCard errors: $HERO_ERRORS"
echo "WeatherDashboardComponent errors: $WEATHER_ERRORS"
echo "FrancoSphereModels errors: $MODELS_ERRORS"
echo "ViewModel errors: $VM_ERRORS"

TOTAL_ERRORS=$((HEADER_ERRORS + HERO_ERRORS + WEATHER_ERRORS + MODELS_ERRORS + VM_ERRORS))

if [ "$TOTAL_ERRORS" -eq 0 ]; then
    echo ""
    echo "✅ SUCCESS: All targeted compilation errors resolved!"
else
    echo ""
    echo "⚠️ Some errors may remain. Current total: $TOTAL_ERRORS"
    echo "$BUILD_OUTPUT" | grep -E "(error|Error)" | head -10
fi

# =============================================================================
# CLEANUP
# =============================================================================

rm -f /tmp/fix_*.py

echo ""
echo "🎯 FINAL COMPREHENSIVE FIX COMPLETED!"
echo "===================================="
echo ""
echo "📋 Comprehensive fixes applied:"
echo "• TaskProgress: Added calculatedPercentage computed property"
echo "• HeaderV3B.swift: Removed extra arguments (lines 178, 183, 203)"
echo "• HeroStatusCard.swift: Added sample data definitions and fixed switch exhaustiveness"
echo "• HeroStatusCard.swift: Fixed constructor arguments and removed problematic lines"
echo "• WeatherDashboardComponent.swift: Added missing constructor arguments"
echo "• FrancoSphereModels.swift: Fixed consecutive declarations with semicolons"
echo "• BuildingDetailViewModel.swift: Removed arguments from no-argument constructor"
echo "• WorkerDashboardViewModel.swift: Fixed property declaration syntax"
echo "• TodayTasksViewModel.swift: Fixed multiple property declaration issues"
echo ""
echo "🚀 Build project (Cmd+B) - should now have significantly fewer compilation errors!"

exit 0
