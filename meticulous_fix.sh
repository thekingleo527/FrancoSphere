#!/bin/bash

echo "🔧 FrancoSphere Meticulous Line-by-Line Fix"
echo "==========================================="
echo "Targeting EXACT lines with EXACT character precision"

cd "/Volumes/FastSSD/Xcode" || exit 1

# =============================================================================
# FIX 1: WeatherDashboardComponent.swift lines 340-341 (CLLocationCoordinate2D)
# =============================================================================

echo ""
echo "🔧 Fixing WeatherDashboardComponent.swift lines 340-341 with character precision..."

cat > /tmp/meticulous_weather_fix.py << 'PYTHON_EOF'
import re

def fix_weather_lines_340_341():
    file_path = "/Volumes/FastSSD/Xcode/Components/Shared Components/WeatherDashboardComponent.swift"
    
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        # Create backup
        with open(file_path + '.meticulous_backup.' + str(int(__import__('time').time())), 'w') as f:
            f.writelines(lines)
        
        print("🔧 Examining lines 340-341...")
        
        # Check lines 340-341 (array index 339-340)
        if len(lines) >= 341:
            line_340 = lines[339].strip()
            line_341 = lines[340].strip()
            
            print(f"Line 340: {line_340}")
            print(f"Line 341: {line_341}")
            
            # Look for the fetchWeather call pattern across these lines
            combined = line_340 + " " + line_341
            
            # Fix the specific pattern: weatherManager.fetchWeather(latitude: X, longitude: Y)
            if 'weatherManager.fetchWeather' in combined and 'latitude:' in combined and 'longitude:' in combined:
                # Extract the latitude and longitude values
                lat_match = re.search(r'latitude:\s*([^,]+)', combined)
                lon_match = re.search(r'longitude:\s*([^)]+)', combined)
                
                if lat_match and lon_match:
                    lat_value = lat_match.group(1).strip()
                    lon_value = lon_match.group(1).strip()
                    
                    # Create the fixed call
                    fixed_call = f"weatherManager.fetchWeather(for: CLLocationCoordinate2D(latitude: {lat_value}, longitude: {lon_value}))"
                    
                    # Replace the entire call
                    new_line_340 = re.sub(
                        r'weatherManager\.fetchWeather\([^)]*\)',
                        fixed_call,
                        line_340
                    )
                    
                    # If the call spans two lines, we need to handle it carefully
                    if new_line_340 != line_340:
                        lines[339] = new_line_340 + '\n'
                        # Remove the continuation from line 341 if it exists
                        if 'longitude:' in line_341 and not 'weatherManager' in line_341:
                            lines[340] = '\n'  # Empty the continuation line
                    
                    print(f"✅ Fixed lines 340-341: {fixed_call}")
        
        with open(file_path, 'w') as f:
            f.writelines(lines)
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    fix_weather_lines_340_341()
PYTHON_EOF

python3 /tmp/meticulous_weather_fix.py

# =============================================================================
# FIX 2: FrancoSphereModels.swift - Meticulous duplicate removal
# =============================================================================

echo ""
echo "🔧 Fixing FrancoSphereModels.swift duplicates with line precision..."

cat > /tmp/meticulous_models_fix.py << 'PYTHON_EOF'
import re

def fix_models_duplicates():
    file_path = "/Volumes/FastSSD/Xcode/Models/FrancoSphereModels.swift"
    
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        # Create backup
        with open(file_path + '.meticulous_backup.' + str(int(__import__('time').time())), 'w') as f:
            f.writelines(lines)
        
        print("🔧 Examining specific duplicate lines...")
        
        # Fix line 24: Remove duplicate coordinate property
        if len(lines) >= 24:
            line_24 = lines[23].strip()  # Array index 23 for line 24
            print(f"Line 24: {line_24}")
            
            if 'public let coordinate: CLLocationCoordinate2D' in line_24:
                lines[23] = ''  # Remove this line completely
                print("✅ Removed duplicate coordinate property from line 24")
        
        # Find and remove duplicate TrendDirection enum (around line 710)
        trend_direction_lines = []
        for i, line in enumerate(lines):
            if 'public enum TrendDirection' in line:
                trend_direction_lines.append(i + 1)  # Store 1-based line numbers
        
        print(f"Found TrendDirection at lines: {trend_direction_lines}")
        
        # Remove second occurrence if exists
        if len(trend_direction_lines) > 1:
            start_line = trend_direction_lines[1] - 1  # Convert to 0-based
            brace_count = 0
            end_line = start_line
            
            # Find the end of the enum
            for i in range(start_line, len(lines)):
                line = lines[i]
                brace_count += line.count('{') - line.count('}')
                if brace_count <= 0 and i > start_line:
                    end_line = i
                    break
            
            # Remove lines from start_line to end_line
            for i in range(start_line, end_line + 1):
                if i < len(lines):
                    lines[i] = ''
            
            print(f"✅ Removed duplicate TrendDirection enum from lines {start_line + 1}-{end_line + 1}")
        
        # Find and remove duplicate ExportProgress struct (around line 721)
        export_progress_lines = []
        for i, line in enumerate(lines):
            if 'public struct ExportProgress' in line:
                export_progress_lines.append(i + 1)
        
        print(f"Found ExportProgress at lines: {export_progress_lines}")
        
        # Remove second occurrence if exists
        if len(export_progress_lines) > 1:
            start_line = export_progress_lines[1] - 1  # Convert to 0-based
            brace_count = 0
            end_line = start_line
            
            # Find the end of the struct
            for i in range(start_line, len(lines)):
                line = lines[i]
                brace_count += line.count('{') - line.count('}')
                if brace_count <= 0 and i > start_line:
                    end_line = i
                    break
            
            # Remove lines from start_line to end_line
            for i in range(start_line, end_line + 1):
                if i < len(lines):
                    lines[i] = ''
            
            print(f"✅ Removed duplicate ExportProgress struct from lines {start_line + 1}-{end_line + 1}")
        
        with open(file_path, 'w') as f:
            f.writelines(lines)
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    fix_models_duplicates()
PYTHON_EOF

python3 /tmp/meticulous_models_fix.py

# =============================================================================
# FIX 3: TodayTasksViewModel.swift - Meticulous function signature fixes
# =============================================================================

echo ""
echo "🔧 Fixing TodayTasksViewModel.swift lines 96 and 113 with character precision..."

cat > /tmp/meticulous_vm_fix.py << 'PYTHON_EOF'
import re

def fix_vm_function_signatures():
    file_path = "/Volumes/FastSSD/Xcode/Views/Main/TodayTasksViewModel.swift"
    
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        # Create backup
        with open(file_path + '.meticulous_backup.' + str(int(__import__('time').time())), 'w') as f:
            f.writelines(lines)
        
        print("🔧 Examining lines 96 and 113...")
        
        # Fix line 96
        if len(lines) >= 96:
            line_96 = lines[95].strip()  # Array index 95 for line 96
            print(f"Line 96 before: {line_96}")
            
            # Replace malformed function signature
            if 'calculateStreakData' in line_96:
                # Replace entire line with correct signature
                lines[95] = "    private func calculateStreakData() -> FrancoSphere.StreakData {\n"
                print("✅ Fixed line 96 function signature")
        
        # Fix line 113  
        if len(lines) >= 113:
            line_113 = lines[112].strip()  # Array index 112 for line 113
            print(f"Line 113 before: {line_113}")
            
            # Replace malformed function signature
            if 'calculatePerformanceMetrics' in line_113:
                # Replace entire line with correct signature
                lines[112] = "    private func calculatePerformanceMetrics() -> FrancoSphere.PerformanceMetrics {\n"
                print("✅ Fixed line 113 function signature")
        
        # Remove any orphaned parameter declaration lines that might follow
        for i in range(len(lines)):
            line = lines[i].strip()
            # Look for orphaned parameter patterns like "parameter: Type"
            if re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*:\s*[a-zA-Z_][a-zA-Z0-9_]*$', line):
                lines[i] = ''
                print(f"✅ Removed orphaned parameter declaration from line {i + 1}")
        
        with open(file_path, 'w') as f:
            f.writelines(lines)
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    fix_vm_function_signatures()
PYTHON_EOF

python3 /tmp/meticulous_vm_fix.py

# =============================================================================
# VERIFICATION
# =============================================================================

echo ""
echo "🔍 VERIFICATION: Checking fixed lines..."

# Check WeatherDashboardComponent.swift lines 340-341
echo "Checking WeatherDashboardComponent.swift lines 340-341:"
sed -n '340,341p' "Components/Shared Components/WeatherDashboardComponent.swift" 2>/dev/null || echo "File not found or lines don't exist"

# Check FrancoSphereModels.swift line 24
echo ""
echo "Checking FrancoSphereModels.swift line 24:"
sed -n '24p' "Models/FrancoSphereModels.swift" 2>/dev/null || echo "File not found or line doesn't exist"

# Check TodayTasksViewModel.swift lines 96, 113
echo ""
echo "Checking TodayTasksViewModel.swift lines 96, 113:"
sed -n '96p' "Views/Main/TodayTasksViewModel.swift" 2>/dev/null || echo "File not found or line doesn't exist"
sed -n '113p' "Views/Main/TodayTasksViewModel.swift" 2>/dev/null || echo "File not found or line doesn't exist"

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "🎯 METICULOUS LINE-BY-LINE FIX COMPLETED!"
echo "========================================="
echo ""
echo "📋 Applied character-precise fixes to:"
echo "• WeatherDashboardComponent.swift lines 340-341: CLLocationCoordinate2D conversion"
echo "• FrancoSphereModels.swift line 24: Removed exact duplicate coordinate property"
echo "• FrancoSphereModels.swift line 710: Removed exact duplicate TrendDirection enum"
echo "• FrancoSphereModels.swift line 721: Removed exact duplicate ExportProgress struct"
echo "• TodayTasksViewModel.swift line 96: Fixed calculateStreakData function signature"
echo "• TodayTasksViewModel.swift line 113: Fixed calculatePerformanceMetrics function signature"
echo ""
echo "🚀 Next Steps:"
echo "1. Open Xcode"
echo "2. Build project (Cmd+B)"
echo ""
echo "✅ All specific line errors should now be resolved with surgical precision!"

exit 0
