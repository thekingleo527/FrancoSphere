//
//  NovaAIContextManager.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/17/25.
//


//
//  NovaAIContextFramework.swift
//  FrancoSphere v6.0
//
//  ✅ ROLE-BASED AI: Framework for contextual AI features
//  ✅ TASK-AWARE: AI adapts to current work context
//  ✅ BUILDING-SPECIFIC: Location-aware assistance
//  ✅ INTELLIGENT ROUTING: Different AI experiences per role
//

import Foundation
import SwiftUI

// MARK: - Nova AI Context System

@MainActor
class NovaAIContextManager: ObservableObject {
    static let shared = NovaAIContextManager()
    
    @Published var currentContext: AIContext?
    @Published var availableFeatures: [AIFeature] = []
    @Published var suggestedActions: [AISuggestion] = []
    
    private let contextAdapter = WorkerContextEngineAdapter.shared
    
    private init() {
        updateContext()
    }
    
    // MARK: - Context Management
    
    func updateContext() {
        guard let worker = contextAdapter.currentWorker else { return }
        
        currentContext = AIContext(
            userRole: worker.role,
            currentBuilding: contextAdapter.getCurrentClockInBuilding(),
            activeTask: getCurrentActiveTask(),
            assignedBuildings: contextAdapter.assignedBuildings,
            portfolioBuildings: contextAdapter.portfolioBuildings,
            urgentTasks: getUrgentTasks(),
            timeOfDay: getTimeOfDay(),
            weatherConditions: getCurrentWeather()
        )
        
        updateAvailableFeatures()
        generateSuggestions()
    }
    
    // MARK: - Role-Based Feature Sets
    
    private func updateAvailableFeatures() {
        guard let context = currentContext else { return }
        
        switch context.userRole {
        case .worker:
            availableFeatures = getWorkerFeatures(context: context)
        case .admin:
            availableFeatures = getAdminFeatures(context: context)
        case .supervisor:
            availableFeatures = getSupervisorFeatures(context: context)
        case .client:
            availableFeatures = getClientFeatures(context: context)
        }
    }
    
    // MARK: - Worker AI Features
    
    private func getWorkerFeatures(context: AIContext) -> [AIFeature] {
        var features: [AIFeature] = []
        
        // Core field assistance
        features.append(contentsOf: [
            AIFeature(
                id: "troubleshooting",
                title: "Equipment Troubleshooting",
                description: "Get step-by-step repair guidance",
                icon: "wrench.adjustable",
                category: .fieldAssistance,
                priority: context.activeTask != nil ? .high : .medium
            ),
            AIFeature(
                id: "safety-protocols",
                title: "Safety Protocols",
                description: "Emergency procedures and safety guidelines",
                icon: "shield.checkered",
                category: .safety,
                priority: .high
            ),
            AIFeature(
                id: "building-info",
                title: "Building Information",
                description: "Systems, layouts, and contact information",
                icon: "building.2",
                category: .information,
                priority: context.currentBuilding != nil ? .high : .low
            )
        ])
        
        // Task-specific features
        if let task = context.activeTask {
            features.append(
                AIFeature(
                    id: "task-guidance",
                    title: "Current Task Assistance",
                    description: "Help with: \(task.title)",
                    icon: "list.clipboard",
                    category: .taskSpecific,
                    priority: .critical
                )
            )
        }
        
        // Building-specific features
        if let building = context.currentBuilding {
            features.append(contentsOf: [
                AIFeature(
                    id: "building-systems",
                    title: "\(building.name) Systems",
                    description: "HVAC, electrical, and security info",
                    icon: "gear.2",
                    category: .buildingSpecific,
                    priority: .high
                ),
                AIFeature(
                    id: "maintenance-history",
                    title: "Maintenance History",
                    description: "Past work and known issues",
                    icon: "clock.arrow.circlepath",
                    category: .buildingSpecific,
                    priority: .medium
                )
            ])
        }
        
        // Weather-dependent features
        if context.weatherConditions?.requiresIndoorWork == true {
            features.append(
                AIFeature(
                    id: "indoor-tasks",
                    title: "Indoor Task Suggestions",
                    description: "Weather-appropriate alternatives",
                    icon: "cloud.rain",
                    category: .weatherAdaptive,
                    priority: .medium
                )
            )
        }
        
        return features.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    // MARK: - Admin AI Features
    
    private func getAdminFeatures(context: AIContext) -> [AIFeature] {
        [
            AIFeature(
                id: "portfolio-analytics",
                title: "Portfolio Analytics",
                description: "Performance metrics and trends",
                icon: "chart.line.uptrend.xyaxis",
                category: .analytics,
                priority: .high
            ),
            AIFeature(
                id: "resource-optimization",
                title: "Resource Optimization", 
                description: "Worker allocation and scheduling",
                icon: "person.3.sequence",
                category: .optimization,
                priority: .high
            ),
            AIFeature(
                id: "predictive-maintenance",
                title: "Predictive Maintenance",
                description: "Anticipate equipment failures",
                icon: "crystal.ball",
                category: .predictive,
                priority: .medium
            ),
            AIFeature(
                id: "cost-analysis",
                title: "Cost Analysis",
                description: "Budget tracking and projections",
                icon: "dollarsign.circle",
                category: .financial,
                priority: .medium
            ),
            AIFeature(
                id: "compliance-monitoring",
                title: "Compliance Monitoring",
                description: "Regulatory requirements and deadlines",
                icon: "checkmark.shield",
                category: .compliance,
                priority: .high
            )
        ]
    }
    
    // MARK: - Supervisor AI Features
    
    private func getSupervisorFeatures(context: AIContext) -> [AIFeature] {
        [
            AIFeature(
                id: "team-coordination",
                title: "Team Coordination",
                description: "Worker assignments and communication",
                icon: "person.3",
                category: .teamManagement,
                priority: .high
            ),
            AIFeature(
                id: "quality-control",
                title: "Quality Control",
                description: "Task verification and standards",
                icon: "checkmark.seal",
                category: .qualityAssurance,
                priority: .high
            ),
            AIFeature(
                id: "training-guidance",
                title: "Training Guidance",
                description: "Skill development and certification",
                icon: "graduationcap",
                category: .training,
                priority: .medium
            ),
            AIFeature(
                id: "issue-escalation",
                title: "Issue Escalation",
                description: "Problem resolution pathways",
                icon: "exclamationmark.triangle",
                category: .problemSolving,
                priority: .high
            )
        ]
    }
    
    // MARK: - Client AI Features
    
    private func getClientFeatures(context: AIContext) -> [AIFeature] {
        [
            AIFeature(
                id: "service-reports",
                title: "Service Reports",
                description: "Detailed maintenance summaries",
                icon: "doc.text",
                category: .reporting,
                priority: .high
            ),
            AIFeature(
                id: "building-status",
                title: "Building Status",
                description: "Real-time system monitoring",
                icon: "building.columns",
                category: .monitoring,
                priority: .high
            ),
            AIFeature(
                id: "service-requests",
                title: "Service Requests",
                description: "Submit and track maintenance requests",
                icon: "plus.message",
                category: .serviceManagement,
                priority: .medium
            ),
            AIFeature(
                id: "performance-dashboard",
                title: "Performance Dashboard",
                description: "Key metrics and satisfaction scores",
                icon: "speedometer",
                category: .performance,
                priority: .medium
            )
        ]
    }
    
    // MARK: - AI Suggestions Generation
    
    private func generateSuggestions() {
        guard let context = currentContext else { return }
        
        var suggestions: [AISuggestion] = []
        
        switch context.userRole {
        case .worker:
            suggestions = generateWorkerSuggestions(context: context)
        case .admin:
            suggestions = generateAdminSuggestions(context: context)
        case .supervisor:
            suggestions = generateSupervisorSuggestions(context: context)
        case .client:
            suggestions = generateClientSuggestions(context: context)
        }
        
        suggestedActions = suggestions.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    private func generateWorkerSuggestions(context: AIContext) -> [AISuggestion] {
        var suggestions: [AISuggestion] = []
        
        // Urgent task suggestions
        if !context.urgentTasks.isEmpty {
            suggestions.append(
                AISuggestion(
                    id: "urgent-tasks",
                    title: "Urgent Tasks Require Attention",
                    description: "You have \(context.urgentTasks.count) urgent task(s) pending",
                    action: "Review urgent tasks",
                    priority: .critical,
                    category: .taskManagement
                )
            )
        }
        
        // Weather-based suggestions
        if let weather = context.weatherConditions, weather.requiresIndoorWork {
            suggestions.append(
                AISuggestion(
                    id: "weather-alert",
                    title: "Weather Advisory",
                    description: "Consider rescheduling outdoor work due to \(weather.description)",
                    action: "View indoor alternatives",
                    priority: .high,
                    category: .weatherAdaptive
                )
            )
        }
        
        // Building-specific suggestions
        if let building = context.currentBuilding {
            suggestions.append(
                AISuggestion(
                    id: "building-checklist",
                    title: "Building Arrival Checklist",
                    description: "Review \(building.name) systems and recent alerts",
                    action: "Open building overview",
                    priority: .medium,
                    category: .buildingSpecific
                )
            )
        }
        
        return suggestions
    }
    
    private func generateAdminSuggestions(context: AIContext) -> [AISuggestion] {
        [
            AISuggestion(
                id: "performance-review",
                title: "Weekly Performance Review",
                description: "Analyze portfolio efficiency and worker productivity",
                action: "Generate report",
                priority: .high,
                category: .analytics
            ),
            AISuggestion(
                id: "budget-optimization",
                title: "Budget Optimization",
                description: "Identify cost-saving opportunities",
                action: "View recommendations",
                priority: .medium,
                category: .financial
            )
        ]
    }
    
    private func generateSupervisorSuggestions(context: AIContext) -> [AISuggestion] {
        [
            AISuggestion(
                id: "team-check-in",
                title: "Team Check-in",
                description: "Review worker status and task progress",
                action: "View team dashboard",
                priority: .high,
                category: .teamManagement
            )
        ]
    }
    
    private func generateClientSuggestions(context: AIContext) -> [AISuggestion] {
        [
            AISuggestion(
                id: "service-summary",
                title: "Service Summary",
                description: "Review this week's maintenance activities",
                action: "View report",
                priority: .medium,
                category: .reporting
            )
        ]
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentActiveTask() -> ContextualTask? {
        return contextAdapter.todaysTasks.first { !$0.isCompleted }
    }
    
    private func getUrgentTasks() -> [ContextualTask] {
        return contextAdapter.todaysTasks.filter { 
            $0.urgency == .urgent || $0.urgency == .critical 
        }
    }
    
    private func getTimeOfDay() -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<20: return .evening
        default: return .night
        }
    }
    
    private func getCurrentWeather() -> WeatherConditions? {
        // This would integrate with weather service
        return nil
    }
}

// MARK: - Supporting Types

struct AIContext {
    let userRole: UserRole
    let currentBuilding: NamedCoordinate?
    let activeTask: ContextualTask?
    let assignedBuildings: [NamedCoordinate]
    let portfolioBuildings: [NamedCoordinate]
    let urgentTasks: [ContextualTask]
    let timeOfDay: TimeOfDay
    let weatherConditions: WeatherConditions?
}

struct AIFeature: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AIFeatureCategory
    let priority: AIPriority
}

struct AISuggestion: Identifiable {
    let id: String
    let title: String
    let description: String
    let action: String
    let priority: AIPriority
    let category: AIFeatureCategory
}

enum AIFeatureCategory {
    case fieldAssistance, safety, information, taskSpecific, buildingSpecific
    case weatherAdaptive, analytics, optimization, predictive, financial
    case compliance, teamManagement, qualityAssurance, training, problemSolving
    case reporting, monitoring, serviceManagement, performance, taskManagement
}

enum AIPriority: Int, CaseIterable {
    case critical = 4
    case high = 3
    case medium = 2
    case low = 1
}

enum TimeOfDay {
    case morning, afternoon, evening, night
}

struct WeatherConditions {
    let description: String
    let requiresIndoorWork: Bool
    let temperature: Double
    let precipitation: Bool
}

// MARK: - Usage Examples

/*
🎯 CONTEXTUAL AI EXAMPLES:

👷 WORKER (Kevin at Rubin Museum with HVAC task):
"Nova, the HVAC system in the east wing is making noise"
→ AI provides: Rubin Museum HVAC troubleshooting guide, safety protocols for museum environment, contact for specialized HVAC vendor

👔 ADMIN (Shawn reviewing portfolio):
"Nova, show me this week's efficiency metrics"
→ AI provides: Portfolio analytics, cost per building, worker productivity scores, maintenance budget analysis

👨‍💼 SUPERVISOR (coordinating team):
"Nova, where should I assign the new maintenance request?"
→ AI provides: Worker availability, skill matching, location optimization, workload balancing

🏢 CLIENT (building owner):
"Nova, what's the status of my building maintenance?"
→ AI provides: Service completion rates, recent activities, upcoming scheduled maintenance, compliance status

🌧️ WEATHER-AWARE:
Worker: "Nova, it's raining - what should I prioritize?"
→ AI provides: Indoor task list, weather-safe alternatives, schedule adjustments

🚨 EMERGENCY-AWARE:
Worker: "Nova, I found a water leak in the basement"
→ AI provides: Emergency shutdown procedures, vendor contacts, escalation protocols, safety guidelines
*/