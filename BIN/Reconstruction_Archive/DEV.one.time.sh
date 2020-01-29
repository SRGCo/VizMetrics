#! //bin/bash
# LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# THIS SCRIPT HAS TO RUN AFTER CHECKDETAIL IS PROCESSED SO THAT THE CHECK NUMBER FIX RUNS CORRECTLY

# UNCOMMENT NEXT FOR VERBOSE
#set -x


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


##### HALT AND CATCH FIRE IF ANY COMMAND FAILS FROM HERE ON
set -e
mysql  --login-path=local -DSRG_Prod -N -e "SELECT Master.DOB FROM Master WHERE Master.DOB IS NOT NULL GROUP BY Master.DOB ORDER BY Master.DOB DESC" | while read -r DOB;
do

		######## GET FY FOR THIS DOB (DOB)
		FY=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT FY from Lunas WHERE DOB = '$DOB'")

		######## GET FY FOR THIS DOB (DOB)
		YLuna=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT YLuna from Lunas WHERE DOB = '$DOB'")

		######## GET FY FOR THIS DOB (DOB)
		Luna=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT Luna from Lunas WHERE DOB = '$DOB'")

		######## IF VARIABLE HAS NO VALUE SET TO NULL
		if [ -z $Luna ] 
		then 
		Luna='0'
		fi

		##### UPDATE FISCAL YEAR FROM DOB
		mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET FY = '$FY',YLuna = '$YLuna', Luna='$Luna' WHERE Master.DOB = '$DOB'"
		#echo $DOB updated FY= $FY YLuna = $YLuna  Luna = $Luna

done
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER FY YLUNA FIELDS UPATED WITH DATA FROM LUNA TABLE'

