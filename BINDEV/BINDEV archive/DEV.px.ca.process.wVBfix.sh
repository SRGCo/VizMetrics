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



##### BACK IT UP AFTER DUMPING OLD BACKUP (-f no error if file does not exist)

## REMOVE (1) HEADER ROW AND MERGE (IF NECCESSARY) INCOMING CARD ACTIVITY CSVs
## INTO SINGLE CARD ACTIVITY FILE IN DB_FILES
   for file in /home/ubuntu/db_files/incoming/px/CardActivity*.csv
  do
#### MAKE A COPY OF THE FILE IN BACKUP DIR
	# cp "$file" //home/ubuntu/db_files/incoming/px/backup/
	tail -n+2 "$file"  >> /home/ubuntu/db_files/incoming/px/Infile.CardActivity.csv
  done
echo 'INCOMING -dev- DATA FILES CLEANED AND MERGED, ARCHIVING ORIGINAL FILES'


# Delete Temp table if it exists
mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP TABLE IF EXISTS CardActivity_Temp"
echo 'TEMP TABLE DROPPED, STARTING NEW TEMP TABLE CREATION'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_Dev -N -e "CREATE TABLE CardActivity_Temp LIKE CardActivity_Structure"
echo 'TEMP TABLE CREATED, LOADING DATA FILE TO TEMP TABLE'

# Load the data from the latest file into the (temp) CardActivity table
mysql  --login-path=local --silent -DSRG_Dev -N -e "Load data local infile '/home/ubuntu/db_files/incoming/px/Infile.CardActivity.csv' into table CardActivity_Temp fields terminated by ',' lines terminated by '\n'"
echo 'CARDACTIVITY DATA LOADED INTO CardActivity_Temp'



############## WE can do an 



# DELETE THE WORKING CARDACTIVITY CSVS
#rm -f /home/ubuntu/db_files/incoming/px/CardActivity*.csv
rm -f /home/ubuntu/db_files/incoming/px/Infile.CardActivity.csv




### INDEX CARD TEMPLATE AND TRANSACTIONTYPE, CardNumber
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp ADD INDEX(TransactionType)"
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp ADD INDEX(CardNumber)"
echo 'CARDACTIVITY -dev- TransactionType and CardNumber indexed'


echo 'DELETING EXTRANEOUS RECORDS BY TRANSACTION TYPES'
### REMOVE ANY/ALL RECORDS THAT ARE NOT WORTH PROCESSING ! ! ! !
mysql  --login-path=local --silent -DSRG_Dev -N -e "DELETE FROM CardActivity_Temp WHERE CardTemplate != 'Serenitee Loyalty'"
echo '10% deleted'
mysql  --login-path=local --silent -DSRG_Dev -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Identify Customer'"
echo '25% deleted'
mysql  --login-path=local --silent -DSRG_Dev -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Web Reward Purchase'"
echo '30% deleted'
mysql  --login-path=local --silent -DSRG_Dev -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Admin Adjustment'"
echo '35% deleted'
mysql  --login-path=local --silent -DSRG_Dev -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Denied Campaign Adjustment'"
echo '40% deleted'
mysql  --login-path=local --silent -DSRG_Dev -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Denied Accrual / Redemption'"
echo '45% deleted'
mysql  --login-path=local --silent -DSRG_Dev -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Denied Activate'"
echo '50% deleted'
mysql  --login-path=local --silent -DSRG_Dev -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Check-In'"
echo '55% deleted'
mysql  --login-path=local --silent -DSRG_Dev -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Campaign Adjustment'"
echo '60% deleted'
mysql  --login-path=local --silent -DSRG_Dev -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Balance Inquiry'"
echo '65% deleted'
mysql  --login-path=local --silent -DSRG_Dev -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Campaign Expiration'"
echo '75% deleted'
mysql  --login-path=local --silent -DSRG_Dev -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType IS NULL"
echo '90% deleted'
mysql  --login-path=local --silent -DSRG_Dev -N -e "DELETE FROM CardActivity_Temp WHERE CardNumber = '0'"
echo '100% deleted, ADDING LOCATIONID FIELD'

# CREATE LOCATIONID FIELD
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp ADD LocationID INT( 3 ) first"
echo 'ADDED LOCATIONID FIELD TO TEMP TABLE, UPDATING LOCATIONS'

##### UPDATE LOCATIONID
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CardActivity_Temp set LocationID = (SELECT ID from locations WHERE locations.PXID = CardActivity_Temp.StoreNumber)"
echo 'UPDATED LOCATIONID FROM locations TABLE, FORMATTING TransactionDate FIELD'

##### UPDATE RAW DOB TO VARCHAR
# UPDATE THE DOB TO VARCHAR
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp modify TransactionDate VARCHAR(40)"
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp ADD COLUMN TransactionTime VARCHAR(10) AFTER TransactionDate"
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CardActivity_Temp SET TransactionTime = RIGHT(TransactionDate, 5)"
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CardActivity_Temp SET TransactionDate = LEFT(TransactionDate,10)"
echo 'DOB NOW VARCHAR, UPDATING TO SQL'

# PUT TransactionDate INTO SQL FORMAT
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CardActivity_Temp SET TransactionDate= STR_TO_DATE(TransactionDate, '%Y-%m-%d') WHERE STR_TO_DATE(TransactionDate, '%Y-%m-%d') IS NOT NULL"
echo 'DOB NOW SQL FORMAT, UPDATING TO DATE FORMAT'

# Change TransactionDate field to type date
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp CHANGE TransactionDate TransactionDate DATE"
echo 'DOB NOW DATE FORMAT, ADDING POSkey field'

# Create POSkey field
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp ADD POSkey VARCHAR(30) first"
echo 'POSkey FIELD ADDED, ADDING Exceldate FIELD'

# Create excel date field
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp ADD Exceldate INT(100) AFTER LocationID"
echo 'Exceldate FIELD ADDED, POPULATING ExcelDate FIELD'

# Update excel date field
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CardActivity_Temp set Exceldate = (((unix_timestamp(TransactionDate) / 86400) + 25569) + (-5/24))"
echo 'ExcelDate FIELD POPULATED, CREATING POSkey VALUES'


# Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CardActivity_Temp set POSkey = CONCAT_WS('', LocationID, Exceldate, CheckNo)"
echo 'POSkeys CREATED'


### INDEX CARD TEMPLATE AND TRANSACTIONTYPE, CardNumber
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp ADD INDEX(CheckNo)"
echo 'CARDACTIVITY -dev- CheckNo indexed'


#### !!!!!!!! 	WE COULD HAVE THE SELECT QUERY ONLY GO BACK x# OF DAYS   !!!!!! ####
############ ************** CAN WE SPEED THIS UP ******************** ##############
##################### ITERATE UPDATE TO CA CheckNumbers MISSING LEADIN "100"
mysql  --login-path=local --silent -DSRG_Dev -N -e "SELECT RIGHT(CheckNumber, 4), DOB, LocationID FROM CheckDetail_Live WHERE CheckDetail_Live.CheckNumber like '100%' ORDER BY DOB ASC" | while read -r CheckNumber DOB LocationID;
do
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CardActivity_Temp SET CheckNo=CONCAT('100',CheckNo) WHERE CheckNo = '$CheckNumber' AND TransactionDate = '$DOB' AND LocationID = '$LocationID' AND char_length(CheckNo) < '6'"
done
echo 'PX CHECKNUMBERS MISSING 100 FIXED, UPDATING POSKEYS IN TEMP TABLE'

echo 'CORRELATING/FIXING PX CHECKNUMBERS MISSING 100'
##### Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CardActivity_Temp set POSkey = CONCAT_WS('', LocationID, Exceldate, CheckNo)"
echo 'UPDATED POSKEYS IN TEMP TABLE'

######## DROP UNNEEDED TEMP FIELDS
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp DROP Exceldate"
echo 'DROPPED Exceldate fields from temp table'



########### UPDATE THE CardActivitylive table
mysql  --login-path=local --silent -DSRG_Dev -N -e "INSERT INTO CardActivity_Live SELECT * FROM CardActivity_Temp"

echo 'Data inserted into CardActivity_Live, done.'



#### WHEN GUESTS_MASTER IS UP TO DATE WHEN CAN RUN THIS ON JUST THE TEMP TABLE USING ENROLLDATE
#####################################################################

##### START VISITBALANCE FIX HERE
ExchangeCounter=$'0'
NoExchange=$'0'
OddCase=$'0'

#UNCOMMENT NEXT FOR VERBOSE
set -x

### VISIT BALANCE FIX ####################### WE WILL PROCESS EVERY CARD
mysql  --login-path=local -DSRG_Dev -N -e "SELECT DISTINCT(CardNumber) FROM CardActivity_Live ORDER BY CardNumber ASC" | while read -r CardNumber;
do
	######## GET FIRST DATE
	Min_dob=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MIN(TransactionDate) from CardActivity_Live 
									WHERE CardNumber = '$CardNumber'")

	######## IF A BALANCE GREATER THAN 1 ON min_dob THEN THIS WAS AN EXCHANGED CARD
	CarriedBal=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(VisitsBalance) from CardActivity_Live 
									WHERE TransactionDate = '$Min_dob' AND CardNumber = '$CardNumber'")
####  AN EXCHANGE IF THE VISITBALANCE ON THE FIRST TRANSACTION
if [ "$CarriedBal"  -gt "1" ]
	then
		echo $CardNumber"   First Day: "$Min_dob"    EXCHANGED!!! CARRIED "$CarriedBal" # Visits"
		##### PX counts are correct
		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE CardActivity_Live SET Vm_VisitsBalance = VisitsBalance, 
								Vm_VisitsAccrued = VisitsAccrued WHERE CardNumber = '$CardNumber' "
	ExchangeCounter=$[$ExchangeCounter +1]
else
	############## PROCESS CARDS THAT WERE NOT EXCHANGED
	####### WHEN WAS THIS CARD ACTIVATED
	ActivDate=$(mysql --login-path=local -DSRG_Dev -N -e "SELECT TransactionDate FROM CardActivity_Live WHERE CardNumber = '$CardNumber' AND TransactionType = 'Activate'")
	
	####### WAS THERE VISIT ACCRUED ON ACTIVATIONDATE
	ActivVisit=$(mysql --login-path=local -DSRG_Dev -N -e "SELECT MAX(VisitsBalance) FROM CardActivity_Live WHERE CardNumber = '$CardNumber' AND TransactionDate = '$ActivDate'")
	if [ "$ActivVisit" = "1" ]
	then
		# echo $CardNumber"  Should have earliest visit accrual deleted, they accrued on activation day."
		mysql  --login-path=local -DSRG_Dev -N -e "UPDATE CardActivity_Live SET VisitsBalance = '0', VisitsAccrued = '0' WHERE CardNumber = '$CardNumber' AND TransactionDate = '$ActivDate' "

		### They did not accrue on activation day because card was pre-activated, but they did accrue on the day they got the card
	NoExchange=$[$NoExchange +1]
	else

#	echo $CardNumber' ODD CASE! Activation date= '$ActivDate' ActivVisit= '$activVisit' Minimum transaction date= '$Min_dob' CarriedBalance= '$CarriedBal
	OddCase=$[$OddCase +1]
	
	fi
fi
echo "Exch="$ExchangeCounter
echo "NotExch="$NoExchange
echo "OddCase="$OddCase

done


echo 'Script Completed'




