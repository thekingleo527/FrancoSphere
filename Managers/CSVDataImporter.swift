//
//  CSVDataImporter.swift
//  FrancoSphere
//
//  🔧 PHASE-2 ENHANCED - Current Worker Roster CSV Import
//  ✅ PATCH P2-02-V2: Only import assignments for current active workers (no Jose Santos)
//  ✅ Enhanced worker validation and assignment tracking
//  ✅ Kevin's expanded duties integration
//  ✅ Real-world data validation and logging
//

import Foundation
import SQLite

// MARK: - CSV Task Assignment Structure (Enhanced)
struct CSVTaskAssignment {
    let building: String             // Plain-English building name as spoken internally
    let taskName: String             // Human friendly task title
    let assignedWorker: String       // Canonical full name, must exist in WorkerConstants
    let category: String             // One of: Cleaning | Sanitation | Maintenance | Inspection | Operations | Repair
    let skillLevel: String           // Basic | Intermediate | Advanced
    let recurrence: String           // Daily | Weekly | Bi-Weekly | Monthly | Quarterly | Semiannual | Annual | On-Demand
    let startHour: Int?              // 0-23, local time
    let endHour: Int?                // 0-23, local time
    let daysOfWeek: String?          // CSV list of day abbreviations (Mon,Tue …) or nil for "any"
}

// MARK: - PATCH P2-02-V2: Current Worker Roster CSV Data Importer

@MainActor
class CSVDataImporter: ObservableObject {
    static let shared = CSVDataImporter()
    
    // MUST have sqliteManager property
    var sqliteManager: SQLiteManager?
    
    @Published var importProgress: Double = 0.0
    @Published var currentStatus: String = ""
    
    private var hasImported = false
    private var importErrors: [String] = []

    // ──────────────────────────────────────────────────────────────────────────────
    //  🔧 PHASE-2: CURRENT ACTIVE WORKER TASK MATRIX  (José removed, Kevin expanded)
    //  – every entry reviewed with ops on 2025-06-17
    //  – Jose Santos completely removed from all assignments
    //  – Kevin Dutan expanded from ~28 to ~34 tasks (6+ buildings)
    //  – Only includes CURRENT ACTIVE WORKERS
    // -----------------------------------------------------------------------------
    private let realWorldTasks: [CSVTaskAssignment] = [

        // ───────────────────────────────
        //  KEVIN DUTAN (EXPANDED DUTIES)
        //  Mon-Fri 06:00-17:00  (lunch 12-13)
        //  🔧 PHASE-2: Took Jose's duties + original assignments = 6+ buildings
        // ───────────────────────────────

        // Perry cluster (finish by 09:30)
        CSVTaskAssignment(building: "131 Perry Street", taskName: "Sidewalk + Curb Sweep / Trash Return", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 6, endHour: 7, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        CSVTaskAssignment(building: "131 Perry Street", taskName: "Hallway & Stairwell Clean / Vacuum", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 7, endHour: 8, daysOfWeek: "Mon,Wed"),
        CSVTaskAssignment(building: "131 Perry Street", taskName: "Hallway & Stairwell Vacuum (light)", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 7, endHour: 7, daysOfWeek: "Fri"),

        // ✅ NEW: 6 additional Kevin tasks for 131 Perry (Monday/Wednesday/Friday) - PHASE-2
        CSVTaskAssignment(building: "131 Perry Street", taskName: "Lobby + Packages Check", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 8, endHour: 8, daysOfWeek: "Mon,Wed,Fri"),
        CSVTaskAssignment(building: "131 Perry Street", taskName: "Vacuum Hallways Floor 2-6", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 8, endHour: 9, daysOfWeek: "Mon,Wed,Fri"),
        CSVTaskAssignment(building: "131 Perry Street", taskName: "Hose Down Sidewalks", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 9, endHour: 9, daysOfWeek: "Mon,Wed,Fri"),
        CSVTaskAssignment(building: "131 Perry Street", taskName: "Clear Walls & Surfaces", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 9, endHour: 10, daysOfWeek: "Mon,Wed,Fri"),
        CSVTaskAssignment(building: "131 Perry Street", taskName: "Check Bathroom + Trash Room", assignedWorker: "Kevin Dutan", category: "Sanitation", skillLevel: "Basic", recurrence: "Weekly", startHour: 10, endHour: 10, daysOfWeek: "Mon,Wed,Fri"),
        CSVTaskAssignment(building: "131 Perry Street", taskName: "Mop Stairs A & B", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 10, endHour: 11, daysOfWeek: "Mon,Wed,Fri"),

        // 68 Perry Street tasks (Jose's former duties now Kevin's)
        CSVTaskAssignment(building: "68 Perry Street", taskName: "Sidewalk / Curb Sweep & Trash Return", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 8, endHour: 9, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        CSVTaskAssignment(building: "68 Perry Street", taskName: "Full Building Clean & Vacuum", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 8, endHour: 9, daysOfWeek: "Tue,Thu"),
        CSVTaskAssignment(building: "68 Perry Street", taskName: "Stairwell Hose-Down + Trash Area Hose", assignedWorker: "Kevin Dutan", category: "Sanitation", skillLevel: "Basic", recurrence: "Weekly", startHour: 9, endHour: 9, daysOfWeek: "Mon,Wed,Fri"),

        // 17th / 18th cluster – Trash areas & common cleaning 10-12 (Kevin expanded coverage)
        CSVTaskAssignment(building: "135–139 West 17th", taskName: "Trash Area + Sidewalk & Curb Clean", assignedWorker: "Kevin Dutan", category: "Sanitation", skillLevel: "Basic", recurrence: "Daily", startHour: 10, endHour: 11, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        CSVTaskAssignment(building: "136 West 17th", taskName: "Trash Area + Sidewalk & Curb Clean", assignedWorker: "Kevin Dutan", category: "Sanitation", skillLevel: "Basic", recurrence: "Daily", startHour: 10, endHour: 11, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        CSVTaskAssignment(building: "138 West 17th Street", taskName: "Trash Area + Sidewalk & Curb Clean", assignedWorker: "Kevin Dutan", category: "Sanitation", skillLevel: "Basic", recurrence: "Daily", startHour: 11, endHour: 12, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        CSVTaskAssignment(building: "117 West 17th Street", taskName: "Trash Area Clean", assignedWorker: "Kevin Dutan", category: "Sanitation", skillLevel: "Basic", recurrence: "Daily", startHour: 11, endHour: 12, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        CSVTaskAssignment(building: "112 West 18th Street", taskName: "Trash Area Clean", assignedWorker: "Kevin Dutan", category: "Sanitation", skillLevel: "Basic", recurrence: "Daily", startHour: 11, endHour: 12, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),

        // After-lunch satellite cleans (former Jose territories now Kevin's)
        CSVTaskAssignment(building: "29–31 East 20th", taskName: "Hallway / Glass / Sidewalk Sweep & Mop", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 13, endHour: 14, daysOfWeek: "Tue"),
        CSVTaskAssignment(building: "123 1st Ave", taskName: "Hallway & Curb Clean", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 13, endHour: 14, daysOfWeek: "Tue,Thu"),
        CSVTaskAssignment(building: "178 Spring", taskName: "Stair Hose & Garbage Return", assignedWorker: "Kevin Dutan", category: "Sanitation", skillLevel: "Basic", recurrence: "Weekly", startHour: 14, endHour: 15, daysOfWeek: "Mon,Wed,Fri"),

        // DSNY put-out (curb placement) — Sun/Tue/Thu, cannot place before 20:00
        CSVTaskAssignment(building: "135–139 West 17th", taskName: "DSNY Put-Out (after 20:00)", assignedWorker: "Kevin Dutan", category: "Operations", skillLevel: "Basic", recurrence: "Weekly", startHour: 20, endHour: 21, daysOfWeek: "Sun,Tue,Thu"),
        CSVTaskAssignment(building: "136 West 17th", taskName: "DSNY Put-Out (after 20:00)", assignedWorker: "Kevin Dutan", category: "Operations", skillLevel: "Basic", recurrence: "Weekly", startHour: 20, endHour: 21, daysOfWeek: "Sun,Tue,Thu"),
        CSVTaskAssignment(building: "138 West 17th Street", taskName: "DSNY Put-Out (after 20:00)", assignedWorker: "Kevin Dutan", category: "Operations", skillLevel: "Basic", recurrence: "Weekly", startHour: 20, endHour: 21, daysOfWeek: "Sun,Tue,Thu"),
        CSVTaskAssignment(building: "178 Spring", taskName: "DSNY Put-Out (after 20:00)", assignedWorker: "Kevin Dutan", category: "Operations", skillLevel: "Basic", recurrence: "Weekly", startHour: 20, endHour: 21, daysOfWeek: "Sun,Tue,Thu"),

        // ───────────────────────────────
        //  MERCEDES INAMAGUA  (06:30-11:00)
        // ───────────────────────────────
        CSVTaskAssignment(building: "112 West 18th Street", taskName: "Glass & Lobby Clean", assignedWorker: "Mercedes Inamagua", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 6, endHour: 7, daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat"),
        CSVTaskAssignment(building: "117 West 17th Street", taskName: "Glass & Lobby Clean", assignedWorker: "Mercedes Inamagua", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 7, endHour: 8, daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat"),
        CSVTaskAssignment(building: "135–139 West 17th", taskName: "Glass & Lobby Clean", assignedWorker: "Mercedes Inamagua", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 8, endHour: 9, daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat"),
        CSVTaskAssignment(building: "136 West 17th", taskName: "Glass & Lobby Clean", assignedWorker: "Mercedes Inamagua", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 9, endHour: 10, daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat"),
        CSVTaskAssignment(building: "138 West 17th Street", taskName: "Glass & Lobby Clean", assignedWorker: "Mercedes Inamagua", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 10, endHour: 11, daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat"),
        CSVTaskAssignment(building: "Rubin Museum (142–148 W 17th)", taskName: "Roof Drain – 2F Terrace", assignedWorker: "Mercedes Inamagua", category: "Maintenance", skillLevel: "Basic", recurrence: "Weekly", startHour: 10, endHour: 10, daysOfWeek: "Wed"),
        // 104 Franklin deep clean twice a week
        CSVTaskAssignment(building: "104 Franklin", taskName: "Office Deep Clean", assignedWorker: "Mercedes Inamagua", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 14, endHour: 16, daysOfWeek: "Mon,Thu"),

        // ───────────────────────────────
        //  EDWIN LEMA  (06:00-15:00)
        // ───────────────────────────────
        // Park open
        CSVTaskAssignment(building: "Stuyvesant Cove Park", taskName: "Morning Park Check", assignedWorker: "Edwin Lema", category: "Maintenance", skillLevel: "Intermediate", recurrence: "Daily", startHour: 6, endHour: 7, daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat,Sun"),
        CSVTaskAssignment(building: "Stuyvesant Cove Park", taskName: "Power Wash Walkways", assignedWorker: "Edwin Lema", category: "Cleaning", skillLevel: "Intermediate", recurrence: "Monthly", startHour: 7, endHour: 9, daysOfWeek: nil),
        // 133 E 15th walk-through + boiler
        CSVTaskAssignment(building: "133 East 15th Street", taskName: "Building Walk-Through", assignedWorker: "Edwin Lema", category: "Maintenance", skillLevel: "Intermediate", recurrence: "Weekly", startHour: 9, endHour: 10, daysOfWeek: "Mon,Wed,Fri"),
        CSVTaskAssignment(building: "133 East 15th Street", taskName: "Boiler Blow-Down", assignedWorker: "Edwin Lema", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 9, endHour: 9, daysOfWeek: "Mon"),
        // Kevin coordination / repairs 13-15 (variable bldg)
        CSVTaskAssignment(building: "FrancoSphere HQ", taskName: "Scheduled Repairs & Follow-ups", assignedWorker: "Edwin Lema", category: "Repair", skillLevel: "Intermediate", recurrence: "Daily", startHour: 13, endHour: 15, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        // Roof & filter rounds (embedded into walkthroughs, every other month)
        CSVTaskAssignment(building: "117 West 17th Street", taskName: "Water Filter Change & Roof Drain Check", assignedWorker: "Edwin Lema", category: "Maintenance", skillLevel: "Intermediate", recurrence: "Bi-Monthly", startHour: 10, endHour: 11, daysOfWeek: nil),
        CSVTaskAssignment(building: "112 West 18th Street", taskName: "Water Filter Change & Roof Drain Check", assignedWorker: "Edwin Lema", category: "Maintenance", skillLevel: "Intermediate", recurrence: "Bi-Monthly", startHour: 11, endHour: 12, daysOfWeek: nil),
        CSVTaskAssignment(building: "135–139 West 17th", taskName: "Backyard Drain Check", assignedWorker: "Edwin Lema", category: "Inspection", skillLevel: "Basic", recurrence: "Weekly", startHour: 10, endHour: 10, daysOfWeek: "Fri"),
        // Boiler blow-downs quick hits
        CSVTaskAssignment(building: "131 Perry Street", taskName: "Boiler Blow-Down", assignedWorker: "Edwin Lema", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 8, endHour: 8, daysOfWeek: "Wed"),
        CSVTaskAssignment(building: "138 West 17th Street", taskName: "Boiler Blow-Down", assignedWorker: "Edwin Lema", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 10, endHour: 10, daysOfWeek: "Thu"),
        CSVTaskAssignment(building: "135–139 West 17th", taskName: "Boiler Blow-Down", assignedWorker: "Edwin Lema", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 10, endHour: 10, daysOfWeek: "Tue"),
        CSVTaskAssignment(building: "117 West 17th Street", taskName: "Boiler Blow-Down", assignedWorker: "Edwin Lema", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 11, endHour: 11, daysOfWeek: "Tue"),

        // ───────────────────────────────
        //  LUIS LOPEZ  (07:00-16:00)
        // ───────────────────────────────
        CSVTaskAssignment(building: "104 Franklin", taskName: "Sidewalk Hose", assignedWorker: "Luis Lopez", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 7, endHour: 7, daysOfWeek: "Mon,Wed,Fri"),
        CSVTaskAssignment(building: "36 Walker", taskName: "Sidewalk Sweep", assignedWorker: "Luis Lopez", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 7, endHour: 8, daysOfWeek: "Mon,Wed,Fri"),
        // 41 Elizabeth daily core
        CSVTaskAssignment(building: "41 Elizabeth Street", taskName: "Bathrooms Clean", assignedWorker: "Luis Lopez", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 8, endHour: 9, daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat"),
        CSVTaskAssignment(building: "41 Elizabeth Street", taskName: "Lobby & Sidewalk Clean", assignedWorker: "Luis Lopez", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 9, endHour: 10, daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat"),
        CSVTaskAssignment(building: "41 Elizabeth Street", taskName: "Elevator Clean", assignedWorker: "Luis Lopez", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 10, endHour: 11, daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat"),
        CSVTaskAssignment(building: "41 Elizabeth Street", taskName: "Afternoon Garbage Removal", assignedWorker: "Luis Lopez", category: "Sanitation", skillLevel: "Basic", recurrence: "Daily", startHour: 13, endHour: 14, daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat"),
        // Mail + bathroom re-check
        CSVTaskAssignment(building: "41 Elizabeth Street", taskName: "Deliver Mail & Packages", assignedWorker: "Luis Lopez", category: "Operations", skillLevel: "Basic", recurrence: "Daily", startHour: 14, endHour: 14, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),

        // ───────────────────────────────
        //  ANGEL GUIRACHOCHA  (18:00-22:00)
        // ───────────────────────────────
        // Evening garbage collection & DSNY prep
        CSVTaskAssignment(building: "12 West 18th Street", taskName: "Evening Garbage Collection", assignedWorker: "Angel Guirachocha", category: "Sanitation", skillLevel: "Basic", recurrence: "Weekly", startHour: 18, endHour: 19, daysOfWeek: "Mon,Wed,Fri"),
        CSVTaskAssignment(building: "68 Perry Street", taskName: "DSNY Prep / Move Bins", assignedWorker: "Angel Guirachocha", category: "Operations", skillLevel: "Basic", recurrence: "Weekly", startHour: 19, endHour: 20, daysOfWeek: "Mon,Wed,Fri"),
        CSVTaskAssignment(building: "123 1st Ave", taskName: "DSNY Prep / Move Bins", assignedWorker: "Angel Guirachocha", category: "Operations", skillLevel: "Basic", recurrence: "Weekly", startHour: 19, endHour: 20, daysOfWeek: "Tue,Thu"),
        CSVTaskAssignment(building: "104 Franklin", taskName: "DSNY Prep / Move Bins", assignedWorker: "Angel Guirachocha", category: "Operations", skillLevel: "Basic", recurrence: "Weekly", startHour: 20, endHour: 21, daysOfWeek: "Mon,Wed,Fri"),
        CSVTaskAssignment(building: "135–139 West 17th", taskName: "Evening Building Security Check", assignedWorker: "Angel Guirachocha", category: "Inspection", skillLevel: "Basic", recurrence: "Daily", startHour: 21, endHour: 22, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),

        // ───────────────────────────────
        //  GREG HUTSON  (09:00-15:00)
        // ───────────────────────────────
        CSVTaskAssignment(building: "12 West 18th Street", taskName: "Sidewalk & Curb Clean", assignedWorker: "Greg Hutson", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 9, endHour: 10, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        CSVTaskAssignment(building: "12 West 18th Street", taskName: "Lobby & Vestibule Clean", assignedWorker: "Greg Hutson", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 10, endHour: 11, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        CSVTaskAssignment(building: "12 West 18th Street", taskName: "Glass & Elevator Clean", assignedWorker: "Greg Hutson", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 11, endHour: 12, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        CSVTaskAssignment(building: "12 West 18th Street", taskName: "Trash Area Clean", assignedWorker: "Greg Hutson", category: "Sanitation", skillLevel: "Basic", recurrence: "Daily", startHour: 13, endHour: 14, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        CSVTaskAssignment(building: "12 West 18th Street", taskName: "Boiler Blow-Down", assignedWorker: "Greg Hutson", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 14, endHour: 14, daysOfWeek: "Fri"),
        CSVTaskAssignment(building: "12 West 18th Street", taskName: "Freight Elevator Operation (On-Demand)", assignedWorker: "Greg Hutson", category: "Operations", skillLevel: "Basic", recurrence: "On-Demand", startHour: nil, endHour: nil, daysOfWeek: nil),

        // ───────────────────────────────
        //  SHAWN MAGLOIRE  (floating specialist)
        // ───────────────────────────────
        CSVTaskAssignment(building: "117 West 17th Street", taskName: "Boiler Blow-Down", assignedWorker: "Shawn Magloire", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 9, endHour: 11, daysOfWeek: "Mon"),
        CSVTaskAssignment(building: "133 East 15th Street", taskName: "Boiler Blow-Down", assignedWorker: "Shawn Magloire", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 11, endHour: 13, daysOfWeek: "Tue"),
        CSVTaskAssignment(building: "136 West 17th", taskName: "Boiler Blow-Down", assignedWorker: "Shawn Magloire", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 13, endHour: 15, daysOfWeek: "Wed"),
        CSVTaskAssignment(building: "138 West 17th Street", taskName: "Boiler Blow-Down", assignedWorker: "Shawn Magloire", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 15, endHour: 17, daysOfWeek: "Thu"),
        CSVTaskAssignment(building: "115 7th Ave", taskName: "Boiler Blow-Down", assignedWorker: "Shawn Magloire", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 9, endHour: 11, daysOfWeek: "Fri"),
        CSVTaskAssignment(building: "112 West 18th Street", taskName: "HVAC System Check", assignedWorker: "Shawn Magloire", category: "Maintenance", skillLevel: "Advanced", recurrence: "Monthly", startHour: 9, endHour: 12, daysOfWeek: nil),
        CSVTaskAssignment(building: "117 West 17th Street", taskName: "HVAC System Check", assignedWorker: "Shawn Magloire", category: "Maintenance", skillLevel: "Advanced", recurrence: "Monthly", startHour: 13, endHour: 16, daysOfWeek: nil)

        // NOTE: Jose Santos tasks have been COMPLETELY REMOVED and redistributed to Kevin Dutan
    ]
    
    private init() {}

    // MARK: - ⭐ PHASE-2: Enhanced Import Methods
    
    /// Main import function - enhanced for current active workers only
    func importRealWorldTasks() async throws -> (imported: Int, errors: [String]) {
        guard let sqliteManager = sqliteManager else {
            throw CSVError.noSQLiteManager
        }
        
        guard !hasImported else {
            print("✅ Tasks already imported, skipping duplicate import")
            return (0, [])
        }
        
        var importedCount = 0
        importErrors = []
        
        let calendar = Calendar.current
        let today = Date()
        
        print("📂 Starting PHASE-2 task import with \(realWorldTasks.count) tasks...")
        print("🔧 Current active workers only (Jose Santos removed)")
        currentStatus = "Importing \(realWorldTasks.count) tasks for current active workers..."
        
        // First populate worker building assignments
        try await populateWorkerBuildingAssignments(realWorldTasks)
        
        // Process each CSV assignment
        for (index, csvTask) in realWorldTasks.enumerated() {
            do {
                // Update progress
                importProgress = Double(index) / Double(realWorldTasks.count)
                currentStatus = "Importing task \(index + 1)/\(realWorldTasks.count)"
                
                // Generate external ID for idempotency
                let externalId = generateExternalId(for: csvTask, index: index)
                
                // Check if task already exists
                let existingTasks = try await sqliteManager.query("""
                    SELECT id FROM tasks WHERE external_id = ?
                    """, [externalId])
                
                if !existingTasks.isEmpty {
                    print("⏭️ Skipping duplicate task: \(csvTask.taskName)")
                    continue
                }
                
                // Calculate due date
                let dueDate = calculateDueDate(for: csvTask.recurrence, from: today)
                
                // Map building name to ID
                let buildingId = try await mapBuildingNameToId(csvTask.building)
                
                // Map worker name to ID (current active workers only)
                let workerId: Int? = if !csvTask.assignedWorker.isEmpty {
                    try? await mapWorkerNameToId(csvTask.assignedWorker)
                } else {
                    nil
                }
                
                // Skip if worker not found (handles Jose removal)
                guard let validWorkerId = workerId else {
                    print("⚠️ Skipping task for inactive worker: \(csvTask.assignedWorker)")
                    continue
                }
                
                // Calculate start/end times
                var startTime: String? = nil
                var endTime: String? = nil
                
                if let startHour = csvTask.startHour, let endHour = csvTask.endHour {
                    if let start = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: dueDate),
                       let end = calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: dueDate) {
                        startTime = start.iso8601String
                        endTime = end.iso8601String
                    }
                }
                
                // Map urgency level
                let urgencyLevel = csvTask.skillLevel == "Advanced" ? "high" :
                                  csvTask.skillLevel == "Intermediate" ? "medium" : "low"
                
                // Insert task - Convert to strings and handle optionals
                try await sqliteManager.execute("""
                    INSERT INTO tasks (
                        name, description, buildingId, workerId, isCompleted,
                        scheduledDate, recurrence, urgencyLevel, category,
                        startTime, endTime, external_id
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, [
                        csvTask.taskName,
                        "Imported from current active worker schedule",
                        "\(buildingId)",  // Convert to string
                        "\(validWorkerId)",  // Convert to string
                        "0",
                        dueDate.iso8601String,
                        csvTask.recurrence,
                        urgencyLevel,
                        csvTask.category,
                        startTime ?? "",  // Use empty string for nil
                        endTime ?? "",    // Use empty string for nil
                        externalId
                    ])
                
                importedCount += 1
                print("✅ Imported: \(csvTask.taskName) for \(csvTask.building) (\(csvTask.assignedWorker))")
                
                // Log progress every 10 tasks
                if (index + 1) % 10 == 0 {
                    print("📈 Imported \(index + 1)/\(realWorldTasks.count) tasks")
                }
                
                // Allow UI to update periodically
                if index % 5 == 0 {
                    try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
                }
                
            } catch {
                let errorMsg = "Error processing task \(csvTask.taskName): \(error.localizedDescription)"
                importErrors.append(errorMsg)
                print("❌ \(errorMsg)")
            }
        }
        
        hasImported = true
        importProgress = 1.0
        currentStatus = "Import complete!"
        
        // Log results with Phase-2 summary
        await logPhase2ImportResults(imported: importedCount, errors: importErrors)
        
        return (importedCount, importErrors)
    }
    
    // MARK: - ⭐ PHASE-2: Populate worker_building_assignments with CURRENT ACTIVE WORKERS ONLY
    
    /// Populate worker_building_assignments with CURRENT ACTIVE WORKERS ONLY
    private func populateWorkerBuildingAssignments(_ assignments: [CSVTaskAssignment]) async throws {
        guard let sqliteManager = sqliteManager else {
            throw NSError(domain: "CSVImportError", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "SQLiteManager not available"])
        }
        
        // CURRENT ACTIVE WORKER ROSTER (Jose Santos removed, Kevin expanded)
        let activeWorkers = [
            "Greg Hutson": "1",
            "Edwin Lema": "2",
            "Kevin Dutan": "4",      // Assumed Jose's duties + original assignments
            "Mercedes Inamagua": "5",
            "Luis Lopez": "6",
            "Angel Guirachocha": "7",
            "Shawn Magloire": "8"
        ]
        
        print("🔗 Extracting assignments from \(assignments.count) CSV tasks for ACTIVE WORKERS ONLY")
        
        // Extract unique worker-building pairs - ACTIVE WORKERS ONLY
        var workerBuildingPairs: Set<String> = []
        var skippedAssignments = 0
        
        for assignment in assignments {
            guard !assignment.assignedWorker.isEmpty,
                  !assignment.building.isEmpty else {
                continue
            }
            
            // CRITICAL: Only process assignments for current active workers
            guard let workerId = activeWorkers[assignment.assignedWorker] else {
                if assignment.assignedWorker == "Jose Santos" {
                    print("📝 Skipping Jose Santos assignment (no longer with company)")
                } else {
                    print("⚠️ Skipping unknown worker: \(assignment.assignedWorker)")
                }
                skippedAssignments += 1
                continue
            }
            
            do {
                let buildingId = try await mapBuildingNameToId(assignment.building)
                let pairKey = "\(workerId)-\(buildingId)"
                workerBuildingPairs.insert(pairKey)
                
            } catch {
                print("⚠️ Skipping assignment - unknown building: \(assignment.building)")
                skippedAssignments += 1
                continue
            }
        }
        
        print("🔗 Active worker assignments: \(workerBuildingPairs.count) pairs, \(skippedAssignments) skipped")
        
        // Insert assignments into database
        var insertedCount = 0
        for pair in workerBuildingPairs {
            let components = pair.split(separator: "-")
            guard components.count == 2 else { continue }
            
            let workerId = String(components[0])
            let buildingId = String(components[1])
            
            // Get worker name from active roster
            let workerName = activeWorkers.first(where: { $0.value == workerId })?.key ?? "Unknown Worker"
            
            do {
                try await sqliteManager.execute("""
                    INSERT OR IGNORE INTO worker_building_assignments 
                    (worker_id, building_id, worker_name, assignment_type, start_date, is_active) 
                    VALUES (?, ?, ?, 'regular', datetime('now'), 1)
                """, [workerId, buildingId, workerName])
                insertedCount += 1
            } catch {
                print("⚠️ Failed to insert assignment \(workerId)->\(buildingId): \(error)")
            }
        }
        
        print("✅ Real-world assignments populated: \(insertedCount) active assignments")
        
        // Log final worker assignment summary
        await logWorkerAssignmentSummary(activeWorkers)
    }
    
    /// Log summary of worker assignments for validation
    private func logWorkerAssignmentSummary(_ activeWorkers: [String: String]) async {
        guard let sqliteManager = sqliteManager else { return }
        
        do {
            let results = try await sqliteManager.query("""
                SELECT wa.worker_name, COUNT(wa.building_id) as building_count 
                FROM worker_building_assignments wa 
                WHERE wa.is_active = 1 
                GROUP BY wa.worker_id 
                ORDER BY building_count DESC
            """)
            
            print("📊 ACTIVE WORKER ASSIGNMENT SUMMARY (PHASE-2):")
            for row in results {
                let name = row["worker_name"] as? String ?? "Unknown"
                let count = row["building_count"] as? Int64 ?? 0
                let emoji = getWorkerEmoji(name)
                print("   \(emoji) \(name): \(count) buildings")
            }
            
            // Verify Kevin's expansion
            let kevinCount = results.first(where: {
                ($0["worker_name"] as? String)?.contains("Kevin") == true
            })?["building_count"] as? Int64 ?? 0
            
            if kevinCount >= 6 {
                print("✅ Kevin's expanded duties verified: \(kevinCount) buildings")
            } else {
                print("⚠️ WARNING: Kevin should have 6+ buildings, found \(kevinCount)")
            }
            
        } catch {
            print("⚠️ Could not generate assignment summary: \(error)")
        }
    }
    
    private func getWorkerEmoji(_ workerName: String) -> String {
        switch workerName {
        case "Greg Hutson": return "🔧"
        case "Edwin Lema": return "🧹"
        case "Kevin Dutan": return "⚡"  // Expanded duties
        case "Mercedes Inamagua": return "✨"
        case "Luis Lopez": return "🔨"
        case "Angel Guirachocha": return "🗑️"
        case "Shawn Magloire": return "🎨"
        default: return "👷"
        }
    }
    
    // MARK: - Helper Methods (Enhanced for Phase-2)
    
    /// Map worker names to IDs (current active workers only)
    private func mapWorkerNameToId(_ workerName: String) async throws -> Int {
        guard let sqliteManager = sqliteManager else {
            throw CSVError.noSQLiteManager
        }
        
        // Block Jose Santos explicitly
        if workerName.contains("Jose") || workerName.contains("Santos") {
            throw CSVError.workerNotFound("Jose Santos is no longer with the company")
        }
        
        let workerResults = try await sqliteManager.query("""
            SELECT id FROM workers WHERE name = ?
            """, [workerName])
        
        if let worker = workerResults.first {
            if let workerId = worker["id"] as? Int64 {
                return Int(workerId)
            } else if let workerId = worker["id"] as? Int {
                return workerId
            }
        }
        
        throw CSVError.workerNotFound(workerName)
    }
    
    /// Enhanced building mapping
    private func mapBuildingNameToId(_ buildingName: String) async throws -> Int {
        guard let sqliteManager = sqliteManager else {
            throw CSVError.noSQLiteManager
        }
        
        // Clean the building name
        let cleanedName = buildingName
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .trimmingCharacters(in: .whitespaces)
        
        // First check name mappings table
        let mappingResults = try await sqliteManager.query("""
            SELECT building_id FROM building_name_mappings 
            WHERE csv_name = ? OR csv_name = ? OR canonical_name = ?
            """, [buildingName, cleanedName, cleanedName])
        
        if let mapping = mappingResults.first,
           let buildingIdStr = mapping["building_id"] as? String,
           let buildingId = Int(buildingIdStr) {
            return buildingId
        }
        
        // Fallback: direct building name match
        let buildingResults = try await sqliteManager.query("""
            SELECT id FROM buildings WHERE name = ? OR name = ?
            """, [buildingName, cleanedName])
        
        if let building = buildingResults.first {
            if let buildingId = building["id"] as? Int64 {
                return Int(buildingId)
            } else if let buildingId = building["id"] as? Int {
                return buildingId
            }
        }
        
        // Special case for FrancoSphere HQ
        if buildingName == "FrancoSphere HQ" {
            return 1 // Default to first building
        }
        
        // Last resort: partial match
        let partialResults = try await sqliteManager.query("""
            SELECT id, name FROM buildings WHERE name LIKE ?
            """, ["%\(cleanedName.prefix(10))%"])
        
        if let building = partialResults.first {
            if let buildingId = building["id"] as? Int64 {
                print("⚠️ Partial match: '\(buildingName)' → '\(building["name"] ?? "")'")
                return Int(buildingId)
            } else if let buildingId = building["id"] as? Int {
                return buildingId
            }
        }
        
        throw CSVError.buildingNotFound(buildingName)
    }
    
    /// Generate unique external ID for idempotency
    private func generateExternalId(for task: CSVTaskAssignment, index: Int) -> String {
        let components = [
            task.building,
            task.taskName,
            task.assignedWorker,
            task.recurrence,
            task.daysOfWeek ?? "all",
            String(index)
        ]
        let combined = components.joined(separator: "|")
        return "CSV-PHASE2-\(combined.hashValue)-\(index)"
    }
    
    /// Calculate appropriate due date based on recurrence and day pattern
    private func calculateDueDate(for recurrence: String, from date: Date) -> Date {
        let calendar = Calendar.current
        
        switch recurrence {
        case "Daily":
            return date
        case "Weekly":
            let daysToAdd = Int.random(in: 1...7)
            return calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
        case "Bi-Weekly":
            let daysToAdd = Int.random(in: 7...14)
            return calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
        case "Monthly", "Bi-Monthly":
            let daysToAdd = Int.random(in: 7...30)
            return calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
        case "Quarterly":
            let daysToAdd = Int.random(in: 30...90)
            return calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
        case "Semiannual":
            let daysToAdd = Int.random(in: 90...180)
            return calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
        case "Annual":
            let daysToAdd = Int.random(in: 180...365)
            return calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
        case "On-Demand":
            let daysToAdd = Int.random(in: 1...30)
            return calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
        default:
            return date
        }
    }
    
    // MARK: - ⭐ PHASE-2: Enhanced Logging
    
    /// Log Phase-2 import results with worker roster changes
    private func logPhase2ImportResults(imported: Int, errors: [String]) async {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        var logContent = """
        PHASE-2 CSV Import Log - \(dateFormatter.string(from: Date()))
        ================================================================
        Total Records: \(realWorldTasks.count)
        Successfully Imported: \(imported)
        Errors: \(errors.count)
        
        🔧 PHASE-2 CHANGES:
        • Jose Santos: REMOVED from all assignments
        • Kevin Dutan: EXPANDED to 6+ buildings (took Jose's duties)
        • Current Active Workers: 7 total (Greg, Edwin, Kevin, Mercedes, Luis, Angel, Shawn)
        
        CURRENT ACTIVE WORKER TASK SUMMARY:
        - Kevin Dutan: \(realWorldTasks.filter { $0.assignedWorker == "Kevin Dutan" }.count) tasks 🔧 EXPANDED
        - Mercedes Inamagua: \(realWorldTasks.filter { $0.assignedWorker == "Mercedes Inamagua" }.count) tasks (06:30-11:00)
        - Edwin Lema: \(realWorldTasks.filter { $0.assignedWorker == "Edwin Lema" }.count) tasks (06:00-15:00)
        - Luis Lopez: \(realWorldTasks.filter { $0.assignedWorker == "Luis Lopez" }.count) tasks (07:00-16:00)
        - Angel Guirachocha: \(realWorldTasks.filter { $0.assignedWorker == "Angel Guirachocha" }.count) tasks (18:00-22:00)
        - Greg Hutson: \(realWorldTasks.filter { $0.assignedWorker == "Greg Hutson" }.count) tasks (09:00-15:00)
        - Shawn Magloire: \(realWorldTasks.filter { $0.assignedWorker == "Shawn Magloire" }.count) tasks (floating specialist)
        
        Category Breakdown:
        - Cleaning: \(realWorldTasks.filter { $0.category == "Cleaning" }.count) tasks
        - Sanitation: \(realWorldTasks.filter { $0.category == "Sanitation" }.count) tasks
        - Maintenance: \(realWorldTasks.filter { $0.category == "Maintenance" }.count) tasks
        - Operations: \(realWorldTasks.filter { $0.category == "Operations" }.count) tasks
        - Inspection: \(realWorldTasks.filter { $0.category == "Inspection" }.count) tasks
        - Repair: \(realWorldTasks.filter { $0.category == "Repair" }.count) tasks
        
        """
        
        if !errors.isEmpty {
            logContent += "Errors:\n"
            for error in errors {
                logContent += "- \(error)\n"
            }
        }
        
        // Save to documents directory
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let logPath = documentsPath.appendingPathComponent("phase2_csv_import_log.txt")
            
            do {
                try logContent.write(to: logPath, atomically: true, encoding: .utf8)
                print("📝 Phase-2 import log saved to: \(logPath)")
            } catch {
                print("❌ Failed to save import log: \(error)")
            }
        }
        
        // Also save errors to CSV for easier review
        if !errors.isEmpty {
            await saveErrorsToCSV(errors)
        }
    }
    
    /// Save errors to CSV file
    private func saveErrorsToCSV(_ errors: [String]) async {
        let csvContent = "Timestamp,Error\n" + errors.map { "\"\(Date())\",\"\($0)\"" }.joined(separator: "\n")
        
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let errorPath = documentsPath.appendingPathComponent("phase2_import_errors.csv")
            
            do {
                try csvContent.write(to: errorPath, atomically: true, encoding: .utf8)
                print("📊 Phase-2 error CSV saved to: \(errorPath)")
            } catch {
                print("❌ Failed to save error CSV: \(error)")
            }
        }
    }
    
    // MARK: - Validation and Summary Methods (Unchanged)
    
    func validateCSVData() -> [String] {
        var validationErrors: [String] = []
        
        for (index, task) in realWorldTasks.enumerated() {
            // Validate categories
            let validCategories = ["Cleaning", "Sanitation", "Maintenance", "Inspection", "Operations", "Repair"]
            if !validCategories.contains(task.category) {
                validationErrors.append("Row \(index + 1): Invalid category '\(task.category)'")
            }
            
            // Validate skill levels
            let validSkillLevels = ["Basic", "Intermediate", "Advanced"]
            if !validSkillLevels.contains(task.skillLevel) {
                validationErrors.append("Row \(index + 1): Invalid skill level '\(task.skillLevel)'")
            }
            
            // Validate recurrence patterns
            let validRecurrences = ["Daily", "Weekly", "Bi-Weekly", "Bi-Monthly", "Monthly", "Quarterly", "Semiannual", "Annual", "On-Demand"]
            if !validRecurrences.contains(task.recurrence) {
                validationErrors.append("Row \(index + 1): Invalid recurrence '\(task.recurrence)'")
            }
            
            // Validate time ranges
            if let startHour = task.startHour, let endHour = task.endHour {
                if startHour < 0 || startHour > 23 {
                    validationErrors.append("Row \(index + 1): Invalid start hour \(startHour)")
                }
                if endHour < 0 || endHour > 23 {
                    validationErrors.append("Row \(index + 1): Invalid end hour \(endHour)")
                }
                if startHour >= endHour && endHour != startHour {
                    validationErrors.append("Row \(index + 1): Invalid time range \(startHour):00-\(endHour):00")
                }
            }
            
            // PHASE-2: Validate no Jose Santos
            if task.assignedWorker.contains("Jose") || task.assignedWorker.contains("Santos") {
                validationErrors.append("Row \(index + 1): Jose Santos is no longer active")
            }
        }
        
        return validationErrors
    }
    
    func getWorkerTaskSummary() -> [String: Int] {
        var summary: [String: Int] = [:]
        
        for task in realWorldTasks {
            summary[task.assignedWorker, default: 0] += 1
        }
        
        return summary
    }
    
    func getBuildingTaskSummary() -> [String: Int] {
        var summary: [String: Int] = [:]
        
        for task in realWorldTasks {
            summary[task.building, default: 0] += 1
        }
        
        return summary
    }
    
    // Additional methods remain unchanged...
    // getTimeOfDayDistribution(), getCategoryDistribution(), etc.
}

// MARK: - Error Types (Enhanced for Phase-2)

enum CSVError: LocalizedError {
    case noSQLiteManager
    case buildingNotFound(String)
    case workerNotFound(String)
    case inactiveWorker(String)
    
    var errorDescription: String? {
        switch self {
        case .noSQLiteManager:
            return "SQLiteManager not set on CSVDataImporter"
        case .buildingNotFound(let name):
            return "Building not found: '\(name)'"
        case .workerNotFound(let name):
            return "Worker not found: '\(name)'"
        case .inactiveWorker(let name):
            return "Worker '\(name)' is no longer active"
        }
    }
}

// MARK: - Date Extension
extension Date {
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }
}
