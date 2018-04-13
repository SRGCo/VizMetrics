#! //bin/bash
# NEXT for echo
# set -x



############################################################################################
################## THIS SCRIPT SHOULD DO FILE HANDLING IN A NON PRODUCTION DIRECTORY !!!!!
############################################################################################
########## ADD ERROR HANDLING AT EACH FAIL POINT ###########################################


#exec 1> >(logger -s -t $(basename $0)) 2>&1

##### HALT AND CATCH FIRE AT SINGLE ITERATION LEVEL
set -e

######### THESE ARE THE Px_monthly FIELDS
#1.	CardNumber
#2.	Date_Calcd = 1st day of focus month
#3.	FirstName = Guest firstname from 'Guests' table (should be Px_guests table) 
#4.	LastName = Guest lastname (same every record for this account)
#5	EnrollDate = Guest enroll date (from guests table ?????)
#6	Zip = Guests' zipcode from guests table
#7	DollarsSpentMonth = Dollars spent during focus month
#8.	PointsRedeemedMonth = Points redeemed during focus month
#9.	PointsAccruedMonth = Points acrrued during focus month
#10.	VisitsAccruedMonth = Visits accrued during focus month
#11.	LifetimeSpendBalance = Lifetime Dollars spent (as of 1st day of focus month)
#12.	LifetimePointsBalance = Lifetime points accrued (as of 1st day of focus month)
#13.	LifetimeVisistsBalance = Lifetime visits accrued  (as of 1st day of focus month)
#14.	LastVisit = Last visit date (ever)
#15.	FreqCurrent = Current Freq (same every record for this account) 
#16.	FreqRecent = Recent Freq  (same every record for this account)
#17.	Freq12mos = 12Mo Freq (same every record for this account)
#18.	HistFreqCurrent = Historical current freq (current freq as of 1st day of focus month)


########## the excludes
## CardNumber IS NOT NULL AND (Account_status <> 'TERMIN' AND Account_status <> 'SUSPEN' AND Account_status <> 'Exchanged'
## 	AND Account_status <> 'Exchange' AND Account_status <> 'Exclude') OR (Account_status IS NULL)
					


##################### ITERATE ON CardNumber TO CALCULATE 
###### -N is the No Headers in Output option
###### -e is the 'read statement and quit'


####### GET ONLY NON-EXCLUDED CARDNUMBERS


mysql  --login-path=local -DSRG_Dev -N -e "SELECT DISTINCT(CardNumber)
					FROM Master_test WHERE  CardNumber = '390000000003838'
					ORDER BY CardNumber ASC" | while read -r CardNumber;
do

	mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(TransactionDate) as MaxDate, 
						EXTRACT(MONTH FROM MIN(transactiondate)) as MinMonth, 
						EXTRACT(YEAR FROM MIN(transactiondate)) as MinYear
						FROM Master_test WHERE  CardNumber = '$CardNumber'" |while read -r MaxDate MinMonth MinYear; 
	do

echo "OG MinMonth "$MinMonth
######## DECREASE 1ST MONTH BY 1 (FOR ADDITION IN ITERATION) UNLESS IT IS 1 (JAN) THEN MAKE IT TWELVE AND ROLL BACK THE YEAR
######## DETERMINE FIRST DATE OF EACH MONTH SINCE CARD INCEPTION
if [ "$MinMonth" == 1 ] 
	then 
		MinMonth="12"
		focusmonth=$MinYear"-"$MinMonth"-01" 
	else 
		MinMonth=$((MinMonth - 1))  
		focusmonth=$MinYear"-"$MinMonth"-01" 
fi
	echo "CardNumber "$CardNumber" MaxDate "$MaxDate" MinYear "$MinYear" focusmonth "$focusmonth" nextmonth "$nextmonth" MinMonth "$MinMonth			

########## CHECK IF THIS CARD HAS FOCUS MONTHS FROM PRIOR RUNS TO SAVE WORK
########## WHILE THE FOCUS MONTH ISNT MONTH AFTER MAX TRANSACTION DATE ITERATE THROUGH THE MONTHS/YEARS
#	while [ "$focusmonth" !=  "$nextmonth" ]
#	do
	
#	echo "focusmonth "$focusmonth" nextmonth "$nextmonth" MinMonth "$MinMonth			
	########## CHECK IF THIS CARD HAS FOCUS MONTHS FROM PRIOR RUNS TO SAVE WORK

	done
done




echo Frequencies Updated

