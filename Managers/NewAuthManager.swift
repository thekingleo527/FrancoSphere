//
//  NewAuthManager.swift - V6.0 FIXED
//  FrancoSphere
//

import Foundation
import SwiftUI

@MainActor
class NewAuthManager: ObservableObject {
    static let shared = NewAuthManager()
    
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var currentWorkerName: String = ""
    @Published var workerId: String = ""
    @Published var userRole: String = ""
    
    private var sqliteManager: SQLiteManager? = nil

    private init() {
        checkLoginStatus()
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
    
    func getCurrentUser() -> User? {
        guard !workerId.isEmpty else { return nil }
        return User(
            id: workerId,
            name: currentWorkerName,
            email: "\(currentWorkerName.lowercased().replacingOccurrences(of: " ", with: "."))@francosphere.com",
            role: userRole
        )
    }
    
    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            if let worker = self.authenticateWorker(email: email, password: password) {
                self.currentWorkerName = worker.name
                self.workerId = worker.id
                self.userRole = worker.role
                self.isAuthenticated = true
                
                UserDefaults.standard.set(worker.name, forKey: "currentWorkerName")
                UserDefaults.standard.set(worker.id, forKey: "workerId")
                UserDefaults.standard.set(worker.role, forKey: "userRole")
                
                self.isLoading = false
                completion(true, nil)
            } else {
                self.isLoading = false
                completion(false, "Invalid credentials")
            }
        }
    }
    
    func logout() {
        isAuthenticated = false
        currentWorkerName = ""
        workerId = ""
        userRole = ""
        
        UserDefaults.standard.removeObject(forKey: "currentWorkerName")
        UserDefaults.standard.removeObject(forKey: "workerId")
        UserDefaults.standard.removeObject(forKey: "userRole")
    }
    
    private func authenticateWorker(email: String, password: String) -> WorkerCredential? {
        let workers = [
            WorkerCredential(id: "1", name: "Greg Taylor", email: "greg@francosphere.com", password: "greg123", role: "worker"),
            WorkerCredential(id: "2", name: "Edwin Brown", email: "edwin@francosphere.com", password: "edwin123", role: "worker"),
            WorkerCredential(id: "4", name: "Kevin Rubin", email: "kevin@francosphere.com", password: "kevin123", role: "worker"),
            WorkerCredential(id: "5", name: "Mercedes Gonzalez", email: "mercedes@francosphere.com", password: "mercedes123", role: "worker"),
            WorkerCredential(id: "6", name: "Luis Saldana", email: "luis@francosphere.com", password: "luis123", role: "worker"),
            WorkerCredential(id: "7", name: "Angel Ramirez", email: "angel@francosphere.com", password: "angel123", role: "worker"),
            WorkerCredential(id: "8", name: "Shawn Magloire", email: "shawn@francosphere.com", password: "shawn123", role: "admin"),
            WorkerCredential(id: "9", name: "Admin", email: "admin@francosphere.com", password: "admin123", role: "admin"),
            WorkerCredential(id: "10", name: "Client", email: "client@francosphere.com", password: "client123", role: "client")
        ]
        
        return workers.first { $0.email.lowercased() == email.lowercased() && $0.password == password }
    }
}

struct WorkerCredential {
    let id: String
    let name: String
    let email: String
    let password: String
    let role: String
}

struct User {
    let id: String
    let name: String
    let email: String
    let role: String
}
