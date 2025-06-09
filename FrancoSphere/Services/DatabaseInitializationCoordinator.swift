import Foundation
import SwiftUI

@MainActor
final class DatabaseInitializationCoordinator: ObservableObject {
    static let shared = DatabaseInitializationCoordinator()
    
    enum InitializationState: Equatable {
        case idle
        case initializing(phase: InitializationPhase)
        case ready
        case failed(Error)
        
        static func == (lhs: InitializationState, rhs: InitializationState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.ready, .ready):
                return true
            case let (.initializing(phase1), .initializing(phase2)):
                return phase1 == phase2
            case let (.failed(error1), .failed(error2)):
                return error1.localizedDescription == error2.localizedDescription
            default:
                return false
            }
        }
    }
    
    enum InitializationPhase: String, Equatable {
        case database = "Database"
        case migrations = "Migrations"
        case dataPreparation = "Data Preparation"
        case contextWarming = "Context Warming"
    }
    
    struct InitializationProgress {
        var phase: InitializationPhase = .database
        var progress: Double = 0.0
        var message: String = ""
    }
    
    @Published var state: InitializationState = .idle
    @Published var progress = InitializationProgress()
    
    private var sqliteManager: SQLiteManager?
    
    // Completion token for downstream systems
    private(set) lazy var initializationComplete = Task<Void, Never> {
        await self.performInitialization()
    }
    
    private init() {}
    
    func performInitialization() async {
        do {
            // Phase 1: Database initialization
            await MainActor.run {
                state = .initializing(phase: .database)
                progress.phase = .database
                progress.message = "Starting database..."
                progress.progress = 0.0
            }
            
            // Create SQLiteManager using the factory method
            sqliteManager = try await SQLiteManager.start()
            
            // Small delay to show progress
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            await MainActor.run {
                progress.progress = 0.25
            }
            
            // Phase 2: Run migrations (handled automatically by SQLiteManager)
            await MainActor.run {
                state = .initializing(phase: .migrations)
                progress.phase = .migrations
                progress.message = "Running database migrations..."
                progress.progress = 0.3
            }
            
            // Small delay to show migration progress
            try await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
            
            await MainActor.run {
                progress.progress = 0.5
            }
            
            // Phase 3: Data preparation with real-world data
            await MainActor.run {
                state = .initializing(phase: .dataPreparation)
                progress.phase = .dataPreparation
                progress.message = "Loading real-world data..."
                progress.progress = 0.6
            }
            
            try await prepareInitialData()
            
            await MainActor.run {
                progress.progress = 0.8
            }
            
            // Phase 4: Warm worker context
            await MainActor.run {
                state = .initializing(phase: .contextWarming)
                progress.phase = .contextWarming
                progress.message = "Preparing worker context..."
                progress.progress = 0.9
            }
            
            await warmWorkerContext()
            
            // Complete
            await MainActor.run {
                progress.progress = 1.0
                progress.message = "Ready!"
                state = .ready
            }
            
            print("✅ Database initialization completed successfully")
            
        } catch {
            await MainActor.run {
                state = .failed(error)
            }
            print("❌ Database initialization failed: \(error)")
        }
    }
    
    private func prepareInitialData() async throws {
        guard let manager = sqliteManager else {
            throw DatabaseError.notInitialized
        }
        
        // Update progress message
        await MainActor.run {
            progress.message = "Loading Edwin's buildings and tasks..."
        }
        
        // Use the RealWorldDataSeeder to populate all real data
        try await RealWorldDataSeeder.seedAllRealData(manager)
        
        // Small delay to show completion
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        await MainActor.run {
            progress.progress = 0.75
            progress.message = "Data loaded successfully!"
        }
        
        print("✅ Real-world data preparation complete")
    }
    
    private func warmWorkerContext() async {
        // Initialize singletons to warm up caches
        _ = NewAuthManager.shared
        _ = ClockInManager.shared
        _ = TaskManager.shared
        _ = WorkerRoutineManager.shared
        _ = WorkerContextEngine.shared
        
        // Pre-load weather service if available
        if let weatherService = try? await WeatherService.shared {
            print("🌤️ Weather service warmed up")
        }
        
        // Small delay to show progress
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        print("✅ Worker context warmed up")
    }
    
    // MARK: - Public Methods
    
    /// Reset the database and re-initialize (for development/testing)
    func resetAndReinitialize() async {
        await MainActor.run {
            state = .idle
            progress = InitializationProgress()
        }
        
        // Clear existing database
        if let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                        in: .userDomainMask).first {
            let dbPath = documentsPath.appendingPathComponent("FrancoSphere.sqlite3")
            try? FileManager.default.removeItem(at: dbPath)
            
            let walPath = documentsPath.appendingPathComponent("FrancoSphere.sqlite3-wal")
            try? FileManager.default.removeItem(at: walPath)
            
            let shmPath = documentsPath.appendingPathComponent("FrancoSphere.sqlite3-shm")
            try? FileManager.default.removeItem(at: shmPath)
        }
        
        // Re-initialize
        await performInitialization()
    }
    
    /// Get current database statistics
    func getDatabaseStats() async -> (workers: Int, buildings: Int, tasks: Int)? {
        guard let manager = sqliteManager else { return nil }
        
        do {
            let workerCount = try await manager.query("SELECT COUNT(*) as count FROM workers")
            let buildingCount = try await manager.query("SELECT COUNT(*) as count FROM buildings")
            let taskCount = try await manager.query("SELECT COUNT(*) as count FROM routine_tasks")
            
            return (
                workers: Int(workerCount.first?["count"] as? Int64 ?? 0),
                buildings: Int(buildingCount.first?["count"] as? Int64 ?? 0),
                tasks: Int(taskCount.first?["count"] as? Int64 ?? 0)
            )
        } catch {
            print("❌ Failed to get database stats: \(error)")
            return nil
        }
    }
}

// MARK: - Database Error Extension
extension DatabaseError: Equatable {
    public static func == (lhs: DatabaseError, rhs: DatabaseError) -> Bool {
        lhs.localizedDescription == rhs.localizedDescription
    }
}
