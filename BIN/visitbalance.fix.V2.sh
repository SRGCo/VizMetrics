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

mysql  --login-path=local -DSRG_Dev -N -e "SELECT DISTINCT(CardNumber) FROM Master_test2 ORDER BY CardNumber ASC" | while read -r CardNumber;
do
	echo $CardNumber
	######## GET FIRST TRANSACTION
	Min_dob=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MIN(TransactionDate) from Master_test2 WHERE CardNumber = '$CardNumber'")

	######## GET visitsaccrued FOR THIS TransactionDate (DOB)
	VisitsAccrued=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(VisitsAccrued) from Master_test2 WHERE TransactionDate = '$Min_dob' and CardNumber = '$CardNumber'")

	CarriedBal=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MIN(VisitsBalance) from Master_test2 WHERE TransactionDate = '$Min_dob' and CardNumber = '$CardNumber'")

	if [[ "$VisitsAccrued" > "0" && "$CarriedBal" < "1" ]] 
	##### IF VisitsAccrued equals 1 or 1.0000 AND NO CARRIED BALANCE
	then
		##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test2 SET Vm_VisitsBalance = VisitsBalance -1 WHERE CardNumber = '$CardNumber' AND VisitsBalance > 0 AND VisitsBalance IS NOT NULL"

	##### IF VisitsAccrued not = to 1 (therefore 0)
	else
		##### UPDATE WITH SAME VISIT VALUES
		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test2 SET Vm_VisitsAccrued = VisitsAccrued, Vm_VisitsBalance = VisitsBalance WHERE CardNumber = '$CardNumber'"

	fi

	##### UPDATE Vm_VisitsAccrued to ON EARLIEST TRANSACTIONDATE 
	mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test2 SET Vm_VisitsAccrued = '0' WHERE CardNumber = '$CardNumber' AND TransactionDate = '$Min_dob'"


done

