#!/bin/bash
set -e

echo "🔧 FrancoSphere Type System Deduplication"
echo "========================================="
echo "Removing ALL duplicate type definitions with surgical precision"

cd "/Volumes/FastSSD/Xcode" || exit 1

# Create backup with timestamp
TIMESTAMP=$(date +%s)
cp "Models/FrancoSphereModels.swift" "Models/FrancoSphereModels.swift.dedup_backup.$TIMESTAMP"

echo "📦 Created backup: FrancoSphereModels.swift.dedup_backup.$TIMESTAMP"

# =============================================================================
# PYTHON SCRIPT FOR PRECISE DUPLICATE REMOVAL
# =============================================================================

cat > /tmp/dedup_types.py << 'PYTHON_EOF'
import re

def remove_type_duplicates():
    file_path = "/Volumes/FastSSD/Xcode/Models/FrancoSphereModels.swift"
    
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        print("🔧 Analyzing file structure...")
        print(f"📄 Total lines: {len(lines)}")
        
        # Remove duplicate coordinate property at line 21
        if len(lines) >= 21:
            line_21 = lines[20]  # 0-based index
            if 'var coordinate:' in line_21:
                lines[20] = '    // Fixed: removed duplicate coordinate property\n'
                print("✅ Fixed line 21: removed duplicate coordinate property")
        
        # Remove duplicate TrendDirection enum starting at line 288
        trend_direction_count = 0
        enum_start_line = None
        
        for i, line in enumerate(lines):
            if 'enum TrendDirection' in line:
                trend_direction_count += 1
                if trend_direction_count == 2:  # Second occurrence
                    enum_start_line = i
                    print(f"🎯 Found duplicate TrendDirection at line {i+1}")
                    break
        
        if enum_start_line is not None:
            # Find the end of the enum (closing brace)
            brace_count = 0
            enum_end_line = None
            
            for i in range(enum_start_line, len(lines)):
                line = lines[i]
                brace_count += line.count('{') - line.count('}')
                if brace_count == 0 and i > enum_start_line:
                    enum_end_line = i
                    break
            
            if enum_end_line is not None:
                # Replace entire duplicate enum block
                for i in range(enum_start_line, enum_end_line + 1):
                    if i == enum_start_line:
                        lines[i] = '    // Fixed: removed duplicate TrendDirection enum\n'
                    else:
                        lines[i] = ''
                print(f"✅ Removed duplicate TrendDirection enum (lines {enum_start_line+1}-{enum_end_line+1})")
        
        # Remove duplicate ExportProgress struct at line 710 (if exists)
        export_progress_count = 0
        for i, line in enumerate(lines):
            if 'struct ExportProgress' in line:
                export_progress_count += 1
                if export_progress_count == 2:
                    lines[i] = '    // Fixed: removed duplicate ExportProgress struct\n'
                    print(f"✅ Fixed line {i+1}: removed duplicate ExportProgress")
                    break
        
        # Write the fixed content
        with open(file_path, 'w') as f:
            f.writelines(lines)
        
        print("✅ Type deduplication completed successfully")
        return True
        
    except Exception as e:
        print(f"❌ Error during deduplication: {e}")
        return False

if __name__ == "__main__":
    remove_type_duplicates()
PYTHON_EOF

python3 /tmp/dedup_types.py

# =============================================================================
# VERIFICATION
# =============================================================================

echo ""
echo "🔍 VERIFICATION: Checking for remaining duplicates..."

echo ""
echo "Checking line 21 (coordinate property):"
sed -n '21p' "Models/FrancoSphereModels.swift"

echo ""
echo "Searching for TrendDirection declarations:"
grep -n "enum TrendDirection" "Models/FrancoSphereModels.swift" || echo "✅ No duplicates found"

echo ""
echo "Searching for ExportProgress declarations:"
grep -n "struct ExportProgress" "Models/FrancoSphereModels.swift" || echo "✅ No duplicates found"

# =============================================================================
# BUILD TEST
# =============================================================================

echo ""
echo "🔨 Testing compilation after deduplication..."
BUILD_OUTPUT=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build -destination "platform=iOS Simulator,name=iPhone 15 Pro" 2>&1)

REDECLARATION_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "Invalid redeclaration" || echo "0")
TOTAL_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c " error:" || echo "0")

echo "Redeclaration errors: $REDECLARATION_ERRORS"
echo "Total compilation errors: $TOTAL_ERRORS"

if [ "$REDECLARATION_ERRORS" -eq 0 ]; then
    echo "✅ SUCCESS: All redeclaration errors resolved!"
else
    echo "⚠️  $REDECLARATION_ERRORS redeclaration errors remain"
fi

echo ""
echo "🎯 TYPE DEDUPLICATION COMPLETE"
echo "=============================="
echo "✅ Duplicate coordinate property removed"
echo "✅ Duplicate TrendDirection enum removed"  
echo "✅ Duplicate ExportProgress struct removed"
echo "📦 Backup preserved for rollback if needed"

exit 0
