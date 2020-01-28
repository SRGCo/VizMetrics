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


##### UPDATE FISCAL YEAR FROM DOB
	mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "DELETE FROM CardActivity_squashed_2 WHERE LocationID = '0'"
	echo 'LOCATION 0 TRANSACTIONS DUMPED FROM CA_S_2'




######### UBER JOIN LIVE CHECK DETAIL WITH LIVE SQUASHED CARD ACTIVITY
# Delete Temp table if it exists
mysql  --login-path=local --silent -DSRG_Prod-1-27-20 -N -e "DROP TABLE IF EXISTS Master_temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER TEMP TABLE DROPPED'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_Prod-1-27-20 -N -e "CREATE TABLE Master_temp LIKE Master_structure"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER TEMP CREATED'

###### WE ONLY GET THE LAST WEEKS WORTH OF DATA
mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "INSERT INTO Master_temp SELECT CD.*, CA.* FROM CheckDetail_Live AS CD 
						LEFT JOIN CardActivity_squashed_2 AS CA ON CD.POSkey = CA.POSkey  
						UNION SELECT CD.*, CA.* FROM .CheckDetail_Live as CD 
						RIGHT JOIN CardActivity_squashed_2 AS CA ON CD.POSkey = CA.POSkey "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
# echo 'UBER JOIN COMPLETED'
echo 'MASTER TEMP POPULATED WITH UBER CARD ACTIVITY AND CHECK DETAIL'

# Create enroll_date and Account_status fields
mysql  --login-path=local --silent -DSRG_Prod-1-27-20 -N -e "ALTER TABLE Master_temp ADD EnrollDate VARCHAR(11)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

# Create ACCOUNT STATUS
mysql  --login-path=local --silent -DSRG_Prod-1-27-20 -N -e "ALTER TABLE Master_temp ADD Account_status VARCHAR(15)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

# Create ACCOUNT STATUS INDEX
mysql  --login-path=local --silent -DSRG_Prod-1-27-20 -N -e "ALTER TABLE Master_temp ADD INDEX(Account_status)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER TEMP ENROLLDATE AND ACCOUNT STATUS FIELDS CREATED'

# Create ACCOUNT STATUS
mysql  --login-path=local --silent -DSRG_Prod-1-27-20 -N -e "ALTER TABLE Master_temp ADD Card_status VARCHAR(15)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


# COPY THE NEW TRANSACTIONS INTO MASTER
### WE COULD HAVE THIS TO MAKE SURE THERE ARE RECORDS IN THE TEMP TABLE(?)
mysql  --login-path=local --silent -DSRG_Prod-1-27-20 -N -e "INSERT INTO Master SELECT * FROM Master_temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER POPULATED FROM MASTER TEMP'



############## THE NEXT SECTIONS WILL GET MOVED AROUND IF WE ADD CARD STATUS FIELDS
####### MASTER TABLE GUEST INFO UPDATE
mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "UPDATE Master JOIN Guests_Master ON Master.CardNumber = Guests_Master.CardNumber 
							SET Master.EnrollDate = Guests_Master.EnrollDate, Master.Account_status = Guests_Master.AccountStatus"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER ACCOUNT STATUSES UPDATED FROM GUESTS MASTER TABLE '



################# PROCESS EXCHANGES WITH PHP SUBROUTINE
( "/home/ubuntu/bin/FIX.px.exchanges.process.php" )
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER- EXCHANGED CARDS PROCESS/FIXED, ACCOUNT STATUS UPDATED TO -Exchange-'


######### EXCLUDES SECTION USE OR NOT ? ? ?
mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "UPDATE Master JOIN Excludes ON Master.CardNumber = Excludes.CardNumber SET Master.Account_status = 'Exclude' "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER - Only SRG Office + Zorba Marked Exclude (using Excludes table), other employees etc STILL BEING PROCESSED'








######## UPDATE THE EMPTY CHECKDETAIL FIELDS WITH PX DATA
mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "UPDATE Master SET CheckNumber = CheckNo_px WHERE CheckNumber IS NULL "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER EMPTY CHECKNO POPULATED FROM PX DATA'


mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "UPDATE Master SET LocationID = LocationID_px WHERE LocationID IS NULL "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER EMPTY LOCATION ID POPULATED FROM PX DATA'

mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "UPDATE Master SET POSkey = POSKey_px WHERE POSkey IS NULL "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER EMPTY POS KEYS POPULATED FROM PX DATA'

mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "UPDATE Master SET DOB = TransactionDate WHERE DOB IS NULL "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER EMPTY DOB POPULATED FROM PX DATA'



mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "UPDATE Master SET GrossSalesCoDefined = DollarsSpentAccrued WHERE GrossSalesCoDefined IS NULL 
						AND Master.Account_status <> 'TERMIN' AND Master.Account_status <> 'SUSPEN' 
						AND Master.Account_status <> 'Exchanged' AND Master.Account_status <> 'Exchange' 
						AND Master.Account_status <> 'Exclude' AND DollarsSpentAccrued IS NOT NULL"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER GROSSSALESCODEFINED FIELD POPULATED'
echo '(PROMOS OR COMPS COULD NOT BE ADDED, LOWBALL FIGURES)'


###### -N is the No Headers in Output option
###### -e is the 'read statement and quit'
######## WE ARE ###

mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "SELECT Master.DOB FROM Master WHERE Master.DOB IS NOT NULL
				GROUP BY Master.DOB ORDER BY Master.DOB DESC" | while read -r DOB;
do

		######## GET FY FOR THIS DOB (DOB)
		FY=$(mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "SELECT FY from Lunas WHERE DOB = '$DOB'")

		######## GET FY FOR THIS DOB (DOB)
		YLuna=$(mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "SELECT YLuna from Lunas WHERE DOB = '$DOB'")

		######## GET FY FOR THIS DOB (DOB)
		Luna=$(mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "SELECT Luna from Lunas WHERE DOB = '$DOB'")

		######## IF VARIABLE HAS NO VALUE SET TO NULL
		if [ -z $Luna ] 
		then 
		Luna='0'
		fi

		##### UPDATE FISCAL YEAR FROM DOB
		mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "UPDATE Master SET FY = '$FY',YLuna = '$YLuna', Luna='$Luna' WHERE Master.DOB = '$DOB'"
		#echo $DOB updated FY= $FY YLuna = $YLuna  Luna = $Luna

done
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER FY YLUNA FIELDS UPATED WITH DATA FROM LUNA TABLE'


mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "SELECT DISTINCT(CardNumber) FROM Master WHERE CardNumber IS NOT NULL ORDER BY CardNumber ASC" | while read -r CardNumber;
do

	######## COUNT VISITS OVER PREVIOUS 12 MONTHS AND LIFETIME
	PrevYear=$(mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "SELECT COUNT(*) from Master WHERE CardNumber = '$CardNumber' AND TransactionDate <> EnrollDate 
								AND Vm_VisitsAccrued = '1' AND TransactionDate >= DATE_SUB(NOW(),INTERVAL 365 DAY)")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	######## MINIMUM VISITBALNCE
	MinBal=$(mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "SELECT MIN(Vm_Visitsbalance) from Master WHERE CardNumber = '$CardNumber'")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

	######## COUNT VISITS OVER LIFETIME
	Lifetime=$(mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "SELECT COUNT(*) from Master WHERE CardNumber = '$CardNumber' 
								AND Vm_VisitsAccrued = '1'")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	######## 
	Lifetimereal="$(($MinBal+$Lifetime))"
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	######## MINIMUM VISITBALNCE
	VmVB=$(mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "SELECT MAX(Vm_Visitsbalance) from Master WHERE CardNumber = '$CardNumber'")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

	##### GET MAX  TRANSACTIONDATE
	MaxDate=$(mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "SELECT MAX(TransactionDate) from Master WHERE CardNumber = '$CardNumber'")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR	

	##### GET 2ND TO MAX TRANSACTIONDATE
	SecondMax=$(mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "SELECT TransactionDate from Master WHERE CardNumber = '$CardNumber' 
										AND Vm_VisitsAccrued = '1' ORDER BY TransactionDate DESC limit 1,1") 
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	##### IF SECONDMAX IS NULL / EMPTY
	if [ -z $SecondMax ]
	then

		##### UPDATE ONLY FIRST FREQUENCIES
		mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "UPDATE Master SET FreqCurrent = DATEDIFF(NOW(), '$MaxDate'), Freq12mos = '$PrevYear', 
									FreqLifetime = '$Lifetimereal'  WHERE CardNumber = '$CardNumber'"
		trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR	
		#echo $CardNumber" first only MAX "$MaxDate" 2ND "$SecondMax"  Prevyr "$PrevYear" VmVB "$VmVB 
		#echo "PrevLifereal "$Lifetimereal" prevlifenotreal"$Lifetime" MinBal "$MinBal

		##### IF SECONDMAX HAS A VALUE
		else
			##### GET 3RD TO MAX TRANSACTIONDATE
			ThirdMax=$(mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "SELECT transactiondate from Master WHERE CardNumber = '$CardNumber' 
										AND Vm_VisitsAccrued = '1' ORDER BY TransactionDate DESC limit 2,1") 
			trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
			##### IF THIRDMAX IS NULL / EMPTY
			if [ -z $ThirdMax ]
			then
				##### UPDATE ONLY FIRST AND SECOND FREQUENCIES
				mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "UPDATE Master SET FreqCurrent = DATEDIFF(NOW(), '$MaxDate'), 
										FreqRecent = DATEDIFF('$MaxDate', '$SecondMax'), Freq12mos = '$PrevYear', 
										FreqLifetime = '$Lifetimereal'  WHERE CardNumber = '$CardNumber'"
				trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR			   
				#echo $CardNumber" first and second MAX "$MaxDate" 2ND "$SecondMax" Prevyr "$PrevYear" VmVB "$VmVB
				#echo " PrevLifereal "$Lifetimereal" prevlifenotreal "$Lifetime" MinBal "$MinBal
				
			##### IF THIRDMAX HAS A VALUE
			else
				##### UPDATE ALL FREQUENCIES
				mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "UPDATE Master SET FreqCurrent = DATEDIFF(NOW(), '$MaxDate'), 
										FreqRecent = DATEDIFF('$MaxDate', '$SecondMax'), 
										FreqPrevious = DATEDIFF('$SecondMax', '$ThirdMax'), Freq12mos = '$PrevYear', 
										FreqLifetime = '$Lifetimereal'   WHERE CardNumber = '$CardNumber'"
			trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
			#echo $CardNumber" first second third MAX "$MaxDate" 2ND "$SecondMax" 3RD "$ThirdMax" Prevyr "$PrevYear" VmVB "$VmVB
			#echo " PrevLifereal "$Lifetimereal" prevlifenotreal "$Lifetime" MinBal "$MinBal

				
			fi

		fi
done || trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER TABLE FREQUENCY FIELDS UPDATED ****NO**** VM Visit fix applied'




