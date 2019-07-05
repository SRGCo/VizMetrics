#!/usr/bin/php
<?php 
##### BEFORE PROCESSING LETS MAKE A BACK UP JUST IN CASE
exec('mysqldump -uroot -ps3r3n1t33 SRG_Prod Px_Monthly > /home/ubuntu/db_files/PROD.Px_Monthly.$(date +%Y-%m-%d-%H.%M.%S).sql');
echo 'PX MONTHLY TABLE BACKED UP';


function yrseg ($pastvisitbal, $lifetimevisits)
{
	 $segment_txt = '';

	if (($pastvisitbal == '0') AND ($lifetimevisits > '0')) $segment_txt = 'Dropout';
	elseif (($pastvisitbal == '0') AND ( $lifetimevisits == '0')) $segment_txt = 'Zombie';
	elseif (($pastvisitbal >= '1') AND ($pastvisitbal <= '2'))  $segment_txt = '1-2';
	elseif (($pastvisitbal >= '3') AND ($pastvisitbal <= '4')) $segment_txt = '3-4';
	elseif (($pastvisitbal >= '5') AND ($pastvisitbal <= '10'))  $segment_txt = '5-10';
	elseif (($pastvisitbal >= '11') AND ($pastvisitbal <= '25'))  $segment_txt = '11-25';
	elseif ($pastvisitbal >= '26') $segment_txt = '26+';

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
define ('DB_NAME','SRG_Prod');

# Make the connection and then select the database
# display errors if fail
$dbc = mysqli_connect(DB_HOST, DB_USER, DB_PASSWORD)
	or die('Could not connect to mysql:'.MYSQLI_ERROR($dbc) );
mysqli_select_db($dbc, DB_NAME)
	OR die('Could not connect to the database:'.MYSQLI_ERROR($dbc));

### INIT Variables
$counter = 0;
$VisitsAccruedLife_db = '0';

//QUERY PX_MONTHLY FOR CARDNUMBER
# NOT USING -- 	AND MOD(CardNumber, 200) = '0'
$query1 = "SELECT CardNumber as CardNumber, MAX(LifetimeVisitBalance) as VisitsAccruedLife FROM Px_Monthly	
		GROUP BY CardNumber ORDER BY CardNumber ASC";
$result1 = mysqli_query($dbc, $query1);
ECHO MYSQLI_ERROR($dbc);
while($row1 = mysqli_fetch_array($result1, MYSQLI_ASSOC)){
	$CardNumber_db = $row1['CardNumber'];
	$VisitsAccruedLife_db = $row1['VisitsAccruedLife'];
	
	#INIT THE VARS
	$YrMoVisitBal_1MoBack_db = $YrMoVisitBal_3MoBack_db = $LapseMo_12MoBack_db = $YrMoVisitBal_12MoBack_db = '';
	$YrMoVisitBal_24MoBack_db = $YrMoVisitBal_36MoBack_db = $YrMoFreqSeg_24MoBack_txt = $YrMoFreqSeg_36MoBack_txt = '';
	$YrMoFreqSeg_12MoBack_txt = $YrMoFreqSeg_3MoBack_txt = $YrMoFreqSeg_1MoBack_txt = $YrMoFreq_1YrBack_txt = '';
	$LastVisitDate_db = $PrevYearVisitBal_db = $LapseDays_db = $RecentFreqDays_db = $ProgAge_db = '';	
	$Carryover_LastVisitDate = '';

	// PRINT COUNT EVERY 5000 CARDNUMBERS
	$counter++;
	$printcount = fmod($counter, 1000);
	IF ($printcount == '0'){
	ECHO PHP_EOL.$counter++.'  card:';
	ECHO $CardNumber_db;
	}

	
	###### NOW SELECT THE FOCUSDATE AND PROCESS
	$query2 = "SELECT FocusDate FROM Px_Monthly where CardNumber = '$CardNumber_db'	
					ORDER BY FocusDate DESC";
	$result2 = mysqli_query($dbc, $query2);
	ECHO MYSQLI_ERROR($dbc);
	while($row1 = mysqli_fetch_array($result2, MYSQLI_ASSOC)){
		$FocusDate_db = $row1['FocusDate'];
	
	 	$segment_txt = '';

		#FIELDS = 12MOVISITBALANCE (PHP=PREVYEARVISITBALANCE)
		$query5= "SELECT 12MoVisitBalance as PrevYearVisitBal
				FROM Px_Monthly 
				WHERE CardNumber = '$CardNumber_db'
				AND FocusDate = '$FocusDate_db'";
		$result5 = mysqli_query($dbc, $query5);	
		ECHO MYSQLI_ERROR($dbc);
		while($row1 = mysqli_fetch_array($result5, MYSQLI_ASSOC)){
			$PrevYearVisitBal_db = $row1['PrevYearVisitBal'];
		}
		IF ($PrevYearVisitBal_db == ''){$PrevYearVisitBal_db = '0';}
	

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

/* set autocommit to off */
mysqli_autocommit($dbc, FALSE);

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

/* commit transaction */
if (!mysqli_commit($dbc)) {
   ECHO 'Commit INSERT Transaction Failed - PROD.Px.Monthly.part2.php'.PHP_EOL;
    exit();
}

/* close connection */
mysqli_close($dbc);


	# ECHO 'Cardnumber: ',$CardNumber_db,' FocusDate: ',$FocusDate_db,PHP_EOL;
	//END OF FOCUSMONTH LOOP
	}
# ECHO '+++++++++++++++ Cardnumber: ',$CardNumber_db,' FocusDate: ',$FocusDate_db,PHP_EOL;
// END OF CARD NUMBER WHILE LOOP
}
ECHO PHP_EOL.'ALL CARDS PAST FREQUENCY UPDATED FOR ALL FOCUSDATES'.PHP_EOL;


##### AFTER WE FINISH ALL THAT PROCESSING LETS MAKE A BACK UP JUST IN CASE
exec('mysqldump -uroot -ps3r3n1t33 SRG_Prod Px_Monthly > /home/ubuntu/db_files/PROD.Px_Monthly.$(date +%Y-%m-%d-%H.%M.%S).sql');
echo 'PX MONTHLY TABLE BACKED UP';


?>
