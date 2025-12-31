#!/bin/bash
#echo on
# set -x



############################# GET CTUIT FILES FROM BERTHA THEN BACK THEM UP ON BERTHA ###################
lftp -e 'set net:timeout 10;set ssl:verify-certificate no; set ftp:ssl-protect-data true;' -u VM_ctuit,Serenitee185Ctuit 50.195.41.122  << EOF
	lcd /home/ubuntu/db_files/incoming/ctuit
	mget *
	mirror --reverse --no-recursion /home/ubuntu/db_files/incoming/ctuit /backup
	mrm *csv
bye
EOF

echo 'CTUIT FTP SUBROUTINE RAN WITH EXIT CODE OF: '$?

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
# trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

