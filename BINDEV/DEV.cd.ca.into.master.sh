#! //bin/bash
# LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# UNCOMMENT NEXT FOR VERBOSE
#set -x
##### HALT AND CATCH FIRE IF ANY COMMAND FAILS
set -e

################# THIS INSERTS ALL DATA FROM TEMP TABLE, IT SHOULD JUST UPDATE.

######### UBER JOIN LIVE CHECK DETAIL WITH LIVE SQUASHED CARD ACTIVITY
# Delete Temp table if it exists
mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP TABLE IF EXISTS Master_temp"
echo 'TEMP TABLE DROPPED, STARTING NEW TEMP TABLE CREATION'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_Dev -N -e "CREATE TABLE Master_temp LIKE Master_structure"
echo 'MASTER TEMP CREATED STARTING JOIN'

#### Double check UNION !!!!!!!!!!!!!!!!
mysql  --login-path=local -DSRG_Dev -N -e "INSERT INTO Master_temp SELECT CD.*, CA.* FROM CheckDetail_Live AS CD 
						LEFT JOIN CardActivity_squashed_2 AS CA ON CD.POSkey = CA.POSkey 
						UNION SELECT CD.*, CA.* FROM .CheckDetail_Live as CD 
						RIGHT JOIN CardActivity_squashed_2 AS CA ON CD.POSkey = CA.POSkey"

# echo 'UBER JOIN COMPLETED'
echo 'UBER JOIN DATA INSERTED INTO Master_temp'

# Create enroll_date and Account_status fields
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE Master_temp ADD EnrollDate VARCHAR(11)"
# Create POSkey field
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE Master_temp ADD Account_status VARCHAR(26)"
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE Master_temp ADD INDEX(Account_status)"
echo 'ADDED ENROLLDATE AND Account_status TO Master_temp'


##### CALC THE (non-dynamic) FREQUENCY FIELDS -FY Y-LUNA
##### FIRST 4 CHARS of TransactionDate BECOME FY
##################### ITERATE ON POSkey 
###### -N is the No Headers in Output option
###### -e is the 'read statement and quit'
###################### This was going to only go 3 months back but we rebuild master every time so that is not possible in this build ###########

mysql  --login-path=local -DSRG_Dev -N -e "SELECT Master_temp.DOB FROM Master_temp WHERE Master_temp.DOB IS NOT NULL 
				GROUP BY Master_temp.DOB ORDER BY Master_temp.DOB DESC" | while read -r TransactionDate;
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
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp JOIN Guests_Master ON Master_temp.CardNumber = Guests_Master.CardNumber 
							SET Master_temp.EnrollDate = Guests_Master.EnrollDate, Master_temp.Account_status = Guests_Master.AccountStatus"
echo 'ACCOUNT STATUSES UPDATED FROM Guests_Master TABLE'

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp JOIN Px_exchanges ON Master_temp.CardNumber = Px_exchanges.CurrentCardNumber SET Master_temp.Account_status = 'Exchange'"
echo 'EXCHANGED ACCOUNTS STATUSES UPDATED FROM px_exchanges TABLE'

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp JOIN Excludes ON Master_temp.CardNumber = Excludes.CardNumber SET Master_temp.Account_status = 'Exclude'"
echo 'EXCLUDED ACCOUNTS STATUSES UPDATED USING Excludes TABLE'

######## UPDATE THE EMPTY CHECKDETAIL FIELDS WITH PX DATA
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp SET CheckNumber = CheckNo_px WHERE CheckNumber IS NULL"
echo EMPTY CHECKNO POPULATED FROM PX DATA

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp SET DOB = TransactionDate WHERE DOB IS NULL"
echo Empty DOB-s POPULATED FROM PX DATA

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp SET LocationID = LocationID_px WHERE LocationID IS NULL"
echo Empty LocationID-s POPULATED FROM PX DATA

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp SET POSkey = POSKey_px WHERE POSkey IS NULL"
echo Empty POSkey-s POPULATED FROM PX DATA

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp SET GrossSalesCoDefined = DollarsSpentAccrued WHERE GrossSalesCoDefined IS NULL 
						AND Master_temp.Account_status <> 'TERMIN' AND Master_temp.Account_status <> 'SUSPEN' 
						AND Master_temp.Account_status <> 'Exchanged' AND Master_temp.Account_status <> 'Exchange' 
						AND Master_temp.Account_status <> 'Exclude'"
echo 'EMPTY GrossSalesCoDefined-s POPULATED (PROMOS OR COMPS COULD NOT BE ADD, LOWBALL FIGURES)'

## TRUNCATE Master TABLE BEFORE LOADING W NEW
# Delete Temp table if it exists

mysql  --login-path=local --silent -DSRG_Dev -N -e "TRUNCATE TABLE Master"
echo 'TABLE Master TRUNCATED'


####### COPY TEMP DATA INTO MASTER
mysql  --login-path=local --silent -DSRG_Dev -N -e "INSERT INTO Master SELECT * FROM Master_temp"
echo 'DATA INSERTED INTO Master TABLE'

