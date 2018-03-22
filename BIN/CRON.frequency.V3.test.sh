#! //bin/bash
# HAVE OUTPUT SO CRON EMAILS RESULTS
# set -x



############################################################################################
################## THIS SCRIPT SHOULD DO FILE HANDLING IN A NON PRODUCTION DIRECTORY !!!!!
############################################################################################
########## ADD ERROR HANDLING AT EACH FAIL POINT ###########################################


#exec 1> >(logger -s -t $(basename $0)) 2>&1

##### HALT AND CATCH FIRE AT SINGLE ITERATION LEVEL
set -e

######### THESE ARE THE FIELDS WE WILL CALCULATE EVERY DAY #################################
#1.	 Historical Current Frequency (Hist_current_freq): Transaction Date (DOB) - Last visit date
#2.      Current Frequency (Current_freq): Today-Last visit date
#3.      Recent Frequency (Recent_freq): Last Visit Date-Previous visit date (2 visits back)
#4.      Previous Frequency: Previous visit date (2 visits back)- 3 visits back
#5.      12 Month Frequency (Year_freq): Count Visits over the previous 12 months
#6.      Lifetime Frequency (Life_freq): Count Visits since Enrollment date


##################### ITERATE ON CardNumber TO CALCULATE VISIT FREQUENCIES
###### -N is the No Headers in Output option
###### -e is the 'read statement and quit'


####### THESE NEED TO CALC OFF Vm_VisitsAccrued !!!!!!!!!!!!!!!!!!!!!!!!!!!!! ###########################

mysql  --login-path=local -DSRG_Dev -N -e "SELECT CardNumber FROM Master_test2 GROUP BY CardNumber HAVING COUNT(*) > 1 ORDER BY CardNumber ASC" | while read -r CardNumber;
do
	echo $CardNumber
	######## COUNT VISITS OVER PREVIOUS 12 MONTHS AND LIFETIME
	PrevYear=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT COUNT(DISTINCT(TransactionDate)) from Master_test2 WHERE CardNumber = '$CardNumber' 
								AND Vm_VisitsAccrued = '1.0000' AND TransactionDate >= DATE_SUB(NOW(),INTERVAL 1 YEAR)")

	######## COUNT VISITS OVER PREVIOUS 12 MONTHS AND LIFETIME
	Lifetime=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT COUNT(DISTINCT(TransactionDate)) from Master_test2 WHERE CardNumber = '$CardNumber' 
								AND Vm_VisitsAccrued = '1.0000'")
	##### GET MAX  TRANSACTIONDATE
	MaxDate=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(TransactionDate) from Master_test2 WHERE CardNumber = '$CardNumber'")
		##### GET 2ND TO MAX TRANSACTIONDATE
		SecondMax=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT DISTINCT(TransactionDate) from Master_test2 WHERE CardNumber = '$CardNumber' AND Vm_VisitsAccrued = '1.0000' ORDER BY TransactionDate DESC limit 1,1") 
		##### IF SECONDMAX IS NULL / EMPTY
		##### IF WE ARE ONLY GRABBING WHERE THERE IS MORE THAN ONE ENTRY **WHY** ARE ANY SECONDMAX's NULL ?!?!?!
		if [ -z "$SecondMax" ]
		then

			##### UPDATE ONLY FIRST FREQUENCIES
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test2 SET FreqCurrent = DATEDIFF(NOW(), '$MaxDate'), Freq12mos = '$PrevYear', FreqLifetime = '$Lifetime'  WHERE CardNumber = '$CardNumber'"
			# echo $MaxDate $PrevYear, $Lifetime, Current updated $CardNumber
		
		##### IF SECONDMAX HAS A VALUE
		else
			##### GET 3RD TO MAX TRANSACTIONDATE
			ThirdMax=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT DISTINCT(transactiondate) from Master_test2 WHERE CardNumber = '$CardNumber' AND Vm_VisitsAccrued = '1.0000' ORDER BY TransactionDate DESC limit 2,1") 
			##### IF THIRDMAX IS NULL / EMPTY
			if [ -z "$ThirdMax" ]
			then
				##### UPDATE ONLY FIRST AND SECOND FREQUENCIES
				mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test2 SET FreqCurrent = DATEDIFF(NOW(), '$MaxDate'), FreqRecent = DATEDIFF('$MaxDate', '$SecondMax'), Freq12mos = '$PrevYear', FreqLifetime = '$Lifetime'  WHERE CardNumber = '$CardNumber'"
				# echo $MaxDate, $SecondMax $PrevYear, $Lifetime, Current, Recent updated $CardNumber

			##### IF THIRDMAX HAS A VALUE
			else
				##### UPDATE ALL FREQUENCIES
				mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test2 SET FreqCurrent = DATEDIFF(NOW(), '$MaxDate'), FreqRecent = DATEDIFF('$MaxDate', '$SecondMax'), FreqPrevious = DATEDIFF('$SecondMax', '$ThirdMax'), Freq12mos = '$PrevYear', FreqLifetime = '$Lifetime'   WHERE CardNumber = '$CardNumber'"

				# echo $MaxDate, $SecondMax, $ThirdMax, $PrevYear, $Lifetime, Current, Recent, previous updated $CardNumber
			fi
		fi



	##################### ITERATE ON RECORDID FOR HISTORICAL CURRENT FREQUENCIES
	###### -N is the No Headers in Output option
	###### -e is the 'read statement and quit'
#	mysql  --login-path=local -DSRG_Dev -N -e "SELECT record_id, transactiondate FROM Master_test2 ORDER BY record_id ASC" | while read -r recordid, transactiondate ;
#	do
#		##### UPDATE HISTORICAL CURRENT FREQUENCIES
#		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test2 SET Hist_current_freq = ('$transactiondate' - '$MaxDate') WHERE recordid = '$recordid'"
#		echo $transactiondate $MaxDate $recordid UPDATED
#	done

done



echo Frequencies Updated

