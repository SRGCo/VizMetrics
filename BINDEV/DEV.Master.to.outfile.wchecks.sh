#! //bin/bash
# LOG IT TO SYSLOG
exec 1> >(logger -s -t $(basename $0)) 2>&1

# UNCOMMENT NEXT FOR VERBOSE
# set -x
##### HALT AND CATCH FIRE IF ANY COMMANd FAILS
set -e



######### UBER JOIN LIVE CHECK DETAIL WITH LIVE SQUASHED CARD ACTIVITY
mysql  --login-path=local -uroot  -DSRG_Dev -N -e "SELECT * INTO OUTFILE '/home/ubuntu/db_files/outfiles/joined.cd.ca.csv' FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' FROM Master 
					WHERE (Master.Account_status <> 'TERMIN' 
					AND Master.Account_status <> 'SUSPEN' 
					AND Master.Account_status <> 'Exchanged'
					AND Master.Account_status <> 'Exchange' 
					AND Master.Account_status <> 'Exclude') OR (Account_status IS NULL)"

echo 'UBER JOIN COMPLETED, ACTIVE PX ACCOUNTS ONLY /outfiles/joined.cd.ca.csv CREATED'

######## Better File names !!!


########### PREPEND HEADERS TO UBER JOIN
######## IF CAT FINISHES CORRECTLY DELETE THE FILE WO HEADERS
cat /home/ubuntu/db_files/headers/uber.join.headers.V2.csv /home/ubuntu/db_files/outfiles/joined.cd.ca.csv > /home/ubuntu/db_files/outfiles/uber.join.wheaders.csv && rm /home/ubuntu/db_files/outfiles/joined.cd.ca.csv
echo 'HEADERS ADDED, /outfiles/uber.join.wheaders.csv CREATED, joined.cd.ca.csv DELETED'


#### REPLACE THE NEWLINE CHARS {\n} IN FILE 
sed 's#\\N##g' /home/ubuntu/db_files/outfiles/uber.join.wheaders.csv > /home/ubuntu/db_files/outfiles/uber.join.clean.wheaders.csv && rm /home/ubuntu/db_files/outfiles/uber.join.wheaders.csv
echo 'NEWLINE CHARACTERS STRIPPED, /outfiles/uber.join.clean.wheaders.csv CREATED, uber.join.wheaders DELETED'
echo '/home/ubuntu/db_files/outfiles/uber.join.clean.wheaders.csv READY.'

####
head -300 /home/ubuntu/db_files/outfiles/uber.join.clean.wheaders.csv > /home/ubuntu/db_files/outfiles/small.uber.csv
echo small uber created


