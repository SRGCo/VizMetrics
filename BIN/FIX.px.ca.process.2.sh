#! //bin/bash
# LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# THIS SCRIPT HAS TO RUN AFTER CHECKDETAIL IS PROCESSED SO THAT THE CHECK NUMBER FIX RUNS CORRECTLY

# UNCOMMENT NEXT FOR VERBOSE
#set -x


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


#### THIS IS ONLY FOR THE CA DATA FROM 2019-07-11 THROUGH 2019-10-09

sleep 5s

##### HALT AND CATCH FIRE IF ANY COMMAND FAILS FROM HERE ON
set -e



### INDEX CARD TEMPLATE AND TRANSACTIONTYPE, CardNumber
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CardActivity_Temp ADD INDEX(TransactionType)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CardActivity_Temp ADD INDEX(CardNumber)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

echo 'CARDACTIVITY -dev- TransactionType and CardNumber indexed'


echo 'DELETING EXTRANEOUS RECORDS BY TRANSACTION TYPES'
### REMOVE ANY/ALL RECORDS THAT ARE NOT WORTH PROCESSING ! ! ! !
mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE FROM CardActivity_Temp WHERE CardTemplate != 'Serenitee Loyalty'"
echo '10% deleted'
mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Identify Customer'"
echo '25% deleted'
mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Web Reward Purchase'"
echo '30% deleted'
mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Admin Adjustment'"
echo '35% deleted'
mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Denied Campaign Adjustment'"
echo '40% deleted'
mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Denied Accrual / Redemption'"
echo '45% deleted'
mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Denied Activate'"
echo '50% deleted'
mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Check-In'"
echo '55% deleted'
mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Campaign Adjustment'"
echo '60% deleted'
mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Balance Inquiry'"
echo '65% deleted'
mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Denied Balance Inquiry'"
echo '70% deleted'
mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Campaign Expiration'"
echo '75% deleted'
mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType IS NULL"
echo '90% deleted'
mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE FROM CardActivity_Temp WHERE CardNumber = '0'"
echo '100% deleted, ADDING LOCATIONID FIELD'

# CREATE LOCATIONID FIELD
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CardActivity_Temp ADD LocationID INT( 3 ) first"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'ADDED LOCATIONID FIELD TO TEMP TABLE, UPDATING LOCATIONS'

##### UPDATE LOCATIONID
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE CardActivity_Temp set LocationID = (SELECT ID from Locations WHERE Locations.PXID = CardActivity_Temp.StoreNumber)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'UPDATED LOCATIONID FROM locations TABLE, FORMATTING TransactionDate FIELD'

##### UPDATE RAW DOB TO VARCHAR
# UPDATE THE DOB TO VARCHAR
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CardActivity_Temp modify TransactionDate VARCHAR(40)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CardActivity_Temp ADD COLUMN TransactionTime VARCHAR(10) AFTER TransactionDate"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE CardActivity_Temp SET TransactionTime = RIGHT(TransactionDate, 5)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE CardActivity_Temp SET TransactionDate = LEFT(TransactionDate,10)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

echo 'DOB NOW VARCHAR, UPDATING TO SQL'

# PUT TransactionDate INTO SQL FORMAT
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE CardActivity_Temp SET TransactionDate= STR_TO_DATE(TransactionDate, '%Y-%m-%d') WHERE STR_TO_DATE(TransactionDate, '%Y-%m-%d') IS NOT NULL"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'DOB NOW SQL FORMAT, UPDATING TO DATE FORMAT'

# Change TransactionDate field to type date
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CardActivity_Temp CHANGE TransactionDate TransactionDate DATE"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'DOB NOW DATE FORMAT, ADDING POSkey field'

# Create POSkey field
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CardActivity_Temp ADD POSkey VARCHAR(30) first"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'POSkey FIELD ADDED, ADDING Exceldate FIELD'

# Create excel date field
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CardActivity_Temp ADD Exceldate INT(100) AFTER LocationID"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'Exceldate FIELD ADDED, POPULATING ExcelDate FIELD'

# Update excel date field
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE CardActivity_Temp set Exceldate = (((unix_timestamp(TransactionDate) / 86400) + 25569) + (-5/24))"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'ExcelDate FIELD POPULATED, CREATING POSkey VALUES'


# Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE CardActivity_Temp set POSkey = CONCAT_WS('', LocationID, Exceldate, CheckNo)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'POSkeys CREATED'


### INDEX CARD TEMPLATE AND TRANSACTIONTYPE, CardNumber
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CardActivity_Temp ADD INDEX(CheckNo)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'CARDACTIVITY -dev- CheckNo indexed'


#### !!!!!!!! 	WE COULD HAVE THE SELECT QUERY ONLY GO BACK x# OF DAYS   !!!!!! ####
############ ************** CAN WE SPEED THIS UP ******************** ##############
##################### ITERATE UPDATE TO CA CheckNumbers MISSING LEADIN "100"
############################## THIS IS WHY CHECKDETAIL HAS TO RUN EARLIER THAN CA 

mysql  --login-path=local --silent -DSRG_Prod -N -e "SELECT RIGHT(CheckNumber, 4), DOB, LocationID FROM CheckDetail_Live WHERE CheckDetail_Live.CheckNumber like '100%' AND DOB >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) ORDER BY DOB ASC" | while read -r CheckNumber DOB LocationID;
do
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE CardActivity_Temp SET CheckNo=CONCAT('100',CheckNo) WHERE CheckNo = '$CheckNumber' AND TransactionDate = '$DOB' AND LocationID = '$LocationID' AND char_length(CheckNo) < '6'"
done
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'PX CHECKNUMBERS MISSING 100 FIXED, UPDATING POSKEYS IN TEMP TABLE'

echo 'CORRELATING/FIXING PX CHECKNUMBERS MISSING 100'
##### Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE CardActivity_Temp set POSkey = CONCAT_WS('', LocationID, Exceldate, CheckNo)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'UPDATED POSKEYS IN TEMP TABLE'

######## DROP UNNEEDED TEMP FIELDS
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CardActivity_Temp DROP Exceldate"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'DROPPED EXCEL DATE FIELD FROM CARDACTIVITY TEMP'


########### UPDATE THE CardActivitylive table
mysql  --login-path=local --silent -DSRG_Prod -N -e "INSERT INTO CardActivity_Live SELECT * FROM CardActivity_Temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'CARD ACTIVITY LIVE TABLE UPDATED WITH CARD ACTIVITY TEMP DATA'



echo 'DEV.PX.CA.PROCESS.SH COMPLETED'




