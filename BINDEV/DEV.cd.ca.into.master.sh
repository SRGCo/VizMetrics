#! //bin/bash
# LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# UNCOMMENT NEXT FOR VERBOSE
set -x
##### HALT AND CATCH FIRE IF ANY COMMAND FAILS
set -e

################# THIS INSERTS ALL DATA FROM TEMP TABLE, IT SHOULD JUST UPDATE.

######### UBER JOIN LIVE CHECK DETAIL WITH LIVE SQUASHED CARD ACTIVITY
# Delete Temp table if it exists
mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP TABLE IF EXISTS Master_temp"
echo 'TEMP TABLE DROPPED, STARTING NEW TEMP TABLE CREATION'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_Dev -N -e "CREATE TABLE Master_temp LIKE Master_structure"
echo 'MASTER TEST CREATED STARTING JOIN'

#### Double check UNION !!!!!!!!!!!!!!!!
mysql  --login-path=local -DSRG_Dev -N -e "INSERT INTO Master_temp SELECT CD.*, CA.* FROM CheckDetail_Live AS CD 
						LEFT JOIN CardActivity_squashed_2 AS CA ON CD.POSkey = CA.POSkey WHERE CA.TransactionDate <= '2018-05-19' 
						UNION SELECT CD.*, CA.* FROM .CheckDetail_Live as CD 
						RIGHT JOIN CardActivity_squashed_2 AS CA ON CD.POSkey = CA.POSkey WHERE CA.TransactionDate <= '2018-05-19' "
# echo 'UBER JOIN COMPLETED, /outfiles/joined.cd.ca.csv CREATED'
echo 'Uber join data inserted into Master_temp'

# Create enroll_date and Account_status fields
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE Master_temp ADD EnrollDate VARCHAR(11)"
# Create POSkey field
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE Master_temp ADD Account_status VARCHAR(26)"
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE Master_temp ADD INDEX(Account_status)"
echo 'Added enroll_date and account status to Master_temp'


##### CALC THE (non-dynamic) FREQUENCY FIELDS -FY Y-LUNA
##### FIRST 4 CHARS of TransactionDate BECOME FY
##################### ITERATE ON POSkey 
###### -N is the No Headers in Output option
###### -e is the 'read statement and quit'
mysql  --login-path=local -DSRG_Dev -N -e "SELECT Master_temp.DOB FROM Master_temp WHERE Master_temp.DOB > DATE_SUB(CURDATE(), INTERVAL 3 MONTH) GROUP BY Master_temp.DOB ORDER BY Master_temp.DOB DESC" | while read -r TransactionDate;
do
	######## GET FY FOR THIS TransactionDate (DOB)
	FY=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT FY from Lunas WHERE DOB = '$TransactionDate'")

	######## GET FY FOR THIS TransactionDate (DOB)
	YLuna=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT YLuna from Lunas WHERE DOB = '$TransactionDate'")

	######## GET FY FOR THIS TransactionDate (DOB)
	Luna=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT Luna from Lunas WHERE DOB = '$TransactionDate'")


			##### UPDATE FISCAL YEAR FROM TRANSACTIONDATE
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp SET FY = '$FY',YLuna = '$YLuna', Luna='$Luna' WHERE Master_temp.DOB = '$TransactionDate'"
			echo $TransactionDate updated FY= $FY YLuna = $YLuna  Luna = $Luna
done
echo FY YLUNA CALCD POPULATED

######## UPDATE ACCOUNT STATUS FROM GUEST TABLE
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp JOIN Guests ON Master_temp.CardNumber = Guests.CardNumber SET Master_temp.EnrollDate = Guests.EnrollDate, Master_temp.Account_status = Guests.AccountStatus"
echo 'Account Status updated from Guests table'
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp JOIN Px_exchanges ON Master_temp.CardNumber = Px_exchanges.CurrentCardNumber SET Master_temp.Account_status = 'Exchange'"
echo 'EXCHANGED accounts account status updated from px_exchanges table'
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp JOIN Excludes ON Master_temp.CardNumber = Excludes.CardNumber SET Master_temp.Account_status = 'Exclude'"
echo 'EXCLUDED accounts account status updated from Excludes table'


######## UPDATE THE EMPTY CHECKDETAIL FIELDS WITH PX DATA

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp SET CheckNumber = CheckNo WHERE CheckNumber IS NULL"
echo Empty CheckNumber-s populated from CheckNo

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp SET DOB = TransactionDate WHERE DOB IS NULL"
echo Empty DOB-s populated from TransactionDate
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp SET LocationID = LocationID_px WHERE LocationID IS NULL"
echo Empty LocationID-s populated form LocationID_px
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp SET POSkey = POSKey_px WHERE POSkey IS NULL"
echo Empty POSkey-s populated from POSkey_px
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp SET GrossSalesCoDefined = DollarsSpentAccrued WHERE GrossSalesCoDefined IS NULL 
						AND Master_temp.Account_status <> 'TERMIN' AND Master_temp.Account_status <> 'SUSPEN' 
						AND Master_temp.Account_status <> 'Exchanged' AND Master_temp.Account_status <> 'Exchange' 
						AND Master_temp.Account_status <> 'Exclude'"
echo 'Empty GrossSalesCoDefined-s Populated (PROMOS OR COMPS COULD NOT BE ADD, LOWBALL FIGURES)'

## TRUNCATE GUESTS TABLE BEFORE LOADING W NEW
# Delete Temp table if it exists

mysql  --login-path=local --silent -DSRG_Dev -N -e "TRUNCATE TABLE Master"
echo 'Guests_Master Emptied'


####### COPY TEMP DATA INTO MASTER
mysql  --login-path=local --silent -DSRG_Dev -N -e "INSERT INTO Master SELECT * FROM Master_temp"
echo 'Data inserted into Master table'

