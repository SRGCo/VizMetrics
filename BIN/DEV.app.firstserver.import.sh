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



##### HALT AND CATCH FIRE IF ANY COMMAND FAILS FROM HERE ON
set -e

## REMOVE (1) HEADER ROW AND MERGE (IF NECCESSARY) INCOMING CARD ACTIVITY CSVs
## INTO SINGLE CARD ACTIVITY FILE IN DB_FILES
for file in /home/ubuntu/db_files/incoming/dev/CardActivity*.csv
  do
	#### MAKE A COPY OF THE FILE IN BACKUP DIR
	cp "$file" //home/ubuntu/db_files/incoming/dev/backup/
	tail -n+3 "$file"  >> /home/ubuntu/db_files/incoming/dev/Infile.CardActivity.csv
  done || trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'INCOMING -dev- DATA FILES CLEANED AND MERGED, ARCHIVING ORIGINAL FILES'


# Delete Temp table if it exists
mysql  --login-path=local --silent -DSRG_Dev -N -e "DROP TABLE IF EXISTS CardActivity_Temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'TEMP TABLE DROPPED, STARTING NEW TEMP TABLE CREATION'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_Dev -N -e "CREATE TABLE CardActivity_Temp LIKE CardActivity_Structure"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'TEMP TABLE CREATED, LOADING DATA FILE TO TEMP TABLE'

# Load the data from the latest file into the (temp) CardActivity table
############### FIELDS DO NOT LINE UP DIRECTLY THERE ARE DUMMY FIELDS ADD AS WELL AS FIELDS IN DIFFERENT POSTIONS FROM PX IMPORT FILE
mysql  --login-path=local --silent -DSRG_Dev -N -e "Load data local infile '/home/ubuntu/db_files/incoming/dev/Infile.CardActivity.csv' into table CardActivity_Temp fields terminated by ',' lines terminated by '\n' (CardNumber,AccountCode,CustomerNo,CardTemplate,TransactionDate,TransactionType,StoreMerchant,StoreNumber,StoreName,WalletType,CheckNo,TerminalID,CashierID,IdentificationMethod,AccountStatus,Promotion,AuthCode,Sender,Dummy1,Dummy2,Dummy3,Dummy4,Dummy5,Dummy6,SurveyAccrued,SurveyRedeemed,SurveyBalance,NewsletterAccrued,NewsletterRedeemed,NewsletterBalance,LifetimeSpendAccrued,LifetimeSpendRedeemed,LifetimeSpendBalance,3000BonusPointsAccrued,3000BonusPointsRedeemed,3000BonusPointsBalance,RegAppAccrued,RegAppRedeemed,RegAppBalance,BdayEntreeAccrued,BdayEntreeRedeemed,BdayEntreeBalance,Dummy7,Dummy8,Dummy9,LTOAccrued,LTORedeemed,LTOBalance,LTObucksAccrued,LTObucksRedeemed,LTObucksBalance,CheckSubtotalAccrued,CheckSubtotalRedeemed,CheckSubtotalBalance,DollarsSpentAccrued,DollarsSpentRedeemed,DollarsSpentBalance,KidsMenuTrackingAccrued,KidsMenuTrackingRedeemed,KidsMenuTrackingBalance,BeerTrackingAccrued,BeerTrackingRedeemed,BeerTrackingBalance,SushiTrackingAccrued,SushiTrackingRedeemed,SushiTrackingBalance,WineTrackingAccrued,WineTrackingRedeemed,WineTrackingBalance,StoreRegisteredAccrued,StoreRegisteredRedeemed,StoreRegisteredBalance,SereniteePointsAccrued,SereniteePointsRedeemed,SereniteePointsBalance,LifetimePointsAccrued,LifetimePointsRedeemed,LifetimePointsBalance,100PointsIncrementAccrued,100PointsIncrementRedeemed,100PointsIncrementBalance,FreeAppAccrued,FreeAppRedeemed,FreeAppBalance,Dummy10,Dummy11,Dummy12,FreeEntreeAccrued,FreeEntreeRedeemed,FreeEntreeBalance,FreeDessertAccrued,FreeDessertRedeemed,FreeDessertBalance,FreePizzaAccrued,FreePizzaRedeemed,FreePizzaBalance,FreeSushiAccrued,FreeSushiRedeemed,FreeSushiBalance,5500PointsAccrued,5500PointsRedeemed,5500PointsBalance,3500PointsAccrued,3500PointsRedeemed,3500PointsBalance,2500PointsAccrued,2500PointsRedeemed,2500PointsBalance,1Kpts5bksAccrued,1Kpts5bksRedeemed,1Kpts5bksBalance,VisitsAccrued,VisitsRedeemed,VisitsBalance,TWKTripAccrued,TWKTripRedeemed,TWKTripBalance,SpotTripAccrued,SpotTripRedeemed,SpotTripBalance,MagsTripAccrued,MagsTripRedeemed,MagsTripBalance,OpusTripAccrued,OpusTripRedeemed,OpusTripBalance,WalnutTripAccrued,WalnutTripRedeemed,WalnutTripBalance,HaleTripAccrued,HaleTripRedeemed,HaleTripBalance,CalasTripAccrued,CalasTripRedeemed,CalasTripBalance,LatTripAccrued,LatTripRedeemed,LatTripBalance,HBTripAccrued,HBTripRedeemed,HBTripBalance,SereniteeAccrued,SereniteeRedeemed,SereniteeBalance,BandCompAccrued,BandCompRedeemed,BandCompBalance,GreenDollarsAccrued,GreenDollarsRedeemed,GreenDollarsBalance,GreenLATAppAccrued,GreenLATAppRedeemed,GreenLATAppBalance,GreenALCAppAccrued,GreenALCAppRedeemed,GreenALCAppBalance,GreenOPUSAppAccrued,GreenOPUSAppRedeemed,GreenOPUSAppBalance,GreenCALAppAccrued,GreenCALAppRedeemed,GreenCALAppBalance,GreenSPOTAppAccrued,GreenSPOTAppRedeemed,GreenSPOTAppBalance,GreenHALEAppAccrued,GreenHALEAppRedeemed,GreenHALEAppBalance,GreenWINCAppAccrued,GreenWINCAppRedeemed,GreenWINCAppBalance,GreenMAGsAppAccrued,GreenMAGsAppRedeemed,GreenMAGsAppBalance,GreenWALAppAccrued,GreenWALAppRedeemed,GreenWALAppBalance,CompAccrued,CompRedeemed,CompBalance,SereniteeGiftCardAccrued,SereniteeGiftCardRedeemed,SereniteeGiftCardBalance,SVDiscountTrackingAccrued,SVDiscountTrackingRedeemed,SVDiscountTrackingBalance)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'CARDACTIVITY DATA LOADED INTO CardActivity_Temp'



# DELETE THE WORKING CARDACTIVITY CSVS
rm -f /home/ubuntu/db_files/incoming/dev/CardActivity*.csv
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

rm -f /home/ubuntu/db_files/incoming/dev/Infile.CardActivity.csv
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR




### INDEX CARD TEMPLATE AND TRANSACTIONTYPE, CardNumber
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp ADD INDEX(TransactionType)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp ADD INDEX(CardNumber)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


# CREATE LOCATIONID FIELD
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp ADD LocationID INT( 3 ) first"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'ADDED LOCATIONID FIELD TO TEMP TABLE, UPDATING LOCATIONS'

##### UPDATE LOCATIONID
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CardActivity_Temp set LocationID = (SELECT ID from Locations WHERE Locations.PXID = CardActivity_Temp.StoreNumber)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'UPDATED LOCATIONID FROM locations TABLE, FORMATTING TransactionDate FIELD'

##### UPDATE RAW DOB TO VARCHAR
# UPDATE THE DOB TO VARCHAR
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp modify TransactionDate VARCHAR(40)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp ADD COLUMN TransactionTime VARCHAR(10) AFTER TransactionDate"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CardActivity_Temp SET TransactionTime = RIGHT(TransactionDate, 5)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CardActivity_Temp SET TransactionDate = LEFT(TransactionDate,10)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

echo 'DOB NOW VARCHAR, UPDATING TO SQL'

# PUT TransactionDate INTO SQL FORMAT
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CardActivity_Temp SET TransactionDate= STR_TO_DATE(TransactionDate, '%Y-%m-%d') WHERE STR_TO_DATE(TransactionDate, '%Y-%m-%d') IS NOT NULL"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'DOB NOW SQL FORMAT, UPDATING TO DATE FORMAT'

# Change TransactionDate field to type date
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp CHANGE TransactionDate TransactionDate DATE"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'DOB NOW DATE FORMAT, ADDING POSkey field'

# Create POSkey field
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp ADD POSkey VARCHAR(30) first"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'POSkey FIELD ADDED, ADDING Exceldate FIELD'

# Create excel date field
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp ADD Exceldate INT(100) AFTER LocationID"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'Exceldate FIELD ADDED, POPULATING ExcelDate FIELD'

# Update excel date field
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CardActivity_Temp set Exceldate = (((unix_timestamp(TransactionDate) / 86400) + 25569) + (-5/24))"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'ExcelDate FIELD POPULATED, CREATING POSkey VALUES'


# Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
mysql  --login-path=local --silent -DSRG_Dev -N -e "UPDATE CardActivity_Temp set POSkey = CONCAT_WS('', LocationID, Exceldate, CheckNo)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'POSkeys CREATED'


### INDEX CARD TEMPLATE AND TRANSACTIONTYPE, CardNumber
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp ADD INDEX(CheckNo)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'CARDACTIVITY -dev- CheckNo indexed'



######## DROP UNNEEDED TEMP FIELDS
mysql  --login-path=local --silent -DSRG_Dev -N -e "ALTER TABLE CardActivity_Temp DROP Exceldate"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'DROPPED EXCEL DATE FIELD FROM CARDACTIVITY TEMP'


########### UPDATE THE CardActivitylive table
mysql  --login-path=local --silent -DSRG_Dev -N -e "INSERT INTO CardActivity_Live SELECT * FROM CardActivity_Temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'CARD ACTIVITY LIVE TABLE UPDATED WITH CARD ACTIVITY TEMP DATA'

echo 'DEV.PX.CA.PROCESS.SH COMPLETED'


###### PROCESS THE CA_Live TABLE INTO FIRST USE TABLE
( "/home/ubuntu/bin/DEV.app.use.firstserver.php" )
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'DEV App_use1 Table populated with new data'






