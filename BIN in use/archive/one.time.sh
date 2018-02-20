#! /bin/bash
# Next line turns echo on
set -x


### FIRE UP MYSQL
mysql -v -uroot -ps3r3n1t33<<EOFMYSQL


### CHOOSE DATABASE
USE SRG_items;


### CHANGE THE OPENTIME FIELD TYPE TO DATE
	ALTER TABLE ItemDetail_temp CHANGE OpenTime OpenTime DATETIME NULL;

### CHANGE THE OPENTIME FIELD TYPE TO DATE
	ALTER TABLE ItemDetail_temp CHANGE CloseTime CloseTime DATETIME NULL;


###################### UPDATES USING CheckDetail_Live #########################
#### MAKE CERTAIN CHECK DETAIL IS FULLY UP TO DATE BEFORE RUNNING #############
#### POPULATE NEW FIELDS ######################################################

UPDATE SRG_items.ItemDetail_temp as ID
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
ID.MinutesOpen = CD.MinutesOpen;


####### BACKUP THE ItemDetail_Live table ######################################
	TRUNCATE ItemDetail_Live_bu;
	INSERT INTO ItemDetail_Live_bu SELECT * FROM ItemDetail_Live;


######## INSERT TEMP DATA INTO LIVE TABLE #####################################
	INSERT INTO ItemDetail_Live SELECT * FROM ItemDetail_temp;	



##### WRITE TO OUTFILE
	SELECT ItemDetail_Live.* INTO OUTFILE '/home/srg/db_files/incoming/ItemDetail_Live.out.csv' FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' FROM ItemDetail_Live; 


# QUIT MYSQL
EOFMYSQL

#### Delete ItemDetail.old.csv to make room for new one.
rm /home/srg/db_files/incoming/ItemDetail_Live.old.csv

#### Rename current CheckDetail.csv file to make room for new one.
mv /home/srg/db_files/incoming/ItemDetail_Live.csv /home/srg/db_files/incoming/ItemDetail_Live.old.csv

##### PROCESS THE FILE
#### PREPEND HEADERS
cat /home/srg/db_files/headers/itemdetail.headers.csv /home/srg/db_files/incoming/ItemDetail_Live.out.csv > /home/srg/db_files/incoming/ItemDetail_Live.csv

