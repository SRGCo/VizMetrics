#! //bin/bash
# HAVE OUTPUT SO CRON EMAILS RESULTS
# set -x

# UNCOMMENT TO LOG TO SYSLOG
#exec 1> >(logger -s -t $(basename $0)) 2>&1

##### HALT AND CATCH FIRE AT SINGLE ITERATION LEVEL
set -e

######### THESE ARE THE FIELDS WE WILL CALCULATE EVERY DAY #################################
#1.	 Historical Current Frequency (Hist_current_freq): Transaction Date (DOB) - Last visit date
#2.      Current Frequency (Current_freq): Today-Last visit date
#3.      Recent Frequency (Recent_freq): Last Visit Date-Previous visit date (2 visits back)
#4.      Previous Frequency: Previous visit date (2 visits back)- 3 visits back
#5.      12 Month Frequency (Year_freq): Count Visits over the previous 12 months
#6.      Lifetime Frequency (Life_freq): Count Visits since Enrollment date

####### THESE NEED TO CALC OFF Vm_VisitsAccrued !!!!!!!!!!!!!!!!!!!!!!!!!!!!! ###########################


mysql  --login-path=local -DSRG_Dev -N -e "SELECT CardNumber FROM Master WHERE CardNumber IS NOT NULL 
						GROUP BY CardNumber ORDER BY CardNumber ASC" | while read -r CardNumber;
do

	######## COUNT VISITS OVER PREVIOUS 12 MONTHS AND LIFETIME
	PrevYear=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT COUNT(*) from Master WHERE CardNumber = '$CardNumber' 
								AND TransactionDate <> EnrollDate  
								AND Vm_VisitsAccrued = '1' 
								AND TransactionDate >= DATE_SUB(NOW(),INTERVAL 1 YEAR)")
	######## MINIMUM VISITBALNCE
	MinBal=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MIN(Vm_Visitsbalance) from Master WHERE CardNumber = '$CardNumber'")

	######## COUNT VISITS OVER LIFETIME
	Lifetime=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT COUNT(*) from Master WHERE CardNumber = '$CardNumber' 
								AND Vm_VisitsAccrued = '1'")
	######## 
	Lifetimereal="$(($MinBal+$Lifetime))"

	######## MINIMUM VISITBALNCE
	VmVB=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(Vm_Visitsbalance) from Master WHERE CardNumber = '$CardNumber'")

	##### GET MAX  TRANSACTIONDATE
	MaxDate=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT MAX(TransactionDate) from Master WHERE CardNumber = '$CardNumber'")
		##### GET 2ND TO MAX TRANSACTIONDATE
		SecondMax=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT TransactionDate from Master WHERE CardNumber = '$CardNumber' 
										AND Vm_VisitsAccrued = '1' ORDER BY TransactionDate DESC limit 1,1") 
		##### IF SECONDMAX IS NULL / EMPTY
		if [ -z "$SecondMax" ]
		then

			##### UPDATE ONLY FIRST FREQUENCIES
			mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET FreqCurrent = DATEDIFF(NOW(), '$MaxDate'), Freq12mos = '$PrevYear', 
										FreqLifetime = '$Lifetimereal'  WHERE CardNumber = '$CardNumber'"
			echo $CardNumber" first only MAX "$MaxDate" 2ND "$SecondMax"  Prevyr "$PrevYear" VmVB "$VmVB 
			echo "PrevLifereal "$Lifetimereal" prevlifenotreal"$Lifetime" MinBal "$MinBal

		##### IF SECONDMAX HAS A VALUE
		else
			##### GET 3RD TO MAX TRANSACTIONDATE
			ThirdMax=$(mysql  --login-path=local -DSRG_Dev -N -e "SELECT transactiondate from Master WHERE CardNumber = '$CardNumber' 
										AND Vm_VisitsAccrued = '1' ORDER BY TransactionDate DESC limit 2,1") 
			##### IF THIRDMAX IS NULL / EMPTY
			if [ -z "$ThirdMax" ]
			then
				##### UPDATE ONLY FIRST AND SECOND FREQUENCIES
				mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET FreqCurrent = DATEDIFF(NOW(), '$MaxDate'), 
										FreqRecent = DATEDIFF('$MaxDate', '$SecondMax'), Freq12mos = '$PrevYear', 
										FreqLifetime = '$Lifetimereal'  WHERE CardNumber = '$CardNumber'"			   
				echo $CardNumber" first and second MAX "$MaxDate" 2ND "$SecondMax" Prevyr "$PrevYear" VmVB "$VmVB
				echo " PrevLifereal "$Lifetimereal" prevlifenotreal "$Lifetime" MinBal "$MinBal
				

			##### IF THIRDMAX HAS A VALUE
			else
				##### UPDATE ALL FREQUENCIES
				mysql  --login-path=local -DSRG_Dev -N -e "UPDATE Master SET FreqCurrent = DATEDIFF(NOW(), '$MaxDate'), 
										FreqRecent = DATEDIFF('$MaxDate', '$SecondMax'), 
										FreqPrevious = DATEDIFF('$SecondMax', '$ThirdMax'), Freq12mos = '$PrevYear', 
										FreqLifetime = '$Lifetimereal'   WHERE CardNumber = '$CardNumber'"

			echo $CardNumber" first second third MAX "$MaxDate" 2ND "$SecondMax" 3RD "$ThirdMax" Prevyr "$PrevYear" VmVB "$VmVB
			echo " PrevLifereal "$Lifetimereal" prevlifenotreal "$Lifetime" MinBal "$MinBal

				
			fi

		fi
done



echo Frequencies Updated
