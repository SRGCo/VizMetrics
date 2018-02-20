#! //bin/bash
# LOG IT TO SYSLOG

############################################################################################
################## FIX THIS SCRIPT SO IT DOES ITS WORK IN A NON PRODUCTION DIRECTORY !!!!!
############################################################################################
########## ADD ERROR HANDLING AT EACH FAIL POINT ###########################################




exec 1> >(logger -s -t $(basename $0)) 2>&1

#UNCOMMENT NEXT FOR VERBOSE
# set -x
##### HALT AND CATCH FIRE IF ANY COMMAND FAILS
set -e

#1.      Current Frequency: Today-Last visit date
#2.      Recent Frequency: Last Visit Date-Previous visit date (2 visits back)
#3.      Previous Frequency: Previous visit date (2 visits back)- 3 visits back
#4.      12 Month Frequency: Count Visits over the previous 12 months
#5.      Lifetime Frequency: Count Visits since Enrollment date

##################### ITERATE TO CALCULATE VISIT FREQUENCIES
###### -N is the No Headers in Output option
###### -e is the 'read statement and quit'
mysql  --login-path=local --silent -DSRG_px -N -e "SELECT CardNumber FROM CardActivity_squashed HAVING COUNT(*) > 1'" | while read -r CardNumber;
do
	##### GET MAX  TRANSACTIONDATE
	mysql  --login-path=local --silent -DSRG_px -N -e "SELECT MAX(transactiondate) from CardActivity_squashed WHERE CardNumber = '$CardNumber'" | while read -r MaxDate;
	do
		##### GET 2ND TO MAX TRANSACTIONDATE (limit 2,1 = 1 entry starting at 2nd)
		mysql  --login-path=local --silent -DSRG_px -N -e "SELECT transactiondate from CardActivity_squashed WHERE CardNumber = '$CardNumber' limit 2,1" | while read -r SecondMax;
		do
			##### GET 3RD TO MAX TRANSACTIONDATE (limit 3,1 = 1 entry starting at 3rd)
			mysql  --login-path=local --silent -DSRG_px -N -e "SELECT transactiondate from CardActivity_squashed WHERE CardNumber = '$CardNumber' limit 3,1" | while read -r ThirdMax;
			do
				##### UPDATE FREQUENCIES
				mysql  --login-path=local --silent -DSRG_px -N -e "UPDATE CardActivity_squashed SET Current_freq = DATEDIFF(NOW(), '$MaxDate'), Recent_freq = DATEDIFF('$MaxDate', '$SecondMax), Previous_freq = DATEDIFF('$SecondMax, $ThirdMax)  WHERE CardNumber = '$CardNumber'"
				echo '$MaxDate', '$SecondMax', '$ThirdMax'
			done
		done
	done
	########### UPDATE COUNT OVER LAST 12 MONTHS AND TOTAL LIFETIME VISITS
done
echo 'FIXED PX CHECKNUMBERS MISSING 100'
echo '+++ DROPPING INDEXED PRIMARY KEY'





SELECT count(*), CardNumber FROM CardActivity_squashed GROUP BY CardNumber HAVING COUNT(*) > 1
while


####CURRENT FREQUENCY
SELECT ALL CARD NUMBERS > 1 entry in CardActivity_Squashed
SELECT ALL DATES FOR THESE CARDNUMBERS
while do
DATEDIFF (MAX(transactiondate), NOW()) as Current Frequency

#### 2 visits back
SELECT TRANSACTIONDATE where cardnumber = {cardnumber}, limit 3,1
DATEDIFF (MAX(transactiondate)
