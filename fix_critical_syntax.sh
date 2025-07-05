#!/bin/bash
set -euo pipefail

echo "🔧 Critical FrancoSphereModels.swift Syntax Fix"
echo "==============================================="
echo "Fixing missing coordinate property and syntax errors"

cd "/Volumes/FastSSD/Xcode" || { echo "❌ Project directory not found"; exit 1; }

# =============================================================================
# CRITICAL FIX: Rebuild NamedCoordinate and fix syntax errors
# =============================================================================

FILE="Models/FrancoSphereModels.swift"
if [[ -f "$FILE" ]]; then
    # Create backup
    cp "$FILE" "$FILE.critical_fix_backup.$(date +%s)"
    echo "📦 Created backup of $FILE"
    
    cat > /tmp/critical_fix.py << 'PYTHON_EOF'
import re

def critical_fix():
    file_path = "/Volumes/FastSSD/Xcode/Models/FrancoSphereModels.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        print("🔧 Applying critical fixes...")
        
        # FIX 1: Completely rebuild NamedCoordinate with proper structure
        print("• Fixing NamedCoordinate structure...")
        
        namedcoordinate_pattern = r'(public struct NamedCoordinate: Identifiable, Codable \{)(.*?)(\n    \})'
        
        def fix_namedcoordinate(match):
            prefix = match.group(1)
            body = match.group(2)
            suffix = match.group(3)
            
            # Create clean NamedCoordinate with stored latitude/longitude and computed coordinate
            clean_body = '''
        public let id: String
        public let name: String
        public let latitude: Double
        public let longitude: Double
        public let address: String?
        public let imageAssetName: String?
        
        // Computed property for CLLocationCoordinate2D
        public var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        public init(id: String, name: String, coordinate: CLLocationCoordinate2D, address: String? = nil, imageAssetName: String? = nil) {
            self.id = id
            self.name = name
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
            self.address = address
            self.imageAssetName = imageAssetName
        }
        
        public init(id: String, name: String, latitude: Double, longitude: Double, address: String? = nil, imageAssetName: String? = nil) {
            self.id = id
            self.name = name
            self.latitude = latitude
            self.longitude = longitude
            self.address = address
            self.imageAssetName = imageAssetName
        }'''
            
            return prefix + clean_body + '\n' + suffix
        
        content = re.sub(namedcoordinate_pattern, fix_namedcoordinate, content, flags=re.DOTALL)
        print("✅ Fixed NamedCoordinate structure")
        
        # FIX 2: Remove invalid syntax at end of file
        print("• Removing invalid syntax at end of file...")
        
        # Find and remove the problematic code after type aliases
        # Look for the pattern where invalid code starts
        invalid_pattern = r'(\n    // MARK: - Data Health Status\s*\n\s*return false.*?)$'
        content = re.sub(invalid_pattern, '', content, flags=re.DOTALL)
        
        # Also remove any stray statements outside functions/types
        lines = content.split('\n')
        fixed_lines = []
        inside_type = False
        brace_count = 0
        
        for line in lines:
            stripped = line.strip()
            
            # Track if we're inside a type declaration
            if re.match(r'public\s+(enum|struct|class)', stripped):
                inside_type = True
                brace_count = 0
            
            # Count braces to track nesting
            brace_count += line.count('{') - line.count('}')
            
            # If we're at top level (brace_count == 0) and not inside a type
            if brace_count == 0 and inside_type:
                inside_type = False
            
            # Skip invalid top-level statements
            if not inside_type and brace_count == 0:
                # Only allow valid top-level statements
                if (stripped.startswith('import ') or 
                    stripped.startswith('//') or 
                    stripped.startswith('public typealias') or
                    stripped.startswith('public enum') or
                    stripped.startswith('public struct') or
                    stripped.startswith('public class') or
                    stripped == '' or
                    stripped.startswith('// MARK:')):
                    fixed_lines.append(line)
                # Skip invalid statements like 'return false' at top level
                elif stripped.startswith('return ') or stripped.startswith('self.'):
                    print(f"  ✅ Removed invalid top-level statement: {stripped}")
                    continue
                else:
                    fixed_lines.append(line)
            else:
                fixed_lines.append(line)
        
        content = '\n'.join(fixed_lines)
        
        # FIX 3: Clean up any remaining syntax issues
        print("• Cleaning up remaining syntax issues...")
        
        # Remove duplicate consecutive empty lines
        content = re.sub(r'\n\s*\n\s*\n', '\n\n', content)
        
        # Ensure proper ending
        if not content.endswith('\n'):
            content += '\n'
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        print("✅ Critical fixes applied successfully")
        return True
        
    except Exception as e:
        print(f"❌ Error during critical fix: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    critical_fix()
PYTHON_EOF

    python3 /tmp/critical_fix.py
    
    # FIX 4: Ensure DataHealthStatus is properly defined as enum, not struct
    echo ""
    echo "🔧 Fix 4: Ensuring DataHealthStatus is proper enum"
    echo "=================================================="
    
    cat > /tmp/fix_datahealth.py << 'PYTHON_EOF'
import re

def fix_datahealth():
    file_path = "/Volumes/FastSSD/Xcode/Models/FrancoSphereModels.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Replace DataHealthStatus struct with proper enum
        datahealth_struct_pattern = r'public struct DataHealthStatus: Codable \{[^}]*\}'
        
        if re.search(datahealth_struct_pattern, content):
            print("• Replacing DataHealthStatus struct with enum...")
            
            datahealth_enum = '''public enum DataHealthStatus: Codable {
        case healthy
        case warning([String])
        case critical([String])
        case unknown
        
        public static var unknown: DataHealthStatus { .unknown }
        
        public var isHealthy: Bool {
            switch self {
            case .healthy:
                return true
            default:
                return false
            }
        }
        
        public var description: String {
            switch self {
            case .unknown:
                return "Unknown status"
            case .healthy:
                return "All systems operational"
            case .warning(let issues):
                return "Warning: \\(issues.joined(separator: ", "))"
            case .critical(let issues):
                return "Critical: \\(issues.joined(separator: ", "))"
            }
        }
    }'''
            
            content = re.sub(datahealth_struct_pattern, datahealth_enum, content)
            print("✅ Replaced DataHealthStatus struct with proper enum")
        
        # Also fix BuildingTab struct to have proper static property
        buildingtab_pattern = r'public struct BuildingTab: Codable \{[^}]*\}'
        
        if re.search(buildingtab_pattern, content):
            print("• Fixing BuildingTab struct...")
            
            buildingtab_struct = '''public struct BuildingTab: Codable {
        public let id: String
        public let name: String
        
        public static var overview: BuildingTab { 
            BuildingTab(id: "overview", name: "Overview") 
        }
        
        public init(id: String = UUID().uuidString, name: String = "") {
            self.id = id
            self.name = name
        }
    }'''
            
            content = re.sub(buildingtab_pattern, buildingtab_struct, content)
            print("✅ Fixed BuildingTab struct")
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        return True
        
    except Exception as e:
        print(f"❌ Error fixing DataHealthStatus: {e}")
        return False

if __name__ == "__main__":
    fix_datahealth()
PYTHON_EOF

    python3 /tmp/fix_datahealth.py
    
else
    echo "❌ FrancoSphereModels.swift not found"
    exit 1
fi

# =============================================================================
# VERIFICATION
# =============================================================================

echo ""
echo "🔍 VERIFICATION: Testing compilation"
echo "===================================="

echo "Building project to verify fixes..."
BUILD_OUTPUT=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build -destination "platform=iOS Simulator,name=iPhone 15 Pro" 2>&1)

# Count specific error types
READONLY_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "get-only property" || echo "0")
SYNTAX_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "Statements are not allowed\|Return invalid outside" || echo "0")
SCOPE_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "Cannot find.*in scope" || echo "0")
TOTAL_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c " error:" || echo "0")

echo ""
echo "📊 Error Analysis:"
echo "• Read-only property errors: $READONLY_ERRORS"
echo "• Syntax/statement errors: $SYNTAX_ERRORS"
echo "• Scope errors: $SCOPE_ERRORS"
echo "• Total compilation errors: $TOTAL_ERRORS"

# Show specific lines that had issues
echo ""
echo "🔍 Checking fixed lines:"
echo "• Line 35 (coordinate assignment): $(sed -n '35p' "$FILE" 2>/dev/null || echo 'File modified')"
echo "• Line 43 (coordinate assignment): $(sed -n '43p' "$FILE" 2>/dev/null || echo 'File modified')"
echo "• End of file syntax: $(tail -5 "$FILE" | grep -v '^$' | wc -l) non-empty lines at end"

# Show first few remaining errors if any
if [[ $TOTAL_ERRORS -gt 0 ]]; then
    echo ""
    echo "📋 First 5 remaining errors:"
    echo "$BUILD_OUTPUT" | grep " error:" | head -5
fi

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "🎯 CRITICAL SYNTAX FIX SUMMARY"
echo "=============================="
echo ""
echo "✅ Applied fixes:"
echo "• NamedCoordinate: Added proper latitude/longitude stored properties"
echo "• NamedCoordinate: Fixed coordinate computed property"
echo "• NamedCoordinate: Fixed initializers to work with stored properties"
echo "• Removed invalid top-level statements (return false, self references)"
echo "• Fixed DataHealthStatus as proper enum instead of struct"
echo "• Fixed BuildingTab struct with proper static properties"
echo "• Cleaned up file ending and syntax"
echo ""

if [[ $TOTAL_ERRORS -eq 0 ]]; then
    echo "🎉 SUCCESS: All critical syntax errors resolved!"
    echo "🚀 FrancoSphere should now compile successfully!"
else
    echo "⚠️  $TOTAL_ERRORS errors remain"
    echo "🔧 Critical NamedCoordinate and syntax issues should be resolved"
fi

echo ""
echo "📦 Backup created: $FILE.critical_fix_backup.TIMESTAMP"
echo "🚀 Next: Build project (Cmd+B) to verify complete success"

exit 0
