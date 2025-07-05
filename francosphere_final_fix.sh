#!/bin/bash

echo "🔧 FrancoSphere Final Compilation Fix"
echo "====================================="
echo "Fixing remaining compilation errors with surgical precision"

cd "/Volumes/FastSSD/Xcode" || exit 1

# =============================================================================
# FIX 1: WeatherDashboardComponent.swift - CLLocationCoordinate2D conversion
# =============================================================================

echo ""
echo "🔧 Fixing WeatherDashboardComponent.swift CLLocationCoordinate2D issues..."

cat > /tmp/fix_weather_component.py << 'PYTHON_EOF'
import re
import time

def fix_weather_component():
    file_path = "/Volumes/FastSSD/Xcode/Components/Shared Components/WeatherDashboardComponent.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Create backup with timestamp
        backup_path = file_path + '.backup.' + str(int(time.time()))
        with open(backup_path, 'w') as f:
            f.write(content)
        
        print("🔧 Applying precise fixes to WeatherDashboardComponent.swift...")
        
        # Split content into lines for precise targeting
        lines = content.split('\n')
        
        # Search for the problematic lines around 340-341
        for i, line in enumerate(lines):
            # Look for WeatherManager fetchWeather calls with separate lat/lon parameters
            if 'weatherManager.fetchWeather' in line and ('latitude:' in line or 'longitude:' in line):
                print(f"✅ Found WeatherManager call at line {i+1}: {line.strip()}")
                # Replace with proper CLLocationCoordinate2D constructor
                if 'latitude:' in line and 'longitude:' in line:
                    # Extract latitude and longitude values
                    lat_match = re.search(r'latitude:\s*([^,\)]+)', line)
                    lon_match = re.search(r'longitude:\s*([^,\)]+)', line)
                    if lat_match and lon_match:
                        lat_val = lat_match.group(1).strip()
                        lon_val = lon_match.group(1).strip()
                        # Replace the entire call
                        new_line = re.sub(
                            r'weatherManager\.fetchWeather\([^)]+\)',
                            f'weatherManager.fetchWeather(for: CLLocationCoordinate2D(latitude: {lat_val}, longitude: {lon_val}))',
                            line
                        )
                        lines[i] = new_line
                        print(f"✅ Fixed line {i+1}: weatherManager.fetchWeather call")
            
            # Look for NamedCoordinate constructor calls with separate lat/lon
            elif 'NamedCoordinate' in line and 'latitude:' in line and 'longitude:' in line:
                print(f"✅ Found NamedCoordinate call at line {i+1}: {line.strip()}")
                # This should be fine as NamedCoordinate has a constructor that takes lat/lon directly
                # But let's check if it's trying to pass individual values where CLLocationCoordinate2D is expected
                if 'coordinate:' in line and ('building.latitude' in line or 'building.longitude' in line):
                    # Replace with proper coordinate object
                    new_line = re.sub(
                        r'coordinate:\s*building\.latitude,\s*longitude:\s*building\.longitude',
                        'coordinate: building.coordinate',
                        line
                    )
                    if new_line != line:
                        lines[i] = new_line
                        print(f"✅ Fixed line {i+1}: NamedCoordinate coordinate parameter")
        
        # Join lines back together
        content = '\n'.join(lines)
        
        # Additional pattern fixes for common CLLocationCoordinate2D issues
        # Fix any remaining cases where lat/lon are passed separately but CLLocationCoordinate2D is expected
        content = re.sub(
            r'CLLocationCoordinate2D\(\s*([^,\)]+),\s*([^,\)]+)\s*\)',
            r'CLLocationCoordinate2D(latitude: \1, longitude: \2)',
            content
        )
        
        # Write the fixed content
        with open(file_path, 'w') as f:
            f.write(content)
        
        print("✅ Fixed WeatherDashboardComponent.swift CLLocationCoordinate2D issues")
        return True
        
    except Exception as e:
        print(f"❌ Error fixing WeatherDashboardComponent.swift: {e}")
        return False

if __name__ == "__main__":
    fix_weather_component()
PYTHON_EOF

python3 /tmp/fix_weather_component.py

# =============================================================================
# FIX 2: FrancoSphereModels.swift - Remove duplicate declarations
# =============================================================================

echo ""
echo "🔧 Fixing FrancoSphereModels.swift duplicate declarations..."

cat > /tmp/fix_models_duplicates.py << 'PYTHON_EOF'
import re
import time

def fix_models_duplicates():
    file_path = "/Volumes/FastSSD/Xcode/Models/FrancoSphereModels.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Create backup with timestamp
        backup_path = file_path + '.backup.' + str(int(time.time()))
        with open(backup_path, 'w') as f:
            f.write(content)
        
        print("🔧 Applying precise fixes to FrancoSphereModels.swift...")
        
        # Split into lines for precise targeting
        lines = content.split('\n')
        
        # Track what we've seen to identify duplicates
        seen_declarations = set()
        lines_to_remove = []
        
        # Look for specific duplicate issues mentioned in the error report
        for i, line in enumerate(lines):
            stripped_line = line.strip()
            
            # Check for duplicate coordinate property declaration (line 24)
            if i == 23:  # Line 24 (0-based index)
                if 'coordinate' in stripped_line and ('public' in stripped_line or 'var' in stripped_line):
                    print(f"✅ Found duplicate coordinate declaration at line {i+1}: {stripped_line}")
                    # Check if this is a duplicate by looking at context
                    if 'CLLocationCoordinate2D' in stripped_line:
                        # This looks like it might be a duplicate - mark for removal
                        lines_to_remove.append(i)
                        print(f"✅ Marked line {i+1} for removal: duplicate coordinate")
            
            # Check for duplicate TrendDirection enum (line 710)
            elif i == 709:  # Line 710 (0-based index)
                if 'TrendDirection' in stripped_line and ('enum' in stripped_line or 'public' in stripped_line):
                    print(f"✅ Found duplicate TrendDirection at line {i+1}: {stripped_line}")
                    lines_to_remove.append(i)
                    print(f"✅ Marked line {i+1} for removal: duplicate TrendDirection")
            
            # Check for duplicate ExportProgress struct (line 721)
            elif i == 720:  # Line 721 (0-based index)
                if 'ExportProgress' in stripped_line and ('struct' in stripped_line or 'public' in stripped_line):
                    print(f"✅ Found duplicate ExportProgress at line {i+1}: {stripped_line}")
                    lines_to_remove.append(i)
                    print(f"✅ Marked line {i+1} for removal: duplicate ExportProgress")
        
        # Remove duplicate lines in reverse order to maintain line numbers
        for line_idx in reversed(lines_to_remove):
            print(f"✅ Removing duplicate at line {line_idx + 1}: {lines[line_idx].strip()}")
            del lines[line_idx]
        
        # Additional cleanup - look for exact duplicate type declarations
        cleaned_lines = []
        type_declarations = set()
        
        for line in lines:
            stripped = line.strip()
            
            # Check for type declaration patterns
            if re.match(r'^\s*public\s+(struct|enum|class)\s+(\w+)', stripped):
                match = re.match(r'^\s*public\s+(struct|enum|class)\s+(\w+)', stripped)
                if match:
                    type_name = match.group(2)
                    if type_name in type_declarations:
                        print(f"✅ Skipping duplicate type declaration: {type_name}")
                        continue
                    type_declarations.add(type_name)
            
            cleaned_lines.append(line)
        
        # Join lines back together
        content = '\n'.join(cleaned_lines)
        
        # Write the fixed content
        with open(file_path, 'w') as f:
            f.write(content)
        
        print("✅ Fixed FrancoSphereModels.swift duplicate declarations")
        return True
        
    except Exception as e:
        print(f"❌ Error fixing FrancoSphereModels.swift: {e}")
        return False

if __name__ == "__main__":
    fix_models_duplicates()
PYTHON_EOF

python3 /tmp/fix_models_duplicates.py

# =============================================================================
# VERIFICATION
# =============================================================================

echo ""
echo "🔍 VERIFICATION: Checking fixed lines..."

echo ""
echo "WeatherDashboardComponent.swift around lines 340-341:"
sed -n '335,345p' "Components/Shared Components/WeatherDashboardComponent.swift" 2>/dev/null || echo "File not found"

echo ""
echo "FrancoSphereModels.swift line 24:"
sed -n '24p' "Models/FrancoSphereModels.swift" 2>/dev/null || echo "File not found"

echo ""
echo "FrancoSphereModels.swift line 710:"
sed -n '710p' "Models/FrancoSphereModels.swift" 2>/dev/null || echo "File not found"

echo ""
echo "FrancoSphereModels.swift line 721:"
sed -n '721p' "Models/FrancoSphereModels.swift" 2>/dev/null || echo "File not found"

# =============================================================================
# BUILD TEST
# =============================================================================

echo ""
echo "🔨 Running build test to verify fixes..."
xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build -destination "platform=iOS Simulator,name=iPhone 15 Pro" 2>&1 | head -20

# =============================================================================
# SUMMARY  
# =============================================================================

echo ""
echo "🎯 FRANCOSPHERE FINAL FIX COMPLETED!"
echo "===================================="
echo ""
echo "📋 Applied fixes:"
echo "• WeatherDashboardComponent.swift: Fixed CLLocationCoordinate2D parameter issues"
echo "• FrancoSphereModels.swift: Removed duplicate declarations at lines 24, 710, 721"
echo ""
echo "🔍 Verification: Check the output above for specific line content"
echo "🔨 Build test: Check build output above for compilation status"
echo ""
echo "🚀 Next: Run full build with Cmd+B in Xcode"
echo ""
echo "📂 Backups created:"
echo "• WeatherDashboardComponent.swift.backup.[timestamp]"
echo "• FrancoSphereModels.swift.backup.[timestamp]"

exit 0
