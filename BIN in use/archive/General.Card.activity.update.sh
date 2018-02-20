#! //bin/bash
# LOG IT TO SYSLOG
exec 1> >(logger -s -t $(basename $0)) 2>&1

## REMOVE HEADERS AND MERGE (IF NECCESSARY) INCOMING CARD ACTIVITY CSVs
## INTO SINGLE CARD ACTIVITY FILE IN DB_FILES
for file in /home/srg/db_files/incoming/px/GeneralCardActivity*.csv
do
    tail -n+3 "$file"  >> /home/srg/db_files/CardActivity.csv
done


## MySQL IN VERBOSE MODE
mysql -uroot -ps3r3n1t33<<EOFMYSQL

## SELECT DB
USE SRG_px;

# Create a empty copy of CardActivity table from CardActivityStructure table
        CREATE TABLE CardActivity_Temp AS (SELECT * FROM CardActivity_Structure WHERE 1=0);

# Load the data from the latest file into the (temp) CardActivity table
       Load data local infile '/home/srg/db_files/CardActivity.csv' into table CardActivity_Temp fields terminated by ',' lines terminated by '\n';

# Create POSkey field
	ALTER TABLE CardActivity_Temp ADD LocationID VARCHAR( 12 ) first;
	UPDATE CardActivity_Temp set LocationID = (SELECT ID from locations WHERE locations.PXID = CardActivity_Temp.StoreNumber);

# UPDATE THE DOB TO VARCHAR
	ALTER TABLE CardActivity_Temp modify TransactionDate VARCHAR(40);
	ALTER TABLE CardActivity_Temp ADD COLUMN TransactionTime VARCHAR(10) AFTER TransactionDate;
	UPDATE CardActivity_Temp SET TransactionTime = RIGHT(TransactionDate, 5);
	UPDATE CardActivity_Temp SET TransactionDate = LEFT(TransactionDate,10);

# PUT TransactionDate INTO SQL FORMAT
        UPDATE CardActivity_Temp SET TransactionDate= STR_TO_DATE(TransactionDate, '%Y-%m-%d') WHERE STR_TO_DATE(TransactionDate, '%Y-%m-%d') IS NOT NULL;

# Change TransactionDate field to type date
	ALTER TABLE CardActivity_Temp CHANGE TransactionDate TransactionDate DATE;

# Create POSkey field
	ALTER TABLE CardActivity_Temp ADD POSkey VARCHAR( 255 ) first;

# Create excel date field
	ALTER TABLE CardActivity_Temp ADD Exceldate INT(100) NOT NULL AFTER LocationID;

# Update excel date field
	 UPDATE CardActivity_Temp set Exceldate = (((unix_timestamp(TransactionDate) / 86400) + 25569) + (-5/24));

# Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
	 UPDATE CardActivity_Temp set POSkey = CONCAT_WS('', LocationID, Exceldate, CheckNo);

# ADD the RowID field but do not populate it (it will get auto increment when it is selected into CardActivitylive)
          ALTER TABLE CardActivity_Temp ADD COLUMN RowID int(11) AFTER POSkey;

########### UPDATE THE CardActivitylive table
          INSERT INTO CardActivity_Live SELECT * FROM CardActivity_Temp;

# Drop the CardActivity_Temp table so we are ready for next time
 	   DROP TABLE CardActivity_Temp;

# QUIT MYSQL
EOFMYSQL

#TURN ECHO ON AGAIN
set -i

# DELETE THE RENAMED AND RAW CardActivity files
rm /home/srg/db_files/incoming/px/CardActivity*.csv
rm /home/srg/db_files/CardActivity*.csv





 


