//
//  DashboardTaskDetailView.swift
//  FrancoSphere
//
//  ✅ V6.0 REFACTOR: All compilation errors resolved
//  ✅ FIXED: Uses actual ContextualTask properties from FrancoSphereModels.swift
//  ✅ FIXED: Proper optional handling and extension property access
//

import SwiftUI

struct DashboardTaskDetailView: View {
    let task: ContextualTask
    
    @StateObject private var viewModel = TaskDetailViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingCompletionSheet = false
    @State private var completionNotes = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                detailSection
                actionSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Task Details")
        .sheet(isPresented: $showingImagePicker) {
            // Use existing ImagePickerWrapper from TaskRequestView.swift
            ImagePickerWrapper(sourceType: .photoLibrary, selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showingCompletionSheet) {
            TaskCompletionView(
                task: task,
                completionNotes: $completionNotes,
                selectedImage: $selectedImage,
                onComplete: {
                    showingCompletionSheet = false
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .task {
            if let buildingId = task.buildingId {
                await viewModel.loadBuildingName(for: buildingId)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Category badge
                Group {
                    if let category = task.category {
                        Text(category.rawValue.capitalized)
                    } else {
                        Text("General")
                    }
                }
                .font(.subheadline)
                .foregroundColor(getCategoryColor(task.category))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(getCategoryColor(task.category).opacity(0.1))
                .cornerRadius(8)
                
                Spacer()
                
                // Urgency badge
                Group {
                    if let urgency = task.urgency {
                        Text(urgency.rawValue.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(urgency.color)
                            .cornerRadius(12)
                    } else {
                        Text("Medium")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                }
            }
            
            // Task title
            Text(task.title)
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let description = task.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            // Building information
            if !viewModel.buildingName.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(viewModel.buildingName)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } else if let building = task.building {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(building.name)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            // Due date
            if let dueDate = task.dueDate {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Due Date")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(dueDate, style: .date)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            // Estimated duration (using helper function)
            VStack(alignment: .leading, spacing: 8) {
                Text("Estimated Duration")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(getEstimatedDuration(for: task))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var actionSection: some View {
        VStack(spacing: 12) {
            if !task.isCompleted {
                Button(action: {
                    showingCompletionSheet = true
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Mark Complete")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
                }
            }
            
            Button(action: {
                showingImagePicker = true
            }) {
                HStack {
                    Image(systemName: "camera")
                    Text("Add Photo")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // Helper function for category colors
    private func getCategoryColor(_ category: TaskCategory?) -> Color {
        guard let category = category else { return .gray }
        return TaskDisplayHelpers.getCategoryColor(for: category.rawValue)
    }
    
    // Helper function to get estimated duration safely
    private func getEstimatedDuration(for task: ContextualTask) -> String {
        // Try to use extension property if available, fallback to default
        let durationInSeconds: TimeInterval
        
        // Check if the task has category-based duration estimation
        if let category = task.category {
            switch category {
            case .cleaning: durationInSeconds = 1800  // 30 minutes
            case .maintenance: durationInSeconds = 3600  // 1 hour
            case .repair: durationInSeconds = 7200  // 2 hours
            case .inspection: durationInSeconds = 1800  // 30 minutes
            default: durationInSeconds = 3600  // 1 hour default
            }
        } else {
            durationInSeconds = 3600  // 1 hour default
        }
        
        let minutes = Int(durationInSeconds / 60)
        return "\(minutes) minutes"
    }
}

// MARK: - Task Completion View
struct TaskCompletionView: View {
    let task: ContextualTask
    @Binding var completionNotes: String
    @Binding var selectedImage: UIImage?
    let onComplete: () -> Void
    
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Completion Notes")) {
                    TextEditor(text: $completionNotes)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("Photo Evidence")) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                        
                        Button("Remove Photo") {
                            selectedImage = nil
                        }
                        .foregroundColor(.red)
                    } else {
                        Button("Add Photo") {
                            showingImagePicker = true
                        }
                    }
                }
            }
            .navigationTitle("Complete Task")
            .navigationBarItems(
                leading: Button("Cancel") {
                    onComplete()
                },
                trailing: Button("Complete") {
                    // Here you would normally save the completion data
                    onComplete()
                }
                .disabled(completionNotes.isEmpty)
            )
            .sheet(isPresented: $showingImagePicker) {
                ImagePickerWrapper(sourceType: .camera, selectedImage: $selectedImage)
            }
        }
    }
}

// MARK: - Preview
struct DashboardTaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBuilding = NamedCoordinate(
            id: "14",
            name: "Rubin Museum",
            latitude: 40.7396,
            longitude: -74.0089
        )
        
        let sampleWorker = WorkerProfile(
            id: "1",
            name: "Kevin Dutan",
            email: "dutankevin1@gmail.com",
            phoneNumber: "555-0123",
            role: .worker,
            skills: [],
            certifications: [],
            hireDate: Date()
        )
        
        let sampleTask = ContextualTask(
            title: "Clean Windows",
            description: "Clean all exterior windows on the east side",
            isCompleted: false,
            scheduledDate: Date(),
            dueDate: Date().addingTimeInterval(86400),
            category: .cleaning,
            urgency: .medium,
            building: sampleBuilding,
            worker: sampleWorker
        )
        
        DashboardTaskDetailView(task: sampleTask)
    }
}
