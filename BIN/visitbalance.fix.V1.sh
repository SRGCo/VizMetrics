#! //bin/bash
# LOG IT TO SYSLOG
########## ADD ERROR HANDLING AT EACH FAIL POINT ###########################################

# exec 1> >(logger -s -t $(basename $0)) 2>&1

###### LAST PIPE SO COUNTER WORKS
shopt -s lastpipe

#UNCOMMENT NEXT FOR VERBOSE
# set -x
##### HALT AND CATCH FIRE IF ANY COMMANd FAILS
set -e

###### -N is the No Headers in Output option
###### -e is the 'read statement and quit'
###### { encapulates the while loop so variables do not disappear
mysql  --login-path=local -DSRG_Dev -N -e "SELECT DISTINCT(CardNumber) FROM Master_test WHERE CardNumber IS NOT NULL ORDER BY CardNumber ASC" | while read -r CardNumber;
do
	echo $CardNumber
	######## GET FIRST TRANSACTION
	Min_dob=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MIN(TransactionDate) from Master_test WHERE CardNumber = '$CardNumber'")

	######## GET FY FOR THIS TransactionDate (DOB)
	VisitsAccrued=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT VisitsAccrued from Master_test WHERE TransactionDate = '$Min_dob' and CardNumber = '$CardNumber'")


	##### SELECT ALL ROWS FOR THAT CARD AND SET Vm_VisitsAccrued = VisitsAccrued, Vm_VisitsBalance = VisitsBalance (they are the same)
	mysql  --login-path=local -DSRG_Dev -N -e "SELECT POSkey from Master_test WHERE CardNumber = '$CardNumber' ORDER BY POSkey ASC" |  while read -r POSkey;
	do
			
		if [ -z "$VisitsAccrued" ]
		##### IF VisitsAccrued IS NULL (NO EXTRA VISIT ON ENROLLMENT DAY) ##########
		then
			##### UPDATE WITH SAME VISIT VALUES
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET Vm_VisitsAccrued = VisitsAccrued, Vm_VisitsBalance = VisitsBalance WHERE POSkey = '$POSkey'"
	
		##### IF VisitsAccrued IS NULL (NO EXTRA VISIT ON ENROLLMENT DAY) ##########
		else
			##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET Vm_VisitsBalance = (VisitsBalance -1) WHERE POSkey = '$POSkey'"

		fi
	done
	
	##### UPDATE Vm_VisitsAccrued to ON EARLIEST TRANSACTIONDATE 
	mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET Vm_VisitsAccrued = '0' WHERE CardNumber = '$CardNumber' AND TransactionDate = '$Min_dob'"

done

