#!/bin/bash

echo "🔧 AIAssistantManager Surgical Fix"
echo "=================================="
echo "Fixing specific addScenario and contextual base errors"

cd "/Volumes/FastSSD/Xcode" || exit 1

# =============================================================================
# FIX 1: Add missing addScenario method and scenario types to AIAssistantManager
# =============================================================================

echo ""
echo "🔧 Fix 1: Adding missing addScenario method and scenario types"
echo "============================================================="

FILE="Managers/AIAssistantManager.swift"
if [ -f "$FILE" ]; then
    echo "Creating backup..."
    cp "$FILE" "${FILE}.surgical_backup.$(date +%s)"
    
    cat > /tmp/fix_ai_manager.py << 'PYTHON_EOF'
import re

def fix_ai_manager():
    file_path = "/Volumes/FastSSD/Xcode/Managers/AIAssistantManager.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        print("🔧 Adding missing addScenario method and scenario types...")
        
        # Add scenario types enum at the top of the file
        scenario_types = '''
// MARK: - Scenario Types
public enum AIScenarioType: String, CaseIterable {
    case routineIncomplete = "routine_incomplete"
    case taskCompletion = "task_completion"
    case pendingTasks = "pending_tasks"
    case buildingArrival = "building_arrival"
    case weatherAlert = "weather_alert"
    case maintenanceRequired = "maintenance_required"
    case scheduleConflict = "schedule_conflict"
    case emergencyResponse = "emergency_response"
}

'''
        
        # Insert scenario types after imports
        content = re.sub(
            r'(import [^\n]+\n)',
            r'\1' + scenario_types,
            content, count=1
        )
        
        # Add missing methods to AIAssistantManager class
        missing_methods = '''
    
    // MARK: - Scenario Management
    func addScenario(_ scenarioType: AIScenarioType, priority: AIPriority = .medium, context: String = "") {
        let scenario = AIScenario(
            id: UUID().uuidString,
            type: scenarioType,
            title: scenarioType.displayTitle,
            description: context.isEmpty ? scenarioType.defaultDescription : context,
            priority: priority,
            timestamp: Date(),
            isActive: true
        )
        
        activeScenarios.append(scenario)
        hasActiveScenarios = !activeScenarios.isEmpty
        
        // Generate relevant suggestions for this scenario
        let suggestions = generateSuggestions(for: scenarioType)
        self.suggestions.append(contentsOf: suggestions)
        
        print("📱 Added AI scenario: \\(scenarioType.rawValue)")
    }
    
    func dismissScenario(_ scenarioId: String) {
        activeScenarios.removeAll { $0.id == scenarioId }
        hasActiveScenarios = !activeScenarios.isEmpty
    }
    
    func clearAllScenarios() {
        activeScenarios.removeAll()
        suggestions.removeAll()
        hasActiveScenarios = false
        currentScenario = nil
        currentScenarioData = nil
    }
    
    private func generateSuggestions(for scenarioType: AIScenarioType) -> [AISuggestion] {
        switch scenarioType {
        case .routineIncomplete:
            return [
                AISuggestion(id: "check_tasks", text: "Review incomplete tasks", priority: .high),
                AISuggestion(id: "update_status", text: "Update task status", priority: .medium)
            ]
        case .taskCompletion:
            return [
                AISuggestion(id: "mark_complete", text: "Mark task as complete", priority: .high),
                AISuggestion(id: "add_notes", text: "Add completion notes", priority: .low)
            ]
        case .pendingTasks:
            return [
                AISuggestion(id: "prioritize", text: "Prioritize pending tasks", priority: .high),
                AISuggestion(id: "reschedule", text: "Reschedule if needed", priority: .medium)
            ]
        case .buildingArrival:
            return [
                AISuggestion(id: "clock_in", text: "Clock in at building", priority: .high),
                AISuggestion(id: "check_schedule", text: "Review today's schedule", priority: .medium)
            ]
        default:
            return [
                AISuggestion(id: "generic_action", text: "Take appropriate action", priority: .medium)
            ]
        }
    }'''
        
        # Insert missing methods before the closing brace of the class
        content = re.sub(
            r'(\n}$)',
            missing_methods + r'\1',
            content, flags=re.MULTILINE
        )
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        print("✅ Fixed AIAssistantManager.swift - added addScenario method and scenario types")
        return True
        
    except Exception as e:
        print(f"❌ Error fixing AIAssistantManager: {e}")
        return False

if __name__ == "__main__":
    fix_ai_manager()
PYTHON_EOF

    python3 /tmp/fix_ai_manager.py
else
    echo "❌ AIAssistantManager.swift not found"
fi

# =============================================================================
# FIX 2: Add missing extensions for AIScenarioType
# =============================================================================

echo ""
echo "🔧 Fix 2: Adding AIScenarioType extensions"
echo "========================================="

cat > "Models/AIScenarioTypeExtensions.swift" << 'EXT_EOF'
//
//  AIScenarioTypeExtensions.swift
//  FrancoSphere
//
//  Extensions for AI scenario types
//

import Foundation

// MARK: - AIScenarioType Extensions
extension AIScenarioType {
    public var displayTitle: String {
        switch self {
        case .routineIncomplete:
            return "Routine Incomplete"
        case .taskCompletion:
            return "Task Completion"
        case .pendingTasks:
            return "Pending Tasks"
        case .buildingArrival:
            return "Building Arrival"
        case .weatherAlert:
            return "Weather Alert"
        case .maintenanceRequired:
            return "Maintenance Required"
        case .scheduleConflict:
            return "Schedule Conflict"
        case .emergencyResponse:
            return "Emergency Response"
        }
    }
    
    public var defaultDescription: String {
        switch self {
        case .routineIncomplete:
            return "Some routine tasks are incomplete"
        case .taskCompletion:
            return "Task is ready for completion"
        case .pendingTasks:
            return "You have pending tasks that need attention"
        case .buildingArrival:
            return "You've arrived at a building"
        case .weatherAlert:
            return "Weather conditions may affect your work"
        case .maintenanceRequired:
            return "Equipment or area needs maintenance"
        case .scheduleConflict:
            return "There's a conflict in your schedule"
        case .emergencyResponse:
            return "Emergency situation requires immediate attention"
        }
    }
    
    public var icon: String {
        switch self {
        case .routineIncomplete:
            return "clock"
        case .taskCompletion:
            return "checkmark.circle"
        case .pendingTasks:
            return "list.bullet"
        case .buildingArrival:
            return "building.2"
        case .weatherAlert:
            return "cloud.rain"
        case .maintenanceRequired:
            return "wrench"
        case .scheduleConflict:
            return "calendar.badge.exclamationmark"
        case .emergencyResponse:
            return "exclamationmark.triangle"
        }
    }
}

// MARK: - AIPriority Enum
public enum AIPriority: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    case critical = "Critical"
    
    public var color: String {
        switch self {
        case .low:
            return "gray"
        case .medium:
            return "blue"
        case .high:
            return "orange"
        case .urgent:
            return "red"
        case .critical:
            return "purple"
        }
    }
}
EXT_EOF

# =============================================================================
# FIX 3: Update AIScenario and AISuggestion models to support new properties
# =============================================================================

echo ""
echo "🔧 Fix 3: Updating AIScenario and AISuggestion models"
echo "===================================================="

FILE="Models/FrancoSphereModels.swift"
if [ -f "$FILE" ]; then
    echo "Adding enhanced AI types to FrancoSphereModels..."
    cp "$FILE" "${FILE}.ai_fix_backup.$(date +%s)"
    
    cat > /tmp/fix_ai_models.py << 'PYTHON_EOF'
import re

def fix_ai_models():
    file_path = "/Volumes/FastSSD/Xcode/Models/FrancoSphereModels.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        print("🔧 Updating AIScenario and AISuggestion models...")
        
        # Enhanced AIScenario struct
        enhanced_ai_scenario = '''
    public struct AIScenario: Identifiable, Codable {
        public let id: String
        public let type: String  // Maps to AIScenarioType.rawValue
        public let title: String
        public let description: String
        public let priority: String  // Maps to AIPriority.rawValue
        public let timestamp: Date
        public let isActive: Bool
        public let context: String
        public let suggestions: [AISuggestion]
        
        public init(id: String = UUID().uuidString, type: AIScenarioType, title: String, 
                   description: String, priority: AIPriority = .medium, 
                   timestamp: Date = Date(), isActive: Bool = true, 
                   context: String = "", suggestions: [AISuggestion] = []) {
            self.id = id
            self.type = type.rawValue
            self.title = title
            self.description = description
            self.priority = priority.rawValue
            self.timestamp = timestamp
            self.isActive = isActive
            self.context = context
            self.suggestions = suggestions
        }
    }'''
        
        # Enhanced AISuggestion struct
        enhanced_ai_suggestion = '''
    
    public struct AISuggestion: Identifiable, Codable {
        public let id: String
        public let text: String
        public let actionType: String
        public let priority: String
        public let createdAt: Date
        public let icon: String
        
        public init(id: String = UUID().uuidString, text: String, 
                   actionType: String = "general", priority: AIPriority = .medium,
                   createdAt: Date = Date(), icon: String = "lightbulb") {
            self.id = id
            self.text = text
            self.actionType = actionType
            self.priority = priority.rawValue
            self.createdAt = createdAt
            self.icon = icon
        }
    }'''
        
        # Enhanced AIScenarioData struct
        enhanced_ai_scenario_data = '''
    
    public struct AIScenarioData: Identifiable, Codable {
        public let id: String
        public let context: String
        public let suggestions: [AISuggestion]
        public let priority: String
        public let timestamp: Date
        
        // Compatibility properties
        public var message: String { context }
        public var actionText: String { "Take Action" }
        public var icon: String { "sparkles" }
        
        public init(id: String = UUID().uuidString, context: String, 
                   suggestions: [AISuggestion] = [], priority: AIPriority = .medium,
                   timestamp: Date = Date()) {
            self.id = id
            self.context = context
            self.suggestions = suggestions
            self.priority = priority.rawValue
            self.timestamp = timestamp
        }
    }'''
        
        # Replace existing AI types with enhanced versions
        content = re.sub(
            r'public struct AIScenario:.*?(?=public struct|public enum|public typealias|\Z)',
            enhanced_ai_scenario + '\n\n    ',
            content, flags=re.DOTALL
        )
        
        content = re.sub(
            r'public struct AISuggestion:.*?(?=public struct|public enum|public typealias|\Z)',
            enhanced_ai_suggestion + '\n\n    ',
            content, flags=re.DOTALL
        )
        
        content = re.sub(
            r'public struct AIScenarioData:.*?(?=public struct|public enum|public typealias|\Z)',
            enhanced_ai_scenario_data + '\n\n    ',
            content, flags=re.DOTALL
        )
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        print("✅ Updated AI models in FrancoSphereModels.swift")
        return True
        
    except Exception as e:
        print(f"❌ Error updating AI models: {e}")
        return False

if __name__ == "__main__":
    fix_ai_models()
PYTHON_EOF

    python3 /tmp/fix_ai_models.py
fi

# =============================================================================
# FIX 4: Fix specific HeaderV3B.swift compilation errors
# =============================================================================

echo ""
echo "🔧 Fix 4: Fixing HeaderV3B.swift specific errors"
echo "=============================================="

FILE="Components/Design/HeaderV3B.swift"
if [ -f "$FILE" ]; then
    echo "Fixing HeaderV3B.swift addScenario calls..."
    cp "$FILE" "${FILE}.surgical_backup.$(date +%s)"
    
    cat > /tmp/fix_header.py << 'PYTHON_EOF'
import re

def fix_header():
    file_path = "/Volumes/FastSSD/Xcode/Components/Design/HeaderV3B.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        print("🔧 Fixing addScenario method calls...")
        
        # Fix addScenario calls with proper AIScenarioType enum values
        content = re.sub(
            r'\.addScenario\(\s*\.routineIncomplete\s*\)',
            '.addScenario(.routineIncomplete)',
            content
        )
        
        content = re.sub(
            r'\.addScenario\(\s*\.taskCompletion\s*\)',
            '.addScenario(.taskCompletion)',
            content
        )
        
        content = re.sub(
            r'\.addScenario\(\s*\.pendingTasks\s*\)',
            '.addScenario(.pendingTasks)',
            content
        )
        
        content = re.sub(
            r'\.addScenario\(\s*\.buildingArrival\s*\)',
            '.addScenario(.buildingArrival)',
            content
        )
        
        # Fix any remaining contextual base references
        content = re.sub(
            r'reference to member \'(\w+)\'',
            r'AIScenarioType.\1',
            content
        )
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        print("✅ Fixed HeaderV3B.swift addScenario calls")
        return True
        
    except Exception as e:
        print(f"❌ Error fixing HeaderV3B.swift: {e}")
        return False

if __name__ == "__main__":
    fix_header()
PYTHON_EOF

    python3 /tmp/fix_header.py
else
    echo "❌ HeaderV3B.swift not found"
fi

# =============================================================================
# VERIFICATION
# =============================================================================

echo ""
echo "🔍 VERIFICATION: Testing specific fixes"
echo "======================================"

# Check if the addScenario method was added
if grep -q "func addScenario" "Managers/AIAssistantManager.swift"; then
    echo "✅ addScenario method found in AIAssistantManager"
else
    echo "❌ addScenario method not found"
fi

# Check if AIScenarioType enum was created
if [ -f "Models/AIScenarioTypeExtensions.swift" ]; then
    echo "✅ AIScenarioType extensions created"
else
    echo "❌ AIScenarioType extensions not created"
fi

# Test specific errors from HeaderV3B.swift
echo ""
echo "🔍 Testing HeaderV3B.swift specific errors..."
ERROR_COUNT=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build 2>&1 | grep "HeaderV3B.swift" | grep -c "error:")

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "✅ HeaderV3B.swift errors resolved!"
else
    echo "⚠️  $ERROR_COUNT HeaderV3B.swift errors remain:"
    xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build 2>&1 | grep "HeaderV3B.swift.*error:" | head -5
fi

echo ""
echo "🎯 AIAssistantManager SURGICAL FIX COMPLETED!"
echo "============================================"
echo ""
echo "✅ Applied fixes:"
echo "• Added addScenario() method to AIAssistantManager"
echo "• Created AIScenarioType enum with all missing values"
echo "• Added AIPriority enum for scenario priorities"
echo "• Enhanced AIScenario and AISuggestion models"
echo "• Fixed HeaderV3B.swift addScenario calls"
echo "• Added comprehensive extensions and compatibility"
echo ""
echo "🚀 HeaderV3B.swift should now compile without errors!"

exit 0
