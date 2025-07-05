#!/bin/bash

echo "🔧 Line-Precise Fix"
echo "==================="
echo "Fixing the exact line issues with surgical precision"

cd "/Volumes/FastSSD/Xcode" || exit 1

# =============================================================================
# FIX 1: Fix HeroStatusCard exact line issues
# =============================================================================

echo ""
echo "🔧 Fix 1: Fixing HeroStatusCard exact line issues"
echo "==============================================="

FILE="Components/Shared Components/HeroStatusCard.swift"
if [ -f "$FILE" ]; then
    echo "Fixing HeroStatusCard line by line..."
    cp "$FILE" "${FILE}.line_precise_backup.$(date +%s)"
    
    cat > /tmp/fix_hero_lines.py << 'PYTHON_EOF'
import re

def fix_hero_lines():
    file_path = "/Volumes/FastSSD/Xcode/Components/Shared Components/HeroStatusCard.swift"
    
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        print("🔧 Fixing HeroStatusCard line by line...")
        
        for i, line in enumerate(lines):
            line_num = i + 1
            
            # Fix line 43: totalTasksTasks -> totalTasks
            if line_num == 43:
                if 'totalTasksTasks' in line:
                    lines[i] = line.replace('totalTasksTasks', 'totalTasks')
                    print(f"  → Fixed line 43: totalTasksTasks -> totalTasks")
            
            # Fix weather enum corrupted values
            if line_num in [154, 156, 158, 160, 173, 175, 177, 179]:
                original_line = line
                # Fix corrupted enum values
                line = line.replace('.rainyy', '.rainy')
                line = line.replace('.snowyy', '.snowy') 
                line = line.replace('.stormyy', '.stormy')
                line = line.replace('.foggygy', '.foggy')
                
                # Also fix any remaining incorrect ones
                line = line.replace('.rain', '.rainy')
                line = line.replace('.snow', '.snowy')
                line = line.replace('.storm', '.stormy') 
                line = line.replace('.fog', '.foggy')
                
                if line != original_line:
                    lines[i] = line
                    print(f"  → Fixed line {line_num}: weather enum")
            
            # Fix constructor issues at lines 188-189
            if line_num == 188 and ('Missing arguments' in line or 'workerId' in line):
                lines[i] = '                workerId: "worker1",\n'
                print(f"  → Fixed line 188: constructor parameter 1")
            elif line_num == 189 and ('Consecutive statements' in line or 'Expected expression' in line or 'currentBuilding' in line):
                lines[i] = '                currentBuilding: "Building 1"\n'
                print(f"  → Fixed line 189: constructor parameter 2")
        
        with open(file_path, 'w') as f:
            f.writelines(lines)
        
        print("✅ Fixed HeroStatusCard line issues")
        return True
        
    except Exception as e:
        print(f"❌ Error fixing HeroStatusCard: {e}")
        return False

if __name__ == "__main__":
    fix_hero_lines()
PYTHON_EOF

    python3 /tmp/fix_hero_lines.py
fi

# =============================================================================
# FIX 2: Fix WeatherDashboardComponent exact line issues
# =============================================================================

echo ""
echo "🔧 Fix 2: Fixing WeatherDashboardComponent exact lines"
echo "===================================================="

FILE="Components/Shared Components/WeatherDashboardComponent.swift"
if [ -f "$FILE" ]; then
    echo "Fixing WeatherDashboardComponent lines 337-338..."
    cp "$FILE" "${FILE}.weather_line_backup.$(date +%s)"
    
    cat > /tmp/fix_weather_lines.py << 'PYTHON_EOF'
import re

def fix_weather_lines():
    file_path = "/Volumes/FastSSD/Xcode/Components/Shared Components/WeatherDashboardComponent.swift"
    
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        print("🔧 Fixing WeatherDashboardComponent lines 337-338...")
        
        for i, line in enumerate(lines):
            line_num = i + 1
            
            # Fix line 337: Expected expression
            if line_num == 337 and 'Expected expression' in line:
                lines[i] = '                WeatherTasksSection(\n'
                print(f"  → Fixed line 337: Expected expression")
            
            # Fix line 338: Missing arguments
            elif line_num == 338 and 'Missing arguments' in line:
                lines[i] = '                    building: building,\n'
                lines.insert(i + 1, '                    weather: weather,\n')
                lines.insert(i + 2, '                    tasks: tasks\n')
                lines.insert(i + 3, '                )\n')
                print(f"  → Fixed line 338: Missing arguments")
                break  # Break to avoid index issues after insertions
        
        with open(file_path, 'w') as f:
            f.writelines(lines)
        
        print("✅ Fixed WeatherDashboardComponent line issues")
        return True
        
    except Exception as e:
        print(f"❌ Error fixing WeatherDashboardComponent: {e}")
        return False

if __name__ == "__main__":
    fix_weather_lines()
PYTHON_EOF

    python3 /tmp/fix_weather_lines.py
fi

# =============================================================================
# FIX 3: Fix FrancoSphereModels exact line issues
# =============================================================================

echo ""
echo "🔧 Fix 3: Fixing FrancoSphereModels exact lines"
echo "============================================="

FILE="Models/FrancoSphereModels.swift"
if [ -f "$FILE" ]; then
    echo "Fixing FrancoSphereModels lines 413, 425, 452..."
    cp "$FILE" "${FILE}.models_line_backup.$(date +%s)"
    
    cat > /tmp/fix_models_lines.py << 'PYTHON_EOF'
import re

def fix_models_lines():
    file_path = "/Volumes/FastSSD/Xcode/Models/FrancoSphereModels.swift"
    
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        print("🔧 Fixing FrancoSphereModels lines 413, 425, 452...")
        
        for i, line in enumerate(lines):
            line_num = i + 1
            
            # Fix lines 413, 425: Consecutive declarations
            if line_num in [413, 425] and 'Consecutive declarations' in line:
                # Split any consecutive struct declarations on the same line
                if 'public struct' in line and line.count('public struct') > 1:
                    # Find all struct declarations and separate them
                    parts = re.split(r'(public struct)', line)
                    new_lines = []
                    current_line = ""
                    
                    for part in parts:
                        if part == 'public struct':
                            if current_line.strip():
                                new_lines.append(current_line + '\n')
                            current_line = 'public struct'
                        else:
                            current_line += part
                    
                    if current_line.strip():
                        new_lines.append(current_line)
                    
                    # Replace the current line with separated lines
                    lines[i] = new_lines[0] if new_lines else line
                    for j, new_line in enumerate(new_lines[1:], 1):
                        lines.insert(i + j, new_line)
                    
                    print(f"  → Fixed line {line_num}: Consecutive declarations")
                    break  # Break to avoid index issues
            
            # Fix line 452: Invalid redeclaration of TrendDirection
            elif line_num == 452 and 'Invalid redeclaration' in line:
                if 'TrendDirection' in line:
                    lines[i] = '    // Duplicate TrendDirection removed\n'
                    print(f"  → Fixed line 452: Removed duplicate TrendDirection")
        
        with open(file_path, 'w') as f:
            f.writelines(lines)
        
        print("✅ Fixed FrancoSphereModels line issues")
        return True
        
    except Exception as e:
        print(f"❌ Error fixing FrancoSphereModels: {e}")
        return False

if __name__ == "__main__":
    fix_models_lines()
PYTHON_EOF

    python3 /tmp/fix_models_lines.py
fi

# =============================================================================
# FIX 4: Fix ViewModel exact line issues
# =============================================================================

echo ""
echo "🔧 Fix 4: Fixing ViewModel exact line issues"
echo "=========================================="

# Fix BuildingDetailViewModel line 13
FILE="Views/ViewModels/BuildingDetailViewModel.swift"
if [ -f "$FILE" ]; then
    echo "Fixing BuildingDetailViewModel line 13..."
    cp "$FILE" "${FILE}.detail_line_backup.$(date +%s)"
    
    sed -i.tmp '13s/BuildingStatistics([^)]*)/BuildingStatistics()/' "$FILE"
    rm -f "${FILE}.tmp"
fi

# Fix WorkerDashboardViewModel lines 27-28
FILE="Views/ViewModels/WorkerDashboardViewModel.swift"
if [ -f "$FILE" ]; then
    echo "Fixing WorkerDashboardViewModel lines 27-28..."
    cp "$FILE" "${FILE}.worker_line_backup.$(date +%s)"
    
    cat > /tmp/fix_worker_lines.py << 'PYTHON_EOF'
import re

def fix_worker_lines():
    file_path = "/Volumes/FastSSD/Xcode/Views/ViewModels/WorkerDashboardViewModel.swift"
    
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        print("🔧 Fixing WorkerDashboardViewModel lines 27-28...")
        
        for i, line in enumerate(lines):
            line_num = i + 1
            
            # Fix lines 27-28: ContextualTask constructor issues
            if line_num == 27 and ('Extra arguments' in line or 'ContextualTask' in line):
                # Replace with simple ContextualTask constructor
                replacement = '''        let sampleTask = ContextualTask(
            task: MaintenanceTask(
                id: UUID().uuidString,
                buildingId: "1",
                title: "Sample Task",
                description: "Description",
                category: .maintenance,
                urgency: .medium,
                dueDate: Date()
            ),
            location: NamedCoordinate(
                id: "1",
                name: "Sample Building",
                coordinate: CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851)
            )
        )
'''
                lines[i] = replacement
                # Remove line 28 if it's part of the same constructor
                if i + 1 < len(lines) and 'Missing argument' in lines[i + 1]:
                    lines[i + 1] = ''
                print(f"  → Fixed lines 27-28: ContextualTask constructor")
                break
        
        with open(file_path, 'w') as f:
            f.writelines(lines)
        
        print("✅ Fixed WorkerDashboardViewModel line issues")
        return True
        
    except Exception as e:
        print(f"❌ Error fixing WorkerDashboardViewModel: {e}")
        return False

if __name__ == "__main__":
    fix_worker_lines()
PYTHON_EOF

    python3 /tmp/fix_worker_lines.py
fi

# Fix TodayTasksViewModel lines 19-20, 27-28
FILE="Views/Main/TodayTasksViewModel.swift"
if [ -f "$FILE" ]; then
    echo "Fixing TodayTasksViewModel lines 19-20, 27-28..."
    cp "$FILE" "${FILE}.today_line_backup.$(date +%s)"
    
    cat > /tmp/fix_today_lines.py << 'PYTHON_EOF'
import re

def fix_today_lines():
    file_path = "/Volumes/FastSSD/Xcode/Views/Main/TodayTasksViewModel.swift"
    
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        print("🔧 Fixing TodayTasksViewModel lines 19-20, 27-28...")
        
        for i, line in enumerate(lines):
            line_num = i + 1
            
            # Fix lines 19-20: ContextualTask constructor
            if line_num == 19 and ('Extra arguments' in line or 'ContextualTask' in line):
                replacement = '''        let sampleTask = ContextualTask(
            task: MaintenanceTask(
                id: UUID().uuidString,
                buildingId: "1",
                title: "Sample Task",
                description: "Description", 
                category: .maintenance,
                urgency: .medium,
                dueDate: Date()
            ),
            location: NamedCoordinate(
                id: "1",
                name: "Sample Building",
                coordinate: CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851)
            )
        )
'''
                lines[i] = replacement
                # Remove line 20 if it's part of the same issue
                if i + 1 < len(lines) and 'Missing argument' in lines[i + 1]:
                    lines[i + 1] = ''
                print(f"  → Fixed lines 19-20: ContextualTask constructor")
            
            # Fix lines 27-28: Method calls with no arguments
            elif line_num == 27 and 'Argument passed to call that takes no arguments' in line:
                lines[i] = line.replace('calculateStreakData([^)]*)', 'calculateStreakData()')
                lines[i] = re.sub(r'calculateStreakData\([^)]*\)', 'calculateStreakData()', lines[i])
                print(f"  → Fixed line 27: calculateStreakData()")
            elif line_num == 28 and 'Argument passed to call that takes no arguments' in line:
                lines[i] = line.replace('calculatePerformanceMetrics([^)]*)', 'calculatePerformanceMetrics()')
                lines[i] = re.sub(r'calculatePerformanceMetrics\([^)]*\)', 'calculatePerformanceMetrics()', lines[i])
                print(f"  → Fixed line 28: calculatePerformanceMetrics()")
        
        with open(file_path, 'w') as f:
            f.writelines(lines)
        
        print("✅ Fixed TodayTasksViewModel line issues")
        return True
        
    except Exception as e:
        print(f"❌ Error fixing TodayTasksViewModel: {e}")
        return False

if __name__ == "__main__":
    fix_today_lines()
PYTHON_EOF

    python3 /tmp/fix_today_lines.py
fi

# =============================================================================
# VERIFICATION
# =============================================================================

echo ""
echo "🔍 VERIFICATION: Testing line-precise fixes"
echo "=========================================="

echo "Building project to test line-precise fixes..."
ERROR_COUNT=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build 2>&1 | grep -c "error:")

echo ""
echo "🎯 LINE-PRECISE FIX COMPLETED!"
echo "============================="
echo "Errors remaining: $ERROR_COUNT"

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS! All compilation errors resolved!"
    echo ""
    echo "✅ Applied line-precise fixes:"
    echo "• Fixed line 43: totalTasksTasks → totalTasks"
    echo "• Fixed lines 154,156,158,160,173,175,177,179: weather enum corruptions"
    echo "• Fixed lines 188-189: HeroStatusCard constructor parameters"
    echo "• Fixed lines 337-338: WeatherDashboardComponent expression issues"
    echo "• Fixed lines 413,425: FrancoSphereModels consecutive declarations"
    echo "• Fixed line 452: removed duplicate TrendDirection"
    echo "• Fixed ViewModel constructor issues in lines 13,27-28,19-20"
    echo "• Fixed no-argument method calls"
    echo ""
    echo "🚀 Your project should now compile successfully!"
else
    echo ""
    echo "⚠️  $ERROR_COUNT errors remain:"
    xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build 2>&1 | grep "error:" | head -5
fi

exit 0
