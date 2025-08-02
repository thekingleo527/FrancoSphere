//
//  ClientDashboardContainerView.swift
//  FrancoSphere v6.0
//
//  Container view for Client Dashboard
//

import SwiftUI

struct ClientDashboardContainerView: View {
    @EnvironmentObject private var authManager: NewAuthManager
    
    var body: some View {
        // ClientDashboardView creates its own ViewModel internally
        ClientDashboardView()
            .environmentObject(authManager)
    }
}
