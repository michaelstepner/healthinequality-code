* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Create required folders
cap mkdir "${root}/scratch/Summary stats on number of observations age and income"

* Erase output numbers
cap erase "${root}/scratch/Summary stats on number of observations age and income/Summary Stats.csv"

/*** Calculate the total number of observations, mean and median household income
	 for working individuals, and the mean age of individuals in our sample.
***/

*************


* Load mortality rates
project, original("${root}/data/derived/Mortality Rates/mskd_national_mortratesBY_gnd_hhincpctile_age_year.dta")
use "${root}/data/derived/Mortality Rates/mskd_national_mortratesBY_gnd_hhincpctile_age_year.dta", clear
keep if age_at_d >= 40

sum hh_inc [w=count] if age_at_d <= 63, detail
scalarout using "${root}/scratch/Summary stats on number of observations age and income/Summary Stats.csv", ///
	id("Working Individuals Mean Household Income") ///
	num(`=r(mean)') fmt(%9.0fc)
scalarout using "${root}/scratch/Summary stats on number of observations age and income/Summary Stats.csv", ///
	id("Working Individuals Median Household Income") ///
	num(`=r(p50)') fmt(%9.0fc)
	
sum age_at_d [w=count]
scalarout using "${root}/scratch/Summary stats on number of observations age and income/Summary Stats.csv", ///
	id("Working Individuals Mean Age") ///
	num(`=r(mean)') fmt(%9.1f)
	
sum count
scalarout using "${root}/scratch/Summary stats on number of observations age and income/Summary Stats.csv", ///
	id("Total Number of Observations") ///
	num(`=r(sum)') fmt(%14.0fc)

*****************************************
*** Project creates: reported numbers ***
*****************************************

project, creates("${root}/scratch/Summary stats on number of observations age and income/Summary Stats.csv")

