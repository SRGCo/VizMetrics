SELECT CD.*, CA.* INTO OUTFILE '/home/srg/db_files/joined.cd.ca.csv' FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' FROM SRG_checks.CheckDetail_Live AS CD JOIN SRG_px.CardActivity_squashed AS CA ON CD.POSkey = CA.POSkey;






	UPDATE CheckDetail_Live CDL 
	INNER JOIN Employees_Live EL ON (CDL.LocationID = EL.LocationID AND CDL.Base_EmployeeID = EL.EmployeeID) 
	SET CDL.PayrollID = EL.PayrollID ;


SELECT checknumber(first 3 stripped, 'A' prepended) AS new_checknumber FROM CardActivity_Live 
WHERE ((checknumber longer than 6 chars) & (checknumber is not '9999999')) 


SELECT * FROM `CheckDetail_Live` where CheckNumber like '100%' and char_length(CheckNumber) > '6' 
and DOB > '2017-08-07' ORDER BY `CheckDetail_Live`.`CheckNumber` DESC

#### silent, no columns, exit
$Checkno = 'mysql -uroot -ps3r3n1t33 -s -N -e "SELECT CheckNumber FROM CheckDetail_Live WHERE CheckNumber like '100%' and char_length(checkNumber) > '6'"`
ECHO $Checkno



mysql -uroot -ps3r3n1t33 -DSRG_px -N -e "UPDATE CardActivity_Live SET CheckNo=CONCAT('100',CheckNo) WHERE CheckNo = $CheckNumber AND TransactionDate = $DOB AND LocationID = $LocationID"





#################################### USING BELOW ITEMS AS OF 12-20-17 ############################
######### UBER JOIN LIVE CHECK DETAIL WITH LIVE SQUASHED CARD ACTIVITY
SELECT CD.*, CA.* INTO OUTFILE '/home/srg/db_files/joined.cd.ca.csv' FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' FROM SRG_checks.CheckDetail_Live AS CD LEFT JOIN SRG_px.CardActivity_squashed AS CA ON CD.POSkey = CA.POSkey;

########### PREPEND HEADERS TO UBER JOIN
cat /home/srg/db_files/headers/cd.ca.joined.headers.csv /home/srg/db_files/joined.cd.ca.csv > /home/srg/db_files/uber.join.wheaders.csv


#### REPLACE THE NEWLINE CHARS {\n} IN FILE 
sed 's#\\N##g' FILE_IN > FILE_OUT

