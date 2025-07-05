#!/bin/bash
set -e

echo "🔧 Precise Line-by-Line Error Fixes"
echo "===================================="

cd "/Volumes/FastSSD/Xcode" || exit 1

# Create backups
TIMESTAMP=$(date +%s)
cp "Components/Shared Components/HeroStatusCard.swift" "Components/Shared Components/HeroStatusCard.swift.precise_backup.$TIMESTAMP"
cp "Models/FrancoSphereModels.swift" "Models/FrancoSphereModels.swift.precise_backup.$TIMESTAMP"
cp "Views/Main/WorkerProfileView.swift" "Views/Main/WorkerProfileView.swift.precise_backup.$TIMESTAMP"

echo "📦 Backups created with timestamp: $TIMESTAMP"

# =============================================================================
# FIX HEROSTATUSCARD.SWIFT - EXACT LINES
# =============================================================================

echo ""
echo "🔧 Fixing HeroStatusCard.swift specific lines..."

# Fix Line 188: Extra arguments and missing arguments
sed -i '' '188c\
        HeroStatusCard(' "Components/Shared Components/HeroStatusCard.swift"

# Fix Line 197: Expected ',' separator  
sed -i '' '197c\
            ,' "Components/Shared Components/HeroStatusCard.swift"

# Fix Line 201: Consecutive statements and expected expression
sed -i '' '201c\
            onClockInTap: { print("Clock in tapped") }' "Components/Shared Components/HeroStatusCard.swift"

# Fix Line 209: Labeled block needs 'do'
sed -i '' '209c\
        }' "Components/Shared Components/HeroStatusCard.swift"

# Fix Line 210: Expected expression
sed -i '' '210c\
    }' "Components/Shared Components/HeroStatusCard.swift"

echo "✅ Fixed HeroStatusCard.swift lines 188, 197, 201, 209, 210"

# =============================================================================
# FIX FRANCOSPHEREMODELS.SWIFT - EXACT LINES  
# =============================================================================

echo ""
echo "🔧 Fixing FrancoSphereModels.swift specific lines..."

# Fix Line 22: Invalid redeclaration of 'coordinate'
sed -i '' '22c\
        // Fixed: removed duplicate coordinate' "Models/FrancoSphereModels.swift"

# Fix Line 27: Initializers may only be declared within a type
sed -i '' '27c\
        public init(id: String, name: String, latitude: Double, longitude: Double, address: String? = nil, imageAssetName: String? = nil) {' "Models/FrancoSphereModels.swift"

# Fix Line 35: Extraneous '}' at top level
sed -i '' '35c\
        }' "Models/FrancoSphereModels.swift"

# Fix Line 290: Invalid redeclaration of 'TrendDirection'
sed -i '' '290,297c\
    // Fixed: removed duplicate TrendDirection enum' "Models/FrancoSphereModels.swift"

# Fix Line 312: TaskTrends conformance issues
sed -i '' '312c\
    public struct TaskTrends: Codable, Equatable {' "Models/FrancoSphereModels.swift"

# Fix Line 317: TrendDirection ambiguity  
sed -i '' '317c\
        public let trend: FrancoSphere.TrendDirection' "Models/FrancoSphereModels.swift"

# Fix Line 319: TrendDirection ambiguity
sed -i '' '319c\
        public init(weeklyCompletion: Double, categoryBreakdown: [String: Int], changePercentage: Double, comparisonPeriod: String, trend: FrancoSphere.TrendDirection) {' "Models/FrancoSphereModels.swift"

echo "✅ Fixed FrancoSphereModels.swift lines 22, 27, 35, 290, 312, 317, 319"

# =============================================================================
# FIX WORKERPROFILEVIEW.SWIFT - EXACT LINE
# =============================================================================

echo ""
echo "🔧 Fixing WorkerProfileView.swift specific line..."

# Fix Line 359: TrendDirection ambiguity
sed -i '' '359c\
                                trend: FrancoSphere.TrendDirection.up' "Views/Main/WorkerProfileView.swift"

echo "✅ Fixed WorkerProfileView.swift line 359"

# =============================================================================
# VERIFICATION - Show fixed lines
# =============================================================================

echo ""
echo "🔍 VERIFICATION: Checking each fixed line..."

echo ""
echo "HeroStatusCard.swift Line 188:"
sed -n '188p' "Components/Shared Components/HeroStatusCard.swift"

echo "HeroStatusCard.swift Line 197:"
sed -n '197p' "Components/Shared Components/HeroStatusCard.swift"

echo "HeroStatusCard.swift Line 201:"
sed -n '201p' "Components/Shared Components/HeroStatusCard.swift"

echo ""
echo "FrancoSphereModels.swift Line 22:"
sed -n '22p' "Models/FrancoSphereModels.swift"

echo "FrancoSphereModels.swift Line 27:"
sed -n '27p' "Models/FrancoSphereModels.swift"

echo "FrancoSphereModels.swift Line 35:"
sed -n '35p' "Models/FrancoSphereModels.swift"

echo ""
echo "WorkerProfileView.swift Line 359:"
sed -n '359p' "Views/Main/WorkerProfileView.swift"

# =============================================================================
# BUILD TEST
# =============================================================================

echo ""
echo "🔨 Testing compilation..."

BUILD_OUTPUT=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build -destination "platform=iOS Simulator,name=iPhone 15 Pro" 2>&1)

# Count specific errors that were targeted
HEROSTATUSCARD_188=$(echo "$BUILD_OUTPUT" | grep -c "HeroStatusCard.swift:188.*Extra arguments" || echo "0")
HEROSTATUSCARD_197=$(echo "$BUILD_OUTPUT" | grep -c "HeroStatusCard.swift:197.*Expected.*separator" || echo "0")
HEROSTATUSCARD_201=$(echo "$BUILD_OUTPUT" | grep -c "HeroStatusCard.swift:201.*Consecutive statements" || echo "0")
HEROSTATUSCARD_209=$(echo "$BUILD_OUTPUT" | grep -c "HeroStatusCard.swift:209.*Labeled block" || echo "0")
HEROSTATUSCARD_210=$(echo "$BUILD_OUTPUT" | grep -c "HeroStatusCard.swift:210.*Expected expression" || echo "0")

MODELS_22=$(echo "$BUILD_OUTPUT" | grep -c "FrancoSphereModels.swift:22.*Invalid redeclaration.*coordinate" || echo "0")
MODELS_27=$(echo "$BUILD_OUTPUT" | grep -c "FrancoSphereModels.swift:27.*Initializers may only" || echo "0")
MODELS_35=$(echo "$BUILD_OUTPUT" | grep -c "FrancoSphereModels.swift:35.*Extraneous" || echo "0")
MODELS_290=$(echo "$BUILD_OUTPUT" | grep -c "FrancoSphereModels.swift:290.*Invalid redeclaration.*TrendDirection" || echo "0")
MODELS_312=$(echo "$BUILD_OUTPUT" | grep -c "FrancoSphereModels.swift:312.*TaskTrends.*not conform" || echo "0")
MODELS_317=$(echo "$BUILD_OUTPUT" | grep -c "FrancoSphereModels.swift:317.*TrendDirection.*ambiguous" || echo "0")
MODELS_319=$(echo "$BUILD_OUTPUT" | grep -c "FrancoSphereModels.swift:319.*TrendDirection.*ambiguous" || echo "0")

WORKER_359=$(echo "$BUILD_OUTPUT" | grep -c "WorkerProfileView.swift:359.*TrendDirection.*ambiguous" || echo "0")

TOTAL_TARGETED=$((HEROSTATUSCARD_188 + HEROSTATUSCARD_197 + HEROSTATUSCARD_201 + HEROSTATUSCARD_209 + HEROSTATUSCARD_210 + MODELS_22 + MODELS_27 + MODELS_35 + MODELS_290 + MODELS_312 + MODELS_317 + MODELS_319 + WORKER_359))
TOTAL_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c " error:" || echo "0")

echo ""
echo "📊 PRECISE FIX RESULTS"
echo "======================"
echo ""
echo "🎯 Targeted line fixes:"
echo "• HeroStatusCard:188 (Extra arguments): $HEROSTATUSCARD_188 remaining"
echo "• HeroStatusCard:197 (Separator): $HEROSTATUSCARD_197 remaining" 
echo "• HeroStatusCard:201 (Consecutive): $HEROSTATUSCARD_201 remaining"
echo "• HeroStatusCard:209 (Labeled block): $HEROSTATUSCARD_209 remaining"
echo "• HeroStatusCard:210 (Expression): $HEROSTATUSCARD_210 remaining"
echo "• FrancoSphereModels:22 (coordinate): $MODELS_22 remaining"
echo "• FrancoSphereModels:27 (Initializer): $MODELS_27 remaining"
echo "• FrancoSphereModels:35 (Brace): $MODELS_35 remaining"
echo "• FrancoSphereModels:290 (TrendDirection): $MODELS_290 remaining"
echo "• FrancoSphereModels:312 (TaskTrends): $MODELS_312 remaining"
echo "• FrancoSphereModels:317 (Ambiguous): $MODELS_317 remaining"
echo "• FrancoSphereModels:319 (Ambiguous): $MODELS_319 remaining"
echo "• WorkerProfileView:359 (Ambiguous): $WORKER_359 remaining"
echo ""
echo "📈 SUMMARY:"
echo "• Targeted errors fixed: $((13 - TOTAL_TARGETED))/13"
echo "• Total compilation errors: $TOTAL_ERRORS"

if [[ $TOTAL_TARGETED -eq 0 ]]; then
    echo ""
    echo "🟢 ✅ ALL TARGETED LINES FIXED!"
    echo "==============================="
    if [[ $TOTAL_ERRORS -eq 0 ]]; then
        echo "🎉 Perfect build - 0 compilation errors!"
    else
        echo "⚠️  $TOTAL_ERRORS other errors remain"
    fi
elif [[ $TOTAL_TARGETED -lt 5 ]]; then
    echo ""
    echo "🟡 ✅ MAJOR SUCCESS!"
    echo "==================="
    echo "📉 Most targeted lines fixed"
    echo "⚠️  $TOTAL_TARGETED targeted errors remain"
else
    echo ""
    echo "🔴 ⚠️  NEED REVIEW"
    echo "=================="
    echo "❌ $TOTAL_TARGETED targeted errors remain"
fi

echo ""
echo "🎯 PRECISE LINE FIXES COMPLETE"
echo "==============================="

exit 0
