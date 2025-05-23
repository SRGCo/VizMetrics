#!/usr/bin/php
<?php 
##### BEFORE PROCESSING LETS MAKE A BACK UP JUST IN CASE
# exec('mysqldump -uroot -ps3r3n1t33 SRG_Prod Px_Monthly > /home/ubuntu/db_files/PROD.Px_Monthly.$(date +%Y-%m-%d-%H.%M.%S).sql');
# echo 'PX MONTHLY TABLE BACKED UP';

function yrseg($pastvisitbal, $lifetimevisits) {
    if ($pastvisitbal == 0 && $lifetimevisits > 0) return 'Dropout';
    if ($pastvisitbal == 0 && $lifetimevisits == 0) return 'Zombie';
    if ($pastvisitbal >= 1 && $pastvisitbal <= 2) return '1-2';
    if ($pastvisitbal >= 3 && $pastvisitbal <= 4) return '3-4';
    if ($pastvisitbal >= 5 && $pastvisitbal <= 10) return '5-10';
    if ($pastvisitbal >= 11 && $pastvisitbal <= 25) return '11-25';
    if ($pastvisitbal >= 26) return '26+';
    return '';
}

// Database configuration
define('DB_USER', 'root');
define('DB_PASSWORD', 's3r3n1t33');
define('DB_HOST', 'localhost');
define('DB_NAME', 'SRG_Prod');

// Connect to database with improved error handling
$dbc = new mysqli(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);
if ($dbc->connect_error) {
    die('Connection failed: ' . $dbc->connect_error);
}

// Set charset for security
$dbc->set_charset('utf8');

// Initialize variables
$counter = 0;
$visit_count_total = 0;
$start_time = microtime(true);
$batch_size = 100; // Process cards in batches

echo "Starting processing...\n";

// Get total count for progress tracking
$count_query = "SELECT COUNT(DISTINCT CardNumber) as total FROM Px_Monthly WHERE CardNumber > '6000227902591219'";
$count_result = $dbc->query($count_query);
$total_cards = $count_result->fetch_assoc()['total'];
echo "Total cards to process: $total_cards\n";

// Process cards in batches to reduce memory usage
$offset = 0;
while ($offset < $total_cards) {
    // Get batch of card numbers with their basic info
    $card_query = "
        SELECT DISTINCT 
            CardNumber,
            MAX(LastVisitDate) as LastVisitDate,
            MAX(LifetimeVisitBalance) as VisitsAccruedLife,
            MAX(EnrollDate) as EnrollDate
        FROM Px_Monthly 
        WHERE CardNumber > '6000227902591219'
        GROUP BY CardNumber 
        ORDER BY CardNumber ASC 
        LIMIT $batch_size OFFSET $offset
    ";
    
    $card_result = $dbc->query($card_query);
    if (!$card_result) {
        die('Card query failed: ' . $dbc->error);
    }
    
    $card_numbers = [];
    $card_data = [];
    
    while ($row = $card_result->fetch_assoc()) {
        $card_number = $row['CardNumber'];
        $card_numbers[] = $card_number;
        $card_data[$card_number] = $row;
        $visit_count_total += $row['VisitsAccruedLife'];
    }
    
    if (empty($card_numbers)) {
        break;
    }
    
    // Create placeholders for IN clause
    $placeholders = str_repeat('?,', count($card_numbers) - 1) . '?';
    
    // Get all historical data for this batch in one query
    $history_query = "
        SELECT 
            CardNumber,
            FocusDate,
            12MoVisitBalance,
            LapseMonths,
            DATE_SUB(FocusDate, INTERVAL 1 MONTH) as date_1mo_back,
            DATE_SUB(FocusDate, INTERVAL 3 MONTH) as date_3mo_back,
            DATE_SUB(FocusDate, INTERVAL 1 YEAR) as date_12mo_back,
            DATE_SUB(FocusDate, INTERVAL 2 YEAR) as date_24mo_back,
            DATE_SUB(FocusDate, INTERVAL 3 YEAR) as date_36mo_back
        FROM Px_Monthly 
        WHERE CardNumber IN ($placeholders)
        ORDER BY CardNumber, FocusDate DESC
    ";
    
    $stmt = $dbc->prepare($history_query);
    if (!$stmt) {
        die('Prepare failed: ' . $dbc->error);
    }
    
    $types = str_repeat('s', count($card_numbers));
    $stmt->bind_param($types, ...$card_numbers);
    $stmt->execute();
    $history_result = $stmt->get_result();
    
    // Build lookup arrays for historical data
    $historical_data = [];
    while ($row = $history_result->fetch_assoc()) {
        $card_number = $row['CardNumber'];
        $focus_date = $row['FocusDate'];
        $historical_data[$card_number][$focus_date] = $row;
    }
    
    // Now get all the historical visit balances in one query
    $historical_visits_query = "
        SELECT 
            p1.CardNumber,
            p1.FocusDate,
            p1.12MoVisitBalance as current_balance,
            p2.12MoVisitBalance as balance_1mo_back,
            p3.12MoVisitBalance as balance_3mo_back,
            p4.12MoVisitBalance as balance_12mo_back,
            p4.LapseMonths as lapse_12mo_back,
            p5.12MoVisitBalance as balance_24mo_back,
            p6.12MoVisitBalance as balance_36mo_back
        FROM Px_Monthly p1
        LEFT JOIN Px_Monthly p2 ON p1.CardNumber = p2.CardNumber 
            AND p2.FocusDate = DATE_SUB(p1.FocusDate, INTERVAL 1 MONTH)
        LEFT JOIN Px_Monthly p3 ON p1.CardNumber = p3.CardNumber 
            AND p3.FocusDate = DATE_SUB(p1.FocusDate, INTERVAL 3 MONTH)
        LEFT JOIN Px_Monthly p4 ON p1.CardNumber = p4.CardNumber 
            AND p4.FocusDate = DATE_SUB(p1.FocusDate, INTERVAL 1 YEAR)
        LEFT JOIN Px_Monthly p5 ON p1.CardNumber = p5.CardNumber 
            AND p5.FocusDate = DATE_SUB(p1.FocusDate, INTERVAL 2 YEAR)
        LEFT JOIN Px_Monthly p6 ON p1.CardNumber = p6.CardNumber 
            AND p6.FocusDate = DATE_SUB(p1.FocusDate, INTERVAL 3 YEAR)
        WHERE p1.CardNumber IN ($placeholders)
        ORDER BY p1.CardNumber, p1.FocusDate DESC
    ";
    
    $stmt2 = $dbc->prepare($historical_visits_query);
    $stmt2->bind_param($types, ...$card_numbers);
    $stmt2->execute();
    $visits_result = $stmt2->get_result();
    
    // Prepare update statement
    $update_query = "
        UPDATE Px_Monthly SET
            12MoVisitBal_1MoBack = ?,
            12MoVisitBal_3MoBack = ?,
            12MoVisitBal_12MoBack = ?,
            12MoVisitBal_24MoBack = ?,
            12MoVisitBal_36MoBack = ?,
            12MoFreqSeg_1MoBack = ?,
            12MoFreqSeg_3MoBack = ?,
            12MoFreqSeg_12MoBack = ?,
            12MoFreqSeg_24MoBack = ?,
            12MoFreqSeg_36MoBack = ?,
            12MoFreqSeg = ?,
            LapseMo_12MoBack = ?
        WHERE CardNumber = ? AND FocusDate = ?
    ";
    
    $update_stmt = $dbc->prepare($update_query);
    if (!$update_stmt) {
        die('Update prepare failed: ' . $dbc->error);
    }
    
    // Process all the visit data and perform batch updates
    $updates = [];
    while ($row = $visits_result->fetch_assoc()) {
        $card_number = $row['CardNumber'];
        $focus_date = $row['FocusDate'];
        $visits_accrued_life = $card_data[$card_number]['VisitsAccruedLife'];
        
        // Get values with defaults
        $balance_1mo = $row['balance_1mo_back'] ?? 0;
        $balance_3mo = $row['balance_3mo_back'] ?? 0;
        $balance_12mo = $row['balance_12mo_back'] ?? 0;
        $balance_24mo = $row['balance_24mo_back'] ?? 0;
        $balance_36mo = $row['balance_36mo_back'] ?? 0;
        $current_balance = $row['current_balance'] ?? 0;
        $lapse_12mo = $row['lapse_12mo_back'] ?? 0;
        
        // Calculate frequency segments
        $freq_1mo = yrseg($balance_1mo, $visits_accrued_life);
        $freq_3mo = yrseg($balance_3mo, $visits_accrued_life);
        $freq_12mo = yrseg($balance_12mo, $visits_accrued_life);
        $freq_24mo = yrseg($balance_24mo, $visits_accrued_life);
        $freq_36mo = yrseg($balance_36mo, $visits_accrued_life);
        $freq_current = yrseg($current_balance, $visits_accrued_life);
        
        // Execute update
        $update_stmt->bind_param(
            'iiiisssssssis',
            $balance_1mo, $balance_3mo, $balance_12mo, $balance_24mo, $balance_36mo,
            $freq_1mo, $freq_3mo, $freq_12mo, $freq_24mo, $freq_36mo,
            $freq_current, $lapse_12mo, $card_number, $focus_date
        );
        
        if (!$update_stmt->execute()) {
            echo "Update failed for card $card_number, focus $focus_date: " . $update_stmt->error . "\n";
        }
        
        $counter++;
        
        // Progress reporting
        if ($counter % 25 == 0) {
            $run_time = microtime(true) - $start_time;
            $progress = round(($counter / $total_cards) * 100, 2);
            echo "\nProcessed: $counter/$total_cards ($progress%)";
            echo " | Last Card: $card_number";
            echo " | Runtime: " . round($run_time, 2) . "s";
            echo " | Total Visits: $visit_count_total";
        }
    }
    
    $stmt->close();
    $stmt2->close();
    $update_stmt->close();
    
    $offset += $batch_size;
}

$total_time = microtime(true) - $start_time;
echo "\n\nALL CARDS PAST FREQUENCY UPDATED FOR ALL FOCUSDATES\n";
echo "Total processing time: " . round($total_time, 2) . " seconds\n";
echo "Total records processed: $counter\n";
echo "Total visits counted: $visit_count_total\n";

##### AFTER WE FINISH ALL PROCESSING LETS MAKE A BACK UP JUST IN CASE
#exec('mysqldump -uroot -ps3r3n1t33 SRG_Prod Px_Monthly > /home/ubuntu/db_files/PROD.Px_Monthly.$(date +%Y-%m-%d-%H.%M.%S).sql');
#echo 'PX MONTHLY TABLE BACKED UP';

$dbc->close();
?>
