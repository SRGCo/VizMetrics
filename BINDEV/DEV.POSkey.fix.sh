#! //bin/bash
# LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# UNCOMMENT NEXT FOR VERBOSE
 set -x
##### HALT AND CATCH FIRE IF ANY COMMAND FAILS
# set -e


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

################################### DOING WORK IN DEV2 DATABASE ####################################

#ysql  --login-path=local -DSRG_dev2 -N -e "SELECT POSkey, COUNT(*) as HOWMANY FROM CardActivity_Live WHERE CardNumber IS NOT NULL group by POSkey HAVING HOWMANY > '1'" | while read -r POSkey HOWMANY;
#trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
#do

######################### only do stuff if variables aren't empty

######################### WHY DOESNT THIS WORK ? / ? ? ? ?

	echo $POSkey" "$HOWMANY 
	mysql  --login-path=local -DSRG_dev2 -N -e "SELECT DISTINCT(CardNumber) as CardNumber FROM CardActivity_Live WHERE POSkey = '0410590' AND CardNumber IS NOT NULL" | while read -r CardNumber;
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	do
		echo $CardNumber

		NewPOSkey=$POSkey$CardNumber
		echo  $NewPOSkey
	
		#### FIX IT IN CARD ACTIVITY
		mysql  --login-path=local --silent -DSRG_dev2 -N -e "UPDATE CardActivity_Live SET POSkey = '$NewPOSkey' WHERE POSkey = '$POSkey' AND CardNumber = '$CardNumber'"
		trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

		#### ADD A NEW RECORD FOR IT IN CHECKDETAIL
		mysql  --login-path=local --silent -DSRG_dev2 -N -e "INSERT INTO CheckDetail_Live SET POSkey = '$NewPOSkey'"
		trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	done

	##### GET RID OF THE (NOW SUPERFLOUS) ENTRY WITH ORIGINAL POSKEY IN CHECKDETAIL
	mysql  --login-path=local --silent -DSRG_dev2 -N -e "DELETE from CheckDetail_Live WHERE POSkey = '$POSkey'"
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	##### GET RID OF THE (NOW SUPERFLOUS) ENTRY WITH ORIGINAL POSKEY IN CARDACTIVITY
	mysql  --login-path=local --silent -DSRG_dev2 -N -e "DELETE from CardActivity_Live WHERE POSkey = '$POSkey'"
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


#done
