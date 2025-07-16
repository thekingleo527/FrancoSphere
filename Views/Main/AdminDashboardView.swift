//
//  AdminDashboardView.swift
//  FrancoSphere
//
//  ✅ CLEAN VERSION: No redeclared components, uses existing shared components only
//  ✅ FIXED: All syntax errors and top-level expressions removed
//  ✅ ALIGNED: With three-dashboard platform architecture
//  ✅ V6.0: Phase 4.1 - Real-Time Admin Dashboard
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
                            // The interactive intelligence panel
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

    // MARK: - Header Section

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
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Intelligence Section
    
    private var intelligenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Portfolio Intelligence")
                .font(.headline)
                .foregroundColor(.white)
            
            // Building Picker
            Picker("Select Building", selection: $selectedBuildingId) {
                Text("Select a Building").tag(nil as CoreTypes.BuildingID?)
                ForEach(viewModel.buildings) { building in
                    Text(building.name).tag(building.id as CoreTypes.BuildingID?)
                }
            }
            .pickerStyle(.menu)
            .tint(.accentColor)

            // Intelligence Panel - Using existing component
            if viewModel.isLoadingIntelligence {
                ProgressView("Loading Intelligence...")
                    .frame(height: 150)
                    .foregroundColor(.white)
            } else if !viewModel.selectedBuildingInsights.isEmpty {
                IntelligencePreviewPanel(insights: viewModel.selectedBuildingInsights)
            } else if selectedBuildingId != nil {
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("No intelligence data available for this building.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 120)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onChange(of: selectedBuildingId) { newId in
            if let id = newId {
                Task { await viewModel.fetchBuildingIntelligence(for: id) }
            } else {
                viewModel.clearBuildingIntelligence()
            }
        }
    }

    // MARK: - Active Workers Section

    private var activeWorkersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Workers")
                .font(.headline)
                .foregroundColor(.white)
            
            if viewModel.activeWorkers.isEmpty {
                Text("No active workers")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
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
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Ongoing Tasks Section
    
    private var ongoingTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ongoing Tasks")
                .font(.headline)
                .foregroundColor(.white)
            
            if viewModel.ongoingTasks.isEmpty {
                Text("No ongoing tasks")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.ongoingTasks.prefix(5)) { task in
                        TaskTimelineRow(task: task)
                    }
                }
                
                if viewModel.ongoingTasks.count > 5 {
                    Text("+ \(viewModel.ongoingTasks.count - 5) more tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
