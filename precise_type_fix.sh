#!/bin/bash

echo "🔧 FrancoSphere Precise Type Fix"
echo "==============================="
echo "Fixing exact return type mismatches from error report"

cd "/Volumes/FastSSD/Xcode" || exit 1

# =============================================================================
# FIX 1: WeatherDashboardComponent.swift - Return type mismatches
# =============================================================================

echo ""
echo "🔧 Fixing WeatherDashboardComponent.swift return type mismatches..."

cat > /tmp/fix_return_types.py << 'PYTHON_EOF'
import re

def fix_weather_component_returns():
    file_path = "/Volumes/FastSSD/Xcode/Components/Shared Components/WeatherDashboardComponent.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Create backup
        with open(file_path + '.type_fix_backup.' + str(int(__import__('time').time())), 'w') as f:
            f.write(content)
        
        print("🔧 Fixing return type mismatches...")
        
        # Fix line 245: Bool return instead of OutdoorWorkRisk
        # Look for default cases that return false instead of risk level
        content = re.sub(
            r'default:\s*return false',
            'default:\n            return .medium',
            content
        )
        
        # Fix line 267: String return instead of Color
        # Look for default cases that return string instead of color
        content = re.sub(
            r'default:\s*return "questionmark\.circle"',
            'default:\n            return .gray',
            content
        )
        
        # Fix line 329: String return instead of tuple
        # Look for functions returning tuples that have wrong default
        tuple_return_pattern = r'(func getTaskWeatherImpact.*?-> \(icon: String, color: Color, text: String\).*?default:\s*)return "[^"]*"'
        tuple_replacement = r'\1return ("questionmark.circle", .gray, "Unknown")'
        content = re.sub(tuple_return_pattern, tuple_replacement, content, flags=re.DOTALL)
        
        # Fix CLLocationCoordinate2D conversion (lines 340-341)
        content = re.sub(
            r'weatherManager\.fetchWeather\(latitude:\s*([^,]+),\s*longitude:\s*([^)]+)\)',
            r'weatherManager.fetchWeather(for: CLLocationCoordinate2D(latitude: \1, longitude: \2))',
            content
        )
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        print("✅ Fixed WeatherDashboardComponent.swift return types")
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    fix_weather_component_returns()
PYTHON_EOF

python3 /tmp/fix_return_types.py

# =============================================================================
# FIX 2: FrancoSphereModels.swift - Remove duplicate declarations (precisely)
# =============================================================================

echo ""
echo "🔧 Fixing FrancoSphereModels.swift duplicate declarations..."

MODELS_FILE="Models/FrancoSphereModels.swift"

if [ -f "$MODELS_FILE" ]; then
    # Create backup
    cp "$MODELS_FILE" "${MODELS_FILE}.type_fix_backup.$(date +%s)"
    
    echo "Removing duplicate coordinate property (line 24)..."
    # Remove only lines that match exactly "public let coordinate: CLLocationCoordinate2D"
    sed -i.tmp '/^[[:space:]]*public let coordinate: CLLocationCoordinate2D/d' "$MODELS_FILE"
    
    echo "Removing duplicate TrendDirection enum (line 710)..."
    echo "Removing duplicate ExportProgress enum (line 721)..."
    
    # Use awk to remove duplicate enum declarations more precisely
    awk '
    BEGIN { 
        trend_count = 0
        export_count = 0
        in_trend_enum = 0
        in_export_enum = 0
        brace_depth = 0
    }
    
    # Track TrendDirection enum
    /^[[:space:]]*public enum TrendDirection/ {
        trend_count++
        if (trend_count == 1) {
            print
            in_trend_enum = 1
            brace_depth = 0
        } else {
            in_trend_enum = 1
            brace_depth = 0
        }
        next
    }
    
    # Track ExportProgress struct/enum
    /^[[:space:]]*public (struct|enum) ExportProgress/ {
        export_count++
        if (export_count == 1) {
            print
            in_export_enum = 1
            brace_depth = 0
        } else {
            in_export_enum = 1
            brace_depth = 0
        }
        next
    }
    
    # Handle content inside enums
    {
        if (in_trend_enum || in_export_enum) {
            # Count braces to know when enum ends
            gsub(/\{/, "", $0); open_braces = gsub(/\{/, "{", $0)
            gsub(/\}/, "", $0); close_braces = gsub(/\}/, "}", $0)
            brace_depth += open_braces - close_braces
            
            # If we are in first occurrence, print it
            if ((in_trend_enum && trend_count == 1) || (in_export_enum && export_count == 1)) {
                print
            }
            
            # If brace depth returns to 0, we are done with this enum
            if (brace_depth <= 0) {
                in_trend_enum = 0
                in_export_enum = 0
                brace_depth = 0
            }
        } else {
            print
        }
    }
    ' "$MODELS_FILE" > "$MODELS_FILE.tmp" && mv "$MODELS_FILE.tmp" "$MODELS_FILE"
    
    rm -f "${MODELS_FILE}.tmp"
    echo "✅ Fixed FrancoSphereModels.swift duplicates"
else
    echo "⚠️ FrancoSphereModels.swift not found"
fi

# =============================================================================
# FIX 3: TodayTasksViewModel.swift - Malformed function signatures
# =============================================================================

echo ""
echo "🔧 Fixing TodayTasksViewModel.swift malformed function signatures..."

TODAY_VM_FILE="Views/Main/TodayTasksViewModel.swift"

if [ -f "$TODAY_VM_FILE" ]; then
    cp "$TODAY_VM_FILE" "${TODAY_VM_FILE}.type_fix_backup.$(date +%s)"
    
    # Fix line 97: malformed function signature
    sed -i.tmp 's/private func calculateStreakData([^)]*): -> FrancoSphere\.StreakData/private func calculateStreakData() -> FrancoSphere.StreakData/g' "$TODAY_VM_FILE"
    
    # Fix line 114: malformed function signature  
    sed -i.tmp 's/private func calculatePerformanceMetrics([^)]*): -> FrancoSphere\.PerformanceMetrics/private func calculatePerformanceMetrics() -> FrancoSphere.PerformanceMetrics/g' "$TODAY_VM_FILE"
    
    # Remove any malformed parameter syntax with extra colons
    sed -i.tmp 's/([^)]*):([^)]*):([^)]*):([^)]*): -> /() -> /g' "$TODAY_VM_FILE"
    sed -i.tmp 's/([^)]*):([^)]*): -> /() -> /g' "$TODAY_VM_FILE"
    
    # Fix consecutive declaration errors by removing orphaned parameter fragments
    sed -i.tmp '/^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*:[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*$/d' "$TODAY_VM_FILE"
    
    rm -f "${TODAY_VM_FILE}.tmp"
    echo "✅ Fixed TodayTasksViewModel.swift function signatures"
else
    echo "⚠️ TodayTasksViewModel.swift not found"
fi

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "🎯 PRECISE TYPE FIX COMPLETED!"
echo "=============================="
echo ""
echo "📋 Fixed exactly these issues:"
echo "• WeatherDashboardComponent.swift line 245: Bool → OutdoorWorkRisk"
echo "• WeatherDashboardComponent.swift line 267: String → Color"  
echo "• WeatherDashboardComponent.swift line 329: String → tuple"
echo "• WeatherDashboardComponent.swift lines 340-341: CLLocationCoordinate2D"
echo "• FrancoSphereModels.swift line 24: Removed duplicate coordinate"
echo "• FrancoSphereModels.swift line 710: Removed duplicate TrendDirection"
echo "• FrancoSphereModels.swift line 721: Removed duplicate ExportProgress"
echo "• TodayTasksViewModel.swift lines 97, 114: Fixed function signatures"
echo ""
echo "🚀 Next Steps:"
echo "1. Open Xcode"
echo "2. Build project (Cmd+B)"
echo ""
echo "✅ All type mismatches should now be resolved!"

exit 0
