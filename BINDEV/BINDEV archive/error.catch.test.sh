#! /bin/bash
### OK 7-23-18 #####

# UNCOMMENT TO LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# Next line turns echo on
set -x


################# ERROR CATCHING ##########################
################# ERROR CATCHING ##########################
failfunction()
{
    if [ "$1" != 0 ]
    then 
	 SCRIPTNAME=$(basename -- "$0") 
	 echo "$SCRIPTNAME failed at line: $LINENO"
         mail -s "VizMetrics Server Alert"  it@serenitee.com <<< 'Script '"$SCRIPTNAME"' failed at Line: '"$LINENO"
         exit
    fi
}


### RENAME A FILE
mv /home/ubuntu/test/testfile /home/ubuntu/test/testfilenew
failfunction "$?"

echo "this script did not fail"

