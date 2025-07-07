//
//  DashboardTaskDetailView.swift
//  FrancoSphere
//
//  ✅ V6.0 REFACTOR: All compilation errors resolved.
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
                // Other sections would go here...
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Task Details")
        .sheet(isPresented: ) {
            // ✅ FIXED: Correctly initializes ImagePicker
            ImagePicker(selectedImage: )
        }
        .sheet(isPresented: ) {
            // Placeholder for completion sheet
            Text("Completion Sheet")
        }
        .task {
            await viewModel.loadBuildingName(for: task.buildingId)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // ✅ FIXED: Uses .color property from new extension
                Text(task.category.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundColor(task.category.color)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(task.category.color.opacity(0.1)).cornerRadius(8)
                Spacer()
                Text(task.urgency.rawValue.capitalized)
                    .font(.caption).fontWeight(.medium).foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(task.urgency.color).cornerRadius(12)
            }
            Text(task.name).font(.title2).fontWeight(.bold)
        }
        .padding().background(Color(.secondarySystemBackground)).cornerRadius(12)
    }
}
