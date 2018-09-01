#! //bin/bash
# LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# UNCOMMENT NEXT FOR VERBOSE
#set -x
##### HALT AND CATCH FIRE IF ANY COMMAND FAILS
set -e

##### USE time command to calc runtime "time DEV.cd.ca.into.master.sh"

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




################# THIS INSERTS ALL DATA FROM TEMP TABLE, IT SHOULD JUST UPDATE.

######### UBER JOIN LIVE CHECK DETAIL WITH LIVE SQUASHED CARD ACTIVITY
# Delete Temp table if it exists
mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP TABLE IF EXISTS Master_temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'TEMP TABLE DROPPED, STARTING NEW TEMP TABLE CREATION'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_Dev -N -e "CREATE TABLE Master_temp LIKE Master_structure"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER TEMP CREATED STARTING JOIN'

#### Double check UNION !!!!!!!!!!!!!!!!
mysql  --login-path=local -DSRG_Dev -N -e "INSERT INTO Master_temp SELECT CD.*, CA.* FROM CheckDetail_Live AS CD 
						LEFT JOIN CardActivity_squashed_2 AS CA ON CD.POSkey = CA.POSkey 
						UNION SELECT CD.*, CA.* FROM .CheckDetail_Live as CD 
						RIGHT JOIN CardActivity_squashed_2 AS CA ON CD.POSkey = CA.POSkey"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
# echo 'UBER JOIN COMPLETED'
echo 'UBER JOIN DATA INSERTED INTO Master_temp'

# Create enroll_date and Account_status fields
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE Master_temp ADD EnrollDate VARCHAR(11)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
# Create POSkey field
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE Master_temp ADD Account_status VARCHAR(26)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE Master_temp ADD INDEX(Account_status)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'ADDED ENROLLDATE AND Account_status TO Master_temp'

######## UPDATE ACCOUNT STATUS FROM GUEST TABLE
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp JOIN Guests_Master ON Master_temp.CardNumber = Guests_Master.CardNumber 
							SET Master_temp.EnrollDate = Guests_Master.EnrollDate, Master_temp.Account_status = Guests_Master.AccountStatus"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'ACCOUNT STATUSES UPDATED FROM Guests_Master TABLE'

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp JOIN Px_exchanges ON Master_temp.CardNumber = Px_exchanges.CurrentCardNumber SET Master_temp.Account_status = 'Exchange'"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'EXCHANGED ACCOUNTS STATUSES UPDATED FROM px_exchanges TABLE'

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp JOIN Excludes ON Master_temp.CardNumber = Excludes.CardNumber SET Master_temp.Account_status = 'Exclude'"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'EXCLUDED ACCOUNTS STATUSES UPDATED USING Excludes TABLE'

######## UPDATE THE EMPTY CHECKDETAIL FIELDS WITH PX DATA
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp SET CheckNumber = CheckNo_px WHERE CheckNumber IS NULL"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo EMPTY CHECKNO POPULATED FROM PX DATA

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp SET DOB = TransactionDate WHERE DOB IS NULL"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo Empty DOB-s POPULATED FROM PX DATA

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp SET LocationID = LocationID_px WHERE LocationID IS NULL"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo Empty LocationID-s POPULATED FROM PX DATA

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp SET POSkey = POSKey_px WHERE POSkey IS NULL"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo Empty POSkey-s POPULATED FROM PX DATA

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_temp SET GrossSalesCoDefined = DollarsSpentAccrued WHERE GrossSalesCoDefined IS NULL 
						AND Master_temp.Account_status <> 'TERMIN' AND Master_temp.Account_status <> 'SUSPEN' 
						AND Master_temp.Account_status <> 'Exchanged' AND Master_temp.Account_status <> 'Exchange' 
						AND Master_temp.Account_status <> 'Exclude'"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'EMPTY GrossSalesCoDefined-s POPULATED (PROMOS OR COMPS COULD NOT BE ADD, LOWBALL FIGURES)'


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
		#echo $TransactionDate updated FY= $FY YLuna = $YLuna  Luna = $Luna

done || trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo FY YLUNA CALCD POPULATED



## TRUNCATE Master TABLE BEFORE LOADING W NEW
# Delete Temp table if it exists

mysql  --login-path=local --silent -DSRG_Dev -N -e "TRUNCATE TABLE Master"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'TABLE Master TRUNCATED'


####### COPY TEMP DATA INTO MASTER
mysql  --login-path=local --silent -DSRG_Dev -N -e "INSERT INTO Master SELECT * FROM Master_temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'DATA INSERTED INTO Master TABLE'


################################ VISIT BALANCE FIX SECTION ########################################

### what if more than one transaction per day

mysql  --login-path=local -DSRG_Dev -N -e "SELECT DISTINCT(CardNumber) FROM Master ORDER BY CardNumber ASC" | while read -r CardNumber;
do
	
	######## GET FIRST TRANSACTION
	Min_dob=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MIN(TransactionDate) from Master WHERE CardNumber = '$CardNumber'")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

	######## GET visitsaccrued FOR THIS TransactionDate (DOB)
	VisitsAccrued=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(VisitsAccrued) from Master WHERE TransactionDate = '$Min_dob' and CardNumber = '$CardNumber'")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	##### CAN NOT BE NULL
	if [ -z "$VisitsAccrued" ] 
	then 
		$VisitsAccrued='0'
	fi

	CarriedBal=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(VisitsBalance) from Master WHERE TransactionDate = '$Min_dob' AND CardNumber = '$CardNumber'")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
		##### CAN NOT BE NULL
	if [ -z "$CarriedBal" ] 
	then 
		$CarriedBal='0'
	fi

	
	#### NOT AN EXCHANGE
	######## VISIT ACCRUED ON FIRST TRANSACTIONDATE
	if [[ "$CarriedBal" = "1" && "$VisitsAccrued" = "1" ]]
	then
		# echo $CardNumber"          Accrued on First Day!!!!       "$Min_dob"       no exchange       "$CarriedBal
		##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsBalance = VisitsBalance -1 WHERE CardNumber = '$CardNumber' AND VisitsBalance IS NOT NULL AND VisitsBalance != '0'"
		trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

		##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsAccrued = '' WHERE CardNumber = '$CardNumber' and TransactionDate > '$Min_dob'"
		trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

		##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsAccrued = VisitsAccrued WHERE CardNumber = '$CardNumber' and TransactionDate > '$Min_dob'"
		trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

	fi



	#### NOT AN EXCHANGE
	if [ "$CarriedBal" = "0" ]
	then
		
		########### VISIT ACCRUED NULL
		if  [ "$VisitsAccrued" = "0" ] ||  [ -z "$VisitsAccrued"  ] 
		then
		# echo $CardNumber" DID NOT Accrue First Day "$Min_dob" no exchange "$CarriedBal
			##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsBalance = VisitsBalance, Vm_VisitsAccrued = VisitsAccrued WHERE CardNumber = '$CardNumber' "
			trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
		else
			##### ODD CASES - NO BALANCE BUT 1 VISIT ACCRUED
		# echo $CardNumber" Odd Case Min_dob:"$Min_dob" Visits Accrued:"$VisitsAccrued" Carried Balance"$CarriedBal
			##### SET FIRST DATES visitsaccrued to 0 (to account for visit counted on enrollment day), vm_visitsbalance = visitsbalance
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsAccrued = '' WHERE CardNumber = '$CardNumber' and TransactionDate = '$Min_dob'"
			trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

			##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsAccrued = VisitsAccrued, Vm_VisitsBalance = VisitsBalance WHERE CardNumber = '$CardNumber' and TransactionDate > '$Min_dob'"
			trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

		fi
	fi


	####  AN EXCHANGE
	if [ "$CarriedBal"  -gt "1" ]
	then
		# echo $CardNumber"        First Day         "$Min_dob"       EXCHANGED!!! "$CarriedBal
		##### PX counts are correct
		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsBalance = VisitsBalance, Vm_VisitsAccrued = VisitsAccrued WHERE CardNumber = '$CardNumber' "
		trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

	fi

	##### FIX THE MULTI TRANS ON DAY 1
	############## AFTER WE FIGURE OUT WHY IT HAPPENS
	mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsBalance = '0' WHERE Vm_VisitsBalance ='-1'"
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


done || trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'VisitBalance Fix subroutine completed'



######### THESE ARE THE FIELDS WE WILL CALCULATE EVERY DAY #################################
#1.	 Historical Current Frequency (Hist_current_freq): Transaction Date (DOB) - Last visit date
#2.      Current Frequency (Current_freq): Today-Last visit date
#3.      Recent Frequency (Recent_freq): Last Visit Date-Previous visit date (2 visits back)
#4.      Previous Frequency: Previous visit date (2 visits back)- 3 visits back
#5.      12 Month Frequency (Year_freq): Count Visits over the previous 12 months
#6.      Lifetime Frequency (Life_freq): Count Visits since Enrollment date

####### CALC-ing OFF Vm_VisitsAccrued


mysql  --login-path=local -DSRG_Prod -N -e "SELECT CardNumber FROM Master WHERE CardNumber IS NOT NULL 
						GROUP BY CardNumber ORDER BY CardNumber ASC" | while read -r CardNumber;
do

	######## COUNT VISITS OVER PREVIOUS 12 MONTHS AND LIFETIME
	PrevYear=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT COUNT(*) from Master WHERE CardNumber = '$CardNumber' AND TransactionDate <> EnrollDate 
								AND Vm_VisitsAccrued = '1' AND TransactionDate >= DATE_SUB(NOW(),INTERVAL 1 YEAR)")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	######## MINIMUM VISITBALNCE
	MinBal=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT MIN(Vm_Visitsbalance) from Master WHERE CardNumber = '$CardNumber'")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

	######## COUNT VISITS OVER LIFETIME
	Lifetime=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT COUNT(*) from Master WHERE CardNumber = '$CardNumber' 
								AND Vm_VisitsAccrued = '1'")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	######## 
	Lifetimereal="$(($MinBal+$Lifetime))"
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	######## MINIMUM VISITBALNCE
	VmVB=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT MAX(Vm_Visitsbalance) from Master WHERE CardNumber = '$CardNumber'")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

	##### GET MAX  TRANSACTIONDATE
	MaxDate=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT MAX(TransactionDate) from Master WHERE CardNumber = '$CardNumber'")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR	
		##### GET 2ND TO MAX TRANSACTIONDATE
		SecondMax=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT TransactionDate from Master WHERE CardNumber = '$CardNumber' 
										AND Vm_VisitsAccrued = '1' ORDER BY TransactionDate DESC limit 1,1") 
		trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
		##### IF SECONDMAX IS NULL / EMPTY
		if [ -z "$SecondMax" ]
		then

			##### UPDATE ONLY FIRST FREQUENCIES
			mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET FreqCurrent = DATEDIFF(NOW(), '$MaxDate'), Freq12mos = '$PrevYear', 
										FreqLifetime = '$Lifetimereal'  WHERE CardNumber = '$CardNumber'"
			trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR	
			#echo $CardNumber" first only MAX "$MaxDate" 2ND "$SecondMax"  Prevyr "$PrevYear" VmVB "$VmVB 
			#echo "PrevLifereal "$Lifetimereal" prevlifenotreal"$Lifetime" MinBal "$MinBal

		##### IF SECONDMAX HAS A VALUE
		else
			##### GET 3RD TO MAX TRANSACTIONDATE
			ThirdMax=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT transactiondate from Master WHERE CardNumber = '$CardNumber' 
										AND Vm_VisitsAccrued = '1' ORDER BY TransactionDate DESC limit 2,1") 
			trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
			##### IF THIRDMAX IS NULL / EMPTY
			if [ -z "$ThirdMax" ]
			then
				##### UPDATE ONLY FIRST AND SECOND FREQUENCIES
				mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET FreqCurrent = DATEDIFF(NOW(), '$MaxDate'), 
										FreqRecent = DATEDIFF('$MaxDate', '$SecondMax'), Freq12mos = '$PrevYear', 
										FreqLifetime = '$Lifetimereal'  WHERE CardNumber = '$CardNumber'"
				trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR			   
				#echo $CardNumber" first and second MAX "$MaxDate" 2ND "$SecondMax" Prevyr "$PrevYear" VmVB "$VmVB
				#echo " PrevLifereal "$Lifetimereal" prevlifenotreal "$Lifetime" MinBal "$MinBal
				

			##### IF THIRDMAX HAS A VALUE
			else
				##### UPDATE ALL FREQUENCIES
				mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET FreqCurrent = DATEDIFF(NOW(), '$MaxDate'), 
										FreqRecent = DATEDIFF('$MaxDate', '$SecondMax'), 
										FreqPrevious = DATEDIFF('$SecondMax', '$ThirdMax'), Freq12mos = '$PrevYear', 
										FreqLifetime = '$Lifetimereal'   WHERE CardNumber = '$CardNumber'"
			trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
			#echo $CardNumber" first second third MAX "$MaxDate" 2ND "$SecondMax" 3RD "$ThirdMax" Prevyr "$PrevYear" VmVB "$VmVB
			#echo " PrevLifereal "$Lifetimereal" prevlifenotreal "$Lifetime" MinBal "$MinBal

				
			fi

		fi
done || trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo "Updated Frequencies in Master table"


