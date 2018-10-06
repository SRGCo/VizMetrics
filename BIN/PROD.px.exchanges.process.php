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
$no_counter = 0;
$counter = 0;


//QUERY EXCHANGES TABLE FOR CARDNUMBER
# NOT USING -- 	AND MOD(CardNumber, 200) = '0'
$query1 = "SELECT DISTINCT(CardNumber) as CardNumber FROM Master WHERE CardNumber IS NOT NULL 	
					AND TransactionDate IS NOT NULL ORDER BY TransactionDate ASC";
$result1 = mysqli_query($dbc, $query1);
ECHO MYSQLI_ERROR($dbc);
while($row1 = mysqli_fetch_array($result1, MYSQLI_ASSOC)){
	$CardNumber_db = $row1['CardNumber'];
	# FIND OUT IF THIS CARD WAS EXCHANGED
	$query2 = "SELECT CurrentCardNumber FROM Px_exchanges WHERE ExchangedCardNumber = '$CardNumber_db'";
	$result2 = mysqli_query($dbc, $query2);
	ECHO MYSQLI_ERROR($dbc);
	IF (mysqli_num_rows($result2)==0){ 
		# IF NOT AN EXCHANGE DO NOTHING
		$no_counter++;
		# echo $no_counter.') No exchange activity on this card number: '.$CardNumber_db.PHP_EOL;
	} ELSE {
		# IF IT WAS AN EXCHANGE UPDATE MASTER WITH NEWER CARD NUMBER
		while($row1 = mysqli_fetch_array($result2, MYSQLI_ASSOC)){
			$CurrentCardNumber_db = $row1['CurrentCardNumber'];
		}
		$counter++;
		# echo $counter.') This card '.$CardNumber_db.' was exchanged for '.$CurrentCardNumber_db.PHP_EOL;
		$query3 = "UPDATE Master SET CardNumber = '$CurrentCardNumber_db' WHERE CardNumber = '$CardNumber_db'";
		$result3 = mysqli_query($dbc, $query3);
		ECHO MYSQLI_ERROR($dbc);
	}
// END OF CARD NUMBER WHILE LOOP
}
ECHO 'Exchanged Counter = '.$counter.PHP_EOL;
ECHO 'Not Exchanged Counter = '.$no_counter.PHP_EOL;
?>


