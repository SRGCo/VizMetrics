#!/usr/bin/php
<?php 



###### could we check to see when the last real transaction is and then just replicate entires for everyone 
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

$query1 = "SELECT DISTINCT(CardNumber) as CardNumber, EnrollDate FROM Guests_Master 
		WHERE CardNumber IS NOT NULL AND EnrollDate IS NOT NULL ORDER BY CardNumber ASC";
$result1 = mysqli_query($dbc, $query1);
ECHO MYSQLI_ERROR($dbc);
while($row1 = mysqli_fetch_array($result1, MYSQLI_ASSOC)){
	$CardNumber_db = $row1['CardNumber'];
	$EnrollDate_db = $row1['EnrollDate'];

	$query2 = "SELECT MIN(TransactionDate) as MinDate, POSkey FROM Master WHERE CardNumber = '$CardNumber_db'";
	$result2 = mysqli_query($dbc, $query2);
	ECHO MYSQLI_ERROR($dbc);
	while($row1 = mysqli_fetch_array($result2, MYSQLI_ASSOC)){
		$MinDate_db = $row1['MinDate'];
		$POSkey_db = $row1['POSkey'];

		IF($MinDate_db <> $EnrollDate_db){
			$counter ++;
			ECHO $CardNumber_db.' '.$EnrollDate_db.' '.$MinDate_db.' '.$POSkey_db.PHP_EOL;
			}
	}
}
ECHO $counter.PHP_EOL;
	
?>
