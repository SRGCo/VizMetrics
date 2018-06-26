#! //bin/bash
# LOG IT TO SYSLOG
exec 1> >(logger -s -t $(basename $0)) 2>&1

# UNCOMMENT NEXT FOR VERBOSE
# set -x
##### HALT AND CATCH FIRE IF ANY COMMANd FAILS
set -e



######### UBER JOIN LIVE CHECK DETAIL WITH LIVE SQUASHED CARD ACTIVITY
mysql  --login-path=local -uroot -N -e "SELECT * INTO OUTFILE '/home/ubuntu/db_files/outfiles/px.monthly.V2.csv' FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' FROM SRG_Dev.Px_monthly"

echo 'Px_Monthly RAW DATA WRITTEN TO CSV /home/ubuntu/db_files/outfiles/px.monthly.V2.csv CREATED'


########### PREPEND HEADERS 
######## IF CAT FINISHES CORRECTLY DELETE THE FILE WO HEADERS
cat /home/ubuntu/db_files/headers/px.monthly.headers.csv /home/ubuntu/db_files/outfiles/px.monthly.V2.csv > /home/ubuntu/db_files/outfiles/px.monthly.V2.wheaders.csv && rm /home/ubuntu/db_files/outfiles/px.monthly.V2.csv
echo 'HEADERS ADDED, /home/ubuntu/db_files/headers/px.monthly.headers.csv CREATED, /home/ubuntu/db_files/outfiles/px.monthly.V2.csv DELETED'


#### REPLACE THE NEWLINE CHARS {\n} IN FILE 
sed 's#\\N##g' /home/ubuntu/db_files/outfiles/px.monthly.V2.wheaders.csv > /home/ubuntu/db_files/outfiles/px.monthly.V2.wheaders.clean.csv && rm /home/ubuntu/db_files/outfiles/px.monthly.V2.wheaders.csv
echo 'NEWLINE CHARACTERS STRIPPED' 
echo 'home/ubuntu/db_files/outfiles/px.monthly.V2.wheaders.clean.csv CREATED' 
echo '/home/ubuntu/db_files/outfiles/px.monthly.V2.wheaders.csv DELETED'

####
head -1000 /home/ubuntu/db_files/outfiles/px.monthly.V2.wheaders.clean.csv > /home/ubuntu/db_files/outfiles/px.monthly.V2.small.csv
echo 'small px monthlu created'


#### Turn both big and small files to dos
unix2dos -n /home/ubuntu/db_files/outfiles/px.monthly.V2.small.csv /home/ubuntu/db_files/outfiles/px.monthly.V2.small.dos.csv
unix2dos -n /home/ubuntu/db_files/outfiles/px.monthly.V2.wheaders.clean.csv /home/ubuntu/db_files/outfiles/px.monthly.V2.wheaders.clean.dos.csv
