#! //bin/bash
# LOG IT TO SYSLOG
exec 1> >(logger -s -t $(basename $0)) 2>&1

# UNCOMMENT NEXT FOR VERBOSE
# set -x
##### HALT AND CATCH FIRE IF ANY COMMANd FAILS
set -e



######### UBER JOIN LIVE CHECK DETAIL WITH LIVE SQUASHED CARD ACTIVITY
mysql  --login-path=local -uroot -N -e "SELECT * INTO OUTFILE '/home/ubuntu/db_files/outfiles/joined.cd.ca.csv' FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' FROM SRG_Dev.Master_test  
					WHERE SRG_Dev.Master_test.Account_status <> 'TERMIN' 
					AND SRG_Dev.Master_test.Account_status <> 'SUSPEN' 
					AND SRG_Dev.Master_test.Account_status <> 'Exchanged'
					AND SRG_Dev.Master_test.Account_status <> 'Exchange' 
					AND SRG_Dev.Master_test.Account_status <> 'Exclude'"

echo 'UBER JOIN COMPLETED, ACTIVE PX ACCOUNTS ONLY /outfiles/joined.cd.ca.csv CREATED'


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



