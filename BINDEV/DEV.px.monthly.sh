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


##################### ITERATE ON CardNumber TO CALCULATE 
###### -N is the No Headers in Output option
###### -e is the 'read statement and quit'


####### GET ONLY NON-EXCLUDED CARDNUMBERS


mysql  --login-path=local -DSRG_Dev -N -e "SELECT CardNumber, MAX(TranactionDate) FROM Master_test WHERE CardNumber IS NOT NULL
					AND (Master_test.Account_status <> 'TERMIN' 
					AND Master_test.Account_status <> 'SUSPEN' 
					AND Master_test.Account_status <> 'Exchanged'
					AND Master_test.Account_status <> 'Exchange' 
					AND Master_test.Account_status <> 'Exclude') OR (Account_status IS NULL)
				GROUP BY CardNumber ORDER BY CardNumber ASC" | while read -r CardNumber LastVisit;
do

	######## DETERMINE FIRST DATE OF EACH MONTH SINCE CARD INCEPTION
	
	########## CHECK IF THIS CARD HAS FOCUS MONTHS FROM PRIOR RUNS TO SAVE WORK

	






	PrevYear=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT COUNT(*) from Master_test WHERE CardNumber = '$CardNumber' 
								AND Vm_VisitsAccrued = '1' AND TransactionDate >= DATE_SUB(NOW(),INTERVAL 1 YEAR)")
		
		if [ -z "$SecondMax" ]
		then

			##### UPDATE ONLY FIRST FREQUENCIES
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET FreqCurrent = DATEDIFF(NOW(), '$MaxDate'), Freq12mos = '$PrevYear', FreqLifetime = '$Lifetimereal'  WHERE CardNumber = '$CardNumber'"
			echo $CardNumber" first only MAX "$MaxDate" 2ND "$SecondMax"  Prevyr "$PrevYear" VmVB "$VmVB" PrevLifereal "$Lifetimereal" prevlifenotreal"$Lifetime" MinBal "$MinBal

		##### IF SECONDMAX HAS A VALUE
		else
			##### GET 3RD TO MAX TRANSACTIONDATE
			ThirdMax=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT transactiondate from Master_test WHERE CardNumber = '$CardNumber' AND Vm_VisitsAccrued = '1' ORDER BY TransactionDate DESC limit 2,1") 
			##### IF THIRDMAX IS NULL / EMPTY
			if [ -z "$ThirdMax" ]
			then
				##### UPDATE ONLY FIRST AND SECOND FREQUENCIES
				mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET FreqCurrent = DATEDIFF(NOW(), '$MaxDate'), FreqRecent = DATEDIFF('$MaxDate', '$SecondMax'), Freq12mos = '$PrevYear', FreqLifetime = '$Lifetimereal'  WHERE CardNumber = '$CardNumber'"			   
				echo $CardNumber" first and second MAX "$MaxDate" 2ND "$SecondMax" Prevyr "$PrevYear" VmVB "$VmVB" PrevLifereal "$Lifetimereal" prevlifenotreal "$Lifetime" MinBal "$MinBal
				

			##### IF THIRDMAX HAS A VALUE
			else
				##### UPDATE ALL FREQUENCIES
				mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET FreqCurrent = DATEDIFF(NOW(), '$MaxDate'), FreqRecent = DATEDIFF('$MaxDate', '$SecondMax'), FreqPrevious = DATEDIFF('$SecondMax', '$ThirdMax'), Freq12mos = '$PrevYear', FreqLifetime = '$Lifetimereal'   WHERE CardNumber = '$CardNumber'"

			echo $CardNumber" first second third MAX "$MaxDate" 2ND "$SecondMax" 3RD "$ThirdMax" Prevyr "$PrevYear" VmVB "$VmVB" PrevLifereal "$Lifetimereal" prevlifenotreal "$Lifetime" MinBal "$MinBal

				
			fi

		fi
done



echo Frequencies Updated

