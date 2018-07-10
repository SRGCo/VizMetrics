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

$counter = 0;
$dbc = mysqli_connect(DB_HOST, DB_USER, DB_PASSWORD)
	or die('Could not connect to mysql:'.MYSQLI_ERROR($dbc) );
mysqli_select_db($dbc, DB_NAME)
	OR die('Could not connect to the database:'.MYSQLI_ERROR($dbc));

// TRUNCATE table Px_monthly_small"
ECHO 'Px_monthly_small TRUNCATED FOR FULL RUN!!!!!!';

//QUERY MASTER FOR CARDNUMBER
$query1 = "SELECT DISTINCT(CardNumber) as CardNumber FROM Master
					WHERE CardNumber > '0'
					AND CardNumber IS NOT NULL 
					AND MOD(CardNumber, 8000) = '0'
					GROUP BY CardNumber	
					ORDER BY CardNumber ASC";
$result1 = mysqli_query($dbc, $query1);
ECHO MYSQLI_ERROR($dbc);
while($row1 = mysqli_fetch_array($result1, MYSQLI_ASSOC)){
	$CardNumber_db = $row1['CardNumber'];
	ECHO $counter++.'  card:';
	ECHO $CardNumber_db;
	$query2 = "SELECT MAX(TransactionDate) as MaxDate, 
				YEAR(MIN(TransactionDate)) as MinDateYear,
				MONTH(MIN(TransactionDate)) as MinDateMonth, 
				MAX(Vm_VisitsBalance) as Vm_VisitsBalance, 
				CURDATE() as TodayDate 
				FROM Master WHERE CardNumber = '$CardNumber_db'";
	$result2 = mysqli_query($dbc, $query2);	
	ECHO MYSQLI_ERROR($dbc);
	while($row1 = mysqli_fetch_array($result2, MYSQLI_ASSOC)){	
		$MaxDate_db = $row1['MaxDate'];
		$MinDateMonth_db = $row1['MinDateMonth'];
		$MinDateYear_db = $row1['MinDateYear'];
		$VisitBalance_db = $row1['Vm_VisitsBalance'];
		$CurrentDate_db = $row1['TodayDate'];

		// FORMAT FOCUSDATE
		$FocusDate = $MinDateYear_db."-".$MinDateMonth_db."-01"; 
		ECHO $FocusDate;
		$FocusDateEnd = date("m",strtotime($FocusDate."+1 month -1 day"));
		ECHO 'FDend:'.$FocusDateEnd;
		ECHO $MaxDate_db.' '.$MinDateMonth_db.' '.$MinDateYear_db.' '.$VisitBalance_db.' '.$CurrentDate_db.' '.$FocusDate;

		$query3 = "SELECT FirstName, LastName, EnrollDate, Zip
				FROM Guests WHERE CardNumber = '$CardNumber_db'";
		$result3 = mysqli_query($dbc, $query3);	
		ECHO MYSQLI_ERROR($dbc);
		while($row1 = mysqli_fetch_array($result3, MYSQLI_ASSOC)){	
			$FirstName_db = $row1['FirstName'];
			$LastName_db = $row1['LastName'];
			$EnrollDate_db = $row1['EnrollDate'];		
			$Zip_db = $row1['Zip'];
	
			// WHILE FOCUSDATE IS LESS THAN TODAYS DATE REPEAT QUERIES
			WHILE ($FocusDate <= $CurrentDate_db){

				$query4 = "SELECT MIN(TransactionDate) as TransMonth, 
				SUM(DollarsSpentAccrued) as DollarsSpentMonth,
				SUM(SereniteePointsRedeemed) as PointsRedeemedMonth,
				SUM(SereniteePointsAccrued) as PointsAccruedMonth,
				SUM(VisitsAccrued) as VisitsAccruedMonth                   
				FROM Master WHERE  CardNumber = '$CardNumber_db'
				AND DollarsSpentAccrued IS NOT NULL
				AND VisitsAccrued > '0'
				AND TransactionDate >= '$FocusDate'
				AND TransactionDate <= '$FocusDateEnd'";
			$result4 = mysqli_query($dbc, $query4);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result4, MYSQLI_ASSOC)){
				$TransMonth_db = $row1['TransMonth'];	
				$DollarsSpentMonth_db = $row1['DollarsSpentMonth'];
				$PointsRedeemedMonth_db = $row1['PointsRedeemedMonth'];
				$PointsAccruedMonth_db = $row1['PointsAccruedMonth'];
				$VisitsAccruedMonth_db = $row1['TransMonth'];

}

	}
}
		}
$FocusDate=strtotime($FocusDate, '+ 1 month');
$FocusDateEnd=strtotime($FocusDate, ' +1 month - 1 day');
// END OF CARD NUMBER WHILE LOOP
}
?>
