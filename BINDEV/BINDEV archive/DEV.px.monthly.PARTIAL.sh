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
#14.    LifetimePointsRedeemed = Lifetime points redeemed (as of FocusDate) 
#15	LastVisit = Last visit date (ever)
#16.*	FreqCurrent = Current Freq (1st day of focus month - last visit date) 
#17.X	FreqRecent = Recent Freq  (1st day of focus month - previous last visit date, 2 visits back)
#18.*	Freq12mos = 12Mo Freq (Count visits over 12 months previous to 1st day of focus month)
#19.-	HistFreqCurrent = Historical current freq (current freq as of FocusDate)
#20.-	Lifetimefrequency = Count visits since enrollment (as of FocusDate)
#21.-	LifetimeFreqSeg = LifeTime Freq segmentation 
#22.-+*	12MoFreqSeg = 12mo freq segmentation
#23.-	RecentFreqSeg = Recent freq segmentation
#24.-	CurFreqSeg = Current freq segmentation
#25.*	ProgramAge = months since enrollment month as of focusdate [+1 for MM calcs]
#26.XXXX	VisitBalance = Visit Balance (at visit date segmentation)


########## the excludes
## CardNumber IS NOT NULL AND (Account_status <> 'TERMIN' AND Account_status <> 'SUSPEN' AND Account_status <> 'Exchanged'
## 	AND Account_status <> 'Exchange' AND Account_status <> 'Exclude') 


##################### ITERATE ON CardNumber TO CALCULATE 
###### -N is the No Headers in Output option
###### -e is the 'read statement and quit'


##################################### THIS CALCULATES ALL VISITS FOR ALL CARDS SO Px_monthly SHOULD BE TRUNCATED BEFORE THIS RUNS 

# mysql  --login-path=local -DSRG_Dev -N -e "TRUNCATE table Px_monthly"
# echo 'Px_Monthly TRUNCATED FOR FULL RUN!!!!!!'
echo 'Px Monthly NOT truncated'



####### GET ONLY NON-EXCLUDED CARDNUMBERS
mysql  --login-path=local -DSRG_Dev -N -e "SELECT DISTINCT(CardNumber), MAX(Vm_VisitsBalance)
					FROM Master
					WHERE CardNumber > '6000227900187101'
					AND CardNumber IS NOT NULL 
					GROUP BY CardNumber	
					ORDER BY CardNumber ASC" | while read -r CardNumber VisitBalance;
do
	
	##### WE WILL ITERATE EACH CARD UP UNTIL MOST RECENT FOCUSDATE (FOCUSDATE CLOSEST TO CURDATE)
	TodayDate=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT CURDATE() as date FROM Master LIMIT 1")
	TodayDateUnix=$(date +%s -d "$TodayDate") 
	MaxDate=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(TransactionDate) FROM Master WHERE CardNumber = '$CardNumber'")
	MaxDateUnix=$(date +%s -d "$MaxDate") 
	MinDate=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MIN(TransactionDate) FROM Master WHERE CardNumber = '$CardNumber'")

	MinDateUnix=$(date +%s -d "$MinDate") 
	FocusDate=$(date +%Y-%m-01 -d "$MinDate")
	FocusDateUnix=$(date +%s -d "$FocusDate")
	FocusDateEnd=$(date +%Y-%m-%d -d "$FocusDate + 1 Month -1 day")
	FocusDateEndUnix=$(date +%s -d "$FocusDateEnd") 


########## WE EXCLUDE EXCHANGES ETC (SEE ABOVE)
	######## GET FIRST NAME
	
	FirstName=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT FirstName FROM Guests WHERE CardNumber = '$CardNumber' LIMIT 1")
	LastName=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT LastName FROM Guests WHERE CardNumber = '$CardNumber' LIMIT 1")
	mysql  --login-path=local -DSRG_Dev -N -e "SELECT EnrollDate, Zip FROM Guests WHERE CardNumber = '$CardNumber'  LIMIT 1" | while read -r "EnrollDate" "Zip"
	do
	while [ $FocusDateUnix -le $TodayDateUnix ]
	do	
		###### DO THE MONTHLY CALCULATION QUERIES HERE
		mysql  --login-path=local -DSRG_Dev -N -e "SELECT
								MIN(TransactionDate), 
								SUM(DollarsSpentAccrued),
								SUM(SereniteePointsRedeemed),
								SUM(SereniteePointsAccrued),
								SUM(VisitsAccrued)                   
								FROM Master WHERE  CardNumber = '$CardNumber'
								AND DollarsSpentAccrued IS NOT NULL
								AND VisitsAccrued > '0'
								AND TransactionDate >= '$FocusDate'
								AND TransactionDate <= '$FocusDateEnd'" | while read -r TransMonth DollarsSpentMonth PointsRedeemedMonth PointsAccruedMonth VisitsAccruedMonth;
		do
				echo "++++++++++++++++++++++++CARD: "$CardNumber" ++++++++++++++"

				mysql  --login-path=local -DSRG_Dev -N -e "SELECT SUM(DollarsSpentAccrued), 
									SUM(SereniteePointsRedeemed), 
									SUM(SereniteePointsAccrued), 
									SUM(VisitsAccrued) FROM Master WHERE CardNumber = '$CardNumber'
									AND TransactionDate < '$FocusDate'" | while read -r DollarsSpentLife PointsRedeemedLife PointsAccruedLife VisitsAccruedLife;
				do
	

					####### ADD ZEROs FOR NULLs on MONTHS OF NO ACTIVITY
					if [ $DollarsSpentMonth == 'NULL' ]
					then
					DollarsSpentMonth=0
					PointsRedeemedMonth=0 
					PointsAccruedMonth=0 
					VisitsAccruedMonth=0
					fi	
						
#################### FREQUENCY STARTS HERE  - - WRITE TO VARIABLES INSTEAD OF MASTER TABLE			

					
					# FREQUENCY STARTS HERE  - - WRITE TO VARIABLES INSTEAD OF MASTER TABLE			
					######## VISITS ACCRUED 12 MONTHS PREVIOUS TO FOCUSDATE (otherwise same query as master freq updater)
					PrevYear=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT COUNT(TransactionDate) FROM Master 
								WHERE CardNumber = '$CardNumber'
								AND TransactionDate <> EnrollDate  
								AND TransactionDate >= DATE_SUB('$FocusDate',INTERVAL 1 YEAR) 
								AND TransactionDate < '$FocusDate'																	
								AND Vm_VisitsAccrued = '1'")

					##### GET CURRENT FREQ AS OF FOCUS DATE
					CurrentFreq=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT DATEDIFF('$FocusDate' ,MAX(TRANSACTIONDATE)) FROM Master
						           	WHERE TransactionDate < '$FocusDate' 
								AND CardNumber = '$CardNumber' 
								AND VisitsAccrued > '0'")

					##### GET CURRENT FREQ AS OF FOCUS DATE PLUS 1 FOR MM CALCS
					ProgAge=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT (PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM '$FocusDate'), EXTRACT(YEAR_MONTH FROM '$EnrollDate')) + 1) AS months 
									FROM Master
									WHERE CardNumber = '$CardNumber' LIMIT 1")	

					# OFF UNTIL NEXT VERSION
					##### GET RECENT FREQ (2 visits back) AS OF FOCUS DATE
				#	TwoVisitsBack=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(TransactionDate) FROM Master
				#		           	WHERE TransactionDate < '$FocusDate' 
				#				AND CardNumber = '$CardNumber' 
				#				AND VisitsAccrued > '0'
				#				ORDER BY TransactionDate DESC LIMIT 1 , 1")


					# OFF UNTIL NEXT VERSION
					###### BASH COULD DO THIS EQUATION AND SAVE OVERHEAD !!!!!!!!!!
					#FreqRecent=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT DATEDIFF('$FocusDate' ,'$2VisitsBack') FROM Master")



					####### ADD blanks FOR NULLs 
					if [ $CurrentFreq == 'NULL' ]	
					then	
					CurrentFreq='0'	
					fi	
					####### ADD blanks FOR NULLs 
					if [ $PrevYear == 'NULL' ]	
					then	
					PrevYear='0'	
					fi
					####### ADD blanks FOR NULLs 
					if [ $ProgAge == 'NULL' ]	
					then	
					ProgAge='0'	
					fi
	
					####### ADD ZEROs FOR NULLs on MONTHS OF NO ACTIVITY
					if [ $DollarsSpentMonth == 'NULL' ]
					then
					DollarsSpentMonth=0
					fi	
					if [ $PointsRedeemedMonth == 'NULL' ]
					then
					PointsRedeemedMonth=0
					fi				
					if [ $PointsAccruedMonth == 'NULL' ]
					then
					PointsAccruedMonth=0
					fi
					if [ $VisitsAccruedMonth == 'NULL' ]
					then
					VisitsAccruedMonth=0
					fi

					if [ $DollarsSpentLife == 'NULL' ]
					then
					DollarsSpentLife=0
					fi					 
					if [ $PointsAccruedLife == 'NULL' ]
					then
					PointsAccruedLife=0
					fi
					if [ $VisitsAccruedLife == 'NULL' ]
					then
					VisitsAccruedLife=0
					fi
					if [ $PointsRedeemedLife == 'NULL' ]
					then
					PointsRedeemedLife=0
					fi

					if [ $PrevYear == 'NULL' ]
					then
					PrevYear=0
					fi					 
					if [ $CurrentFreq == 'NULL' ]
					then
					CurrentFreq=0
					fi
					if [ $ProgAge == 'NULL' ]
					then
					ProgAge=0
					fi
					# this is failing?  prob because variable doesnt exist in this version
					#if [ $FreqRecent == 'NULL' ]
					#then
					#FreqRecent=0
					#fi	

					####### ECHO DATA FOR DEBUG
					echo "FirstName"$FirstName" LastName"$LastName" Enrolled"$EnrollDate" Zip"$Zip" FocDate"$FocusDate" FocDateEnd"$FocusDateEnd 
					echo "DolSpentMo"$DollarsSpentMonth" PtsRedeemMo"$PointsRedeemed " PtsAccrMo"$PointsAccrued" VisAccrMo"$VisitsAccrued"DolSpentLife"$DollarsSpentLife
					echo "PAL"$PointsAccruedLife " VisAcrLife"$VisitsAccruedLife" PtsredeemedLife"$PointsRedeemedLife
					echo "LastVisitever"$MaxDate" CurrentFreqMo"$CurrentFreq" 12MO"$PrevYear" ProgAge"$ProgAge
					echo "================================="
					echo "RecentFrequency"$FreqRecent


					#UPDATE TABLE
					mysql  --login-path=local -DSRG_Dev -N -e "INSERT INTO Px_monthly SET CardNumber = '$CardNumber',
										FocusDate = '$FocusDate',
										FirstName = '${FirstName//\'/''}',
										LastName = '${LastName//\'/''}',
										EnrollDate = '$EnrollDate',
										Zip = '$Zip',
										DollarsSpentMonth = ROUND('$DollarsSpentMonth',2),
										PointsRedeemedMonth = '$PointsRedeemedMonth',
										PointsAccruedMonth = '$PointsAccruedMonth',
										VisitsAccruedMonth = '$VisitsAccruedMonth',
										LifetimeSpendBalance = ROUND('$DollarsSpentLife',2),
										LifetimePointsBalance = '$PointsAccruedLife',
										LifetimeVisitsBalance = '$VisitsAccruedLife',
										LifetimePointsRedeemed = '$PointsRedeemedLife',
										LastVisit = '$MaxDate',
										FreqCurrent = '$CurrentFreq',
										
										Freq12mos = '$PrevYear',
										ProgramAge = '$ProgAge'";
										# FreqRecent = '$FreqRecent',												


				done		 



		done
		FocusDate=$(date +%Y-%m-%d -d "$FocusDate + 1 Month")
		FocusDateEnd=$(date +%Y-%m-%d -d "$FocusDate + 1 Month - 1 day")
		FocusDateUnix=$(date +%s -d "$FocusDate")
		MinDateUnix=$(date +%s -d "$MinDate") 



	done
	done

done




echo Monthly Px Stats Updated

