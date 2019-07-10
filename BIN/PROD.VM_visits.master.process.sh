#! //bin/bash
# LOG IT TO SYSLOG
# exec 1> >(logger -s -t $(basename $0)) 2>&1

# THIS SCRIPT HAS TO RUN AFTER CHECKDETAIL IS PROCESSED SO THAT THE CHECK NUMBER FIX RUNS CORRECTLY

# UNCOMMENT NEXT FOR VERBOSE
#set -x


### USES
# PROD.visitbalance.fix.php

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







################################ VISIT BALANCE FIX SECTION ########################################
### what if more than one transaction per day ? ? ? ? ? ? ? 

mysql  --login-path=local -DSRG_Prod -N -e "SELECT DISTINCT(CardNumber) FROM Master WHERE CardNumber IS NOT NULL AND TransactionDate >= DATE_SUB(NOW(), INTERVAL 60 DAY) 
													ORDER BY CardNumber ASC" | while read -r CardNumber;
do
	
		# GET FIRST TRANSACTION
		Min_dob=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT MIN(TransactionDate) from Master WHERE CardNumber = '$CardNumber'")
		trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

		######## GET visitsaccrued FOR THIS TransactionDate (DOB)
		VisitsAccrued=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT MAX(VisitsAccrued) from Master WHERE TransactionDate = '$Min_dob' and CardNumber = '$CardNumber'")
		trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
		##### CAN NOT BE NULL
		if [ -z $VisitsAccrued ] || [ $VisitsAccrued = NULL ] 
		then 
			#echo $VisitsAccrued" was supposedly NULL or not set"
			VisitsAccrued='0'
			#echo $VisitsAccrued" should now be 0"
		fi

		CarriedBal=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT MAX(VisitsBalance) from Master WHERE TransactionDate = '$Min_dob' AND CardNumber = '$CardNumber'")
		trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
			##### CAN NOT BE NULL
		if [ -z $CarriedBal ]  || [ $CarriedBal = NULL ]   
		then 
			#echo $CarriedBal" was supposedly NULL or not set"
			CarriedBal='0'
			#echo $CarriedBal" should now be 0"
		fi

	
		#### NOT AN EXCHANGE
		######## VISIT ACCRUED ON FIRST TRANSACTIONDATE
		if [[ $CarriedBal -eq 1 && $VisitsAccrued -eq 1 ]]
		then
			# echo $CardNumber"          Accrued on First Day!!!!       "$Min_dob"       no exchange       "$CarriedBal
			##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
			mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET Vm_VisitsBalance = VisitsBalance -1 WHERE CardNumber = '$CardNumber' AND VisitsBalance IS NOT NULL AND VisitsBalance != '0'"
			trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

			##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
			mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET Vm_VisitsAccrued = '0' WHERE CardNumber = '$CardNumber' and TransactionDate > '$Min_dob'"
			trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

			##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
			mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET Vm_VisitsAccrued = VisitsAccrued WHERE CardNumber = '$CardNumber' and TransactionDate > '$Min_dob'"
			trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

		fi



		#### NOT AN EXCHANGE
		if [[ $CarriedBal = 0 ]]
		then
		
			########### VISIT ACCRUED NULL
			if  [ $VisitsAccrued -eq 0 ] ||  [ -z $VisitsAccrued  ] 
			then
				# echo $CardNumber" DID NOT Accrue First Day "$Min_dob" no exchange "$CarriedBal
				##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
				mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET Vm_VisitsBalance = VisitsBalance, Vm_VisitsAccrued = VisitsAccrued WHERE CardNumber = '$CardNumber' "
				trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
			else
				##### ODD CASES - NO BALANCE BUT 1 VISIT ACCRUED
				# echo $CardNumber" Odd Case Min_dob:"$Min_dob" Visits Accrued:"$VisitsAccrued" Carried Balance"$CarriedBal
				##### SET FIRST DATES visitsaccrued to 0 (to account for visit counted on enrollment day), vm_visitsbalance = visitsbalance
				mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET Vm_VisitsAccrued = '0' WHERE CardNumber = '$CardNumber' and TransactionDate = '$Min_dob'"
				trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

				##### UPDATE SUBTRACTING 1 FROM ALL VisitsBalance VALUES (to account for visit counted on enrollment day)
				mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET Vm_VisitsAccrued = VisitsAccrued, Vm_VisitsBalance = VisitsBalance WHERE CardNumber = '$CardNumber' and TransactionDate > '$Min_dob'"
				trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	
			fi
		fi


		####  AN EXCHANGE
		if [ $CarriedBal  -gt 1 ]
		then
			# echo 'XXX '$CardNumber' Carried Bal should be greater than 1' $CarriedBal
			# echo $CardNumber"        First Day         "$Min_dob"       EXCHANGED!!! "$CarriedBal
			##### PX counts are correct
			mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET Vm_VisitsBalance = VisitsBalance, Vm_VisitsAccrued = VisitsAccrued WHERE CardNumber = '$CardNumber' "
			trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR	

		fi

		##### FIX THE MULTI TRANS ON DAY 1
		############## AFTER WE FIGURE OUT WHY IT HAPPENS
		mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET Vm_VisitsBalance = '0' WHERE Vm_VisitsBalance ='-1'"
		trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR


	######### THESE ARE THE FIELDS WE WILL CALCULATE EVERY DAY #################################
	#1.	 Historical Current Frequency (Hist_current_freq): Transaction Date (DOB) - Last visit date
	#2.      Current Frequency (Current_freq): Today-Last visit date
	#3.      Recent Frequency (Recent_freq): Last Visit Date-Previous visit date (2 visits back)
	#4.      Previous Frequency: Previous visit date (2 visits back)- 3 visits back
	#5.      12 Month Frequency (Year_freq): Count Visits over the previous 12 months
	#6.      Lifetime Frequency (Life_freq): Count Visits since Enrollment date

	####### CALC-ing OFF Vm_VisitsAccrued



	######## COUNT VISITS OVER PREVIOUS 12 MONTHS AND LIFETIME
	PrevYear=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT COUNT(*) from Master WHERE CardNumber = '$CardNumber' AND TransactionDate <> EnrollDate 
								AND Vm_VisitsAccrued = '1' AND TransactionDate >= DATE_SUB(NOW(),INTERVAL 60 DAY)")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	######## MINIMUM VISITBALNCE
	MinBal=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT MIN(Vm_Visitsbalance) from Master WHERE CardNumber = '$CardNumber'")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

	######## COUNT VISITS OVER LIFETIME
	Lifetime=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT COUNT(*) from Master WHERE CardNumber = '$CardNumber' 
								AND Vm_VisitsAccrued = '1'")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	######## 
	Lifetimereal="$(($MinBal+$Lifetime))"
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	######## MINIMUM VISITBALNCE
	VmVB=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT MAX(Vm_Visitsbalance) from Master WHERE CardNumber = '$CardNumber'")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR

	##### GET MAX  TRANSACTIONDATE
	MaxDate=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT MAX(TransactionDate) from Master WHERE CardNumber = '$CardNumber'")
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR	

	##### GET 2ND TO MAX TRANSACTIONDATE
	SecondMax=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT TransactionDate from Master WHERE CardNumber = '$CardNumber' 
										AND Vm_VisitsAccrued = '1' ORDER BY TransactionDate DESC limit 1,1") 
	trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
	##### IF SECONDMAX IS NULL / EMPTY
	if [ -z $SecondMax ]
	then

		##### UPDATE ONLY FIRST FREQUENCIES
		mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET FreqCurrent = DATEDIFF(NOW(), '$MaxDate'), Freq12mos = '$PrevYear', 
									FreqLifetime = '$Lifetimereal'  WHERE CardNumber = '$CardNumber'"
		trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR	
		#echo $CardNumber" first only MAX "$MaxDate" 2ND "$SecondMax"  Prevyr "$PrevYear" VmVB "$VmVB 
		#echo "PrevLifereal "$Lifetimereal" prevlifenotreal"$Lifetime" MinBal "$MinBal

		##### IF SECONDMAX HAS A VALUE
		else
			##### GET 3RD TO MAX TRANSACTIONDATE
			ThirdMax=$(mysql  --login-path=local -DSRG_Prod -N -e "SELECT transactiondate from Master WHERE CardNumber = '$CardNumber' 
										AND Vm_VisitsAccrued = '1' ORDER BY TransactionDate DESC limit 2,1") 
			trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
			##### IF THIRDMAX IS NULL / EMPTY
			if [ -z $ThirdMax ]
			then
				##### UPDATE ONLY FIRST AND SECOND FREQUENCIES
				mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET FreqCurrent = DATEDIFF(NOW(), '$MaxDate'), 
										FreqRecent = DATEDIFF('$MaxDate', '$SecondMax'), Freq12mos = '$PrevYear', 
										FreqLifetime = '$Lifetimereal'  WHERE CardNumber = '$CardNumber'"
				trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR			   
				#echo $CardNumber" first and second MAX "$MaxDate" 2ND "$SecondMax" Prevyr "$PrevYear" VmVB "$VmVB
				#echo " PrevLifereal "$Lifetimereal" prevlifenotreal "$Lifetime" MinBal "$MinBal
				
			##### IF THIRDMAX HAS A VALUE
			else
				##### UPDATE ALL FREQUENCIES
				mysql  --login-path=local -DSRG_Prod -N -e "UPDATE Master SET FreqCurrent = DATEDIFF(NOW(), '$MaxDate'), 
										FreqRecent = DATEDIFF('$MaxDate', '$SecondMax'), 
										FreqPrevious = DATEDIFF('$SecondMax', '$ThirdMax'), Freq12mos = '$PrevYear', 
										FreqLifetime = '$Lifetimereal'   WHERE CardNumber = '$CardNumber'"
			trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
			#echo $CardNumber" first second third MAX "$MaxDate" 2ND "$SecondMax" 3RD "$ThirdMax" Prevyr "$PrevYear" VmVB "$VmVB
			#echo " PrevLifereal "$Lifetimereal" prevlifenotreal "$Lifetime" MinBal "$MinBal

				
			fi

		fi
done || trap 'failfunction ${?} ${LINENO} "$BASH_COMMAND"' ERR
echo 'MASTER TABLE FREQUENCY FIELDS UPDATED AND VISIT BALANCE FIX APPLIED'


