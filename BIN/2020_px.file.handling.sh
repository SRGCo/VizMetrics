#!/bin/bash
#echo on
# set -x


# DELETE PREVIOUS CARDACTIVITY FILES
rm -f /home/ubuntu/db_files/incoming/px/CardActivity*.csv
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

rm -f /home/ubuntu/db_files/incoming/px/infile.cardactivity.csv
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

# ANNOUCE PREVIOUS CARDACTIVITY FILES DELETED
echo 'ANNOUCE PREVIOUS CARDACTIVITY FILES DELETED'



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

echo 'PX GET FTP COMPLETED EXIT CODE = '$?


## REMOVE (1) HEADER ROW AND MERGE (IF NECCESSARY) INCOMING CARD ACTIVITY CSVs
## INTO SINGLE CARD ACTIVITY FILE IN DB_FILES
for file in /home/ubuntu/db_files/incoming/px/CardActivity*.csv
  do
	#### MAKE A COPY OF THE FILE IN BACKUP DIR
	cp "$file" //home/ubuntu/db_files/incoming/px/backup/
	tail -n+2 "$file"  >> /home/ubuntu/db_files/incoming/px/infile.cardactivity.csv
  done || trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'DOWNLOADED PAYTRONIX CARDACTIVITY FILE(S) CLEANED (AND MERGED) INTO infile.cardactivity.csv, ORIGINAL FILE(S) ARCHIVED'



