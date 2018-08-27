#! /bin/bash
### OK 7-23-18 #####

# UNCOMMENT TO LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# Next line turns echo on
set -x

####### USES CTUIT EXPORTS #########
## 1 ## TableTurn [all company by date][TableTurns.raw.csv]
## 2 ## Employees
## 3 ## CheckDetail - Full by date [CheckDetail.update.raw.csv]

################# ERROR CATCHING ##########################
failfunction()
{
    if [ "$1" != 0 ]
    then 
	 SCRIPTNAME=$(basename -- "$0") 
	 echo "$SCRIPTNAME failed at line: $LINENO"
         mail -s "VizMetrics Server Alert"  it@serenitee.com <<< 'Script '"$SCRIPTNAME"' failed at Line: '"$LINENO"
         exit
    fi
}

################# TABLETURNS ##############################
##### BACK IT UP AFTER DUMPING OLD BACKUP (-f no error if file does not exist)

## REMOVE (1) HEADER ROW AND MERGE (IF NECCESSARY) INCOMING CARD ACTIVITY CSVs
## INTO SINGLE CARD ACTIVITY FILE IN DB_FILES
for file in /home/ubuntu/db_files/incoming/*Tableturns*.csv
  do
	#### MAKE A COPY OF THE FILE IN BACKUP DIR
	cp "$file" //home/ubuntu/db_files/incoming/backup/
	failfunction "$?"
	tail -n+2 "$file"  >> /home/ubuntu/db_files/incoming/Infile.Tableturns.csv
	failfunction "$?"
  done
echo 'INCOMING TableTurns DATA FILES CLEANED AND MERGED, ARCHIVING ORIGINAL FILES'

## TableTurns ## DELETE OLD TABLETURNS FILE TO MAKE ROOM FOR NEW -OLD- FILE
rm /home/ubuntu/db_files/incoming/TableTurns.old.csv
failfunction "$?"

##################### EMPLOYEES #################################

## 2 ## DELETE OLD EMPLOYEES FILE TO MAKE ROOM FOR NEW -OLD- FILE
rm /home/ubuntu/db_files/incoming/Employees.old.csv
failfunction "$?"

## 2 ## RENAME CURRENT EMPLOYEES FILE TO MAKE ROOM FOR INCOMING
mv /home/ubuntu/db_files/incoming/Employees.csv /home/ubuntu/db_files/incoming/Employees.old.csv
failfunction "$?"

## 2 ## REMOVE FIRST ROW/HEADERS BEFORE IMPORTING
tail -n+2 /home/ubuntu/db_files/incoming/Employees.raw.csv > /home/ubuntu/db_files/incoming/Employees.csv 
failfunction "$?"

## 2 ## DELETE INCOMING RAW FILE AFTER CLEANING IT UP
rm /home/ubuntu/db_files/incoming/Employees.raw.csv 
failfunction "$?"

########################### CHECK DETAIL ########################

## 3 ## DELETE OLD CHECK DETAIL FILE TO MAKE ROOM FOR NEW -OLD- FILE
rm /home/ubuntu/db_files/incoming/CheckDetail.old.csv
failfunction "$?"

## 3 ## RENAME CURRENT FILE TO MAKE ROOM FOR INCOMING
mv /home/ubuntu/db_files/incoming/CheckDetail.csv /home/ubuntu/db_files/incoming/CheckDetail.old.csv
failfunction "$?"

## 3 ## REMOVE FIRST ROW/HEADERS BEFORE IMPORTING
tail -n+2 /home/ubuntu/db_files/incoming/CheckDetail.raw.csv > /home/ubuntu/db_files/incoming/CheckDetail.csv 
failfunction "$?"

## 3 ## DELETE INCOMING RAW FILE AFTER CLEANING IT UP
rm /home/ubuntu/db_files/incoming/CheckDetail.raw.csv 
failfunction "$?"


## PROCESS TDATA SINCE LAST DOB IN TABLES
### MAKE SURE THE TEMP TABLE HAS BEEN DUMPED


mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP TABLE IF EXISTS TableTurns_Temp"
failfunction "$?"

### Create a empty copy of TableTurns_Temp table from TableTurns_Structure table
mysql  --login-path=local --silent -DSRG_Dev -N -e "CREATE TABLE TableTurns_Temp AS (SELECT * FROM TableTurns_Structure WHERE 1=0)"
failfunction "$?"

### Load the data from the latest file into the (temp) TableTurns table ########################
mysql  --login-path=local --silent -DSRG_Dev -N -e "Load data local infile '/home/ubuntu/db_files/incoming/TableTurn.csv' into table TableTurns_Temp fields terminated by ',' lines terminated by '\n'"
failfunction "$?"

### PUT DOB INTO SQL FORMAT
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE TableTurns_Temp SET DOB= STR_TO_DATE(DOB, '%c/%e/%Y') WHERE STR_TO_DATE(DOB, '%c/%e/%Y') IS NOT NULL"
failfunction "$?"

### Change DOB field to type date
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE TableTurns_Temp CHANGE DOB DOB DATE"
failfunction "$?"

#### Change OpenTime & CloseTime to SQL format
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE TableTurns_Temp SET CloseTime= STR_TO_DATE(CloseTime, '%m/%e/%Y %l:%i:%s %p') WHERE STR_TO_DATE(CloseTime, '%m/%e/%Y %l:%i:%s %p')"
failfunction "$?"

mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE TableTurns_Temp SET OpenTime= STR_TO_DATE(OpenTime, '%m/%e/%Y %l:%i:%s %p') WHERE STR_TO_DATE(OpenTime,  '%m/%e/%Y %l:%i:%s %p')"
failfunction "$?"


##### MUST ALTER THESE FIELDS TO DATETIME #################
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE TableTurns_Temp CHANGE CloseTime CloseTime DATETIME NOT NULL"
failfunction "$?"

#### Create POSkey field          ######################### INDEX #######################
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE TableTurns_Temp ADD POSkey VARCHAR(30) first"
failfunction "$?"

mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE TableTurns_Temp ADD INDEX(POSkey)"
failfunction "$?"

#### Create excel date field
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE TableTurns_Temp ADD Exceldate INT(100) NOT NULL AFTER LocationID"
failfunction "$?"

#### Update excel date field
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE TableTurns_Temp set Exceldate = (((unix_timestamp(DOB) / 86400) + 25569) + (-5/24))"
failfunction "$?"

########################### fix check numbers (> 6 chars, start with '100') for PX CA join ###################

#### Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE TableTurns_Temp set POSkey = CONCAT_WS('', LocationID, Exceldate, CheckNumbers)"
failfunction "$?"

mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE TableTurns_Temp ADD INDEX(POSkey)"
failfunction "$?"

#### Insert into the LIVE tableTurns table
mysql  --login-path=local --silent -DSRG_Dev -N -e "INSERT INTO TableTurns_Live SELECT * FROM TableTurns_Temp"
failfunction "$?"

#### EMPTY EMPLOYEE TABLE
mysql  --login-path=local --silent -DSRG_Dev -N -e "TRUNCATE TABLE Employees_Live"
failfunction "$?"

#### Load the data from the latest file into the (LIVE) employees table
mysql  --login-path=local --silent -DSRG_Dev -N -e "Load data local infile '/home/ubuntu/db_files/incoming/Employees.csv' into table Employees_Live fields terminated by ',' lines terminated by '\n'"
failfunction "$?"

#### DUMP EXISTING CHECK DETAIL INCOMING TABLE
mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP TABLE IF EXISTS CheckDetail_Temp"
failfunction "$?"

#### MAKE A STRUCTURE COPY OF THE CHECK DETAIL TABLE
mysql  --login-path=local --silent -DSRG_Dev -N -e "CREATE TABLE CheckDetail_Temp AS (SELECT * FROM CheckDetail_Structure WHERE 1=0)"
failfunction "$?"

#### Load the data from the latest file into the (temp) check detail
mysql  --login-path=local --silent -DSRG_Dev -N -e "Load data local infile '/home/ubuntu/db_files/incoming/CheckDetail.csv' into table CheckDetail_Temp fields terminated by ',' lines terminated by '\n'"
failfunction "$?"

#### PUT TransactionDate INTO SQL FORMAT
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CheckDetail_Temp SET DOB = STR_TO_DATE(DOB, '%m/%d/%Y') WHERE STR_TO_DATE(DOB, '%m/%d/%Y') IS NOT NULL"
failfunction "$?"

#### Remove records where CheckNumber is null.
mysql  --login-path=local --silent -DSRG_Dev -N -e "DELETE from CheckDetail_Temp where CheckNumber = '0'"
failfunction "$?"

#### Change TransactionDate field to type date
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp CHANGE DOB DOB DATE"
failfunction "$?"

#### Create EMPLOYEE fields
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp ADD PayrollID VARCHAR( 26 ) first"
failfunction "$?"

mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp ADD firstname VARCHAR( 255 ) first"
failfunction "$?"

mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp ADD lastname VARCHAR( 255 ) first"
failfunction "$?"

#### Create POSkey field         ######################### INDEX #######################
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp ADD POSkey VARCHAR(30) first"
failfunction "$?"

mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp ADD INDEX(POSkey)"
failfunction "$?"

#### Create excel date fieldC
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp ADD Exceldate INT(100) NOT NULL AFTER LocationID"
failfunction "$?"

#### Update excel date field
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CheckDetail_Temp set Exceldate = (((unix_timestamp(DOB) / 86400) + 25569) + (-5/24))"
failfunction "$?"

#### Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CheckDetail_Temp SET POSkey = CONCAT_WS('', LocationID, Exceldate, CheckNumber)"
failfunction "$?"

#### DROP EXCELDATE FIELD
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp DROP COLUMN Exceldate"
failfunction "$?"

#### NAMES QUERIES/UPDATES 
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CheckDetail_Temp CDT 
	INNER JOIN Employees_Live EL ON (CDT.LocationID = EL.LocationID AND CDT.Base_EmployeeID = EL.EmployeeID) 
	SET CDT.lastname = EL.LastName, CDT.firstname = EL.FirstName, CDT.PayrollID = EL.PayrollID 
	WHERE CDT.lastname IS NULL AND CDT.firstname IS NULL"
failfunction "$?"


#### LEGACY BAR NAMES
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CheckDetail_Temp CDT
	INNER JOIN Employees_Legacy EL ON (CDT.LocationID = EL.LocationID AND CDT.Base_EmployeeID = EL.EmployeeID) 
	SET CDT.lastname = EL.LastName, CDT.firstname = EL.FirstName
	WHERE CDT.lastname IS NULL AND CDT.firstname IS NULL"
failfunction "$?"


#### ADD THE TABLETURNS FIELDS SO MATCHES 'LIVE' TABLE
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp ADD OpenTime datetime AFTER TransfersOut"
failfunction "$?"

mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp ADD CloseTime datetime AFTER OpenTime"
failfunction "$?"

mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp ADD MinutesOpen int(100) AFTER CloseTime"
failfunction "$?"

#### UPDATE LIVE CHECK DETAIL WITH LIVE TABLE TURNS AND TABLE NAMES
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CheckDetail_Temp CDT
	INNER JOIN TableTurns_Live TL 
	ON CDT.POSkey = TL.POSkey
	SET CDT.TableName = TL.TableName, 
	CDT.OpenTime = TL.OpenTime,
	CDT.CloseTime = TL.CloseTime,
	CDT.MinutesOpen = TIMESTAMPDIFF(minute, TL.OpenTime, TL.CloseTime)"
failfunction "$?"


#### NULL OPEN/CLOSE TIME IF ZERO VALUE IN LIVE CARD DETAIL
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CheckDetail_Temp CDT SET CDT.OpenTime = CDT.DOB WHERE CDT.OpenTime < '2001-01-01'"
failfunction "$?"

mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CheckDetail_Temp CDT SET CDT.CloseTime = CDT.DOB WHERE CDT.CloseTime < '2001-01-01'"
failfunction "$?"

##### ADD INCOMING CHECK DETAIL DATA TO LIVE TABLE
mysql  --login-path=local --silent -DSRG_Dev -N -e "INSERT INTO CheckDetail_Live SELECT * FROM CheckDetail_Temp"
failfunction "$?"





