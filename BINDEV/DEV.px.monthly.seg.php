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
if ($YrMoVisitBal_12MoBack_db == '') {$YrMoFreqSeg_12MoBack_txt = 'Never Started';
} ELSE {
	if ($YrMoVisitBal_12MoBack_db == '0') {$YrMoFreqSeg_12MoBack_txt = 'Dropout';
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





if ($YrMoVisitBal_3MoBack_db == '0'){$YrMoFreqSeg_3MoBack_txt = 'Dropout';
} ELSE {
if ($YrMoVisitBal_3MoBack_db == '0'){$YrMoFreqSeg_3MoBack_txt = 'Dropout';}
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
}}}}}}}}

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




if ($YrMoVisitBal_1MoBack_db == '0'){$YrMoFreqSeg_1MoBack_txt = 'Dropout';
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
}}}}}}}}


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


if ($YrAgoFreq == '0'){$YrMoFreq_1YrBack_txt = 'Dropout';
} ELSE {
if (($YrAgoFreq >= '1') AND ($YrAgoFreq <= '2'))  {$YrMoFreq_1YrBack_txt = '1-2';
} ELSE {
if (($YrAgoFreq >= '3') AND ($YrAgoFreq <= '4'))  {$YrMoFreq_1YrBack_txt = '3-4';
} ELSE {
if (($YrAgoFreq >= '5') AND ($YrAgoFreq <= '7'))  {$YrMoFreq_1YrBack_txt = '5-7';
} ELSE {
if (($YrAgoFreq >= '8') AND ($YrAgoFreq <= '10'))  {$YrMoFreq_1YrBack_txt = '8-10';
} ELSE {
if (($YrAgoFreq >= '11') AND ($YrAgoFreq <= '14'))  {$YrMoFreq_1YrBack_txt = '11-14';
} ELSE {
if (($YrAgoFreq >= '15') AND ($YrAgoFreq <= '26'))  {$YrMoFreq_1YrBack_txt = '15-26';
} ELSE {
if ($YrAgoFreq >= '26') {$YrMoFreq_1YrBack_txt = '26+';
}}}}}}}}


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


