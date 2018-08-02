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

// TRUNCATE table Px_Monthly_alt"
$query_table= "TRUNCATE table Master_Alt";
$result_table = mysqli_query($dbc, $query_table);	
ECHO MYSQLI_ERROR($dbc);
ECHO 'Truncated Master_Alt';

//QUERY FOR CARDNUMBER

// WE COULD ALSO QUERY FOR POSkey (AFTER ADDING THE FIELD TO MONTHLY WHICH WOULD ALWAYS BE EMPTY)
// THEN ONLY INSERT THE RECORDS THAT HAVE A POSksy VALUE IN Master_Alt
$query1 = "SELECT CardNumber FROM 
		(SELECT CardNumber FROM Master UNION ALL SELECT CardNumber FROM Px_Monthly) 
			tbl GROUP BY CardNumber HAVING count(*) = 1 ORDER BY CardNumber";
$result1 = mysqli_query($dbc, $query1);
ECHO MYSQLI_ERROR($dbc);
while($row1 = mysqli_fetch_array($result1, MYSQLI_ASSOC)){
	$CardNumber_db = $row1['CardNumber'];
	$query2 = "INSERT into Master_Alt
			SELECT * FROM Master
			WHERE CardNumber = '$CardNumber_db'";
	$result2 = mysqli_query($dbc, $query2);
	ECHO MYSQLI_ERROR($dbc);



// END OF CARD NUMBER WHILE LOOP
}




?>
