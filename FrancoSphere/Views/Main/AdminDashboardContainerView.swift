import SwiftUI

struct AdminDashboardContainerView: View {
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    
    var body: some View {
        NavigationView {
            AdminDashboardView()
                .environmentObject(authManager)
                .environmentObject(dashboardSync)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#if DEBUG
struct AdminDashboardContainerView_Previews: PreviewProvider {
    static var previews: some View {
        AdminDashboardContainerView()
            .environmentObject(NewAuthManager.shared)
            .environmentObject(DashboardSyncService.shared)
            .preferredColorScheme(.dark)
    }
}
#endif
