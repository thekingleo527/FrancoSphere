// InventoryManager.swift
// FrancoSphere
// Created by Shawn Magloire on 3/3/25.

import Foundation
import SQLite

/// Manages building inventory items, usage, and restock requests.
actor InventoryManagerImpl {
    /// Singleton instance of InventoryManagerImpl.
    static let shared = InventoryManagerImpl()
    
    private var sqliteManager: SQLiteManager?

    private init() {
        Task {
            await setupDatabase()
        }
    }

    // MARK: - Setup Methods

    private func setupDatabase() async {
        // Change from:
        // self.sqliteManager = try await SQLiteManager.start()
        // To:
        self.sqliteManager = SQLiteManager.shared
        try? await createInventoryTables()
    }

    private func createInventoryTables() async throws {
        guard let sqliteManager = sqliteManager else {
            print("SQLite manager not initialized")
            return
        }

        try await sqliteManager.execute("""
            CREATE TABLE IF NOT EXISTS inventory_items (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                buildingId TEXT,
                category TEXT,
                quantity INTEGER,
                unit TEXT,
                minimumQuantity INTEGER,
                needsReorder INTEGER,
                lastRestockDate TEXT,
                location TEXT,
                notes TEXT
            )
        """)

        try await sqliteManager.execute("""
            CREATE TABLE IF NOT EXISTS inventory_usage (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                itemId TEXT,
                buildingId TEXT,
                itemName TEXT,
                quantityUsed INTEGER,
                usedBy TEXT,
                usageDate TEXT,
                unit TEXT,
                notes TEXT
            )
        """)

        try await sqliteManager.execute("""
            CREATE TABLE IF NOT EXISTS restock_requests (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                itemId TEXT,
                buildingId TEXT,
                itemName TEXT,
                currentQuantity INTEGER,
                requestedQuantity INTEGER,
                requestedBy TEXT,
                requestDate TEXT,
                status TEXT,
                notes TEXT,
                approvedBy TEXT,
                approvalDate TEXT
            )
        """)

        print("Inventory tables created successfully")
    }

    // MARK: - Database Operations

    /// Retrieves all inventory items for a specific building.
    func getInventoryItems(forBuilding buildingId: String) async -> [FrancoSphere.InventoryItem] {
        guard let sqliteManager = sqliteManager else {
            print("SQLite manager not initialized, returning sample data")
            return createSampleInventoryItems(buildingId: buildingId)
        }

        do {
            let query = """
            SELECT id, name, category, quantity, unit, minimumQuantity,
                   needsReorder, lastRestockDate, location, notes
            FROM inventory_items
            WHERE buildingId = ?
            ORDER BY name
            """
            
            let rows = try await sqliteManager.query(query, [buildingId])
            
            var items: [FrancoSphere.InventoryItem] = []
            
            for row in rows {
                guard let id = row["id"] as? Int64,
                      let name = row["name"] as? String else {
                    continue
                }
                
                let categoryStr = row["category"] as? String ?? "other"
                let quantity = Int(row["quantity"] as? Int64 ?? 0)
                let unit = row["unit"] as? String ?? ""
                let minimumQuantity = Int(row["minimumQuantity"] as? Int64 ?? 0)
                let needsReorder = (row["needsReorder"] as? Int64 ?? 0) != 0
                let lastRestockDateStr = row["lastRestockDate"] as? String
                let location = row["location"] as? String ?? ""
                let notes = row["notes"] as? String

                let category = FrancoSphere.InventoryCategory(rawValue: categoryStr.lowercased()) ?? .other
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let lastRestockDate = lastRestockDateStr != nil ? dateFormatter.date(from: lastRestockDateStr!) ?? Date() : Date()

                let item = FrancoSphere.InventoryItem(
                    id: "\(id)",
                    name: name,
                    buildingID: buildingId,
                    category: category,
                    quantity: quantity,
                    unit: unit,
                    minimumQuantity: minimumQuantity,
                    needsReorder: needsReorder,
                    lastRestockDate: lastRestockDate,
                    location: location,
                    notes: notes
                )
                items.append(item)
            }
            
            if items.isEmpty {
                return createSampleInventoryItems(buildingId: buildingId)
            }
            
            return items
            
        } catch {
            print("Error getting inventory items: \(error)")
            return createSampleInventoryItems(buildingId: buildingId)
        }
    }

    /// Saves or updates an inventory item in the database.
    func saveInventoryItem(_ item: FrancoSphere.InventoryItem) async -> Bool {
        guard let sqliteManager = sqliteManager else {
            print("SQLite manager not initialized")
            return false
        }

        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let lastRestockDateStr = dateFormatter.string(from: item.lastRestockDate)

            // Check if item exists
            let checkQuery = "SELECT id FROM inventory_items WHERE id = ?"
            let rows = try await sqliteManager.query(checkQuery, [item.id])

            
            if !rows.isEmpty {
                // Update existing item
                let updateQuery = """
                UPDATE inventory_items SET
                    name = ?, category = ?, quantity = ?, unit = ?,
                    minimumQuantity = ?, needsReorder = ?, lastRestockDate = ?,
                    location = ?, notes = ?
                WHERE id = ?
                """
                
                try await sqliteManager.execute(updateQuery, [
                    item.name, item.category.rawValue, item.quantity, item.unit,
                    item.minimumQuantity, item.needsReorder ? 1 : 0, lastRestockDateStr,
                    item.location, item.notes ?? "", item.id
                ])
            } else {
                // Insert new item
                let insertQuery = """
                INSERT INTO inventory_items (
                    name, buildingId, category, quantity, unit,
                    minimumQuantity, needsReorder, lastRestockDate, location, notes
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """
                
                try await sqliteManager.execute(insertQuery, [
                    item.name, item.buildingID, item.category.rawValue, item.quantity, item.unit,
                    item.minimumQuantity, item.needsReorder ? 1 : 0, lastRestockDateStr,
                    item.location, item.notes ?? ""
                ])
            }

            return true
        } catch {
            print("Error saving inventory item: \(error)")
            return false
        }
    }

    // MARK: - Usage and Restock Methods

    func recordInventoryUsage(itemId: String, itemName: String, quantityUsed: Int, workerId: String, unit: String, notes: String? = nil) async {
        guard let sqliteManager = sqliteManager else {
            print("SQLite manager not initialized")
            return
        }

        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let usageDateStr = dateFormatter.string(from: Date())

            let insertQuery = """
            INSERT INTO inventory_usage (
                itemId, itemName, quantityUsed, usedBy,
                usageDate, unit, notes
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
            """
            
            try await sqliteManager.execute(insertQuery, [
                itemId, itemName, quantityUsed, workerId,
                usageDateStr, unit, notes ?? ""
            ])
        } catch {
            print("Error recording inventory usage: \(error)")
        }
    }

    func getInventoryUsageHistory(forBuilding buildingId: String) async -> [FrancoSphere.InventoryUsageRecord] {
        guard let sqliteManager = sqliteManager else {
            print("SQLite manager not initialized")
            return []
        }

        do {
            let query = """
            SELECT id, itemId, itemName, quantityUsed, usedBy,
                   usageDate, unit, notes
            FROM inventory_usage
            WHERE buildingId = ?
            ORDER BY usageDate DESC
            LIMIT 100
            """
            
            let rows = try await sqliteManager.query(query, [buildingId])
            
            var records: [FrancoSphere.InventoryUsageRecord] = []
            
            for row in rows {
                guard let id = row["id"] as? Int64,
                      let itemId = row["itemId"] as? String,
                      let itemName = row["itemName"] as? String else {
                    continue
                }
                
                let quantityUsed = Int(row["quantityUsed"] as? Int64 ?? 0)
                let usedBy = row["usedBy"] as? String ?? "Unknown"
                let usageDateStr = row["usageDate"] as? String ?? ""
                let notes = row["notes"] as? String

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let usageDate = dateFormatter.date(from: usageDateStr) ?? Date()

                let record = FrancoSphere.InventoryUsageRecord(
                    id: "\(id)",
                    itemID: itemId,
                    buildingID: buildingId,
                    itemName: itemName,
                    quantityUsed: quantityUsed,
                    usedBy: usedBy,
                    usageDate: usageDate,
                    notes: notes
                )
                records.append(record)
            }
            
            return records
        } catch {
            print("Error getting inventory usage history: \(error)")
            return []
        }
    }

    // MARK: - Sample Data Creation

    private func createSampleInventoryItems(buildingId: String) -> [FrancoSphere.InventoryItem] {
        return [
            FrancoSphere.InventoryItem(
                id: "1",
                name: "All-Purpose Cleaner",
                buildingID: buildingId,
                category: .cleaning,
                quantity: 12,
                unit: "bottles",
                minimumQuantity: 5,
                needsReorder: false,
                lastRestockDate: Date(),
                location: "Janitor Closet",
                notes: "For general cleaning tasks"
            ),
            FrancoSphere.InventoryItem(
                id: "2",
                name: "Light Bulbs (LED)",
                buildingID: buildingId,
                category: .electrical,
                quantity: 30,
                unit: "pieces",
                minimumQuantity: 15,
                needsReorder: false,
                lastRestockDate: Date(),
                location: "Maintenance Room",
                notes: "12W LED bulbs for common areas"
            ),
            FrancoSphere.InventoryItem(
                id: "3",
                name: "Paper Towels",
                buildingID: buildingId,
                category: .cleaning,
                quantity: 24,
                unit: "rolls",
                minimumQuantity: 10,
                needsReorder: false,
                lastRestockDate: Date(),
                location: "Storage Closet",
                notes: "Heavy-duty paper towels"
            ),
            FrancoSphere.InventoryItem(
                id: "4",
                name: "Screwdriver Set",
                buildingID: buildingId,
                category: .tools,
                quantity: 3,
                unit: "sets",
                minimumQuantity: 2,
                needsReorder: true,
                lastRestockDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
                location: "Tool Room",
                notes: "Phillips and flathead screwdrivers"
            ),
            FrancoSphere.InventoryItem(
                id: "5",
                name: "Safety Gloves",
                buildingID: buildingId,
                category: .safety,
                quantity: 50,
                unit: "pairs",
                minimumQuantity: 20,
                needsReorder: false,
                lastRestockDate: Date(),
                location: "Safety Cabinet",
                notes: "Latex-free work gloves"
            )
        ]
    }
}

// MARK: - Thread-Safe Wrapper Class

class InventoryManager {
    static let shared = InventoryManager()
    private let impl = InventoryManagerImpl.shared
    
    private init() {}
    
    func getInventoryItems(forBuilding buildingID: String) -> [FrancoSphere.InventoryItem] {
        // Use a semaphore to wait for async result (for compatibility)
        let semaphore = DispatchSemaphore(value: 0)
        var result: [FrancoSphere.InventoryItem] = []
        
        Task {
            result = await impl.getInventoryItems(forBuilding: buildingID)
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    func getInventoryItemsSafe(forBuilding buildingID: String) -> [FrancoSphere.InventoryItem] {
        // Return immediate sample data without database access
        return [
            FrancoSphere.InventoryItem(
                id: "1",
                name: "All-Purpose Cleaner",
                buildingID: buildingID,
                category: .cleaning,
                quantity: 12,
                unit: "bottles",
                minimumQuantity: 5,
                needsReorder: false,
                lastRestockDate: Date(),
                location: "Janitor Closet",
                notes: "For general cleaning tasks"
            ),
            FrancoSphere.InventoryItem(
                id: "2",
                name: "Light Bulbs (LED)",
                buildingID: buildingID,
                category: .electrical,
                quantity: 30,
                unit: "pieces",
                minimumQuantity: 15,
                needsReorder: false,
                lastRestockDate: Date(),
                location: "Maintenance Room",
                notes: "12W LED bulbs for common areas"
            )
        ]
    }
    
    func getInventoryUsageHistory(forBuilding buildingID: String) -> [FrancoSphere.InventoryUsageRecord] {
        let semaphore = DispatchSemaphore(value: 0)
        var result: [FrancoSphere.InventoryUsageRecord] = []
        
        Task {
            result = await impl.getInventoryUsageHistory(forBuilding: buildingID)
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    func getPendingRestockRequests(forBuilding buildingID: String) -> [FrancoSphere.InventoryRestockRequest] {
        // Return empty array for now - implement async version later
        return []
    }
    
    func updateItemQuantity(itemId: String, newQuantity: Int, workerId: String) -> Bool {
        // Implement async version later
        return true
    }
    
    func recordInventoryUsage(itemId: String, itemName: String, quantityUsed: Int, buildingId: String, workerId: String, unit: String, notes: String) {
        Task {
            await impl.recordInventoryUsage(itemId: itemId, itemName: itemName, quantityUsed: quantityUsed, workerId: workerId, unit: unit, notes: notes)
        }
    }
    
    func createRestockRequest(itemId: String, itemName: String, currentQuantity: Int, requestedQuantity: Int, buildingId: String, requestedBy: String) {
        // Implement async version later
        print("Creating restock request for \(itemName)")
    }
    
    func saveInventoryItem(_ item: FrancoSphere.InventoryItem) -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var result = false
        
        Task {
            result = await impl.saveInventoryItem(item)
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    func deleteInventoryItem(itemId: String) -> Bool {
        // Implement async version later
        return true
    }
    
    func getUsageForItem(itemId: String) -> [FrancoSphere.InventoryUsageRecord] {
        // Return empty array for now
        return []
    }
    
    func updateRestockRequestStatus(requestId: String, status: FrancoSphere.RestockStatus, approvedBy: Int) -> Bool {
        // Implement async version later
        return true
    }
}
