#! //bin/bash
# NEXT for echo
set -x

############################################################################################
################## THIS SCRIPT SHOULD DO FILE HANDLING IN A NON PRODUCTION DIRECTORY !!!!!
############################################################################################
########## ADD ERROR HANDLING AT EACH FAIL POINT ###########################################


#exec 1> >(logger -s -t $(basename $0)) 2>&1

##### HALT AND CATCH FIRE AT SINGLE ITERATION LEVEL
set -e

# Add Population, avg income, Town to Guests_Master table joined from MA_Zips table



mysql  --login-path=local -DSRG_Dev -N -e "INSERT INTO Guests_Master SELECT G.*, MZ.Population, MZ.AvgIncome, MZ.Town FROM Guests AS G 
						LEFT JOIN MA_Zips as MZ ON G.Zip = MZ.Zip"



echo Guest Info Updated

