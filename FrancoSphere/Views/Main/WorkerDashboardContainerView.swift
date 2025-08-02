import SwiftUI

struct WorkerDashboardContainerV6: View {
    @StateObject private var viewModel = WorkerDashboardViewModel()
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    // Loading view
                    LoadingDashboardView()
                } else if viewModel.workerCapabilities?.simplifiedInterface == true {
                    // Simplified dashboard for workers with simplified capabilities
                    SimplifiedDashboard(viewModel: viewModel)
                        .environmentObject(authManager)
                        .environmentObject(dashboardSync)
                } else {
                    // Full-featured standard dashboard
                    WorkerDashboardView(viewModel: viewModel)
                        .environmentObject(authManager)
                        .environmentObject(dashboardSync)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .task {
            do {
                await viewModel.loadInitialData()
            } catch {
                errorMessage = "Failed to load dashboard: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("Retry") {
                Task {
                    await viewModel.loadInitialData()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Loading View Component
private struct LoadingDashboardView: View {
    @State private var loadingProgress: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "1a1a1a"),
                    Color(hex: "2d2d2d")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // FrancoSphere Logo or Icon
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 10)
                
                Text("Loading Your Dashboard")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Progress indicator
                ProgressView(value: loadingProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(.blue)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                    .frame(width: 200)
                
                Text("Preparing your workspace...")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
        }
        .onAppear {
            // Animate progress bar
            withAnimation(.easeInOut(duration: 2.0)) {
                loadingProgress = 0.8
            }
        }
    }
}

#if DEBUG
struct WorkerDashboardContainerV6_Previews: PreviewProvider {
    static var previews: some View {
        WorkerDashboardContainerV6()
            .environmentObject(NewAuthManager.shared)
            .environmentObject(DashboardSyncService.shared)
            .preferredColorScheme(.dark)
    }
}
#endif
