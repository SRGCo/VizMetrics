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


####### FIRST WE TAKE CARE OF DUPE POSKEYS IN CA
( "/home/ubuntu/bin/PROD.POSkey.dedupe.php" )
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'DUPLICATE POSKEYS PROCESS/FIXED'


############################## FIRST WE PROCESS/UPDATE THE GUEST DATA #############################
################# TABLETURNS ##############################
## REMOVE (2) HEADER ROW AND MERGE (IF NECCESSARY) INCOMING GUESTS CSVs
## INTO SINGLE CARD ACTIVITY FILE IN DB_FILES/incoming/px
#for file in /home/ubuntu/db_files/incoming/px/Guest*.csv
#do
	#### MAKE A COPY OF THE FILE IN BACKUP DIR
#	cp "$file" //home/ubuntu/db_files/incoming/px/backup/	
#     	tail -n+3 "$file"  >> /home/ubuntu/db_files/incoming/px/guests.infile.csv	
#	rm "$file"
#done
#trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
#echo 'INCOMING guest DATA FILES CLEANED AND MERGED'

####
#### WE CAN PROCESS GUEST INFO AS ITS OWN SUBROUTINE TO AVOID FAILURES STOPPING WHOLE SCRIPT

	## TRUNCATE GUESTS TABLE BEFORE LOADING W NEW
	# Delete Temp table if it exists
	mysql  --login-path=local --silent -DSRG_Prod -N -e "DROP TABLE IF EXISTS Guests_temp"
	echo 'GUESTS TEMP NEW TABLE DROPPED, STARTING NEW GUESTS TEMP NEW TABLE CREATION'

	# Create a empty copy of CardActivity table from CardActivityStructure table
	mysql  --login-path=local --silent -DSRG_Prod -N -e "CREATE TABLE Guests_temp LIKE Guests_Structure"
	echo 'Guests_temp TABLE CREATED, LOADING DATA FILE TO Guests_temp TABLE'

	# Load the data from the latest file into the (temp) CardActivity table
	mysql  --login-path=local --silent -DSRG_Prod -N -e "Load data local infile '/home/ubuntu/db_files/incoming/px/guests.infile.csv' into table Guests_temp fields terminated by ','  lines terminated by '\n'"
	echo 'Guests_temp loaded'


	### UPDATE TO NULLS FOR ZERO DATES FOR ANNIVERSARY
	mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE Guests_temp SET AnniversaryDate = NULL WHERE CAST(AnniversaryDate AS CHAR(10)) = '0000-00-00'"
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

	## UPDATE TO NULLS FOR ZERO DATES FOR REG DATE
	mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE Guests_temp SET RegisterDate = NULL WHERE CAST(RegisterDate AS CHAR(10)) = '0000-00-00'"
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

	### UPDATE TO NULLS FOR ZERO DATES FOR ENROLL DATE
	mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE Guests_temp SET EnrollDate = NULL WHERE CAST(EnrollDate AS CHAR(10)) = '0000-00-00'"
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

	### UPDATE TO NULLS FOR ZERO DATES FOR BIRTHDATE
	mysql  --login-path=local --silent -DSRG_Prod -N -e "UPDATE Guests_temp SET DateofBirth = NULL WHERE CAST(DateofBirth AS CHAR(10)) = '0000-00-00'"
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


	####### IF THIS CARDNUMBER ALREADY EXISTS IN GUESTS MASTER DELETE IT
	####### INSERT DATA FROM TEMP BY CARDNUMBER
	####### UPDATE THE TOWN INFO BY CARDNUMBER IN GUESTS MASTER
	mysql  --login-path=local -DSRG_Prod -N -e "SELECT DISTINCT(CardNumber) FROM Guests_temp" | while read -r CardNumber;
	do
		# DELETE CARDS FROM GUEST MASTER IF ALREADY EXISTS
		mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE from Guests_Master WHERE CardNumber = '$CardNumber'"
		# INSERT LATEST INFO ABOUT THIS GUEST
		mysql  --login-path=local -DSRG_Prod -N -e "INSERT INTO Guests_Master SELECT Guests_temp.*,NULL,NULL,NULL FROM Guests_temp WHERE CardNumber = '$CardNumber'"
		#### UPDATE TOWN INFO IN GUESTS_MASTER FOR THIS CARD
		mysql  --login-path=local -DSRG_Prod -N -e "SELECT Zip FROM Guests_Master WHERE CardNumber = '$CardNumber'" | while read -r Zip;
		do
			mysql  --login-path=local -DSRG_Prod -N -e "SELECT Population, AvgIncome, Town FROM MA_Zips WHERE Zip = '$Zip'" | while read -r population income town;
			do
				mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Guests_Master SET Population = '$population', AvgIncome = '$income', Town = '$town' WHERE CardNumber = '$CardNumber'"
			done	
		done 

	done
	echo 'GUESTS_MASTER TABLE UPDATED WITH NEW GUEST INFO'

# DELETE CURRENT INFILE TO READY FOR NEXT RUN
rm -f   /home/ubuntu/db_files/incoming/px/guests.infile.csv



#### PHP NO ROW IN MASTER FOR ENROLLDATE IN GUESTS MASTER FIX
( "/home/ubuntu/bin/PROD.wrong.enroll.fix.php" )
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'PHP NO ROW IN MASTER FOR ENROLLDATE IN GUESTS MASTER PROCESS/FIXED'




######### UBER JOIN LIVE CHECK DETAIL WITH LIVE SQUASHED CARD ACTIVITY
# Delete Temp table if it exists
mysql  --login-path=local --silent -DSRG_Prod -N -e "DROP TABLE IF EXISTS Master_temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER TEMP TABLE DROPPED'

# Create a empty copy of CardActivity table from CardActivityStructure table
mysql  --login-path=local --silent -DSRG_Prod -N -e "CREATE TABLE Master_temp LIKE Master_structure"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER TEMP CREATED'

###### WE ONLY GET THE LAST WEEKS WORTH OF DATA
mysql  --login-path=local -DSRG_Prod -N -e "INSERT INTO Master_temp SELECT CD.*, CA.* FROM CheckDetail_Live AS CD 
						LEFT JOIN CardActivity_squashed_2 AS CA ON CD.POSkey = CA.POSkey 
						WHERE CD.DOB >= DATE_SUB(CURDATE(), INTERVAL 30 DAY) 
						UNION SELECT CD.*, CA.* FROM .CheckDetail_Live as CD 
						RIGHT JOIN CardActivity_squashed_2 AS CA ON CD.POSkey = CA.POSkey 
						WHERE CA.TransactionDate >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
# echo 'UBER JOIN COMPLETED'
echo 'MASTER TEMP UPDATED WITH UBER CARD ACTIVITY AND CHECK DETAIL FROM PAST TWO WEEKS'

# Create enroll_date and Account_status fields
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE Master_temp ADD EnrollDate VARCHAR(11)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

# Create ACCOUNT STATUS
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE Master_temp ADD Account_status VARCHAR(15)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

# Create ACCOUNT STATUS INDEX
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE Master_temp ADD INDEX(Account_status)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER TEMP ENROLLDATE AND ACCOUNT STATUS FIELDS CREATED'

# Create ACCOUNT STATUS
mysql  --login-path=local --silent -DSRG_Prod -N -e "ALTER TABLE Master_temp ADD Card_status VARCHAR(15)"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


# AVOID DUPES DELETE SAME INTERVAL BACK
mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE FROM Master WHERE DOB >= DATE_SUB(CURDATE(), INTERVAL 30 DAY) "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER TRUNCATED - USING DOB'

# AVOID DUPES DELETE SAME INTERVAL BACK
mysql  --login-path=local --silent -DSRG_Prod -N -e "DELETE FROM Master WHERE TransactionDate >= DATE_SUB(CURDATE(), INTERVAL 30 DAY) "
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER TRUNCATED - USING TRANSACTIONDATE'



# COPY THE NEW TRANSACTIONS INTO MASTER
### WE COULD HAVE THIS TO MAKE SURE THERE ARE RECORDS IN THE TEMP TABLE(?)
mysql  --login-path=local --silent -DSRG_Prod -N -e "INSERT INTO Master SELECT * FROM Master_temp"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER POPULATED FROM MASTER TEMP'



############## THE NEXT SECTIONS WILL GET MOVED AROUND IF WE ADD CARD STATUS FIELDS
####### MASTER TABLE GUEST INFO UPDATE
mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master JOIN Guests_Master ON Master.CardNumber = Guests_Master.CardNumber 
							SET Master.EnrollDate = Guests_Master.EnrollDate, Master.Account_status = Guests_Master.AccountStatus"
trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER ACCOUNT STATUSES UPDATED FROM GUESTS MASTER TABLE '




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






