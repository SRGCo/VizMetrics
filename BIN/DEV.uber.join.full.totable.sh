#! //bin/bash
# LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# UNCOMMENT NEXT FOR VERBOSE
set -x
##### HALT AND CATCH FIRE IF ANY COMMAND FAILS
set -e


######### UBER JOIN LIVE CHECK DETAIL WITH LIVE SQUASHED CARD ACTIVITY

#### Double check UNION !!!!!!!!!!!!!!!!

mysql  --login-path=local -DSRG_Dev -N -e "INSERT INTO Master_test SELECT CD.*, CA.* FROM CheckDetail_Live AS CD LEFT JOIN CardActivity_squashed AS CA ON CD.POSkey = CA.POSkey UNION SELECT CD.*, CA.* FROM .CheckDetail_Live as CD RIGHT JOIN CardActivity_squashed AS CA ON CD.POSkey = CA.POSkey"
# echo 'UBER JOIN COMPLETED, /outfiles/joined.cd.ca.csv CREATED'
echo 'Uber join data inserted into Master_test'


##### CALC THE (non-dynamic) FREQUENCY FIELDS -FY Y-LUNA
##### FIRST 4 CHARS of TransactionDate BECOME FY
##################### ITERATE ON POSkey 
###### -N is the No Headers in Output option
###### -e is the 'read statement and quit'
mysql  --login-path=local -DSRG_Dev -N -e "SELECT TransactionDate FROM Master_test WHERE TransactionDate > '2013-09-01' GROUP BY TransactionDate ORDER BY TransactionDate ASC" | while read -r TransactionDate;
do
	######## GET FY FOR THIS TransactionDate (DOB)
	FY=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT FY from Lunas WHERE DOB = '$TransactionDate'")

	######## GET FY FOR THIS TransactionDate (DOB)
	YLuna=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT YLuna from Lunas WHERE DOB = '$TransactionDate'")


			##### UPDATE FISCAL YEAR FROM TRANSACTIONDATE
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET FY = '$FY',YLuna = '$YLuna' WHERE TransactionDate = '$TransactionDate'"
			echo $TransactionDate updated FY= $FY Luna = $Luna
done
echo FY YLUNA CALCD POPULATED
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET DOB = TransactionDate WHERE DOB IS NULL"
echo Empty DOBs populated from TransactionDate
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET LocationID = LocationID_px WHERE LocationID IS NULL"
echo Empty LocationIDs populated form LocationID_px
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET POSkey = POSKey_px WHERE POSkey IS NULL"
echo Empty POSkey populated from POSkey_px







########### PREPEND HEADERS TO UBER JOIN
######## IF CAT FINISHES CORRECTLY DELETE THE FILE WO HEADERS
# cat /home/ubuntu/db_files/headers/uber.join.headers.csv /home/ubuntu/db_files/outfiles/joined.cd.ca.csv > /home/ubuntu/db_files/outfiles/uber.join.wheaders.csv && rm /home/ubuntu/db_files/outfiles/joined.cd.ca.csv
# echo 'HEADERS ADDED, /outfiles/uber.join.wheaders.csv CREATED, joined.cd.ca.csv DELETED'


#### REPLACE THE NEWLINE CHARS {\n} IN FILE 
# sed 's#\\N##g' /home/ubuntu/db_files/outfiles/uber.join.wheaders.csv > /home/ubuntu/db_files/outfiles/uber.join.clean.wheaders.csv && rm /home/ubuntu/db_files/outfiles/uber.join.wheaders.csv
# echo 'NEWLINE CHARACTERS STRIPPED, /outfiles/uber.join.clean.wheaders.csv CREATED, uber.join.wheaders DELETED'
# echo '/home/ubuntu/db_files/outfiles/uber.join.clean.wheaders.csv READY.'

eof

