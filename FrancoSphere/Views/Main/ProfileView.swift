//
//  ProfileView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/1/25.
//

import SwiftUI
import UIKit

struct ProfileView: View {
    @StateObject private var authManager = AuthManager.shared
    
    // Sample data - in a real app, this would be fetched from a database
    let assignedBuildingCount = 4
    let hoursThisWeek = 32
    let tasksCompleted = 12
    
    // Navigation state
    @State private var showingAssignedBuildings = false
    @State private var showingHoursBreakdown = false
    @State private var showingTaskHistory = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile header
                    VStack(spacing: 15) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(Color(red: 0.34, green: 0.34, blue: 0.8))
                            .padding(.top, 20)
                        
                        Text(authManager.currentWorkerName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Maintenance Worker")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Divider()
                            .padding(.top, 5)
                    }
                    
                    // Interactive Stats cards
                    VStack(spacing: 15) {
                        // Assigned Buildings Card - now interactive
                        Button(action: {
                            showingAssignedBuildings = true
                        }) {
                            StatCardView(
                                iconName: "building.2",
                                title: "Assigned Buildings",
                                value: "\(assignedBuildingCount)",
                                color: .blue
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .sheet(isPresented: $showingAssignedBuildings) {
                            MyAssignedBuildingsView()
                        }
                        
                        // Hours this Week Card - now interactive
                        Button(action: {
                            showingHoursBreakdown = true
                        }) {
                            StatCardView(
                                iconName: "clock",
                                title: "Hours this Week",
                                value: "\(hoursThisWeek)",
                                color: .orange
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .sheet(isPresented: $showingHoursBreakdown) {
                            HoursBreakdownView(hoursThisWeek: hoursThisWeek)
                        }
                        
                        // Tasks Completed Card - now interactive
                        Button(action: {
                            showingTaskHistory = true
                        }) {
                            StatCardView(
                                iconName: "checkmark.circle",
                                title: "Tasks Completed",
                                value: "\(tasksCompleted)",
                                color: .green
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .sheet(isPresented: $showingTaskHistory) {
                            TaskHistoryView(completedCount: tasksCompleted)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Account settings section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Account Settings")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        SettingsRowView(iconName: "person.fill", title: "Personal Information")
                        SettingsRowView(iconName: "bell", title: "Notifications")
                        SettingsRowView(iconName: "lock.fill", title: "Change Password")
                        SettingsRowView(iconName: "questionmark.circle", title: "Help & Support")
                    }
                    
                    Spacer()
                    
                    // Logout button
                    Button(action: {
                        authManager.logout()
                    }) {
                        Text("LOG OUT")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                    }
                    .background(Color(red: 0.34, green: 0.34, blue: 0.8))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                    
                    // Added custom FrancoSphereFooter implementation
                    FrancoSphereFooter()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Added custom FrancoSphereFooter implementation
struct FrancoSphereFooter: View {
    var body: some View {
        Text("Powered by FrancoSphere")
            .font(.footnote)
            .foregroundColor(.gray)
            .padding()
    }
}

// MARK: - Component Views

struct StatCardView: View {
    let iconName: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.system(size: 30))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct SettingsRowView: View {
    let iconName: String
    let title: String
    
    var body: some View {
        Button(action: {
            // Action for settings row
        }) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(.gray)
                    .frame(width: 30)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Detail Views

struct MyAssignedBuildingsView: View {
    // FIXED: Use @State and load async data in onAppear
    @State private var assignedBuildings: [FrancoSphere.NamedCoordinate] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading buildings...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(assignedBuildings) { building in
                            NavigationLink(destination: BuildingDetailView(building: building)) {
                                HStack {
                                    // Building image loaded directly via imageAssetName
                                    if let uiImage = UIImage(named: building.imageAssetName) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        Image(systemName: "building.2.fill")
                                            .font(.largeTitle)
                                            .foregroundColor(.blue)
                                            .frame(width: 60, height: 60)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(building.name)
                                            .font(.headline)
                                        
                                        Text("Status: Operational")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                        
                                        Text("Location: \(String(format: "%.4f, %.4f", building.latitude, building.longitude))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Assigned Buildings")
            .task {
                await loadAssignedBuildings()
            }
        }
    }
    
    // FIXED: Load buildings asynchronously
    private func loadAssignedBuildings() async {
        do {
            let buildings = await BuildingRepository.shared.getFirstNBuildings(4)
            await MainActor.run {
                self.assignedBuildings = buildings
                self.isLoading = false
            }
        } catch {
            print("Error loading buildings: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

struct HoursBreakdownView: View {
    let hoursThisWeek: Int
    
    // Sample daily hours data
    let dailyHours: [String: Double] = [
        "Monday": 6.5,
        "Tuesday": 7.0,
        "Wednesday": 8.0,
        "Thursday": 6.5,
        "Friday": 4.0,
        "Saturday": 0.0,
        "Sunday": 0.0
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Daily Breakdown")) {
                    ForEach(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], id: \.self) { day in
                        HStack {
                            Text(day)
                                .font(.headline)
                            
                            Spacer()
                            
                            Text(String(format: "%.1f hours", dailyHours[day] ?? 0))
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Location Breakdown")) {
                    HStack {
                        Text("12 West 18th Street")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("12.5 hours")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("29-31 East 20th Street")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("8.0 hours")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("36 Walker Street")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("11.5 hours")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    HStack {
                        Text("Total")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text("\(hoursThisWeek) hours")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("Hours This Week")
        }
    }
}

struct TaskHistoryView: View {
    let completedCount: Int
    
    // Sample completed tasks with corrected parameter order (dueDate before isComplete)
    let completedTasks: [MaintenanceTask] = [
        MaintenanceTask(
            name: "Daily Inspection",
            buildingID: "1",
            description: "Check all common areas",
            dueDate: Date().addingTimeInterval(-86400),
            isComplete: true
        ),
        MaintenanceTask(
            name: "HVAC Maintenance",
            buildingID: "2",
            description: "Inspect air conditioning units",
            dueDate: Date().addingTimeInterval(-172800),
            isComplete: true
        ),
        MaintenanceTask(
            name: "Elevator Inspection",
            buildingID: "3",
            description: "Check elevator operation",
            dueDate: Date().addingTimeInterval(-259200),
            isComplete: true
        ),
        MaintenanceTask(
            name: "Lobby Cleaning",
            buildingID: "1",
            description: "Clean lobby floors and windows",
            dueDate: Date().addingTimeInterval(-345600),
            isComplete: true
        ),
        MaintenanceTask(
            name: "Security Verification",
            buildingID: "4",
            description: "Verify security cameras and alarms",
            dueDate: Date().addingTimeInterval(-432000),
            isComplete: true
        )
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(completedTasks) { task in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(task.name)
                            .font(.headline)
                        
                        Text("Building: \(getBuildingName(for: task.buildingID))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Completed: \(task.dueDate, formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text(task.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Completed Tasks")
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    // Helper function to get building name for a task
    private func getBuildingName(for buildingID: String) -> String {
        // FIXED: Use the synchronous fallback method for now
        return BuildingRepository.shared.getBuildingName(forId: buildingID)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
