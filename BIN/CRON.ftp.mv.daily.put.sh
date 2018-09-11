#!/bin/bash
#echo on
# set -x
### IF THE FOLLOWING FAIL WE KEEP GOING
set +e


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

echo 'MARKETING VITALS FTP SUBROUTINE RAN WITH EXIT CODE OF: '$?








