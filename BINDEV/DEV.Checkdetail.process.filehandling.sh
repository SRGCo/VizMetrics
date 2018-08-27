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

############################# GET CTUIT FILES FROM BERTHA ###################
lftp -e 'set net:timeout 10;set ssl:verify-certificate no; set ftp:ssl-protect-data true;' -u VM_ctuit,Serenitee185Ctuit 50.195.41.122  << EOF
	lcd /home/ubuntu/db_files/incoming/ctuit
	mget *
	mirror --reverse --no-recursion /home/ubuntu/db_files/incoming/ctuit /backup
	mrm *csv
bye
EOF
#failfunction "$?"

################# TABLETURNS ##############################
## REMOVE (1) HEADER ROW AND MERGE (IF NECCESSARY) INCOMING CARD ACTIVITY CSVs
## INTO SINGLE CARD ACTIVITY FILE IN DB_FILES/CTUIT
for file in /home/ubuntu/db_files/incoming/ctuit/*Tableturns*.csv
  do
	#### MAKE A COPY OF THE FILE IN BACKUP DIR
	cp "$file" //home/ubuntu/db_files/incoming/backup/ctuit/
	failfunction "$?"
	tail -n+2 "$file"  >> /home/ubuntu/db_files/incoming/ctuit/Infile.Tableturns.csv
	failfunction "$?"
	rm "$file"
	failfunction "$?"
  done
echo 'INCOMING TableTurns DATA FILES CLEANED AND MERGED, ARCHIVING ORIGINAL FILES'


### Drop and recreate temp tableturns table
mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP TABLE IF EXISTS TableTurns_Temp"
failfunction "$?"

### Create a empty copy of TableTurns_Temp table from TableTurns_Structure table
mysql  --login-path=local --silent -DSRG_Dev -N -e "CREATE TABLE TableTurns_Temp AS (SELECT * FROM TableTurns_Structure WHERE 1=0)"
failfunction "$?"

### Load the data from the latest file into the (temp) TableTurns table ########################
mysql  --login-path=local --silent -DSRG_Dev -N -e "Load data local infile '/home/ubuntu/db_files/incoming/ctuit/Infile.Tableturns.csv' into table TableTurns_Temp fields terminated by ',' lines terminated by '\n'"
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

#### INDEX POSkey
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE TableTurns_Temp ADD INDEX(POSkey)"
failfunction "$?"

#### Insert into the LIVE tableTurns table
# mysql  --login-path=local --silent -DSRG_Dev -N -e "INSERT INTO TableTurns_Live SELECT * FROM TableTurns_Temp"


## Tableturns ## DELETE OLD TABLETURNS FILE TO MAKE READY FOR NEXT TIME
rm /home/ubuntu/db_files/incoming/ctuit/Infile.Tableturns.csv
failfunction "$?"
























