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


mysql  --login-path=local --silent -DSRG_Prod-1-27-20 -N -e "SELECT DISTINCT(POSKey) FROM CardActivity_Live" | while read -r POSkey_db;
do
echo "Squashing: {$POSkey_db}"


	############################ THE SQUASH ####################################
	############## SQUASH AND INSERT DATA FROM LIVE CardActivity ###############
	####### ONLY FOR LAST DATE
	####### should we do the FY and luna inserts here
	mysql  --login-path=local --silent -DSRG_Prod-1-27-20 -N -e "INSERT INTO CardActivity_squashed
	SELECT
	POSKey, LocationID, CardNumber, CardTemplate, TransactionDate, MIN(TransactionTime), MIN(checkno),
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
	FROM CardActivity_Live
	WHERE POSkey = '$POSkey_db'
	AND TransactionType IN ('Accrual / Redemption','Activate')
	GROUP by POSKey, LocationID, CardNumber, CardTemplate, TransactionDate
	ORDER BY MAX(VisitsBalance)"

done
echo 'SQUASH TABLE POPULATED CLEANLY'



######## FIX CHECKS THAT WERE OPEN ACROSS MIDNIGHT
mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "SELECT DISTINCT(CardNumber) FROM CardActivity_squashed WHERE CardNumber IS NOT NULL AND TransactionTime > '21:00:00'
						ORDER BY CardNumber ASC" | while read -r CardNumber;
do
	######### GET DATA IF CHECK FROM BETWEEN MIDNIGHT AND 4 AM 
	mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "SELECT POSkey, TransactionDate, CheckNo FROM CardActivity_squashed where cardnumber like $CardNumber
	AND TransactionTime > '00:00' and TransactionTime < '04:00'"| while read -r POSkey TransactionDate CheckNo;
	do
		########## GET THE POSkey FOR SAME CHECK FROM PREVIOUS DAY IF IT EXISTS
		POSkey_prev=$(mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "SELECT POSkey FROM CardActivity_squashed where cardnumber like '$CardNumber' 
		AND TransactionDate = DATE_SUB('$TransactionDate', INTERVAL 1 DAY) AND CheckNo = '$CheckNo'")

			#### SET POSkey FOR LATER RECORD TO EARLIER DATES POSkey (IF PREVIOUS POSKEY EXISTS)
			if [ -n "$POSkey_prev" ]
			then		
				mysql  --login-path=local -DSRG_Prod-1-27-20 -N -e "UPDATE CardActivity_squashed SET POSkey = '$POSkey_prev' WHERE POSkey = '$POSkey'"
			#	echo "CARD: "$CardNumber" Transdate1: "$TransactionDate" Check: "$CheckNo" Key1: "$POSkey" Key2: "$POSkey_prev 
			fi
	done

done || trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

mysql  --login-path=local --silent -DSRG_Prod-1-27-20 -N -e "SELECT DISTINCT(POSKey) FROM CardActivity_squashed" | while read -r POSkey_db;
do
	echo "Squashing: {$POSkey_db}"


	###################################### SQUASH2 #########################################
	mysql  --login-path=local --silent -DSRG_Prod-1-27-20 -N -e "INSERT INTO CardActivity_squashed_2
	SELECT
	POSKey, LocationID, CardNumber, CardTemplate, MIN(TransactionDate), MIN(TransactionTime), MIN(checkno),
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

	FROM CardActivity_squashed
	WHERE POSkey = '$POSkey_db'
	GROUP by POSKey, LocationID, CardNumber, CardTemplate
	ORDER BY MAX(VisitsBalance)"
done

	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	echo 'NEW SQUASHED DATA TABLE    2    POPULATED'


trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

echo 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'

echo 'FIX SQUASH BALANCES'





