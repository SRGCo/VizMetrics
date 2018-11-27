#! /bin/bash

# UNCOMMENT TO LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# Next line turns echo on
#set -x

################ EMPLOYEES SECTION #########################################

for file in /home/ubuntu/db_files/incoming/ctuit/*Employees*.csv
  do
	#### MAKE A COPY OF THE FILE IN BACKUP DIR
	cp "$file" //home/ubuntu/db_files/incoming/backup/ctuit/
	tail -n+2 "$file"  >> /home/ubuntu/db_files/incoming/ctuit/Infile.Employee.csv
	rm "$file"
  done
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


########################## CHECK THE WHOLE EMPLOYEE FLOW ####################
## EMPLOYEES ##### Load the data from the latest file into the (LIVE) employees table
mysql  --login-path=local --silent -DSRG_Dev -N -e "Load data local infile '/home/ubuntu/db_files/incoming/ctuit/Infile.Employee.csv' into table Employees_Live fields terminated by ',' lines terminated by '\n'"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
## EMPLOYEES ##### DELETE OLD EMPLOYEES FILE TO MAKE READY FOR NEXT TIME
rm /home/ubuntu/db_files/incoming/ctuit/Infile.Employee.csv
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

echo 'FULL SET OF EMPLOYEE DATA PROCESSED AND DEDUPED'

