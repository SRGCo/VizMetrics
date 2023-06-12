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
define ('DB_NAME','SRG_Dev');

# Make the connection and then select the database
# display errors if fail
$dbc = mysqli_connect(DB_HOST, DB_USER, DB_PASSWORD)
	or die('Could not connect to mysql:'.MYSQLI_ERROR($dbc) );
mysqli_select_db($dbc, DB_NAME)
	OR die('Could not connect to the database:'.MYSQLI_ERROR($dbc));


### INIT Variables
$counter = 0;


//QUERY EXCHANGES TABLE FOR CARDNUMBER
# NOT USING -- 	AND MOD(CardNumber, 200) = '0'
$query1 = "SELECT ExchangedCardNumber, CurrentCardNumber FROM Px_exchanges WHERE CardTemplate = 'Serenitee Loyalty' 	
					AND TransactionDate IS NOT NULL ORDER BY TransactionDate ASC";
$result1 = mysqli_query($dbc, $query1);
ECHO MYSQLI_ERROR($dbc);
while($row1 = mysqli_fetch_array($result1, MYSQLI_ASSOC)){
	$ExchangedCardNumber_db = $row1['ExchangedCardNumber'];
	$CurrentCardNumber_db = $row1['CurrentCardNumber'];
	# ECHO $ExchangedCardNumber_db.' '.$CurrentCardNumber_db.' ';

	# UPDATE THE CARD STATUS FOR ALL CURRENT (EXCHANGED) CARDS
	$query3 = "UPDATE Master SET Card_status = 'Exchange' WHERE CardNumber = '$CurrentCardNumber_db'";
	$result3 = mysqli_query($dbc, $query3);
	ECHO MYSQLI_ERROR($dbc);
	

	# FIND LAST DATE OLD CARD NUMBER USED
	$query2 = "SELECT MAX(TransactionDate) as MaxDate FROM Master WHERE CardNumber = 'ExchangedCardNumber_db'";
	$result2 = mysqli_query($dbc, $query2);
	ECHO MYSQLI_ERROR($dbc);
	while($row1 = mysqli_fetch_array($result2, MYSQLI_ASSOC)){
		$MaxDate_db = $row1['MaxDate'];
		# ECHO $MaxDate_db.PHP_EOL;
		$counter++;
		# UPDATE THE OLD CARD NUMBER TO THE NEW AND SET THE CARD STATUS
		$query3 = "UPDATE Master SET CardNumber = '$CurrentCardNumber_db', Card_status = 'Exchange' WHERE CardNumber = '$ExchangedCardNumber_db'";
		$result3 = mysqli_query($dbc, $query3);
		ECHO MYSQLI_ERROR($dbc);
	}
// END OF CARD NUMBER WHILE LOOP
}
ECHO $counter.PHP_EOL;
?>


