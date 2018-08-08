#!/usr/bin/php
<?php 

### functions
function yrseg ($pastvisitbal, $lifetimevisits)
{
	if (($pastvisitbal == '0') AND ($lifetimevisits > '0')) {$segment_txt = 'Dropout';
	} ELSE {
	if (($pastvisitbal == '0') AND ( $lifetimevisits == '0')) {$segment_txt = 'Zombie';
	} ELSE {
	if (($pastvisitbal >= '1') AND ($pastvisitbal <= '2'))  {$segment_txt = '1-2';
	} ELSE {
	if (($pastvisitbal >= '3') AND ($pastvisitbal <= '4')) {$segment_txt = '3-4';
	} ELSE {
	if (($pastvisitbal >= '5') AND ($pastvisitbal <= '10'))  {$segment_txt = '5-10';
	} ELSE {
	if (($pastvisitbal >= '11') AND ($pastvisitbal <= '25'))  {$segment_txt = '11-25';
	} ELSE {
	if ($pastvisitbal >= '26') {$segment_txt = '26+';	
	} 
	} } } } } } 
	# UNCOMMENT NEXT LINE FOR DEBUG
	# echo $segment_txt;
	RETURN $segment_txt;
}

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

// TRUNCATE table Px_Monthly"
$query_table= "TRUNCATE table Px_Monthly";
$result_table = mysqli_query($dbc, $query_table);	
ECHO MYSQLI_ERROR($dbc);
ECHO 'Px_Monthly TRUNCATED FOR FULL RUN!!!!!!'.PHP_EOL;
#ECHO 'Px_Monthly ##NOT## TRUNCATED FOR Partial RUN!!!!!!';


//QUERY MASTER FOR CARDNUMBER
# NOT USING -- 	AND MOD(CardNumber, 200) = '0'
$query1 = "SELECT DISTINCT(CardNumber) as CardNumber FROM Guests_Master	
					ORDER BY CardNumber ASC";
$result1 = mysqli_query($dbc, $query1);
ECHO MYSQLI_ERROR($dbc);
while($row1 = mysqli_fetch_array($result1, MYSQLI_ASSOC)){
	$CardNumber_db = $row1['CardNumber'];

	#INIT THE VARS
	$MaxDate_db = $MinDateMonth_db = $MinDateYear_db = $FocusDate = $FocusDateEnd = '';
	$CurrentDate_db = $FirstName_db = $LastName_db = $EnrollDate_db = $Zip_db = '';	

	$DollarsSpentLife_db = $PointsRedeemedLife_db = $PointsAccruedLife_db = $VisitsAccruedLife_db = '0';
	$DollarsSpentMonth_db = $PointsRedeemedMonth_db = $PointsAccruedMonth_db = $VisitsAccruedMonth_db = '0';

	$LastVisitDate_db = $PrevYearVisitBal_db = $LapseDays_db = $RecentFreqDays_db = $ProgAge_db = '';	
	$TwoVisitsBack_db = $FocusDate_php = $TwoVisitsBack_php = $MonthsEnrolled_db = $LifetimeFreq = '';
	$YearFreqSeg = $RecentFreqMonths_db = $TwoVisitsBack_php = $YrAgoFreq = $LastVisitBalance_db = '';
	$YrMoVisitBal_1MoBack_db = $YrMoVisitBal_3MoBack_db = $LapseMo_12MoBack_db = $YrMoVisitBal_12MoBack_db = '';
	$YrMoFreqSeg_12MoBack_txt = $YrMoFreqSeg_3MoBack_txt = $YrMoFreqSeg_1MoBack_txt = $YrMoFreq_1YrBack_txt = '';

	$segment_txt = '';
	$Carryover_LastVisitDate = '';

	
	#firstrun is for debugging
	$Firstrun = 'Yup';

	$counter++;
	$printcount = fmod($counter, 100);
	IF ($printcount == '0'){
	ECHO $counter++.'  card:';
	ECHO $CardNumber_db;
	}

	#### GET THE MIN AND MAX TRANSACTIONDATE AND THE MAX VISIT BALANCE
	$query2 = "SELECT MAX(TransactionDate) as MaxDate,  
				MAX(VM_VisitsBalance) as VisitsAccruedLife, 
				CURDATE() as TodayDate 
				FROM Master WHERE CardNumber = '$CardNumber_db'";
	$result2 = mysqli_query($dbc, $query2);	
	ECHO MYSQLI_ERROR($dbc);
	while($row1 = mysqli_fetch_array($result2, MYSQLI_ASSOC)){	
		$MaxDate_db = $row1['MaxDate'];
		$VisitsAccruedLife_db = $row1['VisitsAccruedLife'];
		$CurrentDate_db = $row1['TodayDate'];
	}
	IF ($VisitsAccruedLife_db == ''){$VisitsAccruedLife_db = '0';}
	
	# GET FIRSTNAME, LASTNAME, ENROLLDATE, ZIP
	$query3 = "SELECT FirstName, LastName, EnrollDate, Zip, Tier,
				YEAR(EnrollDate) as MinDateYear,
				MONTH(EnrollDate) as MinDateMonth
				FROM Guests_Master WHERE CardNumber = '$CardNumber_db'";
	$result3 = mysqli_query($dbc, $query3);	
	ECHO MYSQLI_ERROR($dbc);
	while($row1 = mysqli_fetch_array($result3, MYSQLI_ASSOC)){
		$MinDateMonth_db = $row1['MinDateMonth'];
		$MinDateYear_db = $row1['MinDateYear'];
		$FirstName_db = addslashes($row1['FirstName']);
		$LastName_db = addslashes($row1['LastName']);
		$EnrollDate_db = $row1['EnrollDate'];		
		$Zip_db = $row1['Zip'];		
		$Tier_db = $row1['Tier'];
	}
	#	echo ' FirstName:'.$FirstName_db.' LastName:'.$LastName_db.' Enrolled:'.$EnrollDate_db;
		IF ($printcount == '0'){echo ' Zip:'.$Zip_db.' Tier:'.$Tier_db;}
	
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
	# ECHO ' MinDateMo'.$MinDateMonth_db.' MinDateYr '.$MinDateYear_db;
	# ECHO ' CurDate'.$CurrentDate_db.' Focusdate '.$FocusDate.PHP_EOL;


		#FIELDS = LIFETIMESPENDBALANCE, LIFETIMEPOINTSREDEEMED, LIFETIMEPOINTSBALANCE, LIFETIMEVISITBALANCE
		$query3a ="SELECT SUM(DollarsSpentAccrued) as DollarsSpentLife, 
				SUM(SereniteePointsRedeemed) as PointsRedeemedLife, 
				SUM(SereniteePointsAccrued) as PointsAccruedLife
				FROM Master WHERE CardNumber = '$CardNumber_db'
				AND TransactionDate < '$FocusDate'";
		$result3a = mysqli_query($dbc, $query3a);	
		ECHO MYSQLI_ERROR($dbc);
		while($row1 = mysqli_fetch_array($result3a, MYSQLI_ASSOC)){
			$DollarsSpentLife_db = $row1['DollarsSpentLife'];
			$PointsRedeemedLife_db = $row1['PointsRedeemedLife'];
			$PointsAccruedLife_db = $row1['PointsAccruedLife']; 
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
			IF ($PrevYearVisitBal_db == ''){$PrevYearVisitBal_db = '0';}
		
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
				IF ($Firstrun == 'Yup'){
					$LastVisitDate_db = $EnrollDate_db;
					$Firstrun = 'Nope';
				} ELSE {
					$LastVisitDate_db = $Carryover_LastVisitDate;
					$Firstrun = 'Nope';
				}
			} ELSE { $Firstrun = 'Nope';}
		#	ECHO 'Card: '.$CardNumber_db.'  FocusDate:'.$FocusDate.'  Last Visit Date: ';
		#	ECHO $LastVisitDate_db.' Firstrun:'.$Firstrun.PHP_EOL;
	
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


			/////// INSERT VALUES INTO THE TABLE HERE
			$query8= "INSERT INTO Px_Monthly SET CardNumber = '$CardNumber_db',
					FocusDate = '$FocusDate',
					FirstName = '$FirstName_db',
					LastName = '$LastName_db',
					EnrollDate = '$EnrollDate_db',
					Zip = '$Zip_db',
					Tier = '$Tier_db',
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




			##### RETRIEVE PRIOR VISITBALANCE VALUES
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
			IF ($YrMoVisitBal_1MoBack_db == ''){$YrMoVisitBal_1MoBack_db = '0';}

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
			IF ($YrMoVisitBal_3MoBack_db == ''){$YrMoVisitBal_3MoBack_db = '0';}

			#### TWELVE MONTHS BACK
			$query15 = "SELECT 12MoVisitBalance, LapseMonths FROM Px_Monthly 
				WHERE CardNumber = '$CardNumber_db'
				AND FocusDate = DATE_SUB('$FocusDate', INTERVAL 1 YEAR)";
			$result15 = mysqli_query($dbc, $query15);	
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result15, MYSQLI_ASSOC)){
				$YrMoVisitBal_12MoBack_db = $row1['12MoVisitBalance'];	
				$LapseMo_12MoBack_db = $row1['LapseMonths'];		
			}
			IF ($YrMoVisitBal_12MoBack_db == ''){$YrMoVisitBal_12MoBack_db = '0';}
			IF ($LapseMo_12MoBack_db == ''){$LapseMo_12MoBack_db = '0';}
			IF ($printcount == '0'){ECHO ' LapseMo_12MoBack='.$LapseMo_12MoBack_db.PHP_EOL;}

		


# do this for $YrMoVisitBal_1MoBack_db - $YrMoFreq_1YrBack_txt
$YrMoFreq_1YrBack_txt = yrseg($PrevYearVisitBal_db, $VisitsAccruedLife_db);

# do this for $YrMoVisitBal_12MoBack_db - $YrMoFreqSeg_12MoBack_txt
$YrMoFreqSeg_12MoBack_txt = yrseg($YrMoVisitBal_12MoBack_db, $VisitsAccruedLife_db);

# do this for $YrMoVisitBal_3MoBack_db - $YrMoFreqSeg_3MoBack_txt
$YrMoFreqSeg_3MoBack_txt = yrseg($YrMoVisitBal_3MoBack_db, $VisitsAccruedLife_db);

# do this for $YrMoVisitBal_1MoBack_db - $YrMoFreqSeg_1MoBack_tx
$YrMoFreqSeg_1MoBack_txt = yrseg($YrMoVisitBal_1MoBack_db, $VisitsAccruedLife_db);

/////// INSERT VALUES INTO THE TABLE HERE
	$query16= "UPDATE Px_Monthly SET
			12MoVisitBal_1MoBack = '$YrMoVisitBal_1MoBack_db',
			12MoVisitBal_3MoBack = '$YrMoVisitBal_3MoBack_db',
			12MoVisitBal_12MoBack = '$YrMoVisitBal_12MoBack_db',
			12MoFreqSeg_1MoBack = '$YrMoFreqSeg_1MoBack_txt',
			12MoFreqSeg_3MoBack = '$YrMoFreqSeg_3MoBack_txt',
			12MoFreqSeg_12MoBack = '$YrMoFreqSeg_12MoBack_txt',
			12MoFreqSeg = '$YrMoFreq_1YrBack_txt',
			LapseMo_12MoBack = '$LapseMo_12MoBack_db'
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

$Carryover_LastVisitDate = $LastVisitDate_db;

}




// END OF CARD NUMBER WHILE LOOP
}

// CLEAN UP THE ENTRIES THAT COULD NOT HAVE BEEN CALC'D CORRECTLY
$Query18 = "DELETE FROM Px_Monthly WHERE LastName = 'Test' or LastName = 'test' or FirstName = 'Serenitee'";
$result18 = mysqli_query($dbc, $Query18);
ECHO MYSQLI_ERROR($dbc);

ECHO PHP_EOL.'COUNTER'.$counter

?>
