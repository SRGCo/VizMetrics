#! //bin/bash
# LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# UNCOMMENT NEXT FOR VERBOSE
# set -x
##### HALT AND CATCH FIRE IF ANY COMMAND FAILS
# set -e

##### USE time command to calc runtime "time DEV.cd.ca.into.master.sh"

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

################# PROCESS EXCHANGES
## REMOVE (1) HEADER ROW AND MERGE (IF NECCESSARY) INCOMING EXCHANGES CSVs
## INTO SINGLE CARD ACTIVITY FILE IN DB_FILES
for file in /home/ubuntu/db_files/incoming/px/MediaExchanges*.csv
  do
	#### MAKE A COPY OF THE FILE IN BACKUP DIR
	cp "$file" //home/ubuntu/db_files/incoming/px/backup/
	tail -n+2 "$file"  >> /home/ubuntu/db_files/incoming/px/Infile.MediaExchanges.csv
	rm "$file"
  done || trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'INCOMING EXCHANGES DATA FILES BACKEDUP, CLEANED AND MERGED'

## TRUNCATE GUESTS TABLE BEFORE LOADING W NEW
# Delete Temp table if it exists
mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP TABLE IF EXISTS Px_exchanges_temp"
echo 'PX EXCHANGES TEMP TABLE DROPPED, STARTING NEW PX EXCHANGES TEMP TABLE CREATION'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_Dev -N -e "CREATE TABLE Px_exchanges_temp LIKE Px_exchanges_structure"
echo 'PX EXCHANGES TEMP TABLE CREATED, LOADING DATA FILE TO PX EXCHANGES TEMP TABLE'

# Load the data from the latest file into the (temp) CardActivity table
mysql  --login-path=local --silent -DSRG_Dev -N -e "Load data local infile '/home/ubuntu/db_files/incoming/px/Infile.MediaExchanges.csv' into table Px_exchanges_temp fields terminated by ','  lines terminated by '\n'"
echo 'PX EXCHANGES TEMP loaded'
	
#Load the temp data into the live table
mysql  --login-path=local -DSRG_Dev -N -e "INSERT INTO Px_exchanges SELECT * FROM Px_exchanges_temp WHERE CardNumber = '$CardNumber'"
echo 'PX EXCHANGES TABLE LOADED WITH DATA FROM TEMP TABLE'


# DELETE CURRENT INFILE TO READY FOR NEXT RUN
rm -f   /home/ubuntu/db_files/incoming/px/Infile.MediaExchanges.csv

################# PROCESS EXCHANGES WITH PHP SUBROUTINE
( "/home/ubuntu/bindev/DEV.px.exchanges.process.php" )
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER- EXCHANGED CARDS PROCESS/FIXED, ACCOUNT STATUS UPDATED TO -Exchange-'

