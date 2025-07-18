# FrancoSphere v6.0 - Database Migration Guide

## ✅ NEW ARCHITECTURE (SINGLE SOURCE OF TRUTH)

### Database Stack:
- **Database**: GRDB (SQLite removed completely)
- **Initializer**: DatabaseStartupCoordinator (all others removed)
- **Models**: GRDB FetchableRecord/PersistableRecord

### Initialization Flow:
```swift
// In FrancoSphereApp.swift
@main
struct FrancoSphereApp: App {
    @State private var isInitialized = false
    
    var body: some Scene {
        WindowGroup {
            if isInitialized {
                ContentView()
            } else {
                LoadingView()
                    .task {
                        do {
                            try await DatabaseStartupCoordinator.shared.initializeDatabase()
                            isInitialized = true
                        } catch {
                            print("❌ Database initialization failed: \(error)")
                        }
                    }
            }
        }
    }
}
```

### Key Changes:
1. ❌ REMOVED: SQLiteManager, RealWorldDataSeeder, UnifiedDataService
2. ✅ SINGLE: DatabaseStartupCoordinator handles everything
3. ✅ GRDB: All database operations use GRDB
4. ✅ MODELS: Proper FetchableRecord/PersistableRecord conformance

### Worker Assignment Fix:
- Kevin (ID: 1) → Rubin Museum (ID: 14) as PRIMARY
- All workers have portfolio access to all buildings
- Primary assignment determines default clock-in location

## Testing:
1. Delete app from simulator
2. Clean build folder
3. Run fresh build
4. Verify Kevin sees Rubin Museum as primary
