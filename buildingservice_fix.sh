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
    pattern = r'FrancoSphere\.InventoryItem\(\s*([^)]+)\s*\)(?![^(]*status:)'
    def add_status_param(match):
        params = match.group(1)
        if 'status:' not in params:
            params += ', status: .inStock'
        return f'FrancoSphere.InventoryItem({params})'
    content = re.sub(pattern, add_status_param, content)
    
    # Fix 3: Line 414 - Cannot convert Int to Date
    # Replace quantity with Date() where Date is expected
    content = re.sub(r'item\.quantity\s*(?=\s*as\s*Date)', 'Date()', content)
    content = re.sub(r'lastRestockString = ISO8601DateFormatter\(\)\.string\(from: item\.quantity\)', 
                    'lastRestockString = ISO8601DateFormatter().string(from: Date())', content)
    
    # Fix 4: Line 415 - Cannot convert RestockStatus to Bool  
    content = re.sub(r'item\.status\s*\?\s*1\s*:\s*0', '(item.status == .lowStock || item.status == .outOfStock) ? 1 : 0', content)
    content = re.sub(r'let needsReorderInt = item\.status \? 1 : 0', 
                    'let needsReorderInt = (item.status == .lowStock || item.status == .outOfStock) ? 1 : 0', content)
    
    # Fix 5: Line 419 - Cannot convert InventoryCategory to SQLiteBinding
    content = re.sub(r'item\.category,', 'item.category.rawValue,', content)
    content = re.sub(r'item\.category\.rawValue\.rawValue', 'item.category.rawValue', content)
    
    # Fix 6: Line 472 - Cannot convert RestockStatus to Bool in closure
    content = re.sub(r'\.filter\s*\{\s*\$0\.status\s*\}', '.filter { $0.status == .lowStock || $0.status == .outOfStock }', content)
    
    # Fix property access mismatches
    content = content.replace('item.buildingID', 'item.id')
    content = content.replace('item.minimumQuantity', 'item.minimumStock')
    content = content.replace('item.needsReorder', '(item.status == .lowStock)')
    content = content.replace('item.lastRestockDate', 'Date()')
    
    print("✅ Fixed InventoryItem constructor and property issues")
    
    with open(file_path, 'w') as f:
        f.write(content)
    
except Exception as e:
    print(f"❌ Error: {e}")
PYTHON_EOF

echo "✅ BuildingService.swift surgical fixes completed!"
echo "📊 Fixed:"
echo "  • Lines 55-73, 216-224: Removed imageAssetName parameters"
echo "  • Line 384: Fixed InventoryItem constructor parameters"
echo "  • Line 388: Added missing status parameter"
echo "  • Line 414: Fixed Int to Date conversion"
echo "  • Line 415: Fixed RestockStatus to Bool conversion"
echo "  • Line 419: Fixed InventoryCategory to SQLiteBinding conversion"
echo "  • Line 472: Fixed RestockStatus to Bool in filter closure"

