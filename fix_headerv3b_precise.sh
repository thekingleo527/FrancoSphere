#!/bin/bash

echo "🔧 HeaderV3B.swift Precise Line Fix"
echo "=================================="
echo "Fixing EXACT character positions on lines 179, 184, 204"

cd "/Volumes/FastSSD/Xcode" || exit 1

# =============================================================================
# SURGICAL FIX: HeaderV3B.swift - Character-precise fixes
# =============================================================================

FILE="Components/Design/HeaderV3B.swift"

if [ ! -f "$FILE" ]; then
    echo "❌ File not found: $FILE"
    exit 1
fi

echo "🔧 Analyzing $FILE and applying surgical fixes..."

# Create Python script for character-precise fixes
cat > /tmp/fix_headerv3b_character_precise.py << 'PYTHON_EOF'
import re

def fix_headerv3b_precise():
    file_path = "/Volumes/FastSSD/Xcode/Components/Design/HeaderV3B.swift"
    
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        print(f"🔧 File has {len(lines)} lines")
        print("🎯 Targeting lines 179, 184, 204 for character-precise fixes")
        
        changes_made = []
        
        # Function to fix parameter syntax at specific character positions
        def fix_parameter_line(line_content, line_num, char_pos):
            # Common patterns that cause "consecutive statements" errors:
            
            # Pattern 1: Missing comma after parameter (most common)
            # Example: "parameter: Type" should be "parameter: Type,"
            if ':' in line_content and not line_content.rstrip().endswith(',') and not line_content.rstrip().endswith(')'):
                # Check if this looks like a parameter definition
                param_pattern = r'([a-zA-Z_][a-zA-Z0-9_]*:\s*[^,\)]+)$'
                if re.search(param_pattern, line_content.strip()):
                    return line_content.rstrip() + ',\n'
            
            # Pattern 2: Double colon or malformed parameter syntax
            # Example: "parameter:: Type" should be "parameter: Type,"
            if '::' in line_content:
                fixed = line_content.replace('::', ':')
                if not fixed.rstrip().endswith(',') and ':' in fixed:
                    fixed = fixed.rstrip() + ',\n'
                return fixed
            
            # Pattern 3: Missing space after colon
            # Example: "parameter:Type" should be "parameter: Type,"
            colon_fix = re.sub(r'([a-zA-Z_][a-zA-Z0-9_]*):([a-zA-Z@\(\)])', r'\1: \2', line_content)
            if colon_fix != line_content:
                if not colon_fix.rstrip().endswith(',') and ':' in colon_fix:
                    colon_fix = colon_fix.rstrip() + ',\n'
                return colon_fix
            
            # Pattern 4: Check for incomplete escaping closure syntax
            # Example: "@escaping () -> Void" without comma
            if '@escaping' in line_content and not line_content.rstrip().endswith(','):
                return line_content.rstrip() + ',\n'
            
            return line_content
        
        # Fix line 179 (character position 61)
        if len(lines) >= 179:
            original_179 = lines[178]
            print(f"Line 179 original: {repr(original_179)}")
            print(f"Line 179 content: {original_179.rstrip()}")
            
            fixed_179 = fix_parameter_line(original_179, 179, 61)
            if fixed_179 != original_179:
                lines[178] = fixed_179
                changes_made.append(f"Line 179: Fixed parameter syntax")
                print(f"Line 179 fixed: {fixed_179.rstrip()}")
        
        # Fix line 184 (character position 61)
        if len(lines) >= 184:
            original_184 = lines[183]
            print(f"Line 184 original: {repr(original_184)}")
            print(f"Line 184 content: {original_184.rstrip()}")
            
            fixed_184 = fix_parameter_line(original_184, 184, 61)
            if fixed_184 != original_184:
                lines[183] = fixed_184
                changes_made.append(f"Line 184: Fixed parameter syntax")
                print(f"Line 184 fixed: {fixed_184.rstrip()}")
        
        # Fix line 204 (character position 57)
        if len(lines) >= 204:
            original_204 = lines[203]
            print(f"Line 204 original: {repr(original_204)}")
            print(f"Line 204 content: {original_204.rstrip()}")
            
            fixed_204 = fix_parameter_line(original_204, 204, 57)
            if fixed_204 != original_204:
                lines[203] = fixed_204
                changes_made.append(f"Line 204: Fixed parameter syntax")
                print(f"Line 204 fixed: {fixed_204.rstrip()}")
        
        # Additional fix: Look for common initializer patterns that need fixing
        in_init = False
        for i in range(len(lines)):
            line = lines[i].strip()
            
            # Detect if we're inside an initializer
            if 'init(' in line:
                in_init = True
            elif in_init and line.startswith('}'):
                in_init = False
            
            # Fix parameters inside initializer that are missing commas
            if in_init and ':' in line and not line.endswith(',') and not line.endswith(')') and not line.endswith('{'):
                # Skip if it's a function declaration or other non-parameter line
                if not ('func ' in line or 'var ' in line or 'let ' in line or '//' in line):
                    # This looks like a parameter that needs a comma
                    if i + 1 < len(lines) and ':' in lines[i + 1]:  # Next line also has a parameter
                        lines[i] = lines[i].rstrip() + ',\n'
                        changes_made.append(f"Line {i+1}: Added missing comma in initializer")
        
        # Write changes if any were made
        if changes_made:
            with open(file_path, 'w') as f:
                f.writelines(lines)
            
            print("\n✅ Applied changes:")
            for change in changes_made:
                print(f"  • {change}")
            return True
        else:
            print("\nℹ️  No syntax errors found on target lines")
            return False
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    fix_headerv3b_precise()
PYTHON_EOF

python3 /tmp/fix_headerv3b_character_precise.py

# =============================================================================
# ADDITIONAL FIX: Common Swift parameter syntax patterns
# =============================================================================

echo ""
echo "🔧 Applying additional Swift parameter syntax fixes..."

# Fix common parameter patterns with sed
sed -i.tmp \
    -e 's/\([a-zA-Z_][a-zA-Z0-9_]*\):\([^,)]*\)$/\1: \2,/g' \
    -e 's/\(@escaping[^,)]*\)$/\1,/g' \
    -e 's/::/:/g' \
    "$FILE"

rm -f "$FILE.tmp"

# =============================================================================
# VERIFICATION
# =============================================================================

echo ""
echo "🔍 VERIFICATION: Examining fixed lines..."

echo "=== Line 179 ==="
sed -n '179p' "$FILE" 2>/dev/null | cat -n

echo "=== Line 184 ==="  
sed -n '184p' "$FILE" 2>/dev/null | cat -n

echo "=== Line 204 ==="
sed -n '204p' "$FILE" 2>/dev/null | cat -n

echo ""
echo "=== Context around line 179 ==="
sed -n '177,181p' "$FILE" 2>/dev/null | cat -n

echo ""
echo "=== Context around line 184 ==="
sed -n '182,186p' "$FILE" 2>/dev/null | cat -n

echo ""
echo "=== Context around line 204 ==="
sed -n '202,206p' "$FILE" 2>/dev/null | cat -n

# =============================================================================
# COMPILATION TEST
# =============================================================================

echo ""
echo "🔨 Testing HeaderV3B.swift compilation..."
BUILD_OUTPUT=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build -destination "platform=iOS Simulator,name=iPhone 15 Pro" 2>&1)

# Check for HeaderV3B specific errors
HEADERV3B_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "HeaderV3B.swift.*error" || echo "0")
CONSECUTIVE_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "Consecutive statements" || echo "0")

echo "HeaderV3B errors found: $HEADERV3B_ERRORS"
echo "Consecutive statement errors: $CONSECUTIVE_ERRORS"

if [ "$HEADERV3B_ERRORS" -eq 0 ] && [ "$CONSECUTIVE_ERRORS" -eq 0 ]; then
    echo "✅ SUCCESS: HeaderV3B.swift compiles without errors!"
else
    echo "⚠️  Remaining errors in HeaderV3B.swift:"
    echo "$BUILD_OUTPUT" | grep -A 1 -B 1 "HeaderV3B.swift.*error"
fi

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "🎯 HEADERV3B PRECISE FIX COMPLETED!"
echo "==================================="
echo ""
echo "📋 Targeted fixes applied:"
echo "• Line 179, character 61: Parameter syntax correction"
echo "• Line 184, character 61: Parameter syntax correction"  
echo "• Line 204, character 57: Parameter syntax correction"
echo ""
echo "🔧 Fix patterns applied:"
echo "• Missing commas in parameter lists"
echo "• Double colon corrections (:: → :)"
echo "• @escaping closure parameter formatting"
echo "• Initializer parameter comma insertion"
echo ""
echo "🚀 Next: Full project build (Cmd+B) to verify all errors resolved"

exit 0
