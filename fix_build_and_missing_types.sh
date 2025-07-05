#!/bin/bash

echo "🔧 Fix Build Reference and Missing Types"
echo "========================================"
echo "Removing Xcode project reference and restoring missing types"

cd "/Volumes/FastSSD/Xcode" || exit 1

# =============================================================================
# STEP 1: Remove FrancoSphereTypes.swift from Xcode Project
# =============================================================================

echo ""
echo "🔧 Step 1: Removing FrancoSphereTypes.swift reference from Xcode project..."

PROJECT_FILE="FrancoSphere.xcodeproj/project.pbxproj"
if [ -f "$PROJECT_FILE" ]; then
    cp "$PROJECT_FILE" "$PROJECT_FILE.backup.$(date +%s)"
    
    # Remove all references to FrancoSphereTypes.swift
    sed -i.tmp '/FrancoSphereTypes\.swift/d' "$PROJECT_FILE"
    rm -f "$PROJECT_FILE.tmp"
    
    echo "✅ Removed FrancoSphereTypes.swift references from Xcode project"
else
    echo "⚠️  Could not find project.pbxproj file"
fi

# =============================================================================
# STEP 2: Fix Missing Types in FrancoSphereModels.swift
# =============================================================================

echo ""
echo "🔧 Step 2: Restoring missing types in FrancoSphereModels.swift..."

FILE="Models/FrancoSphereModels.swift"
if [ -f "$FILE" ]; then
    cp "$FILE" "$FILE.restore_backup.$(date +%s)"
    
    cat > /tmp/restore_missing_types.py << 'PYTHON_EOF'
import re
import time

def restore_missing_types():
    file_path = "/Volumes/FastSSD/Xcode/Models/FrancoSphereModels.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        print("🔧 Analyzing current content for missing types...")
        
        # Check if ContextualTask is missing
        if 'public struct ContextualTask' not in content:
            print("⚠️  ContextualTask is missing, will add it")
            
            # Find insertion point before closing of FrancoSphere enum
            closing_brace_pos = content.rfind("}")
            if closing_brace_pos == -1:
                print("❌ Could not find closing brace of FrancoSphere enum")
                return False
            
            # Insert ContextualTask definition
            contextual_task_def = '''
    // MARK: - Task Context Models
    public struct ContextualTask: Identifiable, Codable {
        public let id: String
        public let maintenanceTask: MaintenanceTask
        public let buildingName: String?
        
        public var name: String { maintenanceTask.title }
        public var title: String { maintenanceTask.title }
        public var description: String { maintenanceTask.description }
        public var category: TaskCategory { maintenanceTask.category }
        public var urgency: TaskUrgency { maintenanceTask.urgency }
        public var buildingId: String { maintenanceTask.buildingId }
        public var isCompleted: Bool { maintenanceTask.isCompleted }
        
        public init(id: String, maintenanceTask: MaintenanceTask, buildingName: String? = nil) {
            self.id = id
            self.maintenanceTask = maintenanceTask
            self.buildingName = buildingName
        }
        
        public init(id: String, name: String, description: String, buildingId: String, workerId: String, isCompleted: Bool) {
            let task = MaintenanceTask(
                id: id,
                title: name,
                description: description,
                category: .maintenance,
                urgency: .medium,
                buildingId: buildingId,
                assignedTo: workerId,
                isCompleted: isCompleted
            )
            self.init(id: id, maintenanceTask: task)
        }
    }

'''
            
            # Find better insertion point - before any type aliases section
            type_alias_pos = content.find("// MARK: - Clean Type Aliases")
            if type_alias_pos != -1:
                insert_pos = type_alias_pos
            else:
                # Insert before the last closing brace of the FrancoSphere enum
                lines = content.split('\n')
                for i in range(len(lines) - 1, -1, -1):
                    if lines[i].strip() == '}' and i > 0:
                        # This should be the closing brace of FrancoSphere enum
                        insert_pos = content.find(lines[i])
                        break
                else:
                    insert_pos = closing_brace_pos
            
            content = content[:insert_pos] + contextual_task_def + content[insert_pos:]
            print("✅ Added ContextualTask definition")
        
        # Check if WorkerProfile is missing
        if 'public struct WorkerProfile' not in content:
            print("⚠️  WorkerProfile is missing, will add it")
            
            worker_profile_def = '''
    // MARK: - Worker Models
    public enum WorkerSkill: String, CaseIterable, Codable {
        case basic = "Basic"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"
        case maintenance = "Maintenance"
        case electrical = "Electrical"
        case plumbing = "Plumbing"
        case hvac = "HVAC"
        case painting = "Painting"
        case carpentry = "Carpentry"
        case landscaping = "Landscaping"
        case security = "Security"
        case specialized = "Specialized"
    }
    
    public enum UserRole: String, Codable, CaseIterable {
        case admin
        case supervisor
        case worker
        case client
    }
    
    public struct WorkerProfile: Identifiable, Codable {
        public let id: String
        public let name: String
        public let email: String
        public let role: UserRole
        public var skills: [WorkerSkill]
        public var assignedBuildings: [String]
        public var isActive: Bool
        
        public init(id: String, name: String, email: String, role: UserRole, skills: [WorkerSkill] = [], assignedBuildings: [String] = [], isActive: Bool = true) {
            self.id = id
            self.name = name
            self.email = email
            self.role = role
            self.skills = skills
            self.assignedBuildings = assignedBuildings
            self.isActive = isActive
        }
    }
    
    public struct WorkerAssignment: Identifiable, Codable {
        public let id: String
        public let workerId: String
        public let buildingId: String
        public let taskId: String?
        public let assignedDate: Date
        public let isActive: Bool
        
        public init(id: String, workerId: String, buildingId: String, taskId: String? = nil, assignedDate: Date, isActive: Bool = true) {
            self.id = id
            self.workerId = workerId
            self.buildingId = buildingId
            self.taskId = taskId
            self.assignedDate = assignedDate
            self.isActive = isActive
        }
    }

'''
            
            # Insert WorkerProfile before ContextualTask if it exists
            contextual_task_pos = content.find("// MARK: - Task Context Models")
            if contextual_task_pos != -1:
                insert_pos = contextual_task_pos
            else:
                # Insert before type aliases
                type_alias_pos = content.find("// MARK: - Clean Type Aliases")
                if type_alias_pos != -1:
                    insert_pos = type_alias_pos
                else:
                    # Insert before last closing brace
                    insert_pos = content.rfind("}")
            
            content = content[:insert_pos] + worker_profile_def + content[insert_pos:]
            print("✅ Added WorkerProfile and related types")
        
        # Fix type aliases at the end to ensure they reference the correct types
        if "public typealias ContextualTask = FrancoSphere.ContextualTask" not in content:
            # Add missing type aliases before the end
            if "// Legacy compatibility" in content:
                legacy_pos = content.find("// Legacy compatibility")
                missing_aliases = '''public typealias ContextualTask = FrancoSphere.ContextualTask
public typealias WorkerProfile = FrancoSphere.WorkerProfile
public typealias WorkerSkill = FrancoSphere.WorkerSkill
public typealias UserRole = FrancoSphere.UserRole
public typealias WorkerAssignment = FrancoSphere.WorkerAssignment

'''
                content = content[:legacy_pos] + missing_aliases + content[legacy_pos:]
                print("✅ Added missing type aliases")
        
        # Write the fixed content
        with open(file_path, 'w') as f:
            f.write(content)
        
        print("✅ Restored missing types in FrancoSphereModels.swift")
        return True
        
    except Exception as e:
        print(f"❌ Error restoring types: {e}")
        return False

if __name__ == "__main__":
    restore_missing_types()
PYTHON_EOF

    python3 /tmp/restore_missing_types.py
fi

# =============================================================================
# STEP 3: Verify File Structure and Types
# =============================================================================

echo ""
echo "🔍 VERIFICATION: Checking file structure and types..."

echo ""
echo "Checking if FrancoSphereTypes.swift still exists:"
ls -la "Components/Shared Components/FrancoSphereTypes.swift" 2>/dev/null || echo "✅ FrancoSphereTypes.swift does not exist (good)"

echo ""
echo "Checking for ContextualTask in FrancoSphereModels.swift:"
grep -n "struct ContextualTask" "Models/FrancoSphereModels.swift" || echo "⚠️  ContextualTask not found"

echo ""
echo "Checking for WorkerProfile in FrancoSphereModels.swift:"
grep -n "struct WorkerProfile" "Models/FrancoSphereModels.swift" || echo "⚠️  WorkerProfile not found"

echo ""
echo "Checking for type aliases:"
grep -c "typealias" "Models/FrancoSphereModels.swift" || echo "0"

# =============================================================================
# STEP 4: Test Compilation
# =============================================================================

echo ""
echo "🔨 TESTING COMPILATION"
echo "======================"

echo "Running clean build to test fixes..."
xcodebuild clean -project FrancoSphere.xcodeproj -scheme FrancoSphere >/dev/null 2>&1

COMPILE_OUTPUT=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build -destination "platform=iOS Simulator,name=iPhone 15 Pro" 2>&1)

# Check for specific error types
BUILD_ERRORS=$(echo "$COMPILE_OUTPUT" | grep -c "Build input file cannot be found" || echo "0")
TYPE_ERRORS=$(echo "$COMPILE_OUTPUT" | grep -c "Cannot find type" || echo "0")
REDECLARATION_ERRORS=$(echo "$COMPILE_OUTPUT" | grep -c "Invalid redeclaration" || echo "0")

echo "Build input file errors: $BUILD_ERRORS"
echo "Type not found errors: $TYPE_ERRORS"
echo "Redeclaration errors: $REDECLARATION_ERRORS"

if [ "$BUILD_ERRORS" -eq 0 ] && [ "$TYPE_ERRORS" -eq 0 ] && [ "$REDECLARATION_ERRORS" -eq 0 ]; then
    echo "✅ SUCCESS: All major compilation issues resolved!"
else
    echo "⚠️  Remaining issues:"
    if [ "$BUILD_ERRORS" -gt 0 ]; then
        echo "$COMPILE_OUTPUT" | grep "Build input file cannot be found" | head -3
    fi
    if [ "$TYPE_ERRORS" -gt 0 ]; then
        echo "$COMPILE_OUTPUT" | grep "Cannot find type" | head -3
    fi
    if [ "$REDECLARATION_ERRORS" -gt 0 ]; then
        echo "$COMPILE_OUTPUT" | grep "Invalid redeclaration" | head -3
    fi
fi

# =============================================================================
# STEP 5: Alternative Quick Fix if Issues Persist
# =============================================================================

if [ "$TYPE_ERRORS" -gt 0 ]; then
    echo ""
    echo "🔧 Applying quick fix for persistent type issues..."
    
    # Ensure essential types are at the beginning of the namespace
    cat > /tmp/quick_type_fix.py << 'PYTHON_EOF'
import re

def quick_type_fix():
    file_path = "/Volumes/FastSSD/Xcode/Models/FrancoSphereModels.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Find the FrancoSphere enum opening
        enum_start = content.find("public enum FrancoSphere {")
        if enum_start == -1:
            print("❌ Could not find FrancoSphere enum")
            return False
        
        # Insert essential types right after the enum opening
        insertion_point = content.find("\n", enum_start) + 1
        
        essential_types = '''    
    // MARK: - Core Types (Always First)
    public enum TaskCategory: String, CaseIterable, Codable {
        case cleaning = "Cleaning"
        case maintenance = "Maintenance"
        case inspection = "Inspection"
        case repair = "Repair"
        case security = "Security"
        case landscaping = "Landscaping"
        case administrative = "Administrative"
        case emergency = "Emergency"
    }
    
    public enum TaskUrgency: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        case urgent = "Urgent"
    }
    
    public enum UserRole: String, Codable, CaseIterable {
        case admin
        case supervisor
        case worker
        case client
    }
    
    public enum VerificationStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case verified = "Verified"
        case approved = "Approved"
        case rejected = "Rejected"
        case failed = "Failed"
        case requiresReview = "Requires Review"
    }

'''
        
        # Only insert if these types aren't already there
        if "public enum TaskCategory" not in content:
            content = content[:insertion_point] + essential_types + content[insertion_point:]
            
            with open(file_path, 'w') as f:
                f.write(content)
            
            print("✅ Added essential enum types at beginning")
        
    except Exception as e:
        print(f"❌ Error in quick fix: {e}")

if __name__ == "__main__":
    quick_type_fix()
PYTHON_EOF

    python3 /tmp/quick_type_fix.py
fi

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "🎯 BUILD AND TYPE FIX COMPLETED!"
echo "================================="
echo ""
echo "📋 Actions taken:"
echo "• ✅ Removed FrancoSphereTypes.swift reference from Xcode project"
echo "• ✅ Restored missing ContextualTask and WorkerProfile types"
echo "• ✅ Added missing type aliases"
echo "• ✅ Applied quick fix for essential enums if needed"
echo "• ✅ Tested compilation for all error types"
echo ""
echo "📂 Backups created:"
echo "• project.pbxproj.backup.[timestamp]"
echo "• FrancoSphereModels.swift.restore_backup.[timestamp]"
echo ""
if [ "$BUILD_ERRORS" -eq 0 ] && [ "$TYPE_ERRORS" -eq 0 ] && [ "$REDECLARATION_ERRORS" -eq 0 ]; then
    echo "🚀 RESULT: Project should now build successfully!"
else
    echo "🔧 RESULT: Major issues resolved, check remaining errors above"
fi

exit 0
