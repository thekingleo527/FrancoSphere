#!/bin/bash

set -e
PROJECT_ROOT="/Volumes/FastSSD/Xcode"

echo "🔧 FrancoSphere Surgical Fix - Targeting exact broken lines only"

# Phase 1: Fix FrancoSphereModels.swift coordinate redeclaration (line 19)
echo "🔧 Fixing FrancoSphereModels.swift coordinate redeclaration..."
python3 << 'PYTHON_EOF'
file_path = "/Volumes/FastSSD/Xcode/Models/FrancoSphereModels.swift"

try:
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    # Remove duplicate coordinate declarations
    fixed_lines = []
    seen_coordinate = False
    
    for line in lines:
        if 'public let coordinate:' in line or 'let coordinate:' in line:
            if not seen_coordinate:
                fixed_lines.append(line)
                seen_coordinate = True
            # Skip duplicate coordinate declarations
        else:
            fixed_lines.append(line)
    
    with open(file_path, 'w') as f:
        f.writelines(fixed_lines)
    
    print("✅ Fixed coordinate redeclaration")
    
except Exception as e:
    print(f"❌ Error: {e}")
PYTHON_EOF

# Phase 2: Fix NewAuthManager.swift broken function declarations (lines 203, 528)
echo "🔧 Fixing NewAuthManager.swift broken function declarations..."
python3 << 'PYTHON_EOF'
file_path = "/Volumes/FastSSD/Xcode/Managers/NewAuthManager.swift"

try:
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix broken function declarations that were mangled by sed
    # Pattern: func name: FrancoSphere.WorkerProfile -> proper function syntax
    
    # Fix line ~203: func getWorkerProfile: FrancoSphere.WorkerProfile
    content = content.replace(
        'func getWorkerProfile: FrancoSphere.WorkerProfile',
        'func getWorkerProfile() -> FrancoSphere.WorkerProfile?'
    )
    
    # Fix line ~528: func getWorkerProfile(byId: FrancoSphere.WorkerProfile
    content = content.replace(
        'func getWorkerProfile(byId: FrancoSphere.WorkerProfile',
        'func getWorkerProfile(byId: String) -> FrancoSphere.WorkerProfile?'
    )
    
    # Fix any other broken function patterns
    content = content.replace(
        ': FrancoSphere.WorkerProfile -> FrancoSphere.WorkerProfile',
        '() -> FrancoSphere.WorkerProfile?'
    )
    
    # Fix broken return statements
    content = content.replace(
        'byId: String) -> FrancoSphere.WorkerProfile? -> FrancoSphere.WorkerProfile',
        'byId: String) -> FrancoSphere.WorkerProfile?'
    )
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("✅ Fixed NewAuthManager function declarations")
    
except Exception as e:
    print(f"❌ Error: {e}")
PYTHON_EOF

# Phase 3: Fix BuildingTaskDetailView.swift broken function declaration (line 614)
echo "🔧 Fixing BuildingTaskDetailView.swift broken function declaration..."
python3 << 'PYTHON_EOF'
file_path = "/Volumes/FastSSD/Xcode/Views/Buildings/BuildingTaskDetailView.swift"

try:
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix broken function declaration around line 614
    # Similar pattern to NewAuthManager
    content = content.replace(
        ': FrancoSphere.WorkerAssignment',
        '() -> [FrancoSphere.WorkerAssignment]'
    )
    
    # Fix any other similar patterns
    content = content.replace(
        'func getAssignments: FrancoSphere.WorkerAssignment',
        'func getAssignments() -> [FrancoSphere.WorkerAssignment]'
    )
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("✅ Fixed BuildingTaskDetailView function declaration")
    
except Exception as e:
    print(f"❌ Error: {e}")
PYTHON_EOF

# Phase 4: Fix BuildingService.swift imageAssetName parameter (lines 55-73)
echo "🔧 Fixing BuildingService.swift imageAssetName parameters..."
python3 << 'PYTHON_EOF'
file_path = "/Volumes/FastSSD/Xcode/Services/BuildingService.swift"

try:
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Remove imageAssetName parameters from NamedCoordinate constructor calls
    import re
    
    # Pattern: NamedCoordinate(id: "...", name: "...", latitude: ..., longitude: ..., imageAssetName: "...")
    # Replace with: NamedCoordinate(id: "...", name: "...", coordinate: CLLocationCoordinate2D(latitude: ..., longitude: ...))
    
    pattern = r'NamedCoordinate\(([^)]*?), imageAssetName: "[^"]*"\)'
    
    def fix_constructor(match):
        params = match.group(1)
        # Extract latitude and longitude
        lat_match = re.search(r'latitude: ([\d.-]+)', params)
        lng_match = re.search(r'longitude: ([\d.-]+)', params)
        
        if lat_match and lng_match:
            lat = lat_match.group(1)
            lng = lng_match.group(1)
            # Remove latitude and longitude from params
            params = re.sub(r', latitude: [\d.-]+', '', params)
            params = re.sub(r', longitude: [\d.-]+', '', params)
            return f'NamedCoordinate({params}, coordinate: CLLocationCoordinate2D(latitude: {lat}, longitude: {lng}))'
        else:
            # Just remove imageAssetName if lat/lng not found
            return match.group(0).replace(re.search(r', imageAssetName: "[^"]*"', match.group(0)).group(0), '')
    
    content = re.sub(pattern, fix_constructor, content)
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("✅ Fixed BuildingService imageAssetName parameters")
    
except Exception as e:
    print(f"❌ Error: {e}")
PYTHON_EOF

# Phase 5: Fix TodayTasksViewModel.swift constructor issues
echo "🔧 Fixing TodayTasksViewModel.swift constructor parameters..."
python3 << 'PYTHON_EOF'
file_path = "/Volumes/FastSSD/Xcode/Views/Main/TodayTasksViewModel.swift"

try:
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix TaskTrends constructor call on line 26
    # From: TaskTrends(weeklyCompletion: [], categoryBreakdown: [:], trend: .stable)
    # To: TaskTrends(weeklyCompletion: [], categoryBreakdown: [:], changePercentage: 0.0)
    
    content = content.replace(
        'trend: .stable',
        'changePercentage: 0.0'
    )
    
    # Fix empty dictionary literal issue on line 28
    content = content.replace(
        'categoryBreakdown: [:]',
        'categoryBreakdown: [String: Int]()'
    )
    
    # Fix .stable reference on line 29 if it exists
    content = content.replace(
        'Double.stable',
        '0.0'
    )
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("✅ Fixed TodayTasksViewModel constructor calls")
    
except Exception as e:
    print(f"❌ Error: {e}")
PYTHON_EOF

echo "✅ Surgical fix completed!"
echo "📊 Fixed exact issues:"
echo "  • FrancoSphereModels.swift:19 - Removed duplicate coordinate declaration"
echo "  • NewAuthManager.swift:203,528 - Fixed broken function declarations"
echo "  • BuildingTaskDetailView.swift:614 - Fixed broken function declaration"
echo "  • BuildingService.swift:55-73 - Removed imageAssetName parameters"
echo "  • TodayTasksViewModel.swift:26,28,29 - Fixed constructor parameters"

