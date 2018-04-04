#! //bin/bash
# LOG IT TO SYSLOG

############################################################################################
################## THIS SCRIPT SHOULD DO ITS WORK IN A NON PRODUCTION DIRECTORY !!!!!
############################################################################################
########## ADD ERROR HANDLING AT EACH FAIL POINT ###########################################


# exec 1> >(logger -s -t $(basename $0)) 2>&1

#UNCOMMENT NEXT FOR VERBOSE
#set -x
##### HALT AND CATCH FIRE IF ANY COMMANd FAILS
set -e


##### BACK IT UP !!!!!!
# mysqldump  --login-path=local -uroot SRG_Dev > /home/ubuntu/db_files/SRG_Dev_bu.sql

############################################################################################
#### WE WILl MAKE / USE COPIES OF REAL DATA FILES WHILE THIS SCRIPT IS IN DEV #############

# cp /home/ubuntu/db_files/incoming/px/CardActivity*.csv /home/ubuntu/db_files/incoming/px/dev/

#### YEARLY DATA FILES HAVE ONE HEADER ROW (tail -n+2)
#### DAILY DATA FILES HAVE TWO HEADER ROWS (tail -n+3)
## REMOVE (1) HEADER ROW AND MERGE (IF NECCESSARY) INCOMING CARD ACTIVITY CSVs
## INTO SINGLE CARD ACTIVITY FILE IN DB_FILES
   for file in /home/ubuntu/db_files/incoming/px/dev/guests.csv
  do
      tail -n+2 "$file"  >> /home/ubuntu/db_files/incoming/px/dev/guest.csv
  done
 echo 'INCOMING -dev- guest DATA FILES CLEANED AND MERGED'



# ARCHIVE THE DOWNLOADED PAYTRONIX FILES
### copy them for now until archive set up - **** NOT IN DEV ***** -
#  mv /home/ubuntu/db_files/incoming/px/*.csv /home/ubuntu/db_files/archive/
### archive trials
# tar -
# echo 'ORIGINAL FILES ARCHIVED, DROPPING -OLD- TEMP TABLE'

# Load the data from the latest file into the (temp) CardActivity table
mysql  --login-path=local --silent -DSRG_Dev -N -e "Load data local infile '/home/ubuntu/db_files/incoming/px/dev/guest.csv' into table Guests fields terminated by ',' lines terminated by '\n'"
echo 'Guests loaded'

# DELETE THE WORKING CARDACTIVITY CSV (from dev folder)
# rm -f /home/ubuntu/db_files/incoming/px/dev/CardActivity.csv

### DEV FOR YEARLY FILES
#mv /home/ubuntu/db_files/incoming/px/dev/*.csv /home/ubuntu/db_files/archive/dev/
# echo 'CARDACTIVITY -dev- DATA FILES DELETED'
 
### INDEX CARD TEMPLATE AND TRANSACTIONTYPE, CardNumber
# mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp ADD INDEX(TransactionType)"
# mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp ADD INDEX(CardNumber)"
# echo 'CARDACTIVITY -dev- TransactionType and CardNumber indexed'








