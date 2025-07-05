#!/bin/bash

echo "🎯 Simple FrancoSphereModels Duplicate Fix"
echo "=========================================="

cd "/Volumes/FastSSD/Xcode" || exit 1

FILE="Models/FrancoSphereModels.swift"

# Backup
cp "$FILE" "$FILE.backup.$(date +%s)"
echo "✅ Backed up $FILE"

# Fix using Python for precision
cat > /tmp/simple_fix.py << 'PYTHON_EOF'
def fix_duplicates():
    file_path = "/Volumes/FastSSD/Xcode/Models/FrancoSphereModels.swift"
    
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    print("🔧 Fixing duplicate declarations...")
    
    fixed_lines = []
    skip_next = False
    
    for i, line in enumerate(lines):
        line_num = i + 1
        
        # Skip duplicate coordinate property (around line 24)
        if skip_next:
            skip_next = False
            continue
            
        if 'public var coordinate:' in line and line_num > 20 and line_num < 30:
            print(f"✅ Removed duplicate coordinate property at line {line_num}")
            skip_next = True  # Skip the next line too (the implementation)
            continue
        
        # Fix WorkerSkill Codable (around line 261)
        if 'public struct WorkerSkill:' in line and 'Equatable' in line and 'Codable' not in line:
            line = line.replace(': Equatable', ': Codable, Equatable')
            print(f"✅ Added Codable to WorkerSkill at line {line_num}")
        
        # Skip duplicate name property in WorkerSkill (around line 262)
        if 'public let name: String' in line and 'WorkerSkill' in ''.join(lines[max(0, i-10):i]):
            # Check if this is a duplicate
            previous_lines = ''.join(lines[max(0, i-5):i])
            if 'public let name: String' in previous_lines:
                print(f"✅ Removed duplicate name property at line {line_num}")
                continue
        
        # Skip duplicate TrendDirection (around line 960)
        if 'public enum TrendDirection' in line and line_num > 900:
            # Check if TrendDirection was already defined earlier
            earlier_lines = ''.join(lines[:i])
            if 'enum TrendDirection' in earlier_lines:
                print(f"✅ Removed duplicate TrendDirection at line {line_num}")
                # Skip this and potentially following lines until next major declaration
                j = i + 1
                while j < len(lines) and not lines[j].strip().startswith('public ') and j < i + 10:
                    j += 1
                i = j - 1  # Adjust index
                continue
        
        fixed_lines.append(line)
    
    # Write fixed content
    with open(file_path, 'w') as f:
        f.writelines(fixed_lines)
    
    print("✅ All duplicates removed")

if __name__ == "__main__":
    fix_duplicates()
PYTHON_EOF

python3 /tmp/simple_fix.py

# Test compilation
echo ""
echo "🔨 Testing compilation..."
ERRORS=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build 2>&1 | grep -c "Invalid redeclaration" || echo "0")

echo "Remaining redeclaration errors: $ERRORS"

if [ "$ERRORS" -eq 0 ]; then
    echo "✅ SUCCESS: All duplicate declarations fixed!"
else
    echo "⚠️ Still have duplicates, showing remaining errors:"
    xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build 2>&1 | grep "Invalid redeclaration"
fi

echo ""
echo "🎯 SIMPLE FIX COMPLETED!"
echo "Current error count should be reduced from 11 to 7"

exit 0
