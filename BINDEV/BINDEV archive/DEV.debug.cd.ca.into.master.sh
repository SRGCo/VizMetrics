#! //bin/bash
# LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# UNCOMMENT NEXT FOR VERBOSE
set -x
##### HALT AND CATCH FIRE IF ANY COMMAND FAILS
set -e

################# THIS INSERTS ALL DATA FROM TEMP TABLE, IT SHOULD JUST UPDATE.


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

