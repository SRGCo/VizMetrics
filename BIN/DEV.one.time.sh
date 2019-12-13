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

########### UPDATE THE CardActivitylive table
mysql  --login-path=local --silent -DSRG_Dev -N -e "INSERT INTO CardActivity_Live SELECT * FROM CardActivity_Temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'CARD ACTIVITY LIVE TABLE UPDATED WITH CARD ACTIVITY TEMP DATA'

echo 'DEV.PX.CA.PROCESS.SH COMPLETED'


###### PROCESS THE CA_Live TABLE INTO FIRST USE TABLE
( "/home/ubuntu/bin/DEV.app.use.firstserver.php" )
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'DEV App_use1 Table populated with new data'

