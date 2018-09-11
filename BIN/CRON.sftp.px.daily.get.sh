#!/bin/bash
#echo on
# set -x

#### SFTP
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



