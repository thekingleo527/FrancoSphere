//
//  UserAccountSeeder.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 8/4/25.
//


//
//  UserAccountSeeder.swift
//  CyntientOps (formerly CyntientOps)
//
//  Phase 0A.1: Seed User Accounts with SHA256 Hashing
//  Creates all production user accounts with secure passwords
//

import Foundation
import CryptoKit
import GRDB

@MainActor
public final class UserAccountSeeder {
    
    // MARK: - Dependencies
    private let grdbManager = GRDBManager.shared
    private let authManager = NewAuthManager.shared
    
    // MARK: - User Account Data
    private struct UserAccount {
        let id: String
        let name: String
        let email: String
        let password: String // Will be hashed
        let role: String
        let isActive: Bool
        let capabilities: WorkerCapabilities?
    }
    
    private struct WorkerCapabilities {
        let simplifiedInterface: Bool
        let language: String
        let requiresPhotoForSanitation: Bool
        let canAddEmergencyTasks: Bool
        let eveningModeUI: Bool
    }
    
    // MARK: - Production User Accounts
    private let productionAccounts: [UserAccount] = [
        // System Admin
        UserAccount(
            id: "0",
            name: "System Administrator",
            email: "admin@cyntientops.com",
            password: "CyntientAdmin2025!",
            role: "admin",
            isActive: true,
            capabilities: nil
        ),
        
        // Managers
        UserAccount(
            id: "1",
            name: "Greg Hutson",
            email: "greg.hutson@cyntientops.com",
            password: "GregManager2025!",
            role: "manager",
            isActive: true,
            capabilities: WorkerCapabilities(
                simplifiedInterface: false,
                language: "en",
                requiresPhotoForSanitation: false,
                canAddEmergencyTasks: true,
                eveningModeUI: false
            )
        ),
        UserAccount(
            id: "8",
            name: "Shawn Magloire",
            email: "shawn.magloire@cyntientops.com",
            password: "ShawnHVAC2025!",
            role: "manager",
            isActive: true,
            capabilities: WorkerCapabilities(
                simplifiedInterface: false,
                language: "en",
                requiresPhotoForSanitation: false,
                canAddEmergencyTasks: true,
                eveningModeUI: false
            )
        ),
        
        // Workers
        UserAccount(
            id: "2",
            name: "Edwin Lema",
            email: "edwin.lema@cyntientops.com",
            password: "EdwinPark2025!",
            role: "worker",
            isActive: true,
            capabilities: WorkerCapabilities(
                simplifiedInterface: false,
                language: "en",
                requiresPhotoForSanitation: true,
                canAddEmergencyTasks: false,
                eveningModeUI: false
            )
        ),
        UserAccount(
            id: "4",
            name: "Kevin Dutan",
            email: "kevin.dutan@cyntientops.com",
            password: "KevinRubin2025!",
            role: "worker",
            isActive: true,
            capabilities: WorkerCapabilities(
                simplifiedInterface: false,
                language: "en",
                requiresPhotoForSanitation: true, // Required for sanitation tasks
                canAddEmergencyTasks: false,
                eveningModeUI: false
            )
        ),
        UserAccount(
            id: "5",
            name: "Mercedes Inamagua",
            email: "mercedes.inamagua@cyntientops.com",
            password: "MercedesGlass2025!",
            role: "worker",
            isActive: true,
            capabilities: WorkerCapabilities(
                simplifiedInterface: true, // Simplified Spanish UI
                language: "es",
                requiresPhotoForSanitation: true,
                canAddEmergencyTasks: false,
                eveningModeUI: false
            )
        ),
        UserAccount(
            id: "6",
            name: "Luis Lopez",
            email: "luis.lopez@cyntientops.com",
            password: "LuisPerry2025!",
            role: "worker",
            isActive: true,
            capabilities: WorkerCapabilities(
                simplifiedInterface: false,
                language: "en",
                requiresPhotoForSanitation: true,
                canAddEmergencyTasks: false,
                eveningModeUI: false
            )
        ),
        UserAccount(
            id: "7",
            name: "Angel Guiracocha",
            email: "angel.guiracocha@cyntientops.com",
            password: "AngelDSNY2025!",
            role: "worker",
            isActive: true,
            capabilities: WorkerCapabilities(
                simplifiedInterface: false,
                language: "en",
                requiresPhotoForSanitation: true,
                canAddEmergencyTasks: false,
                eveningModeUI: true // Evening shift UI
            )
        )
    ]
    
    // MARK: - Client User Accounts
    private let clientAccounts: [UserAccount] = [
        // JM Realty
        UserAccount(
            id: "100",
            name: "JM Realty Admin",
            email: "jm@jmrealty.com",
            password: "JMRealty2025!",
            role: "client",
            isActive: true,
            capabilities: nil
        ),
        UserAccount(
            id: "101",
            name: "Sarah Johnson",
            email: "sarah@jmrealty.com",
            password: "SarahJM2025!",
            role: "client",
            isActive: true,
            capabilities: nil
        ),
        
        // Weber Farhat
        UserAccount(
            id: "102",
            name: "David Weber",
            email: "david@weberfarhat.com",
            password: "WeberFarhat2025!",
            role: "client",
            isActive: true,
            capabilities: nil
        ),
        
        // Solar One
        UserAccount(
            id: "103",
            name: "Maria Rodriguez",
            email: "maria@solarone.org",
            password: "SolarOne2025!",
            role: "client",
            isActive: true,
            capabilities: nil
        ),
        
        // Grand Elizabeth
        UserAccount(
            id: "104",
            name: "Robert Chen",
            email: "robert@grandelizabeth.com",
            password: "GrandEliz2025!",
            role: "client",
            isActive: true,
            capabilities: nil
        ),
        
        // Citadel Realty
        UserAccount(
            id: "105",
            name: "Alex Thompson",
            email: "alex@citadelrealty.com",
            password: "Citadel2025!",
            role: "client",
            isActive: true,
            capabilities: nil
        ),
        
        // Corbel Property
        UserAccount(
            id: "106",
            name: "Jennifer Lee",
            email: "jennifer@corbelproperty.com",
            password: "Corbel2025!",
            role: "client",
            isActive: true,
            capabilities: nil
        )
    ]
    
    // MARK: - Public Methods
    
    /// Seed all user accounts
    public func seedAccounts() async throws {
        print("🌱 Starting user account seeding...")
        
        var successCount = 0
        var failureCount = 0
        
        // Seed production accounts (workers and managers)
        for account in productionAccounts {
            do {
                try await seedAccount(account)
                successCount += 1
                print("✅ Seeded account: \(account.name) (\(account.email))")
            } catch {
                failureCount += 1
                print("❌ Failed to seed account \(account.name): \(error)")
            }
        }
        
        // Seed client accounts
        for account in clientAccounts {
            do {
                try await seedAccount(account)
                successCount += 1
                print("✅ Seeded client account: \(account.name) (\(account.email))")
            } catch {
                failureCount += 1
                print("❌ Failed to seed client account \(account.name): \(error)")
            }
        }
        
        // Seed worker capabilities
        try await seedWorkerCapabilities()
        
        print("🎉 Account seeding completed: \(successCount) succeeded, \(failureCount) failed")
    }
    
    // MARK: - Private Methods
    
    private func seedAccount(_ account: UserAccount) async throws {
        // Hash the password
        let hashedPassword = try await hashPassword(account.password, for: account.email)
        
        // Check if account already exists
        let existing = try await grdbManager.query(
            "SELECT id FROM workers WHERE email = ?",
            [account.email]
        )
        
        if !existing.isEmpty {
            // Update existing account
            try await grdbManager.execute("""
                UPDATE workers 
                SET name = ?, password = ?, role = ?, isActive = ?, updated_at = ?
                WHERE email = ?
            """, [
                account.name,
                hashedPassword,
                account.role,
                account.isActive ? 1 : 0,
                Date().ISO8601Format(),
                account.email
            ])
        } else {
            // Insert new account
            try await grdbManager.execute("""
                INSERT INTO workers (id, name, email, password, role, isActive, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, [
                account.id,
                account.name,
                account.email,
                hashedPassword,
                account.role,
                account.isActive ? 1 : 0,
                Date().ISO8601Format(),
                Date().ISO8601Format()
            ])
        }
    }
    
    private func hashPassword(_ password: String, for email: String) async throws -> String {
        // Generate salt
        var salt = Data(count: 32)
        _ = salt.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 32, bytes.baseAddress!)
        }
        
        // Store salt in keychain
        try KeychainManager.shared.save(salt, for: "salt_\(email)")
        
        // Hash password with salt
        let passwordData = Data(password.utf8)
        let saltedPassword = salt + passwordData
        let hash = SHA256.hash(data: saltedPassword)
        
        return Data(hash).base64EncodedString()
    }
    
    private func seedWorkerCapabilities() async throws {
        print("🔧 Seeding worker capabilities...")
        
        // Create worker_capabilities table if it doesn't exist
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS worker_capabilities (
                worker_id TEXT PRIMARY KEY,
                simplified_interface INTEGER DEFAULT 0,
                language TEXT DEFAULT 'en',
                requires_photo_for_sanitation INTEGER DEFAULT 1,
                can_add_emergency_tasks INTEGER DEFAULT 0,
                evening_mode_ui INTEGER DEFAULT 0,
                priority_level INTEGER DEFAULT 0,
                created_at TEXT,
                updated_at TEXT,
                FOREIGN KEY (worker_id) REFERENCES workers(id)
            )
        """)
        
        // Seed capabilities
        for account in productionAccounts where account.capabilities != nil {
            let cap = account.capabilities!
            
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO worker_capabilities (
                    worker_id, can_upload_photos, can_add_notes, can_view_map, 
                    can_add_emergency_tasks, requires_photo_for_sanitation, 
                    simplified_interface, preferred_language
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, [
                account.id,
                1, // can_upload_photos - default enabled
                1, // can_add_notes - default enabled  
                1, // can_view_map - default enabled
                cap.canAddEmergencyTasks ? 1 : 0,
                cap.requiresPhotoForSanitation ? 1 : 0,
                cap.simplifiedInterface ? 1 : 0,
                cap.language
            ])
        }
        
        print("✅ Worker capabilities seeded")
    }
}