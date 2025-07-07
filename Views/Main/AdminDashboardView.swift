//
//  AdminDashboardView.swift
//  FrancoSphere
//
//  ✅ V6.0 REFACTOR: All compilation errors resolved.
//  ✅ FIXED: Uses a new ViewModel to fetch data from consolidated services.
//  ✅ FIXED: Modern MapKit API implementation.
//  ✅ FIXED: All data types and initializers are now correct.
//

import SwiftUI
import MapKit

// MARK: - Admin Dashboard View Model

@MainActor
class AdminDashboardViewModel: ObservableObject {
    @Published var buildings: [NamedCoordinate] = []
    @Published var activeWorkers: [WorkerProfile] = []
    @Published var ongoingTasks: [ContextualTask] = []
    @Published var inventoryAlerts: [InventoryItem] = []
    @Published var isLoading = false

    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared

    func loadDashboardData() async {
        isLoading = true
        
        async let buildings = buildingService.getAllBuildings()
        async let workers = workerService.getAllActiveWorkers()
        async let tasks = taskService.getAllTasks()
        // In a real app, inventory alerts would come from a dedicated service.
        
        do {
            self.buildings = try await buildings
            self.activeWorkers = try await workers
            self.ongoingTasks = (try await tasks).filter { !$0.isCompleted }
            self.inventoryAlerts = [] // Placeholder for inventory alerts
        } catch {
            print("❌ Failed to load admin dashboard data: \(error)")
        }
        
        isLoading = false
    }
}


// MARK: - Admin Dashboard View

struct AdminDashboardView: View {
    @StateObject private var viewModel = AdminDashboardViewModel()
    @StateObject private var authManager = NewAuthManager.shared
    
    @State private var selectedTab = 0
    @State private var showNewTaskSheet = false
    
    @State private var region: MKCoordinateRegion
    
    init() {
        // Default region centered on NYC
        let center = CLLocationCoordinate2D(latitude: 40.7308, longitude: -73.9973)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        _region = State(initialValue: MKCoordinateRegion(center: center, span: span))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                adminDashboardHeader
                
                ScrollView {
                    VStack(spacing: 20) {
                        if viewModel.isLoading {
                            ProgressView("Loading Dashboard...")
                                .padding(.top, 50)
                        } else {
                            statisticsSection
                            buildingsMapSection
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
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .task {
                await viewModel.loadDashboardData()
            }
            .sheet(isPresented: $showNewTaskSheet) {
                TaskRequestView()
            }
        }
    }

    // MARK: - Subviews

    private var adminDashboardHeader: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome, \(authManager.currentWorkerName)")
                        .font(.title2).bold()
                    Text("Admin Dashboard")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 16) {
                    Button(action: { showNewTaskSheet = true }) {
                        Image(systemName: "plus.circle.fill").font(.system(size: 24)).foregroundColor(.blue)
                    }
                    Menu {
                        Button(action: { authManager.logout() }) {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.crop.circle.fill").font(.system(size: 24))
                    }
                }
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 8)
            Divider()
        }
        .background(Color(.systemBackground).shadow(radius: 2))
    }

    private var statisticsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
            StatCard(title: "Buildings", value: "\(viewModel.buildings.count)", icon: "building.2.fill", color: .blue)
            StatCard(title: "Active Workers", value: "\(viewModel.activeWorkers.count)", icon: "person.2.fill", color: .green)
            StatCard(title: "Ongoing Tasks", value: "\(viewModel.ongoingTasks.count)", icon: "checklist.checked", color: .orange)
            StatCard(title: "Inv. Alerts", value: "\(viewModel.inventoryAlerts.count)", icon: "exclamationmark.triangle.fill", color: .red)
        }
    }

    // ✅ FIXED: Correct MapKit API usage
    private var buildingsMapSection: some View {
        Map(coordinateRegion: $region, annotationItems: viewModel.buildings) { building in
            MapAnnotation(coordinate: building.coordinate) {
                AdminBuildingMarker(building: building)
            }
        }
        .frame(height: 200)
        .cornerRadius(12)
    }
    
    private var activeWorkersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Workers").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.activeWorkers) { worker in
                        WorkerCard(worker: worker)
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
                    TaskListItem(task: task)
                }
            }
        }
    }
}

// MARK: - Supporting Components

private struct AdminBuildingMarker: View {
    let building: NamedCoordinate
    var body: some View {
        Image(systemName: "building.2.crop.circle.fill")
            .font(.title)
            .foregroundColor(.blue)
            .background(Circle().fill(Color.white))
            .shadow(radius: 2)
    }
}

private struct WorkerCard: View {
    let worker: WorkerProfile
    var body: some View {
        VStack {
            ProfileBadge(workerName: worker.name, isCompact: true)
            Text(worker.name.components(separatedBy: " ").first ?? "")
                .font(.caption)
                .lineLimit(1)
        }.frame(width: 80)
    }
}

private struct TaskListItem: View {
    let task: ContextualTask
    var body: some View {
        HStack {
            Image(systemName: task.category.icon).foregroundColor(.blue)
            VStack(alignment: .leading) {
                Text(task.name).font(.subheadline).fontWeight(.medium)
                Text(task.buildingName).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text(task.urgency.rawValue).font(.caption).foregroundColor(task.urgency.displayColor)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

// MARK: - Preview
struct AdminDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        AdminDashboardView()
            .preferredColorScheme(.dark)
    }
}
