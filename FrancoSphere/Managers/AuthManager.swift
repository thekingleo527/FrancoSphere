import Foundation
import SwiftUI

@MainActor
class NewAuthManager: ObservableObject {  // Changed name
    static let shared = NewAuthManager()   // Changed name
    
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var currentWorkerName: String = ""
    @Published var workerId: Int64 = 0
    @Published var userRole: String = ""
    
    // Real users data (email to details mapping)
    private let realUsers: [String: [String: Any]] = [
        "g.hutson1989@gmail.com": ["name": "Greg Hutson", "id": 1, "role": "worker"],
        "edwinlema911@gmail.com": ["name": "Edwin Lema", "id": 2, "role": "worker"],
        "dutankevin1@gmail.com": ["name": "Kevin Dutan", "id": 4, "role": "worker"],
        "jneola@gmail.com": ["name": "Mercedes Inamagua", "id": 5, "role": "worker"],
        "luislopez030@yahoo.com": ["name": "Luis Lopez", "id": 6, "role": "worker"],
        "lio.angel71@gmail.com": ["name": "Angel Guirachocha", "id": 7, "role": "worker"],
        "shawn@francomanagementgroup.com": ["name": "Shawn Magloire", "id": 8, "role": "worker"],
        "francosphere@francomanagementgroup.com": ["name": "Shawn Magloire", "id": 9, "role": "client"],
        "shawn@fme-llc.com": ["name": "Shawn Magloire", "id": 10, "role": "admin"]
    ]
    
    // SQLite manager (actor)
    private var sqliteManager: SQLiteManager? = nil

    private init() {
        checkLoginStatus()
        // You might want to do async setup for SQLiteManager here if not already initialized elsewhere
        Task {
            do {
                self.sqliteManager = try await SQLiteManager.start()
            } catch {
                print("⚠️ AuthManager failed to init SQLiteManager: \(error)")
            }
        }
    }
    
    private func checkLoginStatus() {
        // Restore login state from UserDefaults if available
        if let name = UserDefaults.standard.string(forKey: "currentWorkerName"),
           let workerIdValue = UserDefaults.standard.object(forKey: "workerId") as? Int64,
           let role = UserDefaults.standard.string(forKey: "userRole") {
            self.currentWorkerName = name
            self.workerId = workerIdValue
            self.userRole = role
            self.isAuthenticated = true
        }
    }
    
    /// Authenticates the user against the local SQLite database (if available), or falls back to in-memory "realUsers".
    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        
        let lowercasedEmail = email.lowercased()
        
        // First, try to authenticate against SQLite
        Task { [weak self] in
            guard let self = self else { return }
            
            // Wait for SQLiteManager to finish setup, if needed
            while self.sqliteManager == nil {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
            
            do {
                // Query the workers table for a matching email
                if let manager = self.sqliteManager {
                    let sql = "SELECT id, name, role, passwordHash FROM workers WHERE LOWER(email) = ?"
                    let rows = try await manager.query(sql, parameters: [lowercasedEmail])
                    if let row = rows.first {
                        // Validate password
                        let storedHash = row["passwordHash"] as? String ?? ""
                        if storedHash.isEmpty || storedHash == password || password == "password" {
                            // (For demo/dev: allow default password)
                            await MainActor.run {
                                self.currentWorkerName = row["name"] as? String ?? "Worker"
                                if let idValue = row["id"] as? Int64 {
                                    self.workerId = idValue
                                } else if let idInt = row["id"] as? Int {
                                    self.workerId = Int64(idInt)
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
                            return
                        } else {
                            await MainActor.run {
                                self.isLoading = false
                            }
                            completion(false, "Incorrect password")
                            return
                        }
                    }
                }
            } catch {
                print("⚠️ SQLite login failed: \(error)")
                // Continue to fallback realUsers
            }
            
            // Fallback: use realUsers
            await MainActor.run {
                if let userData = self.realUsers[lowercasedEmail] {
                    if password == "password" { // For dev/demo/testing
                        self.currentWorkerName = userData["name"] as? String ?? "Worker"
                        self.workerId = userData["id"] as? Int64 ?? Int64(userData["id"] as? Int ?? 0)
                        self.userRole = userData["role"] as? String ?? "worker"
                        self.isAuthenticated = true
                        UserDefaults.standard.set(self.currentWorkerName, forKey: "currentWorkerName")
                        UserDefaults.standard.set(self.workerId, forKey: "workerId")
                        UserDefaults.standard.set(self.userRole, forKey: "userRole")
                        self.isLoading = false
                        completion(true, nil)
                    } else {
                        self.isLoading = false
                        completion(false, "Incorrect password")
                    }
                } else {
                    self.isLoading = false
                    completion(false, "User not found")
                }
            }
        }
    }
    
    func logout() {
        self.currentWorkerName = ""
        self.workerId = 0
        self.userRole = ""
        self.isAuthenticated = false
        
        UserDefaults.standard.removeObject(forKey: "currentWorkerName")
        UserDefaults.standard.removeObject(forKey: "workerId")
        UserDefaults.standard.removeObject(forKey: "userRole")
    }
}
