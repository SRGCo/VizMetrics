#!/usr/bin/php
<?php

# Start databaase interaction with
# localhost
# Sets the database access information as constants

define ('DB_USER', 'root');
define ('DB_PASSWORD','s3r3n1t33');
define ('DB_HOST','localhost');
define ('DB_NAME','SRG_Dev')

# Make the connection and then select the database
# display errors if fail
$dbc = mysqli_connect(DB_HOST, DB_USER, DB_PASSWORD)
	or die('Could not connect to mysql:'.MYSQLI_ERROR($dbc) );
mysqli_select_db($dbc, DB_NAME)
	OR die('Could not connect to the database:'.MYSQLI_ERROR($dbc));

### INIT Variables
$counter = 0;


// TRUNCATE table Px_Monthly"


$query_table= "TRUNCATE table Px_Monthly";
$result_table = mysqli_query($dbc, $query_table);	
ECHO MYSQLI_ERROR($dbc);
ECHO 'Px_Monthly TRUNCATED FOR FULL RUN!!!!!!';

//QUERY MASTER FOR CARDNUMBER
# NOT USING -- 	AND MOD(CardNumber, 200) = '0'
$query1 = "SELECT DISTINCT(CardNumber) as CardNumber FROM Master
					WHERE CardNumber > '0'
					AND CardNumber IS NOT NULL
					AND Account_status IS NOT NULL
					AND Account_status <> 'Exclude' 
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
$TransMonth_db = '';	
$DollarsSpentMonth_db = '';
$PointsRedeemedMonth_db = '';
$PointsAccruedMonth_db = '';
$VisitsAccruedMonth_db = '';
$DollarsSpentLife_db = '';
$PointsAccruedLife_db = '';
$VisitsAccruedLife_db = '';
$PointsRedeemedLife_db = '';
$LastVisitDate_db = '';
$PrevYearVisitBal_db = '';	
$CurrentFreq_db = '';
$FreqRecent_db = '';
$ProgAge_db = '';
$FreqRecent_db ='';		
$TwoVisitsBack_db = '';
$FocusDate_php = '';
$TwoVisitsBack_php = '';
$LifetimeFreq = '';
$YearFreqSeg = '';
$RecentFreq_db = '';
$CurFreq_db = '';
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


ECHO PHP_EOL.$counter++.'  card:';
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
	#	ECHO ' FDend:'.$FocusDateEnd.' MaxDate'.$MaxDate_db.' MinDateMo'.$MinDateMonth_db.' MinDateYr '.$MinDateYear_db.' VisitBal';
	#	ECHO $VisitBalance_db.' CurDate'.$CurrentDate_db.' Focusdate '.$FocusDate.PHP_EOL;

		#### One off query, close loop.
		####### GET GUEST INFO
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




# ECHO ' PrevYR:'.$PrevYearVisitBal_db.' LastVisitDate_db'.$LastVisitDate_db.PHP_EOL;

	
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
			$query7= "SELECT (PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM '$FocusDate'), EXTRACT(YEAR_MONTH FROM '$EnrollDate_db')) + 1) AS ProgAge";
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
			##### HANDLE IF NO TwoVisitsBack TRANSACTION
			IF (EMPTY($TwoVisitsBack_db)){
				$FreqRecent_db = '';
			# ECHO 'NO 2 VISITS BACK'.PHP_EOL;
			}ELSE{
				##### GET COUNT OF DAYS BETWEEN FOCUS DATE AND TWO VISITS BACK
				$query7b = "SELECT DATEDIFF('$FocusDate', '$TwoVisitsBack_db') AS FreqRecent";
				$result7b = mysqli_query($dbc, $query7b);	
				ECHO MYSQLI_ERROR($dbc);
				while($row1 = mysqli_fetch_array($result7b, MYSQLI_ASSOC)){
					$FreqRecent_db = $row1['FreqRecent'];	
			# ECHO 'FreqRecent_db='.$FreqRecent_db.PHP_EOL;	
				}
			}
			
#### LifeTime Freq SEGMENTED
			$query7c = "SELECT DATEDIFF('$FocusDate', '$EnrollDate_db')as DaysEnrolled";
			$result7c = mysqli_query($dbc, $query7c);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result7c, MYSQLI_ASSOC)){
				$DaysEnrolled_db = $row1['DaysEnrolled'];	
			# ECHO 'DaysEnrolled_db='.$DaysEnrolled_db.PHP_EOL;	
			}
			



# CALC VISITBALANCE DIVIDED BY COUNT OF MONTHS BETWEEN ENROLLDATE AND ONE YEAR PRIOR TO FOCUSDATE
			IF (($DaysEnrolled_db == '0') OR ($DaysEnrolled_db == '')){
				$LifetimeFreq = '';
			} ELSE {
				
			# CALC VISITBALANCE DIVIDED BY COUNT OF MONTHS BETWEEN ENROLLDATE AND FOCUSDATE
				$MonthsEnrolled = ($DaysEnrolled_db / 12);
				$LifetimeFreq = ($VisitsAccruedLife_db / $MonthsEnrolled);			
			}

			#### VISITBALANCE 12MONTHS PRIOR TO FOCUSDATE
			$query5= "SELECT COUNT(TransactionDate) as PrevYearVisitBalVisitBal
				FROM Master 
				WHERE CardNumber = '$CardNumber_db'
				AND TransactionDate <> EnrollDate  
				AND TransactionDate >= DATE_SUB('$FocusDate',INTERVAL 1 YEAR) 
				AND TransactionDate < '$FocusDate'				
				AND Vm_VisitsAccrued = '1'";
			$result5 = mysqli_query($dbc, $query5);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result5, MYSQLI_ASSOC)){
				$PrevYearVisitBalVisitBal_db = $row1['PrevYearVisitBalVisitBal'];
			# ECHO 'Prev yr visit bal'.$PrevYearVisitBalVisitBal_db.PHP_EOL;
			}


### 12 MONTH Freq SEGMENTED
			$query7d = "SELECT DATEDIFF(DATE_SUB('$FocusDate', INTERVAL 1 YEAR), '$EnrollDate_db')as DaysEnrolledYrAgo";
			$result7d = mysqli_query($dbc, $query7d);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result7d, MYSQLI_ASSOC)){
				$DaysEnrolledYrAgo_db = $row1['DaysEnrolledYrAgo'];	
			# ECHO 'DaysEnrolledYrAgo_db='.$DaysEnrolledYrAgo_db.PHP_EOL;	
			}

			# CALC VISITBALANCE DIVIDED BY COUNT OF MONTHS BETWEEN ENROLLDATE AND ONE YEAR PRIOR TO FOCUSDATE
			IF (($DaysEnrolledYrAgo_db == '0') OR ($DaysEnrolledYrAgo_db == '')){
				$YrAgoFreq = '';
			} ELSE {
				$MonthsEnrolledYrAgo = ($DaysEnrolledYrAgo_db / 12);
				$YrAgoFreq = ($PrevYearVisitBalVisitBal_db / $MonthsEnrolledYrAgo);
			# ECHO 'YrAgoFreq='.$YrAgoFreq.PHP_EOL;
			}





##########################
#### VISITBALANCE 2 VISITS PRIOR TO FOCUSDATE
			$query7e= "SELECT COUNT(TransactionDate) as TwoBackVisitBal
				FROM Master 
				WHERE CardNumber = '$CardNumber_db'
				AND TransactionDate <> EnrollDate  
				AND TransactionDate < '$TwoVisitsBack_db'				
				AND Vm_VisitsAccrued = '1'";
			$result7e = mysqli_query($dbc, $query7e);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result7e, MYSQLI_ASSOC)){
				$TwoBackVisitBal_db = $row1['TwoBackVisitBal'];
		#	ECHO 'TwoBackVisitBal'.$TwoBackVisitBal_db.PHP_EOL;
			}
			#### 12 MONTH Freq SEGMENTED
			$query7f = "SELECT DATEDIFF('$TwoVisitsBack_db', '$EnrollDate_db')as DaysEnrolledTwoBack";
			$result7f = mysqli_query($dbc, $query7f);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result7f, MYSQLI_ASSOC)){
				$DaysEnrolledTwoBack_db = $row1['DaysEnrolledTwoBack'];	
		#	ECHO 'DaysEnrolledTwoBack_db='.$DaysEnrolledTwoBack_db.PHP_EOL;	
			}

			# CALC VISITBALANCE DIVIDED BY COUNT OF MONTHS BETWEEN ENROLLDATE AND ONE YEAR PRIOR TO FOCUSDATE
			IF (($DaysEnrolledTwoBack_db == '0') OR ($DaysEnrolledTwoBack_db == '')){
				$TwoBackFreq = '';
			} ELSE {
				$MonthsEnrolledTwoBack = ($DaysEnrolledTwoBack_db / 12);
				$TwoBackFreq = ($PrevYearVisitBalVisitBal_db / $MonthsEnrolledTwoBack);
		#	ECHO 'TwoBackFreq='.$TwoBackFreqSeg.PHP_EOL;
			}




##########################
#### VISITBALANCE LAST VISITS PRIOR TO FOCUSDATE
			$query10= "SELECT COUNT(TransactionDate) as LastVisitBal
				FROM Master 
				WHERE CardNumber = '$CardNumber_db'
				AND TransactionDate <> EnrollDate  
				AND TransactionDate < '$LastVisitDate_db'				
				AND Vm_VisitsAccrued = '1'";
			$result10 = mysqli_query($dbc, $query10);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result10, MYSQLI_ASSOC)){
				$LastVisitBal_db = $row1['LastVisitBal'];
		#	ECHO 'LastVisitBalance'.$LastVisitBal_db.PHP_EOL;
			}
			####  Freq SEGMENTED
			$query11 = "SELECT DATEDIFF('$LastVisitDate_db', '$EnrollDate_db')as DaysEnrolledLastVisit";
			$result11 = mysqli_query($dbc, $query11);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result11, MYSQLI_ASSOC)){
				$DaysEnrolledLastVisit_db = $row1['DaysEnrolledLastVisit'];	
		#	ECHO 'DaysEnrolledTwoBack_db='.$DaysEnrolledTwoBack_db.PHP_EOL;	
			}

			# CALC VISITBALANCE DIVIDED BY COUNT OF MONTHS BETWEEN ENROLLDATE AND ONE YEAR PRIOR TO FOCUSDATE
			IF (($DaysEnrolledLastVisit_db == '0') OR ($DaysEnrolledLastVisit_db == '')){
				$LastVisitFreq = '';
			} ELSE {
				$MonthsEnrolledLastVisit = ($DaysEnrolledLastVisit_db / 12);
				$LastVisitFreq = ($LastVisitBal_db / $MonthsEnrolledLastVisit);
		#	ECHO 'LastVisitFreq='.$LastVisitFreq.PHP_EOL;
			}

########### PROGRAM AGE	
			$query12 = "SELECT DATEDIFF('$FocusDate', '$EnrollDate_db')as DaysEnrolled";
			$result12 = mysqli_query($dbc, $query12);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result12, MYSQLI_ASSOC)){
				$DaysEnrolled_db = $row1['DaysEnrolled'];	
		#	ECHO 'DaysEnrolled_db='.$DaysEnrolled.PHP_EOL;	
			}
			




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
					FreqCurrentDays = '$CurrentFreq_db',
					FreqRecentDays = '$FreqRecent_db',
					12MoVisitBalance = '$PrevYearVisitBal_db',
					ProgramAge = '$ProgAge_db',
					LifetimeFreq = ROUND('$LifetimeFreq',8),
					RecentFreq = ROUND('$TwoBackFreq',8),
					CurFreq = ROUND('$LastVisitFreq',8),
					LifetimeVisitBalance = '$VisitsAccruedLife_db'";
// ECHO $query8.PHP_EOL;
			$result8 = mysqli_query($dbc, $query8);	
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

		

#echo '12mo:'.$YrMoVisitBal_12MoBack_db.' 3mo:'.$YrMoVisitBal_3MoBack_db.' 1mo:'.$YrMoVisitBal_1MoBack_db.PHP_EOL;

if ($YrMoVisitBal_12MoBack_db == '0') {$YrMoFreqSeg_12MoBack_txt = 'Dropout';}
if (($YrMoVisitBal_12MoBack_db >= '1') AND ($YrMoVisitBal_12MoBack_db <= '2'))  {$YrMoFreqSeg_12MoBack_txt = '1-2';}
if (($YrMoVisitBal_12MoBack_db >= '3') AND ($YrMoVisitBal_12MoBack_db <= '4')) {$YrMoFreqSeg_12MoBack_txt = '3-4';}
if (($YrMoVisitBal_12MoBack_db >= '5') AND ($YrMoVisitBal_12MoBack_db <= '7'))  {$YrMoFreqSeg_12MoBack_txt = '5-7';}
if (($YrMoVisitBal_12MoBack_db >= '8') AND ($YrMoVisitBal_12MoBack_db <= '10'))  {$YrMoFreqSeg_12MoBack_txt = '8-10';}
if (($YrMoVisitBal_12MoBack_db >= '11') AND ($YrMoVisitBal_12MoBack_db <= '14'))  {$YrMoFreqSeg_12MoBack_txt = '11-14';}
if (($YrMoVisitBal_12MoBack_db >= '15') AND ($YrMoVisitBal_12MoBack_db <= '26'))  {$YrMoFreqSeg_12MoBack_txt = '15-26';}
if ($YrMoVisitBal_12MoBack_db >= '26') {$YrMoFreqSeg_12MoBack_txt = '26+';}

if ($YrMoVisitBal_3MoBack_db == '0'){$YrMoFreqSeg_3MoBack_txt = 'Dropout';}
if (($YrMoVisitBal_3MoBack_db >= '1') AND ($YrMoVisitBal_3MoBack_db <= '2'))  {$YrMoFreqSeg_3MoBack_txt = '1-2';}
if (($YrMoVisitBal_3MoBack_db >= '3') AND ($YrMoVisitBal_3MoBack_db <= '4'))  {$YrMoFreqSeg_3MoBack_txt = '3-4';}
if (($YrMoVisitBal_3MoBack_db >= '5') AND ($YrMoVisitBal_3MoBack_db <= '7'))  {$YrMoFreqSeg_3MoBack_txt = '5-7';}
if (($YrMoVisitBal_3MoBack_db >= '8') AND ($YrMoVisitBal_3MoBack_db <= '10'))  {$YrMoFreqSeg_3MoBack_txt = '8-10';}
if (($YrMoVisitBal_3MoBack_db >= '11') AND ($YrMoVisitBal_3MoBack_db <= '14'))  {$YrMoFreqSeg_3MoBack_txt = '11-14';}
if (($YrMoVisitBal_3MoBack_db >= '15') AND ($YrMoVisitBal_3MoBack_db <= '26'))  {$YrMoFreqSeg_3MoBack_txt = '15-26';}
if ($YrMoVisitBal_3MoBack_db >= '26') {$YrMoFreqSeg_3MoBack_txt = '26+';}

if ($YrMoVisitBal_1MoBack_db == '0'){$YrMoFreqSeg_1MoBack_txt = 'Dropout';}
if (($YrMoVisitBal_1MoBack_db >= '1') AND ($YrMoVisitBal_1MoBack_db <= '2'))  {$YrMoFreqSeg_1MoBack_txt = '1-2';}
if (($YrMoVisitBal_1MoBack_db >= '3') AND ($YrMoVisitBal_1MoBack_db <= '4'))  {$YrMoFreqSeg_1MoBack_txt = '3-4';}
if (($YrMoVisitBal_1MoBack_db >= '5') AND ($YrMoVisitBal_1MoBack_db <= '7'))  {$YrMoFreqSeg_1MoBack_txt = '5-7';}
if (($YrMoVisitBal_1MoBack_db >= '8') AND ($YrMoVisitBal_1MoBack_db <= '10'))  {$YrMoFreqSeg_1MoBack_txt = '8-10';}
if (($YrMoVisitBal_1MoBack_db >= '11') AND ($YrMoVisitBal_1MoBack_db <= '14'))  {$YrMoFreqSeg_1MoBack_txt = '11-14';}
if (($YrMoVisitBal_1MoBack_db >= '15') AND ($YrMoVisitBal_1MoBack_db <= '26'))  {$YrMoFreqSeg_1MoBack_txt = '15-26';}
if ($YrMoVisitBal_1MoBack_db >= '26') {$YrMoFreqSeg_1MoBack_txt = '26+';}

if ($YrAgoFreq == '0'){$YrMoFreq_1YrBack_txt = 'Dropout';}
if (($YrAgoFreq >= '1') AND ($YrAgoFreq <= '2'))  {$YrMoFreq_1YrBack_txt = '1-2';}
if (($YrAgoFreq >= '3') AND ($YrAgoFreq <= '4'))  {$YrMoFreq_1YrBack_txt = '3-4';}
if (($YrAgoFreq >= '5') AND ($YrAgoFreq <= '7'))  {$YrMoFreq_1YrBack_txt = '5-7';}
if (($YrAgoFreq >= '8') AND ($YrAgoFreq <= '10'))  {$YrMoFreq_1YrBack_txt = '8-10';}
if (($YrAgoFreq >= '11') AND ($YrAgoFreq <= '14'))  {$YrMoFreq_1YrBack_txt = '11-14';}
if (($YrAgoFreq >= '15') AND ($YrAgoFreq <= '26'))  {$YrMoFreq_1YrBack_txt = '15-26';}
if ($YrAgoFreq >= '26') {$YrMoFreq_1YrBack_txt = '26+';}


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



// END OF WHILE FOCUSDATE LESS THAN TODAY

$FocusDate = date("Y-m-d",strtotime($FocusDate." +1 month "));
$FocusDateEnd = date("Y-m-d",strtotime($FocusDate." +2 month - 1 day "));

}

// END OF CARD NUMBER WHILE LOOP
}

// CLEAN UP THE ENTRIES THAT COULD NOT HAVE BEEN CALC'D CORRECTLY
$Query17 = "DELETE FROM Px_Monthly WHERE EnrollDate = ''";
$result17 = mysqli_query($dbc, $Query17);
ECHO MYSQLI_ERROR($dbc);

// CLEAN UP THE ENTRIES THAT COULD NOT HAVE BEEN CALC'D CORRECTLY
$Query18 = "DELETE FROM Px_Monthly WHERE LastName = 'Test' or LastName = 'test' or FirstName = 'Serenitee'";
$result18 = mysqli_query($dbc, $Query18);
ECHO MYSQLI_ERROR($dbc);


?>
