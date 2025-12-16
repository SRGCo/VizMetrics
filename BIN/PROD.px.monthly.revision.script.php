-- ============================================================================
-- MIGRATION SCRIPT: Fix Px_Monthly Table Structure
-- ============================================================================
-- This script migrates your current Px_Monthly table to the optimal structure
-- for the optimized PHP script to run efficiently.
--
-- CRITICAL ISSUES FOUND IN CURRENT STRUCTURE:
-- 1. Numeric fields stored as VARCHAR (huge performance problem!)
-- 2. CardNumber is BIGINT but should be VARCHAR
-- 3. Missing critical composite indexes
-- 4. Using latin1_swedish_ci instead of utf8mb4
-- 5. All fields allow NULL (should have defaults)
--
-- ESTIMATED TIME: 15-45 minutes depending on table size
-- DISK SPACE NEEDED: 2x current table size during migration
-- ============================================================================

-- SAFETY CHECKS - RUN THESE FIRST!
-- ============================================================================

-- 1. Check current table size
SELECT 
    TABLE_NAME,
    TABLE_ROWS as Estimated_Rows,
    ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) as Size_MB,
    ROUND(DATA_FREE / 1024 / 1024, 2) as Fragmented_MB
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'SRG_Prod' AND TABLE_NAME = 'Px_Monthly';

-- 2. Check available disk space (need 2x table size)
-- Run in terminal: df -h /var/lib/mysql

-- 3. BACKUP THE TABLE FIRST! (CRITICAL!)
-- Option A: Full backup
-- mysqldump -uroot -ps3r3n1t33 SRG_Prod Px_Monthly > /tmp/Px_Monthly_backup_$(date +%Y%m%d_%H%M%S).sql

-- Option B: Create copy in database (faster, but uses disk space)
CREATE TABLE Px_Monthly_backup_20241215 AS SELECT * FROM Px_Monthly;
-- Verify: SELECT COUNT(*) FROM Px_Monthly_backup_20241215;


-- ============================================================================
-- MIGRATION APPROACH: Safe Rename Method
-- ============================================================================
-- We'll create a new optimized table, copy data, then swap tables.
-- This is safer than ALTER TABLE and allows easy rollback.

-- Step 1: Create new optimized table structure
-- ============================================================================

CREATE TABLE `Px_Monthly_new` (
  `row_id` INT(11) NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  
  -- Customer identifiers (FIXED: CardNumber should be VARCHAR, not BIGINT!)
  `CardNumber` VARCHAR(50) NOT NULL COMMENT 'Customer card number',
  `FocusDate` DATE NOT NULL COMMENT 'First day of month for this snapshot',
  
  -- Customer demographics
  `FirstName` VARCHAR(100) DEFAULT NULL,
  `LastName` VARCHAR(100) DEFAULT NULL,
  `EnrollDate` DATE NOT NULL,
  `Zip` VARCHAR(20) DEFAULT NULL,
  `Tier` VARCHAR(50) DEFAULT NULL,
  
  -- Monthly metrics (FIXED: Changed from VARCHAR to proper numeric types!)
  `DollarsSpentMonth` DECIMAL(10,2) DEFAULT 0.00,
  `PointsRedeemedMonth` INT DEFAULT 0,  -- Was VARCHAR(9)!
  `PointsAccruedMonth` INT DEFAULT 0,   -- Was VARCHAR(9)!
  `VisitsAccruedMonth` INT DEFAULT 0,   -- Was VARCHAR(9)!
  
  -- Lifetime metrics (FIXED: Changed from VARCHAR to INT!)
  `LifetimeSpendBalance` DECIMAL(12,2) DEFAULT 0.00,
  `LifetimePointsBalance` INT DEFAULT 0,     -- Was VARCHAR(9)!
  `LifetimePointsRedeemed` INT DEFAULT 0,    -- Was VARCHAR(9)!
  `LifetimeVisitBalance` INT DEFAULT 0,      -- Was VARCHAR(9)!
  
  -- Visit tracking (FIXED: Changed from VARCHAR to proper types!)
  `LastVisitDate` DATE DEFAULT NULL,
  `LapseDays` INT DEFAULT 0,              -- Was VARCHAR(9)!
  `LapseMonths` INT DEFAULT 0,            -- Was VARCHAR(5)!
  `FreqRecentDays` INT DEFAULT NULL,      -- Was VARCHAR(9)!
  
  -- Frequency metrics (FIXED: Changed from VARCHAR to INT!)
  `12MoVisitBalance` INT DEFAULT 0,       -- Was VARCHAR(9)! This is critical!
  `ProgramAge` INT DEFAULT 0,             -- Was VARCHAR(5)!
  `LifetimeFreq` DECIMAL(10,8) DEFAULT NULL,  -- Was VARCHAR(11)!
  `RecentFreqMonths` INT DEFAULT NULL,    -- Was VARCHAR(11)!
  
  -- Historical lookback values (FIXED: Changed from VARCHAR to INT!)
  `12MoVisitBal_1MoBack` INT DEFAULT 0,   -- Was VARCHAR(5)!
  `12MoVisitBal_3MoBack` INT DEFAULT 0,   -- Was VARCHAR(5)!
  `12MoVisitBal_12MoBack` INT DEFAULT 0,  -- Was VARCHAR(5)!
  `12MoVisitBal_24MoBack` INT DEFAULT 0,  -- Was VARCHAR(5)!
  `12MoVisitBal_36MoBack` INT DEFAULT 0,  -- Was VARCHAR(5)!
  `LapseMo_12MoBack` INT DEFAULT 0,       -- Was VARCHAR(5)!
  
  -- Frequency segments (these stay as VARCHAR)
  `12MoFreqSeg` VARCHAR(20) DEFAULT NULL,
  `12MoFreqSeg_1MoBack` VARCHAR(20) DEFAULT NULL,
  `12MoFreqSeg_3MoBack` VARCHAR(20) DEFAULT NULL,
  `12MoFreqSeg_12MoBack` VARCHAR(20) DEFAULT NULL,
  `12MoFreqSeg_24MoBack` VARCHAR(20) DEFAULT NULL,
  `12MoFreqSeg_36MoBack` VARCHAR(20) DEFAULT NULL,
  
  -- Additional metrics
  `Discounts` DECIMAL(10,2) DEFAULT 0.00,
  `Account_status` VARCHAR(20) DEFAULT NULL,
  `Card_status` VARCHAR(20) DEFAULT NULL,
  
  -- Metadata
  `Created` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `Modified` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- PRIMARY KEY
  PRIMARY KEY (`row_id`),
  
  -- CRITICAL: Unique constraint on CardNumber + FocusDate
  UNIQUE KEY `idx_unique_card_focus` (`CardNumber`, `FocusDate`),
  
  -- CRITICAL INDEXES for performance
  KEY `idx_card_focus` (`CardNumber`, `FocusDate`),
  KEY `idx_focus_card` (`FocusDate`, `CardNumber`),
  KEY `idx_focus_date` (`FocusDate`),
  KEY `idx_card_number` (`CardNumber`),
  
  -- Indexes for common queries
  KEY `idx_enroll_focus` (`EnrollDate`, `FocusDate`),
  KEY `idx_tier_focus` (`Tier`, `FocusDate`),
  KEY `idx_freq_seg` (`12MoFreqSeg`, `FocusDate`),
  KEY `idx_last_visit` (`LastVisitDate`),
  
  -- Covering index for analytics
  KEY `idx_analytics_covering` (`FocusDate`, `CardNumber`, `Tier`, 
      `12MoFreqSeg`, `DollarsSpentMonth`, `VisitsAccruedMonth`,
      `LifetimeSpendBalance`, `LifetimeVisitBalance`)
  
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Optimized monthly customer snapshots';


-- Step 2: Copy data from old table to new (with type conversions)
-- ============================================================================
-- This handles the VARCHAR -> INT conversions safely

INSERT INTO Px_Monthly_new (
    row_id,
    CardNumber,
    FocusDate,
    FirstName,
    LastName,
    EnrollDate,
    Zip,
    Tier,
    DollarsSpentMonth,
    PointsRedeemedMonth,
    PointsAccruedMonth,
    VisitsAccruedMonth,
    LifetimeSpendBalance,
    LifetimePointsBalance,
    LifetimePointsRedeemed,
    LifetimeVisitBalance,
    LastVisitDate,
    LapseDays,
    LapseMonths,
    FreqRecentDays,
    `12MoVisitBalance`,
    ProgramAge,
    LifetimeFreq,
    RecentFreqMonths,
    `12MoVisitBal_1MoBack`,
    `12MoVisitBal_3MoBack`,
    `12MoVisitBal_12MoBack`,
    `12MoVisitBal_24MoBack`,
    `12MoVisitBal_36MoBack`,
    `12MoFreqSeg_1MoBack`,
    `12MoFreqSeg_3MoBack`,
    `12MoFreqSeg_12MoBack`,
    `12MoFreqSeg_24MoBack`,
    `12MoFreqSeg_36MoBack`,
    `12MoFreqSeg`,
    LapseMo_12MoBack,
    Discounts,
    Account_status,
    Card_status
)
SELECT 
    row_id,
    CAST(CardNumber AS CHAR(50)) as CardNumber,  -- Convert BIGINT to VARCHAR
    FocusDate,
    FirstName,
    LastName,
    EnrollDate,
    Zip,
    Tier,
    COALESCE(DollarsSpentMonth, 0),
    
    -- Convert VARCHAR to INT (handle NULLs and empty strings)
    CAST(COALESCE(NULLIF(TRIM(PointsRedeemedMonth), ''), '0') AS UNSIGNED),
    CAST(COALESCE(NULLIF(TRIM(PointsAccruedMonth), ''), '0') AS UNSIGNED),
    CAST(COALESCE(NULLIF(TRIM(VisitsAccruedMonth), ''), '0') AS UNSIGNED),
    
    COALESCE(LifetimeSpendBalance, 0),
    CAST(COALESCE(NULLIF(TRIM(LifetimePointsBalance), ''), '0') AS UNSIGNED),
    CAST(COALESCE(NULLIF(TRIM(LifetimePointsRedeemed), ''), '0') AS UNSIGNED),
    CAST(COALESCE(NULLIF(TRIM(LifetimeVisitBalance), ''), '0') AS UNSIGNED),
    
    LastVisitDate,
    CAST(COALESCE(NULLIF(TRIM(LapseDays), ''), '0') AS SIGNED),
    CAST(COALESCE(NULLIF(TRIM(LapseMonths), ''), '0') AS SIGNED),
    CAST(NULLIF(TRIM(FreqRecentDays), '') AS SIGNED),
    
    -- CRITICAL: This field is used heavily in Part 2!
    CAST(COALESCE(NULLIF(TRIM(`12MoVisitBalance`), ''), '0') AS UNSIGNED),
    
    CAST(COALESCE(NULLIF(TRIM(ProgramAge), ''), '0') AS UNSIGNED),
    CAST(NULLIF(TRIM(LifetimeFreq), '') AS DECIMAL(10,8)),
    CAST(NULLIF(TRIM(RecentFreqMonths), '') AS UNSIGNED),
    
    CAST(COALESCE(NULLIF(TRIM(12MoVisitBal_1MoBack), ''), '0') AS UNSIGNED),
    CAST(COALESCE(NULLIF(TRIM(12MoVisitBal_3MoBack), ''), '0') AS UNSIGNED),
    CAST(COALESCE(NULLIF(TRIM(12MoVisitBal_12MoBack), ''), '0') AS UNSIGNED),
    CAST(COALESCE(NULLIF(TRIM(12MoVisitBal_24MoBack), ''), '0') AS UNSIGNED),
    CAST(COALESCE(NULLIF(TRIM(12MoVisitBal_36MoBack), ''), '0') AS UNSIGNED),
    
    12MoFreqSeg_1MoBack,
    12MoFreqSeg_3MoBack,
    12MoFreqSeg_12MoBack,
    12MoFreqSeg_24MoBack,
    12MoFreqSeg_36MoBack,
    `12MoFreqSeg`,
    
    CAST(COALESCE(NULLIF(TRIM(LapseMo_12MoBack), ''), '0') AS UNSIGNED),
    COALESCE(Discounts, 0),
    Account_status,
    Card_status
FROM Px_Monthly;

-- Progress check
SELECT 
    'Original' as Table_Name, COUNT(*) as Row_Count 
FROM Px_Monthly
UNION ALL
SELECT 
    'New' as Table_Name, COUNT(*) as Row_Count 
FROM Px_Monthly_new;

-- Should show same count!


-- Step 3: Verify data integrity
-- ============================================================================

-- Check for data conversion issues
SELECT 'Checking numeric conversions...' as Status;

SELECT 
    COUNT(*) as Total_Rows,
    SUM(CASE WHEN PointsRedeemedMonth IS NULL THEN 1 ELSE 0 END) as Null_PointsRedeemed,
    SUM(CASE WHEN VisitsAccruedMonth IS NULL THEN 1 ELSE 0 END) as Null_Visits,
    SUM(CASE WHEN `12MoVisitBalance` IS NULL THEN 1 ELSE 0 END) as Null_12MoBalance
FROM Px_Monthly_new;

-- Sample data comparison
SELECT 'Sample comparison - Old vs New' as Status;
SELECT * FROM Px_Monthly 
WHERE CardNumber IS NOT NULL 
ORDER BY RAND() 
LIMIT 5;

SELECT * FROM Px_Monthly_new 
WHERE CardNumber IS NOT NULL 
ORDER BY RAND() 
LIMIT 5;


-- Step 4: Atomic table swap
-- ============================================================================
-- This renames tables atomically - no downtime

START TRANSACTION;

-- Rename old table to archive
RENAME TABLE Px_Monthly TO Px_Monthly_old;

-- Rename new table to production
RENAME TABLE Px_Monthly_new TO Px_Monthly;

COMMIT;

-- Verify
SELECT 'Px_Monthly' as Table_Name, COUNT(*) as Rows FROM Px_Monthly;
SHOW CREATE TABLE Px_Monthly\G


-- Step 5: Update Guests_Master and Master tables
-- ============================================================================
-- These also need index optimization

-- Guests_Master: Add missing indexes
ALTER TABLE Guests_Master
ADD INDEX IF NOT EXISTS idx_enroll_date (EnrollDate),
ADD INDEX IF NOT EXISTS idx_card_lookup (CardNumber),
ADD INDEX IF NOT EXISTS idx_name_filter (LastName, FirstName);

-- Verify CardNumber type in Guests_Master
SHOW CREATE TABLE Guests_Master;
-- If CardNumber is BIGINT, it should match Px_Monthly (VARCHAR)
-- If needed: ALTER TABLE Guests_Master MODIFY CardNumber VARCHAR(50);


-- Master table: Add critical covering index
ALTER TABLE Master
ADD INDEX IF NOT EXISTS idx_card_trans_covering (
    CardNumber, 
    TransactionDate, 
    DollarsSpentAccrued, 
    SereniteePointsAccrued, 
    SereniteePointsRedeemed,
    Vm_VisitsAccrued, 
    GrossSalesCoDefined, 
    NetSalesCoDefined
);

-- Verify Master table structure
SHOW CREATE TABLE Master;


-- Step 6: Analyze new tables for optimizer
-- ============================================================================

ANALYZE TABLE Px_Monthly;
ANALYZE TABLE Guests_Master;
ANALYZE TABLE Master;


-- Step 7: Verify indexes are being used
-- ============================================================================

-- Test query performance
EXPLAIN SELECT 
    CardNumber, FocusDate, `12MoVisitBalance`
FROM Px_Monthly
WHERE CardNumber = '1234567890'
ORDER BY FocusDate;
-- Should show "Using index condition" or "Using where"

EXPLAIN SELECT 
    CardNumber,
    FocusDate,
    LAG(`12MoVisitBalance`, 1) OVER (PARTITION BY CardNumber ORDER BY FocusDate) as bal_1mo
FROM Px_Monthly
WHERE CardNumber IN (SELECT DISTINCT CardNumber FROM Px_Monthly LIMIT 100);
-- Should show efficient index usage


-- ============================================================================
-- CLEANUP (Optional - after verifying everything works)
-- ============================================================================

-- Wait 24-48 hours and verify the optimized script runs successfully
-- Then you can drop the old table:

-- DROP TABLE Px_Monthly_old;

-- If you created a backup table:
-- DROP TABLE Px_Monthly_backup_20241215;


-- ============================================================================
-- ROLLBACK PROCEDURE (If something goes wrong)
-- ============================================================================

/*
-- If you need to rollback:

START TRANSACTION;
DROP TABLE Px_Monthly;
RENAME TABLE Px_Monthly_old TO Px_Monthly;
COMMIT;

-- Or restore from backup:
-- mysql -uroot -ps3r3n1t33 SRG_Prod < /tmp/Px_Monthly_backup_YYYYMMDD_HHMMSS.sql
*/


-- ============================================================================
-- VERIFICATION CHECKLIST
-- ============================================================================

-- [ ] Table row counts match (old vs new)
-- [ ] Sample data looks correct (numeric values not truncated)
-- [ ] All indexes created successfully
-- [ ] EXPLAIN shows index usage
-- [ ] CardNumber type is VARCHAR(50)
-- [ ] Numeric fields are INT/DECIMAL (not VARCHAR)
-- [ ] No unexpected NULLs in critical fields
-- [ ] Backup exists and is accessible
-- [ ] Optimized PHP script tested with new structure


-- ============================================================================
-- PERFORMANCE COMPARISON
-- ============================================================================

-- Before migration: Check index sizes
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    ROUND(STAT_VALUE * @@innodb_page_size / 1024 / 1024, 2) as Size_MB
FROM mysql.innodb_index_stats
WHERE DATABASE_NAME = 'SRG_Prod'
  AND TABLE_NAME = 'Px_Monthly'
  AND STAT_NAME = 'size'
ORDER BY STAT_VALUE DESC;

-- After migration: Much better index utilization expected


-- ============================================================================
-- SUMMARY OF CHANGES
-- ============================================================================

/*
CRITICAL FIXES APPLIED:

1. DATA TYPE CORRECTIONS (MAJOR PERFORMANCE IMPACT):
   - CardNumber: BIGINT(16) → VARCHAR(50)
   - PointsRedeemedMonth: VARCHAR(9) → INT
   - PointsAccruedMonth: VARCHAR(9) → INT
   - VisitsAccruedMonth: VARCHAR(9) → INT
   - LifetimePointsBalance: VARCHAR(9) → INT
   - LifetimePointsRedeemed: VARCHAR(9) → INT
   - LifetimeVisitBalance: VARCHAR(9) → INT
   - LapseDays: VARCHAR(9) → INT
   - LapseMonths: VARCHAR(5) → INT
   - 12MoVisitBalance: VARCHAR(9) → INT *** CRITICAL ***
   - ProgramAge: VARCHAR(5) → INT
   - LifetimeFreq: VARCHAR(11) → DECIMAL(10,8)
   - All lookback fields: VARCHAR(5) → INT

2. INDEX ADDITIONS:
   ✓ UNIQUE idx_unique_card_focus (CardNumber, FocusDate)
   ✓ idx_card_focus (CardNumber, FocusDate)
   ✓ idx_focus_card (FocusDate, CardNumber)
   ✓ idx_focus_date (FocusDate)
   ✓ idx_analytics_covering (composite covering index)

3. CHARACTER SET:
   - Changed from latin1_swedish_ci → utf8mb4_unicode_ci

4. DEFAULT VALUES:
   - Added appropriate defaults (0 for numerics, NULL for dates)

EXPECTED PERFORMANCE IMPROVEMENTS:
- Part 1: 5-10x faster (proper indexes + data types)
- Part 2: 20-40x faster (INT operations vs VARCHAR, window function indexes)
- Overall: 15-25x faster total runtime

WHY VARCHAR FOR NUMBERS WAS SO BAD:
- Cannot use numeric indexes efficiently
- String comparison is 10-100x slower than integer comparison
- CAST operations needed on every row
- Window functions (LAG) much slower on strings
- Aggregations (SUM, AVG) require conversion
- More disk space (VARCHAR overhead)
*/

-- End of migration script
