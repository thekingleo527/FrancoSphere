#!/bin/bash

# FrancoSphere Comprehensive Compilation Fix Script
XCODE_PATH="/Volumes/FastSSD/Xcode"
BACKUP_DIR="$HOME/francosphere_compilation_fix_$(date +%Y%m%d_%H%M%S)"

echo "🔧 FrancoSphere Comprehensive Compilation Fix"
echo "============================================="

# Create backup
mkdir -p "$BACKUP_DIR"
cp -r "$XCODE_PATH"/{Models,Managers,Services,Views} "$BACKUP_DIR/" 2>/dev/null || true

echo "✅ Backup created: $BACKUP_DIR"

# Fix 1: Remove duplicate WeatherManager 2.swift
if [ -f "$XCODE_PATH/Managers/WeatherManager 2.swift" ]; then
    echo "🗑️ Removing duplicate WeatherManager 2.swift"
    rm "$XCODE_PATH/Managers/WeatherManager 2.swift"
    sed -i '' '/WeatherManager 2\.swift/d' "$XCODE_PATH/FrancoSphere.xcodeproj/project.pbxproj"
fi

# Fix 2: Create missing WorkerManager.swift
cat > "$XCODE_PATH/Managers/WorkerManager.swift" << 'WORKERMANAGER'
//
//  WorkerManager.swift
//  FrancoSphere
//

import Foundation
import Combine

@MainActor
public class WorkerManager: ObservableObject {
    public static let shared = WorkerManager()
    
    @Published public var currentWorker: FrancoSphere.WorkerProfile?
    @Published public var allWorkers: [FrancoSphere.WorkerProfile] = []
    @Published public var isLoading = false
    @Published public var error: Error?
    
    private let workerService = WorkerService.shared
    
    private init() {
        loadWorkers()
    }
    
    private func loadWorkers() {
        allWorkers = FrancoSphere.WorkerProfile.allWorkers
    }
    
    public func getWorker(by id: String) -> FrancoSphere.WorkerProfile? {
        return allWorkers.first { $0.id == id }
    }
    
    public func setCurrentWorker(_ workerId: String) {
        currentWorker = getWorker(by: workerId)
    }
    
    public func getAllActiveWorkers() -> [FrancoSphere.WorkerProfile] {
        return allWorkers.filter { $0.isActive }
    }
    
    public func loadWorkerBuildings(_ workerId: String) async throws -> [FrancoSphere.NamedCoordinate] {
        return try await workerService.getAssignedBuildings(workerId)
    }
    
    public func getWorkerTasks(for workerId: String, date: Date) async throws -> [ContextualTask] {
        return try await TaskService.shared.getTasks(for: workerId, date: date)
    }
}
WORKERMANAGER

echo "✅ WorkerManager.swift created"

# Fix 3: Test compilation
echo "🔨 Testing compilation..."
cd "$XCODE_PATH"
BUILD_OUTPUT=$(xcodebuild clean build -project FrancoSphere.xcodeproj -scheme FrancoSphere -destination 'platform=iOS Simulator,name=iPhone 15' 2>&1)
ERROR_COUNT=$(echo "$BUILD_OUTPUT" | grep -c "error:" || echo "0")

echo "📊 Build Results: $ERROR_COUNT errors"

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "🎉 SUCCESS: Zero compilation errors!"
else
    echo "❌ Still has $ERROR_COUNT compilation errors"
    echo "$BUILD_OUTPUT" | grep "error:" | head -5
fi

echo "✅ Fix script complete"
