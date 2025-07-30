//

//  BuildingMetricsComponents.swift
//  FrancoSphere v6.0
//
//  Building metrics visualization components
//  Integrates with BuildingMetricsService for real-time data
//

import SwiftUI
import Combine
import Charts

// MARK: - Building Metrics Dashboard

struct BuildingMetricsDashboard: View {
    let buildingId: String
    let buildingName: String
    @StateObject private var viewModel = BuildingMetricsViewModel()
    @State private var selectedTimeRange = TimeRange.today
    
    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        
        var days: Int {
            switch self {
            case .today: return 1
            case .week: return 7
            case .month: return 30
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time range selector
                TimeRangePicker(selection: $selectedTimeRange)
                    .padding(.horizontal)
                
                if viewModel.isLoading {
                    ProgressView("Loading metrics...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let metrics = viewModel.metrics {
                    // Overall score card
                    OverallScoreCard(metrics: metrics)
                    
                    // Key metrics grid
                    MetricsGridView(metrics: metrics)
                    
                    // Completion chart
                    TaskCompletionChart(
                        metrics: metrics,
                        timeRange: selectedTimeRange
                    )
                    
                    // Worker productivity
                    WorkerProductivityGraph(
                        buildingId: buildingId,
                        activeWorkers: metrics.activeWorkers
                    )
                    
                    // Maintenance efficiency
                    MaintenanceEfficiencyCard(
                        efficiency: metrics.maintenanceEfficiency
                    )
                    
                    // Cost analysis (if available)
                    if let costData = viewModel.costAnalysis {
                        CostAnalysisCard(costData: costData)
                    }
                }
            }
            .padding(.vertical)
        }
        .task {
            await viewModel.loadMetrics(for: buildingId)
        }
        .refreshable {
            await viewModel.refreshMetrics(for: buildingId)
        }
    }
}

// MARK: - Overall Score Card

struct OverallScoreCard: View {
    let metrics: CoreTypes.BuildingMetrics
    
    private var scoreColor: Color {
        switch metrics.overallScore {
        case 90...100: return .green
        case 70..<90: return .yellow
        case 50..<70: return .orange
        default: return .red
        }
    }
    
    private var scoreGrade: String {
        switch metrics.overallScore {
        case 90...100: return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        case 60..<70: return "D"
        default: return "F"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Building Score")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 150, height: 150)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: metrics.overallScore / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: metrics.overallScore)
                
                // Score text
                VStack(spacing: 4) {
                    Text("\(Int(metrics.overallScore))")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(scoreColor)
                    
                    Text(scoreGrade)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(scoreColor)
                }
            }
            
            Text(metrics.displayStatus)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                Label("\(metrics.urgentTasksCount) Urgent", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                if metrics.hasWorkerOnSite {
                    Label("Worker On-Site", systemImage: "person.fill.checkmark")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

// MARK: - Metrics Grid View

struct MetricsGridView: View {
    let metrics: CoreTypes.BuildingMetrics
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            MetricCard(
                title: "Completion Rate",
                value: "\(Int(metrics.completionRate * 100))%",
                icon: "checkmark.circle.fill",
                color: completionColor,
                trend: metrics.weeklyCompletionTrend > metrics.completionRate ? .up : .down
            )
            
            MetricCard(
                title: "Active Workers",
                value: "\(metrics.activeWorkers)",
                icon: "person.2.fill",
                color: .blue,
                subtitle: metrics.hasWorkerOnSite ? "On-site now" : "None on-site"
            )
            
            MetricCard(
                title: "Tasks Today",
                value: "\(metrics.totalTasks)",
                icon: "list.bullet.clipboard",
                color: .purple,
                subtitle: "\(metrics.pendingTasks) pending"
            )
            
            MetricCard(
                title: "Overdue Tasks",
                value: "\(metrics.overdueTasks)",
                icon: "clock.badge.exclamationmark",
                color: metrics.overdueTasks > 0 ? .red : .green,
                showWarning: metrics.overdueTasks > 0
            )
        }
        .padding(.horizontal)
    }
    
    private var completionColor: Color {
        switch metrics.completionRate {
        case 0.9...1.0: return .green
        case 0.7..<0.9: return .yellow
        case 0.5..<0.7: return .orange
        default: return .red
        }
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var subtitle: String? = nil
    var trend: CoreTypes.TrendDirection? = nil
    var showWarning: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.caption)
                        .foregroundColor(trend == .up ? .green : .red)
                }
                
                if showWarning {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(color)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Task Completion Chart

struct TaskCompletionChart: View {
    let metrics: CoreTypes.BuildingMetrics
    let timeRange: BuildingMetricsDashboard.TimeRange
    @State private var chartData: [DailyCompletion] = []
    
    struct DailyCompletion: Identifiable {
        let id = UUID()
        let date: Date
        let completed: Int
        let total: Int
        
        var completionRate: Double {
            total > 0 ? Double(completed) / Double(total) : 0
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Task Completion Trends")
                .font(.headline)
            
            if chartData.isEmpty {
                // Placeholder while loading
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: 200)
                    .overlay(
                        Text("Loading chart data...")
                            .foregroundColor(.secondary)
                    )
            } else {
                Chart(chartData) { data in
                    BarMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value("Completion", data.completionRate)
                    )
                    .foregroundStyle(
                        data.completionRate >= 0.8 ? Color.green : 
                        data.completionRate >= 0.6 ? Color.yellow : Color.red
                    )
                }
                .frame(height: 200)
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let rate = value.as(Double.self) {
                                Text("\(Int(rate * 100))%")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
        .task {
            await loadChartData()
        }
    }
    
    private func loadChartData() async {
        // In real implementation, fetch from BuildingMetricsService
        // For now, generate sample data based on current metrics
        var data: [DailyCompletion] = []
        let calendar = Calendar.current
        
        for i in 0..<timeRange.days {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let variation = Double.random(in: -0.1...0.1)
                let rate = max(0, min(1, metrics.completionRate + variation))
                let total = metrics.totalTasks
                let completed = Int(Double(total) * rate)
                
                data.append(DailyCompletion(
                    date: date,
                    completed: completed,
                    total: total
                ))
            }
        }
        
        chartData = data.reversed()
    }
}

// MARK: - Worker Productivity Graph

struct WorkerProductivityGraph: View {
    let buildingId: String
    let activeWorkers: Int
    @State private var productivityData: [WorkerProductivity] = []
    
    struct WorkerProductivity: Identifiable {
        let id = UUID()
        let workerName: String
        let tasksCompleted: Int
        let efficiency: Double
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Worker Productivity")
                    .font(.headline)
                
                Spacer()
                
                Text("\(activeWorkers) Active")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if productivityData.isEmpty {
                Text("No worker data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                ForEach(productivityData) { worker in
                    WorkerProductivityRow(worker: worker)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
        .task {
            await loadProductivityData()
        }
    }
    
    private func loadProductivityData() async {
        // In real implementation, fetch from service
        // Mock data for now
        productivityData = [
            WorkerProductivity(workerName: "Kevin D.", tasksCompleted: 12, efficiency: 0.92),
            WorkerProductivity(workerName: "Maria S.", tasksCompleted: 10, efficiency: 0.88),
            WorkerProductivity(workerName: "Luis L.", tasksCompleted: 8, efficiency: 0.75)
        ].prefix(activeWorkers).map { $0 }
    }
}

struct WorkerProductivityRow: View {
    let worker: WorkerProductivityGraph.WorkerProductivity
    
    private var efficiencyColor: Color {
        switch worker.efficiency {
        case 0.9...1.0: return .green
        case 0.7..<0.9: return .yellow
        default: return .orange
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(worker.workerName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(worker.tasksCompleted) tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                ProgressView(value: worker.efficiency)
                    .progressViewStyle(LinearProgressViewStyle(tint: efficiencyColor))
                    .frame(width: 60)
                
                Text("\(Int(worker.efficiency * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(efficiencyColor)
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Cost Analysis Card

struct CostAnalysisCard: View {
    let costData: CostAnalysisData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cost Analysis")
                .font(.headline)
            
            HStack(spacing: 20) {
                CostMetric(
                    label: "Monthly",
                    value: costData.monthlyCost,
                    trend: costData.monthlyTrend
                )
                
                Divider()
                    .frame(height: 40)
                
                CostMetric(
                    label: "Per Task",
                    value: costData.costPerTask,
                    trend: costData.taskCostTrend
                )
                
                Divider()
                    .frame(height: 40)
                
                CostMetric(
                    label: "Efficiency",
                    value: costData.efficiency,
                    format: .percentage
                )
            }
            
            if let savings = costData.potentialSavings {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    
                    Text("Potential savings: $\(savings, specifier: "%.0f")/month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct CostMetric: View {
    let label: String
    let value: Double
    var trend: CoreTypes.TrendDirection? = nil
    var format: Format = .currency
    
    enum Format {
        case currency
        case percentage
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack(spacing: 4) {
                Text(formattedValue)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.caption)
                        .foregroundColor(trendColor(trend))
                }
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var formattedValue: String {
        switch format {
        case .currency:
            return "$\(Int(value))"
        case .percentage:
            return "\(Int(value * 100))%"
        }
    }
    
    private func trendColor(_ trend: CoreTypes.TrendDirection) -> Color {
        switch trend {
        case .up: return label.contains("Efficiency") ? .green : .red
        case .down: return label.contains("Efficiency") ? .red : .green
        case .stable: return .gray
        default: return .gray
        }
    }
}

// MARK: - Maintenance Efficiency Card

struct MaintenanceEfficiencyCard: View {
    let efficiency: Double
    
    private var efficiencyLevel: String {
        switch efficiency {
        case 0.9...1.0: return "Excellent"
        case 0.8..<0.9: return "Good"
        case 0.7..<0.8: return "Fair"
        default: return "Needs Improvement"
        }
    }
    
    private var efficiencyColor: Color {
        switch efficiency {
        case 0.9...1.0: return .green
        case 0.8..<0.9: return .blue
        case 0.7..<0.8: return .yellow
        default: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Maintenance Efficiency", systemImage: "wrench.and.screwdriver.fill")
                    .font(.headline)
                
                Spacer()
                
                Text(efficiencyLevel)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(efficiencyColor)
            }
            
            // Efficiency gauge
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 40)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(efficiencyColor)
                        .frame(width: geometry.size.width * efficiency, height: 40)
                    
                    Text("\(Int(efficiency * 100))%")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                }
            }
            .frame(height: 40)
            
            // Breakdown
            HStack(spacing: 20) {
                EfficiencyMetric(
                    label: "On-time",
                    value: efficiency * 0.95,
                    icon: "clock.fill"
                )
                
                EfficiencyMetric(
                    label: "Quality",
                    value: efficiency * 1.05,
                    icon: "star.fill"
                )
                
                EfficiencyMetric(
                    label: "Cost",
                    value: efficiency * 0.9,
                    icon: "dollarsign.circle.fill"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct EfficiencyMetric: View {
    let label: String
    let value: Double
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text("\(Int(min(value, 1.0) * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Utility Components

struct TimeRangePicker: View {
    @Binding var selection: BuildingMetricsDashboard.TimeRange
    
    var body: some View {
        Picker("Time Range", selection: $selection) {
            ForEach(BuildingMetricsDashboard.TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

// MARK: - View Model

@MainActor
class BuildingMetricsViewModel: ObservableObject {
    @Published var metrics: CoreTypes.BuildingMetrics?
    @Published var costAnalysis: CostAnalysisData?
    @Published var isLoading = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadMetrics(for buildingId: String) async {
        isLoading = true
        
        do {
            // Fetch metrics from service
            metrics = try await BuildingMetricsService.shared.calculateMetrics(for: buildingId)
            
            // Subscribe to real-time updates
            BuildingMetricsService.shared.subscribeToMetrics(for: buildingId)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] updatedMetrics in
                    self?.metrics = updatedMetrics
                }
                .store(in: &cancellables)
            
            // Load cost analysis (mock for now)
            costAnalysis = CostAnalysisData(
                monthlyCost: 12500,
                costPerTask: 45,
                efficiency: metrics?.maintenanceEfficiency ?? 0.85,
                monthlyTrend: .down,
                taskCostTrend: .stable,
                potentialSavings: 1250
            )
        } catch {
            self.error = error
            print("❌ Failed to load metrics: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshMetrics(for buildingId: String) async {
        // Invalidate cache and reload
        await BuildingMetricsService.shared.invalidateCache(for: buildingId)
        await loadMetrics(for: buildingId)
    }
}

// MARK: - Supporting Types

struct CostAnalysisData {
    let monthlyCost: Double
    let costPerTask: Double
    let efficiency: Double
    let monthlyTrend: CoreTypes.TrendDirection
    let taskCostTrend: CoreTypes.TrendDirection
    let potentialSavings: Double?
}

// MARK: - Preview Support

#Preview("Metrics Dashboard") {
    BuildingMetricsDashboard(
        buildingId: "14",
        buildingName: "Rubin Museum"
    )
}

#Preview("Score Card") {
    OverallScoreCard(
        metrics: CoreTypes.BuildingMetrics(
            buildingId: "14",
            completionRate: 0.92,
            overdueTasks: 2,
            totalTasks: 25,
            activeWorkers: 3,
            overallScore: 88.5,
            pendingTasks: 3,
            urgentTasksCount: 1,
            hasWorkerOnSite: true,
            maintenanceEfficiency: 0.87
        )
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
