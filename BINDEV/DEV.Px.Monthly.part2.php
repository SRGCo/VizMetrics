#!/usr/bin/php
<?php 

	 $segment_txt = '';
	


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
	if ($pastvisitbal >= '26') {$segment_txt = '26+';} 
	} } } } } } 
	# UNCOMMENT NEXT LINE FOR DEBUG
	# echo $segment_txt.PHP_EOL;
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


//QUERY PX_MONTHLY FOR CARDNUMBER
# NOT USING -- 	AND MOD(CardNumber, 200) = '0'
$query1 = "SELECT DISTINCT(CardNumber) as CardNumber FROM Px_Monthly	
					ORDER BY CardNumber ASC";
$result1 = mysqli_query($dbc, $query1);
ECHO MYSQLI_ERROR($dbc);
while($row1 = mysqli_fetch_array($result1, MYSQLI_ASSOC)){
	$CardNumber_db = $row1['CardNumber'];
	
	$YrMoVisitBal_1MoBack_db = $YrMoVisitBal_3MoBack_db = $LapseMo_12MoBack_db = $YrMoVisitBal_12MoBack_db = '';
	$YrMoVisitBal_24MoBack_db = $YrMoVisitBal_36MoBack_db = $YrMoFreqSeg_24MoBack_txt = $YrMoFreqSeg_36MoBack_txt = '';

	$YrMoFreqSeg_12MoBack_txt = $YrMoFreqSeg_3MoBack_txt = $YrMoFreqSeg_1MoBack_txt = $YrMoFreq_1YrBack_txt = '';

	$segment_txt  = $VisitsAccruedLife_db = '0';
	#INIT THE VARS
	$MaxDate_db = $MinDateMonth_db = $MinDateYear_db = $FocusDate = $FocusDateEnd = '';
	$CurrentDate_db = $FirstName_db = $LastName_db = $EnrollDate_db = $Zip_db = '';	

	$DollarsSpentLife_db = $PointsRedeemedLife_db = $PointsAccruedLife_db = $VisitsAccruedLife_db = '0';
	$DollarsSpentMonth_db = $PointsRedeemedMonth_db = $PointsAccruedMonth_db = $VisitsAccruedMonth_db = '0';

	$LastVisitDate_db = $PrevYearVisitBal_db = $LapseDays_db = $RecentFreqDays_db = $ProgAge_db = '';	
	$TwoVisitsBack_db = $FocusDate_php = $TwoVisitsBack_php = $MonthsEnrolled_db = $LifetimeFreq = '';
	$YearFreqSeg = $RecentFreqMonths_db = $TwoVisitsBack_php = $YrAgoFreq = $LastVisitBalance_db = '';

	
	$Carryover_LastVisitDate = $segment_txt = '';
	


	###### NOW SELECT THE FOCUSDATE AND PROCESS
	$query2 = "SELECT FocusDate FROM Px_Monthly where CardNumber = '$CardNumber_db'	
					ORDER BY FocusDate DESC";
	$result2 = mysqli_query($dbc, $query2);
	ECHO MYSQLI_ERROR($dbc);
	while($row1 = mysqli_fetch_array($result2, MYSQLI_ASSOC)){
		$FocusDate_db = $row1['FocusDate'];


		##### RETRIEVE PRIOR VISITBALANCE VALUES
		#### ONE MONTH BACK
		$query13 = "SELECT 12MoVisitBalance FROM Px_Monthly 
			WHERE CardNumber = '$CardNumber_db'
			AND FocusDate = DATE_SUB('$FocusDate_db',INTERVAL 1 MONTH)";
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
			AND FocusDate = DATE_SUB('$FocusDate_db', INTERVAL 3 MONTH)";
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
			AND FocusDate = DATE_SUB('$FocusDate_db', INTERVAL 1 YEAR)";
		$result15 = mysqli_query($dbc, $query15);
		ECHO MYSQLI_ERROR($dbc);
		while($row1 = mysqli_fetch_array($result15, MYSQLI_ASSOC)){
			$YrMoVisitBal_12MoBack_db = $row1['12MoVisitBalance'];	
			$LapseMo_12MoBack_db = $row1['LapseMonths'];		
		}
		IF ($YrMoVisitBal_12MoBack_db == ''){$YrMoVisitBal_12MoBack_db = '0';}
		IF ($LapseMo_12MoBack_db == ''){$LapseMo_12MoBack_db = '0';}
	
		##### RETRIEVE PRIOR VISITBALANCE VALUES
		#### TWENTY FOUR MONTHS BACK
		$query13b = "SELECT 12MoVisitBalance FROM Px_Monthly 
			WHERE CardNumber = '$CardNumber_db'
			AND FocusDate = DATE_SUB('$FocusDate_db',INTERVAL 2 YEAR)";
		$result13b = mysqli_query($dbc, $query13b);	
		ECHO MYSQLI_ERROR($dbc);
		while($row1 = mysqli_fetch_array($result13b, MYSQLI_ASSOC)){
			$YrMoVisitBal_24MoBack_db = $row1['12MoVisitBalance'];	
		}
		IF ($YrMoVisitBal_24MoBack_db == ''){$YrMoVisitBal_24MoBack_db = '0';}

		##### RETRIEVE PRIOR VISITBALANCE VALUES
		#### THIRTY SIX MONTHS BACK
		$query13c = "SELECT 12MoVisitBalance FROM Px_Monthly 
			WHERE CardNumber = '$CardNumber_db'
			AND FocusDate = DATE_SUB('$FocusDate_db',INTERVAL 3 YEAR)";
		$result13c = mysqli_query($dbc, $query13c);	
		ECHO MYSQLI_ERROR($dbc);
		while($row1 = mysqli_fetch_array($result13c, MYSQLI_ASSOC)){
			$YrMoVisitBal_36MoBack_db = $row1['12MoVisitBalance'];	
		#	ECHO 'DaysEnrolled_db='.$DaysEnrolled.PHP_EOL;	
		}
		IF ($YrMoVisitBal_36MoBack_db == ''){$YrMoVisitBal_36MoBack_db = '0';}


		# do this for $YrMoVisitBal_1MoBack_db - $YrMoFreqSeg_1MoBack_tx
		$YrMoFreqSeg_1MoBack_txt = yrseg($YrMoVisitBal_1MoBack_db, $VisitsAccruedLife_db);

		# do this for $YrMoVisitBal_3MoBack_db - $YrMoFreqSeg_3MoBack_txt
		$YrMoFreqSeg_3MoBack_txt = yrseg($YrMoVisitBal_3MoBack_db, $VisitsAccruedLife_db);

		# do this for $YrMoVisitBal_12MoBack_db - $YrMoFreqSeg_12MoBack_txt
		$YrMoFreqSeg_12MoBack_txt = yrseg($YrMoVisitBal_12MoBack_db, $VisitsAccruedLife_db);

		# do this for $YrMoVisitBal_24MoBack_db - $YrMoFreqSeg_24MoBack_txt
		$YrMoFreqSeg_24MoBack_txt = yrseg($YrMoVisitBal_24MoBack_db, $VisitsAccruedLife_db);

		# do this for $YrMoVisitBal_36MoBack_db - $YrMoFreqSeg_36MoBack_txt
		$YrMoFreqSeg_36MoBack_txt = yrseg($YrMoVisitBal_36MoBack_db, $VisitsAccruedLife_db);

		# do this for $YrMoVisitBal_1YrBack_db - $YrMoFreq_1YrBack_txt
		$YrMoFreq_1YrBack_txt = yrseg($PrevYearVisitBal_db, $VisitsAccruedLife_db);


		/////// INSERT VALUES INTO THE TABLE HERE
		$query16= "UPDATE Px_Monthly SET
			12MoVisitBal_1MoBack = '$YrMoVisitBal_1MoBack_db',
			12MoVisitBal_3MoBack = '$YrMoVisitBal_3MoBack_db',
			12MoVisitBal_12MoBack = '$YrMoVisitBal_12MoBack_db',
			12MoVisitBal_24MoBack = '$YrMoVisitBal_24MoBack_db',
			12MoVisitBal_36MoBack = '$YrMoVisitBal_36MoBack_db',
			12MoFreqSeg_1MoBack = '$YrMoFreqSeg_1MoBack_txt',
			12MoFreqSeg_3MoBack = '$YrMoFreqSeg_3MoBack_txt',
			12MoFreqSeg_12MoBack = '$YrMoFreqSeg_12MoBack_txt',
			12MoFreqSeg_24MoBack = '$YrMoFreqSeg_24MoBack_txt',
			12MoFreqSeg_36MoBack = '$YrMoFreqSeg_36MoBack_txt',
			12MoFreqSeg = '$YrMoFreq_1YrBack_txt',
			LapseMo_12MoBack = '$LapseMo_12MoBack_db'
		WHERE CardNumber = '$CardNumber_db'
		AND FocusDate = '$FocusDate_db'";
		// ECHO $query8.PHP_EOL;
		$result16 = mysqli_query($dbc, $query16);	
		ECHO MYSQLI_ERROR($dbc);
	//END OF FOCUSMONTH LOOP
	}

// END OF CARD NUMBER WHILE LOOP
}





?>
