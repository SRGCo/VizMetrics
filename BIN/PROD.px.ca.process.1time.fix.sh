#! //bin/bash
# LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# THIS SCRIPT HAS TO RUN AFTER CHECKDETAIL IS PROCESSED SO THAT THE CHECK NUMBER FIX RUNS CORRECTLY

# UNCOMMENT NEXT FOR VERBOSE
# set -x



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


### IF THE FOLLOWING FTPS FAIL WE KEEP GOING
set +e

###### CALL THE FTP CRON JOBS
###### FIRST WE GET THE FILES FROM PX
( "/home/ubuntu/bin/CRON.sftp.px.daily.get.sh" )
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
 sleep 5s

###### THEN BERTHA AND MARKETING VITALS GET A COPY
( "/home/ubuntu/bin/CRON.ftp.mv.daily.put.sh" )
## IF WE ERROR TRAP HERE AND MV FAILS WHOLE SCRIPT BLOWS OUT
## trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
sleep 5s

