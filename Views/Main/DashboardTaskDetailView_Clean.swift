import SwiftUI
import UIKit

struct DashboardTaskDetailView: View {
    let task: MaintenanceTask
    @Environment(\.presentationMode) var presentationMode
    @State private var isCompleting = false
    @State private var showingCompletionSheet = false
    @State private var buildingName = "Loading..."
    @State private var completionNotes = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                taskDetailsSection
                buildingInfoSection
                statusSection
                actionButtonsSection
                if let selectedImage = selectedImage {
                    completionPhotoSection(selectedImage)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .sheet(isPresented: $showingCompletionSheet) {
            completionSheet
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: imageSourceType, selectedImage: $selectedImage)
        }
        .onAppear {
            loadBuildingName()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: categoryIcon(for: task.category))
                    .font(.title2)
                    .foregroundColor(categoryColor(for: task.category))
                Text(task.name)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            if let dueDate = task.dueDate {
                Label {
                    Text(formatDate(dueDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } icon: {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var taskDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Task Information")
                .font(.headline)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Category", systemImage: "tag")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(task.category.rawValue.capitalized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                HStack {
                    Label("Priority", systemImage: "exclamationmark.triangle")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(task.urgency.rawValue.capitalized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(urgencyColor)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var buildingInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Building")
                .font(.headline)
            HStack {
                Image(systemName: "building.2")
                    .font(.title3)
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(buildingName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Building ID: \(task.buildingID)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .font(.headline)
            HStack {
                Circle()
                    .fill(task.isComplete ? Color.green : urgencyColor)
                    .frame(width: 12, height: 12)
                Text(task.isComplete ? "Completed" : "Pending")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                if task.isComplete {
                    Text("✓ Done")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if !task.isComplete {
                Button(action: { showingCompletionSheet = true }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark as Complete")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isCompleting)
            }
        }
    }
    
    private func completionPhotoSection(_ image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completion Photo")
                .font(.headline)
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var completionSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Complete Task")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                Spacer()
                HStack(spacing: 16) {
                    Button(action: { showingCompletionSheet = false }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                    Button(action: { completeTask() }) {
                        Text("Complete")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(isCompleting)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
    
    private var urgencyColor: Color {
        switch task.urgency {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    private func loadBuildingName() {
        Task {
            let name = await BuildingRepository.shared.getBuildingName(for: task.buildingID)
            await MainActor.run {
                self.buildingName = name ?? "Unknown Building"
            }
        }
    }
    
    private func completeTask() {
        isCompleting = true
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                self.isCompleting = false
                self.showingCompletionSheet = false
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func categoryColor(for category: TaskCategory) -> Color {
        switch category {
        case .cleaning: return .blue
        case .maintenance: return .orange
        case .repair: return .red
        case .sanitation: return .green
        case .inspection: return .purple
        }
    }
    
    private func categoryIcon(for category: TaskCategory) -> String {
        switch category {
        case .cleaning: return "sparkles"
        case .maintenance: return "wrench"
        case .repair: return "hammer"
        case .sanitation: return "trash"
        case .inspection: return "magnifyingglass"
        }
    }
}
