#!/usr/bin/php
<?php 



###### could we check to see when the last real transaction is and then just replicate entires for everyone 
### between that date and the focusmonth ? ? 

# Start database interaction with
# localhost
# Sets the database access information as constants

define ('DB_USER', 'root');
define ('DB_PASSWORD','s3r3n1t33');
define ('DB_HOST','localhost');
define ('DB_NAME','SRG_Dev');

# Make the connection and then select the database
# display errors if fail
$dbc = mysqli_connect(DB_HOST, DB_USER, DB_PASSWORD)
	or die('Could not connect to mysql:'.MYSQLI_ERROR($dbc) );
mysqli_select_db($dbc, DB_NAME)
	OR die('Could not connect to the database:'.MYSQLI_ERROR($dbc));

### INIT Variables
$counter = 0;



//QUERY MASTER FOR CARDNUMBER
# NOT USING -- 	AND MOD(CardNumber, 200) = '0'
$query1 = "SELECT DISTINCT(CardNumber) FROM Master WHERE CardNumber IS NOT NULL ORDER BY CardNumber ASC";
$result1 = mysqli_query($dbc, $query1);
ECHO MYSQLI_ERROR($dbc);
while($row1 = mysqli_fetch_array($result1, MYSQLI_ASSOC)){
	$CardNumber_db = $row1['CardNumber'];
	
	$query2 = "SELECT MIN(TransactionDate) as MinDate from Master WHERE CardNumber = '$CardNumber_db'";
	$result2 = mysqli_query($dbc, $query2);
	ECHO MYSQLI_ERROR($dbc);
	while($row1 = mysqli_fetch_array($result2, MYSQLI_ASSOC)){
		$MinDate_db = $row1['MinDate'];
	}

	$query3 = "SELECT MAX(VisitsAccrued) as MaxAccrued FROM Master WHERE TransactionDate = '$MinDate_db' AND CardNumber = '$CardNumber_db'";
	$result3 = mysqli_query($dbc, $query3);
	ECHO MYSQLI_ERROR($dbc);
	while($row1 = mysqli_fetch_array($result3, MYSQLI_ASSOC)){
		$MaxAccrued_db = $row1['MaxAccrued'];
	}


	// VISIT ACCRUED ON FIRST TRANSACTIONDATE
	IF ($MaxAccrued_db > '0'){
			// SET CORRECT VM #'s FOR ENROLL DATE
			$query4 = "UPDATE Master SET Vm_VisitsAccrued = '0', Vm_VisitsBalance = '0' WHERE CardNumber = '$CardNumber_db' AND VisitsBalance IS NOT NULL 
						AND VisitsBalance != '0' AND Transactiondate = $MinDate";
			$result4 = mysqli_query($dbc, $query4);
			ECHO MYSQLI_ERROR($dbc);

			$query5 = "SELECT TransactionDate, MAX(VisitsBalance) as MaxBalance FROM Master WHERE CardNumber = '$CardNumber_db' AND TransactionDate > '$MinDate' GROUP BY TransactionDate";
			$result5 = mysqli_query($dbc, $query5);
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result5, MYSQLI_ASSOC)){
				$MaxBalance_db = $row1['MaxBalance'];
			}
			



	}




}

// we need to go through every visit for every card and if there was another visit on the same day, set all those visits to the same amount.
