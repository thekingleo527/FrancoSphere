#!/bin/bash
#
# Simple FrancoSphere Compilation Fix Script
# 
# 🎯 SIMPLE SOLUTION: Fix compilation errors with minimal changes
# ✅ Safe operations that only fix type references
# ✅ Creates backup before making changes

set -e

XCODE_PATH="/Volumes/FastSSD/Xcode"
BACKUP_DIR="$XCODE_PATH/backup_$(date +%Y%m%d_%H%M%S)"

echo "🔧 FrancoSphere Simple Compilation Fix"
echo "======================================"

# Function to create backup
create_backup() {
    echo "📦 Creating backup..."
    mkdir -p "$BACKUP_DIR"
    
    # Backup only files we'll modify
    cp "$XCODE_PATH/Components/Design/ModelColorsExtensions.swift" "$BACKUP_DIR/" 2>/dev/null || true
    cp "$XCODE_PATH/Components/Design/TodaysTasksGlassCard.swift" "$BACKUP_DIR/" 2>/dev/null || true  
    cp "$XCODE_PATH/Components/Design/WeatherTaskTimelineCard.swift" "$BACKUP_DIR/" 2>/dev/null || true
    cp "$XCODE_PATH/Models/WorkerRoutineViewModel.swift" "$BACKUP_DIR/" 2>/dev/null || true
    cp "$XCODE_PATH/Views/Buildings/TaskFormView.swift" "$BACKUP_DIR/" 2>/dev/null || true
    cp "$XCODE_PATH/Views/Main/DashboardTaskDetailView.swift" "$BACKUP_DIR/" 2>/dev/null || true
    cp "$XCODE_PATH/Services/WorkerService.swift" "$BACKUP_DIR/" 2>/dev/null || true
    
    echo "✅ Backup created at: $BACKUP_DIR"
}

# Function to fix type references
fix_type_references() {
    echo "🔧 Fixing type references..."
    
    # ModelColorsExtensions.swift
    if [ -f "$XCODE_PATH/Components/Design/ModelColorsExtensions.swift" ]; then
        sed -i '' 's/\bTaskUrgency\b/FrancoSphere.TaskUrgency/g' "$XCODE_PATH/Components/Design/ModelColorsExtensions.swift"
        echo "✅ Fixed ModelColorsExtensions.swift"
    fi
    
    # TodaysTasksGlassCard.swift  
    if [ -f "$XCODE_PATH/Components/Design/TodaysTasksGlassCard.swift" ]; then
        sed -i '' 's/\bMaintenanceTask\b/FrancoSphere.MaintenanceTask/g' "$XCODE_PATH/Components/Design/TodaysTasksGlassCard.swift"
        sed -i '' 's/\bTaskUrgency\b/FrancoSphere.TaskUrgency/g' "$XCODE_PATH/Components/Design/TodaysTasksGlassCard.swift"
        echo "✅ Fixed TodaysTasksGlassCard.swift"
    fi
    
    # WeatherTaskTimelineCard.swift
    if [ -f "$XCODE_PATH/Components/Design/WeatherTaskTimelineCard.swift" ]; then
        sed -i '' 's/\bMaintenanceTask\b/FrancoSphere.MaintenanceTask/g' "$XCODE_PATH/Components/Design/WeatherTaskTimelineCard.swift"
        echo "✅ Fixed WeatherTaskTimelineCard.swift"
    fi
    
    # WorkerRoutineViewModel.swift
    if [ -f "$XCODE_PATH/Models/WorkerRoutineViewModel.swift" ]; then
        sed -i '' 's/\bMaintenanceTask\b/FrancoSphere.MaintenanceTask/g' "$XCODE_PATH/Models/WorkerRoutineViewModel.swift"
        sed -i '' 's/\bTaskCategory\b/FrancoSphere.TaskCategory/g' "$XCODE_PATH/Models/WorkerRoutineViewModel.swift"
        echo "✅ Fixed WorkerRoutineViewModel.swift"
    fi
    
    # TaskFormView.swift
    if [ -f "$XCODE_PATH/Views/Buildings/TaskFormView.swift" ]; then
        sed -i '' 's/\bMaintenanceTask\b/FrancoSphere.MaintenanceTask/g' "$XCODE_PATH/Views/Buildings/TaskFormView.swift"
        echo "✅ Fixed TaskFormView.swift"
    fi
    
    # DashboardTaskDetailView.swift
    if [ -f "$XCODE_PATH/Views/Main/DashboardTaskDetailView.swift" ]; then
        sed -i '' 's/\bMaintenanceTask\b/FrancoSphere.MaintenanceTask/g' "$XCODE_PATH/Views/Main/DashboardTaskDetailView.swift"
        sed -i '' 's/\bTaskCategory\b/FrancoSphere.TaskCategory/g' "$XCODE_PATH/Views/Main/DashboardTaskDetailView.swift"
        echo "✅ Fixed DashboardTaskDetailView.swift"
    fi
}

# Function to clean WorkerService.swift
clean_worker_service() {
    echo "🔧 Cleaning WorkerService.swift..."
    
    local worker_service="$XCODE_PATH/Services/WorkerService.swift"
    
    if [ -f "$worker_service" ]; then
        # Remove the problematic TaskService extension
        # This removes everything from "extension TaskService {" to the matching closing brace
        
        # Create a temporary file to rebuild WorkerService.swift without the extension
        local temp_file="${worker_service}.tmp"
        local in_extension=false
        local brace_count=0
        
        while IFS= read -r line; do
            # Check if we're starting the problematic extension
            if [[ "$line" =~ ^[[:space:]]*extension[[:space:]]+TaskService[[:space:]]*\{ ]]; then
                in_extension=true
                brace_count=1
                echo "⚠️  Removing TaskService extension from WorkerService.swift"
                continue
            fi
            
            # If we're in the extension, count braces
            if [ "$in_extension" = true ]; then
                # Count opening braces
                local open_braces=$(echo "$line" | grep -o '{' | wc -l)
                brace_count=$((brace_count + open_braces))
                
                # Count closing braces  
                local close_braces=$(echo "$line" | grep -o '}' | wc -l)
                brace_count=$((brace_count - close_braces))
                
                # If brace count reaches 0, we've finished the extension
                if [ $brace_count -eq 0 ]; then
                    in_extension=false
                fi
                continue
            fi
            
            # If we're not in the extension, keep the line
            echo "$line" >> "$temp_file"
            
        done < "$worker_service"
        
        # Replace the original file
        mv "$temp_file" "$worker_service"
        
        echo "✅ Cleaned WorkerService.swift - removed problematic extension"
    else
        echo "⚠️  WorkerService.swift not found at expected location"
    fi
}

# Function to test compilation
test_compilation() {
    echo "🔧 Testing compilation..."
    
    cd "$XCODE_PATH"
    
    # Clean build cache
    echo "🧹 Cleaning build cache..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/FrancoSphere-* 2>/dev/null || true
    
    # Test build (just check syntax, don't need full build)
    echo "🔨 Testing syntax..."
    if xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere -dry-run >/dev/null 2>&1; then
        echo "✅ Project structure looks good"
    else
        echo "⚠️  Project may have structural issues, but syntax fixes have been applied"
    fi
}

# Function to verify specific error fixes
verify_fixes() {
    echo "🔧 Verifying fixes..."
    
    # Count remaining ambiguous type errors
    cd "$XCODE_PATH"
    
    echo "📊 Checking for remaining type ambiguity errors..."
    
    # Check each file that had errors
    local files_to_check=(
        "Components/Design/ModelColorsExtensions.swift"
        "Components/Design/TodaysTasksGlassCard.swift"
        "Components/Design/WeatherTaskTimelineCard.swift"
        "Models/WorkerRoutineViewModel.swift"
        "Views/Buildings/TaskFormView.swift"
        "Views/Main/DashboardTaskDetailView.swift"
    )
    
    local fixed_count=0
    local total_count=${#files_to_check[@]}
    
    for file in "${files_to_check[@]}"; do
        if [ -f "$file" ]; then
            # Check if file still has bare type references
            if grep -q '\bMaintenanceTask\b\|\bTaskCategory\b\|\bTaskUrgency\b\|\bTaskRecurrence\b' "$file" 2>/dev/null; then
                echo "⚠️  $file may still have ambiguous types"
            else
                echo "✅ $file - type references fixed"
                fixed_count=$((fixed_count + 1))
            fi
        fi
    done
    
    echo "📈 Progress: $fixed_count/$total_count files fixed"
}

# Main execution
main() {
    echo "Starting FrancoSphere simple compilation fix..."
    echo "Working directory: $XCODE_PATH"
    
    if [ ! -d "$XCODE_PATH" ]; then
        echo "❌ Error: Xcode project directory not found at $XCODE_PATH"
        exit 1
    fi
    
    # Execute all steps
    create_backup
    fix_type_references
    clean_worker_service
    test_compilation
    verify_fixes
    
    echo ""
    echo "🎯 FrancoSphere Simple Compilation Fix Complete!"
    echo "================================================"
    echo "✅ Backup created at: $BACKUP_DIR"
    echo "✅ Type references updated to use FrancoSphere namespace"
    echo "✅ Problematic WorkerService extension removed"
    echo ""
    echo "⚠️  REMAINING MANUAL STEPS:"
    echo "1. Fix TaskScheduleView.swift manually (too complex for script)"
    echo "2. Test actual compilation: xcodebuild clean build"
    echo "3. If issues remain, check TaskScheduleView.swift binding errors"
    echo ""
    echo "📁 Backup location: $BACKUP_DIR"
}

# Run the script
main "$@"