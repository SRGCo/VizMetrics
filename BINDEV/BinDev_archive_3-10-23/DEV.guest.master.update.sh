#! //bin/bash
# LOG IT TO SYSLOG

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


# exec 1> >(logger -s -t $(basename $0)) 2>&1

#UNCOMMENT NEXT FOR VERBOSE
#set -x
##### HALT AND CATCH FIRE IF ANY COMMANd FAILS
# set -e


################# TABLETURNS ##############################
## REMOVE (2) HEADER ROW AND MERGE (IF NECCESSARY) INCOMING GUESTS CSVs
## INTO SINGLE CARD ACTIVITY FILE IN DB_FILES/incoming/px
for file in /home/ubuntu/db_files/incoming/px/Guest*.csv
  do
	#### MAKE A COPY OF THE FILE IN BACKUP DIR
	cp "$file" //home/ubuntu/db_files/incoming/px/backup/	
     	 tail -n+3 "$file"  >> /home/ubuntu/db_files/incoming/px/guests.infile.csv	
	rm "$file"
done
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'INCOMING guest DATA FILES CLEANED AND MERGED'

## TRUNCATE GUESTS TABLE BEFORE LOADING W NEW
# Delete Temp table if it exists
mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP TABLE IF EXISTS Guests_temp"
echo 'GUESTS TEMP NEW TABLE DROPPED, STARTING NEW GUESTS TEMP NEW TABLE CREATION'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_Dev -N -e "CREATE TABLE Guests_temp LIKE Guests_Structure"
echo 'Guests_temp TABLE CREATED, LOADING DATA FILE TO Guests_temp TABLE'

# Load the data from the latest file into the (temp) CardActivity table
mysql  --login-path=local --silent -DSRG_Dev -N -e "Load data local infile '/home/ubuntu/db_files/incoming/px/guests.infile.csv' into table Guests_temp fields terminated by ','  lines terminated by '\n'"
echo 'Guests_temp loaded'


### UPDATE TO NULLS FOR ZERO DATES FOR ANNIVERSARY
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE Guests_temp SET AnniversaryDate = NULL WHERE CAST(AnniversaryDate AS CHAR(10)) = '0000-00-00'"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

## UPDATE TO NULLS FOR ZERO DATES FOR REG DATE
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE Guests_temp SET RegisterDate = NULL WHERE CAST(RegisterDate AS CHAR(10)) = '0000-00-00'"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

### UPDATE TO NULLS FOR ZERO DATES FOR ENROLL DATE
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE Guests_temp SET EnrollDate = NULL WHERE CAST(EnrollDate AS CHAR(10)) = '0000-00-00'"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

### UPDATE TO NULLS FOR ZERO DATES FOR BIRTHDATE
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE Guests_temp SET DateofBirth = NULL WHERE CAST(DateofBirth AS CHAR(10)) = '0000-00-00'"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


####### IF THIS CARDNUMBER ALREADY EXISTS IN GUESTS MASTER DELETE IT
####### INSERT DATA FROM TEMP BY CARDNUMBER
####### UPDATE THE TOWN INFO BY CARDNUMBER IN GUESTS MASTER
mysql  --login-path=local -DSRG_Dev -N -e "SELECT DISTINCT(CardNumber) FROM Guests_temp" | while read -r CardNumber;
do
	# DELETE CARDS FROM GUEST MASTER IF ALREADY EXISTS
	mysql  --login-path=local --silent -DSRG_Dev -N -e "DELETE from Guests_Master WHERE CardNumber = '$CardNumber'"
	# INSERT LATEST INFO ABOUT THIS GUEST
	mysql  --login-path=local -DSRG_Dev -N -e "INSERT INTO Guests_Master SELECT Guests_temp.*,NULL,NULL,NULL FROM Guests_temp WHERE CardNumber = '$CardNumber'"
	#### UPDATE TOWN INFO IN GUESTS_MASTER FOR THIS CARD
	mysql  --login-path=local -DSRG_Dev -N -e "SELECT Zip FROM Guests_Master WHERE CardNumber = '$CardNumber'" | while read -r Zip;
	do
		mysql  --login-path=local -DSRG_Dev -N -e "SELECT Population, AvgIncome, Town FROM MA_Zips WHERE Zip = '$Zip'" | while read -r population income town;
		do
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Guests_Master SET Population = '$population', AvgIncome = '$income', Town = '$town' WHERE CardNumber = '$CardNumber'"
		done	
	done 

done
echo 'GUESTS_MASTER TABLE UPDATED WITH NEW GUEST INFO'


# DELETE CARDS WITH NO ACCOUNT INFO (not active)
# mysql  --login-path=local --silent -DSRG_Dev -N -e "DELETE from Guests_temp WHERE AccountStatus = 'EXISTS'"
# echo 'non active cards removed'

# DELETE CURRENT INFILE TO READY FOR NEXT RUN
rm -f   /home/ubuntu/db_files/incoming/px/guests.infile.csv










