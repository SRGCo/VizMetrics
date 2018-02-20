#! /bin/bash
# Next line turns echo on
set -x

### FIRE UP MYSQL
mysql -v -uroot -ps3r3n1t33<<EOFMYSQL


############# THERE IS SOMETHING WRONG WITH THE OUTFILE, IT CREATES AN EXTRA ROW AFTER EVERY ROW WITH THREE COMMAS 


USE px_test;

# WRITE TO OUTFILE
	SELECT px_test.CardActivity.* INTO OUTFILE '/home/srg/db_files/card.activity.2016.partial.csv' FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' FROM CardActivity WHERE transactiondate > '2016-09-01' AND transactiondate < '2016-12-31';


# QUIT MYSQL
EOFMYSQL

