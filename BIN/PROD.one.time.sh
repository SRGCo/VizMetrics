#! //bin/bash
# LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# UNCOMMENT NEXT FOR VERBOSE
# set -x
##### HALT AND CATCH FIRE IF ANY COMMAND FAILS
# set -e

##### USE time command to calc runtime "time DEV.cd.ca.into.master.sh"

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




################# PROCESS EXCHANGES
## REMOVE (1) HEADER ROW AND MERGE (IF NECCESSARY) INCOMING EXCHANGES CSVs
## INTO SINGLE CARD ACTIVITY FILE IN DB_FILES
for file in /home/ubuntu/db_files/incoming/px/MediaExchanges*.csv
  do
	#### MAKE A COPY OF THE FILE IN BACKUP DIR
	cp "$file" //home/ubuntu/db_files/incoming/px/backup/
	tail -n+2 "$file"  >> /home/ubuntu/db_files/incoming/px/Infile.MediaExchanges.csv
	rm "$file"
  done || trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'INCOMING EXCHANGES DATA FILES BACKEDUP, CLEANED AND MERGED'

## TRUNCATE GUESTS TABLE BEFORE LOADING W NEW
# Delete Temp table if it exists
mysql  --login-path=local --silent -DSRG_Prod -N -e "DROP TABLE IF EXISTS Px_exchanges_temp"
echo 'PX EXCHANGES TEMP TABLE DROPPED, STARTING NEW PX EXCHANGES TEMP TABLE CREATION'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_Prod -N -e "CREATE TABLE Px_exchanges_temp LIKE Px_exchanges_structure"
echo 'PX EXCHANGES TEMP TABLE CREATED, LOADING DATA FILE TO PX EXCHANGES TEMP TABLE'

# Load the data from the latest file into the (temp) CardActivity table
mysql  --login-path=local --silent -DSRG_Prod -N -e "Load data local infile '/home/ubuntu/db_files/incoming/px/Infile.MediaExchanges.csv' into table Px_exchanges_temp fields terminated by ','  lines terminated by '\n'"
echo 'PX EXCHANGES TEMP loaded'
	
#Load the temp data into the live table
mysql  --login-path=local -DSRG_Prod -N -e "INSERT INTO Px_exchanges SELECT * FROM Px_exchanges_temp"
echo 'PX EXCHANGES TABLE LOADED WITH DATA FROM TEMP TABLE'


# DELETE CURRENT INFILE TO READY FOR NEXT RUN
rm -f   /home/ubuntu/db_files/incoming/px/Infile.MediaExchanges.csv


################# PROCESS EXCHANGES WITH PHP SUBROUTINE
( "/home/ubuntu/bin/PROD.px.exchanges.process.php" )
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER- EXCHANGED CARDS PROCESS/FIXED, ACCOUNT STATUS UPDATED TO -Exchange-'


######### EXCLUDES SECTION USE OR NOT ? ? ?
# mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master JOIN Excludes ON Master.CardNumber = Excludes.CardNumber SET Master.Account_status = 'Exclude' "
# trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER - NO ACCOUNTS EXCLUDED!!! (Exclusion routine commented out)'








######## UPDATE THE EMPTY CHECKDETAIL FIELDS WITH PX DATA
mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET CheckNumber = CheckNo_px WHERE CheckNumber IS NULL "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER EMPTY CHECKNO POPULATED FROM PX DATA'


mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET LocationID = LocationID_px WHERE LocationID IS NULL "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER EMPTY LOCATION ID POPULATED FROM PX DATA'

mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET POSkey = POSKey_px WHERE POSkey IS NULL "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER EMPTY POS KEYS POPULATED FROM PX DATA'

mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET DOB = TransactionDate WHERE DOB IS NULL "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER EMPTY DOB POPULATED FROM PX DATA'



mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET GrossSalesCoDefined = DollarsSpentAccrued WHERE GrossSalesCoDefined IS NULL 
						AND Master.Account_status <> 'TERMIN' AND Master.Account_status <> 'SUSPEN' 
						AND Master.Account_status <> 'Exchanged' AND Master.Account_status <> 'Exchange' 
						AND Master.Account_status <> 'Exclude' AND DollarsSpentAccrued IS NOT NULL"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER GROSSSALESCODEFINED FIELD POPULATED'
echo '(PROMOS OR COMPS COULD NOT BE ADDED, LOWBALL FIGURES)'


###### -N is the No Headers in Output option
###### -e is the 'read statement and quit'
######## WE ARE ###

mysql  --login-path=local -DSRG_Prod -N -e "SELECT Master.DOB FROM Master WHERE Master.DOB IS NOT NULL AND DOB >= DATE_SUB(NOW(),INTERVAL 45 DAY) 
				GROUP BY Master.DOB ORDER BY Master.DOB DESC" | while read -r DOB;
do

		######## GET FY FOR THIS DOB (DOB)
		FY=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT FY from Lunas WHERE DOB = '$DOB'")

		######## GET FY FOR THIS DOB (DOB)
		YLuna=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT YLuna from Lunas WHERE DOB = '$DOB'")

		######## GET FY FOR THIS DOB (DOB)
		Luna=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT Luna from Lunas WHERE DOB = '$DOB'")

		######## IF VARIABLE HAS NO VALUE SET TO NULL
		if [ -z $Luna ] 
		then 
		Luna='0'
		fi

		##### UPDATE FISCAL YEAR FROM DOB
		mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET FY = '$FY',YLuna = '$YLuna', Luna='$Luna' WHERE Master.DOB = '$DOB'"
		#echo $DOB updated FY= $FY YLuna = $YLuna  Luna = $Luna

done
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER FY YLUNA FIELDS UPATED WITH DATA FROM LUNA TABLE'


