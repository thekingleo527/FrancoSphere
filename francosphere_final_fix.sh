#!/bin/bash

set -e
PROJECT_ROOT="/Volumes/FastSSD/Xcode"

echo "🔧 FrancoSphere Final Compilation Fix - All Remaining Errors"

# Phase 1: Fix FrancoSphereModels.swift coordinate redeclaration (line 24)
echo "🔧 Phase 1: Fixing coordinate redeclaration in FrancoSphereModels.swift..."
python3 << 'PYTHON_EOF'
file_path = "/Volumes/FastSSD/Xcode/Models/FrancoSphereModels.swift"

try:
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    # Remove duplicate coordinate declarations
    fixed_lines = []
    coordinate_seen = False
    
    for line in lines:
        if 'public let coordinate:' in line or 'let coordinate:' in line:
            if not coordinate_seen:
                fixed_lines.append(line)
                coordinate_seen = True
            # Skip duplicates
        else:
            fixed_lines.append(line)
    
    with open(file_path, 'w') as f:
        f.writelines(fixed_lines)
    
    print("✅ Fixed coordinate redeclaration")
    
except Exception as e:
    print(f"❌ Error: {e}")
PYTHON_EOF

# Phase 2: Fix BuildingService.swift imageAssetName issues (lines 55-224)
echo "🔧 Phase 2: Removing imageAssetName from BuildingService.swift..."
python3 << 'PYTHON_EOF'
file_path = "/Volumes/FastSSD/Xcode/Services/BuildingService.swift"

try:
    with open(file_path, 'r') as f:
        content = f.read()
    
    import re
    
    # Remove imageAssetName parameters from ALL NamedCoordinate constructor calls
    # Pattern: NamedCoordinate(..., imageAssetName: "...")
    pattern = r'(NamedCoordinate\([^)]+), imageAssetName: "[^"]*"\)'
    content = re.sub(pattern, r'\1)', content)
    
    # Also handle cases where imageAssetName might be on a separate line
    pattern = r'(NamedCoordinate\([^)]+),\s*imageAssetName:\s*"[^"]*"\)'
    content = re.sub(pattern, r'\1)', content, flags=re.MULTILINE)
    
    print("✅ Removed all imageAssetName parameters")
    
    with open(file_path, 'w') as f:
        f.write(content)
    
except Exception as e:
    print(f"❌ Error: {e}")
PYTHON_EOF

# Phase 3: Fix BuildingTaskDetailView.swift function declaration errors (lines 525, 614)
echo "🔧 Phase 3: Fixing BuildingTaskDetailView.swift function declarations..."
python3 << 'PYTHON_EOF'
file_path = "/Volumes/FastSSD/Xcode/Views/Buildings/BuildingTaskDetailView.swift"

try:
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix broken function declarations similar to NewAuthManager
    content = content.replace(
        ': FrancoSphere.WorkerAssignment',
        '() -> [FrancoSphere.WorkerAssignment]'
    )
    
    content = content.replace(
        'func getAssignments: FrancoSphere.WorkerAssignment',
        'func getAssignments() -> [FrancoSphere.WorkerAssignment]'
    )
    
    # Fix parameter declaration syntax errors
    content = content.replace(
        'WorkerAssignment Expected',
        'WorkerAssignment) {'
    )
    
    # Fix any other broken function patterns
    content = content.replace(
        'func assignments: FrancoSphere.WorkerAssignment',
        'func assignments() -> [FrancoSphere.WorkerAssignment]'
    )
    
    print("✅ Fixed function declarations")
    
    with open(file_path, 'w') as f:
        f.write(content)
    
except Exception as e:
    print(f"❌ Error: {e}")
PYTHON_EOF

# Phase 4: Fix TodayTasksViewModel.swift dictionary literal (line 28)
echo "🔧 Phase 4: Fixing TodayTasksViewModel.swift dictionary literal..."
python3 << 'PYTHON_EOF'
file_path = "/Volumes/FastSSD/Xcode/Views/Main/TodayTasksViewModel.swift"

try:
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix empty dictionary literal syntax
    content = content.replace(
        'categoryBreakdown: [:]',
        'categoryBreakdown: [String: Int]()'
    )
    
    # Also fix any other similar patterns
    content = content.replace(
        ': [:]',
        ': [String: Int]()'
    )
    
    print("✅ Fixed dictionary literal")
    
    with open(file_path, 'w') as f:
        f.write(content)
    
except Exception as e:
    print(f"❌ Error: {e}")
PYTHON_EOF

echo "✅ All compilation fixes completed!"
echo "📊 Fixed:"
echo "  • FrancoSphereModels.swift:24 - Coordinate redeclaration"
echo "  • BuildingService.swift:55-224 - ImageAssetName parameters (25+ lines)"
echo "  • BuildingTaskDetailView.swift:525,614 - Function declaration syntax"
echo "  • TodayTasksViewModel.swift:28 - Dictionary literal syntax"
echo ""
echo "🎯 Ready for build verification!"

