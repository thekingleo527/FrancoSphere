//
//  MaintenanceHistoryView.swift
//  FrancoSphere
//
//  Updated by Shawn Magloire on 3/3/25.
//

import SwiftUI

struct MaintenanceHistoryView: View {
    let buildingID: String
    @State private var maintRecords: [MaintenanceRecord] = []
    @State private var isLoading = true
    @State private var filterOption: FilterOption = .all
    @State private var searchText = ""
    @State private var showExport = false
    @State private var selectedDate: Date = Date()
    @State private var dateRange: DateRange = .lastMonth
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case cleaning = "Cleaning"
        case maintenance = "Maintenance"
        case repairs = "Repairs"
        case inspection = "Inspection"
    }
    
    enum DateRange: String, CaseIterable {
        case lastWeek = "Last Week"
        case lastMonth = "Last Month"
        case lastThreeMonths = "Last 3 Months"
        case lastYear = "Last Year"
        case custom = "Custom"
        
        var days: Int {
            switch self {
            case .lastWeek: return 7
            case .lastMonth: return 30
            case .lastThreeMonths: return 90
            case .lastYear: return 365
            case .custom: return 0 // Used with date picker
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and filter bar
            searchFilterBar
            
            // Main content
            if isLoading {
                loadingView
            } else if filteredRecords.isEmpty {
                emptyStateView
            } else {
                recordsListView
            }
        }
        .navigationTitle("Maintenance History")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        refreshData()
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    
                    Button(action: {
                        showExport = true
                    }) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    
                    Menu("Date Range") {
                        ForEach(DateRange.allCases, id: \.self) { range in
                            Button(action: {
                                dateRange = range
                                if range == .custom {
                                    // Show date picker
                                } else {
                                    applyDateRange(range)
                                }
                            }) {
                                Label(range.rawValue, systemImage: range == dateRange ? "checkmark" : "calendar")
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            loadData()
        }
        .sheet(isPresented: $showExport) {
            ExportOptionsView(buildingID: buildingID, records: filteredRecords)
        }
    }
    
    // MARK: - UI Components
    
    private var searchFilterBar: some View {
        VStack(spacing: 8) {
            // Search field
            SwiftUI.HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search maintenance records", text: $searchText)
                    .autocapitalization(.none)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Filter tabs
            ScrollView(.horizontal, showsIndicators: false) {
                SwiftUI.HStack(spacing: 8) {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        Button(action: {
                            filterOption = option
                        }) {
                            Text(option.rawValue)
                                .font(.callout)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(filterOption == option ? Color.blue : Color(.systemGray6))
                                .foregroundColor(filterOption == option ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            Divider()
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .padding()
            
            Text("Loading maintenance records...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No maintenance records found")
                .font(.headline)
            
            Text("Try adjusting your filters or search criteria")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                // Reset filters
                filterOption = .all
                searchText = ""
                dateRange = .lastMonth
                applyDateRange(dateRange)
                
                refreshData()
            }) {
                Text("Reset Filters")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var recordsListView: some View {
        List {
            Section(header: recordsHeader) {
                ForEach(filteredRecords) { record in
                    maintenanceRecordRow(record)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var recordsHeader: some View {
        SwiftUI.HStack {
            Text("\(filteredRecords.count) Records")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(formatDateRange())
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func maintenanceRecordRow(_ record: MaintenanceRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SwiftUI.HStack {
                // Task category icon based on task name
                Image(systemName: getRecordCategoryIcon(record))
                    .foregroundColor(getRecordCategoryColor(record))
                    .font(.headline)
                
                Text(record.taskName)
                    .font(.headline)
                
                Spacer()
                
                Text(record.formattedCompletionDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let notes = record.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
            
            SwiftUI.HStack {
                Label("Completed by: \(record.completedBy)", systemImage: "person")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Methods
    
    private var filteredRecords: [MaintenanceRecord] {
        // Apply search and category filters
        var records = maintRecords
        
        // Filter by search text
        if !searchText.isEmpty {
            records = records.filter { record in
                return record.taskName.localizedCaseInsensitiveContains(searchText) ||
                       (record.notes ?? "").localizedCaseInsensitiveContains(searchText) ||
                       record.completedBy.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by category
        if filterOption != .all {
            records = records.filter { record in
                return matchesCategory(record: record, category: filterOption)
            }
        }
        
        // Sort by completion date (newest first)
        return records.sorted { $0.completionDate > $1.completionDate }
    }
    
    private func matchesCategory(record: MaintenanceRecord, category: FilterOption) -> Bool {
        let taskName = record.taskName.lowercased()
        
        switch category {
        case .all:
            return true
        case .cleaning:
            return taskName.contains("clean") ||
                   taskName.contains("wash") ||
                   taskName.contains("sanit")
        case .maintenance:
            return taskName.contains("maint") ||
                   taskName.contains("service") ||
                   taskName.contains("filter") ||
                   taskName.contains("hvac")
        case .repairs:
            return taskName.contains("repair") ||
                   taskName.contains("fix") ||
                   taskName.contains("replace")
        case .inspection:
            return taskName.contains("inspect") ||
                   taskName.contains("check") ||
                   taskName.contains("verify") ||
                   taskName.contains("test")
        }
    }
    
    private func getRecordCategoryIcon(_ record: MaintenanceRecord) -> String {
        let taskName = record.taskName.lowercased()
        
        if taskName.contains("clean") || taskName.contains("wash") || taskName.contains("sanit") {
            return "spray.and.wipe"
        } else if taskName.contains("repair") || taskName.contains("fix") || taskName.contains("replace") {
            return "hammer"
        } else if taskName.contains("inspect") || taskName.contains("check") || taskName.contains("verify") {
            return "checklist"
        } else if taskName.contains("trash") || taskName.contains("garbage") || taskName.contains("waste") {
            return "trash"
        } else {
            return "wrench.and.screwdriver"
        }
    }
    
    private func getRecordCategoryColor(_ record: MaintenanceRecord) -> Color {
        let taskName = record.taskName.lowercased()
        
        if taskName.contains("clean") || taskName.contains("wash") || taskName.contains("sanit") {
            return .blue
        } else if taskName.contains("repair") || taskName.contains("fix") || taskName.contains("replace") {
            return .red
        } else if taskName.contains("inspect") || taskName.contains("check") || taskName.contains("verify") {
            return .purple
        } else if taskName.contains("trash") || taskName.contains("garbage") || taskName.contains("waste") {
            return .green
        } else {
            return .orange
        }
    }
    
    private func formatDateRange() -> String {
        switch dateRange {
        case .custom:
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return "Since \(formatter.string(from: selectedDate))"
        default:
            return dateRange.rawValue
        }
    }
    
    private func applyDateRange(_ range: DateRange) {
        // Calculate the date from which to show records
        let calendar = Calendar.current
        let days = range.days
        
        if days > 0 {
            selectedDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        }
        
        // Refresh data with the new date range
        loadData()
    }
    
    // MARK: - Data Operations
    
    private func loadData() {
        isLoading = true
        
        // In a real app, use selectedDate to filter
        maintRecords = TaskManager.shared.fetchMaintenanceHistory(forBuilding: buildingID, limit: 100)
        
        // Filter by date based on selectedDate
        maintRecords = maintRecords.filter { $0.completionDate >= selectedDate }
        
        isLoading = false
    }
    
    private func refreshData() {
        isLoading = true
        loadData()
    }
}

// MARK: - Supporting Views

struct ExportOptionsView: View {
    let buildingID: String
    let records: [MaintenanceRecord]
    @State private var exportFormat: ExportFormat = .csv
    @State private var includeNotes = true
    @State private var includeDates = true
    @State private var isExporting = false
    @Environment(\.presentationMode) var presentationMode
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case pdf = "PDF"
        case text = "Plain Text"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Export Format")) {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Content Options")) {
                    Toggle("Include Notes", isOn: $includeNotes)
                    Toggle("Include Dates", isOn: $includeDates)
                    
                    SwiftUI.HStack {
                        Text("Records to export")
                        Spacer()
                        Text("\(records.count)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: {
                        exportRecords()
                    }) {
                        if isExporting {
                            SwiftUI.HStack {
                                ProgressView()
                                    .padding(.trailing, 10)
                                Text("Exporting...")
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text("Export Records")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(isExporting)
                }
            }
            .navigationTitle("Export Options")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func exportRecords() {
        isExporting = true
        
        // Simulate export process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // In a real app, this would create and share the export file
            isExporting = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview Support

struct MaintenanceHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MaintenanceHistoryView(buildingID: "1")
        }
    }
}
