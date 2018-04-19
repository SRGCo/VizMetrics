#! //bin/bash
# NEXT for echo
# set -x

mysql  --login-path=local -DSRG_Dev -N -e "SELECT DISTINCT(CardNumber)
					FROM Master_test	
					ORDER BY CardNumber ASC" | while read -r CardNumber;
do
	MaxDate=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(TransactionDate) FROM Master_test WHERE CardNumber = '$CardNumber'")
	MaxDateUnix=$(date +%s -d "$MaxDate") 
	MinDate=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MIN(TransactionDate) FROM Master_test WHERE CardNumber = '$CardNumber'")

	MinDateUnix=$(date +%s -d "$MinDate") 
	FocusDate=$(date +%Y-%m-01 -d "$MinDate")
	FocusDateUnix=$(date +%s -d "$FocusDate")
	FocusDateEnd=$(date +%Y-%m-%d -d "$FocusDate + 1 Month -1 day")
	FocusDateEndUnix=$(date +%s -d "$FocusDateEnd") 
	######## GET ENROLL DATE
	EnrollDate=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT EnrollDate FROM Guests WHERE CardNumber = '$CardNumber' LIMIT 1")


	while [ $FocusDateUnix -le $MaxDateUnix ]
		do	
		######## VISITS ACCRUED 12 MONTHS PREVIOUS TO FOCUSDATE
		PrevYear=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT COUNT(TransactionDate) FROM Master_test 
								WHERE CardNumber = '$CardNumber' 
								AND TransactionDate >= DATE_SUB('$FocusDate',INTERVAL 1 YEAR) 
								AND TransactionDate < '$FocusDate'																		
								AND VisitsAccrued > '0'")

		##### GET CURRENT FREQ AS OF FOCUS DATE
		CurrentFreq=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT DATEDIFF('$FocusDate' ,MAX(TRANSACTIONDATE)) FROM Master_test
						           	WHERE TransactionDate < '$FocusDate' 
								AND CardNumber = '$CardNumber' 
								AND VisitsAccrued > '0'")

		##### GET CURRENT FREQ AS OF FOCUS DATE PLUS 1 FOR MM CALCS
		ProgAge=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT (PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM '$FocusDate'), EXTRACT(YEAR_MONTH FROM '$EnrollDate')) + 1) AS months 
									FROM Master_test
									WHERE CardNumber = '$CardNumber' LIMIT 1")


	###### UPDATE TABLE THIS ONE TIME SCRIPT UPDATES NOT INSERTS
	mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Px_monthly SET FreqCurrent = '$CurrentFreq',
								Freq12mos = '$PrevYear',
								ProgramAge = '$ProgAge'
								WHERE CardNumber = '$CardNumber'
								AND FocusDate = '$FocusDate'"

	echo "CardNumber"$CardNumber" EnrDate"$EnrollDate" FDate"$FocusDate" FreqCur"$CurrentFreq" 12mo"$PrevYear" Progage"$ProgAge 

	# ITERATE TO NEXT FOCUSDATE
	FocusDate=$(date +%Y-%m-%d -d "$FocusDate + 1 Month")
	FocusDateEnd=$(date +%Y-%m-%d -d "$FocusDate + 1 Month - 1 day")
	FocusDateUnix=$(date +%s -d "$FocusDate")
	MinDateUnix=$(date +%s -d "$MinDate") 


	done

done
