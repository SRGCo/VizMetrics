#! //bin/bash

# TURN ECHO ON
set -x

########## Ctuit export named: "Promo Detail"
#### filename should be "Promo.detail.raw.csv"



### REMOVE FIRST ROW/HEADERS BEFORE IMPORTING
#tail -n+2 Promo.detail.raw.csv > Promo.detail.csv 


mysql -v -uroot -ps3r3n1t33<<EOFMYSQL

USE SRG_Promos;

# Make a copy of (structure only)
	CREATE TABLE Promo_Detail_Incoming like Promo_Detail_Structure;

#### Load the data from the latest file into the (Incoming) table ########################
	Load data local infile '/home/srg/db_files/incoming/PromoDetail.csv' into table Promo_Detail_Incoming fields terminated by ',' lines terminated by '\n';

#### DELETE ANY OF THE SALES ADJUSTMENTS
       DELETE FROM Promo_Detail_Incoming WHERE Notes = 'Daily Sales Adjustment';


# PUT DOB INTO SQL FORMAT
        UPDATE Promo_Detail_Incoming SET DOB= STR_TO_DATE(DOB, '%m/%d/%Y') WHERE STR_TO_DATE(DOB, '%m/%d/%Y') IS NOT NULL;

# Change DOB field to type date
	ALTER TABLE Promo_Detail_Incoming CHANGE DOB DOB DATE;

# Create POSkey field
	ALTER TABLE Promo_Detail_Incoming ADD POSkey BIGINT first;

# Create excel date field
	ALTER TABLE Promo_Detail_Incoming ADD Exceldate INT(100) NOT NULL AFTER LocationID;

# Update excel date field
	 UPDATE Promo_Detail_Incoming set Exceldate = (((unix_timestamp(DOB) / 86400) + 25569) + (-5/24));

# Update POSkey field (location + DOB[excel format][no decimal] + checknumber)
	 UPDATE Promo_Detail_Incoming set POSkey = CONCAT_WS('', LocationID, Exceldate, CheckNumber);

# Add Index on PromoID
	ALTER TABLE Promo_Detail_Incoming ADD INDEX(POSkey);

# Dump Excel date field
	 ALTER TABLE Promo_Detail_Incoming DROP Exceldate;

# Add Index on PromoID
	ALTER TABLE Promo_Detail_Incoming ADD INDEX(PromoID);

# Add names columns
	ALTER TABLE Promo_Detail_Incoming ADD COLUMN PromoName varchar (100) after POSkey;

# ADD in Promo Names
	UPDATE Promo_Detail_Incoming PD INNER JOIN Promos P ON PD.PromoID = P.PromoID SET PD.PromoName = P.PromoName;

##### ADD INCOMING CHECK DETAIL DATA TO LIVE TABLE
	INSERT INTO Promo_Detail_Live SELECT * FROM Promo_Detail_Incoming;

##### ADD INCOMING CHECK DETAIL DATA TO LIVE TABLE
	DROP TABLE Promo_Detail_Incoming;

##### SELECT INTO OUTFILE ## SMOOSHED DATA #########
##### WRITE TO OUTFILE
	SELECT DISTINCT(POSkey) as POSkey, PromoName, DOB, SUM(Amount) 
	from Promo_Detail_Live group by POSkey, PromoName, DOB ORDER BY DOB, POSkey
	INTO OUTFILE '/home/srg/db_files/incoming/Promo_Detail.out.csv' 
	FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n'



# QUIT MYSQL
EOFMYSQL

##### PROCESS THE FILE
#### PREPEND HEADERS
cat /home/srg/db_files/headers/promodetail.headers.csv /home/srg/db_files/incoming/Promo_Detail.out.csv > /home/srg/db_files/incoming/PromoDetail_Live.csv
EOFMYSQL

