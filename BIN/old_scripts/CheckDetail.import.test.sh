# 2-17-2017
#! /bin/bash
# Next line turns echo on
set -x

###########################################################################
######## CURRENTLY USING CheckDetail_wip export from CTUIT  ###############
######## saving as CheckDetail.update.raw.csv               ###############




#### Delete CheckDetail.old.csv to make room for new one.
# rm /home/srg/db_files/Check.Detail.old.csv

#### Rename current CheckDetail.csv file to make room for new one.
# mv /home/srg/db_files/CheckDetail.csv /home/srg/db_files/CheckDetail.old.csv

### REMOVE FIRST ROW/HEADERS BEFORE IMPORTING
tail -n+2 CheckDetail.update.raw.csv > Check.detail.update.csv 


### FIRE UP MYSQL
mysql -v -uroot -ps3r3n1t33<<EOFMYSQL

### CHOOSE DATABASE

USE SRG_live;

# MAKE A BACKUP OF EXISTING CHECK DETAIL INCOMING TABLE AFTER FLUSHING BACKUP TABLE
	TRUNCATE Check_Detail_Incoming_bu; 
	INSERT Check_Detail_Incoming_bu SELECT * FROM Check_Detail_Incoming;

# DUMP EXISTING CHECK DETAIL INCOMING TABLE
	DROP TABLE if exists Check_Detail_Incoming;

#### MAKE A STRUCTURE COPY OF THE CHECK DETAIL TABLE
	CREATE TABLE Check_Detail_Incoming like Check_Detail_Incoming_Structure;

# Load the data from the latest file into the (temp) TableTurns table
     	Load data local infile '/home/srg/db_files/Check.detail.update.csv' into table Check_Detail_Incoming fields terminated by ',' lines terminated by '\n';

# Add a record id which will get auto incremented when imported into live
	ALTER TABLE Check_Detail_Incoming ADD record_id INT;

# PUT TransactionDate INTO SQL FORMAT
       UPDATE Check_Detail_Incoming SET DOB = STR_TO_DATE(DOB, '%m/%d/%Y') WHERE STR_TO_DATE(DOB, '%m/%d/%Y') IS NOT NULL;

# Remove records where CheckNumber is null.
	DELETE from Check_Detail_Incoming where CheckNumber = '0';

# Change TransactionDate field to type date
	ALTER TABLE Check_Detail_Incoming CHANGE DOB DOB DATE;

# Create Name fields
	ALTER TABLE Check_Detail_Incoming ADD firstname VARCHAR( 255 ) first;
	ALTER TABLE Check_Detail_Incoming ADD lastname VARCHAR( 255 ) first;

# Create POSkey field
	ALTER TABLE Check_Detail_Incoming ADD POSkey VARCHAR( 255 ) first;

# Create excel date fieldC
	ALTER TABLE Check_Detail_Incoming ADD Exceldate INT(100) NOT NULL AFTER LocationID;

# Update excel date field
	 UPDATE Check_Detail_Incoming set Exceldate = (((unix_timestamp(DOB) / 86400) + 25569) + (-5/24));

# Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
	 UPDATE Check_Detail_Incoming SET POSkey = CONCAT_WS('-', LocationID, Exceldate, CheckNumber);

# Dump Excel date field
	 ALTER TABLE Check_Detail_Incoming DROP Exceldate;

# Join Employee names
########## CHECK THIS QUERY, CAN WE SPEED IT UP OR SOMETHING??? ##########


#UPDATE Check_Detail_Incoming WITH NAMES 
	UPDATE Check_Detail_Incoming CDI 
	INNER JOIN SRG_Employees_Live SEL ON (CDI.LocationID = SEL.LocationID AND CDI.Base_EmployeeID = SEL.EmployeeID) 
	SET CDI.lastname = SEL.LastName, CDI.firstname = SEL.FirstName 
	WHERE CDI.lastname = '' AND CDI.firstname = '';


#### UPDATE LEGACY BAR NAMES
#### DO NOT NEED TO UPDATE IF MERGING WITH LIVE TABLE
	UPDATE Check_Detail_Incoming CDI INNER JOIN SRG_Employees_Legacy SEL ON (CDI.LocationID = SEL.LocationID AND CDI.Base_EmployeeID = SEL.EmployeeID) 
	SET CDI.lastname = SEL.LastName, CDI.firstname = SEL.FirstName;



###### ADD THIS DATA TO LIVE TABLE
	INSERT Check_Detail_Full_Live SELECT * FROM Check_Detail_Incoming;

##########################################################
##########################################################
##### 
##### NOW RUN TABLE TURNS PROCEDURE
### tableturns.update.sh
### which spits out an outfile




# QUIT MYSQL
EOFMYSQL





