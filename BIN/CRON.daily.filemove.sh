#!/bin/bash
#echo on
# set -x

### IF THE FOLLOWING FTPS FAIL WE KEEP GOING
set +e


############################# GET CTUIT FILES FROM BERTHA THEN BACK THEM UP ON BERTHA ###################
lftp -e 'set net:timeout 10;set ssl:verify-certificate no; set ftp:ssl-protect-data true;' -u VM_ctuit,Serenitee185Ctuit 50.195.41.122  << EOF
	lcd /home/ubuntu/db_files/incoming/ctuit
	mget *
	mirror --reverse --no-recursion /home/ubuntu/db_files/incoming/ctuit /backup
	mrm *csv
bye
EOF

echo 'CTUIT FTP SUBROUTINE RAN WITH EXIT CODE OF: '$?

#### SFTP PX
#### PULL THE > /dev/null 2>&1 IF WE WANT TO SEE ERROR
	sftp -o "IdentityFile=/home/ubuntu/.ssh/it@serenitee.id_rsa" -oport=8022 m279@ftp.prod.paytronix.com > /dev/null 2>&1 << EOF

#### LOCAL DIRECTORY FOR INCOMING FILES
	lcd /home/ubuntu/db_files/incoming/px

### grab all the files from remote host, these will be csvs
### put them into incoming local directory
	mget *.csv

### delete the files from remote host
 	rm *.csv

#### END SCRIPT
EOF

echo 'PX GET FTP SUBROUTINE RAN WITH EXIT CODE OF: '$?


#### LFTP A COPY OF PX FILES TO BERTHA
## lftp - e (lftp "command")
## mput - O (specifies base directory)
## -u (specifies username)
lftp -e 'set  net:max-retries 2;set net:timeout 10;set ssl:verify-certificate no; set ftp:ssl-protect-data true;  mput -O / /home/ubuntu/db_files/incoming/px/*; bye' -u px,S3r3n1t33FTP 50.195.41.122 

echo 'BERTHA FTP SUBROUTINE RAN WITH EXIT CODE OF: '$?


#### LFTP A COPY OF PX TO MARKETING VITALS
## lftp - e (lftp "command")
## mput - O (specifies base directory)
## -u (specifies username)
lftp -e 'set net:max-retries 2;set net:timeout 10;set ssl:verify-certificate no; set ftp:ssl-protect-data true;  mput -O / /home/ubuntu/db_files/incoming/px/*; bye' -u serenitee-pt,S3tm#XB4z! ftp.marketingvitals.com 

echo 'MARKETING VITALS FTP SUBROUTINE RAN WITH EXIT CODE OF: '$



