#! //bin/bash
# LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# UNCOMMENT NEXT FOR VERBOSE
set -x
##### HALT AND CATCH FIRE IF ANY COMMAND FAILS
set -e


######### UBER JOIN LIVE CHECK DETAIL WITH LIVE SQUASHED CARD ACTIVITY
# Delete Temp table if it exists
mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP TABLE IF EXISTS Master_test"
echo 'TEMP TABLE DROPPED, STARTING NEW TEMP TABLE CREATION'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_Dev -N -e "CREATE TABLE Master_test LIKE Master_test_structure"
echo 'MASTER TEST CREATED STARTING JOIN'



#### Double check UNION !!!!!!!!!!!!!!!!

mysql  --login-path=local -DSRG_Dev -N -e "INSERT INTO Master_test SELECT CD.*, CA.* FROM CheckDetail_Live AS CD 
						LEFT JOIN CardActivity_squashed_2 AS CA ON CD.POSkey = CA.POSkey 
						UNION SELECT CD.*, CA.* FROM .CheckDetail_Live as CD 
						RIGHT JOIN CardActivity_squashed_2 AS CA ON CD.POSkey = CA.POSkey"
# echo 'UBER JOIN COMPLETED, /outfiles/joined.cd.ca.csv CREATED'
echo 'Uber join data inserted into Master_test'

# Create enroll_date and Account_status fields
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE Master_test ADD enroll_date VARCHAR(11)"
# Create POSkey field
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE Master_test ADD Account_status VARCHAR(26)"
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE Master_test ADD INDEX(Account_status)"
echo 'Added enroll_date and account status'


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
			echo $TransactionDate updated FY= $FY YLuna = $YLuna
done
echo FY YLUNA CALCD POPULATED

######## UPDATE ACCOUNT STATUS FROM GUEST TABLE
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test JOIN Guests ON Master_test.CardNumber = Guests.CardNumber SET Master_test.enroll_date = Guests.EnrollDate, Master_test.Account_status = Guests.AccountStatus"
echo 'Account Status updated from Guests table'
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test JOIN Px_exchanges ON Master_test.CardNumber = Px_exchanges.CurrentCardNumber SET Master_test.Account_status = 'Exchange'"
echo 'EXCHANGED accounts account status updated from px_exchanges table'
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test JOIN Excludes ON Master_test.CardNumber = Excludes.CardNumber SET Master_test.Account_status = 'Exclude'"
echo 'EXCLUDED accounts account status updated from Excludes table'


######## UPDATE THE EMPTY CHECKDETAIL FIELDS WITH PX DATA

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET CheckNumber = CheckNo WHERE CheckNo IS NULL"
echo Empty CheckNumber-s populated from CheckNo

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET DOB = TransactionDate WHERE DOB IS NULL"
echo Empty DOB-s populated from TransactionDate
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET LocationID = LocationID_px WHERE LocationID IS NULL"
echo Empty LocationID-s populated form LocationID_px
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET POSkey = POSKey_px WHERE POSkey IS NULL"
echo Empty POSkey-s populated from POSkey_px
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET GrossSalesCoDefined = DollarsSpentAccrued WHERE GrossSalesCoDefined IS NULL"
echo 'Empty GrossSalesCoDefined-s Populated (PROMOS OR COMPS COULD NOT BE ADD, LOWBALL FIGURES)'








########### PREPEND HEADERS TO UBER JOIN
######## IF CAT FINISHES CORRECTLY DELETE THE FILE WO HEADERS
# cat /home/ubuntu/db_files/headers/uber.join.headers.csv /home/ubuntu/db_files/outfiles/joined.cd.ca.csv > /home/ubuntu/db_files/outfiles/uber.join.wheaders.csv && rm /home/ubuntu/db_files/outfiles/joined.cd.ca.csv
# echo 'HEADERS ADDED, /outfiles/uber.join.wheaders.csv CREATED, joined.cd.ca.csv DELETED'


#### REPLACE THE NEWLINE CHARS {\n} IN FILE 
# sed 's#\\N##g' /home/ubuntu/db_files/outfiles/uber.join.wheaders.csv > /home/ubuntu/db_files/outfiles/uber.join.clean.wheaders.csv && rm /home/ubuntu/db_files/outfiles/uber.join.wheaders.csv
# echo 'NEWLINE CHARACTERS STRIPPED, /outfiles/uber.join.clean.wheaders.csv CREATED, uber.join.wheaders DELETED'
# echo '/home/ubuntu/db_files/outfiles/uber.join.clean.wheaders.csv READY.'

