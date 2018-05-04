#! //bin/bash
# LOG IT TO SYSLOG
exec 1> >(logger -s -t $(basename $0)) 2>&1

# UNCOMMENT NEXT FOR VERBOSE
# set -x
##### HALT AND CATCH FIRE IF ANY COMMANd FAILS
set -e



######### Master Export
mysql  --login-path=local -uroot  -DSRG_Dev -N -e "SELECT * INTO OUTFILE '/home/ubuntu/db_files/outfiles/master.pre.outfile.csv' FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' FROM Master 
					WHERE (Master.Account_status <> 'TERMIN' 
					AND Master.Account_status <> 'SUSPEN' 
					AND Master.Account_status <> 'Exchanged'
					AND Master.Account_status <> 'Exchange' 
					AND Master.Account_status <> 'Exclude') OR (Account_status IS NULL)"

echo 'Master table raw export COMPLETED'
echo 'Active PX accounts only'
echo 'outfiles/master.pre.outfile.csv CREATED'

########### PREPEND HEADERS
######## IF CAT FINISHES CORRECTLY DELETE THE FILE WO HEADERS
cat /home/ubuntu/db_files/headers/headers.master.csv /home/ubuntu/db_files/outfiles/master.pre.outfile.csv > /home/ubuntu/db_files/outfiles/master.outfile.csv && rm /home/ubuntu/db_files/outfiles/master.pre.outfile.csv
echo 'HEADERS ADDED, /outfiles/master.pre.outfile.csv CREATED, master.pre.outfile.csv DELETED'


#### REPLACE THE NEWLINE CHARS {\n} IN FILE 
sed 's#\\N##g' /home/ubuntu/db_files/outfiles/master.outfile.csv > /home/ubuntu/db_files/outfiles/master.csv && rm /home/ubuntu/db_files/outfiles/master.outfile.csv
echo 'NEWLINE CHARACTERS STRIPPED, /outfiles/master.csv CREATED, master.outfile.csv DELETED'
echo '/home/ubuntu/db_files/outfiles/uber.join.clean.wheaders.csv READY.'

####
head -300 /home/ubuntu/db_files/outfiles/master.csv > /home/ubuntu/db_files/outfiles/small.master.csv
echo 'Small master.csv created'


