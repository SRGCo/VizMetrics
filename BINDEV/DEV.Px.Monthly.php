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

// TRUNCATE table Px_Monthly"
#$query_table= "TRUNCATE table Px_Monthly";
#$result_table = mysqli_query($dbc, $query_table);	
#ECHO MYSQLI_ERROR($dbc);
#ECHO 'Px_Monthly TRUNCATED FOR FULL RUN!!!!!!';
ECHO 'Px_Monthly ##NOT## TRUNCATED FOR Partial RUN!!!!!!';

//QUERY MASTER FOR CARDNUMBER
# NOT USING -- 	AND MOD(CardNumber, 200) = '0'
$query1 = "SELECT DISTINCT(CardNumber) as CardNumber FROM Guests_Master
				WHERE CardNumber >= '6000227901380242'	
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
$DollarsSpentMonth_db = '';
$PointsRedeemedMonth_db = '';
$PointsAccruedMonth_db = '';
$VisitsAccruedMonth_db = '';

$LastVisitDate_db = '';
$PrevYearVisitBal_db = '';	
$LapseDays_db = '';
$RecentFreqDays_db = '';
$ProgAge_db = '';	
$TwoVisitsBack_db = '';
$FocusDate_php = '';
$TwoVisitsBack_php = '';
$MonthsEnrolled_db = '';
$LifetimeFreq = '';
$YearFreqSeg = '';
$RecentFreqMonths_db = '';
$TwoVisitsBack_php = '';
$YrAgoFreq = '';
$LastVisitBalance_db = '';
$YrMoVisitBal_1MoBack_db = '';
$YrMoVisitBal_3MoBack_db = '';
$YrMoVisitBal_12MoBack_db = '';
$YrMoFreqSeg_12MoBack_txt = '';
$YrMoFreqSeg_3MoBack_txt = '';
$YrMoFreqSeg_1MoBack_txt = '';
$YrMoFreq_1YrBack_txt = '';

$counter++;
$printcount = fmod($counter, 500);
IF ($printcount == '0'){
ECHO PHP_EOL.$counter++.'  card:';
ECHO $CardNumber_db;
}
	#### GET THE MIN AND MAX TRANSACTIONDATE AND THE MAX VISIT BALANCE
	$query2 = "SELECT MAX(TransactionDate) as MaxDate, 
				YEAR(MIN(TransactionDate)) as MinDateYear,
				MONTH(MIN(TransactionDate)) as MinDateMonth, 
				MAX(VisitsBalance) as VisitsBalance, 
				CURDATE() as TodayDate 
				FROM Master WHERE CardNumber = '$CardNumber_db'";
	$result2 = mysqli_query($dbc, $query2);	
	ECHO MYSQLI_ERROR($dbc);
	while($row1 = mysqli_fetch_array($result2, MYSQLI_ASSOC)){	
		$MaxDate_db = $row1['MaxDate'];
		$MinDateMonth_db = $row1['MinDateMonth'];
		$MinDateYear_db = $row1['MinDateYear'];
		$VisitBalance_db = $row1['VisitsBalance'];
		$CurrentDate_db = $row1['TodayDate'];
	}

	
	# GET FIRSTNAME, LASTNAME, ENROLLDATE, ZIP
	$query3 = "SELECT FirstName, LastName, EnrollDate, Zip
			FROM Guests_Master WHERE CardNumber = '$CardNumber_db'";
	$result3 = mysqli_query($dbc, $query3);	
	ECHO MYSQLI_ERROR($dbc);
	while($row1 = mysqli_fetch_array($result3, MYSQLI_ASSOC)){	
		$FirstName_db = addslashes($row1['FirstName']);
		$LastName_db = addslashes($row1['LastName']);
		$EnrollDate_db = $row1['EnrollDate'];		
		$Zip_db = $row1['Zip'];
	}
#	echo ' FirstName:'.$FirstName_db.' LastName:'.$LastName_db.' Enrolled:'.$EnrollDate_db.' Zip:'.$Zip_db;
	
	// FORMAT FOCUSDATE
	$FocusDate = $MinDateYear_db."-".$MinDateMonth_db."-01"; 
	$FocusDateEnd = date("Y-m-d",strtotime($FocusDate."+1 month -1 day"));
	$FocusDate_php = strtotime($FocusDate);
	$EnrollDate_db_php = strtotime($EnrollDate_db);
	# IF ENROLLMENT OCCURED DURING FOCUSMONTH SKIP TO NEXT MONTH
	IF ($FocusDate_php <= $EnrollDate_db_php){
		$FocusDate = date("Y-m-d",strtotime($FocusDate."+1 month"));
		$FocusDateEnd = date("Y-m-d",strtotime($FocusDateEnd."+1 month"));
	}
	# ECHO 'FocusDate: '. $FocusDate;
	# ECHO ' FDend:'.$FocusDateEnd.' MaxDate'.$MaxDate_db.';
	# ECHO ' MinDateMo'.$MinDateMonth_db.' MinDateYr '.$MinDateYear_db.' VisitBal';
	# ECHO $VisitBalance_db.' CurDate'.$CurrentDate_db.' Focusdate '.$FocusDate.PHP_EOL;


		#FIELDS = LIFETIMESPENDBALANCE, LIFETIMEPOINTSREDEEMED, LIFETIMEPOINTSBALANCE, LIFETIMEVISITBALANCE
		$query3a ="SELECT SUM(DollarsSpentAccrued) as DollarsSpentLife, 
				SUM(SereniteePointsRedeemed) as PointsRedeemedLife, 
				SUM(SereniteePointsAccrued) as PointsAccruedLife, 
				SUM(Vm_VisitsAccrued) as VisitsAccruedLife 
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

		// WHILE FOCUSDATE IS LESS THAN TODAYS DATE REPEAT QUERIES
		WHILE ($FocusDate <= $CurrentDate_db){
		
			#####GET NUMBERS FOR FOCUSMONTH
			#FIELDS = DOLLARSSPENTMONTH, POINTSREDEEMEDMONTH, POINTSACCRUEDMONTH, VISITSACCRUEDMONTH
			$query4 = "SELECT
				SUM(DollarsSpentAccrued) as DollarsSpentMonth,
				SUM(SereniteePointsRedeemed) as PointsRedeemedMonth,
				SUM(SereniteePointsAccrued) as PointsAccruedMonth,
				SUM(Vm_VisitsAccrued) as VisitsAccruedMonth                   
				FROM Master WHERE  CardNumber = '$CardNumber_db'
				AND DollarsSpentAccrued IS NOT NULL
				AND Vm_VisitsAccrued > '0'
				AND TransactionDate >= '$FocusDate'
				AND TransactionDate <= '$FocusDateEnd'";
			$result4 = mysqli_query($dbc, $query4);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result4, MYSQLI_ASSOC)){
				$DollarsSpentMonth_db = $row1['DollarsSpentMonth'];
				$PointsRedeemedMonth_db = $row1['PointsRedeemedMonth'];
				$PointsAccruedMonth_db = $row1['PointsAccruedMonth'];
				$VisitsAccruedMonth_db = $row1['VisitsAccruedMonth'];
			}
				#echo ' DolSpentMo'.$DollarsSpentMonth_db.' PtsRedeemMo'.$PointsRedeemedMonth_db;
				#echo ' PtsAccrMo'.$PointsAccruedMonth_db.' TranMo'.$TransMonth_db.PHP_EOL;

			#FIELDS = 12MOVISITBALANCE (PHP=PREVYEARVISITBALANCE)
			$query5= "SELECT COUNT(TransactionDate) as PrevYearVisitBal
					FROM Master 
					WHERE CardNumber = '$CardNumber_db'
					AND TransactionDate <> EnrollDate  
					AND TransactionDate >= DATE_SUB('$FocusDate',INTERVAL 1 YEAR) 
					AND TransactionDate < '$FocusDate'				
					AND Vm_VisitsAccrued = '1'";
			$result5 = mysqli_query($dbc, $query5);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result5, MYSQLI_ASSOC)){
				$PrevYearVisitBal_db = $row1['PrevYearVisitBal'];
			}

			#FIELD = LASTVISITDATE
			$query5a= "SELECT MAX(TransactionDate) as LastVisitDate 
					FROM Master 
					WHERE CardNumber = '$CardNumber_db'
					AND TransactionDate <= '$FocusDate'				
					AND VisitsAccrued = '1'";
			$result5a = mysqli_query($dbc, $query5a);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result5a, MYSQLI_ASSOC)){
				$LastVisitDate_db = $row1['LastVisitDate'];
			}
			### IF THERE IS NO LAST VISIT DATE SKIP THIS RECORD
			IF (EMPTY($LastVisitDate_db)){
				ECHO 'Card '.$CardNumber_db.' Last transaction date '.$LastVisitDate_db.' is empty, no vm_visitaccrued, focusdate ='.$FocusDate.PHP_EOL;
				goto end;
			} 
		
			#FIELD = LAPSEDAYS
			$query6= "SELECT DATEDIFF('$FocusDate', MAX(TransactionDate)) as LapseDays
					FROM Master
			           	WHERE TransactionDate < '$FocusDate' 
					AND CardNumber = '$CardNumber_db' 
					AND Vm_VisitsAccrued > '0'";
			$result6 = mysqli_query($dbc, $query6);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result6, MYSQLI_ASSOC)){
				$LapseDays_db = $row1['LapseDays'];	
			}
			IF (EMPTY($LapseDays_db)){
				$LapseDays_db = '0';
			}

			##### GET RECENT FREQ (2 visits back) AS OF FOCUS DATE
			#FIELD = FREQRECENTDAYS
			$query7a = "SELECT TransactionDate FROM Master
					WHERE TransactionDate < '$FocusDate' 
					AND CardNumber = '$CardNumber_db' 
					AND Vm_VisitsAccrued > '0'
					ORDER BY TransactionDate DESC LIMIT 1 , 1";
			$result7a = mysqli_query($dbc, $query7a);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result7a, MYSQLI_ASSOC)){
				$TwoVisitsBack_db = $row1['TransactionDate'];		
			}
			##### HANDLE IF NO TwoVisitsBack TRANSACTION
			IF (EMPTY($TwoVisitsBack_db)){
				$RecentFreqDays_db = '';
			# ECHO 'NO 2 VISITS BACK'.PHP_EOL;
			}ELSE{
				##### GET COUNT OF DAYS BETWEEN FOCUS DATE AND TWO VISITS BACK
				$query7b = "SELECT DATEDIFF('$FocusDate', '$TwoVisitsBack_db') AS FreqRecentDays";
				$result7b = mysqli_query($dbc, $query7b);	
				ECHO MYSQLI_ERROR($dbc);
				while($row1 = mysqli_fetch_array($result7b, MYSQLI_ASSOC)){
					$RecentFreqDays_db = $row1['FreqRecentDays'];	
			# ECHO 'RecentFrequencyDays_db='.$RecentFreqDays_db.PHP_EOL;	
				}
			}

			##### GET NUMBER OF MONTHS BETWEEN ENROLLDATE AND FOCUSDATE  (+1 for marks numbers)
			#PROGRAMAGE
			$query7= "SELECT (PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM '$FocusDate'), EXTRACT(YEAR_MONTH FROM '$EnrollDate_db')) + 1) AS ProgAge";
			$result7 = mysqli_query($dbc, $query7);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result7, MYSQLI_ASSOC)){
				$ProgAge_db = $row1['ProgAge'];		
			}

			##### GET NUMBER OF MONTHS BETWEEN ENROLLDATE AND FOCUSDATE 
			#FIELD = LIFETIMEFREQ
			$query7x= "SELECT PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM '$FocusDate'), EXTRACT(YEAR_MONTH FROM '$EnrollDate_db')) AS MonthsEnrolled";
			$result7x = mysqli_query($dbc, $query7x);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result7x, MYSQLI_ASSOC)){
				$MonthsEnrolled_db = $row1['MonthsEnrolled'];		
			}
			# ECHO 'DaysEnrolled_db='.$DaysEnrolled_db.PHP_EOL;	
			IF (($MonthsEnrolled_db == '0') OR ($MonthsEnrolled_db == '')){
				$LifetimeFreq = '';
			} ELSE {
				$LifetimeFreq = ($VisitsAccruedLife_db / $MonthsEnrolled_db);			
			}


			#FIELD RECENTFREQMONTHS
			$query7e= "SELECT PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM '$FocusDate'), EXTRACT(YEAR_MONTH FROM '$TwoVisitsBack_db')) AS RecentFreqMonths";
			$result7e = mysqli_query($dbc, $query7e);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result7e, MYSQLI_ASSOC)){
				$RecentFreqMonths_db = $row1['RecentFreqMonths'];
			# ECHO 'RecentFreqMonths_db'.$RecentFreqMonths_db.PHP_EOL;
			}

			#FIELD LAPSEMONTHS
			$query7e= "SELECT PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM '$FocusDate'), EXTRACT(YEAR_MONTH FROM MAX(TransactionDate))) AS LapseMonths FROM Master
					WHERE TransactionDate < '$FocusDate' 
					AND CardNumber = '$CardNumber_db' 
					AND Vm_VisitsAccrued > '0'";
			$result7e = mysqli_query($dbc, $query7e);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result7e, MYSQLI_ASSOC)){
				$LapseMonths_db = $row1['LapseMonths'];
			# ECHO 'LapseMonths_db'.$LapseMonths_db.PHP_EOL;
			}

















### 12 MONTH Freq SEGMENTED
#			$query7d = "SELECT DATEDIFF(DATE_SUB('$FocusDate', INTERVAL 1 YEAR), '$EnrollDate_db')as DaysEnrolledYrAgo";
#			$result7d = mysqli_query($dbc, $query7d);	
#			ECHO MYSQLI_ERROR($dbc);
#			while($row1 = mysqli_fetch_array($result7d, MYSQLI_ASSOC)){
#				$DaysEnrolledYrAgo_db = $row1['DaysEnrolledYrAgo'];	
			# ECHO 'DaysEnrolledYrAgo_db='.$DaysEnrolledYrAgo_db.PHP_EOL;	
#			}

			# CALC VISITBALANCE DIVIDED BY COUNT OF MONTHS BETWEEN ENROLLDATE AND ONE YEAR PRIOR TO FOCUSDATE
#			IF (($DaysEnrolledYrAgo_db == '0') OR ($DaysEnrolledYrAgo_db == '')){
#				$YrAgoFreq = '';
#			} ELSE {
#				$MonthsEnrolledYrAgo = ($DaysEnrolledYrAgo_db / 12);
#				$YrAgoFreq = ($PrevYearVisitBalVisitBal_db / $MonthsEnrolledYrAgo);
			# ECHO 'YrAgoFreq='.$YrAgoFreq.PHP_EOL;
#			}





##########################
#### VISITBALANCE 2 VISITS PRIOR TO FOCUSDATE

#			#### 12 MONTH Freq SEGMENTED
#			$query7f = "SELECT DATEDIFF('$TwoVisitsBack_db', '$EnrollDate_db')as DaysEnrolledTwoBack";
#			$result7f = mysqli_query($dbc, $query7f);	
#			ECHO MYSQLI_ERROR($dbc);
#			while($row1 = mysqli_fetch_array($result7f, MYSQLI_ASSOC)){
#				$DaysEnrolledTwoBack_db = $row1['DaysEnrolledTwoBack'];	
		#	ECHO 'DaysEnrolledTwoBack_db='.$DaysEnrolledTwoBack_db.PHP_EOL;	
#			}

			# CALC VISITBALANCE DIVIDED BY COUNT OF MONTHS BETWEEN ENROLLDATE AND ONE YEAR PRIOR TO FOCUSDATE
#			IF (($DaysEnrolledTwoBack_db == '0') OR ($DaysEnrolledTwoBack_db == '')){
#				$TwoBackFreq = '';
#			} ELSE {
#				$MonthsEnrolledTwoBack = ($DaysEnrolledTwoBack_db / 12);
#				$TwoBackFreq = ($PrevYearVisitBalVisitBal_db / $MonthsEnrolledTwoBack);
		#	ECHO 'TwoBackFreq='.$TwoBackFreqSeg.PHP_EOL;
#			}




##########################
#### VISITBALANCE LAST VISITS PRIOR TO FOCUSDATE
#			$query10= "SELECT COUNT(TransactionDate) as LastVisitBal
#				FROM Master 
#				WHERE CardNumber = '$CardNumber_db'
#				AND TransactionDate <> EnrollDate  
#				AND TransactionDate < '$LastVisitDate_db'				
#				AND Vm_VisitsAccrued = '1'";
#			$result10 = mysqli_query($dbc, $query10);	
#			ECHO MYSQLI_ERROR($dbc);
#			while($row1 = mysqli_fetch_array($result10, MYSQLI_ASSOC)){
#				$LastVisitBal_db = $row1['LastVisitBal'];
		#	ECHO 'LastVisitBalance'.$LastVisitBal_db.PHP_EOL;
#			}
			####  Freq SEGMENTED
#			$query11 = "SELECT DATEDIFF('$LastVisitDate_db', '$EnrollDate_db')as DaysEnrolledLastVisit";
#			$result11 = mysqli_query($dbc, $query11);	
#			ECHO MYSQLI_ERROR($dbc);
#			while($row1 = mysqli_fetch_array($result11, MYSQLI_ASSOC)){
#				$DaysEnrolledLastVisit_db = $row1['DaysEnrolledLastVisit'];	
		#	ECHO 'DaysEnrolledTwoBack_db='.$DaysEnrolledTwoBack_db.PHP_EOL;	
#			}

			# LAPSE IN MONTHS
#			IF (($DaysEnrolledLastVisit_db == '0') OR ($DaysEnrolledLastVisit_db == '')){
#				$LapseMonths = '';
#			} ELSE {
#				$MonthsEnrolledLastVisit = ($DaysEnrolledLastVisit_db / 12);
#				$LapseMonths = ($LastVisitBal_db / $MonthsEnrolledLastVisit);
		#	ECHO 'LapseMonths='.$LapseMonths.PHP_EOL;
#			}

			

			/////// INSERT VALUES INTO THE TABLE HERE
			$query8= "INSERT INTO Px_Monthly SET CardNumber = '$CardNumber_db',
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
					LifetimePointsRedeemed = '$PointsRedeemedLife_db',
					LastVisitDate = '$LastVisitDate_db',
					LapseDays = '$LapseDays_db',
					FreqRecentDays = '$RecentFreqDays_db',
					12MoVisitBalance = '$PrevYearVisitBal_db',
					ProgramAge = '$ProgAge_db',
					LifetimeFreq = ROUND('$LifetimeFreq',8),
					RecentFreqMonths = '$RecentFreqMonths_db',
					LapseMonths = '$LapseMonths_db',
					LifetimeVisitBalance = '$VisitsAccruedLife_db'";
			// ECHO $query8.PHP_EOL;
			$result8 = mysqli_query($dbc, $query8);	
			if(!$result8){ECHO $query8.' ';}
			ECHO MYSQLI_ERROR($dbc);




##### RETRIEVE PRIOR VALUES
			#### ONE MONTH BACK
			$query13 = "SELECT 12MoVisitBalance FROM Px_Monthly 
				WHERE CardNumber = '$CardNumber_db'
				AND FocusDate = DATE_SUB('$FocusDate',INTERVAL 1 MONTH)";
			$result13 = mysqli_query($dbc, $query13);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result13, MYSQLI_ASSOC)){
				$YrMoVisitBal_1MoBack_db = $row1['12MoVisitBalance'];	
		#	ECHO 'DaysEnrolled_db='.$DaysEnrolled.PHP_EOL;	
			}
			#### THREE MONTHS BACK
			$query14 = "SELECT 12MoVisitBalance FROM Px_Monthly 
				WHERE CardNumber = '$CardNumber_db'
				AND FocusDate = DATE_SUB('$FocusDate', INTERVAL 3 MONTH)";
			$result14 = mysqli_query($dbc, $query14);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result14, MYSQLI_ASSOC)){
				$YrMoVisitBal_3MoBack_db = $row1['12MoVisitBalance'];	
		#	ECHO 'DaysEnrolled_db='.$DaysEnrolled.PHP_EOL;	
			}
			#### TWELVE MONTHS BACK
			$query15 = "SELECT 12MoVisitBalance FROM Px_Monthly 
				WHERE CardNumber = '$CardNumber_db'
				AND FocusDate = DATE_SUB('$FocusDate', INTERVAL 1 YEAR)";
			$result15 = mysqli_query($dbc, $query15);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result15, MYSQLI_ASSOC)){
				$YrMoVisitBal_12MoBack_db = $row1['12MoVisitBalance'];	
		#	ECHO 'DaysEnrolled_db='.$DaysEnrolled.PHP_EOL;	
			}

		IF ($YrMoVisitBal_12MoBack_db == ''){$YrMoVisitBal_12MoBack_db = '0';}
		IF ($YrMoVisitBal_3MoBack_db == ''){$YrMoVisitBal_3MoBack_db = '0';}
		IF ($YrMoVisitBal_1MoBack_db == ''){$YrMoVisitBal_1MoBack_db = '0';}
		IF ($PrevYearVisitBal_db == ''){$PrevYearVisitBal_db = '0';}
		IF ($VisitsAccruedLife_db == ''){$VisitsAccruedLife_db = '0';}
		

######## SWITCH ACTUALLY SLOWER ????/
#switch($YrMoVisitBal_12MoBack_db){

#case NULL:
#	$YrMoFreqSeg_12MoBack_txt = 'Never Started';
#	break;
#case '':
#	$YrMoFreqSeg_12MoBack_txt = 'Never Started';
#	break;
#case '0':
#	$YrMoFreqSeg_12MoBack_txt = 'Dropout';
#	break;
#case ($YrMoVisitBal_12MoBack_db >= '1' && $YrMoVisitBal_12MoBack_db <= '2'):
#	$YrMoFreqSeg_12MoBack_txt = '1-2';
#	break;
#case ($YrMoVisitBal_12MoBack_db >= '3' && $YrMoVisitBal_12MoBack_db <= '4'):
#	$YrMoFreqSeg_12MoBack_txt = '3-4';
#	break;
#case ($YrMoVisitBal_12MoBack_db >= '5' && $YrMoVisitBal_12MoBack_db <= '7'):
#	$YrMoFreqSeg_12MoBack_txt = '5-7';
#	break;
#case ($YrMoVisitBal_12MoBack_db >= '8' && $YrMoVisitBal_12MoBack_db <= '10'):
#	$YrMoFreqSeg_12MoBack_txt = '8-10';
#	break;
#case ($YrMoVisitBal_12MoBack_db >= '11' && $YrMoVisitBal_12MoBack_db <= '14'):
#	$YrMoFreqSeg_12MoBack_txt = '11-14';
#	break;
#case ($YrMoVisitBal_12MoBack_db >= '15' && $YrMoVisitBal_12MoBack_db <= '26'):
#	$YrMoFreqSeg_12MoBack_txt = '15-26';
#	break;
#case ($YrMoVisitBal_12MoBack_db >= '26'):
#	$YrMoFreqSeg_12MoBack_txt = '26+';
#	break;
#}




#echo '12mo:'.$YrMoVisitBal_12MoBack_db.' 3mo:'.$YrMoVisitBal_3MoBack_db.' 1mo:'.$YrMoVisitBal_1MoBack_db.PHP_EOL;
### TRY AS A CASE
if (($YrMoVisitBal_12MoBack_db == '0') AND ($VisitsAccruedLife_db > '0')) {$YrMoFreqSeg_12MoBack_txt = 'Dropout';
} ELSE {
	if (($YrMoVisitBal_12MoBack_db == '0') AND ($VisitsAccruedLife_db == '0')) {$YrMoFreqSeg_12MoBack_txt = 'DOA';
} ELSE {
	if (($YrMoVisitBal_12MoBack_db >= '1') AND ($YrMoVisitBal_12MoBack_db <= '2'))  {$YrMoFreqSeg_12MoBack_txt = '1-2';
} ELSE {
	if (($YrMoVisitBal_12MoBack_db >= '3') AND ($YrMoVisitBal_12MoBack_db <= '4')) {$YrMoFreqSeg_12MoBack_txt = '3-4';
} ELSE {
	if (($YrMoVisitBal_12MoBack_db >= '5') AND ($YrMoVisitBal_12MoBack_db <= '7'))  {$YrMoFreqSeg_12MoBack_txt = '5-7';
} ELSE {
	if (($YrMoVisitBal_12MoBack_db >= '8') AND ($YrMoVisitBal_12MoBack_db <= '10'))  {$YrMoFreqSeg_12MoBack_txt = '8-10';
} ELSE {
	if (($YrMoVisitBal_12MoBack_db >= '11') AND ($YrMoVisitBal_12MoBack_db <= '14'))  {$YrMoFreqSeg_12MoBack_txt = '11-14';
} ELSE {
	if (($YrMoVisitBal_12MoBack_db >= '15') AND ($YrMoVisitBal_12MoBack_db <= '26'))  {$YrMoFreqSeg_12MoBack_txt = '15-26';
} ELSE {
	if ($YrMoVisitBal_12MoBack_db >= '26') {$YrMoFreqSeg_12MoBack_txt = '26+';	} 
} } } } } } } } 

#switch($YrMoVisitBal_3MoBack_db){

#case NULL:
#	$YrMoFreqSeg_3MoBack_txt = 'Never Started';
#	break;
#case '':
#	$YrMoFreqSeg_3MoBack_txt = 'Never Started';
#	break;
#case '0':
#	$YrMoFreqSeg_3MoBack_txt = 'Dropout';
#	break;
#case ($YrMoVisitBal_3MoBack_db >= '1' && $YrMoVisitBal_3MoBack_db <= '2'):
#	$YrMoFreqSeg_3MoBack_txt = '1-2';
#	break;
#case ($YrMoVisitBal_3MoBack_db >= '3' && $YrMoVisitBal_3MoBack_db <= '4'):
#	$YrMoFreqSeg_3MoBack_txt = '3-4';
#	break;
#case ($YrMoVisitBal_3MoBack_db >= '5' && $YrMoVisitBal_3MoBack_db <= '7'):
#	$YrMoFreqSeg_3MoBack_txt = '5-7';
#	break;
#case ($YrMoVisitBal_3MoBack_db >= '8' && $YrMoVisitBal_3MoBack_db <= '10'):
#	$YrMoFreqSeg_3MoBack_txt = '8-10';
#	break;
#case ($YrMoVisitBal_3MoBack_db >= '11' && $YrMoVisitBal_3MoBack_db <= '14'):
#	$YrMoFreqSeg_3MoBack_txt = '11-14';
#	break;
#case ($YrMoVisitBal_3MoBack_db >= '15' && $YrMoVisitBal_3MoBack_db <= '26'):
#	$YrMoFreqSeg_3MoBack_txt = '15-26';
#	break;
#case ($YrMoVisitBal_3MoBack_db >= '26'):
#	$YrMoFreqSeg_3MoBack_txt = '26+';
#	break;
#}




if (($YrMoVisitBal_3MoBack_db == '0') AND ($VisitsAccruedLife_db > '0')) {$YrMoFreqSeg_3MoBack_txt = 'Dropout';
} ELSE {
if (($YrMoVisitBal_3MoBack_db == '0') AND ($VisitsAccruedLife_db == '0')) {$YrMoFreqSeg_3MoBack_txt = 'DOA';
} ELSE {
if (($YrMoVisitBal_3MoBack_db >= '1') AND ($YrMoVisitBal_3MoBack_db <= '2'))  {$YrMoFreqSeg_3MoBack_txt = '1-2';
} ELSE {
if (($YrMoVisitBal_3MoBack_db >= '3') AND ($YrMoVisitBal_3MoBack_db <= '4'))  {$YrMoFreqSeg_3MoBack_txt = '3-4';
} ELSE {
if (($YrMoVisitBal_3MoBack_db >= '5') AND ($YrMoVisitBal_3MoBack_db <= '7'))  {$YrMoFreqSeg_3MoBack_txt = '5-7';
} ELSE {
if (($YrMoVisitBal_3MoBack_db >= '8') AND ($YrMoVisitBal_3MoBack_db <= '10'))  {$YrMoFreqSeg_3MoBack_txt = '8-10';
} ELSE {
if (($YrMoVisitBal_3MoBack_db >= '11') AND ($YrMoVisitBal_3MoBack_db <= '14'))  {$YrMoFreqSeg_3MoBack_txt = '11-14';
} ELSE {
if (($YrMoVisitBal_3MoBack_db >= '15') AND ($YrMoVisitBal_3MoBack_db <= '26'))  {$YrMoFreqSeg_3MoBack_txt = '15-26';
} ELSE {
if ($YrMoVisitBal_3MoBack_db >= '26') {$YrMoFreqSeg_3MoBack_txt = '26+';
}}}}}}}}}

#switch($YrMoVisitBal_1MoBack_db){

#case NULL:
#	$YrMoFreqSeg_1MoBack_txt = 'Never Started';
#	break;
#case '':
#	$YrMoFreqSeg_1MoBack_txt = 'Never Started';
#	break;
#case '0':
#	$YrMoFreqSeg_1MoBack_txt = 'Dropout';
#	break;
#case ($YrMoVisitBal_1MoBack_db >= '1' && $YrMoVisitBal_1MoBack_db <= '2'):
#	$YrMoFreqSeg_1MoBack_txt = '1-2';
#	break;
#case ($YrMoVisitBal_1MoBack_db >= '3' && $YrMoVisitBal_1MoBack_db <= '4'):
#	$YrMoFreqSeg_1MoBack_txt = '3-4';
#	break;
#case ($YrMoVisitBal_1MoBack_db >= '5' && $YrMoVisitBal_1MoBack_db <= '7'):
#	$YrMoFreqSeg_1MoBack_txt = '5-7';
#	break;
#case ($YrMoVisitBal_1MoBack_db >= '8' && $YrMoVisitBal_1MoBack_db <= '10'):
#	$YrMoFreqSeg_1MoBack_txt = '8-10';
#	break;
#case ($YrMoVisitBal_1MoBack_db >= '11' && $YrMoVisitBal_1MoBack_db <= '14'):
#	$YrMoFreqSeg_1MoBack_txt = '11-14';
#	break;
#case ($YrMoVisitBal_1MoBack_db >= '15' && $YrMoVisitBal_1MoBack_db <= '26'):
#	$YrMoFreqSeg_1MoBack_txt = '15-26';
#	break;
#case ($YrMoVisitBal_1MoBack_db >= '26'):
#	$YrMoFreqSeg_1MoBack_txt = '26+';
#	break;
#}



if (($YrMoVisitBal_1MoBack_db == '0') AND ($VisitsAccruedLife_db > '0')) {$YrMoFreqSeg_1MoBack_txt = 'Dropout';
} ELSE {
if (($YrMoVisitBal_1MoBack_db == '0') AND ($VisitsAccruedLife_db == '0')) {$YrMoFreqSeg_1MoBack_txt = 'DOA';
} ELSE {
if (($YrMoVisitBal_1MoBack_db >= '1') AND ($YrMoVisitBal_1MoBack_db <= '2'))  {$YrMoFreqSeg_1MoBack_txt = '1-2';
} ELSE {
if (($YrMoVisitBal_1MoBack_db >= '3') AND ($YrMoVisitBal_1MoBack_db <= '4'))  {$YrMoFreqSeg_1MoBack_txt = '3-4';
} ELSE {
if (($YrMoVisitBal_1MoBack_db >= '5') AND ($YrMoVisitBal_1MoBack_db <= '7'))  {$YrMoFreqSeg_1MoBack_txt = '5-7';
} ELSE {
if (($YrMoVisitBal_1MoBack_db >= '8') AND ($YrMoVisitBal_1MoBack_db <= '10'))  {$YrMoFreqSeg_1MoBack_txt = '8-10';
} ELSE {
if (($YrMoVisitBal_1MoBack_db >= '11') AND ($YrMoVisitBal_1MoBack_db <= '14'))  {$YrMoFreqSeg_1MoBack_txt = '11-14';
} ELSE {
if (($YrMoVisitBal_1MoBack_db >= '15') AND ($YrMoVisitBal_1MoBack_db <= '26'))  {$YrMoFreqSeg_1MoBack_txt = '15-26';
} ELSE {
if ($YrMoVisitBal_1MoBack_db >= '26') {$YrMoFreqSeg_1MoBack_txt = '26+';
}}}}}}}}}


#switch($PrevYearVisitBal_db){

#case NULL:
#	$YrMoFreq_1YrBack_txt = 'Never Started';
#	break;
#case '':
#	$YrMoFreq_1YrBack_txt = 'Never Started';
#	break;
#case '0':
#	$YrMoFreq_1YrBack_txt = 'Dropout';
#	break;
#case ($YrAgoFreq >= '1' && $YrAgoFreq <= '2'):
#	$YrMoFreq_1YrBack_txt = '1-2';
#	break;
#case ($YrAgoFreq >= '3' && $YrAgoFreq <= '4'):
#	$YrMoFreq_1YrBack_txt = '3-4';
#	break;
#case ($YrAgoFreq >= '5' && $YrAgoFreq <= '7'):
#	$YrMoFreq_1YrBack_txt = '5-7';
#	break;
#case ($YrAgoFreq >= '8' && $YrAgoFreq <= '10'):
#	$YrMoFreq_1YrBack_txt = '8-10';
#	break;
#case ($YrAgoFreq >= '11' && $YrAgoFreq <= '14'):
#	$YrMoFreq_1YrBack_txt = '11-14';
#	break;
#case ($YrAgoFreq >= '15' && $YrAgoFreq <= '26'):
#	$YrMoFreq_1YrBack_txt = '15-26';
#	break;
#case ($YrAgoFreq >= '26'):
#	$YrMoFreq_1YrBack_txt = '26+';
#	break;

#}

if (($PrevYearVisitBal_db == '0') AND ($VisitsAccruedLife_db > '0')) {$YrMoFreq_1YrBack_txt = 'Dropout';
} 
if (($PrevYearVisitBal_db == '0') AND ($VisitsAccruedLife_db == '0')) {$YrMoFreq_1YrBack_txt = 'DOA';
} 
if (($PrevYearVisitBal_db >= '1') AND ($PrevYearVisitBal_db <= '2'))  {$YrMoFreq_1YrBack_txt = '1-2';
} 
if (($PrevYearVisitBal_db >= '3') AND ($PrevYearVisitBal_db <= '4'))  {$YrMoFreq_1YrBack_txt = '3-4';
} 
if (($PrevYearVisitBal_db >= '5') AND ($PrevYearVisitBal_db <= '7'))  {$YrMoFreq_1YrBack_txt = '5-7';
} 
if (($PrevYearVisitBal_db >= '8') AND ($PrevYearVisitBal_db <= '10'))  {$YrMoFreq_1YrBack_txt = '8-10';
} 
if (($PrevYearVisitBal_db >= '11') AND ($PrevYearVisitBal_db <= '14'))  {$YrMoFreq_1YrBack_txt = '11-14';
} 
if (($PrevYearVisitBal_db >= '15') AND ($PrevYearVisitBal_db <= '26'))  {$YrMoFreq_1YrBack_txt = '15-26';
} 
if ($PrevYearVisitBal_db >= '26') {$YrMoFreq_1YrBack_txt = '26+';}

#ECHO ' YrAgoFreq:'.$PrevYearVisitBal_db.' Vis life'.$VisitsAccruedLife_db.' Not oddball ? ? ? ?'.$YrMoFreq_1YrBack_txt;



#echo '12mo:'.$YrMoFreqSeg_1MoBack_txt.' 3mo:'.$YrMoFreqSeg_3MoBack_txt.' 1mo:'.$YrMoFreqSeg_12MoBack_txt.PHP_EOL;

/////// INSERT VALUES INTO THE TABLE HERE
	$query16= "UPDATE Px_Monthly SET
			12MoVisitBal_1MoBack = '$YrMoVisitBal_1MoBack_db',
			12MoVisitBal_3MoBack = '$YrMoVisitBal_3MoBack_db',
			12MoVisitBal_12MoBack = '$YrMoVisitBal_12MoBack_db',
			12MoFreqSeg_1MoBack = '$YrMoFreqSeg_1MoBack_txt',
			12MoFreqSeg_3MoBack = '$YrMoFreqSeg_3MoBack_txt',
			12MoFreqSeg_12MoBack = '$YrMoFreqSeg_12MoBack_txt',
			12MoFreqSeg = '$YrMoFreq_1YrBack_txt'
		WHERE CardNumber = '$CardNumber_db'
		AND FocusDate = '$FocusDate'";
// ECHO $query8.PHP_EOL;
	$result16 = mysqli_query($dbc, $query16);	
	ECHO MYSQLI_ERROR($dbc);

// IF NO MAX TRANSACTIONDATE FOR THIS CARD END 
end:


// END OF WHILE FOCUSDATE LESS THAN TODAY

$FocusDate = date("Y-m-d",strtotime($FocusDate." +1 month "));
$FocusDateEnd = date("Y-m-d",strtotime($FocusDate." +2 month - 1 day "));

}




// END OF CARD NUMBER WHILE LOOP
}

// CLEAN UP THE ENTRIES THAT COULD NOT HAVE BEEN CALC'D CORRECTLY
$Query18 = "DELETE FROM Px_Monthly WHERE LastName = 'Test' or LastName = 'test' or FirstName = 'Serenitee'";
$result18 = mysqli_query($dbc, $Query18);
ECHO MYSQLI_ERROR($dbc);

ECHO PHP_EOL.'COUNTER'.$counter

?>
