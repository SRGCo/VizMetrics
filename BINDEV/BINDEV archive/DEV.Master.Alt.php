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
$query1 = "SELECT CardNumber FROM Master_Alt ORDER BY CardNumber"; 
$result1 = mysqli_query($dbc, $query1);
ECHO MYSQLI_ERROR($dbc);
while($row1 = mysqli_fetch_array($result1, MYSQLI_ASSOC)){
	$CardNumber_db = $row1['CardNumber'];
	$query4 = "SELECT MAX(POSkey) as POSkey from Master
			WHERE CardNumber = '$CardNumber_db'";
	$result4 = mysqli_query($dbc, $query4);
	ECHO MYSQLI_ERROR($dbc);
	while($row1 = mysqli_fetch_array($result4, MYSQLI_ASSOC)){
		$POSkey_db = $row1['POSkey'];
		ECHO $CardNumber_db.' '.$POSkey_db.' '.PHP_EOL;
		IF ($POSkey_db >= '1'){
			$query3 = "UPDATE Master_Alt
				SET LifetimeSpendBalance = 'MA'
				WHERE CardNumber = '$CardNumber_db'";
						
		} ELSE {
			$query3 = "UPDATE Master_Alt
				SET LifetimeSpendBalance = 'PX'
				WHERE CardNumber = '$CardNumber_db'";
				echo 'PX'.PHP_EOL;

	
		}

	$result3 = mysqli_query($dbc, $query3);
	ECHO MYSQLI_ERROR($dbc);
	

	}




// END OF CARD NUMBER WHILE LOOP
}




?>
