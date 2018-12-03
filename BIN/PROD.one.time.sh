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


##### ADD INCOMING CHECK DETAIL DATA TO LIVE TABLE
mysql  --login-path=local --silent -DSRG_Prod -N -e "INSERT INTO CheckDetail_Live SELECT * FROM CheckDetail_Temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

## CHECKDETAIL ##### REMOVE DUPLICATE ROWS FROM CHECKDETAIL LIVE TABLE
mysql  --login-path=local --silent -DSRG_Prod -N -e "DROP TABLE IF EXISTS CheckDetail_Live_temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
mysql  --login-path=local --silent -DSRG_Prod -N -e "CREATE table CheckDetail_Live_temp LIKE CheckDetail_Live"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
mysql  --login-path=local --silent -DSRG_Prod -N -e "INSERT INTO CheckDetail_Live_temp SELECT * FROM CheckDetail_Live GROUP BY POSkey"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
mysql  --login-path=local --silent -DSRG_Prod -N -e "DROP table CheckDetail_Live"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
mysql  --login-path=local --silent -DSRG_Prod -N -e "RENAME table CheckDetail_Live_temp TO CheckDetail_Live"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


echo '======================================================'
echo 'CHECKDETAIL LIVE TABLE POPULATED WITH MOST RECENT DATA DEDUPED USING POSKEY GROUPED'

