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

$query1a = "DROP TABLE IF EXISTS Master_temp";
$result1a = mysqli_query($dbc, $query1a);
ECHO MYSQLI_ERROR($dbc);
:set 
$query1b = "CREATE TABLE Master_temp LIKE Master_structure";
$result1b = mysqli_query($dbc, $query1b);
ECHO MYSQLI_ERROR($dbc);

# Create enroll_date and Account_status fields
$query1c =  "ALTER TABLE Master_temp ADD EnrollDate VARCHAR(11), ADD Account_status VARCHAR(15), ADD Card_status VARCHAR(15)";
$result1c = mysqli_query($dbc, $query1c);
ECHO MYSQLI_ERROR($dbc);


$query1 = "SELECT DISTINCT(CardNumber) as CardNumber, EnrollDate, EnrollStoreCode, AccountStatus 
		FROM Guests_Master WHERE CardNumber IS NOT NULL AND EnrollDate IS NOT NULL ORDER BY CardNumber ASC";
$result1 = mysqli_query($dbc, $query1);
ECHO MYSQLI_ERROR($dbc);
while($row1 = mysqli_fetch_array($result1, MYSQLI_ASSOC)){
	$CardNumber_db = $row1['CardNumber'];
	$EnrollDate_db = $row1['EnrollDate'];
	$EnrollDate_alt = str_replace("-","",$EnrollDate_db);
	$EnrollStoreCode_db = $row1['EnrollStoreCode'];
	$AccountStatus_db = $row1['AccountStatus'];
	$LocationID_db = '0';

	ECHO $CardNumber_db.' '.$EnrollDate_db.' EDAlt:'.$EnrollDate_alt;			

	$query2 = "SELECT MIN(TransactionDate) as MinDate, POSkey FROM Master WHERE CardNumber = '$CardNumber_db'";
	$result2 = mysqli_query($dbc, $query2);
	ECHO MYSQLI_ERROR($dbc);
	while($row1 = mysqli_fetch_array($result2, MYSQLI_ASSOC)){
		$MinDate_db = $row1['MinDate'];
		$POSkey_db = $row1['POSkey'];

		IF($MinDate_db <> $EnrollDate_db){
			$counter ++;
			ECHO ' MD:'.$MinDate_db.' '.$POSkey_db;			
		
			#### INSERT A NEW RECORD INTO MASTER WITH A NEW POSKEY
			$query3 = "SELECT ID from Locations WHERE PXID = '$EnrollStoreCode_db'";
			$result3 = mysqli_query($dbc, $query3);
			ECHO MYSQLI_ERROR($dbc);
			while($row1 = mysqli_fetch_array($result3, MYSQLI_ASSOC)){
				$LocationID_db = $row1['ID'];
			}
			echo ' Loc:'.$LocationID_db;
			$query4 = "INSERT INTO Master_temp set 
				POSkey = CONCAT_WS('', '$LocationID_db', '$EnrollDate_alt', RIGHT('$CardNumber_db', 4)),
				POSKey_px = CONCAT_WS('', '$LocationID_db', '$EnrollDate_alt', RIGHT('$CardNumber_db', 4)),
				LocationID = '$LocationID_db',
				LocationID_px = '$LocationID_db',
				dob = '$EnrollDate_db',
				TransactionDate = '$EnrollDate_db',
				CheckNumber = '0',
				CardNumber = '$CardNumber_db',
				CardTemplate = 'Serenitee Loyalty',
				CheckNo_px = '0',
				EnrollDate = '$EnrollDate_db',
				Account_status = '$AccountStatus_db'";
			$result4 = mysqli_query($dbc, $query4);
			ECHO MYSQLI_ERROR($dbc);

		}
	}
echo PHP_EOL;
}
$query5 = "INSERT INTO Master SELECT * FROM Master_temp";
$result5 = mysqli_query($dbc, $query5);
ECHO MYSQLI_ERROR($dbc);


ECHO $counter.PHP_EOL;
	
?>
