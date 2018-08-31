#! //bin/bash
# LOG IT TO SYSLOG
########## ADD ERROR HANDLING AT EACH FAIL POINT ###########################################

# exec 1> >(logger -s -t $(basename $0)) 2>&1


#UNCOMMENT NEXT FOR VERBOSE
# set -x
##### HALT AND CATCH FIRE IF ANY COMMANd FAILS
set -e

###### -N is the No Headers in Output option
###### -e is the 'read statement and quit'
###### { encapulates the while loop so variables do not disappear

### how do we do from a date not that dar in past without missing ca or cd side?

################ We Do a full reload of Master table from Master Temp should just update


##### ************* follows is code from test at cardactivity, but there are no vm_vist* fields
#### WHEN GUESTS_MASTER IS UP TO DATE WHEN CAN RUN THIS ON JUST THE TEMP TABLE USING ENROLLDATE
#####################################################################

##### START VISITBALANCE FIX HERE
ExchangeCounter=$'0'
NoExchange=$'0'
OddCase=$'0'

#UNCOMMENT NEXT FOR VERBOSE
set -x

### VISIT BALANCE FIX ####################### WE WILL PROCESS EVERY CARD
mysql  --login-path=local -DSRG_Dev -N -e "SELECT DISTINCT(CardNumber) FROM Master ORDER BY CardNumber ASC" | while read -r CardNumber;
do
	######## GET FIRST DATE
	Min_dob=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MIN(TransactionDate) from Master 
									WHERE CardNumber = '$CardNumber'")

	######## IF A BALANCE GREATER THAN 1 ON min_dob THEN THIS WAS AN EXCHANGED CARD
	CarriedBal=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(VisitsBalance) from Master 
									WHERE TransactionDate = '$Min_dob' AND CardNumber = '$CardNumber' AND VisitsBalance IS NOT NULL")

####  AN EXCHANGE IF THE VISITBALANCE ON THE FIRST TRANSACTION
if [ "$CarriedBal"  -gt "1" ]
	then
		echo $CardNumber"   First Day: "$Min_dob"    EXCHANGED!!! CARRIED "$CarriedBal" # Visits"
		##### PX counts are correct
		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsBalance = VisitsBalance, 
								Vm_VisitsAccrued = VisitsAccrued WHERE CardNumber = '$CardNumber' "
	ExchangeCounter=$[$ExchangeCounter +1]
else
	############## PROCESS CARDS THAT WERE NOT EXCHANGED
	####### WHEN WAS THIS CARD ACTIVATED
	ActivDate=$(mysql --login-path=local -DSRG_Dev -N -e "SELECT TransactionDate FROM Master WHERE CardNumber = '$CardNumber' AND TransactionType = 'Activate'")
	
	####### WAS THERE VISIT ACCRUED ON ACTIVATIONDATE
	ActivVisit=$(mysql --login-path=local -DSRG_Dev -N -e "SELECT MAX(VisitsBalance) FROM Master WHERE CardNumber = '$CardNumber' AND TransactionDate = '$ActivDate'")
	if [ "$ActivVisit" = "1" ]
	then
		# echo $CardNumber"  Should have earliest visit accrual deleted, they accrued on activation day."
		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET VM_VisitsBalance = '0', VM_VisitsAccrued = '0' WHERE CardNumber = '$CardNumber' AND TransactionDate = '$ActivDate' "

		### They did not accrue on activation day because card was pre-activated, but they did accrue on the day they got the card
	NoExchange=$[$NoExchange +1]
	else

#	echo $CardNumber' ODD CASE! Activation date= '$ActivDate' ActivVisit= '$activVisit' Minimum transaction date= '$Min_dob' CarriedBalance= '$CarriedBal
	OddCase=$[$OddCase +1]
	
	fi
fi
echo "Exch="$ExchangeCounter
echo "NotExch="$NoExchange
echo "OddCase="$OddCase

done

##### ************* END code from test at cardactivity, but there are no vm_vist* fields












########################### 	THIS NEEDS TO BE RUN ON THE CARDACTIVITY_TEMP TABLE BEFORE DATA IS PROCESSED. #############################
##########################         WHAT IF IT IS AN EXCHANGED CARD ???????????? ############################

mysql  --login-path=local -DSRG_Dev -N -e "SELECT DISTINCT(CardNumber) FROM Master ORDER BY CardNumber ASC" | while read -r CardNumber;
do
	
	######## GET FIRST TRANSACTION
	Min_dob=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MIN(TransactionDate) from Master WHERE CardNumber = '$CardNumber'")

	######## GET visitsaccrued FOR THIS TransactionDate (DOB)
	VisitsAccrued=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(VisitsAccrued) from Master WHERE TransactionDate = '$Min_dob' and CardNumber = '$CardNumber'")

	CarriedBal=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(VisitsBalance) from Master WHERE TransactionDate = '$Min_dob' AND CardNumber = '$CardNumber'")

	#### NOT AN EXCHANGE
	######## VISIT ACCRUED ON FIRST TRANSACTIONDATE
	if [[ "$CarriedBal" = "1" && "$VisitsAccrued" = "1" ]]
	then
		echo $CardNumber"          Accrued on First Day!!!!       "$Min_dob"       no exchange       "$CarriedBal
		##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsBalance = VisitsBalance -1 WHERE CardNumber = '$CardNumber' AND VisitsBalance IS NOT NULL AND VisitsBalance != '0'"

		##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsAccrued = '' WHERE CardNumber = '$CardNumber' and TransactionDate > '$Min_dob'"

		##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsAccrued = VisitsAccrued WHERE CardNumber = '$CardNumber' and TransactionDate > '$Min_dob'"

	fi



	#### NOT AN EXCHANGE
	if [ "$CarriedBal" = "0" ]
	then
		
		########### VISIT ACCRUED NULL
		if  [ "$VisitsAccrued" = "0" ] ||  [ -z "$VisitsAccrued"  ] 
		then
			echo $CardNumber" DID NOT Accrue First Day "$Min_dob" no exchange "$CarriedBal
			##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsBalance = VisitsBalance, Vm_VisitsAccrued = VisitsAccrued WHERE CardNumber = '$CardNumber' "
		else
			##### ODD CASES - NO BALANCE BUT 1 VISIT ACCRUED
			echo $CardNumber" Odd Case Min_dob:"$Min_dob" Visits Accrued:"$VisitsAccrued" Carried Balance"$CarriedBal
			##### SET FIRST DATES visitsaccrued to 0 (to account for visit counted on enrollment day), vm_visitsbalance = visitsbalance
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsAccrued = '' WHERE CardNumber = '$CardNumber' and TransactionDate = '$Min_dob'"
			##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsAccrued = VisitsAccrued, Vm_VisitsBalance = VisitsBalance WHERE CardNumber = '$CardNumber' and TransactionDate > '$Min_dob'"

		fi
	fi


	####  AN EXCHANGE
	if [ "$CarriedBal"  -gt "1" ]
	then
		echo $CardNumber"        First Day         "$Min_dob"       EXCHANGED!!! "$CarriedBal
		##### PX counts are correct
		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsBalance = VisitsBalance, Vm_VisitsAccrued = VisitsAccrued WHERE CardNumber = '$CardNumber' "

	fi

	##### FIX THE MULTI TRANS ON DAY 1
	############## AFTER WE FIGURE OUT WHY IT HAPPENS
	# mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET Vm_VisitsBalance = '0' WHERE Vm_VisitsBalance ='-1'"


done

