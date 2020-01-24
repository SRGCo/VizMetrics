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



####### PX MONTHLY PART 1
( "/home/ubuntu/bin/DEV.Px.Monthly.part1.php" )
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'Part 1 of Px Monthly completed'

####### PX MONTHLY PART 2
( "/home/ubuntu/bin/DEV.Px.Monthly.part2.php" )
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'Part 2 of Px Monthly completed'

