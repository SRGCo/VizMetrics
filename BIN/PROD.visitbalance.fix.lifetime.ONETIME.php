#!/usr/bin/php
<?php 

# Start database interaction with
# localhost
# Sets the database access information as constants

define ('DB_USER', 'root');
define ('DB_PASSWORD','s3r3n1t33');
define ('DB_HOST','localhost');
define ('DB_NAME','SRG_Prod');

# Make the connection and then select the database
# display errors if fail
$dbc = mysqli_connect(DB_HOST, DB_USER, DB_PASSWORD)
	or die('Could not connect to mysql:'.MYSQLI_ERROR($dbc) );
mysqli_select_db($dbc, DB_NAME)
	OR die('Could not connect to the database:'.MYSQLI_ERROR($dbc));

### INIT Variables
$counter = 0;
$Fixed_counter = 0;

// QUERY MASTER FOR ALL CARDNUMBERS
// ***** SHOULD RUN A UBER VERSION OF THIS FIX THAT CHECKS ALL CARDS *****
$query1 = "SELECT DISTINCT(CardNumber), EnrollDate FROM Master WHERE CardNumber IS NOT NULL AND CardNumber > '6000227905852386' ORDER BY CardNumber ASC";
$result1 = mysqli_query($dbc, $query1);
ECHO MYSQLI_ERROR($dbc);
while($row1 = mysqli_fetch_array($result1, MYSQLI_ASSOC)){
	$CardNumber_db = $row1['CardNumber'];
	$EnrollDate_db = $row1['EnrollDate'];
	$counter ++;

	### WE GET DATES OF VISITS MORE RECENT THAN ENROLLMENT DATE

	$query2 = "SELECT TransactionDate as FocusDate from Master WHERE CardNumber = '$CardNumber_db' AND TransactionDate > '$EnrollDate_db' ORDER BY TransactionDate ASC";
	$result2 = mysqli_query($dbc, $query2);
	ECHO MYSQLI_ERROR($dbc);
	while($row1 = mysqli_fetch_array($result2, MYSQLI_ASSOC)){
		$FocusDate_db = $row1['FocusDate'];
		# ECHO $query2.PHP_EOL;
		// WE WILL PROCESS ONE TRANSACTIONDATE AT A TIME UPDATING ALL (ESPECIALLY NULLS/O) TO MAX VISITBALANCE FOR THAT DATE
		### FIRST WE THE LARGEST VM VISITBALANCE ON THE DATE WE ARE WORKING WITH FOR THAT ACCOUNT
		$query3 = "SELECT MAX(Vm_VisitsBalance) as MaxBal FROM Master WHERE TransactionDate = '$FocusDate_db' AND CardNumber = '$CardNumber_db'";
		$result3 = mysqli_query($dbc, $query3);
		ECHO MYSQLI_ERROR($dbc);
		while($row1 = mysqli_fetch_array($result3, MYSQLI_ASSOC)){
			$MaxBal_db = $row1['MaxBal'];
			// ERROR CHECK FOR 0 MAX VISITBALANCES
			IF ($MaxBal_db < '1'){ 
				# echo $CardNumber_db.' This card had a '.$MaxBal_db.' vm_visitsbalance as its max on '.$FocusDate_db.' we will try to update to last max'.PHP_EOL;
				## SINCE THIS CARD HAD VISITBALANCE LESS THAN 1 ON THIS DATE WE LOOK BACK THROUGH EARLIER TRANSACTIONS FOR THE HIGHEST/MAX (PREVIOUS) BALANCE
				$query3a = "SELECT MAX(Vm_VisitsBalance) as MaxBalLast FROM Master WHERE TransactionDate < '$FocusDate_db' AND CardNumber = '$CardNumber_db'";
				$result3a = mysqli_query($dbc, $query3a);
				ECHO MYSQLI_ERROR($dbc);
				while($row1 = mysqli_fetch_array($result3a, MYSQLI_ASSOC)){
					$MaxBalLast_db = $row1['MaxBalLast'];
					IF($MaxBalLast_db == ''){$MaxBalLast_db = '0';}
					IF($MaxBalLast_db != '0'){	
						echo '*********'.$CardNumber_db.' This card had a '.$MaxBal_db.' vm_visitsbalance as its max on '.$FocusDate_db.' it is now '.$MaxBalLast_db.PHP_EOL;
						$Fixed_counter ++;
					}
					$query4 = "UPDATE Master SET Vm_VisitsBalance = '$MaxBalLast_db' WHERE CardNumber = '$CardNumber_db' AND Transactiondate = '$FocusDate_db'";
					$result4 = mysqli_query($dbc, $query4);
					ECHO MYSQLI_ERROR($dbc);
				}
			} ELSE {
				## IN THIS CASE THE MAX VISITBALANCE WAS AT LEAST 1 FOR THIS DATE
				// WE WILL UPDATE ALL ROWS ON THIS DATE TO MAX VISITBALANCE
				$query4a = "UPDATE Master SET Vm_VisitsBalance = '$MaxBal_db' WHERE CardNumber = '$CardNumber_db' AND Transactiondate = '$FocusDate_db'";
				$result4a = mysqli_query($dbc, $query4a);
				ECHO MYSQLI_ERROR($dbc);
			}
		}
	}
}
ECHO 'Cards processed:'.$counter.' ********* Visit balances fixed:'.$Fixed_counter.PHP_EOL;

