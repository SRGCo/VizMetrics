#! /bin/bash

################# THIS NEEDS TO HAPPEN to CardActivity_Temp TABLE BEFORE IT IS INSERTED INTO _Live
#### silent, no columns, exit

mysql -uroot -ps3r3n1t33 -DSRG_checks -N -e "SELECT RIGHT(CheckNumber, 4), DOB, LocationID FROM CheckDetail_Live WHERE CheckDetail_Live.CheckNumber like '100%' AND DOB > '2017-08-01'" | while read -r CheckNumber DOB LocationID;
do
echo $CheckNumber $DOB $LocationID
mysql -uroot -ps3r3n1t33 -DSRG_px -N -e "UPDATE CardActivity_Live SET CheckNo=CONCAT('100',CheckNo) WHERE CheckNo = '$CheckNumber' AND TransactionDate = '$DOB' AND LocationID = '$LocationID' AND char_length(CheckNo) < '6'"
done


