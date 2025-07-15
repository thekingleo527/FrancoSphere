//
//  AdminDashboardView.swift
//  FrancoSphere
//
//  ✅ V6.0: Phase 4.1 - Real-Time Admin Dashboard
//  ✅ Uses the new AdminDashboardViewModel for all logic and data.
//  ✅ Integrates the new IntelligencePreviewPanel.
//  ✅ Preserves the original glassmorphism design and layout.
//

import SwiftUI
import MapKit

struct AdminDashboardView: View {
    @StateObject private var viewModel = AdminDashboardViewModel()
    @EnvironmentObject private var authManager: NewAuthManager
    
    // State for the view
    @State private var selectedBuildingId: CoreTypes.BuildingID?
    
    // Default region centered on NYC
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7308, longitude: -73.9973),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        NavigationView {
            ZStack {
                // The dark, blurred background is preserved
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        header
                        
                        if viewModel.isLoading {
                            ProgressView("Loading Dashboard...")
                                .padding(.top, 50)
                                .tint(.white)
                        } else {
                            // statisticsSection #TODO
                            
                            // The new, interactive intelligence panel
                            intelligenceSection
                            
                            activeWorkersSection
                            ongoingTasksSection
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.loadDashboardData()
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadDashboardData()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Subviews (Preserving Original Design)

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome, \(authManager.currentUser?.name ?? "Admin")")
                    .font(.title2).bold().foregroundColor(.white)
                Text("Administrator Dashboard")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
            Menu {
                Button(role: .destructive, action: { Task { await authManager.logout() } }) {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Image(systemName: "person.crop.circle.fill").font(.system(size: 28))
            }
        }
    }
    
    private var intelligenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Portfolio Intelligence")
                .font(.headline)
            
            // Building Picker
            Picker("Select Building", selection: $selectedBuildingId) {
                Text("Select a Building").tag(nil as CoreTypes.BuildingID?)
                ForEach(viewModel.buildings) { building in
                    Text(building.name).tag(building.id as CoreTypes.BuildingID?)
                }
            }
            .pickerStyle(.menu)
            .tint(.accentColor)

            // Intelligence Panel
            if viewModel.isLoadingIntelligence {
                ProgressView("Loading Intelligence...")
                    .frame(height: 150)
            } else if let intelligence = viewModel.selectedBuildingIntelligence {
                IntelligencePreviewPanel(intelligence: intelligence)
            } else if selectedBuildingId != nil {
                Text("No intelligence data available for this building.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 150)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onChange(of: selectedBuildingId) { newId in
            if let id = newId {
                Task { await viewModel.fetchIntelligence(for: id) }
            } else {
                viewModel.clearIntelligence()
            }
        }
    }

    private var activeWorkersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Workers").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.activeWorkers) { worker in
                        ProfileBadge(
                            workerName: worker.name,
                            imageUrl: worker.profileImageUrl,
                            isCompact: true
                        )
                    }
                }
            }
        }
    }
    
    private var ongoingTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ongoing Tasks").font(.headline)
            if viewModel.ongoingTasks.isEmpty {
                Text("No ongoing tasks.").font(.subheadline).foregroundColor(.secondary)
            } else {
                ForEach(viewModel.ongoingTasks.prefix(5)) { task in
                    SimpleTaskRow(task: task)
                }
            }
        }
    }
}

// MARK: - Supporting Components (Moved to their own files)
// We assume Text #TODO and Text #TODO are defined elsewhere now.

// MARK: - Preview
struct AdminDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let authManager = NewAuthManager.shared
        Task { try? await authManager.login(email: "shawn@fme-llc.com", password: "password") }
        
        return AdminDashboardView()
            .preferredColorScheme(.dark)
            .environmentObject(authManager)
    }
}
