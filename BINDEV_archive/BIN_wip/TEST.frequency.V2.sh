#! //bin/bash
# LOG IT TO SYSLOG



############################################################################################
################## FIX THIS SCRIPT SO IT DOES ITS WORK IN A NON PRODUCTION DIRECTORY !!!!!
############################################################################################
########## ADD ERROR HANDLING AT EACH FAIL POINT ###########################################


#exec 1> >(logger -s -t $(basename $0)) 2>&1

#UNCOMMENT NEXT FOR VERBOSE
# set -x
##### HALT AND CATCH FIRE AT SINGLE ITERATION LEVEL
set -e

#1.      Current Frequency (Current_freq): Today-Last visit date
#2.      Recent Frequency (Recent_freq): Last Visit Date-Previous visit date (2 visits back)
#3.      Previous Frequency: Previous visit date (2 visits back)- 3 visits back
#4.      12 Month Frequency (Year_freq): Count Visits over the previous 12 months
#5.      Lifetime Frequency (Life_freq): Count Visits since Enrollment date

########## ************** RUN AFTER px.ca.daily OTHERWISE SQUASHED TABLE WILL STILL BE OLD VER ******** ########
##### following to add freq fields 
mysql  --login-path=local -DSRG_px -N -e "ALTER TABLE CardActivity_squashed_test ADD Current_freq INT(6) NULL AFTER SVDiscountTrackingBalance, ADD Recent_freq INT(6) NULL AFTER Current_freq, ADD Previous_freq INT(6) NULL AFTER Recent_freq, ADD Year_freq INT(6) NULL AFTER Previous_freq, ADD Life_freq INT(6) NULL AFTER Year_freq"

###################### ************ INDEXES ON CARDNUMBER AND TRANSACTIONDATE ***************** ###############

## **** mysql  --login-path=local -DSRG_px -N -e "ALTER TABLE CardActivity_squashed_test ADD INDEX(TransactionDate)"

### **** mysql  --login-path=local -DSRG_px -N -e "ALTER TABLE CardActivity_squashed_test ADD INDEX(CardNumber)"

##################### ITERATE ON CardNumber TO CALCULATE VISIT FREQUENCIES
###### -N is the No Headers in Output option
###### -e is the 'read statement and quit'
mysql  --login-path=local -DSRG_px -N -e "SELECT CardNumber FROM CardActivity_squashed_test GROUP BY CardNumber HAVING COUNT(*) > 1 ORDER BY CardNumber ASC" | while read -r CardNumber;
do
	######## COUNT VISITS OVER PREVIOUS 12 MONTHS AND LIFETIME
	PrevYear=$(mysql  --login-path=local -DSRG_px -N -e "SELECT COUNT(DISTINCT(TransactionDate)) from CardActivity_squashed_test WHERE CardNumber = '$CardNumber' 
								AND VisitsAccrued = '1.0000' AND TransactionDate >= DATE_SUB(NOW(),INTERVAL 1 YEAR)")

	######## COUNT VISITS OVER PREVIOUS 12 MONTHS AND LIFETIME
	Lifetime=$(mysql  --login-path=local -DSRG_px -N -e "SELECT COUNT(DISTINCT(TransactionDate)) from CardActivity_squashed_test WHERE CardNumber = '$CardNumber' 
								AND VisitsAccrued = '1.0000'")
	##### GET MAX  TRANSACTIONDATE
	MaxDate=$(mysql  --login-path=local -DSRG_px -N -e "SELECT MAX(TransactionDate) from CardActivity_squashed_test WHERE CardNumber = '$CardNumber'")
		##### GET 2ND TO MAX TRANSACTIONDATE
		SecondMax=$(mysql  --login-path=local -DSRG_px -N -e "SELECT DISTINCT(TransactionDate) from CardActivity_squashed_test WHERE CardNumber = '$CardNumber' AND VisitsAccrued = '1.0000' ORDER BY TransactionDate DESC limit 1,1") 
		if [ -z "$SecondMax" ]
		then
			##### UPDATE ONLY FIRST FREQUENCIES
			mysql  --login-path=local -DSRG_px -N -e "UPDATE CardActivity_squashed_test SET Current_freq = DATEDIFF(NOW(), '$MaxDate'), Year_freq = '$PrevYear', Life_freq = '$Lifetime'  WHERE CardNumber = '$CardNumber'"
			echo $MaxDate $PrevYear, $Lifetime, Current updated $CardNumber
		else
			##### GET 3RD TO MAX TRANSACTIONDATE
			ThirdMax=$(mysql  --login-path=local -DSRG_px -N -e "SELECT DISTINCT(transactiondate) from CardActivity_squashed_test WHERE CardNumber = '$CardNumber' AND VisitsAccrued = '1.0000' ORDER BY TransactionDate DESC limit 2,1") 
			if [ -z "$ThirdMax" ]
			then
				##### UPDATE ONLY FIRST AND SECOND FREQUENCIES
				mysql  --login-path=local -DSRG_px -N -e "UPDATE CardActivity_squashed_test SET Current_freq = DATEDIFF(NOW(), '$MaxDate'), Recent_freq = DATEDIFF('$MaxDate', '$SecondMax'), Year_freq = '$PrevYear', Life_freq = '$Lifetime'  WHERE CardNumber = '$CardNumber'"
				echo $MaxDate, $SecondMax $PrevYear, $Lifetime, Current, Recent updated $CardNumber
			else
				##### UPDATE ALL FREQUENCIES
				mysql  --login-path=local -DSRG_px -N -e "UPDATE CardActivity_squashed_test SET Current_freq = DATEDIFF(NOW(), '$MaxDate'), Recent_freq = DATEDIFF('$MaxDate', '$SecondMax'), Previous_freq = DATEDIFF('$SecondMax', '$ThirdMax'), Year_freq = '$PrevYear', Life_freq = '$Lifetime'   WHERE CardNumber = '$CardNumber'"

				echo $MaxDate, $SecondMax, $ThirdMax, $PrevYear, $Lifetime, Current, Recent, previous updated $CardNumber
			fi
		fi
done



