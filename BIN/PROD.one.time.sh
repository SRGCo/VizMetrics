#! //bin/bash
# LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# UNCOMMENT NEXT FOR VERBOSE
# set -x
##### HALT AND CATCH FIRE IF ANY COMMAND FAILS
# set -e

##### USE time command to calc runtime "time DEV.cd.ca.into.master.sh"


############# THIS SCRIPT USES THE FOLLOWING
# PROD.wrong.enroll.fix.php
# PROD.VM_visits.master.process.sh
############# above uses: PROD.visitbalance.fix.php




################# ERROR CATCHING ##########################
failfunction()
{
	local scriptname=$(basename -- "$0") 
	local returned_value=$1
	local lineno=$2
	local bash_error=$3

	if [ "$returned_value" != 0 ]
	then 
 		echo "$scriptname failed on $bash_error at line: $lineno"
        	mail -s "VizMetrics Server Alert"  it@serenitee.com <<< 'Script '"$scriptname"' failed on '"$bash_error"' at Line: '"$lineno"
        	exit
	fi
}



######### UBER JOIN LIVE CHECK DETAIL WITH LIVE SQUASHED CARD ACTIVITY
# Delete Temp table if it exists
mysql  --login-path=local --silent -DSRG_Prod -N -e "DROP TABLE IF EXISTS Master_temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER TEMP TABLE DROPPED'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_Prod -N -e "CREATE TABLE Master_temp LIKE Master_structure"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER TEMP CREATED'

###### WE ONLY GET THE LAST WEEKS WORTH OF DATA
mysql  --login-path=local -DSRG_Prod -N -e "INSERT INTO Master_temp SELECT CD.*, CA.* FROM CheckDetail_Live AS CD 
						LEFT JOIN CardActivity_squashed_2 AS CA ON CD.POSkey = CA.POSkey 
						WHERE CD.DOB >= DATE_SUB(CURDATE(), INTERVAL 90 DAY) 
						UNION SELECT CD.*, CA.* FROM .CheckDetail_Live as CD 
						RIGHT JOIN CardActivity_squashed_2 AS CA ON CD.POSkey = CA.POSkey 
						WHERE CA.TransactionDate >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
# echo 'UBER JOIN COMPLETED'
echo 'MASTER TEMP UPDATED WITH UBER CARD ACTIVITY AND CHECK DETAIL FROM PAST 90days'

# Create enroll_date and Account_status fields
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE Master_temp ADD EnrollDate VARCHAR(11)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

# Create ACCOUNT STATUS
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE Master_temp ADD Account_status VARCHAR(15)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

# Create ACCOUNT STATUS INDEX
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE Master_temp ADD INDEX(Account_status)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER TEMP ENROLLDATE AND ACCOUNT STATUS FIELDS CREATED'

# Create ACCOUNT STATUS
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE Master_temp ADD Card_status VARCHAR(15)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


# AVOID DUPES DELETE SAME INTERVAL BACK
mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE FROM Master WHERE DOB >= DATE_SUB(CURDATE(), INTERVAL 90 DAY) "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER TRUNCATED - USING DOB'

# AVOID DUPES DELETE SAME INTERVAL BACK
mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE FROM Master WHERE TransactionDate >= DATE_SUB(CURDATE(), INTERVAL 90 DAY) "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER TRUNCATED - USING TRANSACTIONDATE'



# COPY THE NEW TRANSACTIONS INTO MASTER
### WE COULD HAVE THIS TO MAKE SURE THERE ARE RECORDS IN THE TEMP TABLE(?)
mysql  --login-path=local --silent -DSRG_Prod -N -e "INSERT INTO Master SELECT * FROM Master_temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER POPULATED FROM MASTER TEMP'



############## THE NEXT SECTIONS WILL GET MOVED AROUND IF WE ADD CARD STATUS FIELDS
####### MASTER TABLE GUEST INFO UPDATE
mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master JOIN Guests_Master ON Master.CardNumber = Guests_Master.CardNumber 
							SET Master.EnrollDate = Guests_Master.EnrollDate, Master.Account_status = Guests_Master.AccountStatus"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER ACCOUNT STATUSES UPDATED FROM GUESTS MASTER TABLE '










######## UPDATE THE EMPTY CHECKDETAIL FIELDS WITH PX DATA
mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET CheckNumber = CheckNo_px WHERE CheckNumber IS NULL "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER EMPTY CHECKNO POPULATED FROM PX DATA'


mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET LocationID = LocationID_px WHERE LocationID IS NULL "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER EMPTY LOCATION ID POPULATED FROM PX DATA'

mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET POSkey = POSKey_px WHERE POSkey IS NULL "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER EMPTY POS KEYS POPULATED FROM PX DATA'

mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET DOB = TransactionDate WHERE DOB IS NULL "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER EMPTY DOB POPULATED FROM PX DATA'



mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET GrossSalesCoDefined = DollarsSpentAccrued WHERE GrossSalesCoDefined IS NULL 
						AND Master.Account_status <> 'TERMIN' AND Master.Account_status <> 'SUSPEN' 
						AND Master.Account_status <> 'Exchanged' AND Master.Account_status <> 'Exchange' 
						AND Master.Account_status <> 'Exclude' AND DollarsSpentAccrued IS NOT NULL"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER GROSSSALESCODEFINED FIELD POPULATED'
echo '(PROMOS OR COMPS COULD NOT BE ADDED, LOWBALL FIGURES)'


###### -N is the No Headers in Output option
###### -e is the 'read statement and quit'
######## WE ARE ###

mysql  --login-path=local -DSRG_Prod -N -e "SELECT Master.DOB FROM Master WHERE Master.DOB IS NOT NULL AND DOB >= DATE_SUB(NOW(),INTERVAL 45 DAY) 
				GROUP BY Master.DOB ORDER BY Master.DOB DESC" | while read -r DOB;
do

		######## GET FY FOR THIS DOB (DOB)
		FY=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT FY from Lunas WHERE DOB = '$DOB'")

		######## GET FY FOR THIS DOB (DOB)
		YLuna=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT YLuna from Lunas WHERE DOB = '$DOB'")

		######## GET FY FOR THIS DOB (DOB)
		Luna=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT Luna from Lunas WHERE DOB = '$DOB'")

		######## IF VARIABLE HAS NO VALUE SET TO NULL
		if [ -z $Luna ] 
		then 
		Luna='0'
		fi

		##### UPDATE FISCAL YEAR FROM DOB
		mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET FY = '$FY',YLuna = '$YLuna', Luna='$Luna' WHERE Master.DOB = '$DOB'"
		#echo $DOB updated FY= $FY YLuna = $YLuna  Luna = $Luna

done
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER FY YLUNA FIELDS UPATED WITH DATA FROM LUNA TABLE'

################# PROCESS visits to VM_visits
( "/home/ubuntu/bin/PROD.VM_visits.master.process.sh" )
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER- VM visists processed-'

################# Fix visitbalances in Master
( "/home/ubuntu/bin/PROD.visitbalance.fix.php" )
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER- VM visitbalances fixed-'




