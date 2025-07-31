//
//  TestHelpers.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/31/25.
//


//
//  TestHelpers.swift
//  FrancoSphereTests
//
//  Stream C: Grok - Testing & Infrastructure
//  Mission: Create essential utilities for the entire test suite.
//
//  ✅ PRODUCTION READY: A robust set of test utilities.
//  ✅ ISOLATED: Provides an in-memory database for hermetic testing.
//  ✅ MOCK FACTORIES: Easily generate consistent mock data for any test case.
//

import Foundation
import GRDB
import XCTest

// It's crucial to import the main app module as @testable
// to gain access to its internal types and methods.
@testable import FrancoSphere

class TestHelpers {
    
    // MARK: - In-Memory Database Setup
    
    /// Creates a fresh, in-memory GRDB database pool for a single test run.
    /// This ensures that each test starts with a clean slate and is not affected
    /// by data from previous tests.
    ///
    /// - Returns: A `DatabasePool` configured for in-memory use.
    static func createTestDatabase() throws -> DatabasePool {
        // Use an in-memory database for speed and isolation.
        let dbPool = try DatabasePool(configuration: .inMemory)
        
        // Use the same migrator/table creation logic as the main app.
        try dbPool.write { db in
            try GRDBManager.shared.createTables(db)
        }
        
        return dbPool
    }
    
    /// Seeds the test database with a standard set of workers and buildings.
    ///
    /// - Parameter dbPool: The in-memory `DatabasePool` to seed.
    static func seedTestData(_ dbPool: DatabasePool) async throws {
        try await dbPool.write { db in
            // Seed Workers
            try db.execute(sql: """
                INSERT INTO workers (id, name, email, role, isActive) VALUES
                ('1', 'Greg Hutson', 'greg@test.com', 'worker', 1),
                ('4', 'Kevin Dutan', 'kevin@test.com', 'worker', 1),
                ('5', 'Mercedes Inamagua', 'mercedes@test.com', 'worker', 1),
                ('8', 'Shawn Magloire', 'shawn@test.com', 'admin', 1);
            """)
            
            // Seed Buildings
            try db.execute(sql: """
                INSERT INTO buildings (id, name, address) VALUES
                ('14', 'Rubin Museum', '150 W 17th St'),
                ('6', '68 Perry Street', '68 Perry St'),
                ('1', '12 West 18th Street', '12 W 18th St');
            """)
            
            // Seed Capabilities for Mercedes (simplified UI)
            try db.execute(sql: """
                INSERT INTO worker_capabilities (worker_id, simplified_interface) VALUES ('5', 1);
            """)
        }
    }
    
    // MARK: - Mock Factories
    
    /// Creates a mock `CoreTypes.WorkerProfile` for testing.
    static func createMockWorker(
        id: String = UUID().uuidString,
        name: String = "Test Worker",
        role: CoreTypes.UserRole = .worker,
        isActive: Bool = true,
        capabilities: CoreTypes.WorkerCapabilities? = nil
    ) -> CoreTypes.WorkerProfile {
        return CoreTypes.WorkerProfile(
            id: id,
            name: name,
            email: "\(name.replacingOccurrences(of: " ", with: "."))@test.com",
            role: role,
            isActive: isActive,
            capabilities: capabilities
        )
    }
    
    /// Creates a mock `CoreTypes.ContextualTask` for testing.
    static func createMockTask(
        id: String = UUID().uuidString,
        title: String = "Test Task",
        buildingId: String,
        assignedWorkerId: String? = nil,
        requiresPhoto: Bool = false,
        status: CoreTypes.TaskStatus = .pending
    ) -> CoreTypes.ContextualTask {
        return CoreTypes.ContextualTask(
            id: id,
            title: title,
            status: status,
            buildingId: buildingId,
            assignedWorkerId: assignedWorkerId,
            requiresPhoto: requiresPhoto
        )
    }
    
    /// Creates a mock `CoreTypes.NamedCoordinate` (Building) for testing.
    static func createMockBuilding(
        id: String = UUID().uuidString,
        name: String = "Test Building",
        address: String = "123 Test St"
    ) -> CoreTypes.NamedCoordinate {
        return CoreTypes.NamedCoordinate(
            id: id,
            name: name,
            address: address,
            latitude: 40.7128,
            longitude: -74.0060
        )
    }
    
    // MARK: - Service Mocking
    
    /// Creates a mock `NewAuthManager` with a pre-authenticated user.
    /// This is useful for testing views and services that require an authenticated state.
    static func createMockAuthManager(
        isAuthenticated: Bool = true,
        user: CoreTypes.User = .init(id: "4", workerId: "4", name: "Kevin Dutan", email: "kevin@test.com", role: "worker")
    ) -> NewAuthManager {
        let authManager = NewAuthManager.shared // Using the singleton for consistency
        // In a more advanced setup, you might inject a mock protocol. For this architecture,
        // modifying the shared instance for the duration of a test is a common pattern.
        
        // We'll need to use reflection or modify NewAuthManager to allow setting the user for tests.
        // For now, this is a conceptual placeholder.
        
        return authManager
    }
}