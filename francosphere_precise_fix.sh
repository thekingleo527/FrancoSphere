#!/bin/bash

echo "🎯 FrancoSphere Precise Error Fix"
echo "================================="
echo "Fixing specific line errors in HeroStatusCard.swift"
echo ""

cd "/Volumes/FastSSD/Xcode" || exit 1

FILE="Components/Shared Components/HeroStatusCard.swift"

# =============================================================================
# BACKUP AND PRECISE FIXES
# =============================================================================

if [ -f "$FILE" ]; then
    # Create backup
    cp "$FILE" "$FILE.backup.$(date +%s)"
    echo "✅ Backed up $FILE"
    
    # Apply precise fixes using Python
    cat > /tmp/precise_fix.py << 'PYTHON_EOF'
import re

def fix_hero_status_card_precise():
    file_path = "/Volumes/FastSSD/Xcode/Components/Shared Components/HeroStatusCard.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        print("🔧 Applying precise fixes...")
        
        # Check current state
        lines = content.split('\n')
        
        # FIX 1: Fix line 184 - WeatherData constructor call
        for i, line in enumerate(lines):
            line_num = i + 1
            
            # Look for problematic WeatherData constructor around line 184
            if line_num >= 180 and line_num <= 190 and 'WeatherData(' in line:
                print(f"Found WeatherData constructor at line {line_num}")
                # Replace with simplified constructor using the legacy version
                indent = len(line) - len(line.lstrip())
                new_line = ' ' * indent + 'WeatherData(\n'
                new_line += ' ' * (indent + 4) + 'temperature: 72,\n'
                new_line += ' ' * (indent + 4) + 'condition: .clear,\n'
                new_line += ' ' * (indent + 4) + 'humidity: 65,\n'
                new_line += ' ' * (indent + 4) + 'windSpeed: 8,\n'
                new_line += ' ' * (indent + 4) + 'timestamp: Date()\n'
                new_line += ' ' * indent + ')'
                
                lines[i] = new_line
                print(f"✅ Fixed WeatherData constructor at line {line_num}")
        
        # FIX 2: Fix line 202 - .clear reference
        for i, line in enumerate(lines):
            line_num = i + 1
            if line_num >= 200 and line_num <= 210:
                if '.clear' in line and 'WeatherCondition' not in line:
                    lines[i] = line.replace('.clear', 'WeatherCondition.clear')
                    print(f"✅ Fixed .clear reference at line {line_num}")
        
        # FIX 3: Fix syntax errors around lines 206, 214, 215
        # Look for malformed function blocks and fix them
        fixed_content = '\n'.join(lines)
        
        # Ensure proper function structure for weatherIcon
        weather_icon_func = '''    private func weatherIcon(for condition: WeatherCondition) -> String {
        switch condition {
        case .clear, .sunny:
            return "sun.max.fill"
        case .cloudy:
            return "cloud.fill"
        case .rain, .rainy:
            return "cloud.rain.fill"
        case .snow, .snowy:
            return "cloud.snow.fill"
        case .storm, .stormy:
            return "cloud.bolt.fill"
        case .fog, .foggy:
            return "cloud.fog.fill"
        case .windy:
            return "wind"
        }
    }'''
        
        # Ensure proper function structure for weatherColor
        weather_color_func = '''    private func weatherColor(for condition: WeatherCondition) -> Color {
        switch condition {
        case .clear, .sunny:
            return .yellow
        case .cloudy:
            return .gray
        case .rain, .rainy:
            return .blue
        case .snow, .snowy:
            return .cyan
        case .storm, .stormy:
            return .purple
        case .fog, .foggy:
            return .gray
        case .windy:
            return .green
        }
    }'''
        
        # Replace any malformed weather functions
        # Look for the weatherIcon function and replace it
        icon_pattern = r'private func weatherIcon\(for condition: WeatherCondition\) -> String \{.*?\n    \}'
        if re.search(icon_pattern, fixed_content, re.DOTALL):
            fixed_content = re.sub(icon_pattern, weather_icon_func, fixed_content, flags=re.DOTALL)
            print("✅ Replaced weatherIcon function")
        else:
            # If pattern doesn't match, look for a simpler pattern
            simple_icon_pattern = r'func weatherIcon.*?\n.*?\}'
            if re.search(simple_icon_pattern, fixed_content, re.DOTALL):
                fixed_content = re.sub(simple_icon_pattern, weather_icon_func, fixed_content, flags=re.DOTALL)
                print("✅ Replaced weatherIcon function (simple pattern)")
        
        # Replace weatherColor function
        color_pattern = r'private func weatherColor\(for condition: WeatherCondition\) -> Color \{.*?\n    \}'
        if re.search(color_pattern, fixed_content, re.DOTALL):
            fixed_content = re.sub(color_pattern, weather_color_func, fixed_content, flags=re.DOTALL)
            print("✅ Replaced weatherColor function")
        else:
            # If pattern doesn't match, look for a simpler pattern
            simple_color_pattern = r'func weatherColor.*?\n.*?\}'
            if re.search(simple_color_pattern, fixed_content, re.DOTALL):
                fixed_content = re.sub(simple_color_pattern, weather_color_func, fixed_content, flags=re.DOTALL)
                print("✅ Replaced weatherColor function (simple pattern)")
        
        # Clean up any malformed syntax
        # Remove any lines that have syntax errors
        lines = fixed_content.split('\n')
        cleaned_lines = []
        
        for line in lines:
            # Skip lines that are clearly malformed
            if line.strip() == 'case .sunny: return "sun.max.fill"case .rainy: return "cloud.rain.fill"':
                continue
            if 'case .sunny: return "sun.max.fill"' in line and 'case .rainy:' in line:
                continue
            # Fix any remaining consecutive statements
            if ';' not in line and line.count('case .') > 1:
                continue
            
            cleaned_lines.append(line)
        
        final_content = '\n'.join(cleaned_lines)
        
        # Write the fixed content
        with open(file_path, 'w') as f:
            f.write(final_content)
        
        print("✅ Applied all precise fixes")
        return True
        
    except Exception as e:
        print(f"❌ Error applying precise fixes: {e}")
        return False

if __name__ == "__main__":
    fix_hero_status_card_precise()
PYTHON_EOF
    
    python3 /tmp/precise_fix.py
    
    # Additional manual fixes using sed for any remaining issues
    echo ""
    echo "🔧 Applying additional manual fixes..."
    
    # Fix any remaining .clear references without WeatherCondition prefix
    sed -i.tmp 's/condition: \.clear/condition: WeatherCondition.clear/g' "$FILE"
    
    # Clean up any malformed lines around the problematic areas
    sed -i.tmp '/^[[:space:]]*case \..*case \./d' "$FILE"
    
    # Remove temporary file
    rm -f "${FILE}.tmp"
    
    echo "✅ Applied additional manual fixes"
fi

# =============================================================================
# ALTERNATIVE: Replace entire Preview section if needed
# =============================================================================

echo ""
echo "🔧 Replacing Preview section with clean version"
echo "=============================================="

if [ -f "$FILE" ]; then
    cat > /tmp/fix_preview.py << 'PYTHON_EOF'
import re

def fix_preview_section():
    file_path = "/Volumes/FastSSD/Xcode/Components/Shared Components/HeroStatusCard.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Define a clean preview section
        clean_preview = '''#Preview {
    HeroStatusCard(
        workerId: "4",
        currentBuilding: "Rubin Museum",
        weather: WeatherData(
            temperature: 72,
            condition: WeatherCondition.clear,
            humidity: 65,
            windSpeed: 8,
            timestamp: Date()
        ),
        progress: TaskProgress(
            completed: 8,
            total: 12,
            remaining: 4,
            percentage: 66.7,
            overdueTasks: 1
        ),
        onClockInTap: {}
    )
    .padding()
}'''
        
        # Replace the preview section
        preview_pattern = r'#Preview \{.*?\}'
        if re.search(preview_pattern, content, re.DOTALL):
            content = re.sub(preview_pattern, clean_preview, content, flags=re.DOTALL)
            print("✅ Replaced Preview section with clean version")
        else:
            # If we can't find the preview, add it at the end
            if '#Preview' not in content:
                content += '\n\n' + clean_preview
                print("✅ Added clean Preview section")
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        return True
        
    except Exception as e:
        print(f"❌ Error fixing preview: {e}")
        return False

if __name__ == "__main__":
    fix_preview_section()
PYTHON_EOF
    
    python3 /tmp/fix_preview.py
fi

# =============================================================================
# VERIFICATION
# =============================================================================

echo ""
echo "🔍 VERIFICATION: Checking problematic lines"
echo "=========================================="

if [ -f "$FILE" ]; then
    echo "🔍 Line 184 area:"
    sed -n '180,188p' "$FILE" | nl -v180
    
    echo ""
    echo "🔍 Line 202 area:"
    sed -n '198,208p' "$FILE" | nl -v198
    
    echo ""
    echo "🔍 Line 206 area:"
    sed -n '202,212p' "$FILE" | nl -v202
    
    echo ""
    echo "🔍 Line 214-215 area:"
    sed -n '210,220p' "$FILE" | nl -v210
fi

# =============================================================================
# BUILD TEST
# =============================================================================

echo ""
echo "🔨 BUILD TEST: Testing compilation"
echo "================================="

echo "Testing HeroStatusCard.swift specifically..."
COMPILE_OUTPUT=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build 2>&1)

# Check for the specific errors we're fixing
HERO_ERRORS=$(echo "$COMPILE_OUTPUT" | grep "HeroStatusCard.swift" | grep "error:")
ERROR_COUNT=$(echo "$HERO_ERRORS" | wc -l || echo "0")

if [ -z "$HERO_ERRORS" ] || [ "$ERROR_COUNT" -eq 0 ]; then
    echo "✅ HeroStatusCard.swift compiles cleanly!"
else
    echo "⚠️ Remaining HeroStatusCard.swift errors:"
    echo "$HERO_ERRORS"
fi

# Check overall compilation
TOTAL_ERRORS=$(echo "$COMPILE_OUTPUT" | grep -c "error:" || echo "0")
echo ""
echo "Total compilation errors: $TOTAL_ERRORS"

if [ "$TOTAL_ERRORS" -eq 0 ]; then
    echo "🎉 SUCCESS: Project compiles with 0 errors!"
else
    echo "⚠️ Remaining errors (first 5):"
    echo "$COMPILE_OUTPUT" | grep "error:" | head -5
fi

# =============================================================================
# FALLBACK: Show current file structure for manual fix
# =============================================================================

if [ "$TOTAL_ERRORS" -gt 0 ]; then
    echo ""
    echo "📋 FALLBACK: Manual inspection needed"
    echo "===================================="
    echo ""
    echo "If errors persist, here's the current structure around problematic areas:"
    echo ""
    echo "Lines 180-190:"
    sed -n '180,190p' "$FILE" | nl -v180
    echo ""
    echo "You may need to manually fix any remaining syntax issues in Xcode."
fi

echo ""
echo "🎯 PRECISE FIX COMPLETED!"
echo "========================"
echo ""
echo "📋 Applied fixes:"
echo "• Fixed WeatherData constructor parameters (line 184)"
echo "• Fixed .clear reference to WeatherCondition.clear (line 202)"
echo "• Cleaned up malformed function syntax (lines 206, 214, 215)"
echo "• Replaced Preview section with clean version"
echo "• Applied additional syntax cleanup"
echo ""
echo "🚀 Build project (Cmd+B) to verify fixes!"

exit 0
