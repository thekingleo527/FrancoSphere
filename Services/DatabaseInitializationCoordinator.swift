// DatabaseInitializationCoordinator.swift
// Fixed version

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)


@MainActor
class DatabaseInitializationCoordinator: ObservableObject {
    static let shared = DatabaseInitializationCoordinator()
    
    @Published var isInitialized = false
    @Published var initializationError: String?
    
    private let sqliteManager = SQLiteManager.shared
    
    private init() {}
    
    func initializeApp() async {
        // 1. Initialize SQLite using the shared instance
        print("🔧 Initializing SQLite...")
        
        // Ensure database is ready
        if !sqliteManager.isDatabaseReady() {
            sqliteManager.quickInitialize()
            
            // Wait a moment for initialization
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        // 2. Check if we need to load initial data
        do {
            let workerCount = try await sqliteManager.query(parameters: "SELECT COUNT(*) as count FROM workers").first?["count"] as? Int64 ?? 0
            
            if workerCount == 0 {
                print("📊 Loading test data...")
                // Load minimal test data
                try await loadTestData()
            }
            
            // 3. Mark as initialized
            print("✅ App initialization complete!")
            isInitialized = true
            
        } catch {
            print("❌ Initialization failed: \(error)")
            initializationError = error.localizedDescription
        }
    }
    
    private func loadTestData() async throws {
        // Insert test building
        try await sqliteManager.execute(parameters: """
            INSERT INTO buildings (name, address, latitude, longitude, imageAssetName)
            VALUES (?, ?, ?, ?, ?)
            """, ["12 West 18th Street", "12 West 18th Street, New York, NY", 40.7390, -73.9936, "12West18thStreet"]
        )
        
        // Insert test worker
        try await sqliteManager.execute(parameters: """
            INSERT INTO workers (name, email, passwordHash, role)
            VALUES (?, ?, ?, ?)
            """, ["Edwin Lema", "edwinlema911@gmail.com", "password", "worker"]
        )
        
        print("✅ Test data loaded")
    }
    
    func resetAndReinitialize() async {
        isInitialized = false
        initializationError = nil
        
        // Clear existing data
        do {
            try await sqliteManager.execute(parameters: "DELETE FROM workers")
            try await sqliteManager.execute(parameters: "DELETE FROM buildings")
        } catch {
            print("Error clearing data: \(error)")
        }
        
        // Reinitialize
        await initializeApp()
    }
}
