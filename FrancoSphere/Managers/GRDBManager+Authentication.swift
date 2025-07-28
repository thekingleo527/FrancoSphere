//
//  GRDBManager+Authentication.swift
//  FrancoSphere
//
//  Authentication extension for GRDBManager
//  Adds auth methods without modifying the original file
//

import Foundation
import GRDB

extension GRDBManager {
    
    // MARK: - Authentication Methods
    
    /// Authenticate worker with email and password
    public func authenticateWorker(email: String, password: String) async -> AuthenticationResult {
        do {
            // Check if account is locked
            if try await isAccountLocked(email: email) {
                await recordLoginAttempt(email: email, success: false, reason: "Account locked")
                return .failure("Account is temporarily locked due to multiple failed attempts")
            }
            
            // Fetch worker
            let rows = try await query("""
                SELECT * FROM workers 
                WHERE email = ? AND isActive = 1
            """, [email])
            
            guard let row = rows.first else {
                await recordLoginAttempt(email: email, success: false, reason: "User not found")
                return .failure("Invalid credentials")
            }
            
            // Verify password
            let storedPassword = row["password"] as? String ?? ""
            guard storedPassword == password else {
                try await incrementLoginAttempts(email: email)
                await recordLoginAttempt(email: email, success: false, reason: "Invalid password")
                return .failure("Invalid credentials")
            }
            
            // Success - reset attempts and update last login
            try await execute("""
                UPDATE workers 
                SET loginAttempts = 0, 
                    lockedUntil = NULL,
                    lastLogin = datetime('now'),
                    updated_at = datetime('now')
                WHERE email = ?
            """, [email])
            
            await recordLoginAttempt(email: email, success: true, reason: nil)
            
            // Create authenticated user object
            let user = AuthenticatedUser(
                id: Int(row["id"] as? Int64 ?? 0),
                name: row["name"] as? String ?? "",
                email: email,
                password: "", // Don't return password
                role: row["role"] as? String ?? "worker",
                workerId: String(row["id"] as? Int64 ?? 0),
                displayName: row["display_name"] as? String,
                timezone: row["timezone"] as? String ?? "America/New_York"
            )
            
            return .success(user)
            
        } catch {
            print("❌ Authentication error: \(error)")
            return .failure("Authentication failed: \(error.localizedDescription)")
        }
    }
    
    /// Create a new user session
    public func createSession(for workerId: String, deviceInfo: String = "iOS App") async throws -> String {
        let sessionId = UUID().uuidString
        let expiresAt = Date().addingTimeInterval(24 * 60 * 60) // 24 hours
        
        try await execute("""
            INSERT INTO user_sessions 
            (session_id, worker_id, device_info, ip_address, login_time, last_activity, expires_at, is_active)
            VALUES (?, ?, ?, ?, datetime('now'), datetime('now'), ?, 1)
        """, [sessionId, workerId, deviceInfo, "127.0.0.1", ISO8601DateFormatter().string(from: expiresAt)])
        
        return sessionId
    }
    
    /// Validate an existing session
    public func validateSession(_ sessionId: String) async throws -> AuthenticatedUser? {
        let rows = try await query("""
            SELECT 
                w.*, s.expires_at
            FROM user_sessions s
            JOIN workers w ON s.worker_id = w.id
            WHERE s.session_id = ? AND s.is_active = 1 AND w.isActive = 1
        """, [sessionId])
        
        guard let row = rows.first else { return nil }
        
        // Check if session expired
        if let expiresAtString = row["expires_at"] as? String,
           let expiresAt = ISO8601DateFormatter().date(from: expiresAtString),
           Date() > expiresAt {
            // Deactivate expired session
            try await execute("UPDATE user_sessions SET is_active = 0 WHERE session_id = ?", [sessionId])
            return nil
        }
        
        // Update last activity
        try await execute("""
            UPDATE user_sessions 
            SET last_activity = datetime('now') 
            WHERE session_id = ?
        """, [sessionId])
        
        return AuthenticatedUser(
            id: Int(row["id"] as? Int64 ?? 0),
            name: row["name"] as? String ?? "",
            email: row["email"] as? String ?? "",
            password: "", // Don't return password
            role: row["role"] as? String ?? "worker",
            workerId: String(row["id"] as? Int64 ?? 0),
            displayName: row["display_name"] as? String,
            timezone: row["timezone"] as? String ?? "America/New_York"
        )
    }
    
    /// Logout - deactivate all sessions for a worker
    public func logout(workerId: String) async throws {
        try await execute("""
            UPDATE user_sessions 
            SET is_active = 0, last_activity = datetime('now')
            WHERE worker_id = ? AND is_active = 1
        """, [workerId])
    }
    
    // MARK: - Security Features (Private)
    
    private func isAccountLocked(email: String) async throws -> Bool {
        let rows = try await query("""
            SELECT loginAttempts, lockedUntil FROM workers WHERE email = ?
        """, [email])
        
        guard let row = rows.first else { return false }
        
        let attempts = row["loginAttempts"] as? Int64 ?? 0
        let lockedUntilString = row["lockedUntil"] as? String
        
        if attempts >= 5 {
            if let lockedUntilString = lockedUntilString,
               let lockedUntil = ISO8601DateFormatter().date(from: lockedUntilString),
               Date() < lockedUntil {
                return true
            } else {
                // Reset if lock period expired
                try await execute("""
                    UPDATE workers SET loginAttempts = 0, lockedUntil = NULL WHERE email = ?
                """, [email])
            }
        }
        
        return false
    }
    
    private func incrementLoginAttempts(email: String) async throws {
        let rows = try await query("SELECT loginAttempts FROM workers WHERE email = ?", [email])
        let currentAttempts = rows.first?["loginAttempts"] as? Int64 ?? 0
        let newAttempts = currentAttempts + 1
        
        var lockedUntil: String? = nil
        if newAttempts >= 5 {
            // Lock for 30 minutes
            let lockTime = Date().addingTimeInterval(30 * 60)
            lockedUntil = ISO8601DateFormatter().string(from: lockTime)
        }
        
        try await execute("""
            UPDATE workers 
            SET loginAttempts = ?, lockedUntil = ?, updated_at = datetime('now')
            WHERE email = ?
        """, [newAttempts, lockedUntil as Any, email])
    }
    
    private func recordLoginAttempt(email: String, success: Bool, reason: String?) async {
        do {
            let workerRows = try await query("SELECT id FROM workers WHERE email = ?", [email])
            let workerId = workerRows.first?["id"] as? Int64
            
            try await execute("""
                INSERT INTO login_history 
                (worker_id, email, login_time, success, failure_reason, ip_address, device_info)
                VALUES (?, ?, datetime('now'), ?, ?, ?, ?)
            """, [workerId as Any, email, success ? 1 : 0, reason as Any, "127.0.0.1", "iOS App"])
        } catch {
            print("⚠️ Failed to record login attempt: \(error)")
        }
    }
    
    // MARK: - User Management
    
    /// Get all users (workers) with optional filtering
    public func getAllUsers(includeInactive: Bool = false) async throws -> [AuthenticatedUser] {
        let condition = includeInactive ? "" : "WHERE isActive = 1"
        
        let rows = try await query("""
            SELECT * FROM workers
            \(condition)
            ORDER BY name
        """)
        
        return rows.map { row in
            AuthenticatedUser(
                id: Int(row["id"] as? Int64 ?? 0),
                name: row["name"] as? String ?? "",
                email: row["email"] as? String ?? "",
                password: "", // Don't return passwords
                role: row["role"] as? String ?? "worker",
                workerId: String(row["id"] as? Int64 ?? 0),
                displayName: row["display_name"] as? String,
                timezone: row["timezone"] as? String ?? "America/New_York"
            )
        }
    }
    
    /// Get authentication statistics
    public func getAuthenticationStats() async throws -> [String: Any] {
        var stats: [String: Any] = [:]
        
        // Total active users
        let userCount = try await query("SELECT COUNT(*) as count FROM workers WHERE isActive = 1")
        stats["totalActiveUsers"] = userCount.first?["count"] as? Int64 ?? 0
        
        // Users by role
        let roleStats = try await query("""
            SELECT role, COUNT(*) as count FROM workers 
            WHERE isActive = 1 
            GROUP BY role
        """)
        
        var roleBreakdown: [String: Int64] = [:]
        for row in roleStats {
            if let role = row["role"] as? String, let count = row["count"] as? Int64 {
                roleBreakdown[role] = count
            }
        }
        stats["usersByRole"] = roleBreakdown
        
        // Active sessions
        let activeSessions = try await query("""
            SELECT COUNT(*) as count FROM user_sessions 
            WHERE is_active = 1 AND expires_at > datetime('now')
        """)
        stats["activeSessions"] = activeSessions.first?["count"] as? Int64 ?? 0
        
        // Recent login activity
        let recentLogins = try await query("""
            SELECT COUNT(*) as count FROM login_history 
            WHERE login_time >= datetime('now', '-7 days') AND success = 1
        """)
        stats["successfulLoginsLast7Days"] = recentLogins.first?["count"] as? Int64 ?? 0
        
        return stats
    }
}
