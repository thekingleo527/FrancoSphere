import Foundation
import SQLite

// MARK: - Operational Task Assignment Structure (Enhanced)
struct OperationalTaskAssignment {
    let building: String             // Plain-English building name as spoken internally
    let taskName: String             // Human friendly task title
    let assignedWorker: String       // Canonical full name, must exist in WorkerConstants
    let category: String             // One of: Cleaning | Sanitation | Maintenance | Inspection | Operations | Repair
    let skillLevel: String           // Basic | Intermediate | Advanced
    let recurrence: String           // Daily | Weekly | Bi-Weekly | Monthly | Quarterly | Semiannual | Annual | On-Demand
    let startHour: Int?              // 0-23, local time
    let endHour: Int?                // 0-23, local time
    let daysOfWeek: String?          // Comma list of day abbreviations (Mon,Tue …) or nil for "any"
}

// MARK: - OperationalDataManager (CSV-Free Implementation)

@MainActor
class OperationalDataManager: ObservableObject {
    static let shared = OperationalDataManager()
    
    // MUST have sqliteManager property
    var sqliteManager: SQLiteManager?
    
    @Published var importProgress: Double = 0.0
    @Published var currentStatus: String = ""
    
    private var hasImported = false
    private var importErrors: [String] = []

    // ──────────────────────────────────────────────────────────────────────────────
    //  🔧 PRESERVED: CURRENT ACTIVE WORKER TASK MATRIX  (José removed, Kevin expanded)
    //  – every entry reviewed with ops on 2025-06-17
    //  – Jose Santos completely removed from all assignments
    //  – Kevin Dutan expanded from ~28 to ~38 tasks (8+ buildings including Rubin Museum)
    //  – Only includes CURRENT ACTIVE WORKERS
    //  ✅ NO FILE PARSING - All data programmatic
    // -----------------------------------------------------------------------------
    private let realWorldTasks: [OperationalTaskAssignment] = [

        // ───────────────────────────────
        //  KEVIN DUTAN (EXPANDED DUTIES)
        //  Mon-Fri 06:00-17:00  (lunch 12-13)
        //  🔧 PRESERVED: Took Jose's duties + original assignments = 8+ buildings
        // ───────────────────────────────

        // Perry cluster (finish by 09:30)
        OperationalTaskAssignment(building: "131 Perry Street", taskName: "Sidewalk + Curb Sweep / Trash Return", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 6, endHour: 7, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        OperationalTaskAssignment(building: "131 Perry Street", taskName: "Hallway & Stairwell Clean / Vacuum", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 7, endHour: 8, daysOfWeek: "Mon,Wed"),
        OperationalTaskAssignment(building: "131 Perry Street", taskName: "Hallway & Stairwell Vacuum (light)", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 7, endHour: 7, daysOfWeek: "Fri"),

        // ✅ PRESERVED: 6 additional Kevin tasks for 131 Perry (Monday/Wednesday/Friday)
        OperationalTaskAssignment(building: "131 Perry Street", taskName: "Lobby + Packages Check", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 8, endHour: 8, daysOfWeek: "Mon,Wed,Fri"),
        OperationalTaskAssignment(building: "131 Perry Street", taskName: "Vacuum Hallways Floor 2-6", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 8, endHour: 9, daysOfWeek: "Mon,Wed,Fri"),
        OperationalTaskAssignment(building: "131 Perry Street", taskName: "Hose Down Sidewalks", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 9, endHour: 9, daysOfWeek: "Mon,Wed,Fri"),
        OperationalTaskAssignment(building: "131 Perry Street", taskName: "Clear Walls & Surfaces", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 9, endHour: 10, daysOfWeek: "Mon,Wed,Fri"),
        OperationalTaskAssignment(building: "131 Perry Street", taskName: "Check Bathroom + Trash Room", assignedWorker: "Kevin Dutan", category: "Sanitation", skillLevel: "Basic", recurrence: "Weekly", startHour: 10, endHour: 10, daysOfWeek: "Mon,Wed,Fri"),
        OperationalTaskAssignment(building: "131 Perry Street", taskName: "Mop Stairs A & B", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 10, endHour: 11, daysOfWeek: "Mon,Wed,Fri"),

        // 68 Perry Street tasks (Jose's former duties now Kevin's)
        OperationalTaskAssignment(building: "68 Perry Street", taskName: "Sidewalk / Curb Sweep & Trash Return", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 8, endHour: 9, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        OperationalTaskAssignment(building: "68 Perry Street", taskName: "Full Building Clean & Vacuum", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 8, endHour: 9, daysOfWeek: "Tue,Thu"),
        OperationalTaskAssignment(building: "68 Perry Street", taskName: "Stairwell Hose-Down + Trash Area Hose", assignedWorker: "Kevin Dutan", category: "Sanitation", skillLevel: "Basic", recurrence: "Weekly", startHour: 9, endHour: 9, daysOfWeek: "Mon,Wed,Fri"),

        // 17th / 18th cluster – Trash areas & common cleaning 10-12 (Kevin expanded coverage)
        OperationalTaskAssignment(building: "135-139 West 17th Street", taskName: "Trash Area + Sidewalk & Curb Clean", assignedWorker: "Kevin Dutan", category: "Sanitation", skillLevel: "Basic", recurrence: "Daily", startHour: 10, endHour: 11, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        OperationalTaskAssignment(building: "136 West 17th Street", taskName: "Trash Area + Sidewalk & Curb Clean", assignedWorker: "Kevin Dutan", category: "Sanitation", skillLevel: "Basic", recurrence: "Daily", startHour: 10, endHour: 11, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        OperationalTaskAssignment(building: "138 West 17th Street", taskName: "Trash Area + Sidewalk & Curb Clean", assignedWorker: "Kevin Dutan", category: "Sanitation", skillLevel: "Basic", recurrence: "Daily", startHour: 11, endHour: 12, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        OperationalTaskAssignment(building: "117 West 17th Street", taskName: "Trash Area Clean", assignedWorker: "Kevin Dutan", category: "Sanitation", skillLevel: "Basic", recurrence: "Daily", startHour: 11, endHour: 12, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        OperationalTaskAssignment(building: "112 West 18th Street", taskName: "Trash Area Clean", assignedWorker: "Kevin Dutan", category: "Sanitation", skillLevel: "Basic", recurrence: "Daily", startHour: 11, endHour: 12, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),

        // ✅ CRITICAL: Kevin's Rubin Museum tasks (CORRECTED REALITY)
        OperationalTaskAssignment(building: "Rubin Museum (142–148 W 17th)", taskName: "Trash Area + Sidewalk & Curb Clean", assignedWorker: "Kevin Dutan", category: "Sanitation", skillLevel: "Basic", recurrence: "Daily", startHour: 10, endHour: 11, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        OperationalTaskAssignment(building: "Rubin Museum (142–148 W 17th)", taskName: "Museum Entrance Sweep", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 11, endHour: 11, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        OperationalTaskAssignment(building: "Rubin Museum (142–148 W 17th)", taskName: "Weekly Deep Clean - Trash Area", assignedWorker: "Kevin Dutan", category: "Sanitation", skillLevel: "Basic", recurrence: "Weekly", startHour: 10, endHour: 12, daysOfWeek: "Mon,Wed,Fri"),
        OperationalTaskAssignment(building: "Rubin Museum (142–148 W 17th)", taskName: "DSNY Put-Out (after 20:00)", assignedWorker: "Kevin Dutan", category: "Operations", skillLevel: "Basic", recurrence: "Weekly", startHour: 20, endHour: 21, daysOfWeek: "Sun,Tue,Thu"),

        // After-lunch satellite cleans (former Jose territories now Kevin's)
        OperationalTaskAssignment(building: "29-31 East 20th Street", taskName: "Hallway / Glass / Sidewalk Sweep & Mop", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 13, endHour: 14, daysOfWeek: "Tue"),
        OperationalTaskAssignment(building: "123 1st Avenue", taskName: "Hallway & Curb Clean", assignedWorker: "Kevin Dutan", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 13, endHour: 14, daysOfWeek: "Tue,Thu"),
        OperationalTaskAssignment(building: "178 Spring Street", taskName: "Stair Hose & Garbage Return", assignedWorker: "Kevin Dutan", category: "Sanitation", skillLevel: "Basic", recurrence: "Weekly", startHour: 14, endHour: 15, daysOfWeek: "Mon,Wed,Fri"),

        // DSNY put-out (curb placement) — Sun/Tue/Thu, cannot place before 20:00
        OperationalTaskAssignment(building: "135-139 West 17th Street", taskName: "DSNY Put-Out (after 20:00)", assignedWorker: "Kevin Dutan", category: "Operations", skillLevel: "Basic", recurrence: "Weekly", startHour: 20, endHour: 21, daysOfWeek: "Sun,Tue,Thu"),
        OperationalTaskAssignment(building: "136 West 17th Street", taskName: "DSNY Put-Out (after 20:00)", assignedWorker: "Kevin Dutan", category: "Operations", skillLevel: "Basic", recurrence: "Weekly", startHour: 20, endHour: 21, daysOfWeek: "Sun,Tue,Thu"),
        OperationalTaskAssignment(building: "138 West 17th Street", taskName: "DSNY Put-Out (after 20:00)", assignedWorker: "Kevin Dutan", category: "Operations", skillLevel: "Basic", recurrence: "Weekly", startHour: 20, endHour: 21, daysOfWeek: "Sun,Tue,Thu"),
        OperationalTaskAssignment(building: "178 Spring Street", taskName: "DSNY Put-Out (after 20:00)", assignedWorker: "Kevin Dutan", category: "Operations", skillLevel: "Basic", recurrence: "Weekly", startHour: 20, endHour: 21, daysOfWeek: "Sun,Tue,Thu"),

        // ───────────────────────────────
        //  MERCEDES INAMAGUA  (06:30-11:00)
        // ───────────────────────────────
        OperationalTaskAssignment(building: "112 West 18th Street", taskName: "Glass & Lobby Clean", assignedWorker: "Mercedes Inamagua", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 6, endHour: 7, daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat"),
        OperationalTaskAssignment(building: "117 West 17th Street", taskName: "Glass & Lobby Clean", assignedWorker: "Mercedes Inamagua", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 7, endHour: 8, daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat"),
        OperationalTaskAssignment(building: "135-139 West 17th Street", taskName: "Glass & Lobby Clean", assignedWorker: "Mercedes Inamagua", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 8, endHour: 9, daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat"),
        OperationalTaskAssignment(building: "136 West 17th Street", taskName: "Glass & Lobby Clean", assignedWorker: "Mercedes Inamagua", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 9, endHour: 10, daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat"),
        OperationalTaskAssignment(building: "138 West 17th Street", taskName: "Glass & Lobby Clean", assignedWorker: "Mercedes Inamagua", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 10, endHour: 11, daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat"),
        OperationalTaskAssignment(building: "Rubin Museum (142–148 W 17th)", taskName: "Roof Drain – 2F Terrace", assignedWorker: "Mercedes Inamagua", category: "Maintenance", skillLevel: "Basic", recurrence: "Weekly", startHour: 10, endHour: 10, daysOfWeek: "Wed"),
        // 104 Franklin deep clean twice a week
        OperationalTaskAssignment(building: "104 Franklin Street", taskName: "Office Deep Clean", assignedWorker: "Mercedes Inamagua", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 14, endHour: 16, daysOfWeek: "Mon,Thu"),

        // ───────────────────────────────
        //  EDWIN LEMA  (06:00-15:00)
        // ───────────────────────────────
        // Park open
        OperationalTaskAssignment(building: "Stuyvesant Cove Park", taskName: "Morning Park Check", assignedWorker: "Edwin Lema", category: "Maintenance", skillLevel: "Intermediate", recurrence: "Daily", startHour: 6, endHour: 7, daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat,Sun"),
        OperationalTaskAssignment(building: "Stuyvesant Cove Park", taskName: "Power Wash Walkways", assignedWorker: "Edwin Lema", category: "Cleaning", skillLevel: "Intermediate", recurrence: "Monthly", startHour: 7, endHour: 9, daysOfWeek: nil),
        // 133 E 15th walk-through + boiler
        OperationalTaskAssignment(building: "133 East 15th Street", taskName: "Building Walk-Through", assignedWorker: "Edwin Lema", category: "Maintenance", skillLevel: "Intermediate", recurrence: "Weekly", startHour: 9, endHour: 10, daysOfWeek: "Mon,Wed,Fri"),
        OperationalTaskAssignment(building: "133 East 15th Street", taskName: "Boiler Blow-Down", assignedWorker: "Edwin Lema", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 9, endHour: 9, daysOfWeek: "Mon"),
        // Kevin coordination / repairs 13-15 (variable bldg)
        OperationalTaskAssignment(building: "FrancoSphere HQ", taskName: "Scheduled Repairs & Follow-ups", assignedWorker: "Edwin Lema", category: "Repair", skillLevel: "Intermediate", recurrence: "Daily", startHour: 13, endHour: 15, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        // Roof & filter rounds (embedded into walkthroughs, every other month)
        OperationalTaskAssignment(building: "117 West 17th Street", taskName: "Water Filter Change & Roof Drain Check", assignedWorker: "Edwin Lema", category: "Maintenance", skillLevel: "Intermediate", recurrence: "Bi-Monthly", startHour: 10, endHour: 11, daysOfWeek: nil),
        OperationalTaskAssignment(building: "112 West 18th Street", taskName: "Water Filter Change & Roof Drain Check", assignedWorker: "Edwin Lema", category: "Maintenance", skillLevel: "Intermediate", recurrence: "Bi-Monthly", startHour: 11, endHour: 12, daysOfWeek: nil),
        OperationalTaskAssignment(building: "135-139 West 17th Street", taskName: "Backyard Drain Check", assignedWorker: "Edwin Lema", category: "Inspection", skillLevel: "Basic", recurrence: "Weekly", startHour: 10, endHour: 10, daysOfWeek: "Fri"),
        // Boiler blow-downs quick hits
        OperationalTaskAssignment(building: "131 Perry Street", taskName: "Boiler Blow-Down", assignedWorker: "Edwin Lema", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 8, endHour: 8, daysOfWeek: "Wed"),
        OperationalTaskAssignment(building: "138 West 17th Street", taskName: "Boiler Blow-Down", assignedWorker: "Edwin Lema", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 10, endHour: 10, daysOfWeek: "Thu"),
        OperationalTaskAssignment(building: "135-139 West 17th Street", taskName: "Boiler Blow-Down", assignedWorker: "Edwin Lema", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 10, endHour: 10, daysOfWeek: "Tue"),
        OperationalTaskAssignment(building: "117 West 17th Street", taskName: "Boiler Blow-Down", assignedWorker: "Edwin Lema", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 11, endHour: 11, daysOfWeek: "Tue"),

        // ───────────────────────────────
        //  LUIS LOPEZ  (07:00-16:00)
        // ───────────────────────────────
        OperationalTaskAssignment(building: "104 Franklin Street", taskName: "Sidewalk Hose", assignedWorker: "Luis Lopez", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 7, endHour: 7, daysOfWeek: "Mon,Wed,Fri"),
        OperationalTaskAssignment(building: "36 Walker Street", taskName: "Sidewalk Sweep", assignedWorker: "Luis Lopez", category: "Cleaning", skillLevel: "Basic", recurrence: "Weekly", startHour: 7, endHour: 8, daysOfWeek: "Mon,Wed,Fri"),
        // 41 Elizabeth daily core
        OperationalTaskAssignment(building: "41 Elizabeth Street", taskName: "Bathrooms Clean", assignedWorker: "Luis Lopez", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 8, endHour: 9, daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat"),
        OperationalTaskAssignment(building: "41 Elizabeth Street", taskName: "Lobby & Sidewalk Clean", assignedWorker: "Luis Lopez", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 9, endHour: 10, daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat"),
        OperationalTaskAssignment(building: "41 Elizabeth Street", taskName: "Elevator Clean", assignedWorker: "Luis Lopez", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 10, endHour: 11, daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat"),
        OperationalTaskAssignment(building: "41 Elizabeth Street", taskName: "Afternoon Garbage Removal", assignedWorker: "Luis Lopez", category: "Sanitation", skillLevel: "Basic", recurrence: "Daily", startHour: 13, endHour: 14, daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat"),
        // Mail + bathroom re-check
        OperationalTaskAssignment(building: "41 Elizabeth Street", taskName: "Deliver Mail & Packages", assignedWorker: "Luis Lopez", category: "Operations", skillLevel: "Basic", recurrence: "Daily", startHour: 14, endHour: 14, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),

        // ───────────────────────────────
        //  ANGEL GUIRACHOCHA  (18:00-22:00)
        // ───────────────────────────────
        // Evening garbage collection & DSNY prep
        OperationalTaskAssignment(building: "12 West 18th Street", taskName: "Evening Garbage Collection", assignedWorker: "Angel Guirachocha", category: "Sanitation", skillLevel: "Basic", recurrence: "Weekly", startHour: 18, endHour: 19, daysOfWeek: "Mon,Wed,Fri"),
        OperationalTaskAssignment(building: "68 Perry Street", taskName: "DSNY Prep / Move Bins", assignedWorker: "Angel Guirachocha", category: "Operations", skillLevel: "Basic", recurrence: "Weekly", startHour: 19, endHour: 20, daysOfWeek: "Mon,Wed,Fri"),
        OperationalTaskAssignment(building: "123 1st Avenue", taskName: "DSNY Prep / Move Bins", assignedWorker: "Angel Guirachocha", category: "Operations", skillLevel: "Basic", recurrence: "Weekly", startHour: 19, endHour: 20, daysOfWeek: "Tue,Thu"),
        OperationalTaskAssignment(building: "104 Franklin Street", taskName: "DSNY Prep / Move Bins", assignedWorker: "Angel Guirachocha", category: "Operations", skillLevel: "Basic", recurrence: "Weekly", startHour: 20, endHour: 21, daysOfWeek: "Mon,Wed,Fri"),
        OperationalTaskAssignment(building: "135-139 West 17th Street", taskName: "Evening Building Security Check", assignedWorker: "Angel Guirachocha", category: "Inspection", skillLevel: "Basic", recurrence: "Daily", startHour: 21, endHour: 22, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),

        // ───────────────────────────────
        //  GREG HUTSON  (09:00-15:00)
        // ───────────────────────────────
        OperationalTaskAssignment(building: "12 West 18th Street", taskName: "Sidewalk & Curb Clean", assignedWorker: "Greg Hutson", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 9, endHour: 10, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        OperationalTaskAssignment(building: "12 West 18th Street", taskName: "Lobby & Vestibule Clean", assignedWorker: "Greg Hutson", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 10, endHour: 11, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        OperationalTaskAssignment(building: "12 West 18th Street", taskName: "Glass & Elevator Clean", assignedWorker: "Greg Hutson", category: "Cleaning", skillLevel: "Basic", recurrence: "Daily", startHour: 11, endHour: 12, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        OperationalTaskAssignment(building: "12 West 18th Street", taskName: "Trash Area Clean", assignedWorker: "Greg Hutson", category: "Sanitation", skillLevel: "Basic", recurrence: "Daily", startHour: 13, endHour: 14, daysOfWeek: "Mon,Tue,Wed,Thu,Fri"),
        OperationalTaskAssignment(building: "12 West 18th Street", taskName: "Boiler Blow-Down", assignedWorker: "Greg Hutson", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 14, endHour: 14, daysOfWeek: "Fri"),
        OperationalTaskAssignment(building: "12 West 18th Street", taskName: "Freight Elevator Operation (On-Demand)", assignedWorker: "Greg Hutson", category: "Operations", skillLevel: "Basic", recurrence: "On-Demand", startHour: nil, endHour: nil, daysOfWeek: nil),

        // ───────────────────────────────
        //  SHAWN MAGLOIRE  (floating specialist)
        // ───────────────────────────────
        OperationalTaskAssignment(building: "117 West 17th Street", taskName: "Boiler Blow-Down", assignedWorker: "Shawn Magloire", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 9, endHour: 11, daysOfWeek: "Mon"),
        OperationalTaskAssignment(building: "133 East 15th Street", taskName: "Boiler Blow-Down", assignedWorker: "Shawn Magloire", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 11, endHour: 13, daysOfWeek: "Tue"),
        OperationalTaskAssignment(building: "136 West 17th Street", taskName: "Boiler Blow-Down", assignedWorker: "Shawn Magloire", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 13, endHour: 15, daysOfWeek: "Wed"),
        OperationalTaskAssignment(building: "138 West 17th Street", taskName: "Boiler Blow-Down", assignedWorker: "Shawn Magloire", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 15, endHour: 17, daysOfWeek: "Thu"),
        OperationalTaskAssignment(building: "115 7th Avenue", taskName: "Boiler Blow-Down", assignedWorker: "Shawn Magloire", category: "Maintenance", skillLevel: "Advanced", recurrence: "Weekly", startHour: 9, endHour: 11, daysOfWeek: "Fri"),
        OperationalTaskAssignment(building: "112 West 18th Street", taskName: "HVAC System Check", assignedWorker: "Shawn Magloire", category: "Maintenance", skillLevel: "Advanced", recurrence: "Monthly", startHour: 9, endHour: 12, daysOfWeek: nil),
        OperationalTaskAssignment(building: "117 West 17th Street", taskName: "HVAC System Check", assignedWorker: "Shawn Magloire", category: "Maintenance", skillLevel: "Advanced", recurrence: "Monthly", startHour: 13, endHour: 16, daysOfWeek: nil)

        // NOTE: Jose Santos tasks have been COMPLETELY REMOVED and redistributed to Kevin Dutan
    ]
    
    // ──────────────────────────────────────────────────────────────────────────────
    //  🔧 PRESERVED: ROUTINE SCHEDULES WITH CORRECTED BUILDING IDs
    //  Real-world operational schedules based on NYC property management standards
    //  ✅ NO FILE PARSING - All data programmatic
    // ──────────────────────────────────────────────────────────────────────────────

    private let routineSchedules: [(buildingId: String, name: String, rrule: String, workerId: String, category: String)] = [
        // Kevin's Perry Street circuit (expanded duties - took Jose's routes)
        ("10", "Daily Sidewalk Sweep", "FREQ=DAILY;BYHOUR=6", "4", "Cleaning"),
        ("10", "Weekly Hallway Deep Clean", "FREQ=WEEKLY;BYDAY=MO,WE;BYHOUR=7", "4", "Cleaning"),
        ("6", "Perry 68 Full Building Clean", "FREQ=WEEKLY;BYDAY=TU,TH;BYHOUR=8", "4", "Cleaning"),
        ("7", "17th Street Trash Area Maintenance", "FREQ=DAILY;BYHOUR=11", "4", "Cleaning"),
        ("9", "DSNY Compliance Check", "FREQ=WEEKLY;BYDAY=SU,TU,TH;BYHOUR=20", "4", "Operations"),
        
        // ✅ PRESERVED: Kevin's Rubin Museum routing (consistent ID "14")
        ("14", "Rubin Morning Trash Circuit", "FREQ=DAILY;BYHOUR=10", "4", "Sanitation"),
        ("14", "Rubin Museum Deep Clean", "FREQ=WEEKLY;BYDAY=MO,WE,FR;BYHOUR=10", "4", "Sanitation"),
        ("14", "Rubin DSNY Operations", "FREQ=WEEKLY;BYDAY=SU,TU,TH;BYHOUR=20", "4", "Operations"),
        
        // Mercedes' morning glass circuit (6:30-11:00 AM shift)
        ("7", "Glass & Lobby Clean", "FREQ=DAILY;BYHOUR=6", "5", "Cleaning"),
        ("9", "117 West 17th Glass & Vestibule", "FREQ=DAILY;BYHOUR=7", "5", "Cleaning"),
        ("3", "135-139 West 17th Glass Clean", "FREQ=DAILY;BYHOUR=8", "5", "Cleaning"),
        ("14", "Rubin Museum Roof Drain Check", "FREQ=WEEKLY;BYDAY=WE;BYHOUR=10", "5", "Maintenance"),
        
        // Edwin's maintenance rounds (6:00-15:00)
        ("16", "Stuyvesant Park Morning Inspection", "FREQ=DAILY;BYHOUR=6", "2", "Maintenance"),
        ("15", "133 E 15th Boiler Blow-Down", "FREQ=WEEKLY;BYDAY=MO;BYHOUR=9", "2", "Maintenance"),
        ("9", "Water Filter Change", "FREQ=MONTHLY;BYHOUR=10", "2", "Maintenance"),
        
        // Luis Lopez daily circuit (7:00-16:00)
        ("4", "104 Franklin Sidewalk Hose", "FREQ=WEEKLY;BYDAY=MO,WE,FR;BYHOUR=7", "6", "Cleaning"),
        ("8", "41 Elizabeth Full Service", "FREQ=DAILY;BYHOUR=8", "6", "Cleaning"),
        
        // Greg Hutson building specialist (9:00-15:00)
        ("1", "12 West 18th Complete Service", "FREQ=DAILY;BYHOUR=9", "1", "Cleaning"),
        
        // Angel evening operations (18:00-22:00)
        ("1", "Evening Security Check", "FREQ=DAILY;BYHOUR=21", "7", "Operations"),
        
        // Shawn specialist maintenance (floating schedule)
        ("14", "Rubin Museum HVAC Systems", "FREQ=MONTHLY;BYHOUR=9", "8", "Maintenance"),
    ]

    private let dsnySchedules: [(buildingIds: [String], collectionDays: String, routeId: String)] = [
        // Manhattan West 17th Street corridor (including Rubin Museum)
        (["7", "9", "3", "14"], "MON,WED,FRI", "MAN-17TH-WEST"),
        
        // Perry Street / West Village
        (["10", "6"], "MON,WED,FRI", "MAN-PERRY-VILLAGE"),
        
        // Downtown / Tribeca route
        (["4", "8"], "TUE,THU,SAT", "MAN-DOWNTOWN-TRI"),
        
        // East side route
        (["1"], "MON,WED,FRI", "MAN-18TH-EAST"),
        
        // Special collections (Rubin Museum enhanced)
        (["14"], "TUE,FRI", "MAN-MUSEUM-SPECIAL"),
    ]
    
    private init() {}

    // MARK: - ✅ PRESERVED: Ensure Active Workers Exist in Database

    /// Seed the workers table with current active roster
    private func seedActiveWorkers() async throws {
        guard let sqliteManager = sqliteManager else {
            throw OperationalError.noSQLiteManager
        }
        
        print("🔧 Seeding active workers table...")
        
        // Current active worker roster (no Jose Santos)
        let activeWorkers = [
            ("1", "Greg Hutson", "greg.hutson@francomanagement.com", "Maintenance"),
            ("2", "Edwin Lema", "edwin.lema@francomanagement.com", "Cleaning"),
            ("4", "Kevin Dutan", "kevin.dutan@francomanagement.com", "Cleaning"), // CRITICAL: Kevin
            ("5", "Mercedes Inamagua", "mercedes.inamagua@francomanagement.com", "Cleaning"),
            ("6", "Luis Lopez", "luis.lopez@francomanagement.com", "Maintenance"),
            ("7", "Angel Guirachocha", "angel.guirachocha@francomanagement.com", "Sanitation"),
            ("8", "Shawn Magloire", "shawn.magloire@francomanagement.com", "Management")
        ]
        
        for (id, name, email, role) in activeWorkers {
            // Check if worker already exists
            let existingWorker = try await sqliteManager.query(
                "SELECT id FROM workers WHERE id = ? LIMIT 1",
                [id]
            )
            
            if existingWorker.isEmpty {
                // Insert missing worker
                try await sqliteManager.execute("""
                    INSERT INTO workers (id, name, email, role, isActive, shift, hireDate) 
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    """, [
                        id,
                        name,
                        email,
                        role,
                        "1", // isActive = true
                        getWorkerShift(id),
                        "2023-01-01" // Default hire date
                    ])
                
                print("✅ Created worker record: \(name) (ID: \(id))")
            } else {
                print("✓ Worker exists: \(name) (ID: \(id))")
            }
        }
        
        // Verify Kevin specifically
        let kevinCheck = try await sqliteManager.query(
            "SELECT id, name FROM workers WHERE id = '4' LIMIT 1",
            []
        )
        
        if kevinCheck.isEmpty {
            print("❌ CRITICAL: Kevin still not found after seeding!")
        } else {
            print("✅ VERIFIED: Kevin Dutan (ID: 4) exists in workers table")
        }
    }

    /// Get worker shift schedule
    private func getWorkerShift(_ workerId: String) -> String {
        switch workerId {
        case "1": return "9:00 AM - 3:00 PM"        // Greg
        case "2": return "6:00 AM - 3:00 PM"        // Edwin
        case "4": return "6:00 AM - 5:00 PM"        // Kevin (expanded)
        case "5": return "6:30 AM - 11:00 AM"       // Mercedes (split)
        case "6": return "7:00 AM - 4:00 PM"        // Luis
        case "7": return "6:00 PM - 10:00 PM"       // Angel (evening)
        case "8": return "Flexible"                 // Shawn (management)
        default: return "9:00 AM - 5:00 PM"
        }
    }

    // MARK: - ⭐ PRESERVED: Enhanced Import Methods (NO FILE PARSING)
    
    /// Main import function - uses ONLY programmatic data (no file parsing)
    func importRealWorldTasks() async throws -> (imported: Int, errors: [String]) {
        guard let sqliteManager = sqliteManager else {
            throw OperationalError.noSQLiteManager
        }
        
        guard !hasImported else {
            print("✅ Tasks already imported, skipping duplicate import")
            return (0, [])
        }
        
        await MainActor.run {
            importProgress = 0.0
            currentStatus = "Starting import..."
            importErrors = []
        }
        
        do {
            // ✅ Seed workers table FIRST
            try await seedActiveWorkers()
            
            await MainActor.run {
                importProgress = 0.1
                currentStatus = "Workers seeded, importing tasks..."
            }
            
            // Now continue with the original import logic using programmatic data
            var importedCount = 0
            let calendar = Calendar.current
            let today = Date()
            
            print("📂 Starting task import with \(realWorldTasks.count) tasks...")
            print("🔧 Current active workers only (Jose Santos removed)")
            print("✅ PRESERVED: Kevin's Rubin Museum (building ID 14) tasks included")
            currentStatus = "Importing \(realWorldTasks.count) tasks for current active workers..."
            
            // Pre-import Kevin diagnostic
            print("🔍 Pre-import Kevin diagnostic")
            do {
                let existingKevin = try await sqliteManager.query("""
                    SELECT COUNT(*) as count FROM worker_building_assignments 
                    WHERE worker_id = '4' AND is_active = 1
                """)
                let currentCount = existingKevin.first?["count"] as? Int64 ?? 0
                print("   Kevin's current building assignments: \(currentCount)")
            } catch {
                print("   Could not check Kevin's existing assignments: \(error)")
            }
            
            // First populate worker building assignments
            try await populateWorkerBuildingAssignments(realWorldTasks)
            
            // Process each operational assignment (no file parsing)
            for (index, operationalTask) in realWorldTasks.enumerated() {
                do {
                    // Update progress
                    importProgress = 0.1 + (0.8 * Double(index) / Double(realWorldTasks.count))
                    currentStatus = "Importing task \(index + 1)/\(realWorldTasks.count)"
                    
                    // Generate external ID for idempotency
                    let externalId = generateExternalId(for: operationalTask, index: index)
                    
                    // Check if task already exists
                    let existingTasks = try await sqliteManager.query("""
                        SELECT id FROM tasks WHERE external_id = ?
                        """, [externalId])
                    
                    if !existingTasks.isEmpty {
                        print("⏭️ Skipping duplicate task: \(operationalTask.taskName)")
                        continue
                    }
                    
                    // Calculate due date
                    let dueDate = calculateDueDate(for: operationalTask.recurrence, from: today)
                    
                    // Map building name to ID
                    let buildingId = try await mapBuildingNameToId(operationalTask.building)
                    
                    // Map worker name to ID (current active workers only)
                    let workerId: Int? = if !operationalTask.assignedWorker.isEmpty {
                        try? await mapWorkerNameToId(operationalTask.assignedWorker)
                    } else {
                        nil
                    }
                    
                    // Skip if worker not found (handles Jose removal)
                    guard let validWorkerId = workerId else {
                        print("⚠️ Skipping task for inactive worker: \(operationalTask.assignedWorker)")
                        continue
                    }
                    
                    // Calculate start/end times
                    var startTime: String? = nil
                    var endTime: String? = nil
                    
                    if let startHour = operationalTask.startHour, let endHour = operationalTask.endHour {
                        if let start = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: dueDate),
                           let end = calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: dueDate) {
                            startTime = start.iso8601String
                            endTime = end.iso8601String
                        }
                    }
                    
                    // Map urgency level
                    let urgencyLevel = operationalTask.skillLevel == "Advanced" ? "high" :
                                      operationalTask.skillLevel == "Intermediate" ? "medium" : "low"
                    
                    // Insert task - Convert to strings and handle optionals
                    try await sqliteManager.execute("""
                        INSERT INTO tasks (
                            name, description, buildingId, workerId, isCompleted,
                            scheduledDate, recurrence, urgencyLevel, category,
                            startTime, endTime, external_id
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """, [
                            operationalTask.taskName,
                            "Imported from current active worker schedule",
                            "\(buildingId)",  // Convert to string
                            "\(validWorkerId)",  // Convert to string
                            "0",
                            dueDate.iso8601String,
                            operationalTask.recurrence,
                            urgencyLevel,
                            operationalTask.category,
                            startTime ?? "",  // Use empty string for nil
                            endTime ?? "",    // Use empty string for nil
                            externalId
                        ])
                    
                    importedCount += 1
                    
                    // Special logging for Kevin's Rubin Museum tasks
                    if operationalTask.assignedWorker == "Kevin Dutan" && operationalTask.building.contains("Rubin") {
                        print("✅ PRESERVED: Imported Kevin's Rubin Museum task: \(operationalTask.taskName)")
                    } else {
                        print("✅ Imported: \(operationalTask.taskName) for \(operationalTask.building) (\(operationalTask.assignedWorker))")
                    }
                    
                    // Log progress every 10 tasks
                    if (index + 1) % 10 == 0 {
                        print("📈 Imported \(index + 1)/\(realWorldTasks.count) tasks")
                    }
                    
                    // Allow UI to update periodically
                    if index % 5 == 0 {
                        try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
                    }
                    
                } catch {
                    let errorMsg = "Error processing task \(operationalTask.taskName): \(error.localizedDescription)"
                    importErrors.append(errorMsg)
                    print("❌ \(errorMsg)")
                }
            }
            
            hasImported = true
            
            await MainActor.run {
                importProgress = 1.0
                currentStatus = "Import complete!"
            }
            
            // Log results with corrected summary
            await logImportResults(imported: importedCount, errors: importErrors)
            
            return (importedCount, importErrors)
            
        } catch {
            await MainActor.run {
                currentStatus = "Import failed: \(error.localizedDescription)"
            }
            throw error
        }
    }

    /// Enhanced method to get Kevin's tasks including Rubin Museum (programmatic data only)
    func getTasksForWorker(_ workerId: String, date: Date) async -> [ContextualTask] {
        let workerTasks = realWorldTasks.filter { task in
            // Map worker names to IDs for filtering
            let workerNameToId = [
                "Greg Hutson": "1",
                "Edwin Lema": "2",
                "Kevin Dutan": "4",
                "Mercedes Inamagua": "5",
                "Luis Lopez": "6",
                "Angel Guirachocha": "7",
                "Shawn Magloire": "8"
            ]
            
            return workerNameToId[task.assignedWorker] == workerId
        }
        
        // Convert to ContextualTask objects
        var contextualTasks: [ContextualTask] = []
        
        for operationalTask in workerTasks {
            let task = ContextualTask(
                id: generateExternalId(for: operationalTask, index: 0),
                name: operationalTask.taskName,
                buildingId: getBuildingIdFromName(operationalTask.building),
                buildingName: operationalTask.building,
                category: operationalTask.category,
                startTime: operationalTask.startHour != nil ? String(format: "%02d:00", operationalTask.startHour!) : nil,
                endTime: operationalTask.endHour != nil ? String(format: "%02d:00", operationalTask.endHour!) : nil,
                recurrence: operationalTask.recurrence,
                skillLevel: operationalTask.skillLevel,
                status: "pending",
                urgencyLevel: operationalTask.skillLevel == "Advanced" ? "high" : "medium",
                assignedWorkerName: operationalTask.assignedWorker
            )
            contextualTasks.append(task)
        }
        
        // Special logging for Kevin's Rubin Museum tasks
        if workerId == "4" {
            let rubinTasks = contextualTasks.filter { $0.buildingName.contains("Rubin") }
            print("✅ PRESERVED: Kevin has \(rubinTasks.count) Rubin Museum tasks with building ID 14")
        }
        
        return contextualTasks
    }
    
    /// ✅ PRESERVED: Helper method to map building names to IDs with corrected mapping
    private func getBuildingIdFromName(_ buildingName: String) -> String {
        let buildingMap = [
            // Perry Street cluster
            "131 Perry Street": "10",
            "68 Perry Street": "6",
            
            // West 17th Street corridor
            "135-139 West 17th Street": "3",    // ✅ PRESERVED: corrected mapping
            "136 West 17th Street": "13",       // ✅ CONSISTENT
            "138 West 17th Street": "5",        // ✅ PRESERVED: corrected mapping
            "117 West 17th Street": "9",        // ✅ CONSISTENT
            
            // West 18th Street
            "112 West 18th Street": "7",        // ✅ CONSISTENT
            "12 West 18th Street": "1",         // ✅ CONSISTENT
            
            // ✅ CRITICAL: Rubin Museum (Kevin's workplace)
            "Rubin Museum (142–148 W 17th)": "14",  // ✅ PRESERVED REALITY
            
            // East side
            "29-31 East 20th Street": "2",      // ✅ CONSISTENT
            "133 East 15th Street": "15",       // ✅ CONSISTENT
            
            // Downtown
            "178 Spring Street": "17",          // ✅ CONSISTENT
            "104 Franklin Street": "4",         // ✅ CONSISTENT
            "41 Elizabeth Street": "8",         // ✅ CONSISTENT
            "36 Walker Street": "18",           // ✅ CONSISTENT
            
            // Special locations
            "Stuyvesant Cove Park": "16",       // ✅ PRESERVED: unique ID
            "123 1st Avenue": "11",             // ✅ CONSISTENT
            "115 7th Avenue": "19",             // ✅ CONSISTENT
            "FrancoSphere HQ": "20"             // ✅ CONSISTENT
        ]
        
        return buildingMap[buildingName] ?? "1"
    }
    
    /// Enhanced import method for operational schedules with deterministic IDs (no file parsing)
    func importRoutinesAndDSNY() async throws -> (routines: Int, dsny: Int) {
        guard let sqliteManager = sqliteManager else {
            throw OperationalError.noSQLiteManager
        }
        
        var routineCount = 0, dsnyCount = 0
        
        print("🔧 Creating routine scheduling tables...")
        print("✅ PRESERVED: Including Kevin's Rubin Museum routing with building ID 14")
        
        // Create routine_schedules table (operational schedule tracking)
        try await sqliteManager.execute("""
            CREATE TABLE IF NOT EXISTS routine_schedules (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                building_id TEXT NOT NULL,
                rrule TEXT NOT NULL,
                worker_id TEXT NOT NULL,
                category TEXT NOT NULL,
                estimated_duration INTEGER DEFAULT 3600,
                weather_dependent INTEGER DEFAULT 0,
                priority_level TEXT DEFAULT 'medium',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (building_id) REFERENCES buildings(id),
                FOREIGN KEY (worker_id) REFERENCES workers(id)
            )
        """)
        
        // Add UNIQUE constraints to prevent duplicates
        try await sqliteManager.execute("""
            CREATE UNIQUE INDEX IF NOT EXISTS idx_routine_unique 
            ON routine_schedules(building_id, worker_id, name)
        """)
        
        // Insert operational routines with deterministic IDs (no file parsing)
        for routine in routineSchedules {
            // Deterministic ID generation using hash
            let id = "routine_\(routine.buildingId)_\(routine.workerId)_\(routine.name.hashValue.magnitude)"
            let weatherDependent = routine.category == "Cleaning" ? 1 : 0
            
            try await sqliteManager.execute("""
                INSERT OR REPLACE INTO routine_schedules 
                (id, name, building_id, rrule, worker_id, category, weather_dependent)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, [id, routine.name, routine.buildingId, routine.rrule, routine.workerId, routine.category, String(weatherDependent)])
            routineCount += 1
            
            // Special logging for Kevin's Rubin Museum routing
            if routine.workerId == "4" && routine.buildingId == "14" {
                print("✅ PRESERVED: Added Kevin's Rubin Museum routine: \(routine.name) (building ID 14)")
            }
        }
        
        // Create dsny_schedules table (NYC DSNY compliance tracking)
        try await sqliteManager.execute("""
            CREATE TABLE IF NOT EXISTS dsny_schedules (
                id TEXT PRIMARY KEY,
                route_id TEXT NOT NULL,
                building_ids TEXT NOT NULL,
                collection_days TEXT NOT NULL,
                earliest_setout INTEGER DEFAULT 72000,
                latest_pickup INTEGER DEFAULT 32400,
                pickup_window_start INTEGER DEFAULT 21600,
                pickup_window_end INTEGER DEFAULT 43200,
                route_status TEXT DEFAULT 'active',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        // Add UNIQUE constraint for DSNY routes
        try await sqliteManager.execute("""
            CREATE UNIQUE INDEX IF NOT EXISTS idx_dsny_unique 
            ON dsny_schedules(route_id)
        """)
        
        // Insert DSNY schedules with deterministic IDs (no file parsing)
        for dsny in dsnySchedules {
            // Deterministic ID for DSNY routes
            let id = "dsny_\(dsny.routeId.hashValue.magnitude)"
            let buildingIdsJson = dsny.buildingIds.joined(separator: ",")
            
            try await sqliteManager.execute("""
                INSERT OR REPLACE INTO dsny_schedules 
                (id, route_id, building_ids, collection_days, earliest_setout, latest_pickup, pickup_window_start, pickup_window_end)
                VALUES (?, ?, ?, ?, 72000, 32400, 21600, 43200)
            """, [id, dsny.routeId, buildingIdsJson, dsny.collectionDays])
            dsnyCount += 1
            
            // Special logging for Rubin Museum DSNY routing
            if dsny.buildingIds.contains("14") {
                print("✅ PRESERVED: Rubin Museum (building ID 14) included in DSNY route: \(dsny.routeId)")
            }
        }
        
        print("✅ Imported \(routineCount) routine schedules, \(dsnyCount) DSNY routes")
        print("   🗑️ DSNY compliance: Set-out after 8:00 PM, pickup 6:00-12:00 AM")
        print("   🔄 Routine coverage: \(Set(routineSchedules.map { $0.workerId }).count) active workers")
        print("   ✅ PRESERVED: Kevin's Rubin Museum fully integrated with building ID 14")
        
        return (routineCount, dsnyCount)
    }
    
    // MARK: - ⭐ PRESERVED: Worker Building Assignments (NO FILE PARSING)
    
    /// Populate worker_building_assignments with CURRENT ACTIVE WORKERS ONLY (no file parsing)
    private func populateWorkerBuildingAssignments(_ assignments: [OperationalTaskAssignment]) async throws {
        guard let sqliteManager = sqliteManager else {
            throw NSError(domain: "OperationalImportError", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "SQLiteManager not available"])
        }
        
        // Enhanced activeWorkers with exact name matching and diagnostic logging
        let activeWorkers: [String: String] = [
            "Greg Hutson": "1",
            "Edwin Lema": "2",
            "Kevin Dutan": "4",        // ✅ CRITICAL: Exact operational name match
            "Mercedes Inamagua": "5",
            "Luis Lopez": "6",
            "Angel Guirachocha": "7",
            "Shawn Magloire": "8"
        ]
        
        // EMERGENCY DIAGNOSTIC: Log all worker names in operational data vs activeWorkers
        print("🔍 Operational Data Import Diagnostic")
        print("📋 Active Workers Dictionary:")
        for (name, id) in activeWorkers.sorted(by: { $0.key < $1.key }) {
            print("   '\(name)' → ID '\(id)'")
        }
        
        // Count assignments per worker in operational data
        let operationalWorkerCounts = Dictionary(grouping: assignments) { $0.assignedWorker }
        print("📋 Operational Task Assignments:")
        for (workerName, tasks) in operationalWorkerCounts.sorted(by: { $0.key < $1.key }) {
            let isActive = activeWorkers[workerName] != nil
            let status = isActive ? "✅ ACTIVE" : "❌ INACTIVE/UNKNOWN"
            let rubinCount = tasks.filter { $0.building.contains("Rubin") }.count
            let rubinStatus = rubinCount > 0 ? " (including \(rubinCount) Rubin Museum tasks)" : ""
            print("   '\(workerName)': \(tasks.count) tasks (\(status))\(rubinStatus)")
        }
        
        print("🔗 Extracting assignments from \(assignments.count) operational tasks for ACTIVE WORKERS ONLY")
        print("✅ PRESERVED: Including Kevin's Rubin Museum assignments with building ID 14")
        
        // Extract unique worker-building pairs - ACTIVE WORKERS ONLY (no file parsing)
        var workerBuildingPairs: Set<String> = []
        var skippedAssignments = 0
        var kevinAssignmentCount = 0  // Track Kevin specifically
        var kevinRubinAssignments = 0 // Track Kevin's Rubin Museum specifically
        
        for assignment in assignments {
            guard !assignment.assignedWorker.isEmpty,
                  !assignment.building.isEmpty else {
                continue
            }
            
            // Enhanced worker validation with Kevin tracking
            guard let workerId = activeWorkers[assignment.assignedWorker] else {
                if assignment.assignedWorker.contains("Jose") || assignment.assignedWorker.contains("Santos") {
                    print("📝 Skipping Jose Santos assignment (no longer with company)")
                } else {
                    print("⚠️ Skipping unknown worker: '\(assignment.assignedWorker)'")
                }
                skippedAssignments += 1
                continue
            }
            
            // Track Kevin's assignments specifically
            if workerId == "4" {
                kevinAssignmentCount += 1
                if assignment.building.contains("Rubin") {
                    kevinRubinAssignments += 1
                }
            }
            
            do {
                let buildingId = try await mapBuildingNameToId(assignment.building)
                let pairKey = "\(workerId)-\(buildingId)"
                workerBuildingPairs.insert(pairKey)
                
            } catch {
                print("⚠️ Skipping assignment - unknown building: '\(assignment.building)' for \(assignment.assignedWorker)")
                skippedAssignments += 1
                continue
            }
        }
        
        // Critical Kevin validation with Rubin Museum tracking
        print("🔗 Assignment Extraction Results:")
        print("   Total pairs extracted: \(workerBuildingPairs.count)")
        print("   Assignments skipped: \(skippedAssignments)")
        print("   Kevin task assignments found: \(kevinAssignmentCount)")
        print("   ✅ PRESERVED: Kevin Rubin Museum assignments: \(kevinRubinAssignments)")
        
        // Count Kevin's building assignments specifically
        let kevinBuildingPairs = workerBuildingPairs.filter { $0.hasPrefix("4-") }
        print("   Kevin building assignments: \(kevinBuildingPairs.count)")
        
        if kevinBuildingPairs.isEmpty {
            print("🚨 CRITICAL: Kevin has NO building assignments!")
            print("🔍 Debugging Kevin assignments...")
            
            // Emergency diagnostic for Kevin
            let kevinTasks = assignments.filter { $0.assignedWorker == "Kevin Dutan" }
            print("   Kevin tasks in operational data: \(kevinTasks.count)")
            if kevinTasks.count > 0 {
                print("   Sample Kevin task: '\(kevinTasks.first?.taskName ?? "N/A")' at '\(kevinTasks.first?.building ?? "N/A")'")
            }
            
            // Check if Kevin's name appears with different spelling
            let kevinVariants = assignments.filter { $0.assignedWorker.lowercased().contains("kevin") }
            print("   Kevin name variants found: \(Set(kevinVariants.map { $0.assignedWorker }))")
        } else if kevinRubinAssignments == 0 {
            print("⚠️ WARNING: Kevin has building assignments but NO Rubin Museum tasks!")
        } else {
            print("✅ PRESERVED: Kevin's Rubin Museum assignments confirmed")
        }
        
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
                
                // Special logging for Kevin's Rubin Museum assignment
                if workerId == "4" && buildingId == "14" {
                    print("✅ PRESERVED: Kevin assigned to Rubin Museum (building ID 14)")
                }
            } catch {
                print("⚠️ Failed to insert assignment \(workerId)->\(buildingId): \(error)")
            }
        }
        
        // Enhanced results logging with Kevin focus
        print("✅ Real-world assignments populated: \(insertedCount) active assignments")
        
        // Immediate Kevin verification
        do {
            let kevinVerification = try await sqliteManager.query("""
                SELECT building_id FROM worker_building_assignments 
                WHERE worker_id = '4' AND is_active = 1
            """)
            print("🎯 Kevin verification: \(kevinVerification.count) buildings in database")
            
            // Check specifically for Rubin Museum assignment
            let kevinRubinVerification = try await sqliteManager.query("""
                SELECT building_id FROM worker_building_assignments 
                WHERE worker_id = '4' AND building_id = '14' AND is_active = 1
            """)
            
            if kevinRubinVerification.count > 0 {
                print("✅ PRESERVED: Kevin's Rubin Museum assignment verified in database")
            } else {
                print("⚠️ PRESERVED: Kevin's Rubin Museum assignment NOT found in database")
            }
            
            if kevinVerification.count == 0 {
                print("🚨 EMERGENCY: Kevin still has 0 buildings after import!")
                await createEmergencyKevinAssignments(sqliteManager)
            }
        } catch {
            print("❌ Could not verify Kevin assignments: \(error)")
        }
        
        // Log final worker assignment summary
        await logWorkerAssignmentSummary(activeWorkers)
    }
    
    /// Emergency fallback: Create Kevin's assignments manually if import fails
    private func createEmergencyKevinAssignments(_ manager: SQLiteManager) async {
        print("🆘 Creating emergency Kevin assignments...")
        print("✅ PRESERVED: Including Rubin Museum (building ID 14) in emergency assignments")
        
        // Kevin's known buildings based on real-world assignments (with corrected IDs)
        let kevinBuildings = ["10", "6", "3", "13", "5", "2", "17", "14"] // 14 = Rubin Museum
        
        do {
            for buildingId in kevinBuildings {
                let assignmentType = buildingId == "14" ? "emergency_rubin_museum" : "emergency_fallback"
                try await manager.execute("""
                    INSERT OR REPLACE INTO worker_building_assignments 
                    (worker_id, building_id, worker_name, assignment_type, start_date, is_active) 
                    VALUES ('4', ?, 'Kevin Dutan', ?, datetime('now'), 1)
                """, [buildingId, assignmentType])
                
                if buildingId == "14" {
                    print("✅ PRESERVED: Emergency Rubin Museum assignment created for Kevin (building ID 14)")
                }
            }
            
            print("✅ Emergency Kevin assignments created: \(kevinBuildings)")
            
            // Verify the emergency assignments
            let verification = try await manager.query("""
                SELECT building_id FROM worker_building_assignments 
                WHERE worker_id = '4' AND is_active = 1
            """)
            print("🎯 Emergency verification: Kevin now has \(verification.count) buildings")
            
        } catch {
            print("🚨 CRITICAL: Emergency assignment creation failed: \(error)")
        }
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
            
            print("📊 ACTIVE WORKER ASSIGNMENT SUMMARY (PRESERVED):")
            for row in results {
                let name = row["worker_name"] as? String ?? "Unknown"
                let count = row["building_count"] as? Int64 ?? 0
                let emoji = getWorkerEmoji(name)
                let status = name.contains("Kevin") ? "✅ EXPANDED + Rubin Museum (building ID 14)" : ""
                print("   \(emoji) \(name): \(count) buildings \(status)")
            }
            
            // Verify Kevin's expansion with Rubin Museum
            let kevinCount = results.first(where: {
                ($0["worker_name"] as? String)?.contains("Kevin") == true
            })?["building_count"] as? Int64 ?? 0
            
            if kevinCount >= 8 {
                print("✅ Kevin's expanded duties verified: \(kevinCount) buildings (including Rubin Museum)")
            } else {
                print("⚠️ WARNING: Kevin should have 8+ buildings, found \(kevinCount)")
            }
            
            // Specific Rubin Museum verification
            let rubinCheck = try await sqliteManager.query("""
                SELECT COUNT(*) as count FROM worker_building_assignments 
                WHERE worker_id = '4' AND building_id = '14' AND is_active = 1
            """)
            let rubinCount = rubinCheck.first?["count"] as? Int64 ?? 0
            if rubinCount > 0 {
                print("✅ PRESERVED: Kevin's Rubin Museum assignment verified (building ID 14)")
            } else {
                print("❌ PRESERVED: Kevin's Rubin Museum assignment MISSING")
            }
            
        } catch {
            print("⚠️ Could not generate assignment summary: \(error)")
        }
    }
    
    private func getWorkerEmoji(_ workerName: String) -> String {
        switch workerName {
        case "Greg Hutson": return "🔧"
        case "Edwin Lema": return "🧹"
        case "Kevin Dutan": return "⚡"  // Expanded duties + Rubin Museum
        case "Mercedes Inamagua": return "✨"
        case "Luis Lopez": return "🔨"
        case "Angel Guirachocha": return "🗑️"
        case "Shawn Magloire": return "🎨"
        default: return "👷"
        }
    }
    
    // MARK: - Helper Methods (Enhanced, NO FILE PARSING)
    
    /// Map worker names to IDs (current active workers only)
    private func mapWorkerNameToId(_ workerName: String) async throws -> Int {
        guard let sqliteManager = sqliteManager else {
            throw OperationalError.noSQLiteManager
        }
        
        // Block Jose Santos explicitly
        if workerName.contains("Jose") || workerName.contains("Santos") {
            throw OperationalError.workerNotFound("Jose Santos is no longer with the company")
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
        
        throw OperationalError.workerNotFound(workerName)
    }
    

    /// Enhanced building mapping using BuildingRepository
    private func mapBuildingNameToId(_ buildingName: String) async throws -> Int {
        if let idStr = await BuildingRepository.shared.id(forName: buildingName),
           let id = Int(idStr) {
            return id
        }
        throw OperationalError.buildingNotFound(buildingName)
    }
    
    /// Generate unique external ID for idempotency
    private func generateExternalId(for task: OperationalTaskAssignment, index: Int) -> String {
        let components = [
            task.building,
            task.taskName,
            task.assignedWorker,
            task.recurrence,
            task.daysOfWeek ?? "all",
            String(index)
        ]
        let combined = components.joined(separator: "|")
        return "OPERATIONAL-PRESERVED-\(combined.hashValue)-\(index)"
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
    
    // MARK: - ⭐ PRESERVED: Enhanced Logging (NO FILE PARSING)
    
    /// Log import results with corrected building IDs and Rubin Museum integration
    private func logImportResults(imported: Int, errors: [String]) async {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // Count Kevin's tasks specifically
        let kevinTasks = realWorldTasks.filter { $0.assignedWorker == "Kevin Dutan" }
        let kevinRubinTasks = kevinTasks.filter { $0.building.contains("Rubin") }
        
        var logContent = """
        OPERATIONAL DATA MANAGER - NO FILE PARSING - \(dateFormatter.string(from: Date()))
        ================================================================
        Total Records: \(realWorldTasks.count)
        Successfully Imported: \(imported)
        Errors: \(errors.count)
        
        🔧 PRESERVED CHANGES:
        • Jose Santos: REMOVED from all assignments
        • Kevin Dutan: EXPANDED to 8+ buildings (took Jose's duties)
        • Current Active Workers: 7 total (Greg, Edwin, Kevin, Mercedes, Luis, Angel, Shawn)
        • NO FILE PARSING: All data programmatic
        
        ✅ PRESERVED BUILDING IDs:
        • Kevin Rubin Museum tasks: \(kevinRubinTasks.count) tasks (building ID 14)
        • Rubin Museum building ID: 14 (PRESERVED from correct mapping)
        • Kevin's preserved reality: Works at Rubin Museum (NOT 104 Franklin)
        • All building ID conflicts resolved
        
        CURRENT ACTIVE WORKER TASK SUMMARY:
        - Kevin Dutan: \(kevinTasks.count) tasks 🔧 EXPANDED + Rubin Museum (\(kevinRubinTasks.count) Rubin tasks)
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
        
        Kevin's Building Coverage (PRESERVED):
        """
        
        let kevinBuildings = Set(kevinTasks.map { $0.building })
        for building in kevinBuildings.sorted() {
            let buildingTasks = kevinTasks.filter { $0.building == building }
            let rubinIndicator = building.contains("Rubin") ? " ✅ RUBIN MUSEUM (ID: 14)" : ""
            let buildingId = getBuildingIdFromName(building)
            logContent += "- \(building): \(buildingTasks.count) tasks (ID: \(buildingId))\(rubinIndicator)\n"
        }
        
        if !errors.isEmpty {
            logContent += "\nErrors:\n"
            for error in errors {
                logContent += "- \(error)\n"
            }
        }
        
        // Save to documents directory (no file parsing, but can still write logs)
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let logPath = documentsPath.appendingPathComponent("operational_data_manager_no_csv_log.txt")
            
            do {
                try logContent.write(to: logPath, atomically: true, encoding: .utf8)
                print("📝 Operational DataManager (no CSV parsing) import log saved to: \(logPath)")
            } catch {
                print("❌ Failed to save import log: \(error)")
            }
        }
        
        // Also save errors for review if any
        if !errors.isEmpty {
            await saveErrorsForReview(errors)
        }
    }
    
    /// Save errors for review
    private func saveErrorsForReview(_ errors: [String]) async {
        let errorContent = "Timestamp,Error\n" + errors.map { "\"\(Date())\",\"\($0)\"" }.joined(separator: "\n")
        
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let errorPath = documentsPath.appendingPathComponent("operational_data_manager_errors.txt")
            
            do {
                try errorContent.write(to: errorPath, atomically: true, encoding: .utf8)
                print("📊 OperationalDataManager error file saved to: \(errorPath)")
            } catch {
                print("❌ Failed to save error file: \(error)")
            }
        }
    }
    
    // MARK: - Validation and Summary Methods (NO FILE PARSING)
    
    func validateOperationalData() -> [String] {
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
            
            // Validate no Jose Santos
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
    
    func getTimeOfDayDistribution() -> [String: Int] {
        var distribution: [String: Int] = [:]
        
        for task in realWorldTasks {
            guard let startHour = task.startHour else { continue }
            
            let timeSlot: String
            switch startHour {
            case 0..<6:
                timeSlot = "Night (12AM-6AM)"
            case 6..<12:
                timeSlot = "Morning (6AM-12PM)"
            case 12..<18:
                timeSlot = "Afternoon (12PM-6PM)"
            case 18..<24:
                timeSlot = "Evening (6PM-12AM)"
            default:
                timeSlot = "Unknown"
            }
            
            distribution[timeSlot, default: 0] += 1
        }
        
        return distribution
    }
    
    func getCategoryDistribution() -> [String: Int] {
        var distribution: [String: Int] = [:]
        
        for task in realWorldTasks {
            distribution[task.category, default: 0] += 1
        }
        
        return distribution
    }
    
    func getRecurrenceDistribution() -> [String: Int] {
        var distribution: [String: Int] = [:]
        
        for task in realWorldTasks {
            distribution[task.recurrence, default: 0] += 1
        }
        
        return distribution
    }
    
    func getSkillLevelDistribution() -> [String: Int] {
        var distribution: [String: Int] = [:]
        
        for task in realWorldTasks {
            distribution[task.skillLevel, default: 0] += 1
        }
        
        return distribution
    }
    
    func getBuildingCoverage() -> [String: [String]] {
        var coverage: [String: [String]] = [:]
        
        for task in realWorldTasks {
            if coverage[task.building] == nil {
                coverage[task.building] = []
            }
            if !coverage[task.building]!.contains(task.assignedWorker) {
                coverage[task.building]!.append(task.assignedWorker)
            }
        }
        
        return coverage
    }
}

// MARK: - Error Types (Enhanced for OperationalDataManager)

enum OperationalError: LocalizedError {
    case noSQLiteManager
    case buildingNotFound(String)
    case workerNotFound(String)
    case inactiveWorker(String)
    
    var errorDescription: String? {
        switch self {
        case .noSQLiteManager:
            return "SQLiteManager not set on OperationalDataManager"
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
