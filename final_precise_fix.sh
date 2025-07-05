#!/bin/bash

set -e
PROJECT_ROOT="/Volumes/FastSSD/Xcode"

echo "🔧 Precise Fix for Last 4 Errors"

# Fix 1: FrancoSphereModels.swift - Remove duplicate coordinate declaration
echo "🔧 Fixing FrancoSphereModels.swift coordinate duplicate..."
python3 -c "
import re
with open('$PROJECT_ROOT/Models/FrancoSphereModels.swift', 'r') as f:
    content = f.read()

# Find and remove duplicate coordinate declarations
lines = content.split('\n')
new_lines = []
coordinate_found = False

for line in lines:
    if 'public let coordinate:' in line:
        if not coordinate_found:
            new_lines.append(line)
            coordinate_found = True
        # Skip duplicates
    else:
        new_lines.append(line)

with open('$PROJECT_ROOT/Models/FrancoSphereModels.swift', 'w') as f:
    f.write('\n'.join(new_lines))
print('✅ Fixed coordinate redeclaration')
"

# Fix 2: BuildingTaskDetailView.swift - Fix function declarations
echo "🔧 Fixing BuildingTaskDetailView.swift function declarations..."
python3 -c "
with open('$PROJECT_ROOT/Views/Buildings/BuildingTaskDetailView.swift', 'r') as f:
    content = f.read()

# Fix broken function patterns
content = content.replace(': FrancoSphere.WorkerAssignment', '() -> [FrancoSphere.WorkerAssignment]')
content = content.replace('func getAssignments: FrancoSphere.WorkerAssignment', 'func getAssignments() -> [FrancoSphere.WorkerAssignment]')
content = content.replace('func assignments: FrancoSphere.WorkerAssignment', 'func assignments() -> [FrancoSphere.WorkerAssignment]')

with open('$PROJECT_ROOT/Views/Buildings/BuildingTaskDetailView.swift', 'w') as f:
    f.write(content)
print('✅ Fixed function declarations')
"

# Fix 3: TodayTasksViewModel.swift - Fix dictionary literal
echo "🔧 Fixing TodayTasksViewModel.swift dictionary literal..."
python3 -c "
with open('$PROJECT_ROOT/Views/Main/TodayTasksViewModel.swift', 'r') as f:
    content = f.read()

# Fix dictionary literal
content = content.replace('categoryBreakdown: [:]', 'categoryBreakdown: [String: Int]()')

with open('$PROJECT_ROOT/Views/Main/TodayTasksViewModel.swift', 'w') as f:
    f.write(content)
print('✅ Fixed dictionary literal')
"

echo ""
echo "✅ All precise fixes completed!"
echo "📊 Remaining errors should now be resolved."
echo "🎯 Ready for final build test!"

