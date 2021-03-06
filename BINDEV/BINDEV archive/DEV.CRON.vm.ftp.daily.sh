#!/bin/bash
#echo on
set -x

failfunction()
{
    if [ "$1" != 0 ]
    then 
	 SCRIPTNAME=$(basename -- "$0") 
	 echo "$SCRIPTNAME failed at line: $LINENO"
         mail -s "VizMetrics Server Alert"  it@serenitee.com <<< 'Script '"$SCRIPTNAME"' failed at Line: '"$LINENO"
         exit
    fi
}

#### LFTP A COPY OF PX FILES TO BERTHA
## lftp - e (lftp "command")
## mput - O (specifies base directory)
## -u (specifies username)
lftp -e 'set net:timeout 10;set ssl:verify-certificate no; set ftp:ssl-protect-data true;  mput -O / /home/ubuntu/db_files/incoming/px/*; bye' -u px,S3r3n1t33FTP 50.195.41.122 
failfunction "$?"


#### LFTP A COPY OF PX TO MARKETING VITALS
## lftp - e (lftp "command")
## mput - O (specifies base directory)
## -u (specifies username)
lftp -e 'set net:timeout 10;set ssl:verify-certificate no; set ftp:ssl-protect-data true;  mput -O / /home/ubuntu/db_files/incoming/px/*; bye' -u serenitee-pt,S3tm#XB4z! ftp.marketingvitals.com 
failfunction "$?"


#### LFTP COPY OF CTUIT FILES TO BERTHA
## lftp - e (lftp "command")
## mput - O (specifies base directory)
## -u (specifies username)
lftp -e 'set net:timeout 10;set ssl:verify-certificate no; set ftp:ssl-protect-data true;  mput -O / /home/ubuntu/db_files/incoming/*; bye' -u VM_ctuit,Serenitee185CtuitP 50.195.41.122 
failfunction "$?"






