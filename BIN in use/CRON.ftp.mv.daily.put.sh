#!/bin/bash
#echo on
set -x

#### LFTP A COPY OF PX FILES TO BERTHA
## lftp - e (lftp "command")
## mput - O (specifies base directory)
## -u (specifies username)
lftp -e 'set net:timeout 10;set ssl:verify-certificate no; set ftp:ssl-protect-data true;  mput -O / /home/ubuntu/db_files/incoming/px/*; bye' -u px,S3r3n1t33FTP 50.195.41.122 



#### LFTP A COPY OF PX TO MARKETING VITALS
## lftp - e (lftp "command")
## mput - O (specifies base directory)
## -u (specifies username)
lftp -e 'set net:timeout 10;set ssl:verify-certificate no; set ftp:ssl-protect-data true;  mput -O / /home/ubuntu/db_files/incoming/px/*; bye' -u serenitee-pt,S3tm#XB4z! ftp.marketingvitals.com 










