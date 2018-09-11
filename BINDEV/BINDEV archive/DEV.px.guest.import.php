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


############ We will insert into a guest temp table, do the income updates etc, then write to master table




while ($data = fgetcsv($handle, 1000, ",")) {
    $data = array_map('mysql_real_escape_string', $data);
    $query = "INSERT INTO Px_Guests_temp(`regid`, `firstname`, `lastname`, `email`, `company`) VALUES('".$data[0]."', '".$data[1]."', '".$data[2]."', '".$data[3]."', '".$data[4]."') ON DUPLICATE KEY UPDATE REGID='".$data[0]."', firstname='".$data[1]."', lastname='".$data[2]."', email= '".$data[3]."', company= '".$data[4]."'";
    $result = mysql_query($query) or die("Invalid query: " . mysql_error().__LINE__.__FILE__);
    $row++;
}
