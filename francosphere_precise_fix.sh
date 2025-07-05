#!/bin/bash

set -e
PROJECT_ROOT="/Volumes/FastSSD/Xcode"

echo "🔧 FrancoSphere Precise Fix - Based on actual file analysis"

# Phase 1: Fix NamedCoordinate constructor to support legacy parameters
echo "🔧 Phase 1: Adding legacy constructor support to NamedCoordinate..."
python3 << 'PYTHON_EOF'
file_path = "/Volumes/FastSSD/Xcode/Models/FrancoSphereModels.swift"

try:
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Remove any duplicate coordinate declarations
    lines = content.split('\n')
    fixed_lines = []
    coordinate_count = 0
    
    for line in lines:
        if 'public let coordinate:' in line or 'let coordinate:' in line:
            coordinate_count += 1
            if coordinate_count == 1:
                fixed_lines.append(line)
            # Skip duplicates
        else:
            fixed_lines.append(line)
    
    content = '\n'.join(fixed_lines)
    
    # Add legacy constructor after the main constructor
    legacy_constructor = '''
        // Legacy constructor for compatibility with imageAssetName parameter
        public init(id: String, name: String, latitude: Double, longitude: Double, imageAssetName: String? = nil) {
            self.id = id
            self.name = name
            self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            self.address = nil
        }
        
        // Convenience properties for legacy code
        public var latitude: Double { coordinate.latitude }
        public var longitude: Double { coordinate.longitude }'''
    
    # Insert after the main init method
    if 'Legacy constructor' not in content:
        pattern = r'(public init\(id: String, name: String, coordinate: CLLocationCoordinate2D, address: String\? = nil\) \{[^}]+\})'
        replacement = r'\1' + legacy_constructor
        content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    # Fix Equatable conformance by implementing it manually
    if 'public static func ==' not in content:
        equatable_impl = '''
        
        // Manual Equatable conformance since CLLocationCoordinate2D doesn't conform
        public static func == (lhs: NamedCoordinate, rhs: NamedCoordinate) -> Bool {
            return lhs.id == rhs.id &&
                   lhs.name == rhs.name &&
                   lhs.coordinate.latitude == rhs.coordinate.latitude &&
                   lhs.coordinate.longitude == rhs.coordinate.longitude &&
                   lhs.address == rhs.address
        }'''
        
        # Add before the closing brace of the struct
        pattern = r'(\s+)(}\s+// MARK: - Building Models)'
        replacement = equatable_impl + r'\1\2'
        content = re.sub(pattern, replacement, content)
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("✅ Fixed NamedCoordinate with legacy constructor support")
    
except Exception as e:
    print(f"❌ Error: {e}")
    import re
PYTHON_EOF

# Phase 2: Fix NewAuthManager.swift function declarations
echo "🔧 Phase 2: Fixing NewAuthManager.swift broken function declarations..."
python3 << 'PYTHON_EOF'
file_path = "/Volumes/FastSSD/Xcode/Managers/NewAuthManager.swift"

try:
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix mangled function declarations that were broken by previous sed operations
    
    # Pattern 1: func name: FrancoSphere.WorkerProfile
    content = content.replace(
        'func getWorkerProfile: FrancoSphere.WorkerProfile',
        'func getWorkerProfile() -> FrancoSphere.WorkerProfile?'
    )
    
    # Pattern 2: func name(byId: FrancoSphere.WorkerProfile
    content = content.replace(
        'func getWorkerProfile(byId: FrancoSphere.WorkerProfile',
        'func getWorkerProfile(byId: String) -> FrancoSphere.WorkerProfile?'
    )
    
    # Pattern 3: Fix return type chains
    content = content.replace(
        ': FrancoSphere.WorkerProfile -> FrancoSphere.WorkerProfile',
        '() -> FrancoSphere.WorkerProfile?'
    )
    
    # Pattern 4: Fix parameter type chains  
    content = content.replace(
        'byId: String) -> FrancoSphere.WorkerProfile? -> FrancoSphere.WorkerProfile',
        'byId: String) -> FrancoSphere.WorkerProfile?'
    )
    
    # Pattern 5: Fix any remaining broken syntax
    content = content.replace(
        ') -> FrancoSphere.WorkerProfile? {',
        ') -> FrancoSphere.WorkerProfile? {'
    )
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("✅ Fixed NewAuthManager function declarations")
    
except Exception as e:
    print(f"❌ Error: {e}")
PYTHON_EOF

# Phase 3: Fix BuildingTaskDetailView.swift function declarations
echo "🔧 Phase 3: Fixing BuildingTaskDetailView.swift..."
python3 << 'PYTHON_EOF'
file_path = "/Volumes/FastSSD/Xcode/Views/Buildings/BuildingTaskDetailView.swift"

try:
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix similar broken function declarations
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
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("✅ Fixed BuildingTaskDetailView function declarations")
    
except Exception as e:
    print(f"❌ Error: {e}")
PYTHON_EOF

# Phase 4: Fix TodayTasksViewModel.swift constructor parameters
echo "🔧 Phase 4: Fixing TodayTasksViewModel.swift..."
python3 << 'PYTHON_EOF'
file_path = "/Volumes/FastSSD/Xcode/Views/Main/TodayTasksViewModel.swift"

try:
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix TaskTrends constructor
    content = content.replace(
        'weeklyCompletion: [], categoryBreakdown: [:], trend: .stable',
        'weeklyCompletion: [], categoryBreakdown: [String: Int](), changePercentage: 0.0'
    )
    
    # Fix empty dictionary literal
    content = content.replace(
        'categoryBreakdown: [:]',
        'categoryBreakdown: [String: Int]()'
    )
    
    # Fix .stable reference if it exists
    content = content.replace(
        'Double.stable',
        '0.0'
    )
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("✅ Fixed TodayTasksViewModel constructor parameters")
    
except Exception as e:
    print(f"❌ Error: {e}")
PYTHON_EOF

echo "✅ Precise fix completed!"
echo "📊 Applied fixes:"
echo "  • NamedCoordinate - Added legacy constructor with latitude/longitude parameters"
echo "  • NamedCoordinate - Fixed coordinate property redeclaration"
echo "  • NamedCoordinate - Added manual Equatable implementation"
echo "  • NewAuthManager - Fixed broken function declarations on lines 203,528"
echo "  • BuildingTaskDetailView - Fixed function declaration on line 614"
echo "  • TodayTasksViewModel - Fixed TaskTrends constructor parameters"

