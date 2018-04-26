#! //bin/bash
# LOG IT TO SYSLOG
exec 1> >(logger -s -t $(basename $0)) 2>&1

# UNCOMMENT NEXT FOR VERBOSE
# set -x
##### HALT AND CATCH FIRE IF ANY COMMANd FAILS
set -e

##### MYSQLDUMP SRG_Dev & SRG_Prod DATABASES
mysqldump -uroot -ps3r3n1t33 SRG_Dev > /home/ubuntu/db_files/SRG_Dev.bu.sql

mysqldump -uroot -ps3r3n1t33 SRG_Prod > /home/ubuntu/db_files/SRG_Prod.bu.sql
