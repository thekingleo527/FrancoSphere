//
//  WorkerDashboardView.swift
//  FrancoSphere
//
//  ✅ V6.0 REFACTOR: Complete architectural overhaul.
//  ✅ FIXED: All compilation errors resolved.
//  ✅ INTEGRATED: Correctly uses actor-based managers via its ViewModel.
//  ✅ PRESERVED: Original UI design and functionality from screenshots and prior versions.
//

import SwiftUI
import MapKit

struct WorkerDashboardView: View {
    @StateObject private var viewModel = WorkerDashboardViewModel()
    @EnvironmentObject private var authManager: NewAuthManager

    // UI State
    @State private var showBuildingList = false
    @State private var showMapOverlay = false
    @State private var showProfileView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                mapBackground
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    loadingView
                } else {
                    mainContentScrollView
                }
                
                // Custom header floats on top
                VStack {
                    HeaderV3B(
                        workerName: authManager.currentUser?.name ?? "Worker",
                        clockedInStatus: viewModel.isClockedIn,
                        onClockToggle: { Task { await viewModel.handleClockInToggle() } },
                        onProfilePress: { showProfileView = true },
                        nextTaskName: viewModel.todaysTasks.first(where: { !$0.isCompleted })?.name,
                        hasUrgentWork: viewModel.todaysTasks.contains { $0.urgency == .high || $0.urgency == .urgent },
                        onNovaPress: { /* TODO: Show Nova AI */ },
                        onNovaLongPress: { /* TODO: Show Nova AI Long Press */ },
                        isNovaProcessing: false,
                        hasPendingScenario: false,
                        showClockPill: true
                    )
                    .background(.ultraThinMaterial)
                    Spacer()
                }
            }
            .task {
                await viewModel.loadInitialData()
            }
            .sheet(isPresented: $showBuildingList) {
                BuildingSelectionSheet(
                    buildings: viewModel.assignedBuildings,
                    onSelect: { building in
                        Task { await viewModel.handleClockIn(for: building) }
                        showBuildingList = false
                    },
                    onCancel: { showBuildingList = false }
                )
            }
            .sheet(isPresented: $showProfileView) {
                // Assuming you have a ProfileView
                ProfileView()
            }
            .fullScreenCover(isPresented: $showMapOverlay) {
                EnhancedMapOverlay(
                    buildings: viewModel.assignedBuildings,
                    currentBuildingId: viewModel.currentSession?.buildingId,
                    isPresented: $showMapOverlay
                )
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Subviews (Preserving Original Design)

    private var mapBackground: some View {
        Map(interactionModes: [])
            .mapStyle(.standard(elevation: .realistic))
            .blur(radius: 4)
            .overlay(Color.black.opacity(0.5))
    }
    
    private var loadingView: some View {
        ProgressView("Loading Dashboard...")
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black.opacity(0.4))
    }
    
    private var mainContentScrollView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 100) // Pushes content below the floating header
                
                if let errorMessage = viewModel.errorMessage {
                    errorBanner(message: errorMessage)
                }
                
                clockInSection
                todaysProgressSection
                mySitesSection
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }

    private func errorBanner(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message).font(.caption)
        }
        .foregroundColor(.white)
        .padding()
        .background(Color.red.opacity(0.8))
        .cornerRadius(12)
    }

    private var clockInSection: some View {
        Button(action: {
            if viewModel.isClockedIn {
                Task { await viewModel.handleClockInToggle() }
            } else {
                showBuildingList = true
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: viewModel.isClockedIn ? "location.fill" : "location.slash")
                    .font(.title3).foregroundColor(viewModel.isClockedIn ? .green : .orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.isClockedIn ? "Clocked In" : "Clock In")
                        .font(.headline).foregroundColor(.white)
                    Text(viewModel.isClockedIn ? "Working at \(viewModel.currentSession?.buildingName ?? "...")" : "Select a building to start your shift")
                        .font(.caption).foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.6))
            }
            .padding(16).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain)
    }

    private var todaysProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Progress").font(.headline).foregroundColor(.white)
            ProgressView(value: viewModel.taskProgress?.percentage ?? 0, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            HStack {
                Text("\(Int(viewModel.taskProgress?.percentage ?? 0))% Complete")
                Spacer()
                Text("\(viewModel.taskProgress?.completed ?? 0)/\(viewModel.taskProgress?.total ?? 0) Tasks")
            }
            .font(.caption).foregroundColor(.white.opacity(0.7))
        }
        .padding(16).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var mySitesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Sites").font(.headline).foregroundColor(.white)
                Spacer()
                Button("View All") { showMapOverlay = true }
                    .font(.caption).foregroundColor(.blue)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.assignedBuildings.prefix(6)) { building in
                    MySitesCard(building: building)
                }
            }
        }
        .padding(16).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Reusable Site Card
private struct MySitesCard: View {
    let building: NamedCoordinate
    var body: some View {
        VStack(spacing: 0) {
            if let assetName = building.imageAssetName, !assetName.isEmpty, let uiImage = UIImage(named: assetName) {
                Image(uiImage: uiImage).resizable().aspectRatio(contentMode: .fill).frame(height: 80)
            } else {
                Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 80)
                    .overlay(Image(systemName: "building.2").foregroundColor(.white))
            }
            VStack {
                Text(building.name).font(.caption).fontWeight(.medium).foregroundColor(.white)
                    .lineLimit(2).multilineTextAlignment(.center).frame(height: 35)
            }.padding(8)
        }
        .background(Color.black.opacity(0.2)).cornerRadius(12).clipped()
    }
}

// MARK: - Building Selection Sheet
struct BuildingSelectionSheet: View {
    let buildings: [NamedCoordinate]
    let onSelect: (NamedCoordinate) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            List(buildings) { building in
                Button(action: { onSelect(building) }) {
                    HStack { Text(building.name); Spacer(); Image(systemName: "chevron.right") }
                }
            }
            .navigationTitle("Select a Building")
            .navigationBarItems(leading: Button("Cancel", action: onCancel))
        }.preferredColorScheme(.dark)
    }
}

// MARK: - Preview
struct WorkerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let authManager = NewAuthManager.shared
        // Use a task to call the async login method for the preview
        Task { try? await authManager.login(email: "dutankevin1@gmail.com", password: "password") }
        
        return WorkerDashboardView().environmentObject(authManager)
    }
}
