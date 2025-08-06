//
//  ClientBuildingSeeder.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 8/4/25.
//


//
//  ClientBuildingSeeder.swift
//  CyntientOps (formerly CyntientOps)
//
//  Phase 0B: Client-Building Structure
//  Creates client management schema and seeds real client data
//

import Foundation
import GRDB

@MainActor
public final class ClientBuildingSeeder {
    
    // MARK: - Dependencies
    private let grdbManager = GRDBManager.shared
    
    // MARK: - Client Data Structure
    private struct Client {
        let id: String
        let name: String
        let shortName: String
        let contactEmail: String
        let contactPhone: String
        let address: String
        let isActive: Bool
        let buildings: [String] // Building IDs
    }
    
    // MARK: - Real Client Data
    private let clients: [Client] = [
        Client(
            id: "JMR",
            name: "JM Realty",
            shortName: "JMR",
            contactEmail: "management@jmrealty.com",
            contactPhone: "+1 (212) 555-0200",
            address: "350 Fifth Avenue, New York, NY 10118",
            isActive: true,
            buildings: ["3", "5", "6", "7", "9", "10", "11", "14", "21"] // 9 buildings including Rubin (14) and new Chambers (21)
        ),
        Client(
            id: "WFR",
            name: "Weber Farhat",
            shortName: "WFR",
            contactEmail: "info@weberfarhat.com",
            contactPhone: "+1 (212) 555-0201",
            address: "136 West 17th Street, New York, NY 10011",
            isActive: true,
            buildings: ["13"] // 1 building
        ),
        Client(
            id: "SOL",
            name: "Solar One",
            shortName: "SOL",
            contactEmail: "facilities@solarone.org",
            contactPhone: "+1 (212) 555-0202",
            address: "Stuyvesant Cove Park, New York, NY 10009",
            isActive: true,
            buildings: ["16"] // 1 building
        ),
        Client(
            id: "GEL",
            name: "Grand Elizabeth LLC",
            shortName: "GEL",
            contactEmail: "management@grandelizabeth.com",
            contactPhone: "+1 (212) 555-0203",
            address: "41 Elizabeth Street, New York, NY 10013",
            isActive: true,
            buildings: ["8"] // 1 building
        ),
        Client(
            id: "CIT",
            name: "Citadel Realty",
            shortName: "CIT",
            contactEmail: "property@citadelrealty.com",
            contactPhone: "+1 (212) 555-0204",
            address: "104 Franklin Street, New York, NY 10013",
            isActive: true,
            buildings: ["4", "18"] // 2 buildings
        ),
        Client(
            id: "COR",
            name: "Corbel Property",
            shortName: "COR",
            contactEmail: "admin@corbelproperty.com",
            contactPhone: "+1 (212) 555-0205",
            address: "133 East 15th Street, New York, NY 10003",
            isActive: true,
            buildings: ["15"] // 1 building
        )
    ]
    
    // MARK: - Building Updates
    private let buildingUpdates: [(id: String, name: String, address: String, isActive: Bool)] = [
        // Deactivate building 2
        ("2", "29-31 East 20th Street", "29-31 East 20th Street, New York, NY 10003", false),
        
        // Add new building 21
        ("21", "148 Chambers Street", "148 Chambers Street, New York, NY 10007", true)
    ]
    
    // MARK: - Public Methods
    
    /// Create schema and seed client data
    public func seedClientStructure() async throws {
        print("🏢 Creating client-building structure...")
        
        // Step 1: Create tables
        try await createClientTables()
        
        // Step 2: Update building database
        try await updateBuildingDatabase()
        
        // Step 3: Seed client data
        try await seedClients()
        
        // Step 4: Create client-building relationships
        try await createClientBuildingRelationships()
        
        // Step 5: Link client users
        try await linkClientUsers()
        
        // Step 6: Verify data integrity
        try await verifyClientStructure()
        
        print("✅ Client-building structure created successfully")
    }
    
    // MARK: - Private Methods - Schema
    
    private func createClientTables() async throws {
        print("📋 Creating client management tables...")
        
        // Clients table
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS clients (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                short_name TEXT,
                contact_email TEXT,
                contact_phone TEXT,
                address TEXT,
                is_active INTEGER DEFAULT 1,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            )
        """)
        
        // Client-Building relationships
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS client_buildings (
                client_id TEXT NOT NULL,
                building_id TEXT NOT NULL,
                is_primary INTEGER DEFAULT 0,
                created_at TEXT NOT NULL,
                PRIMARY KEY (client_id, building_id),
                FOREIGN KEY (client_id) REFERENCES clients(id),
                FOREIGN KEY (building_id) REFERENCES buildings(id)
            )
        """)
        
        // Client users table
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS client_users (
                user_id TEXT NOT NULL,
                client_id TEXT NOT NULL,
                role TEXT DEFAULT 'viewer',
                can_view_financials INTEGER DEFAULT 0,
                can_edit_settings INTEGER DEFAULT 0,
                created_at TEXT NOT NULL,
                PRIMARY KEY (user_id, client_id),
                FOREIGN KEY (user_id) REFERENCES workers(id),
                FOREIGN KEY (client_id) REFERENCES clients(id)
            )
        """)
        
        print("✅ Client tables created")
    }
    
    private func updateBuildingDatabase() async throws {
        print("🔧 Updating building database...")
        
        // Add BIN and BBL columns if they don't exist
        let tableInfo = try await grdbManager.query("PRAGMA table_info(buildings)")
        let columns = tableInfo.compactMap { $0["name"] as? String }
        
        if !columns.contains("bin_number") {
            try await grdbManager.execute("""
                ALTER TABLE buildings ADD COLUMN bin_number TEXT
            """)
        }
        
        if !columns.contains("bbl") {
            try await grdbManager.execute("""
                ALTER TABLE buildings ADD COLUMN bbl TEXT
            """)
        }
        
        // Deactivate building 2
        try await grdbManager.execute("""
            UPDATE buildings 
            SET isActive = 0, updated_at = ?
            WHERE id = '2'
        """, [Date().ISO8601Format()])
        
        // Add building 21 if it doesn't exist
        let building21Exists = try await grdbManager.query(
            "SELECT id FROM buildings WHERE id = '21'"
        )
        
        if building21Exists.isEmpty {
            try await grdbManager.execute("""
                INSERT INTO buildings (
                    id, name, address, latitude, longitude, 
                    isActive, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, [
                "21",
                "148 Chambers Street",
                "148 Chambers Street, New York, NY 10007",
                40.7155, // Approximate coordinates
                -74.0086,
                1,
                Date().ISO8601Format(),
                Date().ISO8601Format()
            ])
        }
        
        print("✅ Building database updated")
    }
    
    private func seedClients() async throws {
        print("🌱 Seeding client data...")
        
        for client in clients {
            // Check if client exists
            let existing = try await grdbManager.query(
                "SELECT id FROM clients WHERE id = ?",
                [client.id]
            )
            
            if existing.isEmpty {
                // Insert new client
                try await grdbManager.execute("""
                    INSERT INTO clients (
                        id, name, short_name, contact_email, contact_phone,
                        address, is_active, created_at, updated_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, [
                    client.id,
                    client.name,
                    client.shortName,
                    client.contactEmail,
                    client.contactPhone,
                    client.address,
                    client.isActive ? 1 : 0,
                    Date().ISO8601Format(),
                    Date().ISO8601Format()
                ])
                
                print("✅ Created client: \(client.name)")
            } else {
                // Update existing client
                try await grdbManager.execute("""
                    UPDATE clients 
                    SET name = ?, short_name = ?, contact_email = ?, 
                        contact_phone = ?, address = ?, is_active = ?, updated_at = ?
                    WHERE id = ?
                """, [
                    client.name,
                    client.shortName,
                    client.contactEmail,
                    client.contactPhone,
                    client.address,
                    client.isActive ? 1 : 0,
                    Date().ISO8601Format(),
                    client.id
                ])
                
                print("✅ Updated client: \(client.name)")
            }
        }
    }
    
    private func createClientBuildingRelationships() async throws {
        print("🔗 Creating client-building relationships...")
        
        // Clear existing relationships
        try await grdbManager.execute("DELETE FROM client_buildings")
        
        // Create new relationships
        for client in clients {
            for (index, buildingId) in client.buildings.enumerated() {
                try await grdbManager.execute("""
                    INSERT INTO client_buildings (
                        client_id, building_id, is_primary, created_at
                    ) VALUES (?, ?, ?, ?)
                """, [
                    client.id,
                    buildingId,
                    index == 0 ? 1 : 0, // First building is primary
                    Date().ISO8601Format()
                ])
            }
            
            print("✅ Linked \(client.buildings.count) buildings to \(client.name)")
        }
    }
    
    private func linkClientUsers() async throws {
        print("👥 Linking client users...")
        
        // Map of user emails to client IDs
        let userClientMap: [(email: String, clientId: String, role: String)] = [
            ("jm@jmrealty.com", "JMR", "admin"),
            ("sarah@jmrealty.com", "JMR", "manager"),
            ("david@weberfarhat.com", "WFR", "admin"),
            ("maria@solarone.org", "SOL", "admin"),
            ("robert@grandelizabeth.com", "GEL", "admin"),
            ("alex@citadelrealty.com", "CIT", "admin"),
            ("jennifer@corbelproperty.com", "COR", "admin")
        ]
        
        for mapping in userClientMap {
            // Get user ID from email
            let userResult = try await grdbManager.query(
                "SELECT id FROM workers WHERE email = ?",
                [mapping.email]
            )
            
            if let userId = userResult.first?["id"] as? String {
                try await grdbManager.execute("""
                    INSERT OR REPLACE INTO client_users (
                        user_id, client_id, role, can_view_financials, 
                        can_edit_settings, created_at
                    ) VALUES (?, ?, ?, ?, ?, ?)
                """, [
                    userId,
                    mapping.clientId,
                    mapping.role,
                    1, // Admins can view financials
                    mapping.role == "admin" ? 1 : 0, // Only admins can edit
                    Date().ISO8601Format()
                ])
                
                print("✅ Linked user \(mapping.email) to client \(mapping.clientId)")
            }
        }
    }
    
    private func verifyClientStructure() async throws {
        print("🔍 Verifying client structure...")
        
        // Verify all clients have buildings
        for client in clients {
            let buildingCount = try await grdbManager.query("""
                SELECT COUNT(*) as count 
                FROM client_buildings 
                WHERE client_id = ?
            """, [client.id])
            
            if let count = buildingCount.first?["count"] as? Int64 {
                print("✓ \(client.name): \(count) buildings")
                
                if count != client.buildings.count {
                    throw ClientStructureError.buildingCountMismatch(
                        client: client.name,
                        expected: client.buildings.count,
                        found: Int(count)
                    )
                }
            }
        }
        
        // Verify JM Realty has Rubin Museum
        let jmRubinCheck = try await grdbManager.query("""
            SELECT building_id 
            FROM client_buildings 
            WHERE client_id = 'JMR' AND building_id = '14'
        """)
        
        guard !jmRubinCheck.isEmpty else {
            throw ClientStructureError.missingRubinMuseum
        }
        
        print("✅ Client structure verified successfully")
    }
}

// MARK: - Errors

enum ClientStructureError: LocalizedError {
    case buildingCountMismatch(client: String, expected: Int, found: Int)
    case missingRubinMuseum
    
    var errorDescription: String? {
        switch self {
        case .buildingCountMismatch(let client, let expected, let found):
            return "\(client) should have \(expected) buildings but has \(found)"
        case .missingRubinMuseum:
            return "JM Realty is missing Rubin Museum assignment"
        }
    }
}