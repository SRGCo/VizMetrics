#! /bin/bash


# UNCOMMENT TO LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# Next line turns echo on
set -x

##### CALC THE (non-dynamic) FREQUENCY FIELDS -FY Y-LUNA
##### FIRST 4 CHARS of TransactionDate BECOME FY
##################### ITERATE ON POSkey 
###### -N is the No Headers in Output option
###### -e is the 'read statement and quit'
mysql  --login-path=local -DSRG_Dev -N -e "SELECT Master.DOB FROM Master WHERE Master.DOB > '2017-12-30' GROUP BY Master.DOB ORDER BY Master.DOB ASC" | while read -r TransactionDate;
do
	######## GET FY FOR THIS TransactionDate (DOB)
	FY=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT FY from Lunas WHERE Lunas.DOB = '$TransactionDate'")

	######## GET YLUNA FOR THIS TransactionDate (DOB)
	YLuna=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT YLuna from Lunas WHERE Lunas.DOB = '$TransactionDate'")

	######## GET LUNA FOR THIS TransactionDate (DOB)
	Luna=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT Luna from Lunas WHERE Lunas.DOB = '$TransactionDate'")


			##### UPDATE FISCAL YEAR FROM TRANSACTIONDATE
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET FY = '$FY',YLuna = '$YLuna', Luna = '$Luna' WHERE Master.DOB = '$TransactionDate'"
			echo $TransactionDate updated FY= $FY YLuna = $YLuna Luna = $Luna
done
echo FY YLUNA CALCD POPULATED

