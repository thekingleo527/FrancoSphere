// InventoryManager.swift
// FrancoSphere
// Created by Shawn Magloire on 3/3/25.

import Foundation
import SQLite

/// Manages building inventory items, usage, and restock requests.
class InventoryManagerImpl {
    /// Singleton instance of InventoryManagerImpl.
    static let shared = InventoryManagerImpl()

    private init() {
        setupObservers()
        do {
            try createInventoryTables()
        } catch {
            print("Error creating inventory tables during initialization: \(error)")
            // Continue initialization even if tables couldn't be created
            // This prevents app crashes at startup
        }
    }

    // MARK: - Setup Methods

    private func setupObservers() {
        // Placeholder for setting up observers (e.g., NotificationCenter observers)
        print("Setting up observers for InventoryManager")
    }

    private func createInventoryTables() throws {
        guard let db = SQLiteManager.shared.db else {
            print("Database connection not available")
            return
        }

        do {
            try db.run("""
                CREATE TABLE IF NOT EXISTS inventory_items (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    buildingId INTEGER,
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

            try db.run("""
                CREATE TABLE IF NOT EXISTS inventory_usage (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    itemId INTEGER,
                    buildingId INTEGER,
                    itemName TEXT,
                    quantityUsed INTEGER,
                    usedBy INTEGER,
                    usageDate TEXT,
                    unit TEXT,
                    notes TEXT
                )
            """)

            try db.run("""
                CREATE TABLE IF NOT EXISTS restock_requests (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    itemId INTEGER,
                    buildingId INTEGER,
                    itemName TEXT,
                    currentQuantity INTEGER,
                    requestedQuantity INTEGER,
                    requestedBy INTEGER,
                    requestDate TEXT,
                    status TEXT,
                    notes TEXT,
                    approvedBy INTEGER,
                    approvalDate TEXT
                )
            """)

            print("Inventory tables created successfully")
        } catch {
            print("Error creating inventory tables: \(error)")
        }
    }

    // MARK: - Database Operations

    /// Retrieves all inventory items for a specific building.
    func getInventoryItems(forBuilding buildingId: String) -> [FrancoSphere.InventoryItem] {
        var items: [FrancoSphere.InventoryItem] = []
        guard let db = SQLiteManager.shared.db else {
            print("Database connection not available")
            return []
        }

        do {
            let buildingIdInt = Int64(buildingId) ?? 0
            let query = """
            SELECT id, name, category, quantity, unit, minimumQuantity,
                   needsReorder, lastRestockDate, location, notes
            FROM inventory_items
            WHERE buildingId = ?
            ORDER BY name
            """
            let stmt = try db.prepare(query)
            _ = stmt.bind(1, buildingIdInt)

            for row in stmt {
                let id = row[0] as? Int64 ?? 0
                let name = row[1] as? String ?? ""
                let categoryStr = row[2] as? String ?? "other"
                let quantity = Int(row[3] as? Int64 ?? 0)
                let unit = row[4] as? String ?? ""
                let minimumQuantity = Int(row[5] as? Int64 ?? 0)
                let needsReorder = (row[6] as? Int64 ?? 0) != 0
                let lastRestockDateStr = row[7] as? String
                let location = row[8] as? String ?? ""
                let notes = row[9] as? String

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
        } catch {
            print("Error getting inventory items: \(error)")
        }

        if items.isEmpty {
            items = createInitialInventoryForBuilding(buildingId: buildingId)
        }

        return items
    }

    /// Retrieves inventory items for a building filtered by category.
    func getInventoryItems(forBuilding buildingId: String, category: FrancoSphere.InventoryCategory) -> [FrancoSphere.InventoryItem] {
        let allItems = getInventoryItems(forBuilding: buildingId)
        return allItems.filter { $0.category == category }
    }

    /// Retrieves items needing reorder for a building.
    func getItemsNeedingReorder(forBuilding buildingId: String) -> [FrancoSphere.InventoryItem] {
        let allItems = getInventoryItems(forBuilding: buildingId)
        return allItems.filter { $0.shouldReorder }
    }

    /// Saves or updates an inventory item in the database.
    func saveInventoryItem(_ item: FrancoSphere.InventoryItem) -> Bool {
        guard let db = SQLiteManager.shared.db else {
            print("Database connection not available")
            return false
        }

        do {
            let buildingIdInt = Int64(item.buildingID) ?? 0
            let itemIdInt = Int64(item.id) ?? 0
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let lastRestockDateStr = dateFormatter.string(from: item.lastRestockDate)

            let checkQuery = "SELECT id FROM inventory_items WHERE id = ?"
            let checkStmt = try db.prepare(checkQuery)
            _ = checkStmt.bind(1, itemIdInt)
            let exists = try checkStmt.step()

            if exists {
                // Update existing item
                let updateQuery = """
                UPDATE inventory_items SET
                    name = ?, category = ?, quantity = ?, unit = ?,
                    minimumQuantity = ?, needsReorder = ?, lastRestockDate = ?,
                    location = ?, notes = ?
                WHERE id = ?
                """
                let updateStmt = try db.prepare(updateQuery)
                _ = updateStmt.bind(1, item.name)
                _ = updateStmt.bind(2, item.category.rawValue)
                _ = updateStmt.bind(3, item.quantity)
                _ = updateStmt.bind(4, item.unit)
                _ = updateStmt.bind(5, item.minimumQuantity)
                _ = updateStmt.bind(6, item.needsReorder ? 1 : 0)
                _ = updateStmt.bind(7, lastRestockDateStr)
                _ = updateStmt.bind(8, item.location)
                _ = updateStmt.bind(9, item.notes)
                _ = updateStmt.bind(10, itemIdInt)
                _ = try updateStmt.step()
            } else {
                // Insert new item
                let insertQuery = """
                INSERT INTO inventory_items (
                    name, buildingId, category, quantity, unit,
                    minimumQuantity, needsReorder, lastRestockDate, location, notes
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """
                let insertStmt = try db.prepare(insertQuery)
                _ = insertStmt.bind(1, item.name)
                _ = insertStmt.bind(2, buildingIdInt)
                _ = insertStmt.bind(3, item.category.rawValue)
                _ = insertStmt.bind(4, item.quantity)
                _ = insertStmt.bind(5, item.unit)
                _ = insertStmt.bind(6, item.minimumQuantity)
                _ = insertStmt.bind(7, item.needsReorder ? 1 : 0)
                _ = insertStmt.bind(8, lastRestockDateStr)
                _ = insertStmt.bind(9, item.location)
                _ = insertStmt.bind(10, item.notes)
                _ = try insertStmt.step()
            }

            NotificationCenter.default.post(
                name: Notification.Name("InventoryItemUpdated"),
                object: nil,
                userInfo: ["buildingId": item.buildingID]
            )
            return true
        } catch {
            print("Error saving inventory item: \(error)")
            return false
        }
    }

    /// Updates the quantity of an inventory item and handles usage/restock logic.
    func updateItemQuantity(itemId: String, newQuantity: Int, workerId: Int64) -> Bool {
        guard let db = SQLiteManager.shared.db else {
            print("Database connection not available")
            return false
        }

        do {
            let itemIdInt = Int64(itemId) ?? 0
            let itemQuery = """
            SELECT quantity, name, buildingId, unit, minimumQuantity
            FROM inventory_items
            WHERE id = ?
            """
            let itemStmt = try db.prepare(itemQuery)
            _ = itemStmt.bind(1, itemIdInt)

            var currentQuantity: Int64 = 0
            var itemName: String = ""
            var buildingId: String = ""
            var unit: String = ""
            var minimumQuantity: Int64 = 0

            for row in itemStmt {
                currentQuantity = row[0] as? Int64 ?? 0
                itemName = row[1] as? String ?? ""
                buildingId = "\(row[2] as? Int64 ?? 0)"
                unit = row[3] as? String ?? ""
                minimumQuantity = row[4] as? Int64 ?? 0
                break // Only expect one row
            }

            if currentQuantity == 0 && itemName.isEmpty {
                print("Item not found with ID: \(itemId)")
                return false
            }

            let quantityChange = newQuantity - Int(currentQuantity)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateStr = quantityChange > 0 ? dateFormatter.string(from: Date()) : ""
            let needsReorder = newQuantity <= Int(minimumQuantity) ? 1 : 0

            let updateQuery = """
            UPDATE inventory_items SET
                quantity = ?, needsReorder = ?, lastRestockDate = ?
            WHERE id = ?
            """
            let updateStmt = try db.prepare(updateQuery)
            _ = updateStmt.bind(1, newQuantity)
            _ = updateStmt.bind(2, needsReorder)
            _ = updateStmt.bind(3, dateStr)
            _ = updateStmt.bind(4, itemIdInt)
            _ = try updateStmt.step()

            if quantityChange < 0 {
                recordInventoryUsage(
                    itemId: itemId,
                    itemName: itemName,
                    quantityUsed: abs(quantityChange),
                    workerId: workerId,
                    unit: unit
                )
            }

            if newQuantity <= Int(minimumQuantity) {
                createRestockRequest(
                    itemId: itemId,
                    itemName: itemName,
                    currentQuantity: newQuantity,
                    requestedQuantity: Int(minimumQuantity) * 2,
                    buildingId: buildingId,
                    requestedBy: workerId
                )
            }

            NotificationCenter.default.post(
                name: Notification.Name("InventoryItemUpdated"),
                object: nil,
                userInfo: ["buildingId": buildingId]
            )
            return true
        } catch {
            print("Error updating item quantity: \(error)")
            return false
        }
    }

    /// Deletes an inventory item from the database.
    func deleteInventoryItem(itemId: String) -> Bool {
        guard let db = SQLiteManager.shared.db else {
            print("Database connection not available")
            return false
        }

        do {
            let itemIdInt = Int64(itemId) ?? 0
            let buildingQuery = "SELECT buildingId FROM inventory_items WHERE id = ?"
            let buildingStmt = try db.prepare(buildingQuery)
            _ = buildingStmt.bind(1, itemIdInt)
            var buildingId: String?

            for row in buildingStmt {
                buildingId = "\(row[0] as? Int64 ?? 0)"
                break // Only expect one row
            }

            let deleteQuery = "DELETE FROM inventory_items WHERE id = ?"
            let deleteStmt = try db.prepare(deleteQuery)
            _ = deleteStmt.bind(1, itemIdInt)
            _ = try deleteStmt.step()

            if let buildingId = buildingId {
                NotificationCenter.default.post(
                    name: Notification.Name("InventoryItemUpdated"),
                    object: nil,
                    userInfo: ["buildingId": buildingId]
                )
            }
            return true
        } catch {
            print("Error deleting inventory item: \(error)")
            return false
        }
    }

    // MARK: - Inventory Usage

    /// Records usage of an inventory item.
    func recordInventoryUsage(itemId: String, itemName: String, quantityUsed: Int, workerId: Int64, unit: String, notes: String? = nil) {
        guard let db = SQLiteManager.shared.db else {
            print("Database connection not available")
            return
        }

        do {
            let itemIdInt = Int64(itemId) ?? 0
            let buildingIdQuery = "SELECT buildingId FROM inventory_items WHERE id = ?"
            let buildingStmt = try db.prepare(buildingIdQuery)
            _ = buildingStmt.bind(1, itemIdInt)
            var buildingIdInt: Int64 = 0

            for row in buildingStmt {
                buildingIdInt = row[0] as? Int64 ?? 0
                break // Only expect one row
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let usageDateStr = dateFormatter.string(from: Date())

            let insertQuery = """
            INSERT INTO inventory_usage (
                itemId, buildingId, itemName, quantityUsed, usedBy,
                usageDate, unit, notes
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """
            let insertStmt = try db.prepare(insertQuery)
            _ = insertStmt.bind(1, itemIdInt)
            _ = insertStmt.bind(2, buildingIdInt)
            _ = insertStmt.bind(3, itemName)
            _ = insertStmt.bind(4, quantityUsed)
            _ = insertStmt.bind(5, workerId)
            _ = insertStmt.bind(6, usageDateStr)
            _ = insertStmt.bind(7, unit)
            _ = insertStmt.bind(8, notes)
            _ = try insertStmt.step()
        } catch {
            print("Error recording inventory usage: \(error)")
        }
    }

    /// Retrieves usage history for a building.
    func getInventoryUsageHistory(forBuilding buildingId: String) -> [FrancoSphere.InventoryUsageRecord] {
        var records: [FrancoSphere.InventoryUsageRecord] = []
        guard let db = SQLiteManager.shared.db else {
            print("Database connection not available")
            return []
        }

        do {
            let buildingIdInt = Int64(buildingId) ?? 0
            let query = """
            SELECT iu.id, iu.itemId, iu.itemName, iu.quantityUsed, iu.usedBy,
                   iu.usageDate, iu.unit, iu.notes, w.name
            FROM inventory_usage iu
            LEFT JOIN workers w ON iu.usedBy = w.id
            WHERE iu.buildingId = ?
            ORDER BY iu.usageDate DESC
            LIMIT 100
            """
            let stmt = try db.prepare(query)
            _ = stmt.bind(1, buildingIdInt)

            for row in stmt {
                let id = row[0] as? Int64 ?? 0
                let itemId = "\(row[1] as? Int64 ?? 0)"
                let itemName = row[2] as? String ?? ""
                let quantityUsed = row[3] as? Int64 ?? 0
                let usageDateStr = row[5] as? String ?? ""
                _ = row[6] as? String ?? ""
                let notes = row[7] as? String
                let workerName = row[8] as? String ?? "Unknown Worker"

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let usageDate = dateFormatter.date(from: usageDateStr) ?? Date()

                let record = FrancoSphere.InventoryUsageRecord(
                    id: "\(id)",
                    itemID: itemId,
                    buildingID: buildingId,
                    itemName: itemName,
                    quantityUsed: Int(quantityUsed),
                    usedBy: workerName,
                    usageDate: usageDate,
                    notes: notes
                )
                records.append(record)
            }
        } catch {
            print("Error getting inventory usage history: \(error)")
        }

        return records
    }

    /// Retrieves usage history for a specific item.
    func getUsageForItem(itemId: String) -> [FrancoSphere.InventoryUsageRecord] {
        var records: [FrancoSphere.InventoryUsageRecord] = []
        guard let db = SQLiteManager.shared.db else {
            print("Database connection not available")
            return []
        }

        do {
            let itemIdInt = Int64(itemId) ?? 0
            let query = """
            SELECT iu.id, iu.buildingId, iu.itemName, iu.quantityUsed, iu.usedBy,
                   iu.usageDate, iu.unit, iu.notes, w.name
            FROM inventory_usage iu
            LEFT JOIN workers w ON iu.usedBy = w.id
            WHERE iu.itemId = ?
            ORDER BY iu.usageDate DESC
            LIMIT 50
            """
            let stmt = try db.prepare(query)
            _ = stmt.bind(1, itemIdInt)

            for row in stmt {
                let id = row[0] as? Int64 ?? 0
                let buildingId = "\(row[1] as? Int64 ?? 0)"
                let itemName = row[2] as? String ?? ""
                let quantityUsed = row[3] as? Int64 ?? 0
                let usageDateStr = row[5] as? String ?? ""
                _ = row[6] as? String ?? ""
                let notes = row[7] as? String
                let workerName = row[8] as? String ?? "Unknown Worker"

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let usageDate = dateFormatter.date(from: usageDateStr) ?? Date()

                let record = FrancoSphere.InventoryUsageRecord(
                    id: "\(id)",
                    itemID: itemId,
                    buildingID: buildingId,
                    itemName: itemName,
                    quantityUsed: Int(quantityUsed),
                    usedBy: workerName,
                    usageDate: usageDate,
                    notes: notes
                )
                records.append(record)
            }
        } catch {
            print("Error getting usage for item: \(error)")
        }

        return records
    }

    // MARK: - Restock Requests

    /// Creates a restock request for an item.
    func createRestockRequest(
        itemId: String,
        itemName: String,
        currentQuantity: Int,
        requestedQuantity: Int,
        buildingId: String,
        requestedBy: Int64,
        notes: String? = nil
    ) {
        guard let db = SQLiteManager.shared.db else {
            print("Database connection not available")
            return
        }

        do {
            let buildingIdInt = Int64(buildingId) ?? 0
            let itemIdInt = Int64(itemId) ?? 0
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let requestDateStr = dateFormatter.string(from: Date())

            let checkQuery = """
            SELECT id FROM restock_requests
            WHERE itemId = ? AND status = 'Pending'
            """
            let checkStmt = try db.prepare(checkQuery)
            _ = checkStmt.bind(1, itemIdInt)
            if try checkStmt.step() {
                print("Existing restock request found for item \(itemId)")
                return
            }

            let insertQuery = """
            INSERT INTO restock_requests (
                itemId, buildingId, itemName, currentQuantity, requestedQuantity,
                requestedBy, requestDate, status, notes
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            let insertStmt = try db.prepare(insertQuery)
            _ = insertStmt.bind(1, itemIdInt)
            _ = insertStmt.bind(2, buildingIdInt)
            _ = insertStmt.bind(3, itemName)
            _ = insertStmt.bind(4, currentQuantity)
            _ = insertStmt.bind(5, requestedQuantity)
            _ = insertStmt.bind(6, requestedBy)
            _ = insertStmt.bind(7, requestDateStr)
            _ = insertStmt.bind(8, FrancoSphere.RestockStatus.pending.rawValue)
            _ = insertStmt.bind(9, notes)
            _ = try insertStmt.step()

            NotificationCenter.default.post(
                name: Notification.Name("RestockRequestCreated"),
                object: nil,
                userInfo: ["buildingId": buildingId, "itemName": itemName]
            )
        } catch {
            print("Error creating restock request: \(error)")
        }
    }

    /// Retrieves pending or approved restock requests for a building.
    func getPendingRestockRequests(forBuilding buildingId: String) -> [FrancoSphere.InventoryRestockRequest] {
        var requests: [FrancoSphere.InventoryRestockRequest] = []
        guard let db = SQLiteManager.shared.db else {
            print("Database connection not available")
            return []
        }

        do {
            let buildingIdInt = Int64(buildingId) ?? 0
            let query = """
            SELECT rr.id, rr.itemId, rr.itemName, rr.currentQuantity, rr.requestedQuantity,
                   rr.requestedBy, rr.requestDate, rr.status, rr.notes, rr.approvedBy, rr.approvalDate,
                   w.name
            FROM restock_requests rr
            LEFT JOIN workers w ON rr.requestedBy = w.id
            WHERE rr.buildingId = ? AND (rr.status = 'Pending' OR rr.status = 'Approved')
            ORDER BY rr.requestDate DESC
            """
            let stmt = try db.prepare(query)
            _ = stmt.bind(1, buildingIdInt)

            for row in stmt {
                let id = row[0] as? Int64 ?? 0
                let itemId = "\(row[1] as? Int64 ?? 0)"
                let itemName = row[2] as? String ?? ""
                let currentQuantity = row[3] as? Int64 ?? 0
                let requestedQuantity = row[4] as? Int64 ?? 0
                _ = row[5] as? Int64 ?? 0
                let requestDateStr = row[6] as? String ?? ""
                let statusStr = row[7] as? String ?? "Pending"
                let notes = row[8] as? String
                let approvedByInt = row[9] as? Int64
                let approvalDateStr = row[10] as? String
                let requestedByName = row[11] as? String ?? "Unknown Worker"

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let requestDate = dateFormatter.date(from: requestDateStr) ?? Date()
                let approvalDate = approvalDateStr != nil ? dateFormatter.date(from: approvalDateStr!) : nil

                let status = FrancoSphere.RestockStatus(rawValue: statusStr) ?? .pending
                let approvedBy = approvedByInt != nil ? "\(approvedByInt!)" : nil

                let request = FrancoSphere.InventoryRestockRequest(
                    id: "\(id)",
                    itemID: itemId,
                    buildingID: buildingId,
                    itemName: itemName,
                    currentQuantity: Int(currentQuantity),
                    requestedQuantity: Int(requestedQuantity),
                    requestedBy: requestedByName,
                    requestDate: requestDate,
                    status: status,
                    notes: notes,
                    approvedBy: approvedBy,
                    approvalDate: approvalDate
                )
                requests.append(request)
            }
        } catch {
            print("Error getting pending restock requests: \(error)")
        }

        return requests
    }

    /// Updates the status of a restock request and adjusts inventory if fulfilled.
    func updateRestockRequestStatus(requestId: String, status: FrancoSphere.RestockStatus, approvedBy: Int64) -> Bool {
        guard let db = SQLiteManager.shared.db else {
            print("Database connection not available")
            return false
        }

        do {
            // First update the restock request status
            let updateQuery = """
            UPDATE restock_requests SET
                status = ?, approvedBy = ?, approvalDate = ?
            WHERE id = ?
            """
            
            let requestIdInt = Int64(requestId) ?? 0
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let approvalDateStr = dateFormatter.string(from: Date())
            
            try db.run(updateQuery, [status.rawValue, approvedBy, approvalDateStr, requestIdInt])
            
            // If the status is fulfilled, we need to update the inventory item quantity
            if status == .fulfilled {
                // Get the item ID and requested quantity in a separate query
                let requestQuery = "SELECT itemId, requestedQuantity FROM restock_requests WHERE id = ?"
                let result = try db.prepare(requestQuery, [requestIdInt])
                
                guard let row = result.next() else {
                    print("No restock request found with ID: \(requestId)")
                    return true
                }
                
                let itemId = row[0] as! Int64
                let requestedQuantity = row[1] as! Int64
                
                // Get the current quantity in a separate query
                let itemQuery = "SELECT quantity FROM inventory_items WHERE id = ?"
                let itemResult = try db.prepare(itemQuery, [itemId])
                
                guard let itemRow = itemResult.next() else {
                    print("No inventory item found with ID: \(itemId)")
                    return true
                }
                
                let currentQuantity = itemRow[0] as! Int64
                
                // Update the inventory item in a separate query
                let updateItemQuery = """
                UPDATE inventory_items SET
                    quantity = ?, needsReorder = 0, lastRestockDate = ?
                WHERE id = ?
                """
                
                try db.run(updateItemQuery, [Int(currentQuantity) + Int(requestedQuantity), approvalDateStr, itemId])
            }
            
            return true
        } catch {
            print("Error updating restock request status: \(error)")
            return false
        }
    }

    private func createInitialInventoryForBuilding(buildingId: String) -> [FrancoSphere.InventoryItem] {
        print("Creating initial inventory for building \(buildingId)")
        
        // If database is empty, return sample inventory items consistent with InventoryView's model
        return FrancoSphere.InventoryItem.commonInventoryItems(for: buildingId)
    }
}

// Create a class alias for compatibility with InventoryView
class InventoryManager {
    static let shared = InventoryManager()
    private let impl = InventoryManagerImpl.shared
    
    func getInventoryItems(forBuilding buildingID: String) -> [FrancoSphere.InventoryItem] {
        return impl.getInventoryItems(forBuilding: buildingID)
    }
    
    // New safe method that bypasses database access
    func getInventoryItemsSafe(forBuilding buildingID: String) -> [FrancoSphere.InventoryItem] {
        // Return hardcoded sample data instead of hitting the database
        print("Using SAFE mock inventory data for building \(buildingID)")
        return FrancoSphere.InventoryItem.commonInventoryItems(for: buildingID)
    }
    
    func getInventoryUsageHistory(forBuilding buildingID: String) -> [FrancoSphere.InventoryUsageRecord] {
        return impl.getInventoryUsageHistory(forBuilding: buildingID)
    }
    
    func getPendingRestockRequests(forBuilding buildingID: String) -> [FrancoSphere.InventoryRestockRequest] {
        return impl.getPendingRestockRequests(forBuilding: buildingID)
    }
    
    func updateItemQuantity(itemId: String, newQuantity: Int, workerId: String) -> Bool {
        return impl.updateItemQuantity(itemId: itemId, newQuantity: newQuantity, workerId: Int64(workerId) ?? 0)
    }
    
    func recordInventoryUsage(itemId: String, itemName: String, quantityUsed: Int, buildingId: String, workerId: String, unit: String, notes: String) {
        impl.recordInventoryUsage(itemId: itemId, itemName: itemName, quantityUsed: quantityUsed, workerId: Int64(workerId) ?? 0, unit: unit, notes: notes)
    }
    
    func createRestockRequest(itemId: String, itemName: String, currentQuantity: Int, requestedQuantity: Int, buildingId: String, requestedBy: String) {
        impl.createRestockRequest(itemId: itemId, itemName: itemName, currentQuantity: currentQuantity, requestedQuantity: requestedQuantity, buildingId: buildingId, requestedBy: Int64(requestedBy) ?? 0)
    }
    
    func saveInventoryItem(_ item: FrancoSphere.InventoryItem) -> Bool {
        return impl.saveInventoryItem(item)
    }
    
    func deleteInventoryItem(itemId: String) -> Bool {
        return impl.deleteInventoryItem(itemId: itemId)
    }
    
    func getUsageForItem(itemId: String) -> [FrancoSphere.InventoryUsageRecord] {
        return impl.getUsageForItem(itemId: itemId)
    }
    
    func updateRestockRequestStatus(requestId: String, status: FrancoSphere.RestockStatus, approvedBy: Int) -> Bool {
        return impl.updateRestockRequestStatus(requestId: requestId, status: status, approvedBy: Int64(approvedBy))
    }
}
