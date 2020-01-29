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


#################### NOTES #####################################
# CARD ACTIVITY SCRIPTS NEED TO RUN *AFTER* CHECKDETAIL SCRIPTS SO MISSING '100' CAN BE ADDED TO SOME CHECK NUMBERS
 




### IF THE FOLLOWING FTPS FAIL WE KEEP GOING
set +e

###### CALL THE FTP CRON JOBS
###### FIRST WE GET THE FILES FROM PX
( "/home/ubuntu/bin/2020_px.file.handling.sh" )
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
sleep 5s

##### HALT AND CATCH FIRE IF ANY COMMAND FAILS FROM HERE ON
set -e



# DELETE TEMP CARDACTIVITY TABLE IF IT EXISTS
mysql  --login-path=local --silent -DSRG_2020 -N -e "DROP TABLE IF EXISTS cardactivity_temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'cardactivity_temp TABLE DROPPED, STARTING NEW TEMP TABLE CREATION'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_2020 -N -e "CREATE TABLE cardactivity_temp LIKE cardactivity_structure"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'cardactivity_temp CREATED FROM cardactivity_structure, LOADING infile.cardactivity.csv DATA INTO cardactivity_temp'





# Load the data from the latest file into the (temp) CardActivity table
############### DUMMY FIELDS TO KEEP ALIGNMENT WITH PAYTRONIX ALTERATIONS TO TABLE STRUCTURE
mysql  --login-path=local --silent -DSRG_2020 -N -e "Load data local infile '/home/ubuntu/db_files/incoming/px/infile.cardactivity.csv' into table cardactivity_temp fields terminated by ',' lines terminated by '\n' (CardNumber,AccountCode,CustomerNo,CardTemplate,TransactionDate,TransactionType,StoreMerchant,StoreNumber,StoreName,WalletType,CheckNo,TerminalID,CashierID,IdentificationMethod,AccountStatus,Promotion,AuthCode,Sender,Dummy1,Dummy2,Dummy3,Dummy4,Dummy5,Dummy6,Dummy_Checkins_Accrued,Dummy_Checkins_Redeemed,Dummy_Checkins_Balance,Checkins_Accrued,Checkins_Redeemed,Checkins_Balance,Qualified_Checkins_Accrued,Qualified_Checkins_Redeemed,Qualified_Checkins_Balance,SurveyAccrued,SurveyRedeemed,SurveyBalance,NewsletterAccrued,NewsletterRedeemed,NewsletterBalance,LifetimeSpendAccrued,LifetimeSpendRedeemed,LifetimeSpendBalance,3000BonusPointsAccrued,3000BonusPointsRedeemed,3000BonusPointsBalance,RegAppAccrued,RegAppRedeemed,RegAppBalance,BdayEntreeAccrued,BdayEntreeRedeemed,BdayEntreeBalance,Dummy7,Dummy8,Dummy9,LTOAccrued,LTORedeemed,LTOBalance,LTObucksAccrued,LTObucksRedeemed,LTObucksBalance,CheckSubtotalAccrued,CheckSubtotalRedeemed,CheckSubtotalBalance,DollarsSpentAccrued,DollarsSpentRedeemed,DollarsSpentBalance,KidsMenuTrackingAccrued,KidsMenuTrackingRedeemed,KidsMenuTrackingBalance,BeerTrackingAccrued,BeerTrackingRedeemed,BeerTrackingBalance,SushiTrackingAccrued,SushiTrackingRedeemed,SushiTrackingBalance,WineTrackingAccrued,WineTrackingRedeemed,WineTrackingBalance,StoreRegisteredAccrued,StoreRegisteredRedeemed,StoreRegisteredBalance,SereniteePointsAccrued,SereniteePointsRedeemed,SereniteePointsBalance,LifetimePointsAccrued,LifetimePointsRedeemed,LifetimePointsBalance,100PointsIncrementAccrued,100PointsIncrementRedeemed,100PointsIncrementBalance,FreeEntreeAccrued,FreeEntreeRedeemed,FreeEntreeBalance,Dummy10,Dummy11,Dummy12,FreeAppAccrued,FreeAppRedeemed,FreeAppBalance,FreeDessertAccrued,FreeDessertRedeemed,FreeDessertBalance,FreePizzaAccrued,FreePizzaRedeemed,FreePizzaBalance,FreeSushiAccrued,FreeSushiRedeemed,FreeSushiBalance,5500PointsAccrued,5500PointsRedeemed,5500PointsBalance,3500PointsAccrued,3500PointsRedeemed,3500PointsBalance,2500PointsAccrued,2500PointsRedeemed,2500PointsBalance,1Kpts5bksAccrued,1Kpts5bksRedeemed,1Kpts5bksBalance,VisitsAccrued,VisitsRedeemed,VisitsBalance,TWKTripAccrued,TWKTripRedeemed,TWKTripBalance,SpotTripAccrued,SpotTripRedeemed,SpotTripBalance,MagsTripAccrued,MagsTripRedeemed,MagsTripBalance,OpusTripAccrued,OpusTripRedeemed,OpusTripBalance,WalnutTripAccrued,WalnutTripRedeemed,WalnutTripBalance,HaleTripAccrued,HaleTripRedeemed,HaleTripBalance,CalasTripAccrued,CalasTripRedeemed,CalasTripBalance,LatTripAccrued,LatTripRedeemed,LatTripBalance,HBTripAccrued,HBTripRedeemed,HBTripBalance,SereniteeAccrued,SereniteeRedeemed,SereniteeBalance,BandCompAccrued,BandCompRedeemed,BandCompBalance,GreenDollarsAccrued,GreenDollarsRedeemed,GreenDollarsBalance,GreenLATAppAccrued,GreenLATAppRedeemed,GreenLATAppBalance,GreenALCAppAccrued,GreenALCAppRedeemed,GreenALCAppBalance,GreenOPUSAppAccrued,GreenOPUSAppRedeemed,GreenOPUSAppBalance,GreenCALAppAccrued,GreenCALAppRedeemed,GreenCALAppBalance,GreenSPOTAppAccrued,GreenSPOTAppRedeemed,GreenSPOTAppBalance,GreenHALEAppAccrued,GreenHALEAppRedeemed,GreenHALEAppBalance,GreenWINCAppAccrued,GreenWINCAppRedeemed,GreenWINCAppBalance,GreenMAGsAppAccrued,GreenMAGsAppRedeemed,GreenMAGsAppBalance,GreenWALAppAccrued,GreenWALAppRedeemed,GreenWALAppBalance,CompAccrued,CompRedeemed,CompBalance,SereniteeGiftCardAccrued,SereniteeGiftCardRedeemed,SereniteeGiftCardBalance,SVDiscountTrackingAccrued,SVDiscountTrackingRedeemed,SVDiscountTrackingBalance)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'CARDACTIVITY DATA LOADED INTO cardactivity_temp'


########### COPY DATA PRE-MANIPULATION INTO THE CARDACTIVITY_RAW TABLE
mysql  --login-path=local --silent -DSRG_2020 -N -e "INSERT INTO cardactivity_raw SELECT * FROM cardactivity_temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'cardactivity_raw TABLE UPDATED WITH CARD ACTIVITY FROM TEMP DATA TABLE (PRE_MANIPULATION)'


### INDEX CARD TEMPLATE AND TRANSACTIONTYPE, CardNumber
mysql  --login-path=local --silent -DSRG_2020 -N -e "ALTER TABLE cardactivity_temp ADD INDEX(TransactionType)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_2020 -N -e "ALTER TABLE cardactivity_temp ADD INDEX(CardNumber)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

echo 'CARDACTIVITY -dev- TransactionType and CardNumber indexed'


echo 'DELETING EXTRANEOUS RECORDS BY TRANSACTION TYPES'
### REMOVE ANY/ALL RECORDS THAT ARE NOT WORTH PROCESSING ! ! ! !
mysql  --login-path=local --silent -DSRG_2020 -N -e "DELETE FROM cardactivity_temp WHERE CardTemplate != 'Serenitee Loyalty'"
echo '10% deleted'
mysql  --login-path=local --silent -DSRG_2020 -N -e "DELETE FROM cardactivity_temp WHERE TransactionType = 'Identify Customer'"
echo '25% deleted'
mysql  --login-path=local --silent -DSRG_2020 -N -e "DELETE FROM cardactivity_temp WHERE TransactionType = 'Web Reward Purchase'"
echo '30% deleted'
mysql  --login-path=local --silent -DSRG_2020 -N -e "DELETE FROM cardactivity_temp WHERE TransactionType = 'Admin Adjustment'"
echo '35% deleted'
mysql  --login-path=local --silent -DSRG_2020 -N -e "DELETE FROM cardactivity_temp WHERE TransactionType = 'Denied Campaign Adjustment'"
echo '40% deleted'
mysql  --login-path=local --silent -DSRG_2020 -N -e "DELETE FROM cardactivity_temp WHERE TransactionType = 'Denied Accrual / Redemption'"
echo '45% deleted'
mysql  --login-path=local --silent -DSRG_2020 -N -e "DELETE FROM cardactivity_temp WHERE TransactionType = 'Denied Activate'"
echo '50% deleted'
# NEXT QUERY ACCOUNTS FOR IOS/ANDROID IN CHECKNO FIELD
mysql  --login-path=local --silent -DSRG_2020 -N -e "DELETE FROM cardactivity_temp WHERE TransactionType = 'Check-In'"
echo '55% deleted'
mysql  --login-path=local --silent -DSRG_2020 -N -e "DELETE FROM cardactivity_temp WHERE TransactionType = 'Campaign Adjustment'"
echo '60% deleted'
mysql  --login-path=local --silent -DSRG_2020 -N -e "DELETE FROM cardactivity_temp WHERE TransactionType = 'Balance Inquiry'"
echo '65% deleted'
mysql  --login-path=local --silent -DSRG_2020 -N -e "DELETE FROM cardactivity_temp WHERE TransactionType = 'Denied Balance Inquiry'"
echo '70% deleted'
mysql  --login-path=local --silent -DSRG_2020 -N -e "DELETE FROM cardactivity_temp WHERE TransactionType = 'Campaign Expiration'"
echo '75% deleted'
mysql  --login-path=local --silent -DSRG_2020 -N -e "DELETE FROM cardactivity_temp WHERE TransactionType IS NULL"
echo '90% deleted'
mysql  --login-path=local --silent -DSRG_2020 -N -e "DELETE FROM cardactivity_temp WHERE CardNumber = '0'"
echo '100% deleted, ADDING LOCATIONID FIELD'

# CREATE LOCATIONID FIELD
mysql  --login-path=local --silent -DSRG_2020 -N -e "ALTER TABLE cardactivity_temp ADD LocationID INT( 3 ) first"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'ADDED LOCATIONID FIELD TO TEMP TABLE, UPDATING LOCATIONS'

##### UPDATE LOCATIONID
mysql  --login-path=local --silent -DSRG_2020 -N -e "UPDATE cardactivity_temp set LocationID = (SELECT ID from Locations WHERE Locations.PXID = cardactivity_temp.StoreNumber)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'UPDATED LOCATIONID FROM locations TABLE, FORMATTING TransactionDate FIELD'

##### UPDATE RAW DOB TO VARCHAR
# UPDATE THE DOB TO VARCHAR
mysql  --login-path=local --silent -DSRG_2020 -N -e "ALTER TABLE cardactivity_temp modify TransactionDate VARCHAR(40)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_2020 -N -e "ALTER TABLE cardactivity_temp ADD COLUMN TransactionTime VARCHAR(10) AFTER TransactionDate"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_2020 -N -e "UPDATE cardactivity_temp SET TransactionTime = RIGHT(TransactionDate, 5)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_2020 -N -e "UPDATE cardactivity_temp SET TransactionDate = LEFT(TransactionDate,10)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

echo 'DOB NOW VARCHAR, UPDATING TO SQL'

# PUT TransactionDate INTO SQL FORMAT
mysql  --login-path=local --silent -DSRG_2020 -N -e "UPDATE cardactivity_temp SET TransactionDate= STR_TO_DATE(TransactionDate, '%Y-%m-%d') WHERE STR_TO_DATE(TransactionDate, '%Y-%m-%d') IS NOT NULL"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'DOB NOW SQL FORMAT, UPDATING TO DATE FORMAT'

# Change TransactionDate field to type date
mysql  --login-path=local --silent -DSRG_2020 -N -e "ALTER TABLE cardactivity_temp CHANGE TransactionDate TransactionDate DATE"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'DOB NOW DATE FORMAT, ADDING POSkey field'

# Create POSkey field
mysql  --login-path=local --silent -DSRG_2020 -N -e "ALTER TABLE cardactivity_temp ADD POSkey VARCHAR(30) first"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'POSkey FIELD ADDED, ADDING Exceldate FIELD'

# Create excel date field
mysql  --login-path=local --silent -DSRG_2020 -N -e "ALTER TABLE cardactivity_temp ADD Exceldate INT(100) AFTER LocationID"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'Exceldate FIELD ADDED, POPULATING ExcelDate FIELD'

# Update excel date field
mysql  --login-path=local --silent -DSRG_2020 -N -e "UPDATE cardactivity_temp set Exceldate = (((unix_timestamp(TransactionDate) / 86400) + 25569) + (-5/24))"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'ExcelDate FIELD POPULATED, CREATING POSkey VALUES'


# Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
mysql  --login-path=local --silent -DSRG_2020 -N -e "UPDATE cardactivity_temp set POSkey = CONCAT_WS('', LocationID, Exceldate, CheckNo)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'POSkeys CREATED'


### INDEX CARD TEMPLATE AND TRANSACTIONTYPE, CardNumber
mysql  --login-path=local --silent -DSRG_2020 -N -e "ALTER TABLE cardactivity_temp ADD INDEX(CheckNo)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'CARDACTIVITY -dev- CheckNo indexed'


# this 
##################### ITERATE UPDATE TO CA CheckNumbers MISSING LEADIN "100"
############################## THIS IS WHY CHECKDETAIL HAS TO RUN EARLIER THAN CA 
mysql  --login-path=local --silent -DSRG_2020 -N -e "SELECT RIGHT(CheckNumber, 4), DOB, LocationID FROM CheckDetail_Live WHERE CheckDetail_Live.CheckNumber like '100%' 
							AND DOB >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) ORDER BY DOB ASC" | while read -r CheckNumber DOB LocationID;
do
	mysql  --login-path=local --silent -DSRG_2020 -N -e "UPDATE cardactivity_temp SET CheckNo=CONCAT('100',CheckNo) WHERE CheckNo = '$CheckNumber' AND TransactionDate = '$DOB' 
								AND LocationID = '$LocationID' AND char_length(CheckNo) < '6'"
done
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'PX CHECKNUMBERS MISSING 100 FIXED, UPDATING POSKEYS IN TEMP TABLE'


echo 'CORRELATING/FIXING PX CHECKNUMBERS MISSING 100'
##### Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
mysql  --login-path=local --silent -DSRG_2020 -N -e "UPDATE cardactivity_temp set POSkey = CONCAT_WS('', LocationID, Exceldate, CheckNo)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'UPDATED POSKEYS IN TEMP TABLE'

######## DROP UNNEEDED TEMP FIELDS
mysql  --login-path=local --silent -DSRG_2020 -N -e "ALTER TABLE cardactivity_temp DROP Exceldate"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'DROPPED EXCEL DATE FIELD FROM CARDACTIVITY TEMP'


########### UPDATE THE CardActivitylive table
mysql  --login-path=local --silent -DSRG_2020 -N -e "INSERT INTO cardactivity_live SELECT * FROM cardactivity_temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'CARD ACTIVITY LIVE TABLE UPDATED WITH CARD ACTIVITY TEMP DATA'

################ SQUASHES *SHOULD* PROCESS FOR JUST THE DATES IN THE TEMP TABLE

mysql  --login-path=local --silent -DSRG_2020 -N -e "SELECT MAX(TransactionDate) FROM cardactivity_squashed" | while read -r Maxdate;
do
echo "MaxDate in CA Squashed: {$Maxdate}"

	#### DELETE IN CASE THERE ARE ANY STRAGGLERS
	mysql  --login-path=local --silent -DSRG_2020 -N -e "DELETE FROM cardactivity_squashed WHERE TransactionDate = '$Maxdate'";
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	echo 'MAX DATE DELETED FROM SQUASHED TABLE TO AVOID STRAGGLERS'


	############################ THE SQUASH ####################################
	############## SQUASH AND INSERT DATA FROM LIVE CardActivity ###############
	####### ONLY FOR LAST DATE
	####### should we do the FY and luna inserts here
	mysql  --login-path=local --silent -DSRG_2020 -N -e "INSERT INTO cardactivity_squashed
	SELECT
	DISTINCT(POSKey), LocationID, CardNumber, CardTemplate, TransactionDate, MIN(TransactionTime), MIN(checkno),
	SUM(Dummy1),SUM(Dummy2),MAX(Dummy3),
	SUM(Dummy4),SUM(Dummy5),MAX(Dummy6),
	SUM(Dummy_Checkins_Accrued),SUM(Dummy_Checkins_Redeemed),MAX(Dummy_Checkins_Balance),
	SUM(Checkins_Accrued),SUM(Checkins_Redeemed),MAX(Checkins_Balance),
	SUM(Qualified_Checkins_Accrued),SUM(Qualified_Checkins_Redeemed),MAX(Qualified_Checkins_Balance),
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
	SUM(FreeEntreeAccrued),SUM(FreeEntreeRedeemed),MAX(FreeEntreeBalance),
	SUM(Dummy10),SUM(Dummy11),MAX(Dummy12),
	SUM(FreeAppAccrued),SUM(FreeAppRedeemed),MAX(FreeAppBalance),
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
	FROM cardactivity_live
	WHERE TransactionDate >= '$Maxdate'
	AND TransactionType IN ('Accrual / Redemption','Activate')
	GROUP by POSKey, LocationID, CardNumber, CardTemplate, TransactionDate
	ORDER BY MAX(VisitsBalance)"

	echo 'SQUASH TABLE INCREMENTALLY UPDATED'


	######## FIX CHECKS THAT WERE OPEN ACROSS MIDNIGHT
	mysql  --login-path=local -DSRG_2020 -N -e "SELECT DISTINCT(CardNumber) FROM cardactivity_squashed WHERE CardNumber IS NOT NULL AND TransactionTime > '21:00:00' AND TransactionDate >= '$Maxdate'
							ORDER BY CardNumber ASC" | while read -r CardNumber;
	do
		######### GET DATA IF CHECK FROM BETWEEN MIDNIGHT AND 4 AM 
		mysql  --login-path=local -DSRG_2020 -N -e "SELECT POSkey, TransactionDate, CheckNo FROM cardactivity_squashed where cardnumber like $CardNumber
		AND TransactionTime > '00:00' and TransactionTime < '04:00' AND TransactionDate >= '$Maxdate'"| while read -r POSkey TransactionDate CheckNo;
		do
			########## GET THE POSkey FOR SAME CHECK FROM PREVIOUS DAY IF IT EXISTS
			POSkey_prev=$(mysql  --login-path=local -DSRG_2020 -N -e "SELECT POSkey FROM cardactivity_squashed where cardnumber like '$CardNumber' 
			AND TransactionDate = DATE_SUB('$TransactionDate', INTERVAL 1 DAY) AND CheckNo = '$CheckNo'")
			#### SET POSkey FOR LATER RECORD TO EARLIER DATES POSkey (IF PREVIOUS POSKEY EXISTS)
			if [ -n "$POSkey_prev" ]
			then		
				mysql  --login-path=local -DSRG_2020 -N -e "UPDATE cardactivity_squashed SET POSkey = '$POSkey_prev' WHERE POSkey = '$POSkey'"
			#	echo "CARD: "$CardNumber" Transdate1: "$TransactionDate" Check: "$CheckNo" Key1: "$POSkey" Key2: "$POSkey_prev 
			fi
		done

	done || trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


	#### DELETE FROM SQUASHED2 IN CASE THERE ARE ANY STRAGGLERS
	mysql  --login-path=local --silent -DSRG_2020 -N -e "DELETE FROM cardactivity_squashed_2 WHERE TransactionDate = '$Maxdate'";
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	echo 'MAX DATE DELETED FROM SQUASHED TABLE TO AVOID STRAGGLERS'

	###################################### SQUASH2 #########################################
	mysql  --login-path=local --silent -DSRG_2020 -N -e "INSERT INTO cardactivity_squashed_2
	SELECT
	DISTINCT(POSKey), LocationID, CardNumber, CardTemplate, MIN(TransactionDate), MIN(TransactionTime), MIN(checkno),
	SUM(Dummy1),SUM(Dummy2),MAX(Dummy3),
	SUM(Dummy4),SUM(Dummy5),MAX(Dummy6),
	SUM(Dummy_Checkins_Accrued),SUM(Dummy_Checkins_Redeemed),MAX(Dummy_Checkins_Balance),
	SUM(Checkins_Accrued),SUM(Checkins_Redeemed),MAX(Checkins_Balance),
	SUM(Qualified_Checkins_Accrued),SUM(Qualified_Checkins_Redeemed),MAX(Qualified_Checkins_Balance),
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
	SUM(FreeEntreeAccrued),SUM(FreeEntreeRedeemed),MAX(FreeEntreeBalance),
	SUM(Dummy10),SUM(Dummy11),MAX(Dummy12),
	SUM(FreeAppAccrued),SUM(FreeAppRedeemed),MAX(FreeAppBalance),
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

	FROM cardactivity_squashed
	WHERE TransactionDate >= '$Maxdate'
	GROUP by POSKey, LocationID, CardNumber, CardTemplate
	ORDER BY MAX(VisitsBalance)"

	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	echo 'NEW SQUASHED DATA TABLE    2    POPULATED'

done
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

echo 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'

echo 'DEV.PX.CA.PROCESS.SH COMPLETED'




