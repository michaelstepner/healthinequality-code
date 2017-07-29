* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set global aliases
global racedata $root/data/derived/raceshares

/***

Generate national race shares by (Year x) Age x Gender x Income Percentile.

***/

****************
*** Programs ***
****************

project, original("$root/code/ado/compute_raceshares.ado")


*************************************
*** 2000 Census, Household income ***
*************************************

* Load data
project, uses("$racedata/national_racepopBY_year_age_gnd_hhincpctile.dta")
use "$racedata/national_racepopBY_year_age_gnd_hhincpctile.dta", clear
assert !mi(pop_black, pop_asian, pop_hispanic, pop_other)
rename hh_inc_pctile pctile  // match IRS collapse varname

*** Trends, by year ***

* Compute race shares
compute_raceshares, by(year age gnd pctile)

* Save data
save13 "$racedata/national_racesharesBY_year_age_gnd_hhincpctile.dta", replace
project, creates("$racedata/national_racesharesBY_year_age_gnd_hhincpctile.dta") preserve

*** Levels, pooled ***

* Pool populations over all years
isid year age gnd pctile
collapse (sum) pop_*, by(age gnd pctile)

* Compute race shares
compute_raceshares, by(age gnd pctile)

* Save data
save13 "$racedata/national_racesharesBY_age_gnd_hhincpctile.dta", replace
project, creates("$racedata/national_racesharesBY_age_gnd_hhincpctile.dta")


**************************************
*** 2000 Census, Individual income ***
**************************************

* Load data
project, uses("$racedata/Individual income/national_racepopBY_year_age_gnd_INDincpctile.dta")
use "$racedata/Individual income/national_racepopBY_year_age_gnd_INDincpctile.dta", clear
assert !mi(pop_black, pop_asian, pop_hispanic, pop_other)

* Pool populations over all years
isid year age gnd ind_inc_pctile
collapse (sum) pop_*, by(age gnd ind_inc_pctile)

* Compute race shares
compute_raceshares, by(age gnd ind_inc_pctile)
rename ind_inc_pctile indv_earn_pctile  // match IRS collapse varname

* Save data
save13 "$racedata/Individual income/national_racesharesBY_age_gnd_INDincpctile.dta", replace
project, creates("$racedata/Individual income/national_racesharesBY_age_gnd_INDincpctile.dta")


***************************************
*** 2008-2012 ACS, Household income ***
***************************************

* Load data
project, uses("$racedata/2008-2012 ACS income distribution/national_racepopBY_year_age_gnd_hhincpctile_ACS.dta")
use "$racedata/2008-2012 ACS income distribution/national_racepopBY_year_age_gnd_hhincpctile_ACS.dta", clear
assert !mi(pop_black, pop_asian, pop_hispanic, pop_other)

* Pool populations over all years
isid year age gnd hh_inc_pctile
collapse (sum) pop_*, by(age gnd hh_inc_pctile)

* Compute race shares
compute_raceshares, by(age gnd hh_inc_pctile)
rename hh_inc_pctile pctile  // match IRS collapse varname

* Save data
save13 "$racedata/2008-2012 ACS income distribution/national_racesharesBY_age_gnd_hhincpctile_ACS.dta", replace
project, creates("$racedata/2008-2012 ACS income distribution/national_racesharesBY_age_gnd_hhincpctile_ACS.dta")


********************************************************************************
*** Age 51 Retirement Age Extrapolation Test (2000 Census, Household Income) ***
********************************************************************************

* Load data
project, uses("$racedata/Age 51 Retirement Age Extrapolation Test/national_racepopBY_year_age_gnd_hhincpctile_51test.dta")
use "$racedata/Age 51 Retirement Age Extrapolation Test/national_racepopBY_year_age_gnd_hhincpctile_51test.dta", clear
assert !mi(pop_black, pop_asian, pop_hispanic, pop_other)

* Pool populations over all years
isid year age gnd hh_inc_pctile
collapse (sum) pop_*, by(age gnd hh_inc_pctile)

* Compute race shares
compute_raceshares, by(age gnd hh_inc_pctile)
rename hh_inc_pctile pctile  // match IRS collapse varname

* Save data
save13 "$racedata/Age 51 Retirement Age Extrapolation Test/national_racesharesBY_age_gnd_hhincpctile_51test.dta", replace
project, creates("$racedata/Age 51 Retirement Age Extrapolation Test/national_racesharesBY_age_gnd_hhincpctile_51test.dta")
