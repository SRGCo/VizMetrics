#! /bin/bash
# Next line turns echo on
set -x

### FIRE UP MYSQL
mysql -v -uroot -ps3r3n1t33<<EOFMYSQL


############# THERE IS SOMETHING WRONG WITH THE OUTFILE, IT CREATES AN EXTRA ROW AFTER EVERY ROW WITH THREE COMMAS 


USE srg_dev5;

# Load the data from the latest file
##     	Load data local infile '/home/srg/db_files/card.activity.merged.csv' into table px_card_activity_full fields terminated by ',' lines terminated by '\n';

# fix date length
##	UPDATE px_card_activity_full SET Transaction_Date=SUBSTRING(Transaction_Date, 1, 10);

# PUT TransactionDate INTO SQL FORMAT
##     	UPDATE px_card_activity_full SET Transaction_Date = STR_TO_DATE(Transaction_Date, '%Y-%m-%d') WHERE STR_TO_DATE(Transaction_Date, '%Y-%m-%d') IS NOT NULL;

# Change TransactionDate field to type date
#	ALTER TABLE px_card_activity_full CHANGE Transaction_Date Transaction_Date DATE;



# UPDATE ALL LOCATIONS
#	UPDATE px_card_activity_full SET Store_Number = '3' WHERE Store_Number = '2';
#	UPDATE px_card_activity_full SET Store_Number = '2' WHERE Store_Number = '5';
#	UPDATE px_card_activity_full SET Store_Number = '5' WHERE Store_Number = '8';
#	UPDATE px_card_activity_full SET Store_Number = '7' WHERE Store_Number = '6';
#	UPDATE px_card_activity_full SET Store_Number = '6' WHERE Store_Number = '11';
#	UPDATE px_card_activity_full SET Store_Number = '8' WHERE Store_Number = '12';
#	UPDATE px_card_activity_full SET Store_Number = '9' WHERE Store_Number = '13';


# Create POSkey field
#	ALTER TABLE px_card_activity_full ADD POSkey VARCHAR( 255 ) first;

# Create excel date fieldC
#	ALTER TABLE px_card_activity_full ADD Exceldate INT(100) after POSkey;

# Update excel date field
#	 UPDATE px_card_activity_full set Exceldate = (((unix_timestamp(Transaction_Date) / 86400) + 25569) + (-5/24));

# Update POSkey field (location + TransactionDateexcel formatno decimal + checknumber)
#	 UPDATE px_card_activity_full SET POSkey = CONCAT_WS('-', Store_Number, Exceldate, Check_No);

# Dump Excel date field
#	 ALTER TABLE px_card_activity_full DROP Exceldate;

# NULLS BLOW UP EXPORT
# UPDATE `px_card_activity_full` SET `SV Discount Tracking Accrued` = '';
# UPDATE `px_card_activity_full` SET `SV Discount Tracking Redeemed` = '';
# UPDATE `px_card_activity_full` SET `SV Discount Tracking Balance` = '';


# WRITE TO OUTFILE
	SELECT px_card_activity_full.* INTO OUTFILE '/home/srg/db_files/px.ca.w.poskey.csv' FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' FROM px_card_activity_full;


# QUIT MYSQL
EOFMYSQL

