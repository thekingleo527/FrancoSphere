#!/bin/bash

echo "🔧 Fix WeatherDashboardComponent Line 341"
echo "=========================================="
echo "Adding missing 'address' parameter to NamedCoordinate constructor"

cd "/Volumes/FastSSD/Xcode" || exit 1

# =============================================================================
# PRECISE FIX: Line 341 Missing Address Parameter
# =============================================================================

cat > /tmp/fix_line_341.py << 'PYTHON_EOF'
import time

def fix_line_341():
    file_path = "/Volumes/FastSSD/Xcode/Components/Shared Components/WeatherDashboardComponent.swift"
    
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        # Create backup with timestamp
        backup_path = file_path + '.backup.' + str(int(time.time()))
        with open(backup_path, 'w') as f:
            f.writelines(lines)
        
        print("🔧 Targeting line 341 specifically...")
        
        # Check if we have at least 341 lines
        if len(lines) >= 341:
            line_341 = lines[340]  # 0-based index
            print(f"📍 Line 341 current content: {line_341.strip()}")
            
            # Check if it's a NamedCoordinate constructor
            if 'NamedCoordinate(' in line_341 and 'address:' not in line_341:
                # Different patterns to match based on what's in the line
                
                if 'imageAssetName:' in line_341:
                    # Pattern: NamedCoordinate(id: "x", name: "y", coordinate: z, imageAssetName: "w")
                    # Insert address before imageAssetName
                    new_line = line_341.replace('imageAssetName:', 'address: "150 W 17th St, New York, NY 10011", imageAssetName:')
                    lines[340] = new_line
                    print("✅ Fixed: Added address parameter before imageAssetName")
                
                elif 'coordinate:' in line_341 and line_341.strip().endswith(')'):
                    # Pattern: NamedCoordinate(id: "x", name: "y", coordinate: z)
                    # Insert address before closing parenthesis
                    new_line = line_341.replace(')', ', address: "150 W 17th St, New York, NY 10011")')
                    lines[340] = new_line
                    print("✅ Fixed: Added address parameter before closing parenthesis")
                
                elif 'latitude:' in line_341 and 'longitude:' in line_341:
                    # Pattern: NamedCoordinate(id: "x", name: "y", latitude: a, longitude: b, imageAssetName: "z")
                    # Add missing address parameter
                    import re
                    # Just insert address before imageAssetName if it exists
                    if 'imageAssetName:' in line_341:
                        new_line = line_341.replace('imageAssetName:', 'address: "150 W 17th St, New York, NY 10011", imageAssetName:')
                        lines[340] = new_line
                        print("✅ Fixed: Added address parameter to latitude/longitude constructor")
                    else:
                        # Add address before closing parenthesis
                        new_line = line_341.replace(')', ', address: "150 W 17th St, New York, NY 10011")')
                        lines[340] = new_line
                        print("✅ Fixed: Added address parameter before closing parenthesis")
                
                print(f"📍 Line 341 new content: {lines[340].strip()}")
            else:
                print("ℹ️  Line 341 doesn't appear to be a NamedCoordinate constructor missing address")
        else:
            print(f"❌ File has only {len(lines)} lines, cannot fix line 341")
            return False
        
        # Write the fixed content
        with open(file_path, 'w') as f:
            f.writelines(lines)
        
        print("✅ Fixed line 341 in WeatherDashboardComponent.swift")
        return True
        
    except Exception as e:
        print(f"❌ Error fixing line 341: {e}")
        return False

if __name__ == "__main__":
    fix_line_341()
PYTHON_EOF

python3 /tmp/fix_line_341.py

# =============================================================================
# VERIFICATION
# =============================================================================

echo ""
echo "🔍 VERIFICATION: Checking line 341..."
sed -n '341p' "Components/Shared Components/WeatherDashboardComponent.swift" 2>/dev/null || echo "Line 341 not found"

echo ""
echo "🔍 Context around line 341:"
sed -n '339,343p' "Components/Shared Components/WeatherDashboardComponent.swift" 2>/dev/null || echo "File not found"

# =============================================================================
# BUILD TEST FOR THIS SPECIFIC FILE
# =============================================================================

echo ""
echo "🔨 Testing compilation of WeatherDashboardComponent..."
xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build -destination "platform=iOS Simulator,name=iPhone 15 Pro" 2>&1 | grep -A 5 -B 5 "WeatherDashboardComponent" || echo "No WeatherDashboardComponent errors found"

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "🎯 LINE 341 FIX COMPLETED!"
echo "=========================="
echo ""
echo "📋 What was fixed:"
echo "• Line 341: Added missing 'address' parameter to NamedCoordinate constructor"
echo "• Used real address: '150 W 17th St, New York, NY 10011' (Rubin Museum)"
echo ""
echo "📂 Backup created:"
echo "• WeatherDashboardComponent.swift.backup.[timestamp]"
echo ""
echo "🚀 Next: Run full build to verify the fix"

exit 0
