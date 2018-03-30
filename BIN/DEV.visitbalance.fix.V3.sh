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

### what if more than one transaction per day

mysql  --login-path=local -DSRG_Dev -N -e "SELECT DISTINCT(CardNumber) FROM Master_test ORDER BY CardNumber ASC" | while read -r CardNumber;
do
	
	######## GET FIRST TRANSACTION
	Min_dob=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MIN(TransactionDate) from Master_test WHERE CardNumber = '$CardNumber'")

	######## GET visitsaccrued FOR THIS TransactionDate (DOB)
	VisitsAccrued=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(VisitsAccrued) from Master_test WHERE TransactionDate = '$Min_dob' and CardNumber = '$CardNumber'")

	CarriedBal=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MIN(VisitsBalance) from Master_test WHERE TransactionDate = '$Min_dob' AND CardNumber = '$CardNumber'")

	#### NOT AN EXCHANGE
	######## VISIT ACCRUED ON FIRST TRANSACTIONDATE
	if [[ "$CarriedBal" = "1" && "$VisitsAccrued" = "1" ]]
	then
		echo $CardNumber"          Accrued on First Day!!!!       "$Min_dob"       no exchange       "$CarriedBal
		##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET Vm_VisitsBalance = VisitsBalance -1 WHERE CardNumber = '$CardNumber' AND VisitsBalance IS NOT NULL AND VisitsBalance != '0'"

		##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET Vm_VisitsAccrued = '' WHERE CardNumber = '$CardNumber' and TransactionDate > '$Min_dob'"

		##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET Vm_VisitsAccrued = VisitsAccrued WHERE CardNumber = '$CardNumber' and TransactionDate > '$Min_dob'"

	fi



	#### NOT AN EXCHANGE
	if [ "$CarriedBal" = "0" ]
	then
		
		########### VISIT ACCRUED NULL
		if  [ "$VisitsAccrued" = "0" ] ||  [ -z "$VisitsAccrued"  ] 
		then
			echo $CardNumber" DID NOT Accrue First Day "$Min_dob" no exchange "$CarriedBal
			##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET Vm_VisitsBalance = VisitsBalance, Vm_VisitsAccrued = VisitsAccrued WHERE CardNumber = '$CardNumber' "
		else
			##### ODD CASES - NO BALANCE BUT 1 VISIT ACCRUED
			echo $CardNumber" Odd Case Min_dob:"$Min_dob" Visits Accrued:"$VisitsAccrued" Carried Balance"$CarriedBal
			##### SET FIRST DATES visitsaccrued to 0 (to account for visit counted on enrollment day), vm_visitsbalance = visitsbalance
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET Vm_VisitsAccrued = '' WHERE CardNumber = '$CardNumber' and TransactionDate = '$Min_dob'"
			##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET Vm_VisitsAccrued = VisitsAccrued, Vm_VisitsBalance = VisitsBalance - 1 WHERE CardNumber = '$CardNumber' and TransactionDate > '$Min_dob'"

		fi
	fi


	####  AN EXCHANGE
	if [ "$CarriedBal"  -gt "1" ]
	then
		echo $CardNumber"        First Day         "$Min_dob"       EXCHANGED!!! "$CarriedBal
		##### PX counts are correct
		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET Vm_VisitsBalance = VisitsBalance, Vm_VisitsAccrued = VisitsAccrued WHERE CardNumber = '$CardNumber' "

	fi



done

