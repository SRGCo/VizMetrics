#! //bin/bash
# LOG IT TO SYSLOG

############################################################################################
################## FIX THIS SCRIPT SO IT DOES ITS WORK IN A NON PRODUCTION DIRECTORY !!!!!
############################################################################################
########## ADD ERROR HANDLING AT EACH FAIL POINT ###########################################




# exec 1> >(logger -s -t $(basename $0)) 2>&1

#UNCOMMENT NEXT FOR VERBOSE
set -x
##### HALT AND CATCH FIRE IF ANY COMMANd FAILS
set -e



## REMOVE HEADERS AND MERGE (IF NECCESSARY) INCOMING CARD ACTIVITY CSVs
## INTO SINGLE CARD ACTIVITY FILE IN DB_FILES
for file in /home/ubuntu/db_files/incoming/px/CardActivity*.csv
do
    tail -n+3 "$file"  >> /home/ubuntu/db_files/CardActivity.csv
done
echo 'INCOMING DATA FILES CLEANED AND MERGED, ARCHIVING ORIGINAL FILES'



# ARCHIVE THE DOWNLOADED PAYTRONIX FILES
### copy them for now until archive set up
mv /home/ubuntu/db_files/incoming/px/*.csv /home/ubuntu/db_files/archive/
### archive trials
# tar -
echo 'ORIGINAL FILES ARCHIVED, DROPPING -OLD- TEMP TABLE'

# Delete Temp table if it exists
mysql  --login-path=local --silent -DSRG_px -N -e "DROP TABLE IF EXISTS CardActivity_Temp"
echo 'TEMP TABLE DROPPED, STARTING NEW TEMP TABLE CREATION'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_px -N -e "CREATE TABLE CardActivity_Temp AS (SELECT * FROM CardActivity_Structure WHERE 1=0)"
echo 'TEMP TABLE CREATED, LOADING DATA FILE TO TEMP TABLE'

# Load the data from the latest file into the (temp) CardActivity table
mysql  --login-path=local --silent -DSRG_px -N -e "Load data local infile '/home/ubuntu/db_files/CardActivity.csv' into table CardActivity_Temp fields terminated by ',' lines terminated by '\n'"
echo 'CARDACTIVITY DATE LOADED INTO CardActivity_Temp, DELETING CARDACTIVITY DATA FILE'

# DELETE THE WORKING COPY OF CardActivity.csv
rm -f /home/ubuntu/db_files/CardActivity.csv
echo 'CARDACTIVITY DATA FILE DELETED, CREATING TEMP TABLE PRIMARY KEY'

#### ADD AN INDEXED PRIMARY KEY FIELD TO SPEED UP QUERIES, DELETE BEFORE INSERTING DATA INTO LIVE TABLE
mysql  --login-path=local --silent -DSRG_px -N -e "ALTER TABLE CardActivity_Temp ADD row_count INT(11) NOT NULL AUTO_INCREMENT AFTER SVDiscountTrackingBalance, ADD PRIMARY KEY (row_count)"
echo 'PRIMARY KEY INDEX FIELD ADDED TO CardActivity_Temp TABLE, DELETING NON-REWARDS ROWS'

### DELETE ANY/ALL RECORDS THAT ARE NOT WORTH PROCESSING ! ! ! !
mysql  --login-path=local --silent -DSRG_px -N -e "DELETE FROM CardActivity_Temp WHERE CardTemplate != 'Serenitee Loyalty'"
echo '15% deleted'
mysql  --login-path=local --silent -DSRG_px -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Check-In'"
echo '30% deleted'
mysql  --login-path=local --silent -DSRG_px -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Campaign Adjustment'"
echo '45% deleted'
mysql  --login-path=local --silent -DSRG_px -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Balance Inquiry'"
echo '60% deleted'
mysql  --login-path=local --silent -DSRG_px -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType = 'Campaign Expiration'"
echo '75% deleted'
mysql  --login-path=local --silent -DSRG_px -N -e "DELETE FROM CardActivity_Temp WHERE TransactionType IS NULL"
echo '90% deleted'
mysql  --login-path=local --silent -DSRG_px -N -e "DELETE FROM CardActivity_Temp WHERE CardNumber = '0'"
echo '100% deleted, ADDING LOCATIONID FIELD'

# CREATE LOCATIONID FIELD
mysql  --login-path=local --silent -DSRG_px -N -e "ALTER TABLE CardActivity_Temp ADD LocationID INT( 3 ) first"
echo 'ADDED LOCATIONID FIELD TO TEMP TABLE, UPDATING LOCATIONS'

##### UPDATE LOCATIONID
mysql  --login-path=local --silent -DSRG_px -N -e "UPDATE CardActivity_Temp set LocationID = (SELECT ID from locations WHERE locations.PXID = CardActivity_Temp.StoreNumber)"
echo 'UPDATED LOCATIONID FROM locations TABLE, FORMATTING TransactionDate FIELD'

##### UPDATE RAW DOB TO VARCHAR
# UPDATE THE DOB TO VARCHAR
mysql  --login-path=local --silent -DSRG_px -N -e "ALTER TABLE CardActivity_Temp modify TransactionDate VARCHAR(40)"
mysql  --login-path=local --silent -DSRG_px -N -e "ALTER TABLE CardActivity_Temp ADD COLUMN TransactionTime VARCHAR(10) AFTER TransactionDate"
mysql  --login-path=local --silent -DSRG_px -N -e "UPDATE CardActivity_Temp SET TransactionTime = RIGHT(TransactionDate, 5)"
mysql  --login-path=local --silent -DSRG_px -N -e "UPDATE CardActivity_Temp SET TransactionDate = LEFT(TransactionDate,10)"
echo 'DOB NOW VARCHAR, UPDATING TO SQL'

# PUT TransactionDate INTO SQL FORMAT
mysql  --login-path=local --silent -DSRG_px -N -e "UPDATE CardActivity_Temp SET TransactionDate= STR_TO_DATE(TransactionDate, '%Y-%m-%d') WHERE STR_TO_DATE(TransactionDate, '%Y-%m-%d') IS NOT NULL"
echo 'DOB NOW SQL FORMAT, UPDATING TO DATE FORMAT'

# Change TransactionDate field to type date
mysql  --login-path=local --silent -DSRG_px -N -e "ALTER TABLE CardActivity_Temp CHANGE TransactionDate TransactionDate DATE"
echo 'DOB NOW DATE FORMAT, ADDING POSkey field'

# Create POSkey field
mysql  --login-path=local --silent -DSRG_px -N -e "ALTER TABLE CardActivity_Temp ADD POSkey VARCHAR(30) first"
echo 'POSkey FIELD ADDED, ADDING Exceldate FIELD'

# Create excel date field
mysql  --login-path=local --silent -DSRG_px -N -e "ALTER TABLE CardActivity_Temp ADD Exceldate INT(100) AFTER LocationID"
echo 'Exceldate FIELD ADDED, POPULATING ExcelDate FIELD'

# Update excel date field
mysql  --login-path=local --silent -DSRG_px -N -e "UPDATE CardActivity_Temp set Exceldate = (((unix_timestamp(TransactionDate) / 86400) + 25569) + (-5/24))"
echo 'ExcelDate FIELD POPULATED, CREATING POSkey VALUES'


# Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
mysql  --login-path=local --silent -DSRG_px -N -e "UPDATE CardActivity_Temp set POSkey = CONCAT_WS('', LocationID, Exceldate, CheckNo)"
echo 'POSkeys CREATED, ADD RowID TO MATCH LIVE TABLE FORMAT'


# ADD the RowID field but do not populate it (it will get auto increment when it is selected into CardActivitylive)
mysql  --login-path=local --silent -DSRG_px -N -e "ALTER TABLE CardActivity_Temp ADD COLUMN RowID int(11) AFTER POSkey"
echo 'RowID ADDED, DROPPING INDEXED PRIMARY KEY'

# REMOVE THE TEMP INDEX FIELD
mysql  --login-path=local --silent -DSRG_px -N -e "ALTER TABLE CardActivity_Temp DROP row_count"
echo 'PRIMARY KEY DROPPED !!!INSERTING DATA INTO LIVE TABLE!!!'

########### UPDATE THE CardActivitylive table
mysql  --login-path=local --silent -DSRG_px -N -e "INSERT INTO CardActivity_Live SELECT * FROM CardActivity_Temp"
echo 'DATA INSERTED INTO LIVE TABLE, CORRELATING/FIXING PX CHECKNUMBERS MISSING 100'



############ ************** CAN WE SPEED THIS UP ******************** ##############
##################### ITERATE UPDATE TO CA CheckNumbers MISSING LEADIN "100"
mysql  --login-path=local --silent -DSRG_checks -N -e "SELECT RIGHT(CheckNumber, 4), DOB, LocationID FROM CheckDetail_Live WHERE CheckDetail_Live.CheckNumber like '100%'" | while read -r CheckNumber DOB LocationID;
do
mysql  --login-path=local --silent -DSRG_px -N -e "UPDATE CardActivity_Live SET CheckNo=CONCAT('100',CheckNo) WHERE CheckNo = '$CheckNumber' AND TransactionDate = '$DOB' AND LocationID = '$LocationID' AND char_length(CheckNo) < '6'"
done
echo 'PX CHECKNUMBERS MISSING 100 FIXED, UPDATING POSKEYS IN LIVE TABLE'




##### Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
mysql  --login-path=local --silent -DSRG_px -N -e "UPDATE CardActivity_Live set POSkey = CONCAT_WS('', LocationID, Exceldate, CheckNo)"
echo 'UPDATED POSKEYS IN LIVE TABLE, DROPPING THE SQUASHED TABLE'

########### DROP AND RECREATE THE 'squashed' TABLE to READY FOR RELOAD
mysql  --login-path=local --silent -DSRG_px -N -e "DROP TABLE CardActivity_squashed"
echo 'SQUASHED TABLE DROPPED, CREATING SQUASHED TABLE FROM STRUCTURE'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_px -N -e "CREATE TABLE CardActivity_squashed AS (SELECT * FROM CardActivity_Structure WHERE 1=0)"
echo 'SQUASHED TABLE CREATED, SQUASHING AND LOADING DATA FILE TO SQUASHED TABLE'

############## SQUASH AND INSERT DATA FROM LIVE CardActivity ###############
mysql  --login-path=local --silent -DSRG_px -N -e "INSERT INTO SRG_px.CardActivity_squashed
SELECT
DISTINCT(POSKey), LocationID, CardNumber, CardTemplate, TransactionDate,
SUM(LifetimeSpendAccrued),SUM(LifetimeSpendRedeemed),MAX(LifetimeSpendBalance),
SUM(3000BonusPointsAccrued),SUM(3000BonusPointsRedeemed),MAX(3000BonusPointsBalance),
SUM(CoffeesBoughtAccrued),SUM(CoffeesBoughtRedeemed),MAX(CoffeesBoughtBalance),
SUM(AddCoffeeAccrued),SUM(AddCoffeeRedeemed),MAX(AddCoffeeBalance),
SUM(HappyBellyCoffeeAccrued),SUM(HappyBellyCoffeeRedeemed),MAX(HappyBellyCoffeeBalance),
SUM(LTObucksAccrued),SUM(LTObucksRedeemed),MAX(LTObucksBalance),
SUM(CheckSubtotalAccrued),SUM(CheckSubtotalRedeemed),MAX(CheckSubtotalBalance),
SUM(DollarsSpentAccrued),SUM(DollarsSpentRedeemed),MAX(DollarsSpentBalance),
SUM(KidsMenuTrackingAccrued),SUM(KidsMenuTrackingRedeemed),MAX(KidsMenuTrackingBalance),
SUM(BeerTrackingAccrued),SUM(BeerTrackingRedeemed),MAX(BeerTrackingBalance),
SUM(SushiTrackingAccrued),SUM(SushiTrackingRedeemed),MAX(SushiTrackingBalance),
SUM(WineTrackingAccrued),SUM(WineTrackingRedeemed),MAX(WineTrackingBalance),
SUM(StoreRegisteredAccrued),SUM(StoreRegisteredRedeemed),MAX(StoreRegisteredBalance),
SUM(SereniteePointsAccrued),SUM(SereniteePointsRedeemed),MAX(SereniteePointsBalance),
SUM(LifetimePointsAccrued),SUM(LifetimePointsRedeemed),MAX(LifetimePointsBalance),
SUM(100PointsIncrementAccrued),SUM(100PointsIncrementRedeemed),MAX(100PointsIncrementBalance),
SUM(FreeAppAccrued),SUM(FreeAppRedeemed),MAX(FreeAppBalance),
SUM(FreeEntreeAccrued),SUM(FreeEntreeRedeemed),MAX(FreeEntreeBalance),
SUM(FreeDessertAccrued),SUM(FreeDessertRedeemed),MAX(FreeDessertBalance),
SUM(FreePizzaAccrued),SUM(FreePizzaRedeemed),MAX(FreePizzaBalance),
SUM(FreeSushiAccrued),SUM(FreeSushiRedeemed),MAX(FreeSushiBalance),
SUM(5500PointsAccrued),SUM(5500PointsRedeemed),MAX(5500PointsBalance),
SUM(3500PointsAccrued),SUM(3500PointsRedeemed),MAX(3500PointsBalance),
SUM(2500PointsAccrued),SUM(2500PointsRedeemed),MAX(2500PointsBalance),
SUM(1Kpts5bksAccrued),SUM(1Kpts5bksRedeemed),MAX(1Kpts5bksBalance), 
MAX(VisitsAccrued),SUM(VisitsRedeemed),MAX(VisitsBalance), 
SUM(TWKTripAccrued),SUM(TWKTripRedeemed),MAX(TWKTripBalance),
SUM(SpotTripAccrued),SUM(SpotTripRedeemed),MAX(SpotTripBalance),
SUM(MagsTripAccrued),SUM(MagsTripRedeemed),MAX(MagsTripBalance),
SUM(OpusTripAccrued),SUM(OpusTripRedeemed),MAX(OpusTripBalance),
SUM(WalnutTripAccrued),SUM(WalnutTripRedeemed),MAX(WalnutTripBalance),
SUM(HaleTripAccrued),SUM(HaleTripRedeemed),MAX(HaleTripBalance),
SUM(CalasTripAccrued),SUM(CalasTripRedeemed),MAX(CalasTripBalance),
SUM(LatTripAccrued),SUM(LatTripRedeemed),MAX(LatTripBalance),
SUM(HBTripAccrued),SUM(HBTripRedeemed),MAX(HBTripBalance),
SUM(SereniteebucksAccrued),SUM(SereniteebucksRedeemed),MAX(SereniteebucksBalance),
SUM(BandCompbucksAccrued),SUM(BandCompbucksRedeemed),MAX(BandCompbucksBalance),
SUM(GreenDollarsAccrued),SUM(GreenDollarsRedeemed),MAX(GreenDollarsBalance),
SUM(GreenLATAppAccrued),SUM(GreenLATAppRedeemed),MAX(GreenLATAppBalance),
SUM(GreenALCAppAccrued),SUM(GreenALCAppRedeemed),MAX(GreenALCAppBalance),
SUM(GreenOPUSAppAccrued),SUM(GreenOPUSAppRedeemed),MAX(GreenOPUSAppBalance),
SUM(GreenCALAppAccrued),SUM(GreenCALAppRedeemed),MAX(GreenCALAppBalance),
SUM(GreenSPOTAppAccrued),SUM(GreenSPOTAppRedeemed),MAX(GreenSPOTAppBalance),
SUM(GreenHALEAppAccrued),SUM(GreenHALEAppRedeemed),MAX(GreenHALEAppBalance),
SUM(GreenWINCAppAccrued),SUM(GreenWINCAppRedeemed),MAX(GreenWINCAppBalance),
SUM(GreenMAGsAppAccrued),SUM(GreenMAGsAppRedeemed),MAX(GreenMAGsAppBalance),
SUM(GreenWALAppAccrued),SUM(GreenWALAppRedeemed),MAX(GreenWALAppBalance),
SUM(CompbucksAccrued),SUM(CompbucksRedeemed),MAX(CompbucksBalance),
SUM(SereniteeGiftCardAccrued),SUM(SereniteeGiftCardRedeemed),MAX(SereniteeGiftCardBalance),
SUM(NewsletterAccrued),SUM(NewsletterRedeemed),MAX(NewsletterBalance),
SUM(SVDiscountTrackingAccrued),SUM(SVDiscountTrackingRedeemed),MAX(SVDiscountTrackingBalance),
,,,,,,,

FROM CardActivity_Live

WHERE LocationID IS NOT NULL AND CardTemplate = 'Serenitee Loyalty'  AND CheckNo <> '9999999'
AND (TransactionType = 'Accrual / Redemption' OR TransactionType = 'Activate')

GROUP by POSKey, LocationID, CardNumber, CardTemplate, TransactionDate"

echo 'SQUASHED DATA TABLE POPULATED'

### WE ADD FREQUENCY FIELDS TO SQUASHED TABLE IN FREQ SCRIPT







