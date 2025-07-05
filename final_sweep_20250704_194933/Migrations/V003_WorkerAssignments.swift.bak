import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import SQLite
// FrancoSphere Types Import
// (This comment helps identify our import)


struct V003_WorkerAssignments {
    
    func run() async throws {
        // Use SQLiteManager's public execute method instead
        let manager = SQLiteManager.shared
        
        // Create worker_assignments table
        try await manager.execute("""
            CREATE TABLE IF NOT EXISTS worker_assignments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id INTEGER NOT NULL,
                building_id INTEGER NOT NULL,
                assigned_date TEXT DEFAULT CURRENT_TIMESTAMP,
                is_primary INTEGER DEFAULT 0,
                UNIQUE(worker_id, building_id)
            );
        """)
        
        // Edwin's exact buildings from CSV
        let edwinAssignments = [
            (workerId: 3, buildingId: 17, isPrimary: true),  // Stuyvesant Park
            (workerId: 3, buildingId: 16, isPrimary: false), // 133 E 15th
            (workerId: 3, buildingId: 4, isPrimary: false),  // 131 Perry
            (workerId: 3, buildingId: 8, isPrimary: false),  // 138 W 17th
            (workerId: 3, buildingId: 10, isPrimary: false), // 135-139 W 17th
            (workerId: 3, buildingId: 12, isPrimary: false), // 117 W 17th
            (workerId: 3, buildingId: 15, isPrimary: false), // 112 W 18th
            (workerId: 3, buildingId: 1, isPrimary: false)   // FrancoSphere HQ
        ]
        
        // Insert Edwin's assignments
        for assignment in edwinAssignments {
                    try await manager.execute("""
                        INSERT OR IGNORE INTO worker_assignments 
                        (worker_id, building_id, is_primary) 
                        VALUES (?, ?, ?)
                    """, [assignment.workerId, assignment.buildingId, assignment.isPrimary])
                }
                
                print("✅ V003_WorkerAssignments migration completed")
            }
        }

// Add ISO8601 formatter extension if not exists
extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
