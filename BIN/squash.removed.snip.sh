
mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE CardActivity_Live SET
	Dummy1 = '0', Dummy2 = '0', Dummy3 = '0', Dummy4 = '0', Dummy5 = '0', Dummy6 = '0',Dummy7 = '0',
	Dummy8 = '0', Dummy9 = '0' WHERE Dummy1 IS NULL"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'CARD ACTIVITY LIVE TABLE DUMMY FIELD NULLS CHANGED TO 0'


################ THE SQUASHES RUN ON ALL DATA COULD THEY JUST RUN ON MOST RECENT?

mysql  --login-path=local --silent -DSRG_Prod -N -e "SELECT MAX(TransactionDate) FROM CardActivity_squashed" | while read -r Maxdate;
do

	#### DELETE IN CASE THERE ARE ANY STRAGGLERS
	mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE FROM CardActivity_squashed WHERE TransactionDate = '$Maxdate'";
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	echo 'MAX DATE DELETED FROM SQUASHED TABLE TO AVOID STRAGGLERS'


	############################ THE SQUASH ####################################
	############## SQUASH AND INSERT DATA FROM LIVE CardActivity ###############
	####### ONLY FOR LAST DATE
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
	WHERE TransactionDate >= '$Maxdate'
	AND TransactionType IN ('Accrual / Redemption','Activate')
	GROUP by POSKey, LocationID, CardNumber, CardTemplate, TransactionDate"

	echo 'SQUASH TABLE INCREMENTALLY UPDATED'


	######## FIX CHECKS THAT WERE OPEN ACROSS MIDNIGHT
	mysql  --login-path=local -DSRG_Prod -N -e "SELECT DISTINCT(CardNumber) FROM CardActivity_squashed WHERE CardNumber IS NOT NULL AND TransactionTime > '21:00:00' AND TransactionDate >= '$Maxdate'
							ORDER BY CardNumber ASC" | while read -r CardNumber;
	do
		######### GET DATA IF CHECK FROM BETWEEN MIDNIGHT AND 4 AM 
		mysql  --login-path=local -DSRG_Prod -N -e "SELECT POSkey, TransactionDate, CheckNo FROM CardActivity_squashed where cardnumber like $CardNumber
		AND TransactionTime > '00:00' and TransactionTime < '04:00' AND TransactionDate >= '$Maxdate'"| while read -r POSkey TransactionDate CheckNo;
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


	#### DELETE FROM SQUASHED2 IN CASE THERE ARE ANY STRAGGLERS
	mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE FROM CardActivity_squashed_2 WHERE TransactionDate = '$Maxdate'";
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	echo 'MAX DATE DELETED FROM SQUASHED TABLE TO AVOID STRAGGLERS'

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
	AND TransactionDate >= '$Maxdate'
	GROUP by POSKey, LocationID, CardNumber, CardTemplate"
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	echo 'NEW SQUASHED DATA TABLE    2    POPULATED'

done
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

echo 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'

