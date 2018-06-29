#! //bin/bash
# LOG IT TO SYSLOG
############################################################################################
################## THIS SCRIPT SHOULD DO ITS WORK IN A NON PRODUCTION DIRECTORY !!!!!
############################################################################################
########## ADD ERROR HANDLING AT EACH FAIL POINT ###########################################

# exec 1> >(logger -s -t $(basename $0)) 2>&1

#UNCOMMENT NEXT FOR VERBOSE
#set -x
##### HALT AND CATCH FIRE IF ANY COMMANd FAILS
set -e

##### INSERT px.ca.process contents (after set -e)
ExchangeCounter=$'0'
NoExchange=$'0'
OddCase=$'0'


### VISIT BALANCE FIX ####################### WE WILL PROCESS EVERY CARD
mysql  --login-path=local -DSRG_Dev -N -e "SELECT DISTINCT(CardNumber) FROM CardActivity_Live ORDER BY CardNumber ASC" | while read -r CardNumber;
do

	######## GET FIRST DATE
	Min_dob=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MIN(TransactionDate) from CardActivity_Live 
									WHERE CardNumber = '$CardNumber'")
	
	######## IF A BALANCE GREATER THAN 1 ON min_dob THEN THIS WAS AN EXCHANGED CARD
	CarriedBal=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(VisitsBalance) from CardActivity_Live 
									WHERE TransactionDate = '$Min_dob' AND CardNumber = '$CardNumber'")



####  AN EXCHANGE
if [ "$CarriedBal"  -gt "1" ]
	then
		echo $CardNumber"   First Day: "$Min_dob"    EXCHANGED!!! CARRIED "$CarriedBal" # Visits"
		##### PX counts are correct
		# mysql  --login-path=local -DSRG_Dev -N -e "UPDATE CardActivity_Live SET Vm_VisitsBalance = VisitsBalance, 
		#						Vm_VisitsAccrued = VisitsAccrued WHERE CardNumber = '$CardNumber' "
	ExchangeCounter=$[$ExchangeCounter +1]
fi 




############## PROCESS CARDS THAT WERE NOT EXCHANGED
	####### WHEN WAS THIS CARD ACTIVATED
	ActivDate=$(mysql --login-path=local -DSRG_Dev -N -e "SELECT TransactionDate FROM CardActivity_Live WHERE CardNumber = '$CardNumber' AND TransactionType = 'Activate' ")
	
	####### WAS THERE VISIT ACCRUED ON ACTIVATIONDATE
	ActivVisit=$(mysql --login-path=local -DSRG_Dev -N -e "SELECT MAX(VisitsBalance) FROM CardActivity_Live WHERE CardNumber = '$CardNumber' AND TransactionDate = '$ActivDate'")
	if [ "$ActivVisit" = "1" ]
	then
		echo $CardNumber"  Should have earliest visit accrual deleted, they accrued on activation day."
		# mysql  --login-path=local -DSRG_Dev -N -e "UPDATE CardActivity_Live SET VisitsBalance = '0', VisitsAccrued = '0' WHERE CardNumber = '$CardNumber' AND TransactionDate = 'ActivDate' "

		### They did not accrue on activation day because card was pre-activated, but they did accrue on the day they got the card
	NoExchange=$[$NoExchange +1]
	
	fi






	echo 'What is this case and how many are there?'
	OddCase=$[$OddCase +1]






done

echo "Exch="$ExchangeCounter
echo "NotExch="$NoExchange

