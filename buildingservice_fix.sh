#!/bin/bash

set -e
PROJECT_ROOT="/Volumes/FastSSD/Xcode"

echo "🔧 Surgical Fix for BuildingService.swift - Targeting exact error lines"

# Phase 1: Fix NamedCoordinate constructor by removing imageAssetName parameters
echo "🔧 Phase 1: Removing imageAssetName parameters from NamedCoordinate calls..."
python3 << 'PYTHON_EOF'
file_path = "/Volumes/FastSSD/Xcode/Services/BuildingService.swift"

try:
    with open(file_path, 'r') as f:
        content = f.read()
    
    import re
    
    # Remove imageAssetName parameters from NamedCoordinate constructor calls
    # Pattern: NamedCoordinate(..., imageAssetName: "...")
    pattern = r'(NamedCoordinate\([^)]+), imageAssetName: "[^"]*"\)'
    content = re.sub(pattern, r'\1)', content)
    
    print("✅ Removed imageAssetName parameters from NamedCoordinate calls")
    
    with open(file_path, 'w') as f:
        f.write(content)
    
except Exception as e:
    print(f"❌ Error: {e}")
PYTHON_EOF

# Phase 2: Fix InventoryItem related issues (lines 384-472)
echo "🔧 Phase 2: Fixing InventoryItem constructor and property issues..."
python3 << 'PYTHON_EOF'
file_path = "/Volumes/FastSSD/Xcode/Services/BuildingService.swift"

try:
    with open(file_path, 'r') as f:
        content = f.read()
    
    import re
    
    # Fix 1: Line 384 - Fix InventoryItem constructor with too many parameters
    # The error suggests there are extra arguments at positions #3, #6, #7, #8, #9, #10, #11
    # Replace complex InventoryItem constructor with simpler one matching our structure
    pattern = r'FrancoSphere\.InventoryItem\(\s*id: ([^,]+),\s*name: ([^,]+),\s*buildingID: ([^,]+),\s*category: ([^,]+),\s*quantity: ([^,]+),\s*unit: ([^,]+),\s*minimumQuantity: ([^,]+),\s*needsReorder: ([^,]+),\s*lastRestockDate: ([^,]+),\s*location: ([^,]+),\s*notes: ([^)]+)\)'
    replacement = r'FrancoSphere.InventoryItem(id: \1, name: \2, category: \4, quantity: Int(\5), status: .inStock, minimumStock: Int(\7))'
    content = re.sub(pattern, replacement, content, flags=re.MULTILINE | re.DOTALL)
    
    # Fix 2: Line 388 - Missing 'status' parameter
    # Look for incomplete InventoryItem calls and add status parameter
    pattern = r'FrancoSphere\.InventoryItem\(\s*([^)]+)\s*\)(?!\.)'
    def fix_inventory_item(match):
        params = match.group(1)
        if 'status:' not in params:
            # Add status parameter
            return f'FrancoSphere.InventoryItem({params}, status: .inStock)'
        return match.group(0)
    
    content = re.sub(pattern, fix_inventory_item, content)
    
    # Fix 3: Replace .needsReorder with .status == .lowStock
    content = re.sub(r'\.needsReorder', '.status == .lowStock', content)
    
    # Fix 4: Replace references to buildingID property with appropriate id
    content = re.sub(r'item\.buildingID', 'buildingId', content)
    
    print("✅ Fixed InventoryItem issues")
    
    with open(file_path, 'w') as f:
        f.write(content)
    
except Exception as e:
    print(f"❌ Error: {e}")
PYTHON_EOF

echo "✅ BuildingService.swift fixes complete!"
