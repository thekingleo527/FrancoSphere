//
//  NewAuthManager.swift
//  FrancoSphere
//
//  ✅ V6.0: ObservableObject for SwiftUI compatibility
//

import Foundation
import Combine
import SwiftUI

extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
}

@MainActor
public class NewAuthManager: ObservableObject {
    public static let shared = NewAuthManager()

    @Published public private(set) var currentUser: CoreTypes.User?
    @Published public private(set) var isLoading = false

    public var isAuthenticated: Bool { currentUser != nil }
    public var userRole: String { currentUser?.role ?? "worker" }
    public var workerId: String? { currentUser?.workerId }
    public var currentWorkerName: String { currentUser?.name ?? "Unknown" }

    private init() {
        if let data = UserDefaults.standard.data(forKey: "currentUserSession"),
           let user = try? JSONDecoder().decode(CoreTypes.User.self, from: data) {
            self.currentUser = user
            print("✅ Restored session for \(user.name)")
        }
    }

    public func getCurrentUser() async -> CoreTypes.User? {
        return currentUser
    }

    public func login(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard password == "password" else {
            throw AuthError.invalidCredentials
        }

        let lowercasedEmail = email.lowercased()
        
        let users: [String: (name: String, id: CoreTypes.WorkerID, role: String)] = [
            "g.hutson1989@gmail.com": ("Greg Hutson", "1", "worker"),
            "edwinlema911@gmail.com": ("Edwin Lema", "2", "worker"),
            "dutankevin1@gmail.com": ("Kevin Dutan", "4", "worker"),
            "jneola@gmail.com": ("Mercedes Inamagua", "5", "worker"),
            "luislopez030@yahoo.com": ("Luis Lopez", "6", "worker"),
            "lio.angel71@gmail.com": ("Angel Guirachocha", "7", "worker"),
            "shawn@francomanagementgroup.com": ("Shawn Magloire", "8", "worker"),
            "francosphere@francomanagementgroup.com": ("Shawn Magloire", "9", "client"),
            "shawn@fme-llc.com": ("Shawn Magloire", "10", "admin")
        ]

        guard let userData = users[lowercasedEmail] else {
            throw AuthError.userNotFound
        }

        let user = CoreTypes.User(
            workerId: userData.id,
            name: userData.name,
            email: lowercasedEmail,
            role: userData.role
        )
        
        self.currentUser = user
        persistSession(user)
        print("✅ Login successful for: \(user.name)")
        NotificationCenter.default.post(name: .userDidLogin, object: nil, userInfo: ["user": user])
    }

    public func logout() async {
        guard currentUser != nil else { return }
        let userName = currentUser?.name ?? "User"
        currentUser = nil
        clearPersistedSession()
        print("👋 \(userName) logged out.")
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }

    private func persistSession(_ user: CoreTypes.User) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "currentUserSession")
        }
    }
    
    private func clearPersistedSession() {
        UserDefaults.standard.removeObject(forKey: "currentUserSession")
    }
}

public enum AuthError: LocalizedError {
    case invalidCredentials
    case userNotFound
    case sessionExpired
    
    public var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid email or password"
        case .userNotFound: return "User not found"
        case .sessionExpired: return "Session expired, please log in again"
        }
    }
}
