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
#### ADD "Email Failed", "Account Status", "Phone number", "birthday" fields ON Guest Analysis Report - Customize Output PAGE 
#### REPLACE " with {nothing}
############# there are commas in fields like address etc... fucking things up... alternate delimiter only 200 accounts


# DELETE THE PREVIOUS INFILE FILE
rm -f /home/ubuntu/db_files/incoming/px/guests.infile.csv
### need to remove another line?

   for file in /home/ubuntu/db_files/incoming/px/guests.csv
  do
      tail -n+2 "$file"  >> /home/ubuntu/db_files/incoming/px/guests.infile.csv
  done
 echo 'INCOMING guest DATA FILES CLEANED AND MERGED'

## TRUNCATE GUESTS TABLE BEFORE LOADING W NEW
# Delete Temp table if it exists
mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP TABLE IF EXISTS Guests"
echo 'GUESTS TABLE DROPPED, STARTING NEW GUESTS TABLE CREATION'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_Dev -N -e "CREATE TABLE Guests LIKE Guests_Structure"
echo 'Guests TABLE CREATED, LOADING DATA FILE TO Guests TABLE'


# Load the data from the latest file into the (temp) CardActivity table
mysql  --login-path=local --silent -DSRG_Dev -N -e "Load data local infile '/home/ubuntu/db_files/incoming/px/guests.infile.csv' into table Guests fields terminated by ',' lines terminated by '\n'"
echo 'Guests loaded'










