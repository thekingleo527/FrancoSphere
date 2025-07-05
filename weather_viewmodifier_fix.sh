#!/bin/bash

echo "🔧 WeatherViewModifier Targeted Fix"
echo "==================================="
echo "Fixing ONLY 3 specific WeatherViewModifier errors"

cd "/Volumes/FastSSD/Xcode" || exit 1

FILE="Components/Shared Components/WeatherViewModifier.swift"

if [ ! -f "$FILE" ]; then
    echo "❌ File not found: $FILE"
    exit 1
fi

# Temporary backup (will self-delete)
BACKUP="${FILE}.temp_$(date +%s)"
cp "$FILE" "$BACKUP"

echo "🔧 Fixing 3 specific errors in WeatherViewModifier.swift..."

# Fix 1: Line 96 - Add formattedTemperature property to WeatherData
echo "  • Adding formattedTemperature extension..."
cat >> "Models/FrancoSphereModels.swift" << 'EXTENSION_EOF'

// MARK: - WeatherData Extension for UI
extension FrancoSphere.WeatherData {
    public var formattedTemperature: String {
        return "\(Int(temperature))°"
    }
}
EXTENSION_EOF

# Fix 2: Line 120 - Replace .thunderstorm with existing enum case
echo "  • Fixing .thunderstorm reference..."
sed -i.tmp 's/\.thunderstorm/.stormy/g' "$FILE"

# Fix 3: Line 124 - Replace .other with existing enum case  
echo "  • Fixing .other reference..."
sed -i.tmp 's/\.other/.cloudy/g' "$FILE"

# Clean up sed temp files
rm -f "${FILE}.tmp"

echo ""
echo "🔨 Testing WeatherViewModifier.swift compilation..."
BUILD_OUTPUT=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build -destination "platform=iOS Simulator,name=iPhone 15 Pro" 2>&1)

# Check specifically for WeatherViewModifier errors
WEATHER_ERRORS=$(echo "$BUILD_OUTPUT" | grep "WeatherViewModifier.swift.*error" | wc -l | tr -d ' ')

echo "📊 WeatherViewModifier.swift errors: $WEATHER_ERRORS"

if [ "$WEATHER_ERRORS" -eq 0 ]; then
    echo "✅ SUCCESS: WeatherViewModifier.swift errors resolved"
    echo "🗑️  Cleaning up..."
    rm -f "$BACKUP"
    echo "🎯 RESULT: 3 targeted errors fixed, no cascading effects"
else
    echo "❌ ERRORS REMAIN in WeatherViewModifier.swift:"
    echo "$BUILD_OUTPUT" | grep "WeatherViewModifier.swift.*error"
    echo "📂 Backup preserved: $BACKUP"
fi

exit 0
