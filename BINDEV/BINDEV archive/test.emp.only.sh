#! /bin/bash
### OK 8-29-18 #####

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
#rm -f /home/ubuntu/db_files/Checkdetail.3tables.bu.sql
#mysqldump -uroot -ps3r3n1t33 SRG_Dev CheckDetail_Live Employees_Live TableTurns_Live >  /home/ubuntu/db_files/Checkdetail.3tables.bu.sql
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


############################# GET CTUIT FILES FROM BERTHA THEN BACK THEM UP ON BERTHA ###################
lftp -e 'set net:timeout 10;set ssl:verify-certificate no; set ftp:ssl-protect-data true;' -u VM_ctuit,Serenitee185Ctuit 50.195.41.122  << EOF
	lcd /home/ubuntu/db_files/incoming/ctuit
	mget *
	mirror --reverse --no-recursion /home/ubuntu/db_files/incoming/ctuit /backup
	mrm *csv
bye
EOF
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR



################ EMPLOYEES SECTION #########################################

for file in /home/ubuntu/db_files/incoming/ctuit/*Employees*.csv
  do
	#### MAKE A COPY OF THE FILE IN BACKUP DIR
	cp "$file" //home/ubuntu/db_files/incoming/backup/ctuit/
	tail -n+2 "$file"  >> /home/ubuntu/db_files/incoming/ctuit/Infile.Employee.csv
	rm "$file"
  done
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MOST RECENT INCOMING Employees DATA FILE CLEANED'

## EMPLOYEES ##### EMPTY EMPLOYEE TABLE
mysql  --login-path=local --silent -DSRG_Dev -N -e "TRUNCATE TABLE Employees_Live"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

## EMPLOYEES ##### Load the data from the latest file into the (LIVE) employees table
mysql  --login-path=local --silent -DSRG_Dev -N -e "Load data local infile '/home/ubuntu/db_files/incoming/ctuit/Infile.Employee.csv' into table Employees_Live fields terminated by ',' lines terminated by '\n'"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

## EMPLOYEES ##### REMOVE DUPLICATE ROWS FROM EMPLOYEES LIVE TABLE
mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP TABLE IF EXISTS Employees_Live_temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
mysql  --login-path=local --silent -DSRG_Dev -N -e "CREATE table Employees_Live_temp LIKE Employees_Live"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
mysql  --login-path=local --silent -DSRG_Dev -N -e "INSERT INTO Employees_Live_temp SELECT * FROM Employees_Live GROUP BY EmployeeID"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP table Employees_Live"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
mysql  --login-path=local --silent -DSRG_Dev -N -e "RENAME table Employees_Live_temp TO Employees_Live"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

## EMPLOYEES ##### DELETE OLD EMPLOYEES FILE TO MAKE READY FOR NEXT TIME
rm /home/ubuntu/db_files/incoming/ctuit/Infile.Employee.csv
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR



