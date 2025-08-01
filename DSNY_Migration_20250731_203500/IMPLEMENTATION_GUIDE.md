# DSNY Migration Implementation Guide

## Quick Implementation (5 minutes)

### 1. Add Swift File to Xcode
- Drag `DSNYMigrationOneShot.swift` into your Xcode project
- Select "Copy items if needed"
- Add to target: FrancoSphere

### 2. Run Migration
Add this to your `InitializationView.swift` or `AppDelegate`:

```swift
// One-time DSNY migration
if !UserDefaults.standard.bool(forKey: "dsny_migration_completed") {
    Task {
        do {
            try await DSNYMigrationOneShot.migrate()
            UserDefaults.standard.set(true, forKey: "dsny_migration_completed")
        } catch {
            print("❌ DSNY migration failed: \(error)")
        }
    }
}
```

### 3. Verify Results
Run the app and check console for:
- "✅ Updated X DSNY tasks"
- Kevin's DSNY tasks list

### 4. Clean Up
After successful migration:
1. Delete `DSNYMigrationOneShot.swift` from project
2. Remove migration code from initialization
3. Delete this migration directory

## What Changed
- All trash-related tasks now use "DSNY:" prefix
- Category changed from "maintenance" to "sanitation"
- Standardized terminology across the app

## Verification Query
```sql
SELECT title, COUNT(*) as count, category
FROM routine_tasks
WHERE title LIKE 'DSNY:%'
GROUP BY title, category
ORDER BY title;
```
