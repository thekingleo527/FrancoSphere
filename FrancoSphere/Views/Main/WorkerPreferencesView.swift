
//  WorkerPreferencesView.swift
//  FrancoSphere
//
//  Stream A: UI/UX & Spanish
//  Mission: Allow workers to customize their app experience.
//
//  ✅ PRODUCTION READY: Complete preferences management for workers.
//  ✅ INTEGRATED: Works with ThemeManager, GRDBManager, and worker capabilities.
//  ✅ ACCESSIBLE: Large touch targets and clear visual feedback.
//  ✅ BILINGUAL: Supports English/Spanish language switching.
//

import SwiftUI

struct WorkerPreferencesView: View {
    
    @StateObject private var viewModel: WorkerPreferencesViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    init(workerId: String) {
        self._viewModel = StateObject(wrappedValue: WorkerPreferencesViewModel(workerId: workerId))
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Language Section
                languageSection
                
                // Display Section
                displaySection
                
                // Accessibility Section
                accessibilitySection
                
                // Notifications Section
                notificationsSection
                
                // About Section
                aboutSection
            }
            .navigationTitle(LocalizedStringKey("Preferences"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStringKey("Done")) {
                        Task {
                            await viewModel.savePreferences()
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .task {
            await viewModel.loadPreferences()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Failed to save preferences")
        }
    }
    
    // MARK: - Sections
    
    private var languageSection: some View {
        Section {
            HStack {
                Label("Language", systemImage: "globe")
                Spacer()
                Picker("Language", selection: $viewModel.selectedLanguage) {
                    Text("English").tag("en")
                    Text("Español").tag("es")
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.selectedLanguage) { newValue in
                    // Update app language immediately
                    updateAppLanguage(to: newValue)
                }
            }
        } header: {
            Text("Preferred Language", bundle: .main)
        } footer: {
            Text("Choose your preferred language for the app interface.", bundle: .main)
                .font(.caption)
        }
    }
    
    private var displaySection: some View {
        Section {
            // Text Size
            VStack(alignment: .leading, spacing: 12) {
                Label("Text Size", systemImage: "textformat.size")
                
                HStack(spacing: 16) {
                    Image(systemName: "textformat.size.smaller")
                        .foregroundColor(.secondary)
                    
                    Slider(value: $viewModel.textSizeMultiplier, in: 0.8...1.5, step: 0.1)
                    
                    Image(systemName: "textformat.size.larger")
                        .foregroundColor(.secondary)
                }
                
                // Preview text
                Text("Sample Text", bundle: .main)
                    .font(.body)
                    .scaleEffect(viewModel.textSizeMultiplier)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(8)
            }
            .padding(.vertical, 4)
            
            // High Contrast
            Toggle(isOn: $viewModel.useHighContrast) {
                Label("High Contrast Mode", systemImage: "circle.lefthalf.filled")
            }
            .onChange(of: viewModel.useHighContrast) { newValue in
                themeManager.toggleHighContrast(isOn: newValue)
            }
            
            // Theme Selection
            HStack {
                Label("Theme", systemImage: "moon.circle")
                Spacer()
                Picker("Theme", selection: $viewModel.selectedTheme) {
                    ForEach(ThemeManager.Theme.allCases) { theme in
                        Text(LocalizedStringKey(theme.displayName)).tag(theme)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.selectedTheme) { newValue in
                    themeManager.applyTheme(newValue)
                }
            }
        } header: {
            Text("Display", bundle: .main)
        }
    }
    
    private var accessibilitySection: some View {
        Section {
            // Simplified Interface
            Toggle(isOn: $viewModel.useSimplifiedInterface) {
                Label("Simplified Interface", systemImage: "square.grid.2x2")
            }
            
            // Photo Requirements
            if viewModel.canTogglePhotoRequirement {
                Toggle(isOn: $viewModel.requiresPhoto) {
                    Label("Require Photos for Tasks", systemImage: "camera")
                }
            }
            
            // Reduce Motion
            Toggle(isOn: $viewModel.reduceMotion) {
                Label("Reduce Motion", systemImage: "figure.walk.motion")
            }
        } header: {
            Text("Accessibility", bundle: .main)
        } footer: {
            if viewModel.useSimplifiedInterface {
                Text("Simplified interface shows only essential features with larger buttons.", bundle: .main)
                    .font(.caption)
            }
        }
    }
    
    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $viewModel.enableNotifications) {
                Label("Enable Push Notifications", systemImage: "bell")
            }
            
            if viewModel.enableNotifications {
                Toggle(isOn: $viewModel.urgentTaskAlerts) {
                    Label("Urgent Task Alerts", systemImage: "exclamationmark.triangle")
                }
                
                Toggle(isOn: $viewModel.clockInReminders) {
                    Label("Clock In Reminders", systemImage: "clock")
                }
                
                Toggle(isOn: $viewModel.endOfDayReports) {
                    Label("End of Day Reports", systemImage: "doc.text")
                }
            }
        } header: {
            Text("Notifications", bundle: .main)
        }
    }
    
    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("6.0.0")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Worker ID")
                Spacer()
                Text(viewModel.workerId)
                    .foregroundColor(.secondary)
                    .font(.system(.caption, design: .monospaced))
            }
        } header: {
            Text("About", bundle: .main)
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateAppLanguage(to languageCode: String) {
        // Update UserDefaults for language preference
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        
        // Note: In a production app, you might want to show an alert
        // suggesting the user restart the app for full language change
    }
}

// MARK: - View Model

@MainActor
class WorkerPreferencesViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Language & Display
    @Published var selectedLanguage = "en"
    @Published var textSizeMultiplier: Double = 1.0
    @Published var useHighContrast = false
    @Published var selectedTheme: ThemeManager.Theme = .system
    
    // Accessibility
    @Published var useSimplifiedInterface = false
    @Published var requiresPhoto = true
    @Published var reduceMotion = false
    
    // Notifications
    @Published var enableNotifications = true
    @Published var urgentTaskAlerts = true
    @Published var clockInReminders = true
    @Published var endOfDayReports = false
    
    // UI State
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    // Configuration
    let workerId: String
    var canTogglePhotoRequirement = true
    
    // Services
    private let grdbManager = GRDBManager.shared
    private let themeManager = ThemeManager.shared
    
    init(workerId: String) {
        self.workerId = workerId
    }
    
    // MARK: - Data Operations
    
    func loadPreferences() async {
        isLoading = true
        
        do {
            // Load from worker_capabilities table
            let rows = try await grdbManager.query("""
                SELECT * FROM worker_capabilities
                WHERE worker_id = ?
                LIMIT 1
            """, [workerId])
            
            if let row = rows.first {
                // Map database values to view model properties
                await MainActor.run {
                    self.useSimplifiedInterface = (row["simplified_interface"] as? Int64 ?? 0) == 1
                    self.requiresPhoto = (row["requires_photo_for_sanitation"] as? Int64 ?? 1) == 1
                    
                    // Check if worker can toggle photo requirement
                    self.canTogglePhotoRequirement = (row["can_add_emergency_tasks"] as? Int64 ?? 0) == 1
                }
            }
            
            // Load language preference from UserDefaults
            if let languages = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String],
               let firstLang = languages.first {
                selectedLanguage = firstLang.hasPrefix("es") ? "es" : "en"
            }
            
            // Load display preferences from UserDefaults (or worker-specific storage)
            loadDisplayPreferences()
            
            // Load notification preferences
            loadNotificationPreferences()
            
        } catch {
            errorMessage = "Failed to load preferences: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    func savePreferences() async {
        do {
            // First, ensure worker_capabilities record exists
            let existingRows = try await grdbManager.query("""
                SELECT COUNT(*) as count FROM worker_capabilities
                WHERE worker_id = ?
            """, [workerId])
            
            let exists = (existingRows.first?["count"] as? Int64 ?? 0) > 0
            
            if exists {
                // Update existing record
                try await grdbManager.execute("""
                    UPDATE worker_capabilities
                    SET simplified_interface = ?,
                        requires_photo_for_sanitation = ?,
                        updated_at = ?
                    WHERE worker_id = ?
                """, [
                    useSimplifiedInterface ? 1 : 0,
                    requiresPhoto ? 1 : 0,
                    Date().ISO8601Format(),
                    workerId
                ])
            } else {
                // Insert new record with defaults
                try await grdbManager.execute("""
                    INSERT INTO worker_capabilities (
                        worker_id, can_upload_photos, can_add_notes,
                        can_view_map, can_add_emergency_tasks,
                        requires_photo_for_sanitation, simplified_interface,
                        created_at, updated_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, [
                    workerId,
                    1, // can_upload_photos default
                    1, // can_add_notes default
                    1, // can_view_map default
                    0, // can_add_emergency_tasks default
                    requiresPhoto ? 1 : 0,
                    useSimplifiedInterface ? 1 : 0,
                    Date().ISO8601Format(),
                    Date().ISO8601Format()
                ])
            }
            
            // Save display preferences
            saveDisplayPreferences()
            
            // Save notification preferences
            saveNotificationPreferences()
            
            print("✅ Preferences saved successfully for worker \(workerId)")
            
        } catch {
            errorMessage = "Failed to save preferences: \(error.localizedDescription)"
            showError = true
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadDisplayPreferences() {
        // Load from UserDefaults with worker-specific keys
        let defaults = UserDefaults.standard
        let prefix = "worker_\(workerId)_"
        
        textSizeMultiplier = defaults.double(forKey: "\(prefix)textSize")
        if textSizeMultiplier == 0 { textSizeMultiplier = 1.0 }
        
        useHighContrast = defaults.bool(forKey: "\(prefix)highContrast")
        reduceMotion = defaults.bool(forKey: "\(prefix)reduceMotion")
        
        // Load theme from ThemeManager
        selectedTheme = themeManager.currentTheme
        useHighContrast = themeManager.useHighContrast
    }
    
    private func saveDisplayPreferences() {
        let defaults = UserDefaults.standard
        let prefix = "worker_\(workerId)_"
        
        defaults.set(textSizeMultiplier, forKey: "\(prefix)textSize")
        defaults.set(useHighContrast, forKey: "\(prefix)highContrast")
        defaults.set(reduceMotion, forKey: "\(prefix)reduceMotion")
    }
    
    private func loadNotificationPreferences() {
        let defaults = UserDefaults.standard
        let prefix = "worker_\(workerId)_"
        
        enableNotifications = defaults.bool(forKey: "\(prefix)enableNotifications")
        urgentTaskAlerts = defaults.bool(forKey: "\(prefix)urgentTaskAlerts")
        clockInReminders = defaults.bool(forKey: "\(prefix)clockInReminders")
        endOfDayReports = defaults.bool(forKey: "\(prefix)endOfDayReports")
        
        // Default to true for important notifications
        if !defaults.bool(forKey: "\(prefix)hasSetNotificationPrefs") {
            enableNotifications = true
            urgentTaskAlerts = true
            clockInReminders = true
            defaults.set(true, forKey: "\(prefix)hasSetNotificationPrefs")
        }
    }
    
    private func saveNotificationPreferences() {
        let defaults = UserDefaults.standard
        let prefix = "worker_\(workerId)_"
        
        defaults.set(enableNotifications, forKey: "\(prefix)enableNotifications")
        defaults.set(urgentTaskAlerts, forKey: "\(prefix)urgentTaskAlerts")
        defaults.set(clockInReminders, forKey: "\(prefix)clockInReminders")
        defaults.set(endOfDayReports, forKey: "\(prefix)endOfDayReports")
    }
}

// MARK: - Preview

struct WorkerPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // English version
            WorkerPreferencesView(workerId: "4") // Kevin
                .environmentObject(ThemeManager.shared)
                .environment(\.locale, .init(identifier: "en"))
            
            // Spanish version
            WorkerPreferencesView(workerId: "5") // Mercedes
                .environmentObject(ThemeManager.shared)
                .environment(\.locale, .init(identifier: "es"))
                .preferredColorScheme(.dark)
        }
    }
}
