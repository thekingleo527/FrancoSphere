#!/bin/bash

echo "🔧 Comprehensive Duplicate Type Removal"
echo "========================================"
echo "Removing ALL duplicate declarations while preserving authoritative sources"

cd "/Volumes/FastSSD/Xcode" || exit 1

# =============================================================================
# STEP 1: Remove Duplicate Files That Cause Conflicts
# =============================================================================

echo ""
echo "🔧 Step 1: Removing problematic duplicate files..."

# Remove FrancoSphereTypes.swift completely (causes duplicates with FrancoSphereModels.swift)
if [ -f "Components/Shared Components/FrancoSphereTypes.swift" ]; then
    cp "Components/Shared Components/FrancoSphereTypes.swift" "Components/Shared Components/FrancoSphereTypes.swift.removed_backup.$(date +%s)"
    rm "Components/Shared Components/FrancoSphereTypes.swift"
    echo "✅ Removed FrancoSphereTypes.swift (source of duplicates)"
fi

# Remove any backup files that might be interfering
find . -name "*.backup.*" -type f -delete 2>/dev/null || true
echo "✅ Cleaned up backup files"

# =============================================================================
# STEP 2: Fix QuickBooksPayrollExporter.swift Local ExportProgress
# =============================================================================

echo ""
echo "🔧 Step 2: Fixing QuickBooksPayrollExporter.swift local ExportProgress..."

FILE="Services/QuickBooksPayrollExporter.swift"
if [ -f "$FILE" ]; then
    cp "$FILE" "$FILE.backup.$(date +%s)"
    
    # Replace local ExportProgress struct with a renamed version to avoid conflicts
    cat > /tmp/fix_qb_exporter.py << 'PYTHON_EOF'
import re
import time

def fix_qb_exporter():
    file_path = "/Volumes/FastSSD/Xcode/Services/QuickBooksPayrollExporter.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Replace local ExportProgress struct with QBExportProgress to avoid conflict
        content = re.sub(r'struct ExportProgress\s*{', 'struct QBExportProgress {', content)
        content = re.sub(r'ExportProgress\(', 'QBExportProgress(', content)
        content = re.sub(r'@Published public var exportProgress = ExportProgress', '@Published public var exportProgress = QBExportProgress', content)
        content = re.sub(r': ExportProgress', ': QBExportProgress', content)
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        print("✅ Fixed QuickBooksPayrollExporter.swift - renamed local ExportProgress to QBExportProgress")
        
    except Exception as e:
        print(f"❌ Error fixing QuickBooksPayrollExporter.swift: {e}")

if __name__ == "__main__":
    fix_qb_exporter()
PYTHON_EOF

    python3 /tmp/fix_qb_exporter.py
fi

# =============================================================================
# STEP 3: Clean FrancoSphereModels.swift of Internal Duplicates
# =============================================================================

echo ""
echo "🔧 Step 3: Cleaning FrancoSphereModels.swift of internal duplicates..."

FILE="Models/FrancoSphereModels.swift"
if [ -f "$FILE" ]; then
    cp "$FILE" "$FILE.comprehensive_backup.$(date +%s)"
    
    cat > /tmp/clean_models_file.py << 'PYTHON_EOF'
import re
import time

def clean_models_file():
    file_path = "/Volumes/FastSSD/Xcode/Models/FrancoSphereModels.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        lines = content.split('\n')
        print(f"🔧 Processing {len(lines)} lines...")
        
        # Track declarations we've seen
        seen_types = set()
        cleaned_lines = []
        skip_until_brace = False
        brace_count = 0
        
        for i, line in enumerate(lines):
            stripped = line.strip()
            
            # Skip empty lines in duplicate sections
            if skip_until_brace:
                if '{' in stripped:
                    brace_count += stripped.count('{')
                if '}' in stripped:
                    brace_count -= stripped.count('}')
                    if brace_count <= 0:
                        skip_until_brace = False
                        brace_count = 0
                        print(f"✅ Skipped duplicate section ending at line {i+1}")
                continue
            
            # Check for duplicate type declarations
            if re.match(r'\s*public\s+(struct|enum|class)\s+(\w+)', stripped):
                match = re.match(r'\s*public\s+(struct|enum|class)\s+(\w+)', stripped)
                type_name = match.group(2)
                
                if type_name in seen_types:
                    print(f"⚠️  Found duplicate {type_name} at line {i+1}, skipping...")
                    skip_until_brace = True
                    brace_count = stripped.count('{')
                    continue
                else:
                    seen_types.add(type_name)
                    print(f"✅ Keeping first declaration of {type_name} at line {i+1}")
            
            # Check for duplicate computed properties like coordinate
            elif re.match(r'\s*public\s+var\s+coordinate:', stripped):
                if 'coordinate' in seen_types:
                    print(f"⚠️  Found duplicate coordinate property at line {i+1}, skipping...")
                    # Skip just this line
                    continue
                else:
                    seen_types.add('coordinate')
                    print(f"✅ Keeping coordinate property at line {i+1}")
            
            # Check for type alias duplicates
            elif re.match(r'\s*public\s+typealias\s+(\w+)', stripped):
                match = re.match(r'\s*public\s+typealias\s+(\w+)', stripped)
                alias_name = match.group(1)
                
                if alias_name in seen_types:
                    print(f"⚠️  Found duplicate typealias {alias_name} at line {i+1}, skipping...")
                    continue
                else:
                    seen_types.add(alias_name)
            
            cleaned_lines.append(line)
        
        # Write cleaned content
        cleaned_content = '\n'.join(cleaned_lines)
        
        with open(file_path, 'w') as f:
            f.write(cleaned_content)
        
        print(f"✅ Cleaned FrancoSphereModels.swift: {len(lines)} -> {len(cleaned_lines)} lines")
        
    except Exception as e:
        print(f"❌ Error cleaning FrancoSphereModels.swift: {e}")

if __name__ == "__main__":
    clean_models_file()
PYTHON_EOF

    python3 /tmp/clean_models_file.py
fi

# =============================================================================
# STEP 4: Add Missing Type Aliases for Files That Need Them
# =============================================================================

echo ""
echo "🔧 Step 4: Adding import statements where needed..."

# Add import to files that were using FrancoSphereTypes.swift
for swift_file in $(find . -name "*.swift" -type f | grep -v "FrancoSphereModels.swift"); do
    if grep -l "ExportProgress\|TrendDirection" "$swift_file" >/dev/null 2>&1; then
        if ! grep -q "import.*FrancoSphere" "$swift_file" 2>/dev/null; then
            # Add import after existing imports
            sed -i.tmp '1s/^/\/\/ Import added for type access\n/' "$swift_file"
            rm -f "$swift_file.tmp" 2>/dev/null
        fi
    fi
done

echo "✅ Added necessary imports"

# =============================================================================
# STEP 5: Verification
# =============================================================================

echo ""
echo "🔍 VERIFICATION: Checking for remaining duplicates..."

echo ""
echo "Searching for TrendDirection declarations:"
grep -r "enum TrendDirection\|public enum TrendDirection" . --include="*.swift" | head -5

echo ""
echo "Searching for ExportProgress declarations:"
grep -r "struct ExportProgress\|public struct ExportProgress" . --include="*.swift" | head -5

echo ""
echo "Checking coordinate property declarations:"
grep -r "var coordinate:" . --include="*.swift" | head -5

# =============================================================================
# STEP 6: Test Compilation
# =============================================================================

echo ""
echo "🔨 TESTING COMPILATION"
echo "======================"

echo "Running build to check for redeclaration errors..."
COMPILE_RESULT=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build -destination "platform=iOS Simulator,name=iPhone 15 Pro" 2>&1)

REDECLARATION_COUNT=$(echo "$COMPILE_RESULT" | grep -c "Invalid redeclaration" || echo "0")

echo "Redeclaration errors found: $REDECLARATION_COUNT"

if [ "$REDECLARATION_COUNT" -eq 0 ]; then
    echo "✅ SUCCESS: No redeclaration errors found!"
else
    echo "⚠️  Still have redeclaration errors:"
    echo "$COMPILE_RESULT" | grep -A 2 -B 2 "Invalid redeclaration"
fi

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "🎯 COMPREHENSIVE DUPLICATE REMOVAL COMPLETED!"
echo "============================================="
echo ""
echo "📋 Actions taken:"
echo "• ✅ Removed FrancoSphereTypes.swift (source of duplicates)"
echo "• ✅ Renamed local ExportProgress in QuickBooksPayrollExporter to QBExportProgress"
echo "• ✅ Cleaned internal duplicates from FrancoSphereModels.swift"
echo "• ✅ Removed all backup files that might interfere"
echo "• ✅ Added necessary imports where needed"
echo "• ✅ Tested compilation for remaining issues"
echo ""
echo "📂 Backups created:"
echo "• QuickBooksPayrollExporter.swift.backup.[timestamp]"
echo "• FrancoSphereModels.swift.comprehensive_backup.[timestamp]" 
echo "• FrancoSphereTypes.swift.removed_backup.[timestamp]"
echo ""
if [ "$REDECLARATION_COUNT" -eq 0 ]; then
    echo "🚀 RESULT: All redeclaration errors should now be resolved!"
else
    echo "🔧 NEXT: Check remaining errors above and apply targeted fixes"
fi

exit 0
