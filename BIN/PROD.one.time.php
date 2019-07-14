#!/usr/bin/php
<?php 
################### DUMMY1 INT BY DEFAULT STRUCTURE


###### could we check to see when the last real transaction is and then just replicate entries for everyone 
### between that date and the focusmonth ? ? 

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
#INIT THE VARS
$CardNumber_db = $CheckNo_db = $TransactionDate_db = $LocationID_db = '';


//QUERY MASTER FOR CARDNUMBER (MAIN QUERY1)
$query1 = "SELECT CardNumber, CheckNo, TransactionDate, LocationID FROM CardActivity_w_checkin_type 
			WHERE CardNumber IS NOT NULL AND (CheckNo Like 'iOS' OR CheckNo like 'And%') AND TransactionDate > '2018-08-01' ORDER BY CardNumber ASC";
$result1 = mysqli_query($dbc, $query1);
ECHO MYSQLI_ERROR($dbc);
while($row1 = mysqli_fetch_array($result1, MYSQLI_ASSOC)){
	$CardNumber_db = $row1['CardNumber'];
	$CheckNo_db = $row1['CheckNo'];
	$TransactionDate_db = $row1['TransactionDate'];
	$LocationID_db = $row1['LocationID'];

	//QUERY MASTER FOR CARDNUMBER (MAIN QUERY1)
	$query2 = "UPDATE Master SET Dummy1 = '$CheckNo_db' WHERE CardNumber = '$CardNumber_db' AND TransactionDate = '$TransactionDate_db' AND LocationID = '$LocationID_db'";
	$result2 = mysqli_query($dbc, $query2);
	ECHO MYSQLI_ERROR($dbc);

ECHO $CardNumber_db.PHP_EOL;	

}


?>

