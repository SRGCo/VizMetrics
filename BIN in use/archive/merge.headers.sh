# 4-25-2017
#! /bin/bash

# UNCOMMENT TO LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# Next line turns echo on
set -x

### FIRE UP MYSQL
mysql -v -uroot -ps3r3n1t33<<EOFMYSQL
### CHOOSE DATABASE
USE SRG_checks;

# WRITE TO OUTFILE
SELECT CheckDetail_Live.* INTO OUTFILE '/home/srg/db_files/incoming/CheckDetail_Live.out.csv' FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' FROM CheckDetail_Live; 

# QUIT MYSQL
EOFMYSQL


