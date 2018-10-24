# 4-3-2017
#! /bin/bash

# UNCOMMENT TO LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# Next line turns echo on
set -x

# PRIOR TO RUNNING REQUIRES IMPORTS TO
# Items
# Sale Departments
# Master Sale Departments
# CheckDetail_live

###########################################################################
#### 1 #### CTuit export = Item - Full Table 			###########
#### 1 #### Save it to incoming Items.raw.csv               ###############

#### Delete CheckDetail.old.csv to make room for new one
rm /home/ubuntu/db_files/incoming/Items.old.csv

#### Rename current CheckDetail.csv file to make room for new one.
mv /home/ubuntu/db_files/incoming/Items.csv /home/ubuntu/db_files/incoming/Items.old.csv

### WRITE FROM LINE 2 ON TO NEW FILE ItemDetail.csv
tail -n+2 /home/ubuntu/db_files/incoming/Items.raw.csv > /home/ubuntu/db_files/incoming/Items.csv 

###########################################################################
#### 4 #### CURRENTLY USING### Item Detail by Date ##### export from CTUIT  ##
#### 4 #### saving as ItemDetail.raw.csv                       ###############

#### Delete CheckDetail.old.csv to make room for new one.
rm /home/ubuntu/db_files/incoming/ItemDetail.old.csv

#### Rename current CheckDetail.csv file to make room for new one.
mv /home/ubuntu/db_files/incoming/ItemDetail.csv /home/ubuntu/db_files/incoming/ItemDetail.old.csv

### WRITE FROM LINE 2 ON TO NEW FILE ItemDetail.csv
tail -n+2 /home/ubuntu/db_files/incoming/ItemDetail.raw.csv > /home/ubuntu/db_files/incoming/ItemDetail.csv

#########################   IMPORT TWEAK  #####################################
### MATCH THE INCOMING FILE STRUCTURE TO THE EXTENDED TABLE STRUCTURE
sed -e 's/$/,,,,,,,,,,/g' -e '$ s/,$//' /home/ubuntu/db_files/incoming/ItemDetail.csv  > /home/ubuntu/db_files/incoming/new_file && mv /home/ubuntu/db_files/incoming/new_file /home/ubuntu/db_files/incoming/ItemDetail.csv 

#### Delete ItemDetail_Live.out.csv to make room for new one.
rm /home/ubuntu/db_files/incoming/ItemDetail_Live.out.csv

### BACKUP DB ######
# mysqldump -uroot -ps3r3n1t33 SRG_Dev > /home/ubuntu/db_files/SRG_Dev_bu.sql


### FIRE UP MYSQL TO BEGIN PROCESSING DATA
mysql -v -uroot -ps3r3n1t33<<EOFMYSQL

### CHOOSE DATABASE

USE SRG_Dev;


### 1 ###
# Truncate Items table and reload from items.csv (regardless of changes)
	TRUNCATE TABLE Items;

# Load the data from the ItemDetail.csv file into the Items table
	Load data local infile '/home/ubuntu/db_files/incoming/Items.csv' into table Items fields terminated by ',' lines terminated by '\n';



### 2 #####################################################################
## CREATE TEMP TABLE, LOAD DATA, ALTER STRUCTURE, COPY TO LIVE TABLE ###

#### CREATE ITEMDETAIL TEMP FROM STRUCTURE
### MAKE SURE THE TEMP TABLE HAS BEEN DUMPED
	DROP TABLE IF EXISTS ItemDetail_temp;

# Create a empty copy of TableTurns_Temp table from TableTurns_Structure table
	CREATE TABLE ItemDetail_temp AS (SELECT * FROM ItemDetail_Structure WHERE 1=0);

#### Load the data from the latest file into the (temp) TableTurns table ########################
	Load data local infile '/home/ubuntu/db_files/incoming/ItemDetail.csv' into table ItemDetail_temp fields terminated by ',' lines terminated by '\n';

### UPDATE THE DOB FIELD TO SQL FORMAT
	UPDATE ItemDetail_temp SET DOB = str_to_date(DOB, '%m/%d/%Y');

### CHANGE THE DOB FIELD TYPE TO DATE
	ALTER TABLE ItemDetail_temp CHANGE DOB DOB DATE NOT NULL;


# Create POSkey field
	ALTER TABLE ItemDetail_temp ADD POSkey VARCHAR( 255 ) first;

# Create excel date field
	ALTER TABLE ItemDetail_temp ADD Exceldate INT(100) NOT NULL AFTER LocationID;

# Update excel date field
	 UPDATE ItemDetail_temp set Exceldate = (((unix_timestamp(DOB) / 86400) + 25569) + (-5/24));

# Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
	 UPDATE ItemDetail_temp set POSkey = CONCAT_WS('', LocationID, Exceldate, CheckNumber);

# Dump Excel date field
	 ALTER TABLE ItemDetail_temp DROP Exceldate;

# Create Itemname field
	ALTER TABLE ItemDetail_temp ADD ItemName VARCHAR(255) AFTER ItemID;
	ALTER TABLE ItemDetail_temp ADD INDEX (ItemName);

############## ADD ITEM NAME
	UPDATE ItemDetail_temp ID
	LEFT JOIN Items IT 
		ON ID.ItemID = IT.ItemID 
	SET ID.ItemName = IT.ItemName;


####### Create SalesDepartmentID field
	ALTER TABLE ItemDetail_temp ADD SaleDepartmentID INT (11) AFTER ItemName; 
	ALTER TABLE ItemDetail_temp ADD INDEX (SaleDepartmentID);

####### ADD SalesDepartmentId
	UPDATE ItemDetail_temp ID
	LEFT JOIN Items IT 
		ON ID.ItemID = IT.ItemID 
	SET ID.SaleDepartmentID = IT.SaleDepartmentID;

####### Create SalesDepartment & MasterSaleDepartmentID field
	ALTER TABLE ItemDetail_temp ADD SaleDepartmentName VARCHAR (255) AFTER SaleDepartmentID;
	ALTER TABLE ItemDetail_temp ADD MasterSaleDepartmentID INT (11)  AFTER SaleDepartmentName; 
	ALTER TABLE ItemDetail_temp ADD INDEX (MasterSaleDepartmentID);
	ALTER TABLE ItemDetail_temp ADD MasterSaleDepartmentName VARCHAR (255) AFTER MasterSaleDepartmentID; 
	ALTER TABLE ItemDetail_temp ADD GroupName VARCHAR (255) AFTER MasterSaleDepartmentName;

####### JOIN SaleDepartmentName & MasterSaleDepartmentId
	UPDATE ItemDetail_temp id
	LEFT JOIN SaleDepartment sd 
		ON id.SaleDepartmentID = sd.SaleDepartmentID 
	SET id.SaleDepartmentName = sd.SaleDepartmentName,
	id.MasterSaleDepartmentID = sd.MasterSaleDepartmentID;

######## JOIN MasterSaleDepartmentName
	UPDATE ItemDetail_temp id
	LEFT JOIN MasterSaleDepartment ms 
		ON id.MasterSaleDepartmentID = ms.MasterSaleDepartmentID 
	SET id.MasterSaleDepartmentName = ms.MasterSaleDepartmentName;




### PUT OpenTime default value
	UPDATE ItemDetail_temp SET OpenTime= '1900-01-01 01:00:00';

### PUT CloseTime default value
	UPDATE ItemDetail_temp SET CloseTime= '1900-01-01 01:00:00';

### CHANGE THE OPENTIME FIELD TYPE TO DATE
	ALTER TABLE ItemDetail_temp CHANGE OpenTime OpenTime DATETIME NULL;

### CHANGE THE OPENTIME FIELD TYPE TO DATE
	ALTER TABLE ItemDetail_temp CHANGE CloseTime CloseTime DATETIME NULL;


###################### UPDATES USING CheckDetail_Live #########################
#### MAKE CERTAIN CHECK DETAIL IS FULLY UP TO DATE BEFORE RUNNING #############
#### POPULATE NEW FIELDS ######################################################

UPDATE SRG_Dev.ItemDetail_temp as ID
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

######## INSERT TEMP DATA INTO LIVE TABLE #####################################
	INSERT INTO ItemDetail_Live SELECT * FROM ItemDetail_temp;	



##### WRITE TO OUTFILE
	SELECT ItemDetail_Live.* INTO OUTFILE '/home/ubuntu/db_files/incoming/ItemDetail_Live.out.csv' FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' FROM ItemDetail_Live; 


# QUIT MYSQL
EOFMYSQL

#### Delete ItemDetail.old.csv to make room for new one.
rm /home/ubuntu/db_files/incoming/ItemDetail_Live.old.csv

#### Rename current CheckDetail.csv file to make room for new one.
mv /home/ubuntu/db_files/incoming/ItemDetail_Live.csv /home/ubuntu/db_files/incoming/ItemDetail_Live.old.csv

##### PROCESS THE FILE
#### PREPEND HEADERS
cat /home/ubuntu/db_files/headers/itemdetail.headers.csv /home/ubuntu/db_files/incoming/ItemDetail_Live.out.csv > /home/ubuntu/db_files/incoming/ItemDetail_Live.csv

##### CheckDetail_Live.csv




