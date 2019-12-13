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


## REMOVE (1) HEADER ROW AND MERGE (IF NECCESSARY) INCOMING CARD ACTIVITY CSVs
## INTO SINGLE CARD ACTIVITY FILE IN DB_FILES
for file in /home/ubuntu/db_files/incoming/px/CardActivity*.csv
  do
	#### MAKE A COPY OF THE FILE IN BACKUP DIR
	cp "$file" //home/ubuntu/db_files/incoming/px/backup/
	tail -n+2 "$file"  >> /home/ubuntu/db_files/incoming/px/Infile.CardActivity.csv
  done || trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'INCOMING PX {dev} DATA FILES CLEANED AND MERGED, ARCHIVING ORIGINAL FILES'


# Delete Temp table if it exists
mysql  --login-path=local --silent -DSRG_Prod -N -e "DROP TABLE IF EXISTS CardActivity_Temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'CardActivity_Temp TABLE DROPPED, STARTING NEW TEMP TABLE CREATION'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_Prod -N -e "CREATE TABLE CardActivity_Temp LIKE CardActivity_Structure"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'CardActivity_Temp RE-CREATED, LOADING DATA FILE TO TEMP TABLE'

# Load the data from the latest file into the (temp) CardActivity table
############### DUMMY FIELDS TO KEEP ALIGNMENT WITH PAYTRONIX ALTERATIONS TO TABLE STRUCTURE
mysql  --login-path=local --silent -DSRG_Prod -N -e "Load data local infile '/home/ubuntu/db_files/incoming/px/Infile.CardActivity.csv' into table CardActivity_Raw fields terminated by ',' lines terminated by '\n' (CardNumber,AccountCode,CustomerNo,CardTemplate,TransactionDate,TransactionType,StoreMerchant,StoreNumber,StoreName,WalletType,CheckNo,TerminalID,CashierID,IdentificationMethod,AccountStatus,Promotion,AuthCode,Sender,Dummy1,Dummy2,Dummy3,Dummy4,Dummy5,Dummy6,Dummy_Checkins_Accrued,Dummy_Checkins_Redeemed,Dummy_Checkins_Balance,Checkins_Accrued,Checkins_Redeemed,Checkins_Balance,Qualified_Checkins_Accrued,Qualified_Checkins_Redeemed,Qualified_Checkins_Balance,SurveyAccrued,SurveyRedeemed,SurveyBalance,NewsletterAccrued,NewsletterRedeemed,NewsletterBalance,LifetimeSpendAccrued,LifetimeSpendRedeemed,LifetimeSpendBalance,3000BonusPointsAccrued,3000BonusPointsRedeemed,3000BonusPointsBalance,RegAppAccrued,RegAppRedeemed,RegAppBalance,BdayEntreeAccrued,BdayEntreeRedeemed,BdayEntreeBalance,Dummy7,Dummy8,Dummy9,LTOAccrued,LTORedeemed,LTOBalance,LTObucksAccrued,LTObucksRedeemed,LTObucksBalance,CheckSubtotalAccrued,CheckSubtotalRedeemed,CheckSubtotalBalance,DollarsSpentAccrued,DollarsSpentRedeemed,DollarsSpentBalance,KidsMenuTrackingAccrued,KidsMenuTrackingRedeemed,KidsMenuTrackingBalance,BeerTrackingAccrued,BeerTrackingRedeemed,BeerTrackingBalance,SushiTrackingAccrued,SushiTrackingRedeemed,SushiTrackingBalance,WineTrackingAccrued,WineTrackingRedeemed,WineTrackingBalance,StoreRegisteredAccrued,StoreRegisteredRedeemed,StoreRegisteredBalance,SereniteePointsAccrued,SereniteePointsRedeemed,SereniteePointsBalance,LifetimePointsAccrued,LifetimePointsRedeemed,LifetimePointsBalance,100PointsIncrementAccrued,100PointsIncrementRedeemed,100PointsIncrementBalance,FreeAppAccrued,FreeAppRedeemed,FreeAppBalance,Dummy10,Dummy11,Dummy12,FreeEntreeAccrued,FreeEntreeRedeemed,FreeEntreeBalance,FreeDessertAccrued,FreeDessertRedeemed,FreeDessertBalance,FreePizzaAccrued,FreePizzaRedeemed,FreePizzaBalance,FreeSushiAccrued,FreeSushiRedeemed,FreeSushiBalance,5500PointsAccrued,5500PointsRedeemed,5500PointsBalance,3500PointsAccrued,3500PointsRedeemed,3500PointsBalance,2500PointsAccrued,2500PointsRedeemed,2500PointsBalance,1Kpts5bksAccrued,1Kpts5bksRedeemed,1Kpts5bksBalance,VisitsAccrued,VisitsRedeemed,VisitsBalance,TWKTripAccrued,TWKTripRedeemed,TWKTripBalance,SpotTripAccrued,SpotTripRedeemed,SpotTripBalance,MagsTripAccrued,MagsTripRedeemed,MagsTripBalance,OpusTripAccrued,OpusTripRedeemed,OpusTripBalance,WalnutTripAccrued,WalnutTripRedeemed,WalnutTripBalance,HaleTripAccrued,HaleTripRedeemed,HaleTripBalance,CalasTripAccrued,CalasTripRedeemed,CalasTripBalance,LatTripAccrued,LatTripRedeemed,LatTripBalance,HBTripAccrued,HBTripRedeemed,HBTripBalance,SereniteeAccrued,SereniteeRedeemed,SereniteeBalance,BandCompAccrued,BandCompRedeemed,BandCompBalance,GreenDollarsAccrued,GreenDollarsRedeemed,GreenDollarsBalance,GreenLATAppAccrued,GreenLATAppRedeemed,GreenLATAppBalance,GreenALCAppAccrued,GreenALCAppRedeemed,GreenALCAppBalance,GreenOPUSAppAccrued,GreenOPUSAppRedeemed,GreenOPUSAppBalance,GreenCALAppAccrued,GreenCALAppRedeemed,GreenCALAppBalance,GreenSPOTAppAccrued,GreenSPOTAppRedeemed,GreenSPOTAppBalance,GreenHALEAppAccrued,GreenHALEAppRedeemed,GreenHALEAppBalance,GreenWINCAppAccrued,GreenWINCAppRedeemed,GreenWINCAppBalance,GreenMAGsAppAccrued,GreenMAGsAppRedeemed,GreenMAGsAppBalance,GreenWALAppAccrued,GreenWALAppRedeemed,GreenWALAppBalance,CompAccrued,CompRedeemed,CompBalance,SereniteeGiftCardAccrued,SereniteeGiftCardRedeemed,SereniteeGiftCardBalance,SVDiscountTrackingAccrued,SVDiscountTrackingRedeemed,SVDiscountTrackingBalance)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'CARDACTIVITY DATA LOADED INTO CardActivity_Temp'

