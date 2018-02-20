#! //bin/bash

# TURN ECHO ON
set -x

########## Ctuit export named: "Promo Detail"
#### filename should be "Promo.detail.raw.csv"
### REMOVE FIRST ROW/HEADERS BEFORE IMPORTING
tail -n+2 Promo.detail.raw.csv > Promo.detail.csv 


mysql -uroot -ps3r3n1t33 << EOF

USE SRG_Promos;

# Make a copy of (structure only)
	CREATE TABLE Promo_Details_temp like Promo_Detail_Structure;

#### Load the data from the latest file into the (temp) TableTurns table ########################
	Load data local infile '/home/srg/db_files/Promo.detail.csv' into table Promo_Detail_temp fields terminated by ',' lines terminated by '\n';

# PUT DOB INTO SQL FORMAT
        UPDATE Promo_Detail_temp SET DOB= STR_TO_DATE(DOB, '%m/%d/%Y') WHERE STR_TO_DATE(DOB, '%m/%d/%Y') IS NOT NULL;

# Change DOB field to type date
	ALTER TABLE Promo_Detail_temp CHANGE DOB DOB DATE;

# Create POSkey field
	ALTER TABLE Promo_Detail_temp ADD POSkey BIGINT first;

# Create excel date field
	ALTER TABLE Promo_Detail_temp ADD Exceldate INT(100) NOT NULL AFTER LocationID;

# Update excel date field
	 UPDATE Promo_Detail_temp set Exceldate = (((unix_timestamp(DOB) / 86400) + 25569) + (-5/24));

# Update POSkey field (location + DOB[excel format][no decimal] + checknumber)
	 UPDATE Promo_Detail_temp set POSkey = CONCAT_WS('', LocationID, Exceldate, CheckNumber);

# Dump Excel date field
	 ALTER TABLE Promo_Detail_temp DROP Exceldate;

# Add names columns
	ALTER TABLE Promo_Detail_temp ADD COLUMN PromoName varchar (100) after POSkey;

##################### INDEX HERE #######################


# ADD in Promo Names
#        UPDATE Promo_Detail_temp INNER JOIN Promos on Promo_Detail_temp.PromoID = Promos.PromoID SET Promo_Detail_temp.PromoName = Promos.PromoName;
