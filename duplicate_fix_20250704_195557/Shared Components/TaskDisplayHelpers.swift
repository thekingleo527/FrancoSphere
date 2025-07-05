//
//  TaskDisplayHelpers.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/17/25.
//


//
//  TaskDisplayHelpers.swift
//  FrancoSphere
//
//  ✅ PATCH P2-09-V2: Real data display helpers for Phase-2
//  ✅ Worker-specific time formatting and status colors
//  ✅ Enhanced progress calculation with real-world validation
//  ✅ Current active worker roster display helpers
//  ✅ Optimized for real FrancoSphere operations data
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


/// Display helpers optimized for real-world FrancoSphere operations data
struct TaskDisplayHelpers {
    
    // MARK: - ✅ PHASE-2: Real-World Time Formatting
    
    /// Format time string for mobile display with worker-specific preferences
    static func formatTimeString(_ timeString: String?) -> String {
        guard let timeString = timeString else { return "Time TBD" }
        
        // Handle HH:mm format from CSV data
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return timeString
        }
        
        // Format for mobile display (12-hour format)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        let calendar = Calendar.current
        if let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) {
            return formatter.string(from: date)
        }
        
        return timeString
    }
    
    /// Format time range with worker-specific display preferences
    static func formatWorkerSpecificTimeRange(_ startTime: String?, _ endTime: String?, workerId: String) -> String {
        let start = formatTimeString(startTime)
        let end = formatTimeString(endTime)
        
        // Worker-specific time display preferences based on real schedules
        switch workerId {
        case "5": // Mercedes - show split shift clearly
            if start != "Time TBD" && end != "Time TBD" {
                return "🌅 \(start) - \(end) (Split Shift)"
            }
        case "7": // Angel - indicate evening component for garbage duties
            if start != "Time TBD" && end != "Time TBD" {
                return "☀️ \(start) - \(end) (+Evening Garbage)"
            }
        case "8": // Shawn - flexible indicator for Rubin Museum work
            return "📅 Flexible Schedule"
        case "4": // Kevin - expanded duties indicator
            if start != "Time TBD" && end != "Time TBD" {
                return "⚡ \(start) - \(end) (Expanded Coverage)"
            }
        default:
            break
        }
        
        // Standard formatting
        if start != "Time TBD" && end != "Time TBD" {
            return "\(start) - \(end)"
        } else if start != "Time TBD" {
            return "Starts \(start)"
        }
        return "Time TBD"
    }
    
    // MARK: - ✅ PHASE-2: Worker-Specific Status Colors
    
    /// Get task status color optimized for mobile visibility
    static func getTaskStatusColor(_ task: ContextualTask) -> Color {
        switch task.status {
        case "completed":
            return .green
        case "in_progress":
            return .blue
        case "overdue":
            return .red
        case "assigned":
            return .orange
        case "pending":
            return .yellow
        default:
            return .gray
        }
    }
    
    /// Get urgency color with worker-specific emphasis
    static func getWorkerSpecificUrgencyColor(_ urgency: String, workerId: String) -> Color {
        let baseColor = getUrgencyColor(urgency)
        
        // Worker-specific urgency emphasis based on real responsibilities
        switch workerId {
        case "4": // Kevin - handling expanded duties, emphasize high urgency
            return urgency.lowercased() == "high" ? .red : baseColor
        case "2": // Edwin - early shift, emphasize morning urgency
            return urgency.lowercased() == "high" ? .orange : baseColor
        case "5": // Mercedes - split shift, time-critical work
            return urgency.lowercased() == "high" ? .red : baseColor
        default:
            return baseColor
        }
    }
    
    /// Standard urgency color mapping
    static func getUrgencyColor(_ urgency: String) -> Color {
        switch urgency.lowercased() {
        case "urgent", "high":
            return .red
        case "medium":
            return .orange
        case "low":
            return .green
        default:
            return .gray
        }
    }
    
    // MARK: - ✅ PHASE-2: Real-World Progress Calculation
    
    /// Calculate worker progress with real-world validation and expectations
    static func calculateWorkerProgress(completed: Int, total: Int, workerId: String) -> (percentage: Double, text: String, status: String) {
        guard total > 0 else { return (0.0, "No tasks", "idle") }
        
        let percentage = Double(completed) / Double(total)
        let text = "\(completed)/\(total)"
        
        // Worker-specific progress evaluation based on real schedules
        var status = "on_track"
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        switch workerId {
        case "5": // Mercedes - 4-hour window (6:30-10:30), progress should be faster
            if currentHour > 8 && percentage < 0.5 {
                status = "behind"
            } else if percentage >= 0.8 {
                status = "ahead"
            }
            
        case "2": // Edwin - early start (6:00), should have good morning progress
            if currentHour > 10 && percentage < 0.4 {
                status = "behind"
            } else if percentage >= 0.7 {
                status = "ahead"
            }
            
        case "4": // Kevin - expanded duties, realistic expectations
            if percentage >= 0.7 {
                status = "excellent"
            } else if percentage < 0.3 && currentHour > 12 {
                status = "behind"
            }
            
        case "7": // Angel - day + evening duties, different expectations
            if percentage >= 0.6 && currentHour < 17 {
                status = "ahead" // Good progress before evening duties
            } else if percentage < 0.2 && currentHour > 14 {
                status = "behind"
            }
            
        case "8": // Shawn - flexible schedule, focus on completion over speed
            if percentage >= 0.8 {
                status = "excellent"
            } else if total > 0 {
                status = "on_track" // Flexible schedule, less time pressure
            }
            
        default: // Standard evaluation for other workers
            if percentage >= 0.8 {
                status = "ahead"
            } else if percentage < 0.3 && currentHour > 14 {
                status = "behind"
            }
        }
        
        return (percentage, text, status)
    }
    
    /// Get progress status display color
    static func getProgressStatusColor(_ status: String) -> Color {
        switch status {
        case "excellent", "ahead":
            return .green
        case "on_track":
            return .blue
        case "behind":
            return .orange
        case "idle":
            return .gray
        default:
            return .blue
        }
    }
    
    // MARK: - ✅ PHASE-2: Current Active Worker Display (Jose Removed)
    
    /// Format worker initials for current active roster
    static func formatWorkerInitials(_ name: String) -> String {
        // Handle real worker names from current active roster
        switch name {
        case "Greg Hutson": return "GH"
        case "Edwin Lema": return "EL"
        case "Kevin Dutan": return "KD"
        case "Mercedes Inamagua": return "MI"
        case "Luis Lopez": return "LL"
        case "Angel Guirachocha": return "AG"
        case "Shawn Magloire": return "SM"
        default:
            // Fallback for any other names
            let components = name.split(separator: " ")
            if components.count >= 2 {
                let first = String(components[0].prefix(1))
                let last = String(components[1].prefix(1))
                return "\(first)\(last)".uppercased()
            } else {
                return String(components.first?.prefix(2) ?? "??").uppercased()
            }
        }
    }
    
    /// Get worker role emoji based on real responsibilities
    static func getWorkerRoleEmoji(_ workerId: String) -> String {
        switch workerId {
        case "1": return "🔧" // Greg - maintenance specialist
        case "2": return "🌅" // Edwin - early morning operations
        case "4": return "⚡" // Kevin - HVAC/electrical + expanded duties
        case "5": return "✨" // Mercedes - glass cleaning specialist
        case "6": return "🔨" // Luis - general maintenance
        case "7": return "🗑️" // Angel - garbage/waste management
        case "8": return "🎨" // Shawn - Rubin Museum specialist
        default: return "👷" // Generic worker
        }
    }
    
    /// Get worker specialization text
    static func getWorkerSpecialization(_ workerId: String) -> String {
        switch workerId {
        case "1": return "Maintenance (Reduced Hours)"
        case "2": return "Early Morning Operations"
        case "4": return "HVAC/Electrical + Expanded Coverage"
        case "5": return "Glass Cleaning Specialist"
        case "6": return "General Maintenance"
        case "7": return "Sanitation + Evening Security"
        case "8": return "Rubin Museum + Administration"
        default: return "General Worker"
        }
    }
    
    // MARK: - ✅ PHASE-2: Building Display Helpers
    
    /// Format building name for mobile display
    static func formatBuildingName(_ name: String, maxLength: Int = 25) -> String {
        if name.count <= maxLength {
            return name
        }
        
        // Smart truncation for building addresses
        if name.contains("Street") {
            let components = name.components(separatedBy: " ")
            if components.count > 2 {
                return "\(components[0]) \(components[1])..."
            }
        }
        
        return String(name.prefix(maxLength - 3)) + "..."
    }
    
    /// Get building type icon
    static func getBuildingTypeIcon(_ buildingId: String) -> String {
        switch buildingId {
        case "14": return "🎨" // Rubin Museum
        case "17": return "🌳" // Stuyvesant Cove Park
        default: return "🏢" // Standard building
        }
    }
    
    // MARK: - ✅ PHASE-2: Task Category Display
    
    /// Get task category icon with real-world context
    static func getTaskCategoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case let cat where cat.contains("clean"):
            return "sparkles"
        case let cat where cat.contains("maintenance"):
            return "wrench.and.screwdriver"
        case let cat where cat.contains("hvac"):
            return "wind"
        case let cat where cat.contains("electric"):
            return "bolt"
        case let cat where cat.contains("plumb"):
            return "drop"
        case let cat where cat.contains("garbage"), let cat where cat.contains("waste"):
            return "trash"
        case let cat where cat.contains("glass"):
            return "sparkles"
        case let cat where cat.contains("security"):
            return "shield"
        case let cat where cat.contains("boiler"):
            return "flame"
        default:
            return "checkmark.circle"
        }
    }
    
    /// Get task category color
    static func getTaskCategoryColor(_ category: String) -> Color {
        switch category.lowercased() {
        case let cat where cat.contains("clean"):
            return .cyan
        case let cat where cat.contains("maintenance"):
            return .blue
        case let cat where cat.contains("hvac"):
            return .mint
        case let cat where cat.contains("electric"):
            return .yellow
        case let cat where cat.contains("plumb"):
            return .blue
        case let cat where cat.contains("garbage"), let cat where cat.contains("waste"):
            return .brown
        case let cat where cat.contains("glass"):
            return .cyan
        case let cat where cat.contains("security"):
            return .red
        case let cat where cat.contains("boiler"):
            return .orange
        default:
            return .gray
        }
    }
    
    // MARK: - ✅ PHASE-2: Time-Based Display Logic
    
    /// Check if task should be highlighted based on current time and worker schedule
    static func shouldHighlightTask(_ task: ContextualTask, workerId: String, currentTime: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: currentTime)
        
        // Worker-specific highlighting logic
        switch workerId {
        case "5": // Mercedes - highlight tasks in split shift window
            guard let startTime = task.startTime,
                  let taskHour = parseHour(from: startTime) else { return false }
            return taskHour >= 6 && taskHour <= 10
            
        case "2": // Edwin - highlight morning tasks
            guard let startTime = task.startTime,
                  let taskHour = parseHour(from: startTime) else { return false }
            return taskHour >= 6 && taskHour <= 11 && currentHour <= 12
            
        case "7": // Angel - highlight evening garbage tasks
            if task.category.lowercased().contains("garbage") && currentHour >= 16 {
                return true
            }
            
        case "8": // Shawn - highlight Rubin Museum tasks
            return task.buildingId == "14"
            
        default:
            break
        }
        
        // General highlighting logic
        guard let startTime = task.startTime,
              let taskHour = parseHour(from: startTime) else { return false }
        
        // Highlight if task is within 1 hour
        return abs(taskHour - currentHour) <= 1
    }
    
    /// Parse hour from time string
    private static func parseHour(from timeString: String) -> Int? {
        let components = timeString.split(separator: ":")
        guard let hourString = components.first,
              let hour = Int(hourString) else { return nil }
        return hour
    }
    
    // MARK: - ✅ PHASE-2: Real-World Validation Helpers
    
    /// Validate worker assignment against Phase-2 requirements
    static func validateWorkerAssignment(workerId: String, buildingCount: Int) -> (isValid: Bool, message: String) {
        switch workerId {
        case "4": // Kevin - should have 6+ buildings (expanded duties)
            if buildingCount >= 6 {
                return (true, "✅ Kevin's expanded duties confirmed (\(buildingCount) buildings)")
            } else {
                return (false, "⚠️ Kevin should have 6+ buildings, found \(buildingCount)")
            }
            
        case "5": // Mercedes - split shift, fewer buildings expected
            if buildingCount >= 1 {
                return (true, "✅ Mercedes assignments confirmed (\(buildingCount) buildings)")
            } else {
                return (false, "⚠️ Mercedes should have building assignments")
            }
            
        case "8": // Shawn - Rubin Museum specialist
            if buildingCount >= 1 {
                return (true, "✅ Shawn's assignments confirmed (\(buildingCount) buildings)")
            } else {
                return (false, "⚠️ Shawn should have building assignments")
            }
            
        default:
            if buildingCount > 0 {
                return (true, "✅ Worker assignments confirmed (\(buildingCount) buildings)")
            } else {
                return (false, "⚠️ Worker should have building assignments")
            }
        }
    }
    
    /// Get Phase-2 compliance status
    static func getPhase2ComplianceStatus(
        totalWorkers: Int,
        josePresent: Bool,
        kevinBuildingCount: Int
    ) -> (isCompliant: Bool, issues: [String]) {
        var issues: [String] = []
        
        // Check worker count (should be 7 active workers)
        if totalWorkers != 7 {
            issues.append("Expected 7 active workers, found \(totalWorkers)")
        }
        
        // Check Jose removal
        if josePresent {
            issues.append("Jose Santos still present - should be removed")
        }
        
        // Check Kevin expansion
        if kevinBuildingCount < 6 {
            issues.append("Kevin should have 6+ buildings, found \(kevinBuildingCount)")
        }
        
        return (issues.isEmpty, issues)
    }
}

// MARK: - ✅ PHASE-2: Enhanced ContextualTask Extensions

extension ContextualTask {
    /// Get urgency color for this task
    var urgencyDisplayColor: Color {
        TaskDisplayHelpers.getUrgencyColor(urgencyLevel)
    }
    
    /// Get status color for this task
    var statusDisplayColor: Color {
        TaskDisplayHelpers.getTaskStatusColor(self)
    }
    
    /// Get formatted time range for specific worker
    func formattedTimeRange(for workerId: String) -> String {
        TaskDisplayHelpers.formatWorkerSpecificTimeRange(startTime, endTime, workerId: workerId)
    }
    
    /// Get worker-specific urgency color
    func workerSpecificUrgencyColor(for workerId: String) -> Color {
        TaskDisplayHelpers.getWorkerSpecificUrgencyColor(urgencyLevel, workerId: workerId)
    }
    
    /// Get category icon
    var categoryIcon: String {
        TaskDisplayHelpers.getTaskCategoryIcon(category)
    }
    
    /// Get category color
    var categoryColor: Color {
        TaskDisplayHelpers.getTaskCategoryColor(category)
    }
    
    /// Check if task should be highlighted for worker
    func shouldHighlight(for workerId: String) -> Bool {
        TaskDisplayHelpers.shouldHighlightTask(self, workerId: workerId)
    }
}

// MARK: - ✅ PHASE-2: Worker Extensions

extension String {
    /// Check if this worker ID represents an active worker (Jose removed)
    var isActiveWorker: Bool {
        let activeWorkerIds = ["1", "2", "4", "5", "6", "7", "8"]
        return activeWorkerIds.contains(self)
    }
    
    /// Get worker specialization for display
    var workerSpecialization: String {
        TaskDisplayHelpers.getWorkerSpecialization(self)
    }
    
    /// Get worker role emoji
    var workerRoleEmoji: String {
        TaskDisplayHelpers.getWorkerRoleEmoji(self)
    }
}