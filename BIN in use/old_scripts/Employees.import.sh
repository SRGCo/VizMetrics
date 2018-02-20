#! /bin/bash
# Next line turns echo on
set -x

### Use "Employees - Full" export from ctuit.com
### INCOMING FILENAME = Employees.raw.csv
### Processed FILENAME =  Employees.csv


##### 2016-11-05 ### STILL MANUALLY CLEARING OLD FILES OUT OF db_files DIRECTORY before running import

# DELETE OLD Employees.csv

### REMOVE FIRST ROW/HEADERS BEFORE IMPORTING
tail -n+2 Employees.raw.csv > Employees.csv 

### FIRE UP MYSQL
mysql -v -uroot -ps3r3n1t33<<EOFMYSQL

USE SRG_live;

### EMPTY CURRENT EMPLOYEE BACKUP
 	Truncate SRG_Employees_Live_bu;

### BACKUP CURRENT EMPLOYEE LIVE TABLE
	INSERT INTO SRG_Employees_Live_bu SELECT * FROM SRG_Employees_live;

### EMPTY CURRENT EMPLOYEE LIVE TABLE
	Truncate SRG_Employees_Live;

### MAKE SURE THE TEMP TABLE HAS BEEN DUMPED
	DROP TABLE IF EXISTS SRG_Employees_Temp;

### Create a empty copy of TableTurns_Temp table from TableTurns_Structure table
	CREATE TABLE SRG_Employees_Temp AS (SELECT * FROM SRG_Employees_Temp_Structure WHERE 1=0);

### LOAD DATA FROM CLEANED EMPLOYEES FILE
     	Load data local infile '/home/srg/db_files/Employees.csv' into table SRG_Employees_Temp fields terminated by ',' lines terminated by '\n';

### ADD THE RECORD_ID FIELD
	ALTER TABLE SRG_Employees_Temp ADD record_id INT(11);

###  MOVE DATA TO LIVE TABLE
	INSERT INTO SRG_Employees_Live SELECT * FROM SRG_EMployees_Temp;


# QUIT MYSQL
EOFMYSQL





