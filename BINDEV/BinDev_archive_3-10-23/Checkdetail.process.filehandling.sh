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

################################### BACK UP THE 3 LIVE TABLES FOR SAFTEY #####################################
# rm -f /home/ubuntu/db_files/Checkdetail.3tables.bu.sql
# mysqldump -uroot -ps3r3n1t33 SRG_Prod CheckDetail_Live Employees_Live TableTurns_Live >  /home/ubuntu/db_files/Checkdetail.3tables.bu.sql
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


###### FIRST WE GET THE FILES FROM PX
# ( "/home/ubuntu/bin/CRON.lftp.ctuit.daily.sh" )
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'CTUIT FILES RETRIEVED FROM BERTHA FTP SITE'
sleep 5s


###### TABLETURNS PROCESSING AS A SUBROUTINE
# ( "/home/ubuntu/bin/CD.process.tableturns.sh" )
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'TABLETURNS PROCESSED'
sleep 5s


###### EMPLOYEES PROCESSING AS A SUBROUTINE
# ( "/home/ubuntu/bin/CD.process.employees.sh" )
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'EMPLOYEES PROCESSED'
sleep 5s





################ CHECKDETAIL SECTION #########################################
## REMOVE (1) HEADER ROW AND MERGE (IF NECCESSARY) INCOMING CARD ACTIVITY CSVs
## INTO SINGLE CARD ACTIVITY FILE IN DB_FILES/CTUIT
for file in /home/ubuntu/db_files/incoming/ctuit/*Checkdetail*.csv
  do
	#### MAKE A COPY OF THE FILE IN BACKUP DIR
	cp "$file" //home/ubuntu/db_files/incoming/backup/ctuit/
	tail -n+2 "$file"  >> /home/ubuntu/db_files/incoming/ctuit/Infile.Chkdetail.csv
	rm "$file"
  done
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

#### DUMP EXISTING CHECK DETAIL INCOMING TABLE
mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP TABLE IF EXISTS CheckDetail_Temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

#### MAKE A STRUCTURE COPY OF THE CHECK DETAIL TABLE
mysql  --login-path=local --silent -DSRG_Dev -N -e "CREATE TABLE CheckDetail_Temp AS (SELECT * FROM CheckDetail_Structure WHERE 1=0)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

#### Load the data from the latest file into the (temp) check detail
mysql  --login-path=local --silent -DSRG_Dev -N -e "Load data local infile '/home/ubuntu/db_files/incoming/ctuit/Infile.Chkdetail.csv' into table CheckDetail_Temp fields terminated by ',' lines terminated by '\n'"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

## CHECKDETAIL ##### DELETE OLD CHECKDETAIL FILE TO MAKE READY FOR NEXT TIME
rm /home/ubuntu/db_files/incoming/ctuit/Infile.Chkdetail.csv
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


#### PUT TransactionDate INTO SQL FORMAT
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CheckDetail_Temp SET DOB = STR_TO_DATE(DOB, '%m/%d/%Y') WHERE STR_TO_DATE(DOB, '%m/%d/%Y') IS NOT NULL"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

#### Remove records where CheckNumber is null.
mysql  --login-path=local --silent -DSRG_Dev -N -e "DELETE from CheckDetail_Temp where CheckNumber = '0'"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

#### Change TransactionDate field to type date
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp CHANGE DOB DOB DATE"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

#### Create EMPLOYEE fields
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp ADD PayrollID VARCHAR( 26 ) first"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp ADD firstname VARCHAR( 255 ) first"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp ADD lastname VARCHAR( 255 ) first"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

#### Create POSkey field         ######################### INDEX #######################
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp ADD POSkey VARCHAR(30) first"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp ADD INDEX(POSkey)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

#### Create excel date fieldC
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp ADD Exceldate INT(100) NOT NULL AFTER LocationID"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

#### Update excel date field
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CheckDetail_Temp set Exceldate = (((unix_timestamp(DOB) / 86400) + 25569) + (-5/24))"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

#### Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CheckDetail_Temp SET POSkey = CONCAT_WS('', LocationID, Exceldate, CheckNumber)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

#### DROP EXCELDATE FIELD
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp DROP COLUMN Exceldate"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'CHECKDETAIL TEMP TABLE POPULATED AND REVISED'


#### NAMES QUERIES/UPDATES 
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CheckDetail_Temp CDT 
	INNER JOIN Employees_Live EL ON (CDT.LocationID = EL.LocationID AND CDT.Base_EmployeeID = EL.EmployeeID) 
	SET CDT.lastname = EL.LastName, CDT.firstname = EL.FirstName, CDT.PayrollID = EL.PayrollID 
	WHERE CDT.lastname IS NULL AND CDT.firstname IS NULL"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


#### LEGACY BAR NAMES
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CheckDetail_Temp CDT
	INNER JOIN Employees_Legacy EL ON (CDT.LocationID = EL.LocationID AND CDT.Base_EmployeeID = EL.EmployeeID) 
	SET CDT.lastname = EL.LastName, CDT.firstname = EL.FirstName
	WHERE CDT.lastname IS NULL AND CDT.firstname IS NULL"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


#### ADD THE TABLETURNS FIELDS SO MATCHES 'LIVE' TABLE
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp ADD OpenTime datetime AFTER TransfersOut"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp ADD CloseTime datetime AFTER OpenTime"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CheckDetail_Temp ADD MinutesOpen int(100) AFTER CloseTime"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

#### UPDATE TEMP CHECK DETAIL WITH TABLE TURNS AND TABLE NAMES
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CheckDetail_Temp CDT
	INNER JOIN TableTurns_Live TL 
	ON CDT.POSkey = TL.POSkey
	SET CDT.TableName = TL.TableName, 
	CDT.OpenTime = TL.OpenTime,
	CDT.CloseTime = TL.CloseTime,
	CDT.MinutesOpen = TIMESTAMPDIFF(minute, TL.OpenTime, TL.CloseTime)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'TABLE TURNS AND NAMES UPDATED IN TEMP CHECKDETAIL TABLE'


#### NULL OPEN/CLOSE TIME IF ZERO VALUE IN LIVE CARD DETAIL
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CheckDetail_Temp CDT SET CDT.OpenTime = CDT.DOB WHERE CDT.OpenTime < '2001-01-01'"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CheckDetail_Temp CDT SET CDT.CloseTime = CDT.DOB WHERE CDT.CloseTime < '2001-01-01'"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


##### ADD INCOMING CHECK DETAIL DATA TO LIVE TABLE
mysql  --login-path=local --silent -DSRG_Dev -N -e "INSERT INTO CheckDetail_Live SELECT * FROM CheckDetail_Temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

## CHECKDETAIL ##### REMOVE DUPLICATE ROWS FROM CHECKDETAIL LIVE TABLE
mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP TABLE IF EXISTS CheckDetail_Live_temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
mysql  --login-path=local --silent -DSRG_Dev -N -e "CREATE table CheckDetail_Live_temp LIKE CheckDetail_Live"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
mysql  --login-path=local --silent -DSRG_Dev -N -e "INSERT INTO CheckDetail_Live_temp SELECT * FROM CheckDetail_Live GROUP BY POSkey"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP table CheckDetail_Live"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
mysql  --login-path=local --silent -DSRG_Dev -N -e "RENAME table CheckDetail_Live_temp TO CheckDetail_Live"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


echo '======================================================'
echo 'CHECKDETAIL LIVE TABLE POPULATED WITH MOST RECENT DATA DEDUPED USING POSKEY GROUPED'
















