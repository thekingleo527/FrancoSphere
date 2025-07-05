//
//  DataInitializationView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/8/25.
//  FIXED VERSION - Includes missing InitializationViewModel

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


// MARK: - Missing InitializationViewModel
@MainActor
class InitializationViewModel: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var statusMessage: String = "Preparing..."
    @Published var isInitializing: Bool = false
    @Published var isComplete: Bool = false
    @Published var errors: [String] = []
    
    private let manager = DataInitializationManager.shared
    
    func startInitialization() async {
        isInitializing = true
        isComplete = false
        errors = []
        progress = 0.0
        
        // Monitor the manager's progress
        let progressTask = Task {
            while isInitializing && !isComplete {
                await MainActor.run {
                    self.progress = manager.initializationProgress
                    self.statusMessage = manager.currentStatus
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
        }
        
        do {
            let status = try await manager.initializeAllData()
            await MainActor.run {
                self.isComplete = status.isComplete
                self.errors = status.errors
                self.progress = 1.0
                self.isInitializing = false
            }
        } catch {
            await MainActor.run {
                self.errors.append(error.localizedDescription)
                self.isInitializing = false
                self.statusMessage = "Error: \(error.localizedDescription)"
            }
        }
        
        progressTask.cancel()
    }
}

// MARK: –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
// MARK: Loading / Initialization Screen

struct DataInitializationView: View {
    @StateObject private var viewModel = InitializationViewModel()
    @Binding var isInitialized: Bool

    @State private var showDetails = false
    @State private var animationPhase = 0.0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.05, green: 0.05, blue: 0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Logo + Title
                VStack(spacing: 20) {
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .shadow(color: .blue.opacity(0.5), radius: 20)
                        .scaleEffect(1 + animationPhase * 0.1)
                        .animation(
                            .easeInOut(duration: 2).repeatForever(autoreverses: true),
                            value: animationPhase
                        )

                    Text("FrancoSphere")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 10)
                }

                // Progress + Actions
                VStack(spacing: 24) {
                    progressSection

                    if viewModel.isComplete {
                        continueButton
                    } else if !viewModel.isInitializing && !viewModel.errors.isEmpty {
                        retryButton
                    }
                }

                Spacer()

                // Footer
                VStack(spacing: 8) {
                    Text("Franco Management Group")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    Text("Property Management System v1.0")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.bottom, 20)
            }
            .padding()
        }
        .onAppear {
            animationPhase = 1.0
            if !viewModel.isInitializing && !viewModel.isComplete {
                Task { await viewModel.startInitialization() }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Progress + Details

    private var progressSection: some View {
        VStack(spacing: 24) {
            // Progress bar + status text
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Initializing Database")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(viewModel.progress * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }

                ProgressView(value: viewModel.progress)
                    .progressViewStyle(CustomProgressViewStyle())
                    .frame(height: 8)

                Text(viewModel.statusMessage)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 40)

            // Show/hide detailed steps
            if viewModel.isInitializing || !viewModel.errors.isEmpty {
                Button {
                    withAnimation { showDetails.toggle() }
                } label: {
                    HStack {
                        Image(systemName: showDetails
                                    ? "chevron.up.circle"
                                    : "chevron.down.circle")
                        Text(showDetails ? "Hide Details" : "Show Details")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                }
            }

            if showDetails {
                detailsSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if !viewModel.errors.isEmpty && !showDetails {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("\(viewModel.errors.count) warnings during import")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 40)
            }
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Import Progress")
                .font(.caption).fontWeight(.semibold)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 8) {
                progressItem(label: "Database Setup",    isComplete: viewModel.progress > 0.1)
                progressItem(label: "Buildings Import",  isComplete: viewModel.progress > 0.3)
                progressItem(label: "Workers Import",    isComplete: viewModel.progress > 0.4)
                progressItem(label: "Task Assignments",  isComplete: viewModel.progress > 0.5)
                progressItem(label: "Maintenance Tasks", isComplete: viewModel.progress > 0.6)
                progressItem(label: "Final Setup",       isComplete: viewModel.progress > 0.8)
            }

            if !viewModel.errors.isEmpty {
                Divider().background(Color.white.opacity(0.2))
                Text("Errors (\(viewModel.errors.count))")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(.red)

                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.errors, id: \.self) { error in
                            Text("• \(error)")
                                .font(.caption2)
                                .foregroundColor(.red.opacity(0.8))
                        }
                    }
                }
                .frame(maxHeight: 100)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 40)
    }

    private func progressItem(label: String, isComplete: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundColor(isComplete ? .green : .white.opacity(0.3))
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
        }
    }

    // MARK: Buttons

    private var continueButton: some View {
        Button {
            withAnimation { isInitialized = true }
        } label: {
            HStack {
                Text("Continue to App")
                Image(systemName: "arrow.right.circle.fill")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(width: 200, height: 50)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .cornerRadius(25)
            .shadow(color: .blue.opacity(0.5), radius: 10)
        }
        .padding(.top, 20)
    }

    private var retryButton: some View {
        Button {
            Task { await viewModel.startInitialization() }
        } label: {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("Retry Import")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(width: 180, height: 44)
            .background(Color.orange)
            .cornerRadius(22)
        }
        .padding(.top, 20)
    }
}

// MARK: –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
// MARK: Hosting / Entrance View

struct DataInitializationHostView: View {
    @State private var isDataInitialized = false
    @State private var hasCheckedInitialization = false

    var body: some View {
        Group {
            if !hasCheckedInitialization {
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
                .onAppear(perform: checkInitializationStatus)

            } else if !isDataInitialized {
                DataInitializationView(isInitialized: $isDataInitialized)

            } else {
                // Replace `EmptyView()` with your real app root
                EmptyView()
            }
        }
    }

    private func checkInitializationStatus() {
        Task {
            let (b, w, t) = await DataInitializationManager.shared.verifyDataImport()
            await MainActor.run {
                if b > 0 && w > 0 && t > 0 {
                    isDataInitialized = true
                }
                hasCheckedInitialization = true
            }
        }
    }
}

// MARK: –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
// MARK: Custom Progress Bar Style

struct CustomProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .cyan]),
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(
                        width: geometry.size.width
                            * CGFloat(configuration.fractionCompleted ?? 0),
                        height: 8
                    )
                    .animation(
                        .easeInOut(duration: 0.3),
                        value: configuration.fractionCompleted
                    )
            }
        }
    }
}

// MARK: –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
// MARK: Preview

struct DataInitializationView_Previews: PreviewProvider {
    static var previews: some View {
        DataInitializationHostView()
            .preferredColorScheme(.dark)
    }
}
