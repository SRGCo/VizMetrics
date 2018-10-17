






#! //bin/bash
# LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# UNCOMMENT NEXT FOR VERBOSE
# set -x
##### HALT AND CATCH FIRE IF ANY COMMAND FAILS
# set -e

##### USE time command to calc runtime "time DEV.cd.ca.into.master.sh"

################# ERROR CATCHING ##########################
failfunction()
{
	local scriptname=$(basename -- "$0") 
	local returned_value=$1
	local lineno=$2
	local bash_error=$3

	if [ "$returned_value" != 0 ]
	then 
 		echo "$scriptname failed on $bash_error at line: $lineno"
        	mail -s "VizMetrics Server Alert"  it@serenitee.com <<< 'Script '"$scriptname"' failed on '"$bash_error"' at Line: '"$lineno"
        	exit
	fi
}





mysql  --login-path=local -DSRG_Prod -N -e "SELECT Master.TransactionDate FROM Master WHERE Master.TransactionDate IS NOT NULL 
				GROUP BY Master.TransactionDate ORDER BY Master.TransactionDate DESC" | while read -r TransactionDate;
do

		######## GET FY FOR THIS TransactionDate (DOB)
		FY=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT FY from Lunas WHERE DOB = '$TransactionDate'")

		######## GET FY FOR THIS TransactionDate (DOB)
		YLuna=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT YLuna from Lunas WHERE DOB = '$TransactionDate'")

		######## GET FY FOR THIS TransactionDate (DOB)
		Luna=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT Luna from Lunas WHERE DOB = '$TransactionDate'")

		######## IF VARIABLE HAS NO VALUE SET TO NULL
		if [ -z $Luna ] 
		then 
		Luna='0'
		fi

		##### UPDATE FISCAL YEAR FROM TRANSACTIONDATE
		mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET FY = '$FY',YLuna = '$YLuna', Luna='$Luna' WHERE Master.TransactionDate = '$TransactionDate'"
		#echo $TransactionDate updated FY= $FY YLuna = $YLuna  Luna = $Luna

done
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER FY YLUNA FIELDS UPATED WITH DATA FROM LUNA TABLE'

