#! /bin/bash
### OK 8-29-18 #####

# UNCOMMENT TO LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# Next line turns echo on
# set -x

####### USES CTUIT EXPORTS #########
## 1 ## TableTurn [all company by date][TableTurns.raw.csv]
## 2 ## Employees
## 3 ## CheckDetail - Full by date [CheckDetail.update.raw.csv]

########### FUNCTIONS #####################################
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

TEMPFILE=$$.tmp
echo 0 > $TEMPFILE



########################## 
##########################   WE NEED TO HAVE CARD ACTIVITY SQUASHED BECOME A LIVE TABLE THAT GETS UPDATED INCREMENTALLY
########################## THEN WE CAN RUN THIS FIX ON ONLY THE NEW TRANSACTIONS
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
		#	mysql  --login-path=local -DSRG_Prod -N -e "UPDATE CardActivity_squashed SET POSkey = '$POSkey_prev' WHERE POSkey = '$POSkey'"
			echo "CARD: "$CardNumber" Transdate1: "$TransactionDate" Check: "$CheckNo" Key1: "$POSkey" Key2: "$POSkey_prev 
			Count=$[$(cat $TEMPFILE) + 1]
			echo $Count
			echo $Count > $TEMPFILE
		fi
	done


done
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
unlink $TEMPFILE
