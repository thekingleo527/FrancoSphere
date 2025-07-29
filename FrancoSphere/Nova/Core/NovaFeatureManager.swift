//
//  NovaFeatureManager.swift
//  FrancoSphere v6.0
//
//  Manages Nova AI features and role-based capabilities
//  (Replacement for NovaAIContextManager - focused on feature management)
//

import Foundation
import SwiftUI
import Combine

//
//  NovaFeatureManager.swift
//  FrancoSphere v6.0
//
//  Manages Nova AI features and role-based capabilities
//  (Replacement for NovaAIContextManager - focused on feature management)
//

import Foundation
import SwiftUI
import Combine

// Note: DashboardUpdate type is imported from DashboardSyncService

// MARK: - Nova Feature Manager

@MainActor
public class NovaFeatureManager: ObservableObject {
    public static let shared = NovaFeatureManager()
    
    @Published public var availableFeatures: [NovaAIFeature] = []
    @Published public var suggestedActions: [CoreTypes.AISuggestion] = []
    @Published public var activeInsights: [CoreTypes.IntelligenceInsight] = []
    @Published public var isProcessing = false
    
    // Dependencies
    private let contextAdapter = WorkerContextEngineAdapter.shared
    private let intelligenceEngine = NovaIntelligenceEngine.shared
    private let dashboardSyncService = DashboardSyncService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupSubscriptions()
        updateFeatures()
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // Subscribe to dashboard updates
        dashboardSyncService.crossDashboardUpdates
            .sink(receiveValue: { [weak self] update in
                self?.handleDashboardUpdate(update)
            })
            .store(in: &cancellables)
        
        // Subscribe to worker context changes
        contextAdapter.$currentWorker
            .sink(receiveValue: { [weak self] _ in
                self?.updateFeatures()
            })
            .store(in: &cancellables)
        
        contextAdapter.$currentBuilding
            .sink(receiveValue: { [weak self] _ in
                self?.updateFeatures()
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Feature Management
    
    public func updateFeatures() {
        guard let worker = contextAdapter.currentWorker else { return }
        
        // Update features based on role
        availableFeatures = generateFeaturesForRole(worker.role)
        
        // Generate suggestions
        generateSuggestions()
        
        // Refresh insights
        Task {
            await refreshInsights()
        }
    }
    
    private func generateFeaturesForRole(_ role: CoreTypes.UserRole) -> [NovaAIFeature] {
        var features: [NovaAIFeature] = []
        
        // Common features for all roles
        features.append(contentsOf: [
            NovaAIFeature(
                id: "building-info",
                title: "Building Information",
                description: "Get details about your current building",
                icon: "building.2",
                category: .information,
                priority: .medium
            ),
            NovaAIFeature(
                id: "safety-protocols",
                title: "Safety Protocols",
                description: "Review safety guidelines",
                icon: "shield",
                category: .safety,
                priority: .high
            )
        ])
        
        // Role-specific features
        switch role {
        case .worker, .manager:  // Manager role covers supervisor functionality
            features.append(contentsOf: [
                NovaAIFeature(
                    id: "task-guidance",
                    title: "Task Guidance",
                    description: "Step-by-step task assistance",
                    icon: "checklist",
                    category: .taskManagement,
                    priority: .high
                ),
                NovaAIFeature(
                    id: "equipment-help",
                    title: "Equipment Help",
                    description: "Equipment usage and troubleshooting",
                    icon: "wrench.and.screwdriver",
                    category: .fieldAssistance,
                    priority: .medium
                ),
                NovaAIFeature(
                    id: "report-issue",
                    title: "Report Issue",
                    description: "Report problems or hazards",
                    icon: "exclamationmark.triangle",
                    category: .problemSolving,
                    priority: .high
                )
            ])
            
        case .admin:
            features.append(contentsOf: [
                NovaAIFeature(
                    id: "portfolio-analytics",
                    title: "Portfolio Analytics",
                    description: "AI-powered portfolio insights",
                    icon: "chart.line.uptrend.xyaxis",
                    category: .analytics,
                    priority: .high
                ),
                NovaAIFeature(
                    id: "workforce-optimization",
                    title: "Workforce Optimization",
                    description: "Optimize worker assignments",
                    icon: "person.3",
                    category: .optimization,
                    priority: .medium
                ),
                NovaAIFeature(
                    id: "predictive-maintenance",
                    title: "Predictive Maintenance",
                    description: "Forecast maintenance needs",
                    icon: "gear.badge.questionmark",
                    category: .predictive,
                    priority: .high
                )
            ])
            
        case .client:
            features.append(contentsOf: [
                NovaAIFeature(
                    id: "executive-summary",
                    title: "Executive Summary",
                    description: "AI-generated reports",
                    icon: "doc.text.magnifyingglass",
                    category: .reporting,
                    priority: .high
                ),
                NovaAIFeature(
                    id: "compliance-monitoring",
                    title: "Compliance Monitoring",
                    description: "Track compliance status",
                    icon: "checkmark.shield",
                    category: .compliance,
                    priority: .critical
                ),
                NovaAIFeature(
                    id: "strategic-insights",
                    title: "Strategic Insights",
                    description: "Long-term strategic recommendations",
                    icon: "lightbulb",
                    category: .strategic,
                    priority: .medium
                )
            ])
        }
        
        return features
    }
    
    // MARK: - Suggestions
    
    private func generateSuggestions() {
        Task {
            do {
                let worker = contextAdapter.currentWorker ?? CoreTypes.WorkerProfile(
                    id: "default",
                    name: "User",
                    email: "user@example.com",
                    role: .worker
                )
                
                let suggestions = try await intelligenceEngine.generateTaskRecommendations(for: worker)
                
                await MainActor.run {
                    self.suggestedActions = suggestions
                }
            } catch {
                print("Error generating suggestions: \(error)")
            }
        }
    }
    
    // MARK: - Insights
    
    private func refreshInsights() async {
        // Generate insights using NovaIntelligenceEngine
        let insights = await intelligenceEngine.generateInsights()
        
        await MainActor.run {
            self.activeInsights = insights
        }
    }
    
    // MARK: - Dashboard Updates
    
    private func handleDashboardUpdate(_ update: DashboardUpdate) {
        // Note: DashboardUpdate is from DashboardSyncService, not CoreTypes
        // React to dashboard changes
        switch update.type {
        case .taskCompleted:
            // Refresh suggestions after task completion
            generateSuggestions()
            
        case .buildingMetricsChanged:
            // Update insights when metrics change
            Task {
                await refreshInsights()
            }
            
        default:
            break
        }
    }
    
    // MARK: - Feature Execution
    
    public func executeFeature(_ feature: NovaAIFeature) async -> String {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Use NovaIntelligenceEngine to process feature requests
            let query = generateQueryForFeature(feature)
            let insight = try await intelligenceEngine.process(
                query: query,
                context: ["featureId": feature.id],
                priority: feature.priority
            )
            
            return insight.description
        } catch {
            return "I encountered an error processing your request. Please try again."
        }
    }
    
    private func generateQueryForFeature(_ feature: NovaAIFeature) -> String {
        switch feature.id {
        case "task-guidance":
            return "Provide step-by-step guidance for the current task"
        case "safety-protocols":
            return "List safety protocols for the current location"
        case "building-info":
            return "Provide information about the current building"
        case "portfolio-analytics":
            return "Generate portfolio performance analytics"
        case "workforce-optimization":
            return "Suggest workforce optimization strategies"
        case "predictive-maintenance":
            return "Predict upcoming maintenance needs"
        case "executive-summary":
            return "Generate executive summary of current operations"
        case "compliance-monitoring":
            return "Report on compliance status across portfolio"
        case "strategic-insights":
            return "Provide strategic insights for portfolio improvement"
        default:
            return feature.description
        }
    }
    
    // MARK: - Building Intelligence
    
    public func loadBuildingInsights(for buildingId: String) async {
        isProcessing = true
        
        do {
            let insight = try await intelligenceEngine.analyzeBuilding(buildingId)
            await MainActor.run {
                self.activeInsights = [insight]
                self.isProcessing = false
            }
        } catch {
            print("Error loading building insights: \(error)")
            await MainActor.run {
                self.isProcessing = false
            }
        }
    }
}

// MARK: - Supporting Types (Renamed to avoid conflicts)

public struct NovaAIFeature: Identifiable {
    public let id: String
    public let title: String
    public let description: String
    public let icon: String
    public let category: NovaAIFeatureCategory
    public let priority: CoreTypes.AIPriority
}

public enum NovaAIFeatureCategory {
    case fieldAssistance, safety, information, taskSpecific, buildingSpecific
    case weatherAdaptive, analytics, optimization, predictive, financial
    case compliance, teamManagement, qualityAssurance, training, problemSolving
    case reporting, monitoring, serviceManagement, performance, taskManagement
    case strategic
}

// MARK: - SwiftUI Integration

extension NovaFeatureManager {
    /// Get feature by ID
    public func getFeature(byId id: String) -> NovaAIFeature? {
        return availableFeatures.first { $0.id == id }
    }
}
