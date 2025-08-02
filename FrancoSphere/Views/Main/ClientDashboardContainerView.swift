import SwiftUI

struct ClientDashboardContainerView: View {
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    
    var body: some View {
        NavigationView {
            ClientDashboardView()
                .environmentObject(authManager)
                .environmentObject(dashboardSync)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#if DEBUG
struct ClientDashboardContainerView_Previews: PreviewProvider {
    static var previews: some View {
        ClientDashboardContainerView()
            .environmentObject(NewAuthManager.shared)
            .environmentObject(DashboardSyncService.shared)
            .preferredColorScheme(.dark)
    }
}
#endif
