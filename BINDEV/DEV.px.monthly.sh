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

######### Px_monthly FIELDS
#1.	CardNumber
#2.	FocusDate = 1st day of focus month
#3.	FirstName = Guest firstname from 'Guests' table (should be Px_guests table) 
#4.	LastName = Guest lastname (same every record for this account)
#5	EnrollDate = Guest enroll date (from guests table ?????)
#6	Zip = Guests' zipcode from guests table
#7	DollarsSpentMonth = Dollars spent during focus month [DollarsSpentAccrued]
#8.	PointsRedeemedMonth = Points redeemed during focus month [SereniteePointsRedeemed]
#9.	PointsAccruedMonth = Points acrrued during focus month [SereniteePointsAccrued]
#10.	VisitsAccruedMonth = Visits accrued during focus month [VisitsAccrued]
#11.	LifetimeSpendBalance = Lifetime Dollars spent (as of FocusDate)
#12.	LifetimePointsBalance = Lifetime points accrued (as of FocusDate)
#13.	LifetimeVisistsBalance = Lifetime visits accrued  (as of FocusDate)
#14.	LastVisit = Last visit date (ever)
#15.	FreqCurrent = Current Freq (1st day of focus month - last visit date) 
#16.	FreqRecent = Recent Freq  (1st day of focus month - previous last visit date, 2 visits back)
#17.	Freq12mos = 12Mo Freq (Count visits over 12 months previous to 1st day of focus month)
#18.	HistFreqCurrent = Historical current freq (current freq as of FocusDate)
#19.	Lifetimefrequency = Count visits since enrollment (as of FocusDate)
#################### SEGMENTATION FIELDS NOT YET ADDED ################
#20.	field20 = LifeTime Freq segmentation 
#21.	field21 = 12mo freq segmentation
#22.	field22 = Recent freq segmentation
#23.	field23 = Current freq segmentation
#24.	field24 = program age
#25.	field25 = Visit Balance (at visit date segmentation)


########## the excludes
## CardNumber IS NOT NULL AND (Account_status <> 'TERMIN' AND Account_status <> 'SUSPEN' AND Account_status <> 'Exchanged'
## 	AND Account_status <> 'Exchange' AND Account_status <> 'Exclude') OR (Account_status IS NULL)


##################### ITERATE ON CardNumber TO CALCULATE 
###### -N is the No Headers in Output option
###### -e is the 'read statement and quit'


####### GET ONLY NON-EXCLUDED CARDNUMBERS


mysql  --login-path=local -DSRG_Dev -N -e "SELECT DISTINCT(CardNumber)
			FROM Master_test
			WHERE (SRG_Dev.Master_test.Account_status <> 'TERMIN' 
					AND SRG_Dev.Master_test.Account_status <> 'SUSPEN' 
					AND SRG_Dev.Master_test.Account_status <> 'Exchanged'
					AND SRG_Dev.Master_test.Account_status <> 'Exchange' 
					AND SRG_Dev.Master_test.Account_status <> 'Exclude') OR (Account_status IS NULL)
					ORDER BY CardNumber DESC" | while read -r CardNumber;
do
echo "CardNumber "$CardNumber
	######## GET FIRST NAME
	FirstName=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT FirstName FROM Guests WHERE CardNumber = '$CardNumber' LIMIT 1")

	######## GET LAST NAME
	LastName=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT LastName FROM Guests WHERE CardNumber = '$CardNumber' LIMIT 1")

	######## GET ENROLL DATE
	EnrollDate=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT EnrollDate FROM Guests WHERE CardNumber = '$CardNumber' LIMIT 1")

	######## GET ZIP
	Zip=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT Zip FROM Guests WHERE CardNumber = '$CardNumber' LIMIT 1")

echo "FirstName "$FirstName" LastName "$LastName" Enroll "$EnrollDate" Zip "$Zip
	######## GET MAxYear
	MaxDate=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(TransactionDate) FROM Master_test WHERE CardNumber = '$CardNumber'")
	MaxDateUnix=$(date +%s -d "$MaxDate") 

	######## GET MinYear
	MinDate=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MIN(TransactionDate) FROM Master_test WHERE CardNumber = '$CardNumber'")

echo "MinDate "$MinDate" MaxDate "$MaxDate

	FocusDate=$(date +%Y-%m-01 -d "$MinDate")
	FocusDateUnix=$(date +%s -d "$FocusDate")
	FocusDateEnd=$(date +%Y-%m-%d -d "$FocusDate + 1 Month -1 day")
	FocusDateEndUnix=$(date +%s -d "$FocusDateEnd") 
 
echo "STARTING------- FocusDate "$FocusDate" FocusDateEnd "$FocusDateEnd" MaxDate "$MaxDate" MinDate "$MinDate	
echo "Unixfocus "$FocusDateUnix" FocusDateUnixEnd "$FocusDateEndUnix

	while [ $FocusDateUnix -le $MaxDateUnix ]
	do	
		###### DO THE MONTHLY CALCULATION QUERIES HERE
		mysql  --login-path=local -DSRG_Dev -N -e "SELECT SUM(DollarsSpentAccrued),
								SUM(SereniteePointsRedeemed),
								SUM(SereniteePointsAccrued),
								SUM(VisitsAccrued)
								FROM Master_test WHERE  CardNumber = '$CardNumber'
								AND TransactionDate >= '$FocusDate'
								AND TransactionDate <= '$FocusDateEnd'" | while read -r DollarsSpentMonth PointsRedeemed PointsAccrued VisitsAccrued;
		do
			echo " FocusDate "$FocusDate" FocusDateEnd "$FocusDateEnd" DollarsSpentMonth "$DollarsSpentMonth" Ptsredeemed "$PointsRedeemed "PtsAccrued "$PointsAccrued" VisitsAccrued "$VisitsAccrued
		done


	FocusDate=$(date +%Y-%m-%d -d "$FocusDate + 1 Month")
	FocusDateEnd=$(date +%Y-%m-%d -d "$FocusDate + 1 Month - 1 day")
	FocusDateUnix=$(date +%s -d "$FocusDate") 



	done

done




echo Monthly Px Stats Updated

