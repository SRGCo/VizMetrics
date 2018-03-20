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




############## SQUASH AND INSERT DATA FROM LIVE CardActivity ###############
####### should we do the FY and luna inserts here
mysql  --login-path=local --silent -DSRG_Dev -N -e "INSERT INTO SRG_px.CardActivity_squashed
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
'0','0','0','0','0','0','0','0'

FROM CardActivity_Live

WHERE LocationID IS NOT NULL AND CardTemplate = 'Serenitee Loyalty'  AND CheckNo <> '9999999'
AND (TransactionType = 'Accrual / Redemption' OR TransactionType = 'Activate')

GROUP by POSKey, LocationID, CardNumber, CardTemplate, TransactionDate"

echo 'SQUASHED DATA TABLE POPULATED'


##### CALC THE (non-dynamic) FREQUENCY FIELDS -FY Y-LUNA
##### FIRST 4 CHARS of TransactionDate BECOME FY
##################### ITERATE ON POSkey 
###### -N is the No Headers in Output option
###### -e is the 'read statement and quit'
mysql  --login-path=local -DSRG_Dev -N -e "SELECT TransactionDate FROM Master GROUP BY TransactionDate ORDER BY TransactionDate ASC" | while read -r TransactionDate;
do
	######## GET FY FOR THIS TransactionDate (DOB)
	FY=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT FY from Lunas WHERE DOB = '$TransactionDate'")

	######## GET FY FOR THIS TransactionDate (DOB)
	Luna=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT Luna from Lunas WHERE DOB = '$TransactionDate'")


			##### UPDATE FISCAL YEAR FROM TRANSACTIONDATE
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET FY = '$FY', Luna = '$Luna' WHERE TransactionDate = '$TransactionDate'"
			echo $TransactionDate updated FY= $FY Luna = $Luna
done


echo FY & Y-LUNA CALCD & POPULATED

