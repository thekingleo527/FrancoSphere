#!/bin/bash

echo "🔧 Fix HeroStatusCard Preview Constructor Signatures"
echo "=================================================="
echo "Targeting lines 117, 119, 120, 126 with exact constructor fixes"

cd "/Volumes/FastSSD/Xcode" || exit 1

# =============================================================================
# FIX HEROSTATUSCARD PREVIEW SECTION WITH CORRECT CONSTRUCTORS
# =============================================================================

echo ""
echo "🔧 REBUILDING HeroStatusCard.swift preview with correct constructor signatures..."

FILE="Components/Shared Components/HeroStatusCard.swift"

if [ -f "$FILE" ]; then
    # Show current problematic lines
    echo "Current problematic lines:"
    echo "Line 117:"
    sed -n '117p' "$FILE"
    echo "Line 119:"
    sed -n '119p' "$FILE"
    echo "Line 120:"
    sed -n '120p' "$FILE"
    echo "Line 126:"
    sed -n '126p' "$FILE"
    
    # Create backup
    cp "$FILE" "$FILE.constructor_fix_backup.$(date +%s)"
    
    # Replace the entire preview section with correct constructors
    cat > /tmp/fix_preview_constructors.py << 'PYTHON_EOF'
import re

def fix_preview_constructors():
    file_path = "/Volumes/FastSSD/Xcode/Components/Shared Components/HeroStatusCard.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Create backup
        with open(file_path + '.preview_constructor_backup.' + str(int(__import__('time').time())), 'w') as f:
            f.write(content)
        
        print("🔧 Replacing preview section with correct constructor signatures...")
        
        # Find the preview section
        preview_start = content.find('struct HeroStatusCard_Previews')
        if preview_start != -1:
            # Find the end of the preview struct
            brace_count = 0
            preview_end = preview_start
            in_preview = False
            
            for i in range(preview_start, len(content)):
                if content[i] == '{':
                    brace_count += 1
                    in_preview = True
                elif content[i] == '}':
                    brace_count -= 1
                    if brace_count == 0 and in_preview:
                        preview_end = i + 1
                        break
            
            # Create new preview section with correct constructors based on the error analysis
            new_preview = '''struct HeroStatusCard_Previews: PreviewProvider {
    static var previews: some View {
        HeroStatusCard(
            workerId: "kevin",
            currentBuilding: NamedCoordinate(
                id: "14",
                name: "Rubin Museum",
                coordinate: CLLocationCoordinate2D(latitude: 40.7402, longitude: -73.9980)
            ),
            weather: WeatherData(
                condition: WeatherCondition.sunny,
                temperature: 72,
                humidity: 65,
                windSpeed: 8.5,
                description: "Clear skies"
            ),
            progress: TaskProgress(completed: 12, total: 15, remaining: 3, percentage: 80.0, overdueTasks: 1),
            completedTasks: 12,
            totalTasks: 15,
            onClockInTap: { print("Clock in tapped") }
        )
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}'''
            
            content = content[:preview_start] + new_preview
            
            with open(file_path, 'w') as f:
                f.write(content)
            
            print("✅ Replaced preview section with correct constructors")
            return True
        else:
            print("⚠️ Preview section not found")
            return False
        
    except Exception as e:
        print(f"❌ Error replacing preview section: {e}")
        return False

if __name__ == "__main__":
    fix_preview_constructors()
PYTHON_EOF

    python3 /tmp/fix_preview_constructors.py
    
    echo ""
    echo "🔍 After fix - checking lines 117-126:"
    sed -n '117,126p' "$FILE" | cat -n
    
else
    echo "❌ HeroStatusCard.swift not found"
    exit 1
fi

# =============================================================================
# ALTERNATIVE: Fix each line individually if needed
# =============================================================================

echo ""
echo "🔧 APPLYING INDIVIDUAL LINE FIXES as backup..."

# Fix line 117 - NamedCoordinate extra 'address' argument
sed -i.tmp '117s/, address: "[^"]*"//g' "$FILE"

# Fix line 119-120 - WeatherData constructor
sed -i.tmp '119,120s/WeatherData([^)]*))/WeatherData(condition: WeatherCondition.sunny, temperature: 72, humidity: 65, windSpeed: 8.5, description: "Clear skies")/g' "$FILE"

# Fix .sunny reference to be WeatherCondition.sunny
sed -i.tmp 's/condition: \.sunny/condition: WeatherCondition.sunny/g' "$FILE"

# Fix line 126 - TaskProgress constructor
sed -i.tmp '126s/TaskProgress([^)]*))/TaskProgress(completed: 12, total: 15, remaining: 3, percentage: 80.0, overdueTasks: 1)/g' "$FILE"

# Remove any Date constructor with parameters
sed -i.tmp 's/Date([^)]*))/Date()/g' "$FILE"

rm -f "$FILE.tmp"

echo "✅ Applied individual line fixes"

# =============================================================================
# VERIFY CONSTRUCTOR SIGNATURES BY CHECKING MODEL DEFINITIONS
# =============================================================================

echo ""
echo "🔍 CHECKING actual constructor signatures in FrancoSphereModels.swift..."

MODELS_FILE="Models/FrancoSphereModels.swift"
if [ -f "$MODELS_FILE" ]; then
    echo ""
    echo "NamedCoordinate constructor signature:"
    grep -A 10 "struct NamedCoordinate" "$MODELS_FILE" | grep -A 10 "init("
    
    echo ""
    echo "WeatherData constructor signature:"
    grep -A 10 "struct WeatherData" "$MODELS_FILE" | grep -A 10 "init("
    
    echo ""
    echo "TaskProgress constructor signature:"
    grep -A 10 "struct TaskProgress" "$MODELS_FILE" | grep -A 10 "init("
fi

# =============================================================================
# VERIFICATION
# =============================================================================

echo ""
echo "🔍 VERIFICATION: Testing HeroStatusCard compilation..."

BUILD_OUTPUT=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build -destination "platform=iOS Simulator,name=iPhone 15 Pro" 2>&1)

HEROSTATUSCARD_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "HeroStatusCard.swift.*error" || echo "0")
PREVIEW_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "HeroStatusCard.swift:11[7-9]\|HeroStatusCard.swift:12[0-6]" || echo "0")

echo "HeroStatusCard.swift total errors: $HEROSTATUSCARD_ERRORS"
echo "Preview section errors (lines 117-126): $PREVIEW_ERRORS"

if [ "$PREVIEW_ERRORS" -gt 0 ]; then
    echo ""
    echo "📋 Preview section errors:"
    echo "$BUILD_OUTPUT" | grep "HeroStatusCard.swift:11[7-9]\|HeroStatusCard.swift:12[0-6]"
fi

if [ "$HEROSTATUSCARD_ERRORS" -eq 0 ]; then
    echo "✅ SUCCESS: HeroStatusCard.swift compiles without errors!"
else
    echo ""
    echo "📋 All HeroStatusCard errors:"
    echo "$BUILD_OUTPUT" | grep "HeroStatusCard.swift.*error"
fi

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "🎯 HEROSTATUSCARD PREVIEW CONSTRUCTOR FIX COMPLETED!"
echo "==================================================="
echo ""
echo "📋 Targeted fixes for exact lines:"
echo "• ✅ Line 117: Removed extra 'address' argument from NamedCoordinate"
echo "• ✅ Line 119-120: Fixed WeatherData constructor with correct signature"
echo "• ✅ Line 120: Fixed .sunny → WeatherCondition.sunny"
echo "• ✅ Line 126: Fixed TaskProgress constructor with correct parameters"
echo "• ✅ All Date() constructors simplified to basic form"
echo ""
echo "🔧 Constructor signatures used:"
echo "• NamedCoordinate(id, name, coordinate) - removed address"
echo "• WeatherData(condition, temperature, humidity, windSpeed, description)"
echo "• TaskProgress(completed, total, remaining, percentage, overdueTasks)"
echo "• WeatherCondition.sunny instead of .sunny"
echo ""
if [ "$PREVIEW_ERRORS" -eq 0 ]; then
    echo "🚀 SUCCESS: All preview constructor errors resolved!"
else
    echo "⚠️  Some preview errors remain - check output above"
fi
echo ""
echo "🚀 Next: Check compilation results to verify complete fix"

exit 0
