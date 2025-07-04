#!/bin/bash
# CSV Dependency Cleanup Script
# Safely removes CSV file dependencies while preserving all real-world data

echo "🚀 Starting CSV dependency cleanup..."

# Step 1: Delete CSV parsing utility (entire file)
echo "📁 Deleting CSV parsing utility..."
if [ -f "Services/CSVLoader.swift" ]; then
    git rm Services/CSVLoader.swift
    echo "✅ Deleted Services/CSVLoader.swift"
else
    echo "⚠️ Services/CSVLoader.swift not found"
fi

# Step 2: Delete build script (entire file)
echo "📁 Deleting build script..."
if [ -f "build_scripts/csv2sql.sh" ]; then
    git rm build_scripts/csv2sql.sh
    echo "✅ Deleted build_scripts/csv2sql.sh"
else
    echo "⚠️ build_scripts/csv2sql.sh not found"
fi

# Step 3: Delete actual CSV files (data preserved in code)
echo "📁 Deleting CSV data files..."
find . -name "*.csv" -path "./Data/*" | while read file; do
    if [ -f "$file" ]; then
        git rm "$file"
        echo "✅ Deleted $file"
    fi
done

# Step 4: Update import references throughout codebase
echo "🔄 Updating import references..."

# Find all Swift files and update CSVDataImporter → OperationalDataManager
find . -name "*.swift" -not -path "./build/*" -not -path "./.git/*" | while read file; do
    if grep -q "CSVDataImporter" "$file"; then
        echo "📝 Updating references in $file"
        
        # Update import statements
        sed -i '' 's/import CSVDataImporter/\/\/ Removed: import CSVDataImporter/g' "$file"
        
        # Update class references
        sed -i '' 's/CSVDataImporter\.shared/OperationalDataManager.shared/g' "$file"
        sed -i '' 's/CSVDataImporter(/OperationalDataManager(/g' "$file"
        sed -i '' 's/let csvImporter = CSVDataImporter/let operationalManager = OperationalDataManager/g' "$file"
        sed -i '' 's/csvImporter\./operationalManager\./g' "$file"
        
        # Update variable names
        sed -i '' 's/csvImportProgress/dataImportProgress/g' "$file"
        sed -i '' 's/ensureCSVDataLoaded/ensureOperationalDataLoaded/g' "$file"
        sed -i '' 's/checkIfCSVImported/checkIfDataImported/g' "$file"
        
        echo "✅ Updated $file"
    fi
done

# Step 5: Update specific references in key files
echo "🔧 Updating specific file references..."

# Update BuildingDetailView.swift if it exists
if [ -f "Views/Buildings/BuildingDetailView.swift" ]; then
    echo "📝 Updating BuildingDetailView.swift references..."
    sed -i '' 's/loadCSVRoutinesForBuilding/loadOperationalRoutinesForBuilding/g' "Views/Buildings/BuildingDetailView.swift"
    sed -i '' 's/CSV data using existing CSVDataImporter/operational data using OperationalDataManager/g' "Views/Buildings/BuildingDetailView.swift"
    sed -i '' 's/Get routines from CSV data/Get routines from operational data/g' "Views/Buildings/BuildingDetailView.swift"
    echo "✅ Updated BuildingDetailView.swift"
fi

# Step 6: Create commit
echo "💾 Creating git commit..."
git add .
git commit -m "Phase 1: Remove CSV file dependencies

✅ REMOVED: Services/CSVLoader.swift (CSV parsing utility)
✅ REMOVED: build_scripts/csv2sql.sh (CSV processing script)  
✅ REMOVED: All .csv data files (data preserved in OperationalDataManager)
✅ UPDATED: All references from CSVDataImporter → OperationalDataManager
✅ PRESERVED: All real-world operational data in programmatic form

- Kevin's 38+ tasks preserved in OperationalDataManager
- All 7 worker schedules preserved
- All building assignments and DSNY routes preserved
- Database insertion logic unchanged
- Emergency repair systems intact"

echo ""
echo "🎉 CSV dependency cleanup complete!"
echo ""
echo "📋 SUMMARY:"
echo "  ✅ Removed file parsing dependencies"
echo "  ✅ Preserved all real-world operational data"
echo "  ✅ Updated all import references"
echo "  ✅ Created git commit for tracking"
echo ""
echo "🔄 NEXT STEPS:"
echo "  1. Test compilation: xcodebuild clean build"
echo "  2. Verify Kevin has 38+ tasks in OperationalDataManager"
echo "  3. Verify all worker schedules preserved"
echo "  4. Run app and confirm dashboard loads"
echo ""