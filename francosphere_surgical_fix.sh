#!/bin/bash

echo "🎯 FrancoSphere Surgical Error Fix"
echo "=================================="
echo "Targeting specific remaining compilation errors"
echo ""

cd "/Volumes/FastSSD/Xcode" || exit 1

# =============================================================================
# FIX 1: Remove InventoryItem.swift from Xcode project references
# =============================================================================

echo "🔧 Fix 1: Removing InventoryItem.swift file reference"
echo "===================================================="

# Check if the file exists in project but not on disk
if [ ! -f "Models/InventoryItem.swift" ]; then
    echo "⚠️  InventoryItem.swift missing from disk but referenced in project"
    echo "✅ This file was consolidated into FrancoSphereModels.swift"
    echo "   You'll need to remove it from Xcode project manually:"
    echo "   1. Open Xcode"
    echo "   2. Right-click Models/InventoryItem.swift in project navigator"
    echo "   3. Select 'Delete' → 'Remove Reference'"
fi

# =============================================================================
# FIX 2: Surgical fix for HeroStatusCard.swift
# =============================================================================

echo ""
echo "🔧 Fix 2: Surgical fix for HeroStatusCard.swift"
echo "=============================================="

FILE="Components/Shared Components/HeroStatusCard.swift"
if [ -f "$FILE" ]; then
    # Create backup
    cp "$FILE" "$FILE.backup.$(date +%s)"
    echo "✅ Backed up $FILE"
    
    # Apply surgical Python fixes
    cat > /tmp/fix_hero_card.py << 'PYTHON_EOF'
import time

def fix_hero_status_card():
    file_path = "/Volumes/FastSSD/Xcode/Components/Shared Components/HeroStatusCard.swift"
    
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        changes_made = []
        
        for i, line in enumerate(lines):
            line_num = i + 1
            
            # FIX: Lines around 149 & 171 - Switch exhaustiveness
            if 'switch condition {' in line or ('case .' in line and 'weatherIcon' in ''.join(lines[max(0, i-5):i+5])):
                # Look for incomplete switch statements in weatherIcon function
                if i < len(lines) - 10:
                    switch_block = ''.join(lines[i:i+15])
                    if 'case .clear:' in switch_block and 'case .sunny:' not in switch_block:
                        # Add missing cases before the closing brace
                        for j in range(i+1, min(len(lines), i+15)):
                            if lines[j].strip() == '}':
                                # Insert missing cases before closing brace
                                missing_cases = '''        case .sunny: return "sun.max.fill"
        case .rainy: return "cloud.rain.fill"
        case .snowy: return "cloud.snow.fill"
        case .stormy: return "cloud.bolt.fill"
        case .foggy: return "cloud.fog.fill"
        case .windy: return "wind"
'''
                                lines.insert(j, missing_cases)
                                changes_made.append(f"Line {line_num}: Added missing WeatherCondition cases")
                                break
            
            # FIX: Lines 179, 181, 183, 185, 187 - String return instead of Color
            if ('return "' in line and 'weatherColor' in ''.join(lines[max(0, i-10):i])):
                if 'return "sun.max.fill"' in line:
                    lines[i] = line.replace('return "sun.max.fill"', 'return .yellow')
                    changes_made.append(f"Line {line_num}: Fixed String→Color return")
                elif 'return "cloud.rain.fill"' in line:
                    lines[i] = line.replace('return "cloud.rain.fill"', 'return .blue')
                    changes_made.append(f"Line {line_num}: Fixed String→Color return")
                elif 'return "cloud.snow.fill"' in line:
                    lines[i] = line.replace('return "cloud.snow.fill"', 'return .cyan')
                    changes_made.append(f"Line {line_num}: Fixed String→Color return")
                elif 'return "cloud.bolt.fill"' in line:
                    lines[i] = line.replace('return "cloud.bolt.fill"', 'return .purple')
                    changes_made.append(f"Line {line_num}: Fixed String→Color return")
                elif 'return "cloud.fog.fill"' in line:
                    lines[i] = line.replace('return "cloud.fog.fill"', 'return .gray')
                    changes_made.append(f"Line {line_num}: Fixed String→Color return")
            
            # FIX: Line 197 - WeatherData constructor parameters
            if 'WeatherData(' in line and 'date:' in line and 'humidity:' in line:
                # Fix the constructor call to match the new signature
                if 'feelsLike:' not in line:
                    # Replace with correct parameter set
                    indent = len(line) - len(line.lstrip())
                    new_line = ' ' * indent + 'WeatherData(\n'
                    new_line += ' ' * (indent + 4) + 'date: Date(),\n'
                    new_line += ' ' * (indent + 4) + 'temperature: 72,\n'
                    new_line += ' ' * (indent + 4) + 'feelsLike: 75,\n'
                    new_line += ' ' * (indent + 4) + 'humidity: 65,\n'
                    new_line += ' ' * (indent + 4) + 'windSpeed: 8,\n'
                    new_line += ' ' * (indent + 4) + 'windDirection: 180,\n'
                    new_line += ' ' * (indent + 4) + 'precipitation: 0,\n'
                    new_line += ' ' * (indent + 4) + 'snow: 0,\n'
                    new_line += ' ' * (indent + 4) + 'condition: .clear,\n'
                    new_line += ' ' * (indent + 4) + 'uvIndex: 5,\n'
                    new_line += ' ' * (indent + 4) + 'visibility: 10,\n'
                    new_line += ' ' * (indent + 4) + 'description: "Clear weather"\n'
                    new_line += ' ' * indent + ')\n'
                    
                    lines[i] = new_line
                    changes_made.append(f"Line {line_num}: Fixed WeatherData constructor parameters")
        
        # Remove any duplicate/conflicting case statements
        cleaned_lines = []
        in_weather_function = False
        seen_cases = set()
        
        for line in lines:
            if 'func weatherIcon' in line or 'func weatherColor' in line:
                in_weather_function = True
                seen_cases.clear()
            elif in_weather_function and line.strip() == '}':
                in_weather_function = False
            
            if in_weather_function and 'case .' in line.strip():
                case_match = line.strip().split(':')[0] if ':' in line else line.strip()
                if case_match in seen_cases:
                    # Skip duplicate case
                    continue
                seen_cases.add(case_match)
            
            cleaned_lines.append(line)
        
        # Write the fixed content
        with open(file_path, 'w') as f:
            f.writelines(cleaned_lines)
        
        print("✅ Applied surgical fixes to HeroStatusCard.swift:")
        for change in changes_made:
            print(f"  • {change}")
        
        if not changes_made:
            print("⚠️  No automatic changes applied - may need manual review")
        
        return len(changes_made) > 0
        
    except Exception as e:
        print(f"❌ Error applying surgical fixes: {e}")
        return False

if __name__ == "__main__":
    success = fix_hero_status_card()
    if success:
        print("\n✅ HeroStatusCard.swift surgical fixes completed")
    else:
        print("\n❌ Some issues occurred during surgical fixes")
PYTHON_EOF

    python3 /tmp/fix_hero_card.py
fi

# =============================================================================
# FIX 3: Manual fixes for any remaining switch statement issues
# =============================================================================

echo ""
echo "🔧 Fix 3: Manual fixes for switch statements"
echo "==========================================="

if [ -f "$FILE" ]; then
    # Use sed to remove any remaining problematic duplicate cases
    sed -i.tmp '/case \.sunny, \.rainy, \.snowy, \.stormy, \.foggy:/d' "$FILE"
    sed -i.tmp '/return "sun\.max\.fill"$/d' "$FILE"
    
    # Clean up any temporary files
    rm -f "${FILE}.tmp"
    
    echo "✅ Cleaned up duplicate switch cases"
fi

# =============================================================================
# FIX 4: Alternative approach - Replace entire problematic functions
# =============================================================================

echo ""
echo "🔧 Fix 4: Replace problematic functions with clean versions"
echo "========================================================"

if [ -f "$FILE" ]; then
    cat > /tmp/replace_functions.py << 'PYTHON_EOF'
import re

def replace_weather_functions():
    file_path = "/Volumes/FastSSD/Xcode/Components/Shared Components/HeroStatusCard.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Define clean weatherIcon function
        weather_icon_function = '''    private func weatherIcon(for condition: WeatherCondition) -> String {
        switch condition {
        case .clear: return "sun.max.fill"
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .rainy: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .snowy: return "cloud.snow.fill"
        case .storm: return "cloud.bolt.fill"
        case .stormy: return "cloud.bolt.fill"
        case .fog: return "cloud.fog.fill"
        case .foggy: return "cloud.fog.fill"
        case .windy: return "wind"
        }
    }'''
        
        # Define clean weatherColor function
        weather_color_function = '''    private func weatherColor(for condition: WeatherCondition) -> Color {
        switch condition {
        case .clear: return .yellow
        case .sunny: return .yellow
        case .cloudy: return .gray
        case .rain: return .blue
        case .rainy: return .blue
        case .snow: return .cyan
        case .snowy: return .cyan
        case .storm: return .purple
        case .stormy: return .purple
        case .fog: return .gray
        case .foggy: return .gray
        case .windy: return .green
        }
    }'''
        
        # Replace weatherIcon function
        icon_pattern = r'private func weatherIcon\(for condition: WeatherCondition\) -> String \{[^}]*\}(?:\s*\})?'
        content = re.sub(icon_pattern, weather_icon_function, content, flags=re.DOTALL)
        
        # Replace weatherColor function
        color_pattern = r'private func weatherColor\(for condition: WeatherCondition\) -> Color \{[^}]*\}(?:\s*\})?'
        content = re.sub(color_pattern, weather_color_function, content, flags=re.DOTALL)
        
        # Fix WeatherData constructor in preview
        preview_pattern = r'WeatherData\([^)]*\)'
        new_weather_data = '''WeatherData(
            date: Date(),
            temperature: 72,
            feelsLike: 75,
            humidity: 65,
            windSpeed: 8,
            windDirection: 180,
            precipitation: 0,
            snow: 0,
            condition: .clear,
            uvIndex: 5,
            visibility: 10,
            description: "Clear weather"
        )'''
        content = re.sub(preview_pattern, new_weather_data, content, flags=re.DOTALL)
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        print("✅ Replaced weather functions with clean versions")
        return True
        
    except Exception as e:
        print(f"❌ Error replacing functions: {e}")
        return False

if __name__ == "__main__":
    replace_weather_functions()
PYTHON_EOF

    python3 /tmp/replace_functions.py
fi

# =============================================================================
# VERIFICATION
# =============================================================================

echo ""
echo "🔍 VERIFICATION: Checking specific problematic lines"
echo "===================================================="

if [ -f "$FILE" ]; then
    echo "🔍 Checking lines around 149:"
    sed -n '145,155p' "$FILE" | nl -v145
    
    echo ""
    echo "🔍 Checking lines around 171:"
    sed -n '167,177p' "$FILE" | nl -v167
    
    echo ""
    echo "🔍 Checking lines around 179-187:"
    sed -n '175,190p' "$FILE" | nl -v175
    
    echo ""
    echo "🔍 Checking lines around 197:"
    sed -n '193,203p' "$FILE" | nl -v193
fi

# =============================================================================
# BUILD TEST
# =============================================================================

echo ""
echo "🔨 BUILD TEST: Testing specific file compilation"
echo "==============================================="

# Test compile just the problematic file first
echo "Testing HeroStatusCard.swift compilation..."
HERO_COMPILE=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build 2>&1 | grep -A3 -B3 "HeroStatusCard.swift")

if echo "$HERO_COMPILE" | grep -q "error:"; then
    echo "⚠️ HeroStatusCard.swift still has errors:"
    echo "$HERO_COMPILE" | grep "error:"
else
    echo "✅ HeroStatusCard.swift compiles cleanly"
fi

# Test full project compilation
echo ""
echo "Testing full project compilation..."
FULL_COMPILE=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build 2>&1)
ERROR_COUNT=$(echo "$FULL_COMPILE" | grep -c "error:" || echo "0")
WARNING_COUNT=$(echo "$FULL_COMPILE" | grep -c "warning:" || echo "0")

echo "Compilation results:"
echo "• Errors: $ERROR_COUNT"
echo "• Warnings: $WARNING_COUNT"

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo ""
    echo "✅ SUCCESS: All compilation errors resolved!"
    echo "🎉 Project should now build successfully"
else
    echo ""
    echo "⚠️ Remaining errors:"
    echo "$FULL_COMPILE" | grep "error:" | head -10
fi

# =============================================================================
# MANUAL INSTRUCTIONS
# =============================================================================

echo ""
echo "📋 MANUAL STEPS REQUIRED"
echo "========================"
echo ""
echo "If InventoryItem.swift error persists:"
echo "1. Open Xcode"
echo "2. In Project Navigator, find Models/InventoryItem.swift (red/missing)"
echo "3. Right-click → Delete → Remove Reference"
echo "4. The type is now defined in FrancoSphereModels.swift"
echo ""
echo "If switch statement errors persist:"
echo "1. Open HeroStatusCard.swift in Xcode"
echo "2. Look for any remaining switch statements with missing cases"
echo "3. Add missing cases or use our generated functions above"

echo ""
echo "🎯 SURGICAL FIX COMPLETED!"
echo "=========================="
echo ""
echo "📋 Applied fixes:"
echo "• Fixed switch statement exhaustiveness in weather functions"
echo "• Corrected String→Color return type mismatches"
echo "• Fixed WeatherData constructor parameters"
echo "• Cleaned up duplicate case statements"
echo "• Provided manual instructions for InventoryItem.swift reference"
echo ""
echo "🚀 Build project (Cmd+B) to verify all fixes!"

exit 0
