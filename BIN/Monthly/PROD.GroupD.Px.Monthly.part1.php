#!/usr/bin/php
<?php 

##########################################################################################################
################## THIS SCRIPT IS A CATCHALL FOR ACCOUNTS ENROLLED AFTER JAN 2 2019  #####################
##########################################################################################################

###### could we check to see when the last real transaction is and then just replicate entries for everyone 
### between that date and the focusmonth ? ? 

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
$printcount = 0;

### WE ONLY TRUNCATE THE TABLE BEFORE RUNNING THE FIRST GROUP #################

//QUERY MASTER FOR CARDNUMBER (MAIN QUERY1)
// ******************************** 2019 - 2030 ***************************
$query1 = "SELECT DISTINCT(CardNumber) as CardNumber FROM Guests_Master WHERE CardNumber IS NOT NULL 	
					AND EnrollDate > '2019-01-02' AND EnrollDate < '2030-01-01'
					AND AccountStatus = 'ACTIVE' ORDER BY CardNumber ASC";
$result1 = mysqli_query($dbc, $query1);
ECHO MYSQLI_ERROR($dbc);
while($row1 = mysqli_fetch_array($result1, MYSQLI_ASSOC)){
	$CardNumber_db = $row1['CardNumber'];


#echo 'Cardnumber:'.$CardNumber_db.' Counter:'.$counter.' Printcount:'.$printcount.PHP_EOL;

	#INIT THE VARS
	$MinDateMonth_db = $MinDateYear_db = $FocusDate = $FocusDateEnd = '';
	$CurrentDate_db = $FirstName_db = $LastName_db = $EnrollDate_db = $Zip_db = '';	

	$DollarsSpentLife_db = $PointsRedeemedLife_db = $PointsAccruedLife_db = $VisitsAccruedLife_db = '0';
	$DollarsSpentMonth_db = $PointsRedeemedMonth_db = $PointsAccruedMonth_db = $VisitsAccruedMonth_db = '0';

	$LastVisitDate_db = $PrevYearVisitBal_db = $LapseDays_db = $RecentFreqDays_db = $ProgAge_db = '';	
	$TwoVisitsBack_db = $FocusDate_php = $TwoVisitsBack_php = $MonthsEnrolled_db = $LifetimeFreq = '';
	$YearFreqSeg = $RecentFreqMonths_db = $TwoVisitsBack_php = $YrAgoFreq = $LastVisitBalance_db = '';
	$Discounts_db = $Account_status_db = $Card_status_db = '';

	
	$Carryover_LastVisitDate = '';
	
	
	#firstrun is for debugging
	$Firstrun = 'Yes';
	// PRINT COUNTER ENTRY EVERY 1000 CARDNUMBERS
	// ************ THIS IS NOT WORKING, COUNT - CARD NUMBERS NOT PRINTING *************
	$counter++;
	$printcount = fmod($counter, 100);
	IF ($printcount == '0'){
		ECHO PHP_EOL.$counter++.'  card:';
		ECHO $CardNumber_db;
	}

	#### GET THE MIN AND MAX TRANSACTIONDATE AND THE MAX VISIT BALANCE
##### WE AREN'T USING MAXDATE / END AS A MEANS OF ITERATING ANYMORE, SHOULD WE REMOVE IT?
	$query2 = "SELECT MAX(VM_VisitsBalance) as VisitsAccruedLife, 
				CURDATE() as TodayDate 
				FROM Master WHERE CardNumber = '$CardNumber_db'";
	$result2 = mysqli_query($dbc, $query2);	
	ECHO MYSQLI_ERROR($dbc);
	while($row1 = mysqli_fetch_array($result2, MYSQLI_ASSOC)){
		$VisitsAccruedLife_db = $row1['VisitsAccruedLife'];
		$CurrentDate_db = $row1['TodayDate'];
	}
	IF ($VisitsAccruedLife_db == ''){$VisitsAccruedLife_db = '0';}
	
	# GET FIRSTNAME, LASTNAME, ENROLLDATE, ZIP
	$query3 = "SELECT FirstName, LastName, EnrollDate, Zip, Tier,
				YEAR(EnrollDate) as MinDateYear,
				DATE_FORMAT(EnrollDate, '%m') as MinDateMonth
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
	
	// FORMAT FOCUSDATE
	$FocusDate = $MinDateYear_db."-".$MinDateMonth_db."-01"; 
	$FocusDateEnd = date("Y-m-d",strtotime($FocusDate."+1 month -1 day"));
	$FocusDate_php = strtotime($FocusDate);
	$EnrollDate_db_php = strtotime($EnrollDate_db);

#ECHO 'Curdate'.$CurrentDate_db.' FD:'.$FocusDate.' FDE'.$FocusDateEnd.PHP_EOL;	


	// WHILE FOCUSDATE IS LESS THAN TODAYS DATE REPEAT QUERIES
	WHILE ($FocusDate <= $CurrentDate_db){
	
		#FIELDS = LIFETIMESPENDBALANCE, LIFETIMEPOINTSREDEEMED, LIFETIMEPOINTSBALANCE, LIFETIMEVISITBALANCE
		$query3a ="SELECT ROUND(SUM(DollarsSpentAccrued), 2) as DollarsSpentLife, 
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

		IF (EMPTY($DollarsSpentLife_db)){
			$DollarsSpentLife_db = '0.00';
		}

		#####GET NUMBERS FOR FOCUSMONTH
		#FIELDS = DISCOUNTS(CALCD), DOLLARSSPENTMONTH, POINTSREDEEMEDMONTH, POINTSACCRUEDMONTH, VISITSACCRUEDMONTH
		$query4 = "SELECT
			ROUND((GrossSalesCoDefined - NetSalesCoDefined), 2) as DiscountsMonth,
			ROUND(SUM(DollarsSpentAccrued), 2) as DollarsSpentMonth,
			SUM(SereniteePointsRedeemed) as PointsRedeemedMonth,
			SUM(SereniteePointsAccrued) as PointsAccruedMonth,
			SUM(Vm_VisitsAccrued) as VisitsAccruedMonth                   
			FROM Master WHERE  CardNumber = '$CardNumber_db'
			AND DollarsSpentAccrued IS NOT NULL
			AND DollarsSpentAccrued > '0'
			AND TransactionDate >= '$FocusDate'
			AND TransactionDate <= '$FocusDateEnd'";
		$result4 = mysqli_query($dbc, $query4);	
		ECHO MYSQLI_ERROR($dbc);
		while($row1 = mysqli_fetch_array($result4, MYSQLI_ASSOC)){
			$DiscountsMonth_db = $row1['DiscountsMonth'];
			$DollarsSpentMonth_db = $row1['DollarsSpentMonth'];
			$PointsRedeemedMonth_db = $row1['PointsRedeemedMonth'];
			$PointsAccruedMonth_db = $row1['PointsAccruedMonth'];
			$VisitsAccruedMonth_db = $row1['VisitsAccruedMonth'];
		}

		IF (EMPTY($DollarsSpentMonth_db)){
			$DollarsSpentMonth_db = '0.00';
		}
		IF (EMPTY($DiscountsMonth_db)){
			$DiscountsMonth_db = '0.00';
		}

		$YearFreqSeg = $RecentFreqMonths_db = $TwoVisitsBack_php = $YrAgoFreq = $LastVisitBalance_db = '';
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
			IF ($Firstrun == 'Yes'){
				$LastVisitDate_db = $EnrollDate_db;
				$Firstrun = 'No';
			} ELSE {
				$LastVisitDate_db = $Carryover_LastVisitDate;
				$Firstrun = 'No';
			}
		} ELSE { $Firstrun = 'No';}

		##################### NEED TO VERIFY BOTH LAPSEDAYS AND FREQRECENTDAYS (RECENTLAPSE)
		#FIELD = LAPSEDAYS
		$query6= "SELECT DATEDIFF('$FocusDate', '$LastVisitDate_db') as LapseDays";
		$result6 = mysqli_query($dbc, $query6);	
		ECHO MYSQLI_ERROR($dbc);
		while($row1 = mysqli_fetch_array($result6, MYSQLI_ASSOC)){
			$LapseDays_db = $row1['LapseDays'];	
		}
		IF (EMPTY($LapseDays_db)){
			$LapseDays_db = '0';
		}

		####### IF LAPSE WASN'T CORRECT THIS IS MOST LIKELY WRONG
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
				
			}
		}

		##### GET NUMBER OF MONTHS BETWEEN ENROLLDATE AND FOCUSDATE  (+1 for marks numbers)
		#PROGRAMAGE
		$query7= "SELECT (TIMESTAMPDIFF(MONTH, '$EnrollDate_db', '$FocusDate') + 1) AS ProgAge";
		$result7 = mysqli_query($dbc, $query7);	
		ECHO MYSQLI_ERROR($dbc);
		while($row1 = mysqli_fetch_array($result7, MYSQLI_ASSOC)){
			$ProgAge_db = $row1['ProgAge'];		
		}

		##### GET NUMBER OF MONTHS BETWEEN ENROLLDATE AND FOCUSDATE 
		#FIELD = LIFETIMEFREQ
		$query7x= "SELECT TIMESTAMPDIFF(MONTH, '$EnrollDate_db', '$FocusDate') AS MonthsEnrolled";
		$result7x = mysqli_query($dbc, $query7x);	
		ECHO MYSQLI_ERROR($dbc);
		while($row1 = mysqli_fetch_array($result7x, MYSQLI_ASSOC)){
			$MonthsEnrolled_db = $row1['MonthsEnrolled'];		
		}
#ECHO 'MonthsEnrolled_db='.$MonthsEnrolled_db.PHP_EOL;	
		IF (($MonthsEnrolled_db == '0') OR ($MonthsEnrolled_db == '')){
			$LifetimeFreq = '';
		} ELSE {
			$LifetimeFreq = ($VisitsAccruedLife_db / $MonthsEnrolled_db);			
		}


		#FIELD RECENTFREQMONTHS
		$query7e= "SELECT TIMESTAMPDIFF(MONTH, '$TwoVisitsBack_db', '$FocusDate') AS RecentFreqMonths";
		$result7e = mysqli_query($dbc, $query7e);	
		ECHO MYSQLI_ERROR($dbc);
		while($row1 = mysqli_fetch_array($result7e, MYSQLI_ASSOC)){
			$RecentFreqMonths_db = $row1['RecentFreqMonths'];
			# ECHO 'RecentFreqMonths_db'.$RecentFreqMonths_db.PHP_EOL;
		}

		#FIELD LAPSEMONTHS
		$query7e= "SELECT TIMESTAMPDIFF(MONTH, '$LastVisitDate_db', '$FocusDate') AS LapseMonths";
		$result7e = mysqli_query($dbc, $query7e);	
		ECHO MYSQLI_ERROR($dbc);
		while($row1 = mysqli_fetch_array($result7e, MYSQLI_ASSOC)){
			$LapseMonths_db = $row1['LapseMonths'];
			# ECHO 'LapseMonths_db'.$LapseMonths_db.PHP_EOL;
		}

		#ACCOUNT AND STATUS
		$query7f= "SELECT Account_status, Card_status FROM Master WHERE CardNumber = '$CardNumber_db' LIMIT 1";
		$result7f = mysqli_query($dbc, $query7f);	
		ECHO MYSQLI_ERROR($dbc);
		while($row1 = mysqli_fetch_array($result7f, MYSQLI_ASSOC)){
			$Account_status_db = $row1['Account_status'];
			$Card_status_db = $row1['Card_status'];
		}


		/////// INSERT VALUES INTO THE TABLE HERE
		$query8= "INSERT INTO Px_Monthly SET CardNumber = '$CardNumber_db',
				FocusDate = '$FocusDate',
				FirstName = '$FirstName_db',
				LastName = '$LastName_db',
				EnrollDate = '$EnrollDate_db',
				Zip = '$Zip_db',
				Tier = '$Tier_db',
				Discounts = '$DiscountsMonth_db',
				DollarsSpentMonth = '$DollarsSpentMonth_db',
				PointsRedeemedMonth = '$PointsRedeemedMonth_db',
				PointsAccruedMonth = '$PointsAccruedMonth_db',
				VisitsAccruedMonth = '$VisitsAccruedMonth_db',
				LifetimeSpendBalance = '$DollarsSpentLife_db',
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
				Account_status = '$Account_status_db',
				Card_status = '$Card_status_db',
				LifetimeVisitBalance = '$VisitsAccruedLife_db'";
				// ECHO $query8.PHP_EOL;
		$result8 = mysqli_query($dbc, $query8);	
		if(!$result8){ECHO $query8.' ';}
		ECHO MYSQLI_ERROR($dbc);

		$FocusDate = date("Y-m-d",strtotime($FocusDate." +1 month "));
		$FocusDateEnd = date("Y-m-d",strtotime($FocusDate." +1 month - 1 day "));
		$Carryover_LastVisitDate = $LastVisitDate_db;

	// END OF WHILE FOCUSDATE LESS THAN TODAY (MAIN QUERY2)
	}

	### WE'LL PRINT EXTENDED INFO FOR COUNTER ACCOUNTS, JUST TO SEE IF ANYTHING LOOKS WONKY
	IF ($printcount == '0'){
		ECHO ' FirstName: '.$FirstName_db.' LastName: '.$LastName_db.' FirstRun:'.$Firstrun;
		ECHO PHP_EOL.'             Zip:'.$Zip_db.' Tier:'.$Tier_db.' Enrolled: '.$EnrollDate_db;
		ECHO PHP_EOL.'             FocusDate:'.$FocusDate.' Last Visit Date: '.$LastVisitDate_db;
		ECHO PHP_EOL.'             LifetimeSpend:'.$DollarsSpentLife_db.' LapseMonths: '.$LapseMonths_db;
		ECHO PHP_EOL.'             Lifetime Visits: '.$VisitsAccruedLife_db;
	}


// END OF CARD NUMBER WHILE LOOP (MAIN QUERY1)
}



// CLEAN UP THE ENTRIES THAT COULD NOT HAVE BEEN CALC'D CORRECTLY
$Query18 = "DELETE FROM Px_Monthly WHERE LastName = 'Test' or LastName = 'test' or FirstName = 'Serenitee'";
$result18 = mysqli_query($dbc, $Query18);
ECHO MYSQLI_ERROR($dbc);
################ WE COULE BREAK THE SCRIPT HERE AND POSSIBLY GET IT TO RUN FASTER
ECHO PHP_EOL.'Count of accounts processed: '.$counter


?>


