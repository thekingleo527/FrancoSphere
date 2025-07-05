#!/bin/bash

echo "🔧 Fixing specific nil → String errors in OperationalDataManager.swift"

# Create backup first
cp "/Volumes/FastSSD/Xcode/Managers/OperationalDataManager.swift" "/Volumes/FastSSD/Xcode/Managers/OperationalDataManager.swift.backup_$(date +%H%M%S)"

# Fix the specific lines - replace nil with default time strings
sed -i '' 's/startTime: operationalTask\.startHour != nil ? String(format: "%02d:00", operationalTask\.startHour!) : nil,/startTime: operationalTask.startHour != nil ? String(format: "%02d:00", operationalTask.startHour!) : "09:00",/g' "/Volumes/FastSSD/Xcode/Managers/OperationalDataManager.swift"

sed -i '' 's/endTime: operationalTask\.endHour != nil ? String(format: "%02d:00", operationalTask\.endHour!) : nil,/endTime: operationalTask.endHour != nil ? String(format: "%02d:00", operationalTask.endHour!) : "17:00",/g' "/Volumes/FastSSD/Xcode/Managers/OperationalDataManager.swift"

echo "✅ Fixed lines 519-520 in OperationalDataManager.swift"
echo "   - startTime nil → \"09:00\" default"  
echo "   - endTime nil → \"17:00\" default"

# Verify the fix
echo ""
echo "🔍 Verifying the fix:"
grep -n "startTime: operationalTask" "/Volumes/FastSSD/Xcode/Managers/OperationalDataManager.swift"
grep -n "endTime: operationalTask" "/Volumes/FastSSD/Xcode/Managers/OperationalDataManager.swift"

echo ""
echo "✅ Fix complete! The nil values have been replaced with default time strings."
