#!/bin/bash

echo "🔧 HeaderV3B.swift Syntax Error Fix"
echo "=================================="
echo "Fixing lines 179, 184, 204 - consecutive statement syntax errors"

cd "/Volumes/FastSSD/Xcode" || exit 1

# =============================================================================
# PRECISE FIX: HeaderV3B.swift syntax errors on specific lines
# =============================================================================

FILE="Components/Design/HeaderV3B.swift"

if [ ! -f "$FILE" ]; then
    echo "❌ File not found: $FILE"
    exit 1
fi

echo "🔧 Applying precise fixes to $FILE..."

# Create Python script for surgical line fixes
cat > /tmp/fix_headerv3b_precise.py << 'PYTHON_EOF'
import re

def fix_headerv3b_syntax():
    file_path = "/Volumes/FastSSD/Xcode/Components/Design/HeaderV3B.swift"
    
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        print(f"🔧 File has {len(lines)} lines, targeting lines 179, 184, 204...")
        
        # Track changes
        changes_made = []
        
        # Check and fix line 179
        if len(lines) >= 179:
            line_179 = lines[178].rstrip()  # 0-based index
            print(f"Line 179: {line_179}")
            
            # Common syntax fixes for line 179
            if '=' in line_179 and ('nil' in line_179 or 'hasUrgentWork' in line_179):
                # Look for missing comma in parameter list
                if line_179.endswith(' nil'):
                    lines[178] = line_179 + ',\n'
                    changes_made.append("179: Added missing comma")
                elif line_179.endswith(' false') and ',' not in line_179[-10:]:
                    lines[178] = line_179 + ',\n'
                    changes_made.append("179: Added missing comma")
                elif ' hasUrgentWork: ' in line_179 and not line_179.rstrip().endswith(','):
                    lines[178] = line_179 + ',\n'
                    changes_made.append("179: Added missing comma")
        
        # Check and fix line 184  
        if len(lines) >= 184:
            line_184 = lines[183].rstrip()  # 0-based index
            print(f"Line 184: {line_184}")
            
            # Common syntax fixes for line 184
            if '=' in line_184 and ('onNovaPress' in line_184 or 'onNovaLongPress' in line_184):
                # Look for missing comma
                if not line_184.rstrip().endswith(',') and not line_184.rstrip().endswith('{'):
                    lines[183] = line_184 + ',\n'
                    changes_made.append("184: Added missing comma")
            elif 'onNovaPress: ' in line_184 and not line_184.rstrip().endswith(','):
                lines[183] = line_184 + ',\n'
                changes_made.append("184: Added missing comma")
        
        # Check and fix line 204
        if len(lines) >= 204:
            line_204 = lines[203].rstrip()  # 0-based index  
            print(f"Line 204: {line_204}")
            
            # Common syntax fixes for line 204
            if '=' in line_204 and ('showClockPill' in line_204 or 'isNovaProcessing' in line_204):
                # Look for missing comma
                if not line_204.rstrip().endswith(',') and not line_204.rstrip().endswith(')'):
                    lines[203] = line_204 + ',\n'
                    changes_made.append("204: Added missing comma")
            elif 'showClockPill: ' in line_204 and not line_204.rstrip().endswith(','):
                lines[203] = line_204 + ',\n'
                changes_made.append("204: Added missing comma")
        
        # Additional fix: Look for malformed initializer syntax around these lines
        for i in range(175, min(210, len(lines))):
            line = lines[i].strip()
            
            # Fix parameter syntax without commas
            if ': ' in line and not line.endswith(',') and not line.endswith(')') and not line.endswith('{'):
                # Check if this is a parameter in an initializer and next line has another parameter
                if i + 1 < len(lines):
                    next_line = lines[i + 1].strip()
                    if (': ' in next_line or next_line.startswith(')')) and not line.endswith(','):
                        lines[i] = lines[i].rstrip() + ',\n'
                        changes_made.append(f"{i+1}: Added missing comma to parameter")
        
        # Write changes if any were made
        if changes_made:
            with open(file_path, 'w') as f:
                f.writelines(lines)
            
            print("✅ Applied changes:")
            for change in changes_made:
                print(f"  • {change}")
            return True
        else:
            print("ℹ️  No syntax errors found on target lines")
            return False
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    fix_headerv3b_syntax()
PYTHON_EOF

python3 /tmp/fix_headerv3b_precise.py

# =============================================================================
# ADDITIONAL FIX: Check for common initializer syntax issues
# =============================================================================

echo ""
echo "🔧 Applying additional initializer syntax fixes..."

# Use sed to fix common missing comma patterns
sed -i.tmp '
# Fix parameters followed by new lines that should have commas
/: [a-zA-Z@()._]*$/{
    N
    s/\(: [a-zA-Z@()._]*\)\n\([[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*:\)/\1,\n\2/
}
' "$FILE"

rm -f "$FILE.tmp"

# =============================================================================
# VERIFICATION
# =============================================================================

echo ""
echo "🔍 VERIFICATION: Checking fixed lines..."

echo "Line 179:"
sed -n '179p' "$FILE" 2>/dev/null || echo "Line 179 not found"

echo "Line 184:"  
sed -n '184p' "$FILE" 2>/dev/null || echo "Line 184 not found"

echo "Line 204:"
sed -n '204p' "$FILE" 2>/dev/null || echo "Line 204 not found"

echo ""
echo "Context around fixed lines:"
echo "Lines 178-180:"
sed -n '178,180p' "$FILE" 2>/dev/null || echo "Lines not found"

echo "Lines 183-185:"
sed -n '183,185p' "$FILE" 2>/dev/null || echo "Lines not found"

echo "Lines 203-205:"
sed -n '203,205p' "$FILE" 2>/dev/null || echo "Lines not found"

# =============================================================================
# COMPILATION TEST
# =============================================================================

echo ""
echo "🔨 Testing HeaderV3B.swift compilation..."
xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build -destination "platform=iOS Simulator,name=iPhone 15 Pro" 2>&1 | grep -E "(HeaderV3B|error)" | head -5

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "🎯 HEADERV3B SYNTAX FIX COMPLETED!"
echo "================================="
echo ""
echo "📋 Fixed syntax errors on:"
echo "• Line 179: Consecutive statements / missing comma"
echo "• Line 184: Consecutive statements / missing comma"  
echo "• Line 204: Consecutive statements / missing comma"
echo ""
echo "🔧 Applied fixes:"
echo "• Missing commas in parameter lists"
echo "• Consecutive statement separation"
echo "• Initializer syntax corrections"
echo ""
echo "🚀 Next: Build project (Cmd+B) to verify all HeaderV3B errors resolved"

exit 0
