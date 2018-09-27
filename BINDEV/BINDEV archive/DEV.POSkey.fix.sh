#! //bin/bash
# LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# UNCOMMENT NEXT FOR VERBOSE
# set -x
##### HALT AND CATCH FIRE IF ANY COMMAND FAILS
set -e


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

mysql  --login-path=local -DSRG_dev2 -N -e "SELECT POSkey, COUNT(*) as HOWMANY FROM CardActivity_squashed_2 WHERE CardNumber IS NOT NULL AND POSkey is NOT NULL group by POSkey HAVING HOWMANY > '1'" | while read -r POSkey;
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
do

 
	mysql  --login-path=local -DSRG_dev2 -N -e "SELECT CardNumber, RIGHT(CardNumber, 6) FROM CardActivity_squashed_2 WHERE POSkey = '$POSkey' 
						AND CardNumber IS NOT NULL ORDER BY CardNumber ASC" | while read -r CardNumber Lastsix;
	do

		NewPOSkey=$POSkey$Lastsix
	
		#### FIX IT IN CARD ACTIVITY
		mysql  --login-path=local --silent -DSRG_dev2 -N -e "UPDATE CardActivity_squashed_2 SET POSkey = '$NewPOSkey' WHERE POSkey = '$POSkey' AND CardNumber = '$CardNumber'"
		trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

		#### ADD A NEW RECORD FOR IT IN CHECKDETAIL
		mysql  --login-path=local --silent -DSRG_dev2 -N -e "INSERT INTO CheckDetail_Live SET POSkey = '$NewPOSkey'"
		trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	
		echo "Card: " $CardNumber" Old POSKEY:"$POSkey" New:"$NewPOSkey" Updated CA, created new record CD"


	done

	##### GET RID OF THE (NOW SUPERFLOUS) ENTRY WITH ORIGINAL POSKEY IN CHECKDETAIL
	mysql  --login-path=local --silent -DSRG_dev2 -N -e "DELETE from CheckDetail_Live WHERE POSkey = '$POSkey'"
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	echo "Deleted original POSkey Entries "$POSkey" from CD"

	##### GET RID OF THE (NOW SUPERFLOUS) ENTRY WITH ORIGINAL POSKEY IN CARDACTIVITY
	mysql  --login-path=local --silent -DSRG_dev2 -N -e "DELETE from CardActivity_squashed_2 WHERE POSkey = '$POSkey'"
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	echo "Deleted original POSkey Entries "$POSkey" from CA"

done

echo "Complete"

