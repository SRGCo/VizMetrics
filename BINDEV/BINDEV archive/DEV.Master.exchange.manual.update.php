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


//QUERY FOR CARDNUMBER

// WE COULD ALSO QUERY FOR POSkey (AFTER ADDING THE FIELD TO MONTHLY WHICH WOULD ALWAYS BE EMPTY)
// THEN ONLY INSERT THE RECORDS THAT HAVE A POSksy VALUE IN Master_Alt
$query1 = "SELECT ExchangedCardNumber, CurrentCardNumber FROM Px_exchanges ORDER BY ExchangedCardNumber ASC"; 
$result1 = mysqli_query($dbc, $query1);
ECHO MYSQLI_ERROR($dbc);
while($row1 = mysqli_fetch_array($result1, MYSQLI_ASSOC)){
	$ExchangedCardNumber_db = $row1['ExchangedCardNumber'];
	$CurrentCardNumber_db = $row1['CurrentCardNumber'];

	##### UPDATE THE Master TABLE TO REFLECT MOST RECENT CARDNUMBERS
	$query2 = "UPDATE Master SET CardNumber = '$CurrentCardNumber_db' WHERE CardNumber = '$ExchangedCardNumber_db'"; 
	$result2 = mysqli_query($dbc, $query2);
	ECHO MYSQLI_ERROR($dbc);
// END OF CARD NUMBER WHILE LOOP
}

$query3 = "UPDATE Master JOIN Guests_Master ON Master.CardNumber = Guests_Master.CardNumber 
				SET Master.EnrollDate = Guests_Master.EnrollDate, 
				Master.Account_status = Guests_Master.AccountStatus";
$result3 = mysqli_query($dbc, $query3);
ECHO MYSQLI_ERROR($dbc);
echo 'ACCOUNT STATUSES UPDATED FROM Guests_Master TABLE'



?>
