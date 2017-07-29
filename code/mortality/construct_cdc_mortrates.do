* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mortality_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mortality_root}/code/set_environment.do"
}

* Set convenient globals
global raw "${root}/data/raw"

* Create required folders
cap mkdir "${root}/data/derived/Mortality Rates"
cap mkdir "${root}/data/derived/Mortality Rates/CDC-SSA Life Table"


/*** Generate national mortality rates by Gender x Age, for ages 0-119, from:

- CDC Life Tables for Ages 0-99, taking a simple average of years 2001-2011
	- CDC does not report mortality rates past age 99.

- SSA Life Tables for Ages 100-119, using data from 2000 life table

***/

********************


*** Reference docs
project, relies_on("${raw}/CDC Life Tables/source.txt")
project, relies_on("${raw}/CDC Life Tables/download_CDC_life_tables.do")
project, relies_on("${raw}/SSA Life Tables/source.txt")

*** Load CDC mortality rates from 0-99

* Load data
project, original("${raw}/CDC Life Tables/CDC_LifeTables.dta")
use "${raw}/CDC Life Tables/CDC_LifeTables.dta", clear
tab year

* Average over years
isid gnd age year
collapse (mean) mortrate, by(gnd age)


*** Append SSA mortality rates at 100+
project, original("${raw}/SSA Life Tables/SSA_LifeTables_2000.dta") preserve
append using "${raw}/SSA Life Tables/SSA_LifeTables_2000.dta", gen(_append)
drop if _append==1 & age<100
drop _append

*** Output
sort gnd age
bys gnd: assert _N==120 & age[1]==0 & age[120]==119
rename mortrate cdc_mort
save13 "${root}/data/derived/Mortality Rates/CDC-SSA Life Table/national_CDC_SSA_mortratesBY_gnd_age.dta", replace
project, creates("${root}/data/derived/Mortality Rates/CDC-SSA Life Table/national_CDC_SSA_mortratesBY_gnd_age.dta")
