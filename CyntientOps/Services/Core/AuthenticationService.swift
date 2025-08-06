//
//  AuthenticationService.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 8/5/25.
//


import Foundation
import GRDB

@MainActor
public final class AuthenticationService: ObservableObject {
    @Published public var currentUser: CoreTypes.User?
    @Published public var isAuthenticated = false
    @Published public var currentUserId: String?
    
    private let database: GRDBManager
    
    public init(database: GRDBManager) {
        self.database = database
    }
    
    public func login(email: String, password: String) async throws -> CoreTypes.User {
        // TODO: Implement actual authentication
        throw AuthError.notImplemented
    }
    
    public func logout() async {
        currentUser = nil
        currentUserId = nil
        isAuthenticated = false
    }
}

enum AuthError: Error {
    case notImplemented
}