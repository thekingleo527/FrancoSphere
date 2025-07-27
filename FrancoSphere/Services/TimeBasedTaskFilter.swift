//
//  TimeBasedTaskFilter.swift
//  FrancoSphere
//
//  ✅ FIXED: Corrected Bool comparison (removed .lowercased() from Bool property)
//

import Foundation

public struct TimeBasedTaskFilter {
    
    // Make methods internal instead of public to avoid visibility issues
    static func filterTasksForTimeframe(_ tasks: [ContextualTask], timeframe: FilterTimeframe) -> [ContextualTask] {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeframe {
        case .today:
            return tasks.filter { task in
                calendar.isDate(task.scheduledDate ?? now, inSameDayAs: now)
            }
        case .thisWeek:
            return tasks.filter { task in
                calendar.isDate(task.scheduledDate ?? now, equalTo: now, toGranularity: .weekOfYear)
            }
        case .thisMonth:
            return tasks.filter { task in
                calendar.isDate(task.scheduledDate ?? now, equalTo: now, toGranularity: .month)
            }
        case .overdue:
            return tasks.filter { task in
                guard let dueDate = task.scheduledDate else { return false }
                // ✅ FIXED: isCompleted is a Bool, not a String
                return dueDate < now && !task.isCompleted
            }
        }
    }
    
    public static func formatTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    // Make internal to avoid visibility issues
    static func timeUntilTask(_ task: ContextualTask) -> String {
        guard let scheduledDate = task.scheduledDate else { return "No time set" }
        
        let timeInterval = scheduledDate.timeIntervalSinceNow
        if timeInterval < 0 {
            return "Overdue"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

public enum FilterTimeframe: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case overdue = "Overdue"
}
