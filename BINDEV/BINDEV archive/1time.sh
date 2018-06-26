#! //bin/bash
# LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# UNCOMMENT NEXT FOR VERBOSE
set -x
##### HALT AND CATCH FIRE IF ANY COMMAND FAILS
set -e


######### UBER JOIN LIVE CHECK DETAIL WITH LIVE SQUASHED CARD ACTIVITY

#### Double check UNION !!!!!!!!!!!!!!!!

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test JOIN Px_exchanges ON Master_test.CardNumber = Px_exchanges.CurrentCardNumber SET Master_test.Account_status = 'Exchange'"
echo 'EXCHANGED accounts account status updated from px_exchanges table'
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test JOIN Excludes ON Master_test.CardNumber = Excludes.CardNumber SET Master_test.Account_status = 'Exclude'"
echo 'EXCLUDED accounts account status updated from Excludes table'


######## UPDATE THE EMPTY CHECKDETAIL FIELDS WITH PX DATA

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET CheckNumber = CheckNo WHERE CheckNo IS NULL"
echo Empty CheckNumber-s populated from CheckNo

mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET DOB = TransactionDate WHERE DOB IS NULL"
echo Empty DOB-s populated from TransactionDate
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET LocationID = LocationID_px WHERE LocationID IS NULL"
echo Empty LocationID-s populated form LocationID_px
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET POSkey = POSKey_px WHERE POSkey IS NULL"
echo Empty POSkey-s populated from POSkey_px
mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master_test SET GrossSalesCoDefined = DollarsSpentAccrued WHERE GrossSalesCoDefined IS NULL"
echo 'Empty GrossSalesCoDefined-s Populated (PROMOS OR COMPS COULD NOT BE ADD, LOWBALL FIGURES)'

