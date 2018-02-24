#! /bin/bash

# Next line turns echo on
set -x

# Will need to remove the first row of header data from file before importing it.
# tail -n+2 TableTurns.raw.csv > TableTurns.csv 


#Fire up mysql (as root not the best idea, revise in future)
# mysql -uroot -ps3r3n1t33 <<EOF

#MySQL in Verbose mode
mysql -v -uroot -ps3r3n1t33<<EOFMYSQL

USE srg_dev4;

##### 1 create copy of the TenderDetail_structure table -TenderDetail_temp
# Create a empty copy of TenderDetai_Temp table from TenderDetail_structure table
     # CREATE TABLE TenderDetail_Temp AS (SELECT * FROM TenderDetail_structure WHERE 1=0);

# Load the data from the latest file into the (temp) TableTurns table
    # Load data local infile '/home/srg/db_files/TenderDetail.csv' into table TenderDetail_Temp fields terminated by ',' lines terminated by '\n';

# Create excel date field
#	ALTER TABLE TenderDetail_Temp ADD TenderName VARCHAR(128) NOT NULL AFTER LocationID;
#	ALTER TABLE TenderDetail_Temp ADD TenderTypeName VARCHAR(128) NOT NULL AFTER LocationID;

##### 2 ### TWEAK DATA IN TEMP TABLE
# PUT DOB INTO SQL FORMAT
   #	UPDATE TenderDetail_Temp SET DOB= STR_TO_DATE(DOB, '%c/%e/%Y') WHERE STR_TO_DATE(DOB, '%c/%e/%Y') IS NOT NULL;
# Change DOB field to type date
#	ALTER TABLE TenderDetail_Temp CHANGE DOB DOB DATE;



# Create POSkey field
#	ALTER TABLE TenderDetail_Temp ADD POSkey VARCHAR( 255 ) first;

# Create excel date field
#	ALTER TABLE TenderDetail_Temp ADD Exceldate INT(100) NOT NULL AFTER LocationID;

# Update excel date field
#	UPDATE TenderDetail_Temp set Exceldate = (((unix_timestamp(DOB) / 86400) + 25569) + (-5/24));

# Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
#	UPDATE TenderDetail_Temp set POSkey = CONCAT_WS('-', LocationID, Exceldate, CheckNumber);

# NOT WORKING
# This should be the check detail join
# Update TenderDetail_Live
# INNER JOIN Tenders ON TenderDetail_Live.TenderID = Tenders.TenderID
# SET TenderDetail_Live.TenderName = Tenders.TenderName, TenderDetail_Live.TenderTypeName = Tenders.TenderTypeName; 

SELECT TenderDetail_Live.* INTO OUTFILE '/home/srg/db_files/Tender_details.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' FROM TenderDetail_Live;


##### 3 update TenderDetail_live with the data

##### 4 drop the TenderDetail_Temp table



# NEED to add an auto index primary key to the live table so it incrments when temp table values are selected/updated








# Create a empty copy of CardActivity table from CardActivityStructure table
#        CREATE TABLE CardActivity AS (SELECT * FROM CardActivityStructure WHERE 1=0);

# Load the data from the latest file into the (temp) TableTurns table
#       Load data local infile '/home/srg/db_files/TableTurns.csv' into table TableTurns fields terminated by ',' lines terminated by '\n';

# QUIT MYSQL
EOFMYSQL

#TURN ECHO ON AGAIN
set -x



# Now that we are back out of the mysql aql scripting we can 
# DELETE THE RENAMED AND RAW CardActivity files
# cp TableTurns.csv TableTurns.old.csv
# rm TableTurns.csv
# TableTurns.raw.csv






 



