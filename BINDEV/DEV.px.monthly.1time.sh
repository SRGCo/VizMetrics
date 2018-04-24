#! //bin/bash
# NEXT for echo
# set -x

mysql  --login-path=local -DSRG_Dev -N -e "SELECT DISTINCT(CardNumber), MAX(Vm_Visitbalance)
					FROM Master_test	
					ORDER BY CardNumber ASC" | while read -r CardNumber VisitBalance;
do

	##### WE WILL ITERATE EACH CARD UP UNTIL MOST RECENT FOCUSDATE (FOCUSDATE CLOSEST TO CURDATE)
	TodayDate=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT CURDATE() as date FROM Master_test LIMIT 1")
	TodayDateUnix=$(date +%s -d "$TodayDate") 

	MaxDate=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(TransactionDate) FROM Master_test WHERE CardNumber = '$CardNumber'")
	MaxDateUnix=$(date +%s -d "$MaxDate") 
	MinDate=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MIN(TransactionDate) FROM Master_test WHERE CardNumber = '$CardNumber'")

	MinDateUnix=$(date +%s -d "$MinDate") 
	FocusDate=$(date +%Y-%m-01 -d "$MinDate")
	FocusDateUnix=$(date +%s -d "$FocusDate")
	FocusDateEnd=$(date +%Y-%m-%d -d "$FocusDate + 1 Month -1 day")
	FocusDateEndUnix=$(date +%s -d "$FocusDateEnd") 

	############### already in monthly
	PrevYear=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT COUNT(TransactionDate) FROM Master_test 
					WHERE CardNumber = '$CardNumber' 
					AND TransactionDate >= DATE_SUB('$FocusDate',INTERVAL 1 YEAR) 
					AND TransactionDate < '$FocusDate'																	
					AND VisitsAccrued > '0'")

	##### 
	ProgAge=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT (PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM '$FocusDate'), EXTRACT(YEAR_MONTH FROM '$EnrollDate')) + 1) AS months 
								FROM Master_test
								WHERE CardNumber = '$CardNumber' LIMIT 1")	




	######## GET ENROLL DATE
	EnrollDate=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT EnrollDate FROM Guests WHERE CardNumber = '$CardNumber' LIMIT 1")

	while [ $FocusDateUnix -le $TodayDateUnix ]
	do	
	##### GET 2ND TO MAX TRANSACTIONDATE back from focusdate
	RecentFreq=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT TransactionDate from Master_test WHERE CardNumber = '$CardNumber' AND VisitsAccrued > '0'
									 AND TransactionDate < '$FocusDate'
									ORDER BY TransactionDate DESC limit 1,1") 
	##### IF SECONDMAX IS NULL / EMPTY THEN FreqRecent = 0
	if [ -z "$RecentFreq" ]
		then
			RecentFreq='0'
		fi
	##### Visit count since enroll date {at FocusDate}
	LifeFreq=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT COUNT(TransactionDate) from Master_test WHERE CardNumber = '$CardNumber' AND VisitsAccrued > '0'
								 AND TransactionDate < '$FocusDate'") 
	
	##### LIFETIME FREQ SEGMENTED
	LifeFreqSeg="$(($LifeFreq / $ProgAge))"

	##### 12MO FREQ SEGMENTED
	YearFreqSeg="$(($PrevYear / $ProgAge))"







####### UPDATE TABLE
	###### UPDATE TABLE THIS ONE TIME SCRIPT UPDATES NOT INSERTS
	mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Px_monthly SET FreqRecent = DATEDIFF('$MaxDate', '$RecentFreq'),
									LifetimeFrequency = '$LifeFreq',
									LifetimeFreqSeg = '$LifeFreqSeg',
									12MoFreqSeg = '$YearFreqSeg',
									VisitBalance =  '$VisitBalance'
									WHERE CardNumber = '$CardNumber'
									AND FocusDate = '$FocusDate'"

	echo "CardNumber"$CardNumber" EnrDate"$EnrollDate" FDate"$FocusDate" FreqCur"$CurrentFreq" 12mo"$PrevYear" Progage"$ProgAge 
###################### WILL WE NEED SECONDARY CALCS WITH ALL VALUES FROM REAL MONTHLY? ###########
###################### OR CAN WE DO THESE IN FIRST ROUND OF CALCS ABOVE IN PX MONTHLY ##############
	####### DO SECONDARY CALCULATIONS
	##### 12MO FREQ SEGMENTED
	##### Visit count since enroll date {at FocusDate}
	FreqRecent=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT FreqRecent from Px_monthly WHERE CardNumber = '$CardNumber'
								 AND FocusDate '$FocusDate'") 
	### RECENT FREQUENCY IN MONTHS NOT DAYS
	RecentFreqSeg="$(($FreqRecent / 30))"

	##### Visit count since enroll date {at FocusDate}
	FreqCurrent=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT FreqCurrent from Px_monthly WHERE CardNumber = '$CardNumber'
								 AND FocusDate '$FocusDate'") 
	### RECENT FREQUENCY IN MONTHS NOT DAYS
	CurrentFreqSeg="$(($FreqRecent / 30))"


####### UPDATE TABLE AFTER SECONDARY CALCULATIONS
	###### UPDATE TABLE THIS ONE TIME SCRIPT UPDATES NOT INSERTS
	mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Px_monthly SET RecentFreqSeg = '$RecentFreqSeg,
									CurFreqSeg = '$CurrentFreqSeg'
									WHERE CardNumber = '$CardNumber'
									AND FocusDate = '$FocusDate'"

	# ITERATE TO NEXT FOCUSDATE
	FocusDate=$(date +%Y-%m-%d -d "$FocusDate + 1 Month")
	FocusDateEnd=$(date +%Y-%m-%d -d "$FocusDate + 1 Month - 1 day")
	FocusDateUnix=$(date +%s -d "$FocusDate")
	MinDateUnix=$(date +%s -d "$MinDate") 

	done
done
