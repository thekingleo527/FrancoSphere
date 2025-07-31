//
//  SimplifiedTaskView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/31/25.
//


//
//  SimplifiedTaskView.swift
//  FrancoSphere
//
//  Stream A: Claude - UI/UX & Spanish
//  Mission: Create simplified interfaces for specific worker capabilities.
//
//  ✅ PRODUCTION READY: A high-contrast, accessible view for task completion.
//  ✅ SPANISH-READY: All text uses LocalizedStringKey for translation.
//  ✅ ACCESSIBLE: Large touch targets and clear, simple layout.
//  ✅ CAPABILITY-DRIVEN: Designed to be shown for workers with the `simplifiedInterface` flag.
//

import SwiftUI
// Note: CoreTypes is not explicitly imported because it's aliased globally.
// This view will depend on `ContextualTask`.

struct SimplifiedTaskView: View {
    
    // ViewModel to handle the business logic, injected from the parent view.
    @ObservedObject var viewModel: TaskDetailViewModel
    
    // The task to display, passed from the list view.
    let task: ContextualTask
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // High-contrast background for readability
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Task Title Card
                taskInfoCard
                
                // Building Info Card
                buildingInfoCard
                
                Spacer()
                
                // Single, large completion button
                completionButton
            }
            .padding()
        }
        .onAppear {
            // Load the task into the ViewModel when the view appears.
            Task {
                await viewModel.loadTask(task)
            }
        }
        .alert("Success", isPresented: $viewModel.showSuccess) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Task marked as complete.")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        }
    }
    
    // MARK: - View Components
    
    private var taskInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // Icon representing the task category
                Image(systemName: task.category?.icon ?? "hammer.fill")
                    .font(.title)
                    .foregroundColor(.accentColor)
                    .frame(width: 50, height: 50)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    // Task Title (Large and Bold)
                    Text(LocalizedStringKey(task.title))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.8)
                }
            }
            
            // Description if available
            if let description = task.description, !description.isEmpty {
                Text(LocalizedStringKey(description))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private var buildingInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "building.2.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading) {
                    Text("Building", bundle: .main)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(LocalizedStringKey(viewModel.buildingName))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            if let dueDate = task.dueDate {
                Divider()
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundColor(isOverdue ? .red : .secondary)
                    
                    VStack(alignment: .leading) {
                        Text("Due Time", bundle: .main)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(dueDate.formatted(date: .omitted, time: .shortened))
                            .font(.body)
                            .foregroundColor(isOverdue ? .red : .secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private var completionButton: some View {
        Button(action: {
            Task {
                await viewModel.completeTask()
            }
        }) {
            HStack {
                Spacer()
                if viewModel.isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                        Text("Complete Task", bundle: .main)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                Spacer()
            }
            .padding()
            .frame(minHeight: 80) // Large touch target
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(20)
            .shadow(color: .green.opacity(0.4), radius: 10, y: 5)
        }
        .disabled(viewModel.isSubmitting)
    }
    
    // MARK: - Computed Properties
    
    private var isOverdue: Bool {
        guard let dueDate = task.dueDate else { return false }
        return !task.isCompleted && Date() > dueDate
    }
}

// MARK: - Preview
struct SimplifiedTaskView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock task using the CoreTypes model
        let mockTask = ContextualTask(
            id: "simplified-task-1",
            title: "Limpiar Entrada Principal", // Spanish title
            description: "Asegúrese de que el vestíbulo y las ventanas estén impecables.",
            status: .pending,
            dueDate: Date().addingTimeInterval(3600), // Due in 1 hour
            category: .cleaning,
            urgency: .high,
            buildingId: "14",
            buildingName: "Rubin Museum"
        )
        
        // Create a ViewModel instance for the preview
        let viewModel = TaskDetailViewModel()
        
        SimplifiedTaskView(viewModel: viewModel, task: mockTask)
            // For previewing in dark mode with larger text for accessibility testing
            .preferredColorScheme(.dark)
            .environment(\.sizeCategory, .accessibilityLarge)
    }
}
