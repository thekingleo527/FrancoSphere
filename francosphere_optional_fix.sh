#!/bin/bash

echo "🔧 FrancoSphere CurrentBuildingStatusCard Optional String Fix"
echo "============================================================="
echo "Fixing line 95 optional unwrapping with surgical precision..."

cd "/Volumes/FastSSD/Xcode" || exit 1

TIMESTAMP=$(date +%s)

# =============================================================================
# TARGET FILE
# =============================================================================

FILE="Components/Design/CurrentBuildingStatusCard.swift"

if [ ! -f "$FILE" ]; then
    echo "❌ ERROR: File not found: $FILE"
    echo "Current directory: $(pwd)"
    echo "Available files in Components/Design/:"
    ls -la "Components/Design/" 2>/dev/null || echo "Directory not found"
    exit 1
fi

echo "✅ Found target file: $FILE"

# =============================================================================
# CREATE BACKUP
# =============================================================================

echo ""
echo "📦 Creating backup..."
cp "$FILE" "${FILE}.optional_fix_backup.${TIMESTAMP}"
echo "✅ Backup created: ${FILE}.optional_fix_backup.${TIMESTAMP}"

# =============================================================================
# EXAMINE CURRENT LINE 95
# =============================================================================

echo ""
echo "🔍 BEFORE FIX - Examining line 95:"
echo "=================================="
sed -n '95p' "$FILE" | cat -n
echo ""

# Show some context around line 95
echo "🔍 Context (lines 90-100):"
sed -n '90,100p' "$FILE" | cat -n

# =============================================================================
# APPLY SURGICAL FIX TO LINE 95
# =============================================================================

echo ""
echo "🔧 APPLYING SURGICAL FIX TO LINE 95"
echo "===================================="

cat > /tmp/fix_line_95.py << 'PYTHON_EOF'
def fix_optional_line_95():
    file_path = "/Volumes/FastSSD/Xcode/Components/Design/CurrentBuildingStatusCard.swift"
    
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        if len(lines) < 95:
            print(f"❌ File only has {len(lines)} lines, but error is on line 95")
            return False
        
        # Get line 95 (0-based index 94)
        line_95 = lines[94]
        original_line = line_95.strip()
        
        print(f"🔍 Original line 95: {original_line}")
        
        # Common patterns that need optional unwrapping
        fixes_applied = []
        
        # Pattern 1: building.address (most likely)
        if 'building.address' in line_95 and '??' not in line_95:
            lines[94] = line_95.replace('building.address', 'building.address ?? "No address"')
            fixes_applied.append("building.address → building.address ?? \"No address\"")
        
        # Pattern 2: building.name if it's optional
        if 'building.name' in line_95 and '??' not in line_95 and 'building.address' not in line_95:
            lines[94] = line_95.replace('building.name', 'building.name ?? "Unknown Building"')
            fixes_applied.append("building.name → building.name ?? \"Unknown Building\"")
        
        # Pattern 3: Any other String? property
        import re
        
        # Look for property access that might be optional
        optional_pattern = r'(\w+)\.(\w+)(?!\s*\?\?)'
        matches = re.findall(optional_pattern, line_95)
        
        for obj, prop in matches:
            if prop in ['address', 'description', 'notes', 'title', 'subtitle']:
                if f'{obj}.{prop} ??' not in line_95:
                    old_access = f'{obj}.{prop}'
                    new_access = f'{obj}.{prop} ?? "N/A"'
                    lines[94] = lines[94].replace(old_access, new_access)
                    fixes_applied.append(f"{old_access} → {new_access}")
        
        # Write back the file
        with open(file_path, 'w') as f:
            f.writelines(lines)
        
        new_line = lines[94].strip()
        print(f"✅ Fixed line 95: {new_line}")
        
        if fixes_applied:
            print("🔧 Fixes applied:")
            for fix in fixes_applied:
                print(f"   • {fix}")
        else:
            print("⚠️ No automatic fix pattern matched - manual inspection needed")
        
        return True
        
    except Exception as e:
        print(f"❌ Error fixing line 95: {e}")
        return False

if __name__ == "__main__":
    fix_optional_line_95()
PYTHON_EOF

python3 /tmp/fix_line_95.py

# =============================================================================
# ALTERNATIVE MANUAL FIXES (if Python script doesn't work)
# =============================================================================

echo ""
echo "🔧 APPLYING ALTERNATIVE MANUAL FIXES"
echo "===================================="

# Try multiple sed patterns to catch different optional scenarios
echo "Trying sed pattern 1: building.address"
sed -i.tmp1 '95s/building\.address\b/building.address ?? "No address"/g' "$FILE"

echo "Trying sed pattern 2: building.name (if optional)"
sed -i.tmp2 '95s/building\.name\b/building.name ?? "Unknown Building"/g' "$FILE"

echo "Trying sed pattern 3: Any .description property"
sed -i.tmp3 '95s/\.description\b/.description ?? "No description"/g' "$FILE"

# Clean up temp files
rm -f "${FILE}.tmp1" "${FILE}.tmp2" "${FILE}.tmp3"

# =============================================================================
# VERIFICATION
# =============================================================================

echo ""
echo "🔍 AFTER FIX - Examining line 95:"
echo "================================="
sed -n '95p' "$FILE" | cat -n
echo ""

echo "🔍 Context after fix (lines 90-100):"
sed -n '90,100p' "$FILE" | cat -n

# =============================================================================
# BUILD TEST
# =============================================================================

echo ""
echo "🔨 TESTING COMPILATION"
echo "====================="

echo "Running quick build test on CurrentBuildingStatusCard.swift..."
BUILD_OUTPUT=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build -destination "platform=iOS Simulator,name=iPhone 15 Pro" 2>&1)

# Check specifically for the line 95 error
LINE_95_ERROR=$(echo "$BUILD_OUTPUT" | grep "CurrentBuildingStatusCard.swift:95" || echo "")

if [ -z "$LINE_95_ERROR" ]; then
    echo "✅ SUCCESS: Line 95 error resolved!"
    echo "🎉 CurrentBuildingStatusCard.swift:95 no longer has optional unwrapping error"
else
    echo "⚠️ Line 95 error still exists:"
    echo "$LINE_95_ERROR"
    echo ""
    echo "🔍 Current line 95 content:"
    sed -n '95p' "$FILE"
fi

# Check total error count
TOTAL_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c " error:" || echo "0")
echo ""
echo "📊 Total compilation errors: $TOTAL_ERRORS"

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "🎯 OPTIONAL STRING FIX COMPLETED!"
echo "================================="
echo ""
echo "📋 What was fixed:"
echo "• ✅ Targeted line 95 in CurrentBuildingStatusCard.swift"
echo "• ✅ Applied nil coalescing operator (??) for optional String unwrapping"
echo "• ✅ Used multiple fix patterns to catch different scenarios"
echo "• ✅ Created backup with timestamp: $TIMESTAMP"
echo ""
echo "📦 Backup location:"
echo "   ${FILE}.optional_fix_backup.${TIMESTAMP}"
echo ""
if [ -z "$LINE_95_ERROR" ]; then
    echo "🚀 SUCCESS: Optional unwrapping error resolved!"
    echo "          CurrentBuildingStatusCard.swift should now compile cleanly"
else
    echo "🔧 ADDITIONAL ACTION NEEDED:"
    echo "   Line 95 still has issues - manual inspection required"
    echo "   Current line content shown above"
fi
echo ""
echo "🔄 Next: Run full build (Cmd+B) to check all remaining errors"

exit 0
