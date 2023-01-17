#! //bin/bash
# LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1


# UNCOMMENT NEXT FOR VERBOSE
set -x


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


##### HALT AND CATCH FIRE IF ANY COMMAND FAILS FROM HERE ON
set -e

################ EMPLOYEES SECTION #########################################

for file in /home/ubuntu/db_files/incoming/employees/*Employees*.csv
  do
	#### MAKE A COPY OF THE FILE IN BACKUP DIR
	cp "$file" //home/ubuntu/db_files/incoming/employees/backup/ctuit/
	tail -n+2 "$file"  >> /home/ubuntu/db_files/incoming/employees/Infile.Employee.csv
	rm "$file"
  done
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


########################## CHECK THE WHOLE EMPLOYEE FLOW ####################
## EMPLOYEES ##### Load the data from the latest file into the (LIVE) employees table




## EMPLOYEES ##### REMOVE DUPLICATE ROWS FROM EMPLOYEES LIVE TABLE
mysql  --login-path=local --silent -DSRG_Prod -N -e "DROP TABLE IF EXISTS Employees_Live_temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
mysql  --login-path=local --silent -DSRG_Prod -N -e "CREATE table Employees_Live_temp LIKE Employees_Live_structure"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


mysql  --login-path=local --silent -DSRG_Prod -N -e "Load data local infile '/home/ubuntu/db_files/incoming/ctuit/Infile.Employee.csv' into table Employees_Live_temp fields terminated by ',' lines terminated by '\n'"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
## EMPLOYEES ##### DELETE OLD EMPLOYEES FILE TO MAKE READY FOR NEXT TIME
rm /home/ubuntu/db_files/incoming/ctuit/Infile.Employee.csv
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_Prod -N -e "DROP table Employees_Live"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
mysql  --login-path=local --silent -DSRG_Prod -N -e "RENAME table Employees_Live_temp TO Employees_Live"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

echo 'Employees_Live now has the latest employees list'

echo 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'





