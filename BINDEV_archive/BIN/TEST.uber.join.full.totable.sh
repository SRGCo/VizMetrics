#! //bin/bash
# LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# UNCOMMENT NEXT FOR VERBOSE
set -x
##### HALT AND CATCH FIRE IF ANY COMMAND FAILS
set -e


######### UBER JOIN LIVE CHECK DETAIL WITH LIVE SQUASHED CARD ACTIVITY

#### Double check UNION !!!!!!!!!!!!!!!!

mysql  --login-path=local -uroot -N -e "INSERT INTO SRG_uber.Master_test SELECT CD.*, CA.* FROM SRG_checks.CheckDetail_Live AS CD LEFT JOIN SRG_px.CardActivity_squashed_test AS CA ON CD.POSkey = CA.POSkey UNION SELECT CD.*, CA.* FROM SRG_checks.CheckDetail_Live as CD RIGHT JOIN SRG_px.CardActivity_squashed_test AS CA ON CD.POSkey = CA.POSkey"
# echo 'UBER JOIN COMPLETED, /outfiles/joined.cd.ca.csv CREATED'
echo 'Uber join data inserted into Master_test'





########### PREPEND HEADERS TO UBER JOIN
######## IF CAT FINISHES CORRECTLY DELETE THE FILE WO HEADERS
# cat /home/ubuntu/db_files/headers/uber.join.headers.csv /home/ubuntu/db_files/outfiles/joined.cd.ca.csv > /home/ubuntu/db_files/outfiles/uber.join.wheaders.csv && rm /home/ubuntu/db_files/outfiles/joined.cd.ca.csv
# echo 'HEADERS ADDED, /outfiles/uber.join.wheaders.csv CREATED, joined.cd.ca.csv DELETED'


#### REPLACE THE NEWLINE CHARS {\n} IN FILE 
# sed 's#\\N##g' /home/ubuntu/db_files/outfiles/uber.join.wheaders.csv > /home/ubuntu/db_files/outfiles/uber.join.clean.wheaders.csv && rm /home/ubuntu/db_files/outfiles/uber.join.wheaders.csv
# echo 'NEWLINE CHARACTERS STRIPPED, /outfiles/uber.join.clean.wheaders.csv CREATED, uber.join.wheaders DELETED'
# echo '/home/ubuntu/db_files/outfiles/uber.join.clean.wheaders.csv READY.'

eof

