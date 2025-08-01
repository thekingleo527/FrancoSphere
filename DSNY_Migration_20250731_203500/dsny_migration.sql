-- DSNY Terminology Migration SQL
-- Generated: 20250731_203500

-- Backup existing data
CREATE TABLE IF NOT EXISTS routine_tasks_backup_20250731_203500 AS SELECT * FROM routine_tasks;

-- Update all DSNY-related task titles
UPDATE routine_tasks 
SET 
    title = CASE 
        WHEN title = 'Trash Management - Evening' THEN 'DSNY: Set Out Trash'
        WHEN title = 'Trash Removal' THEN 'DSNY: Set Out Trash'
        WHEN title = 'Trash removal' THEN 'DSNY: Set Out Trash'
        WHEN title = 'Put Out Trash' THEN 'DSNY: Set Out Trash'
        WHEN title = 'DSNY Put-Out (after 20:00)' THEN 'DSNY: Set Out Trash'
        WHEN title = 'Bring in trash bins' THEN 'DSNY: Bring In Trash Bins'
        WHEN title = 'DSNY Prep / Move Bins' THEN 'DSNY: Bring In Trash Bins'
        WHEN title = 'Recycling Management' THEN 'DSNY: Set Out Recycling'
        WHEN title = 'Put Out Recycling' THEN 'DSNY: Set Out Recycling'
        WHEN title = 'DSNY Compliance' THEN 'DSNY: Compliance Check'
        WHEN title = 'Rubin Museum DSNY' THEN 'DSNY: Compliance Check'
        WHEN title = 'Rubin DSNY Operations' THEN 'DSNY: Compliance Check'
        WHEN title = 'DSNY Compliance Check' THEN 'DSNY: Compliance Check'
        ELSE title
    END,
    category = CASE
        WHEN (title LIKE '%Trash%' OR title LIKE '%DSNY%' OR title LIKE '%Recycling%') 
             AND category = 'maintenance'
        THEN 'sanitation'
        ELSE category
    END,
    updated_at = datetime('now')
WHERE 
    title LIKE '%Trash%' OR 
    title LIKE '%DSNY%' OR 
    title LIKE '%Recycling%' OR 
    title LIKE '%Sanitation%';

-- Report changes
SELECT 
    'Tasks updated' as report,
    COUNT(*) as count 
FROM routine_tasks 
WHERE title LIKE 'DSNY:%';
