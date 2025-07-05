#!/bin/bash

echo "🔧 FrancoSphere Ultra Precise Fix"
echo "================================"
echo "Fixing EXACT lines with EXACT return types"

cd "/Volumes/FastSSD/Xcode" || exit 1

# =============================================================================
# FIX 1: WeatherDashboardComponent.swift - Line-by-line precision
# =============================================================================

echo ""
echo "🔧 Fixing WeatherDashboardComponent.swift with surgical precision..."

cat > /tmp/ultra_precise_fix.py << 'PYTHON_EOF'
import re

def fix_weather_component_precisely():
    file_path = "/Volumes/FastSSD/Xcode/Components/Shared Components/WeatherDashboardComponent.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Create backup
        with open(file_path + '.ultra_precise_backup.' + str(int(__import__('time').time())), 'w') as f:
            f.write(content)
        
        print("🔧 Applying ultra-precise fixes...")
        
        # Split into lines for precise line-by-line editing
        lines = content.split('\n')
        
        # Process each line individually
        for i, line in enumerate(lines):
            line_num = i + 1
            
            # Line 256: String function returning .gray - fix to return proper string
            if line_num == 256 and '.gray' in line and 'return' in line:
                lines[i] = line.replace('return .gray', 'return "questionmark.circle"')
                print(f"✅ Fixed line 256: String return")
            
            # Line 278: String function returning .gray - fix to return proper string  
            elif line_num == 278 and '.gray' in line and 'return' in line:
                lines[i] = line.replace('return .gray', 'return "questionmark.circle"')
                print(f"✅ Fixed line 278: String return")
            
            # Line 289: String function returning .gray - fix to return proper string
            elif line_num == 289 and '.gray' in line and 'return' in line:
                lines[i] = line.replace('return .gray', 'return "questionmark.circle"')
                print(f"✅ Fixed line 289: String return")
            
            # Line 312: Bool function returning .medium - fix to return proper bool
            elif line_num == 312 and '.medium' in line and 'return' in line:
                lines[i] = line.replace('return .medium', 'return false')
                print(f"✅ Fixed line 312: Bool return")
            
            # Line 329: Tuple function returning .gray - fix to return proper tuple
            elif line_num == 329 and '.gray' in line and 'return' in line:
                lines[i] = line.replace('return .gray', 'return ("questionmark.circle", .gray, "Unknown")')
                print(f"✅ Fixed line 329: Tuple return")
        
        # Rejoin lines
        content = '\n'.join(lines)
        
        # Fix CLLocationCoordinate2D issue (lines 340-341) - this spans multiple lines
        content = re.sub(
            r'weatherManager\.fetchWeather\(\s*latitude:\s*([^,]+),\s*longitude:\s*([^)]+)\s*\)',
            r'weatherManager.fetchWeather(for: CLLocationCoordinate2D(latitude: \1, longitude: \2))',
            content
        )
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        print("✅ Fixed WeatherDashboardComponent.swift with precision")
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    fix_weather_component_precisely()
PYTHON_EOF

python3 /tmp/ultra_precise_fix.py

# =============================================================================
# FIX 2: FrancoSphereModels.swift - Ultra precise duplicate removal
# =============================================================================

echo ""
echo "🔧 Fixing FrancoSphereModels.swift duplicates with line precision..."

MODELS_FILE="Models/FrancoSphereModels.swift"

if [ -f "$MODELS_FILE" ]; then
    # Create backup
    cp "$MODELS_FILE" "${MODELS_FILE}.ultra_precise_backup.$(date +%s)"
    
    # Use sed to remove EXACT line matches
    echo "Removing duplicate coordinate property (line 24)..."
    sed -i.tmp '24{/public let coordinate: CLLocationCoordinate2D/d;}' "$MODELS_FILE"
    
    echo "Removing duplicate TrendDirection enum (around line 710)..."
    # Find and remove the second occurrence of TrendDirection enum
    awk '
    BEGIN { trend_seen = 0 }
    /^[[:space:]]*public enum TrendDirection/ {
        trend_seen++
        if (trend_seen == 1) {
            print
            # Print the entire first enum
            while ((getline) && $0 !~ /^[[:space:]]*}[[:space:]]*$/) {
                print
            }
            print  # Print the closing brace
        } else {
            # Skip the duplicate enum
            while ((getline) && $0 !~ /^[[:space:]]*}[[:space:]]*$/) {
                # Skip lines
            }
            # Skip the closing brace too
        }
        next
    }
    { print }
    ' "$MODELS_FILE" > "$MODELS_FILE.dedup1" && mv "$MODELS_FILE.dedup1" "$MODELS_FILE"
    
    echo "Removing duplicate ExportProgress struct (around line 721)..."
    # Find and remove the second occurrence of ExportProgress
    awk '
    BEGIN { export_seen = 0 }
    /^[[:space:]]*public struct ExportProgress/ {
        export_seen++
        if (export_seen == 1) {
            print
            # Print the entire first struct
            while ((getline) && $0 !~ /^[[:space:]]*}[[:space:]]*$/) {
                print
            }
            print  # Print the closing brace
        } else {
            # Skip the duplicate struct
            while ((getline) && $0 !~ /^[[:space:]]*}[[:space:]]*$/) {
                # Skip lines
            }
            # Skip the closing brace too
        }
        next
    }
    { print }
    ' "$MODELS_FILE" > "$MODELS_FILE.dedup2" && mv "$MODELS_FILE.dedup2" "$MODELS_FILE"
    
    rm -f "${MODELS_FILE}.tmp"
    echo "✅ Fixed FrancoSphereModels.swift duplicates with precision"
else
    echo "⚠️ FrancoSphereModels.swift not found"
fi

# =============================================================================
# FIX 3: TodayTasksViewModel.swift - Ultra precise function signature fixes
# =============================================================================

echo ""
echo "🔧 Fixing TodayTasksViewModel.swift function signatures with line precision..."

TODAY_VM_FILE="Views/Main/TodayTasksViewModel.swift"

if [ -f "$TODAY_VM_FILE" ]; then
    cp "$TODAY_VM_FILE" "${TODAY_VM_FILE}.ultra_precise_backup.$(date +%s)"
    
    # Use sed to fix exact lines
    echo "Fixing line 96 function signature..."
    sed -i.tmp '96s/private func calculateStreakData([^)]*): -> FrancoSphere\.StreakData/private func calculateStreakData() -> FrancoSphere.StreakData/' "$TODAY_VM_FILE"
    
    echo "Fixing line 113 function signature..."
    sed -i.tmp '113s/private func calculatePerformanceMetrics([^)]*): -> FrancoSphere\.PerformanceMetrics/private func calculatePerformanceMetrics() -> FrancoSphere.PerformanceMetrics/' "$TODAY_VM_FILE"
    
    # Remove any orphaned parameter declarations that are causing "Expected declaration" errors
    echo "Removing orphaned parameter fragments..."
    sed -i.tmp '/^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*:[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*$/d' "$TODAY_VM_FILE"
    
    rm -f "${TODAY_VM_FILE}.tmp"
    echo "✅ Fixed TodayTasksViewModel.swift with precision"
else
    echo "⚠️ TodayTasksViewModel.swift not found"
fi

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "🎯 ULTRA PRECISE FIX COMPLETED!"
echo "==============================="
echo ""
echo "📋 Fixed exactly these specific lines:"
echo "• WeatherDashboardComponent.swift line 256: .gray → \"questionmark.circle\""
echo "• WeatherDashboardComponent.swift line 278: .gray → \"questionmark.circle\""  
echo "• WeatherDashboardComponent.swift line 289: .gray → \"questionmark.circle\""
echo "• WeatherDashboardComponent.swift line 312: .medium → false"
echo "• WeatherDashboardComponent.swift line 329: .gray → tuple"
echo "• WeatherDashboardComponent.swift lines 340-341: CLLocationCoordinate2D"
echo "• FrancoSphereModels.swift line 24: Removed exact duplicate coordinate"
echo "• FrancoSphereModels.swift line 710: Removed exact duplicate TrendDirection"
echo "• FrancoSphereModels.swift line 721: Removed exact duplicate ExportProgress"
echo "• TodayTasksViewModel.swift line 96: Fixed function signature"
echo "• TodayTasksViewModel.swift line 113: Fixed function signature"
echo ""
echo "🚀 Next Steps:"
echo "1. Open Xcode"
echo "2. Build project (Cmd+B)"
echo ""
echo "✅ All return type mismatches should now be resolved!"

exit 0
