#!/usr/bin/php
<?php 

// Use environment variables for database credentials
define('DB_USER', $_ENV['DB_USER'] ?? 'root');
define('DB_PASSWORD', $_ENV['DB_PASSWORD'] ?? 's3r3n1t33');
define('DB_HOST', $_ENV['DB_HOST'] ?? 'localhost');
define('DB_NAME', $_ENV['DB_NAME'] ?? 'SRG_Prod');

// Enhanced database connection with error handling
function connectDatabase() {
    $dbc = mysqli_connect(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);
    if (!$dbc) {
        die('Could not connect to database: ' . mysqli_connect_error());
    }
    
    // Set character set and enable buffering
    mysqli_set_charset($dbc, 'utf8');
    mysqli_query($dbc, "SET SESSION sql_mode = 'TRADITIONAL'");
    
    return $dbc;
}

$dbc = connectDatabase();

// Truncate table with transaction
mysqli_query($dbc, "START TRANSACTION");
mysqli_query($dbc, "TRUNCATE table Px_Monthly");
mysqli_query($dbc, "COMMIT");
echo "Px_Monthly TRUNCATED\n";

// MAJOR OPTIMIZATION: Single query to get all data at once
$mainQuery = "
SELECT 
    gm.CardNumber,
    gm.FirstName,
    gm.LastName,
    gm.EnrollDate,
    gm.Zip,
    gm.Tier,
    YEAR(gm.EnrollDate) as MinDateYear,
    DATE_FORMAT(gm.EnrollDate, '%m') as MinDateMonth,
    
    -- Lifetime totals (calculated once)
    COALESCE(SUM(m.DollarsSpentAccrued), 0) as DollarsSpentLife,
    COALESCE(SUM(m.SereniteePointsRedeemed), 0) as PointsRedeemedLife,
    COALESCE(SUM(m.SereniteePointsAccrued), 0) as PointsAccruedLife,
    COALESCE(MAX(m.VM_VisitsBalance), 0) as VisitsAccruedLife,
    
    -- Account status (fetch once)
    MAX(m.Account_status) as Account_status,
    MAX(m.Card_status) as Card_status
    
FROM Guests_Master gm
LEFT JOIN Master m ON gm.CardNumber = m.CardNumber
WHERE gm.CardNumber IS NOT NULL 
  AND gm.EnrollDate IS NOT NULL
GROUP BY gm.CardNumber, gm.FirstName, gm.LastName, gm.EnrollDate, gm.Zip, gm.Tier
ORDER BY gm.CardNumber ASC
";

$result = mysqli_query($dbc, $mainQuery);
if (!$result) {
    die("Main query failed: " . mysqli_error($dbc));
}

$counter = 0;
$batchInserts = [];
$batchSize = 1000;

while ($customerData = mysqli_fetch_assoc($result)) {
    $counter++;
    
    if ($counter % 1000 == 0) {
        echo "\nProcessed $counter customers: " . $customerData['CardNumber'];
    }
    
    $cardNumber = mysqli_real_escape_string($dbc, $customerData['CardNumber']);
    $firstName = mysqli_real_escape_string($dbc, $customerData['FirstName']);
    $lastName = mysqli_real_escape_string($dbc, $customerData['LastName']);
    
    // Skip test accounts early
    if (strtolower($lastName) == 'test' || strtolower($firstName) == 'serenitee') {
        continue;
    }
    
    $enrollDate = $customerData['EnrollDate'];
    $focusDate = $customerData['MinDateYear'] . '-' . str_pad($customerData['MinDateMonth'], 2, '0', STR_PAD_LEFT) . '-01';
    $currentDate = date('Y-m-d');
    
    // Generate monthly records using a single query with date generation
    $monthlyQuery = "
    WITH RECURSIVE date_series AS (
        SELECT '$focusDate' as focus_date
        UNION ALL
        SELECT DATE_ADD(focus_date, INTERVAL 1 MONTH)
        FROM date_series 
        WHERE focus_date < '$currentDate'
    ),
    monthly_stats AS (
        SELECT 
            ds.focus_date,
            
            -- Monthly totals
            COALESCE(ROUND(SUM(CASE 
                WHEN m.TransactionDate >= ds.focus_date 
                AND m.TransactionDate < DATE_ADD(ds.focus_date, INTERVAL 1 MONTH)
                AND m.DollarsSpentAccrued > 0
                THEN m.DollarsSpentAccrued END), 2), 0) as DollarsSpentMonth,
                
            COALESCE(SUM(CASE 
                WHEN m.TransactionDate >= ds.focus_date 
                AND m.TransactionDate < DATE_ADD(ds.focus_date, INTERVAL 1 MONTH)
                THEN m.SereniteePointsRedeemed END), 0) as PointsRedeemedMonth,
                
            COALESCE(SUM(CASE 
                WHEN m.TransactionDate >= ds.focus_date 
                AND m.TransactionDate < DATE_ADD(ds.focus_date, INTERVAL 1 MONTH)
                THEN m.SereniteePointsAccrued END), 0) as PointsAccruedMonth,
                
            COALESCE(SUM(CASE 
                WHEN m.TransactionDate >= ds.focus_date 
                AND m.TransactionDate < DATE_ADD(ds.focus_date, INTERVAL 1 MONTH)
                THEN m.Vm_VisitsAccrued END), 0) as VisitsAccruedMonth,
                
            -- Discounts calculation
            COALESCE(ROUND(SUM(CASE 
                WHEN m.TransactionDate >= ds.focus_date 
                AND m.TransactionDate < DATE_ADD(ds.focus_date, INTERVAL 1 MONTH)
                THEN (m.GrossSalesCoDefined - m.NetSalesCoDefined) END), 2), 0) as DiscountsMonth,
            
            -- Lifetime totals up to focus date
            COALESCE(ROUND(SUM(CASE 
                WHEN m.TransactionDate < ds.focus_date 
                THEN m.DollarsSpentAccrued END), 2), 0) as DollarsSpentLife,
                
            COALESCE(SUM(CASE 
                WHEN m.TransactionDate < ds.focus_date 
                THEN m.SereniteePointsRedeemed END), 0) as PointsRedeemedLife,
                
            COALESCE(SUM(CASE 
                WHEN m.TransactionDate < ds.focus_date 
                THEN m.SereniteePointsAccrued END), 0) as PointsAccruedLife,
            
            -- Visit metrics
            COUNT(CASE 
                WHEN m.TransactionDate >= DATE_SUB(ds.focus_date, INTERVAL 1 YEAR)
                AND m.TransactionDate < ds.focus_date
                AND m.TransactionDate != '$enrollDate'
                AND m.Vm_VisitsAccrued = 1
                THEN 1 END) as PrevYearVisitBal,
                
            MAX(CASE 
                WHEN m.TransactionDate <= ds.focus_date 
                AND m.VisitsAccrued = 1 
                THEN m.TransactionDate END) as LastVisitDate,
            
            -- Calculate program age and other metrics
            (TIMESTAMPDIFF(MONTH, '$enrollDate', ds.focus_date) + 1) as ProgAge,
            TIMESTAMPDIFF(MONTH, '$enrollDate', ds.focus_date) as MonthsEnrolled
            
        FROM date_series ds
        LEFT JOIN Master m ON m.CardNumber = '$cardNumber'
        GROUP BY ds.focus_date
    )
    SELECT 
        focus_date,
        DollarsSpentMonth,
        PointsRedeemedMonth,
        PointsAccruedMonth,
        VisitsAccruedMonth,
        DiscountsMonth,
        DollarsSpentLife,
        PointsRedeemedLife,
        PointsAccruedLife,
        PrevYearVisitBal,
        COALESCE(LastVisitDate, '$enrollDate') as LastVisitDate,
        DATEDIFF(focus_date, COALESCE(LastVisitDate, '$enrollDate')) as LapseDays,
        TIMESTAMPDIFF(MONTH, COALESCE(LastVisitDate, '$enrollDate'), focus_date) as LapseMonths,
        ProgAge,
        CASE 
            WHEN MonthsEnrolled > 0 AND MonthsEnrolled IS NOT NULL 
            THEN ROUND({$customerData['VisitsAccruedLife']} / MonthsEnrolled, 8)
            ELSE NULL 
        END as LifetimeFreq
    FROM monthly_stats
    ORDER BY focus_date
    ";
    
    $monthlyResult = mysqli_query($dbc, $monthlyQuery);
    if (!$monthlyResult) {
        echo "Monthly query failed for card $cardNumber: " . mysqli_error($dbc) . "\n";
        continue;
    }
    
    // Collect batch inserts
    while ($monthlyData = mysqli_fetch_assoc($monthlyResult)) {
        $batchInserts[] = "(
            '$cardNumber',
            '{$monthlyData['focus_date']}',
            '$firstName',
            '$lastName',
            '$enrollDate',
            '{$customerData['Zip']}',
            '{$customerData['Tier']}',
            '{$monthlyData['DiscountsMonth']}',
            '{$monthlyData['DollarsSpentMonth']}',
            '{$monthlyData['PointsRedeemedMonth']}',
            '{$monthlyData['PointsAccruedMonth']}',
            '{$monthlyData['VisitsAccruedMonth']}',
            '{$monthlyData['DollarsSpentLife']}',
            '{$monthlyData['PointsAccruedLife']}',
            '{$monthlyData['PointsRedeemedLife']}',
            '{$monthlyData['LastVisitDate']}',
            '{$monthlyData['LapseDays']}',
            NULL,
            '{$monthlyData['PrevYearVisitBal']}',
            '{$monthlyData['ProgAge']}',
            " . ($monthlyData['LifetimeFreq'] ? "'{$monthlyData['LifetimeFreq']}'" : 'NULL') . ",
            NULL,
            '{$monthlyData['LapseMonths']}',
            '{$customerData['Account_status']}',
            '{$customerData['Card_status']}',
            '{$customerData['VisitsAccruedLife']}'
        )";
        
        // Execute batch insert when we hit batch size
        if (count($batchInserts) >= $batchSize) {
            executeBatchInsert($dbc, $batchInserts);
            $batchInserts = [];
        }
    }
}

// Execute remaining batch inserts
if (!empty($batchInserts)) {
    executeBatchInsert($dbc, $batchInserts);
}

function executeBatchInsert($dbc, $values) {
    $insertQuery = "
    INSERT INTO Px_Monthly (
        CardNumber, FocusDate, FirstName, LastName, EnrollDate, Zip, Tier,
        Discounts, DollarsSpentMonth, PointsRedeemedMonth, PointsAccruedMonth,
        VisitsAccruedMonth, LifetimeSpendBalance, LifetimePointsBalance,
        LifetimePointsRedeemed, LastVisitDate, LapseDays, FreqRecentDays,
        `12MoVisitBalance`, ProgramAge, LifetimeFreq, RecentFreqMonths,
        LapseMonths, Account_status, Card_status, LifetimeVisitBalance
    ) VALUES " . implode(',', $values);
    
    $result = mysqli_query($dbc, $insertQuery);
    if (!$result) {
        echo "Batch insert failed: " . mysqli_error($dbc) . "\n";
    }
}

echo "\nProcessed $counter customers total\n";

// Close connection
mysqli_close($dbc);

?>

