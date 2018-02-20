#! /bin/bash
#uncomment next for echo
#set -x
# next line logs to syslog
exec 1> >(logger -s -t $(basename $0)) 2>&1


TIMESTAMP=$(date +"%F")
BACKUP_DIR="/mnt/USB_drive/"
MYSQL_USER="srg"
MYSQL=/usr/bin/mysql
MYSQL_PASSWORD="s3r3n1t33"
MYSQLDUMP=/usr/bin/mysqldump
 
mkdir -p "$BACKUP_DIR/mysql/$TIMESTAMP"
 
databases=`$MYSQL --user=$MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)"`
 
for db in $databases; do
  $MYSQLDUMP --force --opt --user=$MYSQL_USER -p$MYSQL_PASSWORD --databases $db | gzip > "$BACKUP_DIR/mysql/$TIMESTAMP/$db.gz"
done

