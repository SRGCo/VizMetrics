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



## CHECKDETAIL ##### REMOVE DUPLICATE ROWS FROM CHECKDETAIL LIVE TABLE
mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP TABLE IF EXISTS Master_dedupe"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
mysql  --login-path=local --silent -DSRG_Dev -N -e "CREATE table Master_dedupe LIKE Master"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR



mysql  --login-path=local -DSRG_Dev -N -e "SELECT DISTINCT(POSkey) FROM Master ORDER BY POSkey ASC" | while read -r POSkey;
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
do
	echo $POSkey
	mysql  --login-path=local --silent -DSRG_Dev -N -e "INSERT INTO Master_dedupe SELECT * FROM Master WHERE POSkey = '$POSkey' LIMIT 1"
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
done
