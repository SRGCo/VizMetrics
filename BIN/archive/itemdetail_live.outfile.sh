5-5-2017
#! /bin/bash

# OPTIMIZE TABLES
mysqlcheck -o --all-databases

# UNCOMMENT TO LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# Next line turns echo on
set -x


#### Delete ItemDetail_Live.out.csv to make room for new one.
# rm /home/srg/db_files/incoming/ItemDetail_Live.out.csv

#### Delete ItemDetail_Live.out.csv to make room for new one.
# rm /home/srg/db_files/incoming/ItemDetail_Live.csv



### FIRE UP MYSQL
mysql -v -uroot -ps3r3n1t33<<EOFMYSQL
### CHOOSE DATABASE
USE SRG_items;


###### CAN WE LIMIT TO JUST THOSE WHERE FIRSTNAME,LASTNAME NULL?

UPDATE SRG_items.ItemDetail_Live as ID
LEFT JOIN SRG_checks.CheckDetail_Live as CD
ON ID.POSkey = CD.POSkey
SET 
ID.lastname = CD.lastname,
ID.firstname = CD.firstname,
ID.GrossSalesCoDefined = CD.GrossSalesCoDefined,
ID.Guests = CD.Guests,
ID.Promos = CD.Promos,
ID.ExclusiveTaxes = CD.ExclusiveTaxes,
ID.NonCashTips = CD.NonCashTips,
ID.OpenTime = CD.OpenTime,
ID.CloseTime = CD.CloseTime,
ID.MinutesOpen = ID.MinutesOpen;




##### WRITE TO OUTFILE
#	SELECT ItemDetail_Live.* INTO OUTFILE '/home/srg/db_files/incoming/ItemDetail_Live.out.csv' FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' FROM ItemDetail_Live; 


# QUIT MYSQL
EOFMYSQL

##### PROCESS THE FILE
#### PREPEND HEADERS
# cat /home/srg/db_files/headers/itemdetail.headers.csv /home/srg/db_files/incoming/ItemDetail_Live.out.csv > /home/srg/db_files/incoming/ItemDetail_Live.csv

##### CheckDetail_Live.csv



