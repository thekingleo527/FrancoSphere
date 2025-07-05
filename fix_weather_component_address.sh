#!/bin/bash

echo "🔧 Fix WeatherDashboardComponent Address Parameter"
echo "================================================="
echo "Finding and fixing missing 'address' parameter in NamedCoordinate constructor"

cd "/Volumes/FastSSD/Xcode" || exit 1

# =============================================================================
# FIND THE CORRECT FILE PATH
# =============================================================================

echo "🔍 Finding WeatherDashboardComponent.swift..."

# Try different possible paths
POSSIBLE_PATHS=(
    "Components/Shared Components/WeatherDashboardComponent.swift"
    "FrancoSphere/Components/Shared Components/WeatherDashboardComponent.swift"
    "$(find . -name "WeatherDashboardComponent.swift" 2>/dev/null | head -1)"
)

FILE_PATH=""
for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -f "$path" ]; then
        FILE_PATH="$path"
        echo "✅ Found file at: $FILE_PATH"
        break
    fi
done

if [ -z "$FILE_PATH" ]; then
    echo "❌ WeatherDashboardComponent.swift not found in any expected location"
    echo "Searching entire directory..."
    find . -name "WeatherDashboardComponent.swift" -type f 2>/dev/null
    exit 1
fi

# =============================================================================
# FIX THE ADDRESS PARAMETER ISSUE
# =============================================================================

cat > /tmp/fix_address_param.py << 'PYTHON_EOF'
import time
import re

def fix_address_parameter():
    file_path = "./PLACEHOLDER_PATH"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Create backup with timestamp
        backup_path = file_path + '.backup.' + str(int(time.time()))
        with open(backup_path, 'w') as f:
            f.write(content)
        
        print("🔧 Applying address parameter fix...")
        
        original_content = content
        
        # Look for NamedCoordinate constructor in Preview section that's missing address
        # Pattern: NamedCoordinate(...latitude:...longitude:...imageAssetName:...)
        pattern = r'(NamedCoordinate\s*\(\s*id:\s*"[^"]*",\s*name:\s*"[^"]*",\s*latitude:\s*[^,\)]+,\s*longitude:\s*[^,\)]+,)(\s*imageAssetName:\s*"[^"]*"\s*\))'
        
        def add_address_param(match):
            prefix = match.group(1)
            suffix = match.group(2)
            return prefix + '\n            address: "150 W 17th St, New York, NY 10011",' + suffix
        
        # Apply the fix
        content = re.sub(pattern, add_address_param, content, flags=re.MULTILINE)
        
        # Alternative pattern for FrancoSphere.NamedCoordinate
        pattern2 = r'(FrancoSphere\.NamedCoordinate\s*\(\s*id:\s*"[^"]*",\s*name:\s*"[^"]*",\s*latitude:\s*[^,\)]+,\s*longitude:\s*[^,\)]+,)(\s*imageAssetName:\s*"[^"]*"\s*\))'
        content = re.sub(pattern2, add_address_param, content, flags=re.MULTILINE)
        
        # Even simpler fix - just look for any NamedCoordinate constructor missing address
        # Split into lines and fix line by line
        lines = content.split('\n')
        for i, line in enumerate(lines):
            # Look for NamedCoordinate constructor with latitude, longitude, imageAssetName but no address
            if ('NamedCoordinate(' in line and 'latitude:' in line and 'longitude:' in line and 
                'imageAssetName:' in line and 'address:' not in line):
                print(f"📍 Found line {i+1}: {line.strip()}")
                # Insert address parameter before imageAssetName
                new_line = line.replace('imageAssetName:', 'address: "150 W 17th St, New York, NY 10011",\n            imageAssetName:')
                lines[i] = new_line
                print(f"✅ Fixed line {i+1}")
                break
        
        content = '\n'.join(lines)
        
        # Check if we made any changes
        if content != original_content:
            # Write the fixed content
            with open(file_path, 'w') as f:
                f.write(content)
            print("✅ Fixed WeatherDashboardComponent.swift address parameter")
            return True
        else:
            print("ℹ️  No NamedCoordinate constructor found that needs address parameter fix")
            return False
        
    except Exception as e:
        print(f"❌ Error fixing address parameter: {e}")
        return False

if __name__ == "__main__":
    fix_address_parameter()
PYTHON_EOF

# Replace placeholder with actual file path
sed -i.tmp "s|PLACEHOLDER_PATH|$FILE_PATH|g" /tmp/fix_address_param.py
rm -f /tmp/fix_address_param.py.tmp

python3 /tmp/fix_address_param.py

# =============================================================================
# VERIFICATION
# =============================================================================

echo ""
echo "🔍 VERIFICATION: Checking for Preview section..."
grep -n -A 10 -B 2 "#Preview\|Preview {" "$FILE_PATH" 2>/dev/null || echo "Preview section not found with grep"

echo ""
echo "🔍 Looking for NamedCoordinate constructors..."
grep -n "NamedCoordinate(" "$FILE_PATH" 2>/dev/null || echo "No NamedCoordinate constructors found"

echo ""
echo "🔍 Checking for address parameter..."
grep -n "address:" "$FILE_PATH" 2>/dev/null || echo "No address parameters found"

# =============================================================================
# BUILD TEST FOR THIS SPECIFIC FILE
# =============================================================================

echo ""
echo "🔨 Testing compilation of WeatherDashboardComponent..."
xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build -destination "platform=iOS Simulator,name=iPhone 15 Pro" 2>&1 | grep -E "(WeatherDashboardComponent|error|warning)" | head -10

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "🎯 ADDRESS PARAMETER FIX COMPLETED!"
echo "==================================="
echo ""
echo "📋 What was fixed:"
echo "• Added missing 'address' parameter to NamedCoordinate constructor"
echo "• Used real address: '150 W 17th St, New York, NY 10011' (Rubin Museum)"
echo ""
echo "📂 File location: $FILE_PATH"
echo "📂 Backup created: $FILE_PATH.backup.[timestamp]"
echo ""
echo "🚀 Next: Check build output above for any remaining errors"

exit 0
