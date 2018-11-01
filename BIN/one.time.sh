#! /bin/bash
### OK 8-29-18 #####

# UNCOMMENT TO LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# Next line turns echo on
#set -x

####### USES CTUIT EXPORTS #########
## 1 ## TableTurn [all company by date][TableTurns.raw.csv]
## 2 ## Employees
## 3 ## CheckDetail - Full by date [CheckDetail.update.raw.csv]

########### FUNCTIONS #####################################
################# ERROR CATCHING ##########################
failfunction()
{
	local scriptname=$(basename -- "$0") 
	local returned_value=$1
	local lineno=$2
	local bash_error=$3

	if [ "$returned_value" != 0 ]
	then 
 		echo "$scriptname failed on $bash_error at line: $lineno"
        	mail -s "VizMetrics Server Alert"  it@serenitee.com <<< 'Script '"$scriptname"' failed on '"$bash_error"' at Line: '"$lineno"
        	exit
	fi
}



################# TABLETURNS ##############################
## REMOVE (1) HEADER ROW AND MERGE (IF NECCESSARY) INCOMING CARD ACTIVITY CSVs
## INTO SINGLE CARD ACTIVITY FILE IN DB_FILES/CTUIT
for file in /home/ubuntu/db_files/incoming/ctuit/*Tableturns*.csv
  do
	#### MAKE A COPY OF THE FILE IN BACKUP DIR
	cp "$file" //home/ubuntu/db_files/incoming/backup/ctuit/	
	tail -n+2 "$file"  >> /home/ubuntu/db_files/incoming/ctuit/Infile.Tableturn.csv		
	rm "$file"
done
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

### Drop and recreate temp tableturns table
mysql  --login-path=local --silent -DSRG_Prod -N -e "DROP TABLE IF EXISTS TableTurns_Temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

### Create a empty copy of TableTurns_Temp table from TableTurns_Structure table
mysql  --login-path=local --silent -DSRG_Prod -N -e "CREATE TABLE TableTurns_Temp AS (SELECT * FROM TableTurns_Structure WHERE 1=0)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

### Load the data from the latest file into the (temp) TableTurns table ########################
mysql  --login-path=local --silent -DSRG_Prod -N -e "Load data local infile '/home/ubuntu/db_files/incoming/ctuit/Infile.Tableturn.csv' into table TableTurns_Temp fields terminated by ',' lines terminated by '\n'"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

## Tableturns ## DELETE OLD TABLETURNS FILE TO MAKE READY FOR NEXT TIME
rm /home/ubuntu/db_files/incoming/ctuit/Infile.Tableturn.csv
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

### PUT DOB INTO SQL FORMAT
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE TableTurns_Temp SET DOB= STR_TO_DATE(DOB, '%c/%e/%Y') WHERE STR_TO_DATE(DOB, '%c/%e/%Y') IS NOT NULL"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

### Change DOB field to type date
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE TableTurns_Temp CHANGE DOB DOB DATE"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

#### Change OpenTime & CloseTime to SQL format
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE TableTurns_Temp SET CloseTime= STR_TO_DATE(CloseTime, '%m/%e/%Y %l:%i:%s %p') WHERE STR_TO_DATE(CloseTime, '%m/%e/%Y %l:%i:%s %p')"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE TableTurns_Temp SET OpenTime= STR_TO_DATE(OpenTime, '%m/%e/%Y %l:%i:%s %p') WHERE STR_TO_DATE(OpenTime,  '%m/%e/%Y %l:%i:%s %p')"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


##### CHANGE CLOSETIME FIELD TO DATETIME #################
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE TableTurns_Temp CHANGE CloseTime CloseTime DATETIME NOT NULL"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

#### Create POSkey field          ######################### INDEX #######################
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE TableTurns_Temp ADD POSkey VARCHAR(30) first"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE TableTurns_Temp ADD INDEX(POSkey)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

#### Create excel date field
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE TableTurns_Temp ADD Exceldate INT(100) NOT NULL AFTER LocationID"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

#### Update excel date field
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE TableTurns_Temp set Exceldate = (((unix_timestamp(DOB) / 86400) + 25569) + (-5/24))"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

#### fix check numbers (> 6 chars, start with '100') for PX CA join #######
#### Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE TableTurns_Temp set POSkey = CONCAT_WS('', LocationID, Exceldate, CheckNumbers)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

#### INDEX POSkey
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE TableTurns_Temp ADD INDEX(POSkey)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

#### Insert into the LIVE tableTurns table
mysql  --login-path=local --silent -DSRG_Prod -N -e "INSERT INTO TableTurns_Live SELECT * FROM TableTurns_Temp GROUP BY POSkey"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'TABLETURNS DATA INSERTED INTO LIVE TABLE GROUPED BY POSKEY TO AVOID DUPLICATE ENTRIES'

