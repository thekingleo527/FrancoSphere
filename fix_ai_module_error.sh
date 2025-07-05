#!/bin/bash
set -e

echo "🔧 Fixing AIModels import error - Quick patch"
echo "============================================"

cd "/Volumes/FastSSD/Xcode" || exit 1

# =============================================================================
# 🔧 FIX 1: Remove invalid AIModels imports
# =============================================================================

echo ""
echo "🔧 Removing invalid AIModels imports..."

AI_FILES=(
    "Components/Shared Components/AIScenarioSheetView.swift"
    "Components/Shared Components/AIAvatarOverlayView.swift"
    "Managers/AIAssistantManager.swift"
)

for FILE in "${AI_FILES[@]}"; do
    if [ -f "$FILE" ]; then
        sed -i '' '/import AIModels/d' "$FILE"
        echo "✅ Removed AIModels import from $FILE"
    fi
done

# =============================================================================
# 🔧 FIX 2: Add AI types directly to FrancoSphereModels.swift
# =============================================================================

echo ""
echo "🔧 Adding AI types to FrancoSphereModels.swift..."

cat > /tmp/add_ai_types.py << 'PYTHON_EOF'
def add_ai_types_to_models():
    file_path = "/Volumes/FastSSD/Xcode/Models/FrancoSphereModels.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Add AI types before the type aliases section
        ai_types = '''    
    // MARK: - AI Assistant Types
    public struct AIScenario: Identifiable, Codable {
        public let id: String
        public let type: String
        public let title: String
        public let description: String
        public let timestamp: Date
        
        public init(id: String = UUID().uuidString, type: String = "general", title: String = "AI Scenario", description: String = "AI-generated scenario", timestamp: Date = Date()) {
            self.id = id
            self.type = type
            self.title = title
            self.description = description
            self.timestamp = timestamp
        }
    }
    
    public struct AISuggestion: Identifiable, Codable {
        public let id: String
        public let text: String
        public let actionType: String
        public let confidence: Double
        
        public init(id: String = UUID().uuidString, text: String, actionType: String = "general", confidence: Double = 0.8) {
            self.id = id
            self.text = text
            self.actionType = actionType
            self.confidence = confidence
        }
    }
    
    public struct AIScenarioData: Identifiable, Codable {
        public let id: String
        public let context: String
        public let workerId: String?
        public let buildingId: String?
        public let taskId: String?
        public let timestamp: Date
        
        public init(id: String = UUID().uuidString, context: String, workerId: String? = nil, buildingId: String? = nil, taskId: String? = nil, timestamp: Date = Date()) {
            self.id = id
            self.context = context
            self.workerId = workerId
            self.buildingId = buildingId
            self.taskId = taskId
            self.timestamp = timestamp
        }
    }
'''
        
        # Insert AI types before the closing brace of FrancoSphere enum
        insertion_point = content.rfind('}', content.rfind('// MARK: - Type Aliases'))
        if insertion_point != -1:
            content = content[:insertion_point] + ai_types + '\n' + content[insertion_point:]
        
        # Add type aliases for AI types
        ai_aliases = '''public typealias AIScenario = FrancoSphere.AIScenario
public typealias AISuggestion = FrancoSphere.AISuggestion
public typealias AIScenarioData = FrancoSphere.AIScenarioData
'''
        
        # Add to the end of type aliases
        content = content + '\n' + ai_aliases
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        print("✅ Added AI types to FrancoSphereModels.swift")
        return True
        
    except Exception as e:
        print(f"❌ Error adding AI types: {e}")
        return False

if __name__ == "__main__":
    add_ai_types_to_models()
PYTHON_EOF

python3 /tmp/add_ai_types.py

# =============================================================================
# 🔧 FIX 3: Remove standalone AIModels.swift file
# =============================================================================

echo ""
echo "🔧 Removing standalone AIModels.swift file..."

if [ -f "Models/AIModels.swift" ]; then
    rm "Models/AIModels.swift"
    echo "✅ Removed Models/AIModels.swift"
fi

# =============================================================================
# 🔧 BUILD TEST
# =============================================================================

echo ""
echo "🔨 Testing build after AI types fix..."

BUILD_OUTPUT=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build -destination "platform=iOS Simulator,name=iPhone 15 Pro" 2>&1)

ERROR_COUNT=$(echo "$BUILD_OUTPUT" | grep -c " error:" || echo "0")
AI_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "No such module 'AIModels'\|Cannot find type 'AI" || echo "0")

echo ""
echo "📊 Build Results:"
echo "• Total errors: $ERROR_COUNT"
echo "• AI-related errors: $AI_ERRORS"

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo ""
    echo "🟢 ✅ BUILD SUCCESS"
    echo "=================="
    echo "🎉 All AI module errors fixed!"
    echo "✅ FrancoSphere compiles successfully"
elif [ "$AI_ERRORS" -eq 0 ]; then
    echo ""
    echo "🟡 ✅ AI ERRORS FIXED"
    echo "===================="
    echo "✅ No more AI module errors"
    echo "⚠️  $ERROR_COUNT other errors remain"
    echo ""
    echo "📋 Remaining errors:"
    echo "$BUILD_OUTPUT" | grep " error:" | head -10
else
    echo ""
    echo "🔴 ❌ AI ERRORS PERSIST"
    echo "======================"
    echo "❌ $AI_ERRORS AI-related errors remain"
    echo ""
    echo "📋 AI errors:"
    echo "$BUILD_OUTPUT" | grep -E "(AIModels|Cannot find type 'AI)" | head -5
fi

echo ""
echo "🔧 AI Module Fix Complete"
echo "========================"
