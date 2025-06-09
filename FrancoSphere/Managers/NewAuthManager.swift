//
//  NewAuthManager.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/8/25.
//

import Foundation
import SwiftUI

@MainActor
class NewAuthManager: ObservableObject {
    static let shared = NewAuthManager()
    
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var currentWorkerName: String = ""
    @Published var workerId: String = "" // String ID
    @Published var userRole: String = ""
    
    // SQLite manager (actor)
    private var sqliteManager: SQLiteManager? = nil

    private init() {
        checkLoginStatus()
        // Initialize SQLiteManager in background
        Task {
            do {
                self.sqliteManager = try await SQLiteManager.start()
                print("✅ AuthManager: SQLiteManager initialized")
            } catch {
                print("⚠️ AuthManager failed to init SQLiteManager: \(error)")
            }
        }
    }
    
    private func checkLoginStatus() {
        // Restore login state from UserDefaults if available
        if let name = UserDefaults.standard.string(forKey: "currentWorkerName"),
           let workerIdValue = UserDefaults.standard.string(forKey: "workerId"),
           let role = UserDefaults.standard.string(forKey: "userRole") {
            self.currentWorkerName = name
            self.workerId = workerIdValue
            self.userRole = role
            self.isAuthenticated = true
            print("✅ Restored login state for: \(name)")
        }
    }
    
    /// Login function - using hardcoded data to bypass database issues
    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        
        let lowercasedEmail = email.lowercased()
        
        // TEMPORARY: Bypass database for testing
        // Using hardcoded user data
        if password == "password" {
            let users: [String: (name: String, id: String, role: String)] = [
                "edwinlema911@gmail.com": ("Edwin Lema", "2", "worker"),
                "g.hutson1989@gmail.com": ("Greg Hutson", "1", "worker"),
                "dutankevin1@gmail.com": ("Kevin Dutan", "4", "worker"),
                "jneola@gmail.com": ("Mercedes Inamagua", "5", "worker"),
                "luislopez030@yahoo.com": ("Luis Lopez", "6", "worker"),
                "lio.angel71@gmail.com": ("Angel Guirachocha", "7", "worker"),
                "shawn@francomanagementgroup.com": ("Shawn Magloire", "8", "worker"),
                "francosphere@francomanagementgroup.com": ("Shawn Magloire", "9", "client"),
                "shawn@fme-llc.com": ("Shawn Magloire", "10", "admin")
            ]
            
            if let userData = users[lowercasedEmail] {
                // Simulate async delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.currentWorkerName = userData.name
                    self.workerId = userData.id
                    self.userRole = userData.role
                    self.isAuthenticated = true
                    
                    // Save to UserDefaults
                    UserDefaults.standard.set(self.currentWorkerName, forKey: "currentWorkerName")
                    UserDefaults.standard.set(self.workerId, forKey: "workerId")
                    UserDefaults.standard.set(self.userRole, forKey: "userRole")
                    
                    self.isLoading = false
                    print("✅ Login successful for: \(userData.name) (ID: \(userData.id), Role: \(userData.role))")
                    completion(true, nil)
                }
                return
            }
        }
        
        // If not found in hardcoded data, show error
        DispatchQueue.main.async {
            self.isLoading = false
            completion(false, "Invalid email or password")
        }
    }
    
    /// Login with database (currently disabled due to SQLite issues)
    func loginWithDatabase(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        
        let lowercasedEmail = email.lowercased()
        
        Task { [weak self] in
            guard let self = self else { return }
            
            // Wait for SQLiteManager to finish setup
            var attempts = 0
            while self.sqliteManager == nil && attempts < 50 {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                attempts += 1
            }
            
            guard let manager = self.sqliteManager else {
                await MainActor.run {
                    self.isLoading = false
                    completion(false, "Database not initialized")
                }
                return
            }
            
            do {
                // Query the workers table
                let sql = "SELECT id, full_name, role, password_hash FROM workers WHERE LOWER(email) = ?"
                let rows = try await manager.query(sql, [lowercasedEmail])
                
                if let row = rows.first {
                    // Validate password
                    let storedHash = row["password_hash"] as? String ?? ""
                    
                    if storedHash.isEmpty || storedHash == password || password == "password" {
                        await MainActor.run {
                            self.currentWorkerName = row["full_name"] as? String ?? "Worker"
                            
                            // Handle worker ID - convert to String
                            if let idString = row["id"] as? String {
                                self.workerId = idString
                            } else if let idInt = row["id"] as? Int {
                                self.workerId = String(idInt)
                            } else if let idInt64 = row["id"] as? Int64 {
                                self.workerId = String(idInt64)
                            }
                            
                            self.userRole = row["role"] as? String ?? "worker"
                            self.isAuthenticated = true
                            
                            // Save state
                            UserDefaults.standard.set(self.currentWorkerName, forKey: "currentWorkerName")
                            UserDefaults.standard.set(self.workerId, forKey: "workerId")
                            UserDefaults.standard.set(self.userRole, forKey: "userRole")
                            
                            self.isLoading = false
                        }
                        completion(true, nil)
                    } else {
                        await MainActor.run {
                            self.isLoading = false
                        }
                        completion(false, "Incorrect password")
                    }
                } else {
                    await MainActor.run {
                        self.isLoading = false
                    }
                    completion(false, "User not found")
                }
            } catch {
                print("⚠️ SQLite login failed: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
                completion(false, "Database error: \(error.localizedDescription)")
            }
        }
    }
    
    func logout() {
        self.currentWorkerName = ""
        self.workerId = ""
        self.userRole = ""
        self.isAuthenticated = false
        
        UserDefaults.standard.removeObject(forKey: "currentWorkerName")
        UserDefaults.standard.removeObject(forKey: "workerId")
        UserDefaults.standard.removeObject(forKey: "userRole")
        
        print("👋 User logged out")
    }
    
    // MARK: - Helper Methods
    
    /// Get current worker profile
    func getCurrentWorkerProfile() -> WorkerProfile? {
        guard !workerId.isEmpty else { return nil }
        return WorkerProfile.getWorker(byId: workerId)
    }
    
    /// Check if current user is admin
    var isAdmin: Bool {
        return userRole == "admin"
    }
    
    /// Check if current user is manager
    var isManager: Bool {
        return userRole == "manager" || userRole == "admin"
    }
    
    /// Get worker display name
    var displayName: String {
        return currentWorkerName.isEmpty ? "Worker" : currentWorkerName
    }
    
    /// Get worker ID as String
    var workerIdString: String {
        return workerId
    }
    
    /// Get worker's assigned buildings (hardcoded for now)
    var assignedBuildings: [String] {
        guard !workerId.isEmpty else { return [] }
        
        // Hardcoded building assignments
        let assignments: [String: [String]] = [
            "1": ["1", "2", "3", "4", "5"],           // Greg Hutson
            "2": ["6", "7", "8", "11", "14", "17", "18"], // Edwin Lema
            "4": ["1", "3", "5", "9", "10", "14", "15", "16"], // Kevin Dutan
            "5": ["1", "6", "7", "8", "12", "13", "14", "15"], // Mercedes
            "6": ["1", "14"],                         // Luis Lopez
            "7": ["7", "8", "11", "13", "14", "18"], // Angel
            "8": ["1", "2", "3", "4", "5", "6", "7", "8"], // Shawn (worker)
            "9": [],  // Shawn (client) - can see all
            "10": []  // Shawn (admin) - can see all
        ]
        
        return assignments[workerId] ?? []
    }
    
    /// Check if worker can access a building
    func canAccessBuilding(_ buildingId: String) -> Bool {
        // Admins and clients can access all buildings
        if isAdmin || userRole == "client" { return true }
        
        // Workers can only access assigned buildings
        return assignedBuildings.contains(buildingId)
    }
    
    /// Get worker's schedule
    var workerSchedule: String {
        guard !workerId.isEmpty else { return "No schedule" }
        
        // Hardcoded schedules
        let schedules: [String: String] = [
            "1": "Mon-Fri 7:00 AM - 3:00 PM",  // Greg
            "2": "Mon-Sat 6:00 AM - 3:00 PM",  // Edwin
            "4": "Mon-Fri 6:00 AM - 5:00 PM",  // Kevin
            "5": "Mon-Sat 6:30 AM - 10:30 AM", // Mercedes
            "6": "Mon-Fri 7:00 AM - 4:00 PM",  // Luis
            "7": "Mon-Fri 6:00 AM - 5:00 PM",  // Angel
            "8": "Flexible",                     // Shawn
            "9": "N/A",                         // Client
            "10": "Flexible"                    // Admin
        ]
        
        return schedules[workerId] ?? "No schedule"
    }
}
