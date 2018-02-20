#! //bin/bash

# Next line turns echo on
set -x



################################

### THIS WAS FAILING SOMEWHERE AND ONLY GIVE PART OF FILE


#######################






#################################################################################
########## Ctuit export named: "TableTurn"
### TABLETURN EXPORT FROM CTUIT ONLY NEEDS DATA FROM LATEST DOB IN TABLETURNS_LIVE TABLE
##### 2016-12-20 ### STILL MANUALLY CLEARING OLD FILES OUT OF db_files DIRECTORY BEFORE RUNNING IMPORT/UPDATE


#### filename should be "TableTurns.raw.csv"
### REMOVE FIRST ROW/HEADERS BEFORE IMPORTING
tail -n+2 Tableturns.raw.csv > Tableturns.csv 


#Fire up mysql (as root not the best idea, revise in future)
# mysql -uroot -ps3r3n1t33 <<EOF

#MySQL in Verbose mode
mysql -v -uroot -ps3r3n1t33<<EOFMYSQL

USE SRG_live;

### MAKE SURE THE TEMP TABLE HAS BEEN DUMPED
	DROP TABLE IF EXISTS TableTurns_temp;


# Create a empty copy of TableTurns_Temp table from TableTurns_Structure table
	CREATE TABLE TableTurns_temp AS (SELECT * FROM TableTurns_Structure WHERE 1=0);

# Load the data from the latest file into the (temp) TableTurns table
	Load data local infile '/home/srg/db_files/Tableturns.csv' into table TableTurns_temp fields terminated by ',' lines terminated by '\n';

##### 2 ### TWEAK DATA IN TEMP TABLE
# PUT DOB INTO SQL FORMAT
	UPDATE TableTurns_temp SET DOB= STR_TO_DATE(DOB, '%c/%e/%Y') WHERE STR_TO_DATE(DOB, '%c/%e/%Y') IS NOT NULL;
# Change DOB field to type date
	ALTER TABLE TableTurns_temp CHANGE DOB DOB DATE;

# Change OpenTime & CloseTime to SQL format
	UPDATE TableTurns_temp SET CloseTime= STR_TO_DATE(CloseTime, '%m/%e/%Y %l:%i:%s %p') WHERE STR_TO_DATE(CloseTime, '%m/%e/%Y %l:%i:%s %p');
	UPDATE TableTurns_temp SET OpenTime= STR_TO_DATE(OpenTime, '%m/%e/%Y %l:%i:%s %p') WHERE STR_TO_DATE(OpenTime,  '%m/%e/%Y %l:%i:%s %p');
##### MUST ALTER THESE FIELDS TO DATETIME #################
	ALTER TABLE TableTurns_temp CHANGE CloseTime CloseTime DATETIME NOT NULL;

# Create POSkey field
	ALTER TABLE TableTurns_temp ADD POSkey VARCHAR( 255 ) first;

# Create excel date field
	ALTER TABLE TableTurns_temp ADD Exceldate INT(100) NOT NULL AFTER LocationID;

# Update excel date field
	 UPDATE TableTurns_temp set Exceldate = (((unix_timestamp(DOB) / 86400) + 25569) + (-5/24));

# Update POSkey field (location + TransactionDate[excel format][no decimal] + checknumber)
	 UPDATE TableTurns_temp set POSkey = CONCAT_WS('-', LocationID, Exceldate, CheckNumbers);

############################
##### 3 update TableTurns_live with the data
###########################

INSERT INTO TableTurns_Live SELECT * FROM TableTurns_temp;


############# THIS SHOULD WRITE TO THE CHECK DETAIL FULL LIVE 

	UPDATE Check_Detail_Full_Live CD
	INNER JOIN TableTurns_Live TT 
	ON CD.POSkey = TT.POSkey
	SET CD.OpenTime = TT.OpenTime,
	CD.CloseTime = TT.CloseTime,
	CD.MinutesOpen = TIMESTAMPDIFF(minute, TT.OpenTime, TT.CloseTime)

##### 4 drop the TableTurns_temp table
	DROP TABLE IF EXISTS TableTurns_temp


# QUIT MYSQL
EOFMYSQL

################################################################################################################
#############                  Need to create                 ##################################################
#### script to automatically prepend check.detail.wturns.headings.csv to Check.Detail.wturns.csv (outfile) #####

# sed -i '1s/^/POSkey,lastname,firstname,LocationID,DOB,CheckNumber,Base_DaypartID,Base_RevenueCenterID,Base_EmployeeID,TrueNetSales,NetSalesCoDefined,GrossSalesCoDefined,TaxExemptSales,NonSalesRevenue,Surcharges,ModeCharges,GCSold,Guests,Checks,Entrees,Comps,Promos,GCComps,GCPromos,ExclusiveTaxes,InclusiveTaxes,CashTenders,NonCashTenders,CashTips,NonCashTips,CashAutoGrats,NonCashAutoGrats,PaidIns,PaidOuts,Refunds,Voids,TransfersIn,TransfersOut,record_id,OpenTime,CloseTime,MinutesOpen\n /' outfiles/Check.Detail.wturns.csv






#TURN ECHO ON AGAIN
set -x



# Now that we are back out of the mysql aql scripting we can 
# DELETE THE RENAMED AND RAW CardActivity files
# cp TableTurns.csv TableTurns.old.csv
# rm TableTurns.csv
# TableTurns.raw.csv






 


