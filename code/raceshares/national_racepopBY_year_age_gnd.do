* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Create required folders
cap mkdir "$root/scratch/National Intercensal-Postcensal Populations/"
cap mkdir "$root/data/derived/raceshares/"

/***

Uses the national Intercensal and Postcensal estimate tables, which contain
racial populations by Age x Gender x Year. In addition to intercensal and
postcensal data (July), they also contain the 2000 and 2010 Census data (April).

We use these data to generate the national population of
each race, in two files:

- by Age x Gender x Year (2001-2014) from the 2000s and 2010s
	Intercensal/Postcensal estimates.

- by Gender for age 40 from the 2000 Census

***/

********************************************************************

cap program drop clean_censal_estimates
program define clean_censal_estimates
	
	/* Note:
	- For the 2000s Intercensal Estimates, 85="85+", 999="all ages". rest are single ages.
	- For the 2010s Postcensal Estimates, 100="100+", 999="all ages". rest are single ages.
	*/
	
	* Keep only desired single ages
	keep if inrange(age,40,76)
	
	* Keep only required race pops
	keep year month age tot_male tot_female h_male h_female nhba_male nhba_female nhaa_male nhaa_female
	
	* Reshape gender long
	reshape long tot_ nhba_ nhaa_ h_, i(year month age) j(gnd) string
	assert inlist(gnd,"male","female")
	replace gnd=cond(gnd=="male","M","F")
	compress gnd
	
	* Rename pop vars
	rename tot_ pop_total
	rename nhba_ pop_black
	rename nhaa_ pop_asian
	rename h_ pop_hispanic
	
	* Generate non-black non-hispanic population count
	gen long pop_other = pop_total - pop_black - pop_asian - pop_hispanic
	drop pop_total

end

***************************************
*** 2000-2010 Intercensal Estimates ***
***************************************

* For details on intercensal estimates: http://www.cdc.gov/nchs/ppt/nchs2012/SS-20_ALEXA.pdf
project, relies_on("$root/data/raw/Census National Intercensal Estimates 2000-2010/SS-20_ALEXA.pdf")

* Import raw data
project, relies_on("$root/data/raw/Census National Intercensal Estimates 2000-2010/source.txt")  // web source
project, relies_on("$root/data/raw/Census National Intercensal Estimates 2000-2010/US-EST00INT-ALLDATA.pdf")  // docs
project,  original("$root/data/raw/Census National Intercensal Estimates 2000-2010/US-EST00INT-ALLDATA.csv")  // data
import delimited "$root/data/raw/Census National Intercensal Estimates 2000-2010/US-EST00INT-ALLDATA.csv", clear

* Reshape/rename raw intercensal data
clean_censal_estimates

/*

The census data is April 2000 and April 2010.
The intercensal estimates are for July of each year, 2000 and 2010 included.

We therefore want to use the July data for our "by year" data, but the April data
for our 2000 Census reference race shares.

*/
tab year month

*** 2000 CENSUS
preserve

* Keep only age 40 2000 Census data
keep if age==40 & year==2000 & month==4
drop age year month
isid gnd

* Output
save13 "$root/data/derived/raceshares/national_2000age40_racepopBY_gnd.dta", replace
project, creates("$root/data/derived/raceshares/national_2000age40_racepopBY_gnd.dta")

restore

*** BY YEAR

* Keep only July data
keep if month==7
drop month
isid year age gnd

* Output
order year age gnd
sort year age gnd
save13 "$root/scratch/National Intercensal-Postcensal Populations/national_2000s_racepopBY_year_age_gnd.dta", replace


**************************************
*** 2010-2014 Postcensal Estimates ***
**************************************

project, relies_on("$root/data/raw/Census National Postcensal Estimates 2010-2014/source.txt")  // web source
project, relies_on("$root/data/raw/Census National Postcensal Estimates 2010-2014/NC-EST2014-ALLDATA.pdf")  // data dictionary
project, relies_on("$root/data/raw/Census National Postcensal Estimates 2010-2014/2014-natstcopr-meth.pdf")  // methodology

* Prepare annual data
forvalues f=2(2)10 {

	* Import raw data
	local ff "`: di %02.0f `f''"
	project, original("$root/data/raw/Census National Postcensal Estimates 2010-2014/NC-EST2014-ALLDATA-R-File`ff'.csv")  // data
	import delimited "$root/data/raw/Census National Postcensal Estimates 2010-2014/NC-EST2014-ALLDATA-R-File`ff'.csv", clear
	
	* Reshape/rename
	clean_censal_estimates
	
	* Keep only July data
	keep if month==7
	drop month
	isid age gnd  // only a single year's data
	
	* Output
	order year age gnd
	qui sum year, meanonly
	save13 "$root/scratch/National Intercensal-Postcensal Populations/national_`r(mean)'_racepopBY_year_age_gnd.dta", replace
	
}


***********************************
*** Combine data from 2001-2014 ***
***********************************

* Load and append data from all years
use if inrange(year,2001,2009) using "$root/scratch/National Intercensal-Postcensal Populations/national_2000s_racepopBY_year_age_gnd.dta", clear
forvalues y=2010/2014 {
	append using "$root/scratch/National Intercensal-Postcensal Populations/national_`y'_racepopBY_year_age_gnd.dta"
}

* Output
order year age gnd
sort year age gnd
save13 "$root/data/derived/raceshares/national_racepopBY_year_age_gnd.dta", replace
project, creates("$root/data/derived/raceshares/national_racepopBY_year_age_gnd.dta")

