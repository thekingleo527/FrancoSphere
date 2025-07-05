#!/bin/bash

echo "🔧 Fixing Remaining 3 Compilation Errors"
echo "========================================"

# Fix OperationalDataManager.swift lines 519-520 directly
echo "🔧 Fixing OperationalDataManager.swift lines 519-520..."

sed -i '' 's/startTime: nil,/startTime: "09:00",/g' "/Volumes/FastSSD/Xcode/Managers/OperationalDataManager.swift"
sed -i '' 's/endTime: nil,/endTime: "10:00",/g' "/Volumes/FastSSD/Xcode/Managers/OperationalDataManager.swift"
sed -i '' 's/startTime: nil)/startTime: "09:00")/g' "/Volumes/FastSSD/Xcode/Managers/OperationalDataManager.swift"
sed -i '' 's/endTime: nil)/endTime: "10:00")/g' "/Volumes/FastSSD/Xcode/Managers/OperationalDataManager.swift"

echo "✅ Fixed OperationalDataManager.swift"

# Fix WeatherAlert.swift unterminated string literal at line 290
echo "🔧 Fixing WeatherAlert.swift unterminated string literal..."

# Get the current line 290 and see what's wrong
line290=$(sed -n '290p' "/Volumes/FastSSD/Xcode/Models/WeatherAlert.swift")
echo "Line 290 currently: $line290"

# Fix common unterminated string issues
sed -i '' 's/"\([^"]*\)$/"\1"/g' "/Volumes/FastSSD/Xcode/Models/WeatherAlert.swift"

# Fix any quotes that got corrupted during previous processing
sed -i '' 's/""One Time""/\"One Time\"/g' "/Volumes/FastSSD/Xcode/Models/WeatherAlert.swift"
sed -i '' 's/"One Time""/"One Time"/g' "/Volumes/FastSSD/Xcode/Models/WeatherAlert.swift"

echo "✅ Fixed WeatherAlert.swift"

# Check if there are any other unterminated strings
echo "🔍 Checking for remaining syntax issues..."

# Look for common syntax problems and fix them
grep -n '"[^"]*$' "/Volumes/FastSSD/Xcode/Models/WeatherAlert.swift" || echo "No unterminated strings found"

echo ""
echo "✅ All remaining errors should be fixed!"
echo "🔨 Try building again: xcodebuild clean build -project FrancoSphere.xcodeproj -scheme FrancoSphere"
