#! //bin/bash
# LOG IT TO SYSLOG

############################################################################################
################## THIS SCRIPT SHOULD DO ITS WORK IN A NON PRODUCTION DIRECTORY !!!!!
############################################################################################
########## ADD ERROR HANDLING AT EACH FAIL POINT ###########################################


# exec 1> >(logger -s -t $(basename $0)) 2>&1

#UNCOMMENT NEXT FOR VERBOSE
set -x
##### HALT AND CATCH FIRE IF ANY COMMANd FAILS
set -e


#### USE PX REPORT Guest Analysis Report
#### WITH FILTER ~ALL rewards accounts (all statuses) use for VM
#### ADD "Email Failed", "Account Status", "Phone number", "date of birth" fields ON Guest Analysis Report - Customize Output PAGE (run report)
#### download tsv

# DELETE THE PREVIOUS INFILE FILE
rm -f /home/ubuntu/db_files/incoming/px/guests.infile.tsv

# REMOVE HEADERS
for file in /home/ubuntu/db_files/incoming/px/Guests.tsv
  do
      tail -n+3 "$file"  >> /home/ubuntu/db_files/incoming/px/guests.infile.tsv
  done
echo 'INCOMING guest DATA FILES CLEANED AND MERGED'

## TRUNCATE GUESTS TABLE BEFORE LOADING W NEW
# Delete Temp table if it exists
mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP TABLE IF EXISTS Guests_temp"
echo 'GUESTS TABLE DROPPED, STARTING NEW GUESTS TABLE CREATION'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_Dev -N -e "CREATE TABLE Guests_temp LIKE Guests_Structure"
echo 'Guests_temp TABLE CREATED, LOADING DATA FILE TO Guests_temp TABLE'

# Load the data from the latest file into the (temp) CardActivity table
mysql  --login-path=local --silent -DSRG_Dev -N -e "Load data local infile '/home/ubuntu/db_files/incoming/px/guests.infile.tsv' into table Guests_temp lines terminated by '\n'"
echo 'Guests_temp loaded'


# DELETE CARDS WITH NO ACCOUNT INFO (not active)
mysql  --login-path=local --silent -DSRG_Dev -N -e "DELETE from Guests_temp WHERE AccountStatus = 'EXISTS'"
echo 'non active cards removed'

## TRUNCATE GUESTS TABLE BEFORE LOADING W NEW
# Delete Temp table if it exists
mysql  --login-path=local --silent -DSRG_Dev -N -e "TRUNCATE TABLE Guests_Master"
echo 'Guests_Master Emptied'

# Add Population, avg income, Town to Guests_Master table joined from MA_Zips table
mysql  --login-path=local -DSRG_Dev -N -e "INSERT INTO Guests_Master SELECT GT.*, MZ.Population, MZ.AvgIncome, MZ.Town FROM Guests_temp AS GT 
						LEFT JOIN MA_Zips as MZ ON MZ.Zip = GT.Zip"
echo 'Guests_Master Updated w town data'

# Delete guests file
# rm -f /home/ubuntu/db_files/incoming/px/Guests.tsv










