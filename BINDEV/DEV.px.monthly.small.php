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
					AND MOD(CardNumber, 1000) = '0'
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
		ECHO 'FocusDate: '. $FocusDate;
		$FocusDateEnd = date("Y-m-d",strtotime($FocusDate."+1 month -1 day"));
		ECHO 'FDend:'.$FocusDateEnd.PHP_EOL;
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
		ECHO 'Query 3 Completed'.$FirstName_db.' '.$EnrollDate_db.PHP_EOL;
		ECHO 'focus:'.$FocusDate.'focusend'.$FocusDateEnd.'curdate'.$CurrentDate_db.PHP_EOL;	
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
				$VisitsAccruedMonth_db = $row1['VisitsAccruedMonth'];

# FREQUENCY STARTS HERE  - - WRITE TO VARIABLES INSTEAD OF MASTER TABLE			
######## VISITS ACCRUED 12 MONTHS PREVIOUS TO FOCUSDATE (otherwise same query as master freq updater)
				$query5= "SELECT COUNT(TransactionDate) as PrevYear FROM Master 
						WHERE CardNumber = '$CardNumber_db'
							AND TransactionDate <> EnrollDate  
							AND TransactionDate >= DATE_SUB('$FocusDate',INTERVAL 1 YEAR) 
							AND TransactionDate < '$FocusDate'				
							AND Vm_VisitsAccrued = '1'";
				$result5 = mysqli_query($dbc, $query5);	
				ECHO MYSQLI_ERROR($dbc);
				while($row1 = mysqli_fetch_array($result5, MYSQLI_ASSOC)){
				$PrevYear_db = $row1['PrevYear'];	







#### GET CURRENT FREQ AS OF FOCUS DATE
				$query6= "SELECT DATEDIFF('$FocusDate' ,MAX(TRANSACTIONDATE)) as CurrentFreq FROM Master
						           	WHERE TransactionDate < '$FocusDate' 
								AND CardNumber = '$CardNumber_db' 
								AND VisitsAccrued > '0'";
				$result6 = mysqli_query($dbc, $query6);	
				ECHO MYSQLI_ERROR($dbc);
				while($row1 = mysqli_fetch_array($result6, MYSQLI_ASSOC)){
				$CurrentFreq_db = $row1['CurrentFreq'];	









##### GET CURRENT FREQ AS OF FOCUS DATE PLUS 1 FOR MM CALCS
				$query7= "SELECT (PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM '$FocusDate'), EXTRACT(YEAR_MONTH FROM '$EnrollDate_db')) + 1) AS ProgAge
									FROM Master
									WHERE CardNumber = '$CardNumber_db' LIMIT 1";
				$result7 = mysqli_query($dbc, $query7);	
				ECHO MYSQLI_ERROR($dbc);
				while($row1 = mysqli_fetch_array($result7, MYSQLI_ASSOC)){
				$ProgAge_db = $row1['ProgAge'];		
			#ECHO 'transmonth'.$TransMonth_db.'VisitsAccruedMonth'.$VisitsAccruedMonth_db.PHP_EOL;
			ECHO 'Focus'.$FocusDate.' less than Current Date'.$CurrentDate_db.PHP_EOL;

// END OF WHILE FOCUSDATE LESS THAN TODAY

$FocusDate = date("Y-m-d",strtotime($FocusDate." +1 month "));
$FocusDateEnd = date("Y-m-d",strtotime($FocusDate." +2 month - 1 day "));




}
}
}
}

	}
}

		}
// END OF CARD NUMBER WHILE LOOP
}

?>
