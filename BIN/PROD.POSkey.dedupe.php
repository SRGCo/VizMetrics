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


$query1 = "SELECT POSkey, COUNT(*) as HowMany FROM CardActivity_squashed_2 WHERE CardNumber IS NOT NULL AND POSkey is NOT NULL 
		group by POSkey HAVING HowMany > '1'";
$result1 = mysqli_query($dbc, $query1);
ECHO MYSQLI_ERROR($dbc);
while($row1 = mysqli_fetch_array($result1, MYSQLI_ASSOC))
{
	$POSkey_db = $row1['POSkey'];
	$HowMany_db = $row1['HowMany'];


	$query2 = "SELECT CardNumber, RIGHT(CardNumber, 6) as LastSix FROM CardActivity_squashed_2 WHERE POSkey = '$POSkey_db' 
						AND CardNumber IS NOT NULL ORDER BY CardNumber ASC";
	$result2 = mysqli_query($dbc, $query2);
	ECHO MYSQLI_ERROR($dbc);
	while($row1 = mysqli_fetch_array($result2, MYSQLI_ASSOC))
	{
		$CardNumber_db = $row1['CardNumber'];
		$LastSix_db = $row1['LastSix'];

		$NewPOSkey = $POSkey_db.$LastSix_db;

		$query3 = "UPDATE CardActivity_squashed_2 SET POSkey = '$NewPOSkey' WHERE POSkey = '$POSkey_db' 
				AND CardNumber = '$CardNumber_db'";
		$result3 = mysqli_query($dbc, $query3);
		ECHO MYSQLI_ERROR($dbc);

		$query4 = "INSERT INTO CheckDetail_Live SET POSkey = '$NewPOSkey'";
		$result4 = mysqli_query($dbc, $query4);
		ECHO MYSQLI_ERROR($dbc);

		# ECHO  'Card: '.$CardNumber_db.' Old POSKEY:'.$POSkey_db.' New:'.$NewPOSkey.' Updated CA, New CD record'.PHP_EOL;
	}


	$query5 = "DELETE from CheckDetail_Live WHERE POSkey = '$POSkey_db'";
	$result5 = mysqli_query($dbc, $query5);
	ECHO MYSQLI_ERROR($dbc);

	$query6 = "DELETE from CardActivity_squashed_2 WHERE POSkey = '$POSkey_db'";
	$result6 = mysqli_query($dbc, $query6);
	ECHO MYSQLI_ERROR($dbc);
}
echo 'DONE'.PHP_EOL;;
?>


