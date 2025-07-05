#!/bin/bash
set -e

echo "🔧 Fixing Key Path Type Inference Error"
echo "======================================="

cd "/Volumes/FastSSD/Xcode" || exit 1

# =============================================================================
# 🔧 FIX: Key path type inference in AIAssistantManager.swift
# =============================================================================

echo ""
echo "🔧 Fixing key path type inference error..."

cat > /tmp/fix_key_path.py << 'PYTHON_EOF'
def fix_key_path_error():
    file_path = "/Volumes/FastSSD/Xcode/Managers/AIAssistantManager.swift"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Replace the problematic assign(to:) with a sink approach
        old_binding = """    private func setupBindings() {
        $activeScenarios
            .map { !$0.isEmpty }
            .assign(to: \.hasActiveScenarios, on: self)
            .store(in: &cancellables)
    }"""
        
        new_binding = """    private func setupBindings() {
        $activeScenarios
            .map { !$0.isEmpty }
            .sink { [weak self] hasScenarios in
                self?.hasActiveScenarios = hasScenarios
            }
            .store(in: &cancellables)
    }"""
        
        content = content.replace(old_binding, new_binding)
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        print("✅ Fixed key path type inference error")
        return True
        
    except Exception as e:
        print(f"❌ Error fixing key path: {e}")
        return False

if __name__ == "__main__":
    fix_key_path_error()
PYTHON_EOF

python3 /tmp/fix_key_path.py

# =============================================================================
# 🔧 BUILD TEST
# =============================================================================

echo ""
echo "🔨 Testing build after key path fix..."

BUILD_OUTPUT=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build -destination "platform=iOS Simulator,name=iPhone 15 Pro" 2>&1)

ERROR_COUNT=$(echo "$BUILD_OUTPUT" | grep -c " error:" || echo "0")
KEY_PATH_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "Cannot infer key path\|key path type" || echo "0")

echo ""
echo "📊 Build Results:"
echo "• Total errors: $ERROR_COUNT"
echo "• Key path errors: $KEY_PATH_ERRORS"

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo ""
    echo "🟢 ✅ BUILD SUCCESS"
    echo "=================="
    echo "🎉 All key path errors fixed!"
    echo "✅ FrancoSphere compiles successfully"
elif [ "$KEY_PATH_ERRORS" -eq 0 ]; then
    echo ""
    echo "🟡 ✅ KEY PATH FIXED"
    echo "==================="
    echo "✅ No more key path errors"
    echo "⚠️  $ERROR_COUNT other errors remain"
    echo ""
    echo "📋 Remaining errors:"
    echo "$BUILD_OUTPUT" | grep " error:" | head -10
else
    echo ""
    echo "🔴 ❌ KEY PATH ERRORS PERSIST"
    echo "=========================="
    echo "❌ $KEY_PATH_ERRORS key path errors remain"
    echo ""
    echo "📋 Key path errors:"
    echo "$BUILD_OUTPUT" | grep -E "(Cannot infer key path|key path type)" | head -5
fi

echo ""
echo "🔧 Key Path Fix Complete"
echo "======================="
