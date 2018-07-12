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
$dbc = mysqli_connect(DB_HOST, DB_USER, DB_PASSWORD)
	or die('Could not connect to mysql:'.MYSQLI_ERROR($dbc) );
mysqli_select_db($dbc, DB_NAME)
	OR die('Could not connect to the database:'.MYSQLI_ERROR($dbc));

### INIT Variables
$counter = 0;


// TRUNCATE table Px_monthly_small"


$query_table= "TRUNCATE table Px_monthly_small";
$result_table = mysqli_query($dbc, $query_table);	
ECHO MYSQLI_ERROR($dbc);
ECHO 'Px_monthly_small TRUNCATED FOR FULL RUN!!!!!!';

//QUERY MASTER FOR CARDNUMBER
# NOT USING -- 	AND MOD(CardNumber, 200) = '0'
$query1 = "SELECT DISTINCT(CardNumber) as CardNumber FROM Master
					WHERE CardNumber > '0'
					AND CardNumber IS NOT NULL 
					AND MOD(CardNumber, 2000) = '0'
					GROUP BY CardNumber	
					ORDER BY CardNumber ASC";
$result1 = mysqli_query($dbc, $query1);
ECHO MYSQLI_ERROR($dbc);
while($row1 = mysqli_fetch_array($result1, MYSQLI_ASSOC)){
	$CardNumber_db = $row1['CardNumber'];

#INIT THE VARS
$MaxDate_db = '';
$MinDateMonth_db = '';
$MinDateYear_db = '';
$FocusDate = ''; 
$FocusDateEnd = '';
$VisitBalance_db = '0';
$CurrentDate_db = '';
$FirstName_db = '';
$LastName_db = '';
$EnrollDate_db = '';		
$Zip_db = '';	
$DollarsSpentLife_db = '0'; 
$PointsRedeemedLife_db = '0'; 
$PointsAccruedLife_db = '0'; 
$VisitsAccruedLife_db = '0';
#### INIT VARS
$TransMonth_db = '';	
$DollarsSpentMonth_db = '';
$PointsRedeemedMonth_db = '';
$PointsAccruedMonth_db = '';
$VisitsAccruedMonth_db = '';
$PrevYear_db = '';	
$CurrentFreq_db = '';	
$CurrentFreq_db = '';
$ProgAge_db = '';
$FreqRecent_db ='';		
$TwoVisitsBack_db = '';


ECHO $counter++.'  card:';
ECHO $CardNumber_db;
	#### GET THE MIN & MAX DATES
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
		}
	
	// FORMAT FOCUSDATE
	$FocusDate = $MinDateYear_db."-".$MinDateMonth_db."-01"; 
#	ECHO 'FocusDate: '. $FocusDate;
	$FocusDateEnd = date("Y-m-d",strtotime($FocusDate."+1 month -1 day"));
#	ECHO ' FDend:'.$FocusDateEnd.' MaxDate'.$MaxDate_db.' MinDateMo'.$MinDateMonth_db.' MinDateYr '.$MinDateYear_db.' VisitBal'.$VisitBalance_db.' CurDate'.$CurrentDate_db.' Focusdate '.$FocusDate.PHP_EOL;

#### One off query, close loop.
		####### GET GUEST INFO
		$query3 = "SELECT FirstName, LastName, EnrollDate, Zip
				FROM Guests WHERE CardNumber = '$CardNumber_db'";
		$result3 = mysqli_query($dbc, $query3);	
		ECHO MYSQLI_ERROR($dbc);
		while($row1 = mysqli_fetch_array($result3, MYSQLI_ASSOC)){	
			$FirstName_db = addslashes($row1['FirstName']);
			$LastName_db = addslashes($row1['LastName']);
			$EnrollDate_db = $row1['EnrollDate'];		
			$Zip_db = $row1['Zip'];
			}
echo ' FirstName:'.$FirstName_db.' LastName:'.$LastName_db.' Enrolled:'.$EnrollDate_db.' Zip:'.$Zip_db;
#### One off query, close loop.
		############## GET LIFETIME VALUES (up until this FocusDate)
		$query3a ="SELECT SUM(DollarsSpentAccrued) as DollarsSpentLife, 
				SUM(SereniteePointsRedeemed) as PointsRedeemedLife, 
				SUM(SereniteePointsAccrued) as PointsAccruedLife, 
				SUM(VisitsAccrued) as VisitsAccruedLife 
				FROM Master WHERE CardNumber = '$CardNumber_db'
				AND TransactionDate < '$FocusDate'";
		$result3a = mysqli_query($dbc, $query3a);	
		ECHO MYSQLI_ERROR($dbc);
		while($row1 = mysqli_fetch_array($result3a, MYSQLI_ASSOC)){
			$DollarsSpentLife_db = $row1['DollarsSpentLife'];
			$PointsRedeemedLife_db = $row1['PointsRedeemedLife'];
			$PointsAccruedLife_db = $row1['PointsAccruedLife']; 
			$VisitsAccruedLife_db = $row1['VisitsAccruedLife'];
			}
# echo 'While transactiondate less than todays date starts here'.PHP_EOL;
#### While loop open ended starts here
		// WHILE FOCUSDATE IS LESS THAN TODAYS DATE REPEAT QUERIES
		WHILE ($FocusDate <= $CurrentDate_db){

#### One off query, close loop.
		##### MONTH NUMBERS
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
			}
#echo ' DolSpentMo'.$DollarsSpentMonth_db.' PtsRedeemMo'.$PointsRedeemedMonth_db.' PtsAccrMo'.$PointsAccruedMonth_db.' TranMo'.$TransMonth_db.PHP_EOL;
#### One off query, close loop.
			# FREQUENCY STARTS HERE  - - WRITE TO VARIABLES INSTEAD OF MASTER TABLE			
			######## VISITS ACCRUED 12 MONTHS PREVIOUS TO FOCUSDATE (otherwise same query as master freq updater)
			$query5= "SELECT COUNT(TransactionDate) as PrevYear
					FROM Master 
					WHERE CardNumber = '$CardNumber_db'
					AND TransactionDate <> EnrollDate  
					AND TransactionDate >= DATE_SUB('$FocusDate',INTERVAL 1 YEAR) 
					AND TransactionDate < '$FocusDate'				
					AND Vm_VisitsAccrued = '1'";
			$result5 = mysqli_query($dbc, $query5);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result5, MYSQLI_ASSOC)){
			$PrevYear_db = $row1['PrevYear'];
			}


			$query5a= "SELECT MAX(TransactionDate) as LastVisitDate 
					FROM Master 
					WHERE CardNumber = '$CardNumber_db'
					AND TransactionDate < '$FocusDate'				
					AND Vm_VisitsAccrued = '1'";
			$result5a = mysqli_query($dbc, $query5a);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result5a, MYSQLI_ASSOC)){
			$LastVisitDate_db = $row1['LastVisitDate'];
			}
		### IF THERE IS NO LAST VISIT
			IF (EMPTY($LastVisitDate_db)){$LastVisitDate_db = $EnrollDate_db;} 




ECHO ' PrevYR:'.$PrevYear_db.' LastVisitDate_db'.$LastVisitDate_db.PHP_EOL;

	
#### One off query, close loop.
			#### GET CURRENT FREQ AS OF FOCUS DATE
			$query6= "SELECT DATEDIFF('$FocusDate' ,MAX(TRANSACTIONDATE)) as CurrentFreq FROM Master
			           	WHERE TransactionDate < '$FocusDate' 
					AND CardNumber = '$CardNumber_db' 
					AND VisitsAccrued > '0'";
			$result6 = mysqli_query($dbc, $query6);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result6, MYSQLI_ASSOC)){
			$CurrentFreq_db = $row1['CurrentFreq'];	
			}
#### One off query, close loop.
		##### GET CURRENT FREQ AS OF FOCUS DATE PLUS 1 FOR MM CALCS
			$query7= "SELECT (PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM '$FocusDate'), EXTRACT(YEAR_MONTH FROM '$EnrollDate_db')) + 1) AS ProgAge
					FROM Master
					WHERE CardNumber = '$CardNumber_db' LIMIT 1";
			$result7 = mysqli_query($dbc, $query7);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result7, MYSQLI_ASSOC)){
			$ProgAge_db = $row1['ProgAge'];		
			}
			##### GET RECENT FREQ (2 visits back) AS OF FOCUS DATE
			$query7a = "SELECT TransactionDate FROM Master
					WHERE TransactionDate < '$FocusDate' 
					AND CardNumber = '$CardNumber_db' 
					AND VisitsAccrued > '0'
					ORDER BY TransactionDate DESC LIMIT 1 , 1";
			$result7a = mysqli_query($dbc, $query7a);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result7a, MYSQLI_ASSOC)){
			$TwoVisitsBack_db = $row1['TransactionDate'];		
			}
			
			# CALC NUMBER OF DAYS BETWEEN FOCUSDATE AND 2 VISITS BACK IF THERE WAS A 2 VISITS BACK VISIT
			IF (EMPTY($TwoVisitsBack_db)){$FreqRecent = '';
			} ELSE {
			$FreqRecent_db = date_diff($FocusDate ,$TwoVisitsBack_db);
			}

			# CALC VISITBALANCE DIVIDED BY COUNT OF MONTHS BETWEEN ENROLLDATE AND FOCUSDATE
		#	$LifetimeFreqSeg = ($VisitsAccruedLife_db / date_diff($FocusDate, $EnrollDate_db));

		
			####### ECHO DATA FOR DEBUG
#			echo ' VisAccrMo'.$VisitsAccruedMonth_db.' DolSpentLife'.$DollarsSpentLife_db.PHP_EOL;
#			echo 'PAL'.$PointsAccruedLife_db. PtsredeemedLife'.$PointsRedeemedLife_db.PHP_EOL;
#			echo 'LastVisitever'.$MaxDate_db.' CurrentFreqMo'.$CurrentFreq_db.' 12MO'.$PrevYear_db.' ProgAge'.$ProgAge_db.PHP_EOL;
#			echo '================================='.PHP_EOL;
		#	echo 'RecentFrequency'.$FreqRecent.PHP_EOL;
		#	echo ' VisAcrLife'.$VisitsAccruedLife_db.PHP_EOL;
		#	echo 'FocusDate:'.$FocusDate.' EnrollDate:'.$EnrollDate_db.' LIFEFREQSEG:'.$LifetimeFreqSeg.PHP_EOL;

/////// INSERT VALUES INTO THE TABLE HERE
			$query8= "INSERT INTO Px_monthly_small SET CardNumber = '$CardNumber_db',
					FocusDate = '$FocusDate',
					FirstName = '$FirstName_db',
					LastName = '$LastName_db',
					EnrollDate = '$EnrollDate_db',
					Zip = '$Zip_db',
					DollarsSpentMonth = ROUND('$DollarsSpentMonth_db',2),
					PointsRedeemedMonth = '$PointsRedeemedMonth_db',
					PointsAccruedMonth = '$PointsAccruedMonth_db',
					VisitsAccruedMonth = '$VisitsAccruedMonth_db',
					LifetimeSpendBalance = ROUND('$DollarsSpentLife_db',2),
					LifetimePointsBalance = '$PointsAccruedLife_db',
					LifetimeVisitsBalance = '$VisitsAccruedLife_db',
					LifetimePointsRedeemed = '$PointsRedeemedLife_db',
					LastVisitDate = '$LastVisitDate_db',
					FreqCurrent = '$CurrentFreq_db',
					FreqRecent = '$FreqRecent_db',
					12MoVisitBal = '$PrevYear_db',
					ProgramAge = '$ProgAge_db'";
// ECHO $query8.PHP_EOL;
			$result8 = mysqli_query($dbc, $query8);	
			ECHO MYSQLI_ERROR($dbc);


// END OF WHILE FOCUSDATE LESS THAN TODAY

$FocusDate = date("Y-m-d",strtotime($FocusDate." +1 month "));
$FocusDateEnd = date("Y-m-d",strtotime($FocusDate." +2 month - 1 day "));

}

// END OF CARD NUMBER WHILE LOOP
}

?>
