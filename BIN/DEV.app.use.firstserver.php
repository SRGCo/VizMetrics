#!/usr/bin/php
<?php 



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


##### GET ALL THE Activation CARDNUMBERS
##### THE STANDARD CARD ACTIVITY 
$query1 = "SELECT CardNumber FROM `CardActivity_Live` WHERE TransactionType = 'Activate' AND (CheckNo like 'i%' or CheckNo LIKE 'And%') GROUP BY CardNumber";
$result1 = mysqli_query($dbc, $query1);
ECHO MYSQLI_ERROR($dbc);
while($row1 = mysqli_fetch_array($result1, MYSQLI_ASSOC)){
	$CardNumber_db = $row1['CardNumber'];
	echo $CardNumber_db.PHP_EOL;

	##### QUERY FOR THE MIN TRANSACTION WHERE MORE THAN 0 WAS SPENT
	$query2 = "SELECT MIN(transactiondate) as mindate, firstname, lastname, CheckNumber, GrossSalesCoDefined, LocationID FROM SRG_Prod.Master WHERE CardNumber = '$CardNumber_db' and SereniteePointsAccrued > '0'";
	$result2 = mysqli_query($dbc, $query2);
	ECHO MYSQLI_ERROR($dbc);
	while($row1 = mysqli_fetch_array($result2, MYSQLI_ASSOC)){
		$mindate_db = $row1['mindate'];
		$firstname_db = $row1['firstname'];
		$lastname_db = $row1['lastname'];
		$checkno_db = $row1['CheckNumber'];
		$GrossSalesCoDefined_db = $row1['GrossSalesCoDefined'];
		$LocationID_db = $row1['LocationID'];

		$query3 = "SELECT Name FROM Locations WHERE ID = '$LocationID_db'";
		$result3 = mysqli_query($dbc, $query3);
		ECHO MYSQLI_ERROR($dbc);
		while($row1 = mysqli_fetch_array($result3, MYSQLI_ASSOC)){
			$location_db = $row1['Name'];
		}

		##### CHECK USEAGE TABLE FOR TO AVOID DUPES FROM PAST RUNS
		$query3a = "SELECT Record_id FROM App_Use1 WHERE CardNumber = '$CardNumber_db'";
		$result3a = mysqli_query($dbc, $query3a);
		ECHO MYSQLI_ERROR($dbc);
		if(mysqli_num_rows($result3a)==0){
			# ECHO 'Rows: '.(mysqli_num_rows($result3a)).PHP_EOL;
			$Not_dupe = 'T';
		} ELSE {
			# ECHO 'Rows: '.(mysqli_num_rows($result3a)).PHP_EOL;
			$Not_dupe = 'F';
		}
		

		echo $CardNumber_db.' Not Dupe = '.$Not_dupe.' '.$location_db.' '.$lastname_db.' '.$mindate_db.' '.$GrossSalesCoDefined_db.PHP_EOL;
		

		If (($mindate_db <> '') && ($Not_dupe <> 'F')) {
			##### INSERT IT INTO TABLE
			$query4 = "INSERT INTO App_Use1 set CardNumber = '$CardNumber_db',
							Firstname = '$firstname_db',
							Lastname = '$lastname_db',
							Location = '$location_db',
							Checkno = '$checkno_db',
							TransactionDate = '$mindate_db'";
			$result4 = mysqli_query($dbc, $query4);
			ECHO MYSQLI_ERROR($dbc);
		}
	}		

}
echo 'DONE'.PHP_EOL;
?>


