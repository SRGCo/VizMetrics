#! //bin/bash
# LOG IT TO SYSLOG
########## ADD ERROR HANDLING AT EACH FAIL POINT ###########################################

# exec 1> >(logger -s -t $(basename $0)) 2>&1


#UNCOMMENT NEXT FOR VERBOSE
set -x
##### HALT AND CATCH FIRE IF ANY COMMANd FAILS
set -e

###### -N is the No Headers in Output option
###### -e is the 'read statement and quit'
###### { encapulates the while loop so variables do not disappear

### what if more than one transaction per day


#mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET GrossSalesCoDefined = DollarsSpentAccrued WHERE GrossSalesCoDefined IS NULL"


mysql  --login-path=local  -uroot -DSRG_Dev -N -e "SELECT DISTINCT(DollarsSpentAccrued) INTO OUTFILE '/home/ubuntu/db_files/outfiles/dollars.csv'  FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' FROM Master_test" 

