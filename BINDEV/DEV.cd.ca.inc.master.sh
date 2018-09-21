#! //bin/bash
# LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# UNCOMMENT NEXT FOR VERBOSE
# set -x
##### HALT AND CATCH FIRE IF ANY COMMAND FAILS
# set -e

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


######### UBER JOIN LIVE CHECK DETAIL WITH LIVE SQUASHED CARD ACTIVITY
# Delete Temp table if it exists
mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP TABLE IF EXISTS Master_temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER TEMP TABLE DROPPED'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_Dev -N -e "CREATE TABLE Master_temp LIKE Master_structure"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER TEMP CREATED'

###### WE ONLY GET THE LAST WEEKS WORTH OF DATA
mysql  --login-path=local -DSRG_Dev -N -e "INSERT INTO Master_temp SELECT CD.*, CA.* FROM CheckDetail_Live AS CD 
						LEFT JOIN CardActivity_squashed_2 AS CA ON CD.POSkey = CA.POSkey 
						WHERE CD.DOB >= DATE_SUB(CURDATE(), INTERVAL 14 DAY) 
						UNION SELECT CD.*, CA.* FROM .CheckDetail_Live as CD 
						RIGHT JOIN CardActivity_squashed_2 AS CA ON CD.POSkey = CA.POSkey 
						WHERE CD.DOB >= DATE_SUB(CURDATE(), INTERVAL 14 DAY)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
# echo 'UBER JOIN COMPLETED'
echo 'MASTER TEMP UPDATED WITH UBER CARD ACTIVITY AND CHECK DETAIL FROM PAST TWO WEEKS'

# Create enroll_date and Account_status fields
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE Master_temp ADD EnrollDate VARCHAR(11)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

# Create ACCOUNT STATUS
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE Master_temp ADD Account_status VARCHAR(26)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

# Create ACCOUNT STATUS INDEX
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE Master_temp ADD INDEX(Account_status)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER TEMP ENROLLDATE AND ACCOUNT STATUS FIELDS CREATED'

# AVOID DUPES DELETE SAME INTERVAL BACK
mysql  --login-path=local --silent -DSRG_Dev -N -e "DELETE FROM Master WHERE DOB >= DATE_SUB(CURDATE(), INTERVAL 14 DAY) "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER TRUNCATED BACK TWO WEEKS'

# Copy Dev Master to Prod
mysql  --login-path=local --silent -DSRG_Dev -N -e "INSERT INTO Master SELECT * FROM Master_temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER POPULATED FROM MASTER TEMP'


####### MASTER TABLE GUEST INFO UPDATE
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master JOIN Guests_Master ON Master.CardNumber = Guests_Master.CardNumber 
							SET Master.EnrollDate = Guests_Master.EnrollDate, Master.Account_status = Guests_Master.AccountStatus"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER ACCOUNT STATUSES UPDATED FROM GUESTS MASTER TABLE'

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master JOIN Px_exchanges ON Master.CardNumber = Px_exchanges.CurrentCardNumber SET Master.Account_status = 'Exchange' "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER EXCHANGED ACCOUNTS STATUSES UPDATED FROM PX EXCHANGES TABLE'

######### EXCLUDES SECTION USE OR NOT ? ? ?
# mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master JOIN Excludes ON Master.CardNumber = Excludes.CardNumber SET Master.Account_status = 'Exclude' "
# trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER - NO ACCOUNTS EXCLUDED !!!!!!!!!!!!!!!'


######## UPDATE THE EMPTY CHECKDETAIL FIELDS WITH PX DATA
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET CheckNumber = CheckNo_px WHERE CheckNumber IS NULL "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER EMPTY CHECKNO POPULATED FROM PX DATA'


mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET LocationID = LocationID_px WHERE LocationID IS NULL "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER EMPTY LOCATION ID POPULATED FROM PX DATA'

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET POSkey = POSKey_px WHERE POSkey IS NULL "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo MASTER EMPTY POS KEYS POPULATED FROM PX DATA

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET GrossSalesCoDefined = DollarsSpentAccrued WHERE GrossSalesCoDefined IS NULL 
						AND Master.Account_status <> 'TERMIN' AND Master.Account_status <> 'SUSPEN' 
						AND Master.Account_status <> 'Exchanged' AND Master.Account_status <> 'Exchange' 
						AND Master.Account_status <> 'Exclude' "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER GROSSSALESCODEFINED FIELD POPULATED'
echo '(PROMOS OR COMPS COULD NOT BE ADDED, LOWBALL FIGURES)'


###### -N is the No Headers in Output option
###### -e is the 'read statement and quit'
######## WE ARE ###

mysql  --login-path=local -DSRG_Dev -N -e "SELECT Master.DOB FROM Master  WHERE Master.DOB IS NOT NULL AND DOB >= DATE_SUB(NOW(),INTERVAL 14 DAY) 
				GROUP BY Master.DOB ORDER BY Master.DOB DESC" | while read -r TransactionDate;
do

		######## GET FY FOR THIS TransactionDate (DOB)
		FY=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT FY from Lunas WHERE DOB = '$TransactionDate'")

		######## GET FY FOR THIS TransactionDate (DOB)
		YLuna=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT YLuna from Lunas WHERE DOB = '$TransactionDate'")

		######## GET FY FOR THIS TransactionDate (DOB)
		Luna=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT Luna from Lunas WHERE DOB = '$TransactionDate'")

		######## IF VARIABLE HAS NO VALUE SET TO NULL
		if [ -z $Luna ] 
		then 
		Luna='0'
		fi

		##### UPDATE FISCAL YEAR FROM TRANSACTIONDATE
		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET FY = '$FY',YLuna = '$YLuna', Luna='$Luna' WHERE Master.DOB = '$TransactionDate'"
		#echo $TransactionDate updated FY= $FY YLuna = $YLuna  Luna = $Luna

done
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER FY YLUNA FIELDS UPATED WITH DATA FROM LUNA TABLE'



################################ VISIT BALANCE FIX SECTION ########################################
### what if more than one transaction per day

mysql  --login-path=local -DSRG_Dev -N -e "SELECT DISTINCT(CardNumber) FROM Master WHERE CardNumber IS NOT NULL AND DOB >= DATE_SUB(NOW(),INTERVAL 14 DAY) ORDER BY CardNumber ASC" | while read -r CardNumber;
do
	
		# GET FIRST TRANSACTION
		Min_dob=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MIN(TransactionDate) from Master WHERE CardNumber = '$CardNumber'")
		trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

		######## GET visitsaccrued FOR THIS TransactionDate (DOB)
		VisitsAccrued=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(VisitsAccrued) from Master WHERE TransactionDate = '$Min_dob' and CardNumber = '$CardNumber'")
		trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
		##### CAN NOT BE NULL
		if [ -z $VisitsAccrued ] 
		then 
			VisitsAccrued='0'
		fi

		CarriedBal=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(VisitsBalance) from Master WHERE TransactionDate = '$Min_dob' AND CardNumber = '$CardNumber'")
		trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
			##### CAN NOT BE NULL
		if [ -z $CarriedBal ] 
		then 
			CarriedBal='0'
		fi

	
		#### NOT AN EXCHANGE
		######## VISIT ACCRUED ON FIRST TRANSACTIONDATE
		if [[ $CarriedBal -eq 1 && $VisitsAccrued -eq 1 ]]
		then
			# echo $CardNumber"          Accrued on First Day!!!!       "$Min_dob"       no exchange       "$CarriedBal
			##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsBalance = VisitsBalance -1 WHERE CardNumber = '$CardNumber' AND VisitsBalance IS NOT NULL AND VisitsBalance != '0'"
			trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

			##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsAccrued = '0' WHERE CardNumber = '$CardNumber' and TransactionDate > '$Min_dob'"
			trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

			##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsAccrued = VisitsAccrued WHERE CardNumber = '$CardNumber' and TransactionDate > '$Min_dob'"
			trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

		fi



		#### NOT AN EXCHANGE
		if [[ $CarriedBal = 0 ]]
		then
		
			########### VISIT ACCRUED NULL
			if  [ $VisitsAccrued -eq 0 ] ||  [ -z $VisitsAccrued  ] 
			then
				# echo $CardNumber" DID NOT Accrue First Day "$Min_dob" no exchange "$CarriedBal
				##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
				mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsBalance = VisitsBalance, Vm_VisitsAccrued = VisitsAccrued WHERE CardNumber = '$CardNumber' "
				trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
			else
				##### ODD CASES - NO BALANCE BUT 1 VISIT ACCRUED
				# echo $CardNumber" Odd Case Min_dob:"$Min_dob" Visits Accrued:"$VisitsAccrued" Carried Balance"$CarriedBal
				##### SET FIRST DATES visitsaccrued to 0 (to account for visit counted on enrollment day), vm_visitsbalance = visitsbalance
				mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsAccrued = '0' WHERE CardNumber = '$CardNumber' and TransactionDate = '$Min_dob'"
				trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

				##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
				mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsAccrued = VisitsAccrued, Vm_VisitsBalance = VisitsBalance WHERE CardNumber = '$CardNumber' and TransactionDate > '$Min_dob'"
				trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	
			fi
		fi


		####  AN EXCHANGE
		if [ $CarriedBal  -gt 1 ]
		then
			# echo 'XXX '$CardNumber' Carried Bal should be greater than 1' $CarriedBal
			# echo $CardNumber"        First Day         "$Min_dob"       EXCHANGED!!! "$CarriedBal
			##### PX counts are correct
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsBalance = VisitsBalance, Vm_VisitsAccrued = VisitsAccrued WHERE CardNumber = '$CardNumber' "
			trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR	

		fi

		##### FIX THE MULTI TRANS ON DAY 1
		############## AFTER WE FIGURE OUT WHY IT HAPPENS
		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsBalance = '0' WHERE Vm_VisitsBalance ='-1'"
		trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


	######### THESE ARE THE FIELDS WE WILL CALCULATE EVERY DAY #################################
	#1.	 Historical Current Frequency (Hist_current_freq): Transaction Date (DOB) - Last visit date
	#2.      Current Frequency (Current_freq): Today-Last visit date
	#3.      Recent Frequency (Recent_freq): Last Visit Date-Previous visit date (2 visits back)
	#4.      Previous Frequency: Previous visit date (2 visits back)- 3 visits back
	#5.      12 Month Frequency (Year_freq): Count Visits over the previous 12 months
	#6.      Lifetime Frequency (Life_freq): Count Visits since Enrollment date

	####### CALC-ing OFF Vm_VisitsAccrued



	######## COUNT VISITS OVER PREVIOUS 12 MONTHS AND LIFETIME
	PrevYear=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT COUNT(*) from Master WHERE CardNumber = '$CardNumber' AND TransactionDate <> EnrollDate 
								AND Vm_VisitsAccrued = '1' AND TransactionDate >= DATE_SUB(NOW(),INTERVAL 1 YEAR)")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	######## MINIMUM VISITBALNCE
	MinBal=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MIN(Vm_Visitsbalance) from Master WHERE CardNumber = '$CardNumber'")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

	######## COUNT VISITS OVER LIFETIME
	Lifetime=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT COUNT(*) from Master WHERE CardNumber = '$CardNumber' 
								AND Vm_VisitsAccrued = '1'")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	######## 
	Lifetimereal="$(($MinBal+$Lifetime))"
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	######## MINIMUM VISITBALNCE
	VmVB=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(Vm_Visitsbalance) from Master WHERE CardNumber = '$CardNumber'")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

	##### GET MAX  TRANSACTIONDATE
	MaxDate=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(TransactionDate) from Master WHERE CardNumber = '$CardNumber'")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR	

	##### GET 2ND TO MAX TRANSACTIONDATE
	SecondMax=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT TransactionDate from Master WHERE CardNumber = '$CardNumber' 
										AND Vm_VisitsAccrued = '1' ORDER BY TransactionDate DESC limit 1,1") 
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	##### IF SECONDMAX IS NULL / EMPTY
	if [ -z $SecondMax ]
	then

		##### UPDATE ONLY FIRST FREQUENCIES
		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET FreqCurrent = DATEDIFF(NOW(), '$MaxDate'), Freq12mos = '$PrevYear', 
									FreqLifetime = '$Lifetimereal'  WHERE CardNumber = '$CardNumber'"
		trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR	
		#echo $CardNumber" first only MAX "$MaxDate" 2ND "$SecondMax"  Prevyr "$PrevYear" VmVB "$VmVB 
		#echo "PrevLifereal "$Lifetimereal" prevlifenotreal"$Lifetime" MinBal "$MinBal

		##### IF SECONDMAX HAS A VALUE
		else
			##### GET 3RD TO MAX TRANSACTIONDATE
			ThirdMax=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT transactiondate from Master WHERE CardNumber = '$CardNumber' 
										AND Vm_VisitsAccrued = '1' ORDER BY TransactionDate DESC limit 2,1") 
			trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
			##### IF THIRDMAX IS NULL / EMPTY
			if [ -z $ThirdMax ]
			then
				##### UPDATE ONLY FIRST AND SECOND FREQUENCIES
				mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET FreqCurrent = DATEDIFF(NOW(), '$MaxDate'), 
										FreqRecent = DATEDIFF('$MaxDate', '$SecondMax'), Freq12mos = '$PrevYear', 
										FreqLifetime = '$Lifetimereal'  WHERE CardNumber = '$CardNumber'"
				trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR			   
				#echo $CardNumber" first and second MAX "$MaxDate" 2ND "$SecondMax" Prevyr "$PrevYear" VmVB "$VmVB
				#echo " PrevLifereal "$Lifetimereal" prevlifenotreal "$Lifetime" MinBal "$MinBal
				
			##### IF THIRDMAX HAS A VALUE
			else
				##### UPDATE ALL FREQUENCIES
				mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET FreqCurrent = DATEDIFF(NOW(), '$MaxDate'), 
										FreqRecent = DATEDIFF('$MaxDate', '$SecondMax'), 
										FreqPrevious = DATEDIFF('$SecondMax', '$ThirdMax'), Freq12mos = '$PrevYear', 
										FreqLifetime = '$Lifetimereal'   WHERE CardNumber = '$CardNumber'"
			trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
			#echo $CardNumber" first second third MAX "$MaxDate" 2ND "$SecondMax" 3RD "$ThirdMax" Prevyr "$PrevYear" VmVB "$VmVB
			#echo " PrevLifereal "$Lifetimereal" prevlifenotreal "$Lifetime" MinBal "$MinBal

				
			fi

		fi
done || trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


## CHECKDETAIL ##### REMOVE DUPLICATE ROWS FROM CHECKDETAIL LIVE TABLE
mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP TABLE IF EXISTS Master_Live_temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
mysql  --login-path=local --silent -DSRG_Dev -N -e "CREATE table Master_Live_temp LIKE Master"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
mysql  --login-path=local --silent -DSRG_Dev -N -e "INSERT INTO Master_Live_temp SELECT * FROM Master GROUP BY POSkey"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP table Master"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
mysql  --login-path=local --silent -DSRG_Dev -N -e "RENAME table Master_Live_temp TO Master"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


echo 'MASTER TABLE FREQUENCY FIELDS UPDATED AND VISIT BALANCE FIX APPLIED'
############# COPY TO PROD ##############
# Delete Prod Master table if it exists
#mysql  --login-path=local --silent -DSRG_Prod -N -e "DROP TABLE IF EXISTS Master"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'PROD MASTER TABLE DROPPED'

# Copy Dev Master to Prod
#mysql  --login-path=local --silent -DSRG_Prod -N -e "CREATE TABLE Master LIKE SRG_Dev.Master;"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'PROD MASTER TABLE CREATED'

# Copy Dev Master to Prod
#mysql  --login-path=local --silent -DSRG_Prod -N -e "INSERT INTO Master SELECT * FROM SRG_Dev.Master;"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'PROD MASTER POPULATED FROM DEV MASTER'

