//
//  NewAuthManager.swift
//  FrancoSphere
//
//  ✅ V6.0 REFACTOR: Aligned with CoreTypes and converted to a thread-safe actor.
//  ✅ FIXED: Replaces scattered properties with a single `CoreTypes.User` object.
//  ✅ PRESERVED: All real-world worker login logic.
//

import Foundation
import Combine

// MARK: - Notification Names for Auth State Changes
extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
}

// MARK: - New Auth Manager Actor
public actor NewAuthManager {
    public static let shared = NewAuthManager()

    // The single source of truth for the authenticated user's session.
    private(set) var currentUser: CoreTypes.User?

    // Private initializer for singleton pattern.
    private init() {
        // Attempt to load a persisted session on startup.
        if let data = UserDefaults.standard.data(forKey: "currentUserSession"),
           let user = try? JSONDecoder().decode(CoreTypes.User.self, from: data) {
            self.currentUser = user
            print("✅ Restored session for \(user.name)")
        }
    }

    // MARK: - Public API
    
    /// A safe, asynchronous method for other services to get the current user's state.
    public func getCurrentUser() -> CoreTypes.User? {
        return self.currentUser
    }

    /// A computed property to check authentication status.
    public var isAuthenticated: Bool {
        return currentUser != nil
    }

    /// Attempts to authenticate a user with the provided credentials.
    public func login(email: String, password: String) async throws {
        // In a real app, you would hash the password and compare it to a stored hash.
        guard password == "password" else {
            throw AuthError.invalidCredentials
        }

        let lowercasedEmail = email.lowercased()
        
        // This user roster should eventually come from the database via WorkerService
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

        // Create the unified User object
        let user = CoreTypes.User(
            workerId: userData.id,
            name: userData.name,
            role: userData.role,
            email: lowercasedEmail
        )
        
        self.currentUser = user
        persistSession(user)

        print("✅ Login successful for: \(user.name) (ID: \(user.workerId), Role: \(user.role))")

        // Notify the rest of the app that a user has logged in.
        await MainActor.run {
            NotificationCenter.default.post(name: .userDidLogin, object: nil, userInfo: ["user": user])
        }
    }

    /// Logs the current user out, clears the session, and posts a notification.
    public func logout() async {
        guard currentUser != nil else { return }
        
        let userName = currentUser?.name ?? "User"
        currentUser = nil
        clearPersistedSession()
        
        print("👋 \(userName) logged out.")

        // Notify the rest of the app that the user has logged out.
        await MainActor.run {
            NotificationCenter.default.post(name: .userDidLogout, object: nil)
        }
    }

    // MARK: - Session Persistence

    private func persistSession(_ user: CoreTypes.User) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "currentUserSession")
        }
    }

    private func clearPersistedSession() {
        UserDefaults.standard.removeObject(forKey: "currentUserSession")
    }
}

// MARK: - Error Types
public enum AuthError: LocalizedError {
    case invalidCredentials
    case userNotFound
    case sessionExpired

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "The email or password you entered is incorrect."
        case .userNotFound:
            return "No account was found with that email address."
        case .sessionExpired:
            return "Your session has expired. Please log in again."
        }
    }
}
