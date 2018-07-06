#!/usr/bin/php
<?php


# Start databaase interaction with
# localhost
# Sets the database access information as constants

define ('DB_USER', 'root');
define ('DB_PASSWORD','s3r3n1t33');
define ('DB_HOST','localhost');
define ('DB_NAME','SRG_Dev');

# Make the connection and then select the database
# display errors if fail


$dbc = @mysql_connect(DB_HOST, DB_USER, DB_PASSWORD)
	or die('Could not connect to mysql:'.MYSQL_ERROR() );
@mysql_select_db(DB_NAME)
	OR die('Could not connect to the database:'.MYSQL_ERROR());

// TRUNCATE table Px_monthly_small"
ECHO 'Px_monthly_small TRUNCATED FOR FULL RUN!!!!!!';

//QUERY MASTER FOR CARDNUMBER
$Query1 = "SELECT DISTINCT(CardNumber), MAX(Vm_VisitsBalance), CURDATE()
					FROM Master
					WHERE CardNumber > '0'
					AND CardNumber IS NOT NULL 
					AND MOD(CardNumber, 8000) = '0'
					GROUP BY CardNumber	
					ORDER BY CardNumber ASC";
$result1 = mysql_query($query1);
ECHO MYSQL_ERROR();
while($row1 = mysql_fetch_array($result1, MYSQL_ASSOC)){
	$CardNumber_db = $row1['CardNumber'];
	$VisitBalance_db = $row1['Vm_VisitsBalance'];
	$CurrentDate_db = $row1['TodayDate'];
	

	$Query2 = "SELECT MAX(TransactionDate) as MaxDate, YEAR(MIN(TransactionDate)) as MinDateYear,
					 MONTH(MIN(TransactionDate)) as MinDateMonth, 
				FROM Master WHERE CardNumber = '$CardNumber_db'";
	$result2 = mysql_query($query2);	
	ECHO MYSQL_ERROR();
	while($row1 = mysql_fetch_array($result2, MYSQL_ASSOC)){	
		$MaxDate_db = $row1['MaxDate'];
		$MinDateMonth_db = $row1['MinDateMonth'];
		$MinDateYear_db = $row1['MinDateYear'];

	}
// FORMAT FOCUSDATE
	$FocusDate = $MinDateYear_db."-".$MinDateMonth_db."-01"; 
	$FocusDateEnd = strtotime($FocusDate '+1months -1 days');


	$Query3 = "SELECT FirstName, LastName, EnrollDate, Zip
				FROM Guests WHERE CardNumber = '$CardNumber_db'";
	$result3 = mysql_query($query3);	
	ECHO MYSQL_ERROR();
	while($row1 = mysql_fetch_array($result3, MYSQL_ASSOC)){	
		$FirstName_db = $row1['FirstName'];
		$LastName_db = $row1['LastName'];
		$EnrollDate_db = $row1['EnrollDate'];		
		$Zip_db = $row1['Zip'];
	}
// WHILE FOCUSDATE IS LESS THAN TODAYS DATE REPEAT QUERIES
WHILE ($FocusDate <= $CurrentDate_db){

	$Query4 = "SELECT MIN(TransactionDate) as TransMonth, 
			SUM(DollarsSpentAccrued) as DollarSpentMonth,
			SUM(SereniteePointsRedeemed) as PointsRedeemedMonth,
			SUM(SereniteePointsAccrued) as PointsAccruedMonth,
			SUM(VisitsAccrued) as VisitsAccruedMonth,                   
			FROM Master WHERE  CardNumber = '$CardNumber_db'
			AND DollarsSpentAccrued IS NOT NULL
			AND VisitsAccrued > '0'
			AND TransactionDate >= '$FocusDate'
			AND TransactionDate <= '$FocusDateEnd'";
	$result4 = mysql_query($query4);	
	ECHO MYSQL_ERROR();
	while($row1 = mysql_fetch_array($result4, MYSQL_ASSOC)){
		$TransMonth_db = $row1['TransMonth'];	
		$DollarsSpentMonth_db = $row1['DollarsSpentMonth'];
		$PointsRedeemedMonth_db = $row1['PointsRedeemedMonth'];
		$PointsAccruedMonth_db = $row1['PointsAccruedMonth'];
		$VisitsAccruedMonth_db = $row1['TransMonth'];
	}




ECHO $CardNumber_db;

// END OF WHILE FOCUSDATE LESS THAN TODAY
}
$FocusDate=strtotime($FocusDate' + 1 month');
$FocusDateEnd=strtotime($FocusDate' +1 month - 1 day');
// END OF CARD NUMBER WHILE LOOP
}
?>
