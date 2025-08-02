
//  AdminDashboardContainerView.swift
//  FrancoSphere v6.0
//
//  Container view for Admin/Manager Dashboard
//

struct AdminDashboardContainerView: View {
    @EnvironmentObject private var authManager: NewAuthManager
    
    var body: some View {
        // AdminDashboardView creates its own ViewModel internally
        AdminDashboardView()
            .environmentObject(authManager)
    }
}
