#! /bin/bash
# Next line turns echo on
set -x

### FIRE UP MYSQL
mysql -v -uroot -ps3r3n1t33<<EOFMYSQL

USE SRG_live;

#UPDATE Check_Detail_Incoming INNER JOIN SRG_Employees_Live ON (Check_Detail_Incoming.LocationID = SRG_Employees_Live.LocationID AND Check_Detail_Incoming.Base_EmployeeID = SRG_Employees_Live.EmployeeID) SET Check_Detail_Incoming.lastname = SRG_Employees_Live.LastName, Check_Detail_Incoming.firstname = SRG_Employees_Live.FirstName;

#### UPDATE LEGACY BAR NAMES
UPDATE Check_Detail_Incoming INNER JOIN SRG_Employees_Legacy ON (Check_Detail_Incoming.LocationID = SRG_Employees_Legacy.LocationID AND Check_Detail_Incoming.Base_EmployeeID = SRG_Employees_Legacy.EmployeeID) SET Check_Detail_Incoming.lastname = SRG_Employees_Legacy.LastName, Check_Detail_Incoming.firstname = SRG_Employees_Legacy.FirstName;

# QUIT MYSQL
EOFMYSQL

