import Foundation
import SwiftUI

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var currentWorkerName: String = ""
    @Published var workerId: Int64 = 0
    @Published var userRole: String = ""
    
    // Real users data (email to details mapping)
    private let realUsers: [String: [String: Any]] = [
        "g.hutson1989@gmail.com": ["name": "Greg Hutson", "id": 1, "role": "worker"],
        "edwinlema911@gmail.com": ["name": "Edwin Lema", "id": 2, "role": "worker"],
        "josesantos14891989@gmail.com": ["name": "Jose Santos", "id": 3, "role": "worker"],
        "dutankevin1@gmail.com": ["name": "Kevin Dutan", "id": 4, "role": "worker"],
        "Jneola@gmail.com": ["name": "Mercedes Inamagua", "id": 5, "role": "worker"],
        "luislopez030@yahoo.com": ["name": "Luis Lopez", "id": 6, "role": "worker"],
        "lio.angel71@gmail.com": ["name": "Angel Guirachocha", "id": 7, "role": "worker"],
        "shawn@francomanagementgroup.com": ["name": "Shawn Magloire", "id": 8, "role": "worker"],
        "FrancoSphere@francomanagementgroup.com": ["name": "Shawn Magloire", "id": 9, "role": "client"],
        "Shawn@fme-llc.com": ["name": "Shawn Magloire", "id": 10, "role": "admin"]
    ]
    
    // Private initializer ensures only one instance exists
    private init() {
        checkLoginStatus()
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
    
    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            // First, attempt authentication via SQLiteManager
            SQLiteManager.shared.authenticateUser(email: email, password: password) { success, userData, errorMessage in
                if success, let userData = userData {
                    // Set user data from database
                    self.currentWorkerName = userData["name"] as? String ?? "Worker"
                    self.workerId = userData["id"] as? Int64 ?? 0
                    self.userRole = userData["role"] as? String ?? "worker"
                    self.isAuthenticated = true
                    
                    // Save state
                    UserDefaults.standard.set(self.currentWorkerName, forKey: "currentWorkerName")
                    UserDefaults.standard.set(self.workerId, forKey: "workerId")
                    UserDefaults.standard.set(self.userRole, forKey: "userRole")
                    
                    self.isLoading = false
                    completion(true, nil)
                    return
                }
                
                // Fallback to realUsers if SQLite authentication fails
                if let userData = self.realUsers[email.lowercased()] {
                    if password == "password" { // For testing
                        self.currentWorkerName = userData["name"] as? String ?? "Worker"
                        self.workerId = userData["id"] as? Int64 ?? Int64(userData["id"] as? Int ?? 0)
                        self.userRole = userData["role"] as? String ?? "worker"
                        self.isAuthenticated = true
                        
                        // Save state
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
        // Clear local user data
        self.currentWorkerName = ""
        self.workerId = 0
        self.userRole = ""
        self.isAuthenticated = false
        
        // Remove from persistence
        UserDefaults.standard.removeObject(forKey: "currentWorkerName")
        UserDefaults.standard.removeObject(forKey: "workerId")
        UserDefaults.standard.removeObject(forKey: "userRole")
    }
}
