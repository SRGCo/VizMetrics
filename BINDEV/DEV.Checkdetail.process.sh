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
rm /home/ubuntu/db_files/incoming/TableTurns.old.csv

## 1 ## RENAME CURRENT TABLETURNS FILE TO MAKE ROOM FOR INCOMING
mv /home/ubuntu/db_files/incoming/TableTurns.csv /home/ubuntu/db_files/incoming/TableTurns.old.csv

## 1 ## REMOVE FIRST ROW/HEADERS BEFORE IMPORTING
tail -n+2 /home/ubuntu/db_files/incoming/TableTurns.raw.csv > /home/ubuntu/db_files/incoming/TableTurns.csv

## 1 ## DELETE INCOMING RAW FILE AFTER CLEANING IT UP
rm /home/ubuntu/db_files/incoming/TableTurns.raw.csv 

##################### EMPLOYEES #################################

## 2 ## DELETE OLD EMPLOYEES FILE TO MAKE ROOM FOR NEW -OLD- FILE
rm /home/ubuntu/db_files/incoming/Employees.old.csv

## 2 ## RENAME CURRENT EMPLOYEES FILE TO MAKE ROOM FOR INCOMING
mv /home/ubuntu/db_files/incoming/Employees.csv /home/ubuntu/db_files/incoming/Employees.old.csv



################### THIS IS FAILING ############################

## 2 ## REMOVE FIRST ROW/HEADERS BEFORE IMPORTING
tail -n+2 /home/ubuntu/db_files/incoming/Employees.raw.csv > /home/ubuntu/db_files/incoming/Employees.csv 

## 2 ## DELETE INCOMING RAW FILE AFTER CLEANING IT UP
rm /home/ubuntu/db_files/incoming/Employees.raw.csv 

########################### CHECK DETAIL ########################

## 3 ## DELETE OLD CHECK DETAIL FILE TO MAKE ROOM FOR NEW -OLD- FILE
rm /home/ubuntu/db_files/incoming/CheckDetail.old.csv

## 3 ## RENAME CURRENT FILE TO MAKE ROOM FOR INCOMING
mv /home/ubuntu/db_files/incoming/CheckDetail.csv /home/ubuntu/db_files/incoming/CheckDetail.old.csv

## 3 ## REMOVE FIRST ROW/HEADERS BEFORE IMPORTING
tail -n+2 /home/ubuntu/db_files/incoming/CheckDetail.raw.csv > /home/ubuntu/db_files/incoming/CheckDetail.csv 

## 3 ## DELETE INCOMING RAW FILE AFTER CLEANING IT UP
rm /home/ubuntu/db_files/incoming/CheckDetail.raw.csv 


## PROCESS TDATA SINCE LAST DOB IN TABLES
### MAKE SURE THE TEMP TABLE HAS BEEN DUMPED


mysql  --login-path=local --silent -DSRG_Prod -N -e "DROP TABLE IF EXISTS TableTurns_Temp"

### Create a empty copy of TableTurns_Temp table from TableTurns_Structure table
mysql  --login-path=local --silent -DSRG_Prod -N -e "CREATE TABLE TableTurns_Temp AS (SELECT * FROM TableTurns_Structure WHERE 1=0)"

### Load the data from the latest file into the (temp) TableTurns table ########################
mysql  --login-path=local --silent -DSRG_Prod -N -e "Load data local infile '/home/ubuntu/db_files/incoming/TableTurns.csv' into table TableTurns_Temp fields terminated by ',' lines terminated by '\n'"

### PUT DOB INTO SQL FORMAT
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE TableTurns_Temp SET DOB= STR_TO_DATE(DOB, '%c/%e/%Y') WHERE STR_TO_DATE(DOB, '%c/%e/%Y') IS NOT NULL"

### Change DOB field to type date
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE TableTurns_Temp CHANGE DOB DOB DATE"

#### Change OpenTime & CloseTime to SQL format
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE TableTurns_Temp SET CloseTime= STR_TO_DATE(CloseTime, '%m/%e/%Y %l:%i:%s %p') WHERE STR_TO_DATE(CloseTime, '%m/%e/%Y %l:%i:%s %p')"
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE TableTurns_Temp SET OpenTime= STR_TO_DATE(OpenTime, '%m/%e/%Y %l:%i:%s %p') WHERE STR_TO_DATE(OpenTime,  '%m/%e/%Y %l:%i:%s %p')"

##### MUST ALTER THESE FIELDS TO DATETIME #################
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE TableTurns_Temp CHANGE CloseTime CloseTime DATETIME NOT NULL"

#### Create POSkey field          ######################### INDEX #######################
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE TableTurns_Temp ADD POSkey VARCHAR(30) first"
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE TableTurns_Temp ADD INDEX(POSkey)"

#### Create excel date field
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE TableTurns_Temp ADD Exceldate INT(100) NOT NULL AFTER LocationID"

#### Update excel date field
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE TableTurns_Temp set Exceldate = (((unix_timestamp(DOB) / 86400) + 25569) + (-5/24))"

########################### fix check numbers (> 6 chars, start with '100') for PX CA join ###################

#### Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE TableTurns_Temp set POSkey = CONCAT_WS('', LocationID, Exceldate, CheckNumbers)"
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE TableTurns_Temp ADD INDEX(POSkey)"

#### Insert into the LIVE tableTurns table
mysql  --login-path=local --silent -DSRG_Prod -N -e "INSERT INTO TableTurns_Live SELECT * FROM TableTurns_Temp"

#### EMPTY EMPLOYEE TABLE
mysql  --login-path=local --silent -DSRG_Prod -N -e "TRUNCATE TABLE Employees_Live"

#### Load the data from the latest file into the (LIVE) employees table
mysql  --login-path=local --silent -DSRG_Prod -N -e "Load data local infile '/home/ubuntu/db_files/incoming/Employees.csv' into table Employees_Live fields terminated by ',' lines terminated by '\n'"

#### DUMP EXISTING CHECK DETAIL INCOMING TABLE
mysql  --login-path=local --silent -DSRG_Prod -N -e "DROP TABLE IF EXISTS CheckDetail_Temp"

#### MAKE A STRUCTURE COPY OF THE CHECK DETAIL TABLE
mysql  --login-path=local --silent -DSRG_Prod -N -e "CREATE TABLE CheckDetail_Temp AS (SELECT * FROM CheckDetail_Structure WHERE 1=0)"

#### Load the data from the latest file into the (temp) check detail
mysql  --login-path=local --silent -DSRG_Prod -N -e "Load data local infile '/home/ubuntu/db_files/incoming/CheckDetail.csv' into table CheckDetail_Temp fields terminated by ',' lines terminated by '\n'"

#### PUT TransactionDate INTO SQL FORMAT
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE CheckDetail_Temp SET DOB = STR_TO_DATE(DOB, '%m/%d/%Y') WHERE STR_TO_DATE(DOB, '%m/%d/%Y') IS NOT NULL"

#### Remove records where CheckNumber is null.
mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE from CheckDetail_Temp where CheckNumber = '0'"

#### Change TransactionDate field to type date
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CheckDetail_Temp CHANGE DOB DOB DATE"

#### Create EMPLOYEE fields
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CheckDetail_Temp ADD PayrollID VARCHAR( 26 ) first"
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CheckDetail_Temp ADD firstname VARCHAR( 255 ) first"
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CheckDetail_Temp ADD lastname VARCHAR( 255 ) first"

#### Create POSkey field         ######################### INDEX #######################
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CheckDetail_Temp ADD POSkey VARCHAR(30) first"
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CheckDetail_Temp ADD INDEX(POSkey)"

#### Create excel date fieldC
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CheckDetail_Temp ADD Exceldate INT(100) NOT NULL AFTER LocationID"

#### Update excel date field
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE CheckDetail_Temp set Exceldate = (((unix_timestamp(DOB) / 86400) + 25569) + (-5/24))"

#### Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE CheckDetail_Temp SET POSkey = CONCAT_WS('', LocationID, Exceldate, CheckNumber)"

#### DROP EXCELDATE FIELD
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CheckDetail_Temp DROP COLUMN Exceldate"

#### NAMES QUERIES/UPDATES 
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE CheckDetail_Temp CDT 
	INNER JOIN Employees_Live EL ON (CDT.LocationID = EL.LocationID AND CDT.Base_EmployeeID = EL.EmployeeID) 
	SET CDT.lastname = EL.LastName, CDT.firstname = EL.FirstName, CDT.PayrollID = EL.PayrollID 
	WHERE CDT.lastname IS NULL AND CDT.firstname IS NULL"


#### LEGACY BAR NAMES
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE CheckDetail_Temp CDT
	INNER JOIN Employees_Legacy EL ON (CDT.LocationID = EL.LocationID AND CDT.Base_EmployeeID = EL.EmployeeID) 
	SET CDT.lastname = EL.LastName, CDT.firstname = EL.FirstName
	WHERE CDT.lastname IS NULL AND CDT.firstname IS NULL"


#### ADD THE TABLETURNS FIELDS SO MATCHES 'LIVE' TABLE
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CheckDetail_Temp ADD OpenTime datetime AFTER TransfersOut"
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CheckDetail_Temp ADD CloseTime datetime AFTER OpenTime"
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CheckDetail_Temp ADD MinutesOpen int(100) AFTER CloseTime"

#### UPDATE LIVE CHECK DETAIL WITH LIVE TABLE TURNS AND TABLE NAMES
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE CheckDetail_Temp CDT
	INNER JOIN TableTurns_Live TL 
	ON CDT.POSkey = TL.POSkey
	SET CDT.TableName = TL.TableName, 
	CDT.OpenTime = TL.OpenTime,
	CDT.CloseTime = TL.CloseTime,
	CDT.MinutesOpen = TIMESTAMPDIFF(minute, TL.OpenTime, TL.CloseTime)"

#### NULL OPEN/CLOSE TIME IF ZERO VALUE IN LIVE CARD DETAIL
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE CheckDetail_Temp CDT SET CDT.OpenTime = CDT.DOB WHERE CDT.OpenTime < '2001-01-01'"
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE CheckDetail_Temp CDT SET CDT.CloseTime = CDT.DOB WHERE CDT.CloseTime < '2001-01-01'"

##### ADD INCOMING CHECK DETAIL DATA TO LIVE TABLE
mysql  --login-path=local --silent -DSRG_Prod -N -e "INSERT INTO CheckDetail_Live SELECT * FROM CheckDetail_Temp"





