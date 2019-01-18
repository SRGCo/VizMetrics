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


### IF THE FOLLOWING FTPS FAIL WE KEEP GOING
set +e

###### CALL THE FTP CRON JOBS
###### FIRST WE GET THE FILES FROM PX
( "/home/ubuntu/bin/CRON.sftp.px.daily.get.sh" )
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
sleep 5s

###### THEN BERTHA AND MARKETING VITALS GET A COPY
( "/home/ubuntu/bin/CRON.ftp.mv.daily.put.sh" )
## IF WE ERROR TRAP HERE AND MV FAILS WHOLE SCRIPT BLOWS OUT
# trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
sleep 5s

##### HALT AND CATCH FIRE IF ANY COMMAND FAILS FROM HERE ON
set -e

## REMOVE (1) HEADER ROW AND MERGE (IF NECCESSARY) INCOMING CARD ACTIVITY CSVs
## INTO SINGLE CARD ACTIVITY FILE IN DB_FILES
for file in /home/ubuntu/db_files/incoming/px/CardActivity*.csv
  do
	#### MAKE A COPY OF THE FILE IN BACKUP DIR
	cp "$file" //home/ubuntu/db_files/incoming/px/backup/
	tail -n+2 "$file"  >> /home/ubuntu/db_files/incoming/px/Infile.CardActivity.csv
  done || trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'INCOMING -dev- DATA FILES CLEANED AND MERGED, ARCHIVING ORIGINAL FILES'


# Delete Temp table if it exists
mysql  --login-path=local --silent -DSRG_Prod -N -e "DROP TABLE IF EXISTS CardActivity_Temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'TEMP TABLE DROPPED, STARTING NEW TEMP TABLE CREATION'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_Prod -N -e "CREATE TABLE CardActivity_Temp LIKE CardActivity_Structure"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'TEMP TABLE CREATED, LOADING DATA FILE TO TEMP TABLE'

# Load the data from the latest file into the (temp) CardActivity table
############### FIELDS DO NOT LINE UP DIRECTLY THERE ARE DUMMY FIELDS ADD AS WELL AS FIELDS IN DIFFERENT POSTIONS FROM PX IMPORT FILE
mysql  --login-path=local --silent -DSRG_Prod -N -e "Load data local infile '/home/ubuntu/db_files/incoming/px/Infile.CardActivity.csv' into table CardActivity_Temp fields terminated by ',' lines terminated by '\n' (CardNumber,AccountCode,CustomerNo,CardTemplate,TransactionDate,TransactionType,StoreMerchant,StoreNumber,StoreName,WalletType,CheckNo,TerminalID,CashierID,IdentificationMethod,AccountStatus,Promotion,AuthCode,Sender,Dummy1,Dummy2,Dummy3,Dummy4,Dummy5,Dummy6,SurveyAccrued,SurveyRedeemed,SurveyBalance,NewsletterAccrued,NewsletterRedeemed,NewsletterBalance,LifetimeSpendAccrued,LifetimeSpendRedeemed,LifetimeSpendBalance,3000BonusPointsAccrued,3000BonusPointsRedeemed,3000BonusPointsBalance,RegAppAccrued,RegAppRedeemed,RegAppBalance,BdayEntreeAccrued,BdayEntreeRedeemed,BdayEntreeBalance,Dummy7,Dummy8,Dummy9,LTOAccrued,LTORedeemed,LTOBalance,LTObucksAccrued,LTObucksRedeemed,LTObucksBalance,CheckSubtotalAccrued,CheckSubtotalRedeemed,CheckSubtotalBalance,DollarsSpentAccrued,DollarsSpentRedeemed,DollarsSpentBalance,KidsMenuTrackingAccrued,KidsMenuTrackingRedeemed,KidsMenuTrackingBalance,BeerTrackingAccrued,BeerTrackingRedeemed,BeerTrackingBalance,SushiTrackingAccrued,SushiTrackingRedeemed,SushiTrackingBalance,WineTrackingAccrued,WineTrackingRedeemed,WineTrackingBalance,StoreRegisteredAccrued,StoreRegisteredRedeemed,StoreRegisteredBalance,SereniteePointsAccrued,SereniteePointsRedeemed,SereniteePointsBalance,LifetimePointsAccrued,LifetimePointsRedeemed,LifetimePointsBalance,100PointsIncrementAccrued,100PointsIncrementRedeemed,100PointsIncrementBalance,FreeAppAccrued,FreeAppRedeemed,FreeAppBalance,Dummy10,Dummy11,Dummy12,FreeEntreeAccrued,FreeEntreeRedeemed,FreeEntreeBalance,FreeDessertAccrued,FreeDessertRedeemed,FreeDessertBalance,FreePizzaAccrued,FreePizzaRedeemed,FreePizzaBalance,FreeSushiAccrued,FreeSushiRedeemed,FreeSushiBalance,5500PointsAccrued,5500PointsRedeemed,5500PointsBalance,3500PointsAccrued,3500PointsRedeemed,3500PointsBalance,2500PointsAccrued,2500PointsRedeemed,2500PointsBalance,1Kpts5bksAccrued,1Kpts5bksRedeemed,1Kpts5bksBalance,VisitsAccrued,VisitsRedeemed,VisitsBalance,TWKTripAccrued,TWKTripRedeemed,TWKTripBalance,SpotTripAccrued,SpotTripRedeemed,SpotTripBalance,MagsTripAccrued,MagsTripRedeemed,MagsTripBalance,OpusTripAccrued,OpusTripRedeemed,OpusTripBalance,WalnutTripAccrued,WalnutTripRedeemed,WalnutTripBalance,HaleTripAccrued,HaleTripRedeemed,HaleTripBalance,CalasTripAccrued,CalasTripRedeemed,CalasTripBalance,LatTripAccrued,LatTripRedeemed,LatTripBalance,HBTripAccrued,HBTripRedeemed,HBTripBalance,SereniteeAccrued,SereniteeRedeemed,SereniteeBalance,BandCompAccrued,BandCompRedeemed,BandCompBalance,GreenDollarsAccrued,GreenDollarsRedeemed,GreenDollarsBalance,GreenLATAppAccrued,GreenLATAppRedeemed,GreenLATAppBalance,GreenALCAppAccrued,GreenALCAppRedeemed,GreenALCAppBalance,GreenOPUSAppAccrued,GreenOPUSAppRedeemed,GreenOPUSAppBalance,GreenCALAppAccrued,GreenCALAppRedeemed,GreenCALAppBalance,GreenSPOTAppAccrued,GreenSPOTAppRedeemed,GreenSPOTAppBalance,GreenHALEAppAccrued,GreenHALEAppRedeemed,GreenHALEAppBalance,GreenWINCAppAccrued,GreenWINCAppRedeemed,GreenWINCAppBalance,GreenMAGsAppAccrued,GreenMAGsAppRedeemed,GreenMAGsAppBalance,GreenWALAppAccrued,GreenWALAppRedeemed,GreenWALAppBalance,CompAccrued,CompRedeemed,CompBalance,SereniteeGiftCardAccrued,SereniteeGiftCardRedeemed,SereniteeGiftCardBalance,SVDiscountTrackingAccrued,SVDiscountTrackingRedeemed,SVDiscountTrackingBalance)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'CARDACTIVITY DATA LOADED INTO CardActivity_Temp'



# DELETE THE WORKING CARDACTIVITY CSVS
rm -f /home/ubuntu/db_files/incoming/px/CardActivity*.csv
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

rm -f /home/ubuntu/db_files/incoming/px/Infile.CardActivity.csv
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR




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


#######################################################################
################ THE SQUASHES RUN ON ALL DATA COULD THEY JUST RUN ON MOST RECENT?


########### DROP AND RECREATE THE 'squashed' TABLE to READY FOR RELOAD
mysql  --login-path=local --silent -DSRG_Prod -N -e "DROP TABLE IF EXISTS CardActivity_squashed"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'SQUASHED TABLE DROPPED, CREATING SQUASHED TABLE FROM STRUCTURE'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_Prod -N -e "CREATE TABLE CardActivity_squashed LIKE CardActivity_squashed_structure"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'SQUASHED TABLE CREATED, SQUASHING AND INSERTING DATA TO SQUASHED TABLE'

############################ THE SQUASH ####################################
############## SQUASH AND INSERT DATA FROM LIVE CardActivity ###############
####### should we do the FY and luna inserts here
mysql  --login-path=local --silent -DSRG_Prod -N -e "INSERT INTO CardActivity_squashed
SELECT
DISTINCT(POSKey), LocationID, CardNumber, CardTemplate, TransactionDate, MIN(TransactionTime), MIN(checkno),
SUM(Dummy1),SUM(Dummy2),MAX(Dummy3),
SUM(Dummy4),SUM(Dummy5),MAX(Dummy6),
SUM(SurveyAccrued),SUM(SurveyRedeemed),MAX(SurveyBalance),
SUM(NewsletterAccrued),SUM(NewsletterRedeemed),MAX(NewsletterBalance),
SUM(LifetimeSpendAccrued),SUM(LifetimeSpendRedeemed),MAX(LifetimeSpendBalance),
SUM(3000BonusPointsAccrued),SUM(3000BonusPointsRedeemed),MAX(3000BonusPointsBalance),
SUM(RegAppAccrued),SUM(RegAppRedeemed),MAX(RegAppBalance),
SUM(BdayEntreeAccrued),SUM(BdayEntreeRedeemed),MAX(BdayEntreeBalance),
SUM(Dummy7),SUM(Dummy8),MAX(Dummy9),
SUM(LTOAccrued),SUM(LTORedeemed),MAX(LTOBalance),
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
SUM(Dummy10),SUM(Dummy11),MAX(Dummy12),
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
SUM(SVDiscountTrackingAccrued),SUM(SVDiscountTrackingRedeemed),MAX(SVDiscountTrackingBalance),
'0',
'0',
'0',
'0',
'0',
'0',
'0',
'0',
'0',
'0',
'0',
''

FROM CardActivity_Live

WHERE LocationID IS NOT NULL AND CardTemplate = 'Serenitee Loyalty'  AND CheckNo <> '9999999'
AND (TransactionType = 'Accrual / Redemption' OR TransactionType = 'Activate')
GROUP by POSKey, LocationID, CardNumber, CardTemplate, TransactionDate"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'SQUASHED DATA TABLE POPULATED'


########################## 
##########################   WE NEED TO HAVE CARD ACTIVITY SQUASHED BECOME A LIVE TABLE THAT GETS UPDATED INCREMENTALLY
##########################          THEN WE CAN RUN THIS FIX ON ONLY THE NEW TRANSACTIONS
############################          STILL NEED TO DO THIS 1-18-19 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!



######## Get CardNumber
mysql  --login-path=local -DSRG_Prod -N -e "SELECT DISTINCT(CardNumber) FROM CardActivity_squashed WHERE CardNumber IS NOT NULL AND TransactionTime > '21:00:00' ORDER BY CardNumber ASC" | while read -r CardNumber;
do
	######### GET DATA IF CHECK FROM BETWEEN MIDNIGHT AND 4 AM 
	mysql  --login-path=local -DSRG_Prod -N -e "SELECT POSkey, TransactionDate, CheckNo FROM CardActivity_squashed where cardnumber like $CardNumber
	AND TransactionTime > '00:00' and TransactionTime < '04:00'"| while read -r POSkey TransactionDate CheckNo;
	do
		
		########## GET THE POSkey FOR SAME CHECK FROM PREVIOUS DAY IF IT EXISTS
		POSkey_prev=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT POSkey FROM CardActivity_squashed where cardnumber like '$CardNumber' 
		AND TransactionDate = DATE_SUB('$TransactionDate', INTERVAL 1 DAY) AND CheckNo = '$CheckNo'")
		#### SET POSkey FOR LATER RECORD TO EARLIER DATES POSkey (IF PREVIOUS POSKEY EXISTS)
		if [ -n "$POSkey_prev" ]
		then		
			mysql  --login-path=local -DSRG_Prod -N -e "UPDATE CardActivity_squashed SET POSkey = '$POSkey_prev' WHERE POSkey = '$POSkey'"
		#	echo "CARD: "$CardNumber" Transdate1: "$TransactionDate" Check: "$CheckNo" Key1: "$POSkey" Key2: "$POSkey_prev 
		fi
	done

done || trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


########### DROP AND RECREATE THE 2ND 'squashed' TABLE to READY FOR RELOAD
mysql  --login-path=local --silent -DSRG_Prod -N -e "DROP TABLE IF EXISTS CardActivity_squashed_2"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'EXISTING 2ND SQUASHED TABLE DROPPED, CREATING SQUASHED TABLE FROM STRUCTURE'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_Prod -N -e "CREATE TABLE CardActivity_squashed_2 LIKE CardActivity_squashed_structure"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'NEW 2ND SQUASHED TABLE CREATED, SQUASHING 1ST SQUASHED TABLE'

############## SQUASH AND INSERT DATA FROM FIRST SQUASHED TABLE ###############
######### THIS ACCOUNTS FOR THE CARDS THAT GOT A WRONG POSKEY BECAUSE THEY WERE OPEN ACROSS MIDNIGHT
############# THIS IS ANOTHER REASON WE SHOULD HAVE SQUASH ONLY PROCESSING INCREMENTALLY 

###################################### SQUASH2 #########################################
mysql  --login-path=local --silent -DSRG_Prod -N -e "INSERT INTO CardActivity_squashed_2
SELECT
DISTINCT(POSKey), LocationID, CardNumber, CardTemplate, MIN(TransactionDate), MIN(TransactionTime), MIN(checkno),

SUM(Dummy1),SUM(Dummy2),MAX(Dummy3),
SUM(Dummy4),SUM(Dummy5),MAX(Dummy6),
SUM(SurveyAccrued),SUM(SurveyRedeemed),MAX(SurveyBalance),
SUM(NewsletterAccrued),SUM(NewsletterRedeemed),MAX(NewsletterBalance),
SUM(LifetimeSpendAccrued),SUM(LifetimeSpendRedeemed),MAX(LifetimeSpendBalance),
SUM(3000BonusPointsAccrued),SUM(3000BonusPointsRedeemed),MAX(3000BonusPointsBalance),
SUM(RegAppAccrued),SUM(RegAppRedeemed),MAX(RegAppBalance),
SUM(BdayEntreeAccrued),SUM(BdayEntreeRedeemed),MAX(BdayEntreeBalance),
SUM(Dummy7),SUM(Dummy8),MAX(Dummy9),
SUM(LTOAccrued),SUM(LTORedeemed),MAX(LTOBalance),
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
SUM(Dummy10),SUM(Dummy11),MAX(Dummy12),
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
SUM(SVDiscountTrackingAccrued),SUM(SVDiscountTrackingRedeemed),MAX(SVDiscountTrackingBalance),
'0','0','0','0','0','0','0','0','0','0','0',''

FROM CardActivity_squashed

GROUP by POSKey, LocationID, CardNumber, CardTemplate"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'NEW SQUASHED DATA TABLE    2    POPULATED'

### INDEX SQUASHED TABLE POSkey
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE CardActivity_squashed_2 ADD INDEX(POSkey)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'CARDACTIVITY SQUASHED 2 POSKEY INDEX ADDED'

echo 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'

echo 'DEV.PX.CA.PROCESS.SH COMPLETED'




