# 4-25-2017
#! /bin/bash

# UNCOMMENT TO LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# Next line turns echo on
set -x

####### USES CTUIT EXPORTS #########
## 1 ## TableTurn [all company by date][TableTurns.raw.csv]
## 2 ## Employees
## 3 ## CheckDetail - Full by date [CheckDetail.update.raw.csv]

################# TABLETURNS ##############################

## 1 ## DELETE OLD TABLETURNS FILE TO MAKE ROOM FOR NEW -OLD- FILE
rm /home/srg/db_files/incoming/TableTurns.old.csv

## 1 ## RENAME CURRENT TABLETURNS FILE TO MAKE ROOM FOR INCOMING
mv /home/srg/db_files/incoming/TableTurns.csv /home/srg/db_files/incoming/TableTurns.old.csv

## 1 ## REMOVE FIRST ROW/HEADERS BEFORE IMPORTING
tail -n+2 /home/srg/db_files/incoming/TableTurns.raw.csv > /home/srg/db_files/incoming/TableTurns.csv

## 1 ## DELETE INCOMING RAW FILE AFTER CLEANING IT UP
rm /home/srg/db_files/incoming/TableTurns.raw.csv 

##################### EMPLOYEES #################################

## 2 ## DELETE OLD EMPLOYEES FILE TO MAKE ROOM FOR NEW -OLD- FILE
rm /home/srg/db_files/incoming/Employees.old.csv

## 2 ## RENAME CURRENT EMPLOYEES FILE TO MAKE ROOM FOR INCOMING
mv /home/srg/db_files/incoming/Employees.csv /home/srg/db_files/incoming/Employees.old.csv

## 2 ## REMOVE FIRST ROW/HEADERS BEFORE IMPORTING
tail -n+2 /home/srg/db_files/incoming/Employees.raw.csv > /home/srg/db_files/incoming/Employees.csv 

## 2 ## DELETE INCOMING RAW FILE AFTER CLEANING IT UP
rm /home/srg/db_files/incoming/Employees.raw.csv 

########################### CHECK DETAIL ########################

## 3 ## DELETE OLD CHECK DETAIL FILE TO MAKE ROOM FOR NEW -OLD- FILE
rm /home/srg/db_files/incoming/CheckDetail.old.csv

## 3 ## RENAME CURRENT EMPLOYEES FILE TO MAKE ROOM FOR INCOMING
mv /home/srg/db_files/incoming/CheckDetail.csv /home/srg/db_files/incoming/CheckDetail.old.csv

## 3 ## REMOVE FIRST ROW/HEADERS BEFORE IMPORTING
tail -n+2 /home/srg/db_files/incoming/CheckDetail.raw.csv > /home/srg/db_files/incoming/CheckDetail.csv 

## 3 ## DELETE INCOMING RAW FILE AFTER CLEANING IT UP
rm /home/srg/db_files/incoming/CheckDetail.raw.csv 


##################################################################
### FIRE UP MYSQL
mysql -v -uroot -ps3r3n1t33<<EOFMYSQL
### CHOOSE DATABASE
USE SRG_checks;



#################################################
## PROCESS TABLE TURNS DATA SINCE LAST DATE  ####
## OF DATA IN TableTurns_Live                ####
## CTUIT DATA SHOULD BE FROM NEXT DAY ON     ####
#################################################

#### EMPTY CURRENT BACKUP TABLE
	TRUNCATE TABLE TableTurns_Live_bu;

#### CREATE NEW BACKUP OF EMPLOYEES TABLE
	INSERT INTO TableTurns_Live_bu SELECT * FROM TableTurns_Live;

### MAKE SURE THE TEMP TABLE HAS BEEN DUMPED
	DROP TABLE IF EXISTS TableTurns_Temp;

### Create a empty copy of TableTurns_Temp table from TableTurns_Structure table
	CREATE TABLE TableTurns_Temp AS (SELECT * FROM TableTurns_Structure WHERE 1=0);

### Load the data from the latest file into the (temp) TableTurns table ########################
	Load data local infile '/home/srg/db_files/incoming/TableTurns.csv' into table TableTurns_Temp fields terminated by ',' lines terminated by '\n';

### PUT DOB INTO SQL FORMAT
	UPDATE TableTurns_Temp SET DOB= STR_TO_DATE(DOB, '%c/%e/%Y') WHERE STR_TO_DATE(DOB, '%c/%e/%Y') IS NOT NULL;

### Change DOB field to type date
	ALTER TABLE TableTurns_Temp CHANGE DOB DOB DATE;

#### Change OpenTime & CloseTime to SQL format
	UPDATE TableTurns_Temp SET CloseTime= STR_TO_DATE(CloseTime, '%m/%e/%Y %l:%i:%s %p') WHERE STR_TO_DATE(CloseTime, '%m/%e/%Y %l:%i:%s %p');
	UPDATE TableTurns_Temp SET OpenTime= STR_TO_DATE(OpenTime, '%m/%e/%Y %l:%i:%s %p') WHERE STR_TO_DATE(OpenTime,  '%m/%e/%Y %l:%i:%s %p');

##### MUST ALTER THESE FIELDS TO DATETIME #################
	ALTER TABLE TableTurns_Temp CHANGE CloseTime CloseTime DATETIME NOT NULL;

#### Create POSkey field          ######################### INDEX #######################
	ALTER TABLE TableTurns_Temp ADD POSkey VARCHAR( 255 ) first;
	ALTER TABLE TableTurns_Temp ADD INDEX(POSkey);

#### Create excel date field
	ALTER TABLE TableTurns_Temp ADD Exceldate INT(100) NOT NULL AFTER LocationID;

#### Update excel date field
	 UPDATE TableTurns_Temp set Exceldate = (((unix_timestamp(DOB) / 86400) + 25569) + (-5/24));

#### Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
 	UPDATE TableTurns_Temp set POSkey = CONCAT_WS('', LocationID, Exceldate, CheckNumbers);
        ALTER TABLE TableTurns_Temp ADD INDEX(POSkey);

#### Insert into the LIVE tableTurns table
	INSERT INTO TableTurns_Live SELECT * FROM TableTurns_Temp;

######################################## EMPLOYEES ######################################################################

#### DELETE OLD EMPLOYEE BACKUP TABLE
	TRUNCATE TABLE Employees_Live_bu;

#### CREATE NEW BACKUP OF EMPLOYEES TABLE
	INSERT INTO Employees_Live_bu SELECT * FROM Employees_Live;

#### EMPTY EMPLOYEE TABLE
	TRUNCATE TABLE Employees_Live;

#### Load the data from the latest file into the (temp) TableTurns table
	Load data local infile '/home/srg/db_files/incoming/Employees.csv' into table Employees_Live fields terminated by ',' lines terminated by '\n';

######################################## CHECK DETAIL #########################################################################

#### EMPTY CURRENT BACKUP TABLE
	TRUNCATE TABLE CheckDetail_Live_bu;

#### CREATE NEW BACKUP OF CHECKDETAIL TABLE
	INSERT INTO CheckDetail_Live_bu SELECT * FROM CheckDetail_Live;

#### DUMP EXISTING CHECK DETAIL INCOMING TABLE
	DROP TABLE IF EXISTS CheckDetail_Temp;

#### MAKE A STRUCTURE COPY OF THE CHECK DETAIL TABLE
	CREATE TABLE CheckDetail_Temp AS (SELECT * FROM CheckDetail_Structure WHERE 1=0);

#### Load the data from the latest file into the (temp) check detail
     	Load data local infile '/home/srg/db_files/incoming/CheckDetail.csv' into table CheckDetail_Temp fields terminated by ',' lines terminated by '\n';

#### Add a record id which will get auto incremented when imported into live
	ALTER TABLE CheckDetail_Temp ADD record_id INT;

#### PUT TransactionDate INTO SQL FORMAT
       UPDATE CheckDetail_Temp SET DOB = STR_TO_DATE(DOB, '%m/%d/%Y') WHERE STR_TO_DATE(DOB, '%m/%d/%Y') IS NOT NULL;

#### Remove records where CheckNumber is null.
	DELETE from CheckDetail_Temp where CheckNumber = '0';

#### Change TransactionDate field to type date
	ALTER TABLE CheckDetail_Temp CHANGE DOB DOB DATE;

#### Create Name fields
	ALTER TABLE CheckDetail_Temp ADD firstname VARCHAR( 255 ) first;
	ALTER TABLE CheckDetail_Temp ADD lastname VARCHAR( 255 ) first;

#### Create POSkey field         ######################### INDEX #######################
	ALTER TABLE CheckDetail_Temp ADD POSkey VARCHAR( 255 ) first;
	ALTER TABLE CheckDetail_Temp ADD INDEX(POSkey);

#### Create excel date fieldC
	ALTER TABLE CheckDetail_Temp ADD Exceldate INT(100) NOT NULL AFTER LocationID;

#### Update excel date field
	 UPDATE CheckDetail_Temp set Exceldate = (((unix_timestamp(DOB) / 86400) + 25569) + (-5/24));

#### Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
	 UPDATE CheckDetail_Temp SET POSkey = CONCAT_WS('', LocationID, Exceldate, CheckNumber);

#### DROP EXCELDATE FIELD
	ALTER TABLE CheckDetail_Temp DROP COLUMN Exceldate;

#### NAMES QUERIES/UPDATES 
	UPDATE CheckDetail_Temp CDT 
	INNER JOIN Employees_Live EL ON (CDT.LocationID = EL.LocationID AND CDT.Base_EmployeeID = EL.EmployeeID) 
	SET CDT.lastname = EL.LastName, CDT.firstname = EL.FirstName 
	WHERE CDT.lastname IS NULL AND CDT.firstname IS NULL;


#### LEGACY BAR NAMES
	UPDATE CheckDetail_Temp CDT
	INNER JOIN Employees_Legacy EL ON (CDT.LocationID = EL.LocationID AND CDT.Base_EmployeeID = EL.EmployeeID) 
	SET CDT.lastname = EL.LastName, CDT.firstname = EL.FirstName
	WHERE CDT.lastname IS NULL AND CDT.firstname IS NULL;


#### ADD THE TABLETURNS FIELDS SO MATCHES 'LIVE' TABLE
	ALTER TABLE CheckDetail_Temp ADD OpenTime datetime AFTER record_id;
	ALTER TABLE CheckDetail_Temp ADD CloseTime datetime AFTER OpenTime;
	ALTER TABLE CheckDetail_Temp ADD MinutesOpen int(100) AFTER CloseTime;


#### GO BACK TO TURN TIME AND INSERT THEM INTO INCOMING CHECK DETAIL
	UPDATE CheckDetail_Temp CDT
	INNER JOIN TableTurns_Temp TT 
	ON CDT.POSkey = TT.POSkey
	SET CDT.OpenTime = TT.OpenTime,
	CDT.CloseTime = TT.CloseTime,
	CDT.MinutesOpen = TIMESTAMPDIFF(minute, TT.OpenTime, TT.CloseTime);

#### NULL OPEN/CLOSE TIME IF ZERO VALUE
	UPDATE CheckDetail_Temp CDT SET CDT.OpenTime = CDT.DOB WHERE CDT.OpenTime < '2001-01-01';
	UPDATE CheckDetail_Temp CDT SET CDT.CloseTime = CDT.DOB WHERE CDT.CloseTime < '2001-01-01';

##### ADD INCOMING CHECK DETAIL DATA TO LIVE TABLE
	INSERT INTO CheckDetail_Live SELECT * FROM CheckDetail_Temp;

##### WRITE TO OUTFILE
	SELECT CheckDetail_Live.* INTO OUTFILE '/home/srg/db_files/incoming/CheckDetail_Live.out.csv' FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' FROM CheckDetail_Live; 

# QUIT MYSQL
EOFMYSQL

##### PROCESS THE FILE
#### PREPEND HEADERS
cat /home/srg/db_files/headers/checkdetail.headers.csv /home/srg/db_files/incoming/CheckDetail_Live.out.csv > /home/srg/db_files/incoming/CheckDetail_Live.csv

##### CheckDetail_Live.csv



